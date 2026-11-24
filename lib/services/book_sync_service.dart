import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'book_server_config.dart';

/// One entry from the book server's `manifest.json`.
class BookManifestEntry {
  const BookManifestEntry({
    required this.relativePath,
    this.size,
    this.mtime,
  });

  /// Path relative to the server root, e.g. `SecretHistoryOfMongols.json`
  /// or `output/folktales-1979-p001.jpg`.
  final String relativePath;

  /// File size in bytes, when the manifest reports it.
  final int? size;

  /// Last-modified time, when the manifest reports it.
  final DateTime? mtime;

  /// Local file name — the sync flattens the server tree into the local
  /// books dir, same as the old FTP sync did.
  String get fileName => relativePath.split('/').last;

  static DateTime? _parseMtime(dynamic value) {
    if (value == null) return null;
    if (value is num) {
      // Epoch seconds (~1.8e9) vs milliseconds (~1.8e12).
      final ms =
          value > 100000000000 ? value.toInt() : (value * 1000).toInt();
      return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    if (value is String) {
      final asDate = DateTime.tryParse(value);
      if (asDate != null) return asDate;
      final asNum = num.tryParse(value);
      if (asNum != null) return _parseMtime(asNum);
    }
    return null;
  }

  factory BookManifestEntry.fromJson(Map<String, dynamic> json) {
    final rawPath = json['path'] ?? json['name'] ?? json['file'];
    final rawSize = json['size'] ?? json['bytes'];
    return BookManifestEntry(
      relativePath: '$rawPath',
      size: rawSize is num ? rawSize.toInt() : int.tryParse('$rawSize'),
      mtime: _parseMtime(
          json['mtime'] ?? json['modified'] ?? json['lastModified']),
    );
  }
}

/// Syncs book JSON + cover images + page images from the public book
/// server over HTTPS (plain HTTP only for the local test URL).
///
/// Server endpoint — ONE configurable constant:
///   [BookServerConfig.baseUrl] (see lib/services/book_server_config.dart).
/// The server serves `{baseUrl}/manifest.json` listing each file's
/// relative path, size and mtime, and each file at
/// `{baseUrl}/<relative-path>`. To point the sync at a different server,
/// change that one constant.
///
/// Sync is best-effort background work: failures are logged to
/// [lastBooksStatus] and never pop up UI, books already downloaded keep
/// working offline, and the library reloads only when files actually
/// changed. Uses dart:io [HttpClient] (stdlib) — no new pub dependency.
class BookSyncService extends GetxService {
  static const Duration _updateCheckInterval = Duration(minutes: 1);
  static const Duration _requestTimeout = Duration(seconds: 30);
  static Timer? _updateTimer;
  static bool _isBooksChecking = false;

  // Book updates stream — BookCtrl listens to this and reloads the library.
  static final _bookUpdatesController = StreamController<void>.broadcast();
  static Stream<void> get onBooksUpdated => _bookUpdatesController.stream;

  // Last known status — readable from anywhere for debugging.
  static String lastBooksStatus = 'Never checked';

  /// Starts the automatic background update checker (every 1 minute).
  /// Call after the first frame (GetMaterialApp must exist for snackbars).
  static void startAutoUpdate() {
    if (kIsWeb) return; // Skip on web
    stopAutoUpdate(); // Cancel any existing timer
    debugPrint('Book Sync: Starting auto-update checker (every 1 minute)');
    checkForBookUpdates(); // Initial check
    _updateTimer = Timer.periodic(_updateCheckInterval, (timer) {
      checkForBookUpdates();
    });
  }

  /// Stops the automatic background update checker.
  static void stopAutoUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
    debugPrint('Book Sync: Stopped auto-update checker');
  }

