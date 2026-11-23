import 'dart:io';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/screens/reading_screen.dart';
import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';
import 'package:get/get.dart';

import '../Component/MongolFonts.dart';
import '../consttants.dart';
import '../global_controllers/books_ctrl.dart';
import 'book_rating.dart';

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
              BookRating(score: 4.9),
              SizedBox(height: 10),
              // TextBox decoration
              GestureDetector(
                onTap: () {
                  if (book.chapters.isEmpty) return;
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
                      color: isDark
                          ? Color(0xFF3A3F47)
                          : Color.fromARGB(255, 143, 146, 148),
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

    // return Container(
    //   child: Flex(
    //     crossAxisAlignment: CrossAxisAlignment.start,
    //     direction: Axis.horizontal,
    //     children: <Widget>[
    //       Expanded(
    //           flex: 1,
    //           child: Column(
    //             children: <Widget>[
    //               Container(
    //                 alignment: Alignment.centerLeft,
    //                 child: Text(
    //                   "Crushing &",
    //                   style: Theme.of(context)
    //                       .textTheme
    //                       .headline4
    //                       .copyWith(fontSize: 28),
    //                 ),
    //               ),
    //               Row(
    //                 children: <Widget>[
    //                   Column(
    //                     crossAxisAlignment: CrossAxisAlignment.center,
    //                     children: <Widget>[
    //                       Container(
    //                         width: this.size.width * .3,
    //                         padding:
    //                             EdgeInsets.only(top: this.size.height * .02),
    //                         child: Container(
    //                           height: 150,
    //                           child: MongolText(
    //                             "When the earth was flat andeveryone wanted to win the gameof the best and people and winning with an A game with all the things you have.",
    //                             maxLines: 5,
    //                             style: TextStyle(
    //                               fontSize: 10,
    //                               color: kLightBlackColor,
    //                             ),
    //                           ),
    //                         ),
    //                       ),
    //                       Container(
    //                         margin:
    //                             EdgeInsets.only(top: this.size.height * .015),
    //                         padding: EdgeInsets.only(left: 10, right: 10),
    //                         decoration: BoxDecoration(
    //                           color: Colors.white,
    //                           borderRadius: BorderRadius.circular(30),
    //                         ),
    //                         child: ElevatedButton(
    //                           onPressed: () {},
    //                           child: MongolText(
    //                             "ᡥᡭᡪᢊᢔᡬᡪᡪᡳ",
    //                             style: TextStyle(fontWeight: FontWeight.bold, fontFamily: MongolFonts.z52ordostig),
    //                           ),
    //                         ),
    //                       )
    //                     ],
    //                   ),
    //                   Column(
    //                     children: <Widget>[
    //                       IconButton(
    //                         icon: Icon(
    //                           Icons.favorite_border,
    //                           size: 20,
    //                           color: Colors.grey,
    //                         ),
    //                         onPressed: () {},
    //                       ),
    //                       BookRating(score: 4.9),
    //                     ],
    //                   )
    //                 ],
    //               )
    //             ],
    //           )),
    //       Expanded(
    //           flex: 1,
    //           child: Container(
    //             color: Colors.transparent,
    //             child: Image.asset(
    //               "assets/images/book-1.png",
    //               height: double.infinity,
    //               alignment: Alignment.topRight,
    //               fit: BoxFit.fitWidth,
    //             ),
    //           )),
    //     ],
    //   ),
    // );
  }
}

/// Returns the book cover image: local file (FTP download) preferred over asset.
Widget _bookCoverImage(Book book) {
  if (book.localImagePath != null && book.localImagePath!.isNotEmpty) {
    return Image.file(
      File(book.localImagePath!),
      height: double.infinity,
      alignment: Alignment.topRight,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => _bookImagePlaceholder(),
    );
  }
  // Only use Image.asset for bundled assets — FTP books have bare filenames
  if (book.image.isNotEmpty && book.image.startsWith('assets/')) {
    return Image.asset(
      book.image,
      height: double.infinity,
      alignment: Alignment.topRight,
      fit: BoxFit.fitWidth,
      errorBuilder: (_, __, ___) => _bookImagePlaceholder(),
    );
  }
  return _bookImagePlaceholder();
}

Widget _bookImagePlaceholder() => Container(
      color: const Color(0xFF6C5CE7).withValues(alpha: 0.1),
      child: const Center(
        child: Icon(Icons.book, size: 40, color: Color(0xFF6C5CE7)),
      ),
    );
