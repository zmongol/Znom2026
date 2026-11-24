import 'dart:io';
import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/consttants.dart';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/widgets/book_rating.dart';
import 'package:book_app/widgets/two_side_rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';
import 'package:get/get.dart';
import '../global_controllers/books_ctrl.dart';

class ReadingListCard extends StatelessWidget {
  final Book book;

  final Function? pressDetails;
  final Function? pressRead;

  const ReadingListCard({
    super.key,
    required this.book,
    this.pressDetails,
    this.pressRead,
  });

  @override
  Widget build(BuildContext context) {
    final bookCtrl = Get.find<BookCtrl>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.only(left: 24, bottom: 40),
      // height: 248,
      width: 202,
      child: Stack(
        children: <Widget>[
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 221,
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(29),
                boxShadow: [
                  BoxShadow(
                    offset: Offset(0, 10),
                    blurRadius: 33,
                    color:
                        isDark ? Colors.black.withOpacity(0.5) : kShadowColor,
                  ),
                ],
              ),
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      _readingCardImage(book),
                      Row(
                        children: <Widget>[
                          IconButton(
                            icon: Icon(
                              Icons.favorite_border,
                            ),
                            onPressed: () {},
                          ),
                          BookRating(score: book.rating),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 130,
                    child: Obx(
                      () => MongolText(
                        "${book.title}\n",
                        style: TextStyle(
                          fontWeight: FontWeight.normal,
                          fontFamily: bookCtrl.fontFamily.value.isEmpty
                              ? MongolFonts.z52dardastig
                              : bookCtrl.fontFamily.value,
                          fontSize: 22,
                          color: isDark
                              ? Colors.white.withOpacity(0.95)
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: pressDetails as void Function()?,
                    child: Container(
                      width: 101,
                      padding: EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      child: Obx(
                        () => Text(
                          "ᢘᡭᡳᢚᡫ",
                          style: TextStyle(
                              fontFamily: bookCtrl.fontFamily.value.isEmpty
                                  ? MongolFonts.z52xanadutig
                                  : bookCtrl.fontFamily.value,
                              color: isDark
                                  ? Colors.white.withOpacity(0.9)
                                  : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: pressDetails as void Function()?,
                      child: TwoSideRoundedButton(
                        text: "ᠤᠩᠰᠢᠬᠤ",
                        press: pressRead,
                      ),
                    ),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }
}

Widget _readingCardImage(Book book) {
  if (book.localImagePath != null && book.localImagePath!.isNotEmpty) {
    return Image.file(
      File(book.localImagePath!),
      width: 100,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.book, size: 40, color: AppColors.primary),
    );
  }
  if (book.image.isNotEmpty) {
    return Image.asset(
      book.image,
      width: 100,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.book, size: 40, color: AppColors.primary),
    );
  }
  return const Icon(Icons.book, size: 40, color: AppColors.primary);
}
