import 'package:get_storage/get_storage.dart';

final _box = GetStorage();

extension KbGetStorageExt on String {
  String get boxfontScale => _finder("boxfontScale");
  String get boxfontFamily => _finder("boxfontFamily");
  String get boxThemeMode => _finder("boxThemeMode");

  String _finder(String key) {
    if (isNotEmpty) {
      if (this == "--") {
        _box.write(key, '');
      } else {
        _box.write(key, this);
      }
    }

    return _box.read(key) ?? "";
  }
}

/// Saves and restores reading progress: scroll offset + chapter per book.
/// Key format: "readprog_{bookTitle}"  →  "{chapterIndex}:{scrollOffset}"
class ReadingProgress {
  static String _key(String bookTitle) => 'readprog_$bookTitle';

  /// Save progress for a book.
  static void save(String bookTitle, int chapterIndex, double scrollOffset) {
    _box.write(_key(bookTitle), '$chapterIndex:$scrollOffset');
  }

  /// Returns saved [chapterIndex, scrollOffset] or null if no progress saved.
  static (int chapter, double scroll)? load(String bookTitle) {
    final raw = _box.read<String>(_key(bookTitle));
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final chapter = int.tryParse(parts[0]);
    final scroll = double.tryParse(parts[1]);
    if (chapter == null || scroll == null) return null;
    return (chapter, scroll);
  }

  /// Clear saved progress for a book.
  static void clear(String bookTitle) {
    _box.remove(_key(bookTitle));
  }
}