  /// Gets the local path where downloaded book files are stored.
  static Future<String> getLocalBooksPath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, 'books');
  }

  /// URL for a server file. Each path segment is percent-encoded, so
  /// names with spaces or non-ASCII characters (e.g. the Mongolian
  /// filename) fetch correctly.
  static Uri fileUri(String relativePath) {
    final base = Uri.parse(BookServerConfig.baseUrl);
    return base.replace(
      pathSegments: [...base.pathSegments, ...relativePath.split('/')],
    );
  }

  /// Parses `manifest.json` — either a top-level list of file entries or
  /// an object with a `files` list. Keeps only supported book files
  /// (.json/.png/.jpg/.jpeg), deduplicated by local file name.
  /// Throws [FormatException] when the manifest has no file list.
  static List<BookManifestEntry> parseManifest(dynamic decoded) {
    final List<dynamic> raw;
    if (decoded is List) {
      raw = decoded;
    } else if (decoded is Map<String, dynamic> && decoded['files'] is List) {
      raw = decoded['files'] as List<dynamic>;
    } else {
      throw const FormatException('manifest.json has no file list');
    }
    final entries = <BookManifestEntry>[];
    final seenNames = <String>{};
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final entry = BookManifestEntry.fromJson(item);
      if (entry.relativePath.isEmpty || entry.relativePath == 'null') {
        continue;
      }
      final lower = entry.fileName.toLowerCase();
      final supported = lower.endsWith('.json') ||
          lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg');
      if (!supported) continue;
      if (!seenNames.add(entry.fileName)) continue;
      entries.add(entry);
    }
    return entries;
  }

  /// Downloads new or updated book files from the book server.
  /// Auto-discovers all .json/.png/.jpg files from the manifest — new
  /// books added to the server appear in the app on the next check.
  static Future<bool> checkForBookUpdates() async {
    if (kIsWeb || _isBooksChecking) return false;
    _isBooksChecking = true;
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      debugPrint(
          'Book Sync: Checking for new/updated book files at ${BookServerConfig.baseUrl}...');

      final manifestUri = fileUri('manifest.json');
      final request = await client.getUrl(manifestUri).timeout(
            _requestTimeout,
            onTimeout: () => throw TimeoutException(
                'manifest request timed out', _requestTimeout),
          );
      final response =
          await request.close().timeout(_requestTimeout);
      if (response.statusCode != HttpStatus.ok) {
        await response.drain<void>();
        lastBooksStatus =
            'Server returned HTTP ${response.statusCode} — ${DateTime.now()}';
        debugPrint('Book Sync: manifest HTTP ${response.statusCode}');
        return false;
      }
      final body = await response.transform(utf8.decoder).join().timeout(
            _requestTimeout,
            onTimeout: () => throw TimeoutException(
                'manifest read timed out', _requestTimeout),
          );
      final entries = parseManifest(jsonDecode(body));
      final jsonCount =
          entries.where((e) => e.fileName.toLowerCase().endsWith('.json')).length;
      final imageCount = entries.length - jsonCount;
      debugPrint(
          'Book Sync: Manifest lists $jsonCount book JSON(s) and $imageCount image(s)');

      // Ensure local books directory exists.
      final String localBooksPath = await getLocalBooksPath();
      final Directory localDir = Directory(localBooksPath);
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }

      // Mirror the local cache to server state: remove local files that
      // are no longer in the manifest, so deleted server books disappear.
      final Set<String> remoteBaseNames =
          entries.map((e) => e.fileName).toSet();
      int removedCount = 0;
      for (final f in localDir.listSync().whereType<File>()) {
        final localName = f.path.split('/').last;
        final lower = localName.toLowerCase();
        final isManagedType = lower.endsWith('.json') ||
            lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.tmp');
        if (!isManagedType) continue;
        if (!remoteBaseNames.contains(localName)) {
          await f.delete();
          removedCount++;
          debugPrint(
              'Book Sync: Removed local file missing on server: $localName');
        }
      }

      int updatedCount = 0;
      int skippedCount = 0;

      for (final entry in entries) {
        final String localFilePath =
            path.join(localBooksPath, entry.fileName);
        final File localFile = File(localFilePath);
        try {
          bool needsUpdate = true;
          if (await localFile.exists()) {
            final localStat = await localFile.stat();
            final sizeDiffers =
                entry.size != null && entry.size != localStat.size;
            final newerOnServer = entry.mtime != null &&
                entry.mtime!.isAfter(
                    localStat.modified.add(const Duration(seconds: 1)));
            needsUpdate = sizeDiffers || newerOnServer;
          }
          if (!needsUpdate) {
            skippedCount++;
            continue;
          }
          debugPrint('Book Sync: Downloading ${entry.fileName}...');
          final downloaded =
              await _downloadFile(client, entry, localFilePath);
          if (downloaded) {
            updatedCount++;
            debugPrint('Book Sync: Downloaded ${entry.fileName}');
          } else {
            debugPrint('Book Sync: Failed to download ${entry.fileName}');
          }
        } catch (e) {
          debugPrint('Book Sync: Error processing ${entry.fileName}: $e');
        }
      }

      debugPrint(
          'Book Sync: Done — Downloaded: $updatedCount, Removed: $removedCount, '
          'Unchanged: $skippedCount');

      if (updatedCount > 0 || removedCount > 0) {
        lastBooksStatus =
            'Downloaded $updatedCount, Removed $removedCount — ${DateTime.now()}';
        _bookUpdatesController.add(null); // notify library to reload
      } else {
        lastBooksStatus = 'All up to date — ${DateTime.now()}';
        debugPrint('Book Sync: All files up to date');
      }
      return updatedCount > 0 || removedCount > 0;
    } on TimeoutException catch (e) {
      lastBooksStatus = 'Timed out: $e';
      debugPrint('Book Sync: Timeout: $e');
      return false;
    } on SocketException catch (e) {
      lastBooksStatus = 'Connection error: ${e.message}';
      debugPrint('Book Sync: Connection error: ${e.message}');
      return false;
    } on HttpException catch (e) {
      lastBooksStatus = 'HTTP error: ${e.message}';
      debugPrint('Book Sync: HTTP error: ${e.message}');
      return false;
    } catch (e) {
      lastBooksStatus = 'Error: $e';
      debugPrint('Book Sync: Error: $e');
      return false;
    } finally {
      _isBooksChecking = false;
      client.close();
    }
  }

  /// Downloads one manifest entry to [localPath] via a temp file, so a
  /// failed or truncated download never replaces a good cached copy.
  /// Returns true when the file was written.
  static Future<bool> _downloadFile(
      HttpClient client, BookManifestEntry entry, String localPath) async {
    final tmpPath = '$localPath.tmp';
    final request = await client.getUrl(fileUri(entry.relativePath)).timeout(
          _requestTimeout,
          onTimeout: () =>
              throw TimeoutException('download timed out', _requestTimeout),
        );
    final response = await request.close().timeout(_requestTimeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      debugPrint(
          'Book Sync: HTTP ${response.statusCode} for ${entry.relativePath}');
      return false;
    }
    final bytes = await response
        .fold<List<int>>(<int>[], (acc, chunk) => acc..addAll(chunk))
        .timeout(_requestTimeout);
    // A truncated download must not replace a good cached copy.
    if (entry.size != null && bytes.length != entry.size) {
      debugPrint(
          'Book Sync: size mismatch for ${entry.fileName} '
          '(got ${bytes.length}, expected ${entry.size}), discarding');
      return false;
    }
    final tmpFile = File(tmpPath);
    await tmpFile.writeAsBytes(bytes, flush: true);
    await tmpFile.rename(localPath);
    if (entry.mtime != null) {
      try {
        await File(localPath).setLastModified(entry.mtime!);
      } catch (_) {
        // Best effort — a wrong local mtime only costs a re-download.
      }
    }
    return true;
  }

  /// Deletes all locally downloaded book files.
  static Future<void> clearLocalBookFiles() async {
    try {
      final String localPath = await getLocalBooksPath();
      final Directory dir = Directory(localPath);

      if (await dir.exists()) {
        await dir.delete(recursive: true);
        debugPrint('Book Sync: Local book files cleared');
      }
    } catch (e) {
      debugPrint('Book Sync: Error clearing local files: $e');
    }
  }
}
