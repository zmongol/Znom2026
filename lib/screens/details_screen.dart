import 'dart:io';

import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/extensions/storage_ext.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/screens/image_reading_screen.dart';
import 'package:book_app/screens/reading_screen.dart';
import 'package:flutter/material.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';

import '../Component/find_ctrls.dart';
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
        title: Obx(
          () => Text(book.title,
              style: TextStyle(
                  fontFamily: _bookCtrl.fontFamily.value.isEmpty
                      ? null
                      : _bookCtrl.fontFamily.value,
                  color: Colors.white)),
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
                              press: () {
                                // Image books open the page-image reader;
                                // text books open the text reader.
                                if (book.isImageBook) {
                                  ImageReadingScreen.open(context, book);
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
                  Text(
                    'Featured Books',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? Colors.white.withOpacity(0.95)
                          : Color(0xFF2D3436),
                    ),
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
                        childAspectRatio: 1.0,
                      ),
                      itemCount: _bookCtrl.booksList.length,
                      itemBuilder: (context, index) {
                        final bookItem = _bookCtrl.booksList[index];
                        return _buildModernBookCard(
                          context,
                          bookItem,
                          () {
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

  Widget _buildModernBookCard(
      BuildContext context, dynamic book, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Theme.of(context).cardColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.4)
                  : Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: _buildBookCardContent(context, book),
      ),
    );
  }

  Widget _buildBookCardContent(BuildContext context, dynamic book) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Book Cover (Left side)
          Container(
            width: 80,
            margin: EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildBookImage(book),
            ),
          ),
          // Book Title (Right side, scrollable)
          Container(
            width: 90,
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Center(
              child: Obx(
                () => MongolText(
                  book.title,
                  style: TextStyle(
                    fontFamily: _bookCtrl.fontFamily.value.isEmpty
                        ? null
                        : _bookCtrl.fontFamily.value,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.95)
                        : Color(0xFF2D3436),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookImage(dynamic book) {
    // Check if there's a local downloaded image
    if (book.localImagePath != null && book.localImagePath.isNotEmpty) {
      return Image.file(
        File(book.localImagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(book);
        },
      );
    }

    // Check if there's an asset image
    if (book.image != null && book.image.isNotEmpty) {
      return Image.asset(
        book.image,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(book);
        },
      );
    }

    // Show placeholder
    return _buildPlaceholderImage(book);
  }

  Widget _buildPlaceholderImage(dynamic book) {
    return Container(
      color: Color(0xFF6C5CE7).withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.book,
          size: 40,
          color: Color(0xFF6C5CE7),
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
                : 'Chapter ${chapterIndex + 1}')
        : 'Chapter ${chapterIndex + 1}';
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
