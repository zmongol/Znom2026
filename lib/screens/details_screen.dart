import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/core/constants/ui_strings.dart';
import 'package:book_app/extensions/storage_ext.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/screens/image_reading_screen.dart';
import 'package:book_app/screens/paywall_screen.dart';
import 'package:book_app/screens/reading_screen.dart';
import 'package:book_app/services/access_service.dart';
import 'package:book_app/widgets/book_card.dart';
import 'package:book_app/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:get/get.dart';

import '../Component/find_ctrls.dart';
import '../Component/MongolFonts.dart';
import '../widgets/bounded_mongol_text.dart';
import '../widgets/book_info.dart';
import '../widgets/chapter_card.dart';
import 'Donate.dart';

final _bookCtrl = FindCtrl.book;

class DetailsScreen extends StatelessWidget {
  final Book book;

  const DetailsScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        // Book title upright in vertical columns fitted to the bar —
        // never sideways in a plain Text.
        title: Obx(
          () => BoundedMongolText(
            book.title,
            maxHeight: 42,
            maxColumns: 8,
            minFontSize: 8,
            style: TextStyle(
                fontFamily: _bookCtrl.fontFamily.value.isEmpty
                    ? MongolFonts.z52dardastig
                    : _bookCtrl.fontFamily.value,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white),
          ),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite,
                color: Colors.white), //Go to Donation page
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Donation()), //Go to Donation page
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                Container(
                  alignment: Alignment.topCenter,
                  padding: EdgeInsets.only(
                      top: size.height * .12,
                      left: size.width * .1,
                      right: size.width * .02),
                  // height: size.height * .48,
                  height: size.height * 0.48,
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? LinearGradient(
                            colors: [Color(0xFF1A1D23), Color(0xFF2A2E35)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    image: isDark
                        ? null
                        : DecorationImage(
                            image: AssetImage("assets/images/bg.png"),
                            fit: BoxFit.fitWidth,
                          ),
                    color: isDark ? null : null,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(50),
                      bottomRight: Radius.circular(50),
                    ),
                  ),
                  child: BookInfo(
                    size: size,
                    book: book,
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsets.only(top: size.height * .48 - 20, right: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.only(right: 60),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: book.chapters
                          .mapIndexed(
                            (e, i) => ChapterCard(
                              chapter: e,
                              locked:
                                  !AccessService.canOpenChapter(book, i),
                              press: () {
                                // Image books open the page-image reader;
                                // text books open the text reader.
                                if (book.isImageBook) {
                                  ImageReadingScreen.open(context, book);
                                  return;
                                }
                                // Paid chapters past the free preview
                                // route to the paywall instead.
                                if (!AccessService.canOpenChapter(book, i)) {
                                  PaywallScreen.open(context, book);
                                  return;
                                }
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReadingScreen(
                                      book: book,
                                      chapterIndex: i,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: 40),
                  // ── Continue Reading banner ──────────────────────────────
                  _ContinueReadingBanner(book: book),
                  const SectionHeader(
                    z52: UiStrings.featuredBooks,
                    english: 'Featured Books',
                  ),
                  SizedBox(height: 16),
                  // Books Grid
                  Obx(
                    () => GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.12,
                      ),
                      itemCount: _bookCtrl.booksList.length,
                      itemBuilder: (context, index) {
                        final bookItem = _bookCtrl.booksList[index];
                        return BookCard(
                          book: bookItem,
                          onTap: () {
                            _bookCtrl.randombooksList.shuffle();
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DetailsScreen(book: bookItem),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a "Continue Reading" card when the user has saved progress for [book].
/// Tapping it resumes the exact chapter and scroll position (or, for image
/// books, the last-read page).
class _ContinueReadingBanner extends StatelessWidget {
  final Book book;
  const _ContinueReadingBanner({required this.book});

  @override
  Widget build(BuildContext context) {
    final progress = ReadingProgress.load(book.title);
    if (progress == null) return const SizedBox.shrink();

    final chapterIndex = progress.$1;
    final chapterName = (chapterIndex < book.chapters.length)
        ? (book.chapters[chapterIndex].chapterTitle?.isNotEmpty == true
            ? book.chapters[chapterIndex].chapterTitle!
            : book.chapters[chapterIndex].title?.isNotEmpty == true
                ? book.chapters[chapterIndex].title!
                : '${UiStrings.chapter} ${chapterIndex + 1}')
        : '${UiStrings.chapter} ${chapterIndex + 1}';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Image books resume at the saved page in the image reader.
            if (book.isImageBook) {
              ImageReadingScreen.open(context, book);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReadingScreen(
                  book: book,
                  chapterIndex: chapterIndex,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withOpacity(0.2)
                  : AppColors.primary.withOpacity(0.08),
              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_rounded,
                    color: AppColors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continue Reading',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 14,
                          )),
                      const SizedBox(height: 2),
                      // Chapter names are Mongolian — they stand in an
                      // upright bounded column, not a sideways row.
                      // Pure Latin/digit labels ("1 - 01") stay a Text.
                      if (RegExp(r'[\u1800-\u18AF]').hasMatch(chapterName))
                        BoundedMongolText(
                          chapterName,
                          maxHeight: 34,
                          maxColumns: 4,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontFamily: _bookCtrl.fontFamily.value.isEmpty
                                ? MongolFonts.z52dardastig
                                : _bookCtrl.fontFamily.value,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        )
                      else
                        Text(
                          chapterName,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
