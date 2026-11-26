import 'dart:io';

import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/extensions/storage_ext.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/services/access_service.dart';
import 'package:book_app/services/book_catalog.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';

import '../Component/find_ctrls.dart';

/// Reading progress of [book] as a fraction 0–1, or null when the book
/// has never been opened. Text books: chapters reached / total chapters.
/// Image books: last page / page count.
double? bookProgressFraction(Book book) {
  final progress = ReadingProgress.load(book.title);
  if (progress == null) return null;
  if (book.isImageBook) {
    if (book.pageCount <= 0) return null;
    return ((progress.$2.round() + 1) / book.pageCount).clamp(0.0, 1.0);
  }
  if (book.chapters.isEmpty) return null;
  return ((progress.$1 + 1) / book.chapters.length).clamp(0.0, 1.0);
}

/// The downloaded cover of [book], or the logo placeholder when the
/// cover has not been downloaded (or failed to load).
class BookCoverImage extends StatelessWidget {
  final Book book;
  const BookCoverImage({super.key, required this.book});

  @override
  Widget build(BuildContext context) {
    final path = book.localImagePath;
    if (path != null && path.isNotEmpty) {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: 360,
        errorBuilder: (_, __, ___) => const CoverPlaceholder(),
      );
    }
    return const CoverPlaceholder();
  }
}

/// Fallback cover: the Znom logo on its own pale-pink ground — the
/// brand placeholder, never a blank coloured block.
class CoverPlaceholder extends StatelessWidget {
  const CoverPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.logoPink,
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.72,
          child: Image.asset(
            'assets/images/znom_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.menu_book,
              size: 40,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cover-forward library card: a fixed-aspect cover frame (all source
/// covers are normalised to the same 0.71 book aspect), the vertical
/// Z52 title and author beside it, and a slim progress line for books
/// in progress. No star ratings.
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  const BookCard({super.key, required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookCtrl = FindCtrl.book;
    final progress = bookProgressFraction(book);
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
              offset: const Offset(0, 5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fixed-aspect cover frame (fixed height so the text
                  // columns beside it always have room).
                  SizedBox(
                    height: 140,
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 0.71,
                          child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BookCoverImage(book: book),
                            ),
                          ),
                        ),
                        // Tier badge: PRO for the subscription shelf,
                        // the price for premium books, nothing for free.
                        Positioned(
                          top: 6,
                          left: 6,
                          child: Obx(() {
                            if (!Get.isRegistered<AccessService>()) {
                              return const SizedBox.shrink();
                            }
                            final entry = Get.find<AccessService>()
                                .entryFor(book);
                            if (entry == null ||
                                entry.tier == BookTier.free) {
                              return const SizedBox.shrink();
                            }
                            final label = entry.tier == BookTier.pro
                                ? 'PRO'
                                : (entry.priceLabel ?? '\$4.99');
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title + author as vertical columns (clipped, like
                  // the search result cards, so long titles can never
                  // overflow the card).
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: ClipRect(
                            child: Obx(
                              () => MongolText(
                                book.title,
                                maxLines: 2,
                                style: TextStyle(
                                  fontFamily:
                                      bookCtrl.fontFamily.value.isEmpty
                                          ? MongolFonts.z52dardastig
                                          : bookCtrl.fontFamily.value,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white.withOpacity(0.95)
                                      : const Color(0xFF2D3436),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (book.auth.trim().isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRect(
                              child: Obx(
                                () => MongolText(
                                  book.auth,
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontFamily:
                                        bookCtrl.fontFamily.value.isEmpty
                                            ? MongolFonts.z52dardastig
                                            : bookCtrl.fontFamily.value,
                                    fontSize: 13,
                                    color: isDark
                                        ? Colors.white.withOpacity(0.55)
                                        : Colors.black45,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (progress != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: AppColors.secondary.withOpacity(0.18),
                  valueColor:
                      const AlwaysStoppedAnimation(AppColors.secondary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
