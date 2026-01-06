import 'dart:io';
import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/Component/app_theme.dart';
import 'package:book_app/dialogues/show_font_family_sheet.dart';
import 'package:book_app/dialogues/show_font_size_sheet.dart';
import 'package:book_app/extensions/storage_ext.dart';
import 'package:book_app/functions/load_book_json.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

class BookCtrl extends GetxService {
  var booksList = <Book>[].obs;
  var randombooksList = <Book>[].obs;
  var appTheme = appLightTheme().obs;

  var isDarkMode = false.obs;

  static const double _baseContentFontSize = 22;

  var contentStyle = TextStyle().obs;

  var fontScale = 1.0.obs;
  var fontFamily = "".obs;

  @override
  void onInit() {
    setUps();
    loadBooks();
    super.onInit();
  }

  void setUps() {
    fontScale.value = double.tryParse("".boxfontScale) ?? 1;
    if (fontScale.value <= 0) {
      fontScale.value = 1;
      "1".boxfontScale;
    }
    final savedTheme = "".boxThemeMode;
    isDarkMode.value = savedTheme == "dark";
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
    final family =
        fontFamily.value.isEmpty ? MongolFonts.z52ordostig : fontFamily.value;
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
        _updateContentStyle();
        _refreshTheme();
      },
    );
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

  Future<void> loadBooks() async {
    final booksFiles = await loadBookFiles();
    if (booksFiles.isEmpty) return;
    for (var bookfile in booksFiles) {
      final book = await loadBookJson(bookfile);

      if (book != null && book["items"] != null) {
        final dd = await compute<List<dynamic>, Book>(
            Book.fetch, (book["items"] as List<dynamic>));

        // Check for local downloaded image
        await _checkAndSetLocalImage(dd, bookfile);

        booksList.add(dd);
        randombooksList.add(dd);
      }
    }

    //

    randombooksList.shuffle();
  }

  Future<void> _checkAndSetLocalImage(Book book, String bookFilePath) async {
    try {
      // Get book name from file path
      String fileName = bookFilePath.split('/').last.replaceAll('.json', '');
      String imageName = '$fileName.png';

      // Check if it's a downloaded file
      if (bookFilePath.startsWith('/')) {
        final appDir = await getApplicationDocumentsDirectory();
        final imagePath = '${appDir.path}/book_images/$imageName';
        final imageFile = File(imagePath);

        if (await imageFile.exists()) {
          book.setLocalImagePath(imagePath);
        }
      }
    } catch (e) {
      print('Error checking local image: $e');
    }
  }

  Future<void> reloadBooks() async {
    // Clear existing lists
    booksList.clear();
    randombooksList.clear();

    // Reload all books
    await loadBooks();

    // Notify observers
    booksList.refresh();
    randombooksList.refresh();
  }
}
