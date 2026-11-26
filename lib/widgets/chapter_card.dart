import 'package:book_app/models/books/book_chapter_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';
import 'package:book_app/core/services/font_service.dart';

class ChapterCard extends StatelessWidget {
  final BookChapter chapter;
  final Function() press;

  /// Locked chapters (paid content past the free preview) are dimmed
  /// and badged with a lock; [press] still fires so the caller can
  /// route to the paywall.
  final bool locked;
  const ChapterCard({
    super.key,
    required this.chapter,
    required this.press,
    this.locked = false,
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
              child: Stack(
                children: [
                  RotatedBox(
                    quarterTurns: 0,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ClipRect(
                        child: MongolText(
                            'ᡴᡭᡬᢑᡭᡬᡨ ${chapter.chapterNumber} : \n${chapter.chapterTitle}',
                            maxLines: 2,
                            style: TextStyle(
                                color: locked
                                    ? (isDark
                                        ? Colors.white38
                                        : Colors.black38)
                                    : isDark
                                        ? Colors.white.withOpacity(0.95)
                                        : Colors.black,
                            fontFamily: Get.find<FontService>()
                                    .fontFamily
                                    .value
                                    .isEmpty
                                ? null
                                : Get.find<FontService>().fontFamily.value)),
                      ),
                    ),
                  ),
                  if (locked)
                    const Positioned(
                      top: 6,
                      right: 6,
                      child: Icon(
                        Icons.lock,
                        size: 16,
                        color: Colors.black45,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
