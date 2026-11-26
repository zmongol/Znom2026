import 'dart:async';
import 'dart:io';
import 'package:book_app/core/services/font_service.dart';
import 'package:book_app/services/book_sync_service.dart';
import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/Component/app_theme.dart';
import 'package:book_app/dialogues/show_font_family_sheet.dart';
import 'package:book_app/dialogues/show_font_size_sheet.dart';
import 'package:book_app/extensions/storage_ext.dart';
import 'package:book_app/functions/load_book_json.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/services/access_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class BookCtrl extends GetxService {
  var booksList = <Book>[].obs;
  var randombooksList = <Book>[].obs;
  var appTheme = appLightTheme().obs;

  var isDarkMode = false.obs;

  static const double _baseContentFontSize = 22;

  var contentStyle = TextStyle().obs;

  var fontScale = 1.0.obs;
  var fontFamily = "".obs;

  /// Reader page background: 'white' | 'sepia' | 'dark'.
  var readerBackground = 'white'.obs;

  StreamSubscription<void>? _bookUpdateSub;
  bool _isLoading = false;
  bool _pendingReload = false;

  @override
  void onInit() {
    super.onInit();
    setUps();
    // Await via async helper so onInit itself stays synchronous
    _initialLoad();

    // Listen for new books downloaded from the book server
    _bookUpdateSub = BookSyncService.onBooksUpdated.listen((_) {
      debugPrint('BookCtrl: New books detected from book server — reloading library');
      reloadBooks().then((_) {
        Get.snackbar(
          'Library Updated',
          'New books downloaded from server.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      });
    });

    // Sync with global FontService: react to font changes from Home picker
    final fs = Get.find<FontService>();
    ever(fs.fontFamily, (String f) {
      if (fontFamily.value != f) {
        fontFamily.value = f;
        f.boxfontFamily;
        _updateContentStyle();
        _refreshTheme();
      }
    });
    // Also push the current FontService value if it differs from local storage
    if (fs.fontFamily.value.isNotEmpty &&
        fontFamily.value != fs.fontFamily.value) {
      fontFamily.value = fs.fontFamily.value;
      fs.fontFamily.value.boxfontFamily;
      _updateContentStyle();
      _refreshTheme();
    }
  }

  @override
  void onClose() {
    _bookUpdateSub?.cancel();
    super.onClose();
  }

  void setUps() {
    fontScale.value = double.tryParse("".boxfontScale) ?? 1;
    if (fontScale.value <= 0) {
      fontScale.value = 1;
      "1".boxfontScale;
    }
    final savedTheme = "".boxThemeMode;
    isDarkMode.value = savedTheme == "dark";
    readerBackground.value =
        GetStorage().read<String>('readerBg') ?? 'white';
    if ("".boxfontFamily.isEmpty) {
      final family = MongolFonts.fontList[0][0].toString();
      family.boxfontFamily;
      fontFamily.value = family;
    } else {
      fontFamily.value = "".boxfontFamily;
    }
    _refreshTheme();
    _updateContentStyle();
  }

  void _updateContentStyle() {
    print(fontFamily.value);
    final family = fontFamily.value.isEmpty
        ? Get.find<FontService>().fontFamily.value
        : fontFamily.value;
    final scale = fontScale.value <= 0 ? 1 : fontScale.value;

    contentStyle.value = TextStyle(
      fontFamily: family,
      fontSize: _baseContentFontSize * scale,
    );
  }

  void changeFontScale() {
    showFontSizeDialogue(
      selectedScale: fontScale.value,
      onTap: (val) {
        Get.back();
        fontScale.value = val;
        val.toString().boxfontScale;
        fontScale.refresh();
        _updateContentStyle();
      },
    );
  }

  void changeFontFamily() {
    showFontFamilyDialogue(
      selectedFamily: fontFamily.value,
      onTap: (val) {
        print("val.familyName : ${val.familyName} : ${val.mongolName}");
        Get.back();
        fontFamily.value = val.familyName;
        val.familyName.boxfontFamily;
        // Push to global FontService so Home picker stays in sync
        Get.find<FontService>().setFont(val.familyName);
        _updateContentStyle();
        _refreshTheme();
      },
    );
  }

  /// Applies a font family directly (used by the reader settings sheet,
  /// where the picker is embedded instead of opened as a dialogue).
  void setFontFamilyByName(String family) {
    fontFamily.value = family;
    family.boxfontFamily;
    Get.find<FontService>().setFont(family);
    _updateContentStyle();
    _refreshTheme();
  }

  /// Applies a font scale directly (reader settings sheet).
  void setFontScaleValue(double val) {
    fontScale.value = val;
    val.toString().boxfontScale;
    fontScale.refresh();
    _updateContentStyle();
  }

  void setReaderBackground(String value) {
    readerBackground.value = value;
    GetStorage().write('readerBg', value);
  }

  void toggleThemeMode() {
    isDarkMode.value = !isDarkMode.value;
    (isDarkMode.value ? "dark" : "light").boxThemeMode;
    _refreshTheme();
  }

  void _refreshTheme() {
    appTheme.value = isDarkMode.value
        ? appDarkTheme(fontFamily: fontFamily.value)
        : appLightTheme(fontFamily: fontFamily.value);
    appTheme.refresh();
  }

  Future<void> _initialLoad() async {
    await loadBooks();
  }

  Future<void> loadBooks() async {
    if (_isLoading) {
      // The book sync may have delivered books while we were already loading — mark for
      // a retry so the new files are not silently dropped.
      _pendingReload = true;
      debugPrint('BookCtrl: loadBooks already in progress, will retry after');
      return;
    }
    _isLoading = true;
    try {
      final booksFiles = await loadBookFiles();
      if (booksFiles.isEmpty) return;

      final List<Book> loaded = [];
      for (var bookfile in booksFiles) {
        final book = await loadBookJson(bookfile);
        if (book != null && book["items"] != null) {
          final dd = await compute<List<dynamic>, Book>(
              Book.fetch, (book["items"] as List<dynamic>));
          dd.sourceFile = bookfile.split('/').last;
          if (dd.title.trim().isEmpty) {
            final fallbackTitle =
                bookfile.split('/').last.replaceAll('.json', '');
            dd.title = fallbackTitle;
            debugPrint(
                'BookCtrl: empty title fallback to filename "$fallbackTitle"');
          }
          for (var i = 0; i < dd.chapters.length; i++) {
            final ch = dd.chapters[i];
            if (ch.chapterNumber == null || ch.chapterNumber == 0) {
              ch.chapterNumber = i + 1;
            }
            // An empty chapterTitle stays empty on purpose: display
            // sites fall back to "<chapter word> N" (UiStrings.chapter,
            // Z52) — never a Latin "Chapter N" and never the book title
            // masquerading as a chapter title.
          }
          await _checkAndSetLocalImage(dd, bookfile);
          loaded.add(dd);
          debugPrint(
              'BookCtrl: loaded book "${dd.title}" image=${dd.localImagePath ?? dd.image}');
        }
      }

      // Deduplicate by title — loadBookFiles() returns only server-synced
      // files now, so a duplicate can only come from two JSONs sharing a title.
      final Set<String> seenTitles = {};
      final List<Book> deduped = [];
      for (final b in loaded) {
        if (seenTitles.add(b.title)) deduped.add(b);
      }
      booksList.assignAll(deduped);
      randombooksList.assignAll(deduped);
      randombooksList.shuffle();
      // The sync may have delivered a new charging catalogue alongside
      // the books — pick it up whenever the library reloads.
      if (Get.isRegistered<AccessService>()) {
        Get.find<AccessService>().reloadCatalog();
      }
    } finally {
      _isLoading = false;
      // If a reload was requested while we were loading (e.g. FTP finished),
      // run it now that the lock is released.
      if (_pendingReload) {
        _pendingReload = false;
        debugPrint('BookCtrl: running deferred reload after book-server sync');
        loadBooks();
      }
    }
  }

  Future<void> _checkAndSetLocalImage(Book book, String bookFilePath) async {
    try {
      // All books are server-synced local files, so all paths are absolute
      if (!bookFilePath.startsWith('/')) return;

      final String bookDir =
          bookFilePath.substring(0, bookFilePath.lastIndexOf('/'));

      // 1. Primary: match by JSON base name — check all three extensions in
      //    parallel to avoid sequential round-trips for each await.
      final String jsonBase =
          bookFilePath.split('/').last.replaceAll('.json', '');
      const primaryExts = ['.png', '.jpg', '.jpeg'];
      final primaryPaths =
          primaryExts.map((e) => '$bookDir/$jsonBase$e').toList();
      final primaryResults = await Future.wait(
        primaryPaths.map((p) => File(p).exists()),
      );
      final primaryIdx = primaryResults.indexOf(true);
      if (primaryIdx != -1) {
        book.setLocalImagePath(primaryPaths[primaryIdx]);
        debugPrint(
            'BookCtrl: image matched by JSON name at ${primaryPaths[primaryIdx]}');
        return;
      }

      // 2. Secondary: use the "image" field value as a bare filename.
      //    The JSON stores it as an asset-style path (e.g.
      //    "assets/images/book1.png"), but the cover itself is a server
      //    file downloaded into this same dir — so match on the bare
      //    filename whatever prefix the field carries.
      if (book.image.isNotEmpty) {
        final imageBaseName = book.image.split('/').last;
        final imagePath = '$bookDir/$imageBaseName';
        if (await File(imagePath).exists()) {
          book.setLocalImagePath(imagePath);
          debugPrint('BookCtrl: image from book.image field at $imagePath');
          return;
        }
      }

      debugPrint(
          'BookCtrl: no local image found for "${book.title}" (dir=$bookDir, base=$jsonBase)');
    } catch (e) {
      print('Error checking local image: $e');
    }
  }

  Future<void> reloadBooks() async {
    // loadBooks() guards itself with _isLoading, so just call it directly.
    // It uses assignAll() which atomically replaces the list.
    await loadBooks();
  }
}
