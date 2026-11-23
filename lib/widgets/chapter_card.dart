import 'package:book_app/models/books/book_chapter_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';
import 'package:book_app/core/services/font_service.dart';

class ChapterCard extends StatelessWidget {
  final BookChapter chapter;
  final Function() press;
  const ChapterCard({
    super.key,
    required this.chapter,
    required this.press,
  });

  @override
  Widget build(BuildContext context) {
    // var size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: press,
      child: Row(
        children: [
          SizedBox(
            width: 10,
          ),
          Container(
            decoration: BoxDecoration(
                border: Border.all(
                    color: isDark
                        ? Colors.grey.shade700
                        : Color.fromARGB(255, 164, 166, 168)),
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(10)),
            child: Container(
              height: 280,
              margin: EdgeInsets.fromLTRB(0, 8, 0, 8),
              child: RotatedBox(
                quarterTurns: 0,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: MongolText(
                      'ᡴᡭᡬᢑᡭᡬᡨ ${chapter.chapterNumber} : \n${chapter.chapterTitle}',
                      maxLines: 2,
                      style: TextStyle(
                          color: isDark
                              ? Colors.white.withOpacity(0.95)
                              : Colors.black,
                          fontFamily:
                              Get.find<FontService>().fontFamily.value.isEmpty
                                  ? null
                                  : Get.find<FontService>().fontFamily.value)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
