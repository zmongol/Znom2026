import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/screens/image_reading_screen.dart';
import 'package:book_app/screens/reading_screen.dart';
import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';
import 'package:get/get.dart';

import '../Component/MongolFonts.dart';
import '../consttants.dart';
import '../global_controllers/books_ctrl.dart';
import 'book_card.dart';

class BookInfo extends StatelessWidget {
  final Book book;
  final _bookCtrl = Get.find<BookCtrl>();

  BookInfo({
    super.key,
    this.size,
    required this.book,
  });

  final Size? size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 280,
      child: Row(
        children: [
          Obx(
            () => MongolText(
              book.title,
              maxLines: 2,
              style: TextStyle(
                  fontSize: 28,
                  color: isDark ? Colors.white.withOpacity(0.95) : Colors.black,
                  fontFamily: _bookCtrl.fontFamily.value.isEmpty
                      ? MongolFonts.z52dardastig
                      : _bookCtrl.fontFamily.value),
            ),
          ),
          Obx(
            () => MongolText(
              book.content,
              maxLines: 7,
              style: TextStyle(
                fontSize: 10,
                fontFamily: _bookCtrl.fontFamily.value.isEmpty
                    ? null
                    : _bookCtrl.fontFamily.value,
                color:
                    isDark ? Colors.white.withOpacity(0.7) : kLightBlackColor,
              ),
            ),
          ),
          Column(
            children: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.favorite_border,
                  size: 20,
                  color: isDark ? Colors.white70 : Colors.grey,
                ),
                onPressed: () {},
              ),
              SizedBox(height: 10),
              // TextBox decoration
              GestureDetector(
                onTap: () {
                  if (book.chapters.isEmpty) return;
                  // Image books open the page-image reader; text books
                  // open the text reader.
                  if (book.isImageBook) {
                    ImageReadingScreen.open(context, book);
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReadingScreen(
                        book: book,
                        chapterIndex: 0,
                      ),
                    ), //Go to Donation page
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: isDark ? Colors.grey.shade600 : Colors.white),
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10)),
                  child: Container(
                    height: 80,
                    margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
                    child: RotatedBox(
                      quarterTurns: 0,
                      child: Align(
                        alignment: Alignment.center,
                        child: Obx(
                          () => MongolText('ᡥᡭᡪᢊᢔᡬᡫᡨ',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: _bookCtrl.fontFamily.value.isEmpty
                                      ? null
                                      : _bookCtrl.fontFamily.value)),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            ],
          ),
          Expanded(
              flex: 1,
              child: Container(
                color: Colors.transparent,
                child: _bookCoverImage(book),
              )),
        ],
      ),
    );
  }
}

/// Returns the book cover image: the downloaded local file, or the
/// logo placeholder when the cover has not been downloaded yet.
Widget _bookCoverImage(Book book) => BookCoverImage(book: book);
