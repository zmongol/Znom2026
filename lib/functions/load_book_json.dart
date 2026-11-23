import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:path_provider/path_provider.dart';

Future<Map<String, dynamic>?> loadBookJson(String path) async {
  try {
    // Check if it's a local file path (not an asset)
    if (path.startsWith('/')) {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content) as Map<String, dynamic>?;
      }
      return null;
    }
    // Load from assets
    return jsonDecode(await rootBundle.loadString(path))
        as Map<String, dynamic>?;
  } catch (e) {
    print('Error loading book from $path: $e');
    return null;
  }
}

Future<String?> readAssetFile(String path) async {
  try {
    final dd = await rootBundle.loadString(path);
    print("dd : $dd");
    return dd;
  } catch (e) {
    print("dd : $e");
    return null;
  }
}

Future<List<String>> loadBookFiles() async {
  List<String> files = [];

  // FTP-downloaded files first (they take priority over bundled assets)
  final Set<String> downloadedBaseNames = {};
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${appDir.path}/books');

    if (await booksDir.exists()) {
      final fileList = booksDir.listSync();
      for (var file in fileList) {
        if (file.path.endsWith('.json')) {
          files.add(file.path);
          // Track base filenames to skip duplicates from assets
          downloadedBaseNames.add(file.path.split('/').last);
        }
      }
    }
  } catch (e) {
    print('Error loading downloaded book files: $e');
  }

  // Discover bundled asset books dynamically via AssetManifest — no hardcoded
  // list means new books added to assets/json/books/ appear automatically,
  // and Unicode filename mismatches can no longer silently drop books.
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final assetPaths = manifest
        .listAssets()
        .where((p) => p.startsWith('assets/json/books/') && p.endsWith('.json'))
        .toList();
    for (final assetPath in assetPaths) {
      // AssetManifest paths are URL-encoded in the real app; decode for the
      // rootBundle key. In tests the manifest returns raw Unicode paths, and
      // Uri.decodeFull rejects some of them (e.g. U+180E in a filename) —
      // fall back to the raw path instead of dropping the whole library.
      String decoded;
      try {
        decoded = Uri.decodeFull(assetPath);
      } catch (_) {
        decoded = assetPath;
      }
      final baseName = decoded.split('/').last;
      if (!downloadedBaseNames.contains(baseName)) {
        files.add(decoded);
      }
    }
  } catch (e) {
    print('Error discovering asset books from manifest: $e');
  }

  return files;
}
