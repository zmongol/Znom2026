import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<Map<String, dynamic>?> loadBookJson(String path) async {
  try {
    // All books are local files downloaded from the book server; there are
    // no bundled book assets any more, so only absolute file paths load.
    if (!path.startsWith('/')) return null;
    final file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>?;
    }
    return null;
  } catch (e) {
    print('Error loading book from $path: $e');
    return null;
  }
}

/// The library loads ONLY from the local books dir — files downloaded from
/// the book server by BookSyncService. Books already downloaded keep
/// working offline, and the library shows them even when the server is
/// unreachable. On a fresh install with no server reach yet this returns
/// an empty list (the home screen explains that no books are downloaded
/// yet) — never a crash.
Future<List<String>> loadBookFiles() async {
  final List<String> files = [];
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
  files.sort();
  return files;
}
