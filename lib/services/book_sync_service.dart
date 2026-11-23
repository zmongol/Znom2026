import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'ftp_secrets.dart';

/// Syncs book JSON + cover images from the user's own Mac Mini FTP server.
///
/// Server endpoint — ONE configurable constant:
///   [FtpSecrets.host] (default '100.127.70.29', the Mini's Tailscale address)
///   with [FtpSecrets.port] (21), [FtpSecrets.user], [FtpSecrets.password].
/// To point the sync at a different server, edit lib/services/ftp_secrets.dart
/// (git-ignored; see ftp_secrets.dart.template). The Mini is Tailscale-private,
/// so phones outside the Tailscale network cannot reach it yet — public
/// reachability is a separate later step.
///
/// Adapted from the Zmongol flagship's FTPUpdateService (books part only;
/// the calendar sync was dropped). Sync is best-effort background work:
/// failures are logged to [lastBooksStatus] and never pop up UI, and the
/// library reloads only when files actually changed.
class BookSyncService extends GetxService {
  // FTP credentials loaded from ftp_secrets.dart (git-ignored).
  static const String _ftpHost = FtpSecrets.host;
  static const int _ftpPort = FtpSecrets.port;
  static const String _ftpUser = FtpSecrets.user;
  static const String _ftpPassword = FtpSecrets.password;

  // Remote book directories on the Mini server.
  static const List<String> _remoteBooksDirectories = [
    '/Znom/js',
    '/Znom/js/output',
  ];

  static const Duration _updateCheckInterval = Duration(minutes: 1);
  static Timer? _updateTimer;
  static bool _isBooksChecking = false;
  // Stale (corrupted) images are cleaned up on the first successful sync only.
  static bool _staleImagesCleaned = false;

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

  /// Gets the local path where downloaded book JSON files are stored.
  static Future<String> getLocalBooksPath() async {
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    return path.join(appDocDir.path, 'books');
  }

