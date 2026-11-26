import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/core/constants/ui_strings.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/services/access_service.dart';
import 'package:book_app/widgets/chapter_card.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../Component/find_ctrls.dart';
import '../Component/MongolFonts.dart';
import '../widgets/bounded_mongol_text.dart';

/// Chapter picker for the text reader. Chapters whose titles carry a
/// volume prefix ("1 - 01" … "4 - 18", as the 91-chapter novel does)
/// are grouped by volume; other books get one flat group. The current
/// chapter is outlined in the brand colour. Pops with the chosen
/// chapter index, or null when dismissed.
class ChapterPickerScreen extends StatelessWidget {
  final Book book;
  final int currentChapter;
  const ChapterPickerScreen({
    super.key,
    required this.book,
    required this.currentChapter,
  });

  /// Groups of (volume number or null, chapter indices).
  List<(int?, List<int>)> get _groups {
    final volumeOf = <int, int?>{};
    final volumes = <int>{};
    final pattern = RegExp(r'^(\d+)\s*-');
    for (var i = 0; i < book.chapters.length; i++) {
      final m = pattern.firstMatch(book.chapters[i].chapterTitle ?? '');
      volumeOf[i] = m == null ? null : int.parse(m.group(1)!);
      if (m != null) volumes.add(int.parse(m.group(1)!));
    }
    if (volumes.length < 2) {
      return [(null, List.generate(book.chapters.length, (i) => i))];
    }
    final groups = <(int?, List<int>)>[];
    for (var i = 0; i < book.chapters.length; i++) {
      final v = volumeOf[i];
      if (groups.isEmpty || groups.last.$1 != v) {
        groups.add((v, [i]));
      } else {
        groups.last.$2.add(i);
      }
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final bookCtrl = FindCtrl.book;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Row(
          children: [
            SizedBox(
              width: 130,
              child: Obx(
                () => BoundedMongolText(
                  UiStrings.chapters,
                  maxHeight: 42,
                  maxColumns: 5,
                  style: TextStyle(
                    fontFamily: bookCtrl.fontFamily.value.isEmpty
                        ? MongolFonts.z52dardastig
                        : bookCtrl.fontFamily.value,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Chapters',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          for (final group in _groups) ...[
            if (group.$1 != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 70,
                      child: Obx(
                        () => BoundedMongolText(
                          UiStrings.volume,
                          maxHeight: 40,
                          style: TextStyle(
                            fontFamily: bookCtrl.fontFamily.value.isEmpty
                                ? MongolFonts.z52dardastig
                                : bookCtrl.fontFamily.value,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Volume ${group.$1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: group.$2.length,
                itemBuilder: (context, j) {
                  final index = group.$2[j];
                  final isCurrent = index == currentChapter;
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    decoration: isCurrent
                        ? BoxDecoration(
                            border: Border.all(
                                color: AppColors.primary, width: 2.5),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: ChapterCard(
                      chapter: book.chapters[index],
                      locked: !AccessService.canOpenChapter(book, index),
                      press: () => Navigator.pop(context, index),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
