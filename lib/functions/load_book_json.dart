import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
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

  // Load asset files
  files.addAll([
    'assets/json/Compendium of Chronicles.json',
    'assets/json/LookingForBook.json',
    'assets/json/SecretHistoryOfMongols.json',
    'assets/json/ᠭᠠᠩᠭ᠎ᠠ_ᠢᠨ_ᠤᠷᠤᠰᠬᠠᠯ.json',
  ]);

  // Load downloaded files from app documents
  try {
    final appDir = await getApplicationDocumentsDirectory();
    final booksDir = Directory('${appDir.path}/books');

    if (await booksDir.exists()) {
      final fileList = booksDir.listSync();
      for (var file in fileList) {
        if (file.path.endsWith('.json')) {
          files.add(file.path);
        }
      }
    }
  } catch (e) {
    print('Error loading downloaded book files: $e');
  }

  return files;
}