  /// Downloads new or updated book JSON files from the Mini FTP server.
  /// Auto-discovers all .json/.png/.jpg files on the server — new books added
  /// to the server appear in the app on the next check.
  static Future<bool> checkForBookUpdates() async {
    if (kIsWeb || _isBooksChecking) return false;
    if (_ftpHost.isEmpty || _ftpUser.isEmpty || _ftpPassword.isEmpty) {
      lastBooksStatus = 'ERROR: FTP credentials not configured';
      debugPrint('Book Sync: Credentials not configured, skipping');
      return false;
    }

    _isBooksChecking = true;

    try {
      debugPrint('Book Sync: Checking for new/updated book files...');

      final ftpConnect = FTPConnect(
        _ftpHost,
        port: _ftpPort,
        user: _ftpUser,
        pass: _ftpPassword,
        timeout: 30,
      );

      await ftpConnect.connect();
      // Binary mode is required for image files — ASCII mode corrupts PNGs.
      await ftpConnect.setTransferType(TransferType.binary);

      // Discover book files in known remote folders. This supports server
      // layouts where generated files are uploaded under /output.
      final List<Map<String, dynamic>> remoteBookFiles = [];
      final Set<String> seenRemoteKeys = {};

      for (final remoteDir in _remoteBooksDirectories) {
        final bool dirChanged = await ftpConnect.changeDirectory(remoteDir);
        if (!dirChanged) {
          debugPrint('Book Sync: Directory not found: $remoteDir');
          continue;
        }

        final remoteFiles = await ftpConnect.listDirectoryContent();
        for (final f in remoteFiles) {
          final n = f.name.toLowerCase();
          final isSupported = n.endsWith('.json') ||
              n.endsWith('.png') ||
              n.endsWith('.jpg') ||
              n.endsWith('.jpeg');
          if (!isSupported) continue;

          final key = '$remoteDir/${f.name}';
          if (seenRemoteKeys.add(key)) {
            remoteBookFiles.add({'dir': remoteDir, 'file': f});
          }
        }
      }

      final jsonCount = remoteBookFiles
          .where((e) => (e['file'] as dynamic)
              .name
              .toString()
              .toLowerCase()
              .endsWith('.json'))
          .length;
      final imageCount = remoteBookFiles.where((e) {
        final name = (e['file'] as dynamic).name.toString().toLowerCase();
        return name.endsWith('.png') ||
            name.endsWith('.jpg') ||
            name.endsWith('.jpeg');
      }).length;
      debugPrint(
          'Book Sync: Found $jsonCount book JSON(s) and $imageCount image(s) '
          'across ${_remoteBooksDirectories.length} folder(s)');

      // Ensure local books directory exists.
      final String localBooksPath = await getLocalBooksPath();
      final Directory localDir = Directory(localBooksPath);
      if (!await localDir.exists()) {
        await localDir.create(recursive: true);
      }

      // Delete any existing local images once per app session to replace
      // corrupted files from a previous ASCII-mode download.
      if (!_staleImagesCleaned) {
        for (final f in localDir.listSync().whereType<File>()) {
          final n = f.path.toLowerCase();
          if (n.endsWith('.png') || n.endsWith('.jpg') || n.endsWith('.jpeg')) {
            await f.delete();
            debugPrint(
                'Book Sync: Removed stale image ${f.path.split('/').last}');
          }
        }
        _staleImagesCleaned = true;
      }

      // Mirror local FTP cache to server state: remove local files that are
      // no longer present on FTP, so deleted server books disappear in app.
      final Set<String> remoteBaseNames = remoteBookFiles
          .map((e) => (e['file'] as dynamic).name.toString())
          .toSet();
      int removedCount = 0;
      for (final f in localDir.listSync().whereType<File>()) {
        final localName = f.path.split('/').last;
        final lower = localName.toLowerCase();
        final isManagedType = lower.endsWith('.json') ||
            lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg');
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

      String? activeRemoteDir;
      for (final remoteRef in remoteBookFiles) {
        final String remoteName =
            (remoteRef['file'] as dynamic).name.toString();
        try {
          final String remoteDir = remoteRef['dir'] as String;
          final dynamic remoteFile = remoteRef['file'];

          if (activeRemoteDir != remoteDir) {
            final bool moved = await ftpConnect.changeDirectory(remoteDir);
            if (!moved) {
              debugPrint('Book Sync: Failed to enter directory: $remoteDir');
              continue;
            }
            activeRemoteDir = remoteDir;
          }

          final String localFilePath =
              path.join(localBooksPath, remoteFile.name);
          final File localFile = File(localFilePath);

          bool needsUpdate = true;

          if (await localFile.exists()) {
            final localStat = await localFile.stat();
            // Use modifyTime if available, fall back to size.
            final remoteModified = remoteFile.modifyTime;
            if (remoteModified != null) {
              if (!remoteModified.isAfter(localStat.modified)) {
                needsUpdate = false;
                skippedCount++;
              }
            } else if (remoteFile.size == localStat.size) {
              needsUpdate = false;
              skippedCount++;
            }
          }

          if (needsUpdate) {
            debugPrint('Book Sync: Downloading ${remoteFile.name}...');
            final bool downloaded =
                await ftpConnect.downloadFile(remoteFile.name, localFile);
            if (downloaded) {
              updatedCount++;
              debugPrint('Book Sync: Downloaded ${remoteFile.name}');
            } else {
              debugPrint('Book Sync: Failed to download ${remoteFile.name}');
            }
          }
        } catch (e) {
          debugPrint('Book Sync: Error processing $remoteName: $e');
        }
      }

      await ftpConnect.disconnect();

      debugPrint(
          'Book Sync: Done — Downloaded: $updatedCount, Removed: $removedCount, '
          'Unchanged: $skippedCount');

      _isBooksChecking = false;
      if (updatedCount > 0 || removedCount > 0) {
        lastBooksStatus =
            'Downloaded $updatedCount, Removed $removedCount — ${DateTime.now()}';
        _bookUpdatesController.add(null); // notify library to reload
      } else {
        lastBooksStatus = 'All up to date — ${DateTime.now()}';
        debugPrint('Book Sync: All files up to date');
      }
      return updatedCount > 0 || removedCount > 0;
    } on FTPConnectException catch (e) {
      lastBooksStatus = 'Connection error: ${e.message}';
      debugPrint('Book Sync: FTP Connection Error: ${e.message}');
      _isBooksChecking = false;
      return false;
    } catch (e) {
      lastBooksStatus = 'Error: $e';
      debugPrint('Book Sync: Error: $e');
      _isBooksChecking = false;
      return false;
    }
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
