import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/core/constants/ui_strings.dart';
import 'package:book_app/extensions/storage_ext.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/screens/details_screen.dart';
import 'package:book_app/screens/image_reading_screen.dart';
import 'package:book_app/screens/reading_screen.dart';
import 'package:book_app/screens/search_screen.dart';
import 'package:book_app/widgets/book_card.dart';
import 'package:book_app/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';

import '../Component/MongolFonts.dart';
import '../Component/find_ctrls.dart';
import '../widgets/bounded_mongol_text.dart';
import 'Donate.dart';

final _bookCtrl = FindCtrl.book;

/// The newest book on the server (added 24 Nov 2026) — featured at the
/// top of the home screen with its real cover.
const _featuredBookTitle = 'ᢘᡭᡪᢊᡱᡱᡪᢑᡪᢇ ᢘᡪᢎᡬᢝ';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar — no back arrow on the root screen, three actions.
          SliverAppBar(
            pinned: true,
            elevation: 0,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primary,
            title: Obx(
              () => Text(
                "Znom",
                style: TextStyle(
                  fontFamily: _bookCtrl.fontFamily.value.isEmpty
                      ? MongolFonts.z52xanadutig
                      : _bookCtrl.fontFamily.value,
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            actions: [
              _buildIconButton(
                context,
                Icons.search,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SearchScreen()),
                ),
              ),
              _buildIconButton(
                context,
                Icons.favorite,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Donation()),
                ),
              ),
              _buildPopupMenu(context),
            ],
          ),

          // Continue Reading — first, when anything is in progress.
          SliverToBoxAdapter(
            child: Obx(() {
              final inProgress = _bookCtrl.booksList
                  .where((b) => ReadingProgress.load(b.title) != null)
                  .toList();
              if (inProgress.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      z52: UiStrings.continueReading,
                      english: 'Continue Reading',
                    ),
                    const SizedBox(height: 12),
                    ...inProgress
                        .take(3)
                        .map((b) => _ContinueReadingRow(book: b)),
                  ],
                ),
              );
            }),
          ),

          // Featured — the newest book, with its real cover.
          SliverToBoxAdapter(
            child: Obx(() {
              if (_bookCtrl.booksList.isEmpty) {
                return const SizedBox.shrink();
              }
              final book = _bookCtrl.booksList.firstWhere(
                (b) => b.title == _featuredBookTitle,
                orElse: () => _bookCtrl.booksList.last,
              );
              return Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
                child: _FeaturedBookCard(book: book),
              );
            }),
          ),

          // Section Title - Featured Books
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: SectionHeader(
                z52: UiStrings.featuredBooks,
                english: 'Featured Books',
              ),
            ),
          ),

          // Books Grid List
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: Obx(() {
              final count = _bookCtrl.booksList.length;
              if (count == 0) {
                // Fresh install: books are still downloading from the
                // book server — a friendly welcome state, not a blank
                // library.
                return SliverToBoxAdapter(child: _buildWelcomeState(context));
              }
              return SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final book = _bookCtrl.booksList[index];
                    return BookCard(
                      book: book,
                      onTap: () {
                        _bookCtrl.randombooksList.shuffle();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetailsScreen(book: book),
                          ),
                        );
                      },
                    );
                  },
                  childCount: count,
                ),
              );
            }),
          ),

          // About Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader(
                    z52: UiStrings.about,
                    english: 'About',
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 200,
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Obx(
                          () => MongolText(
                            "ᢊᡪᢞᡳᡪᡨ ᢚᡫ ᡸᡪᡬᡬᢝᡨ ᡳᡪᡧ ᡥᡭᢑᡭᢉᡨ ᡥᡭᡬᢊᡪᡫ ᢜᡪᡴᡭᢉᡨ ᡴᡭᢐ ᡯᡭᢍ ᡥᡭᡪᢊᢔᡫ ᡒ ᢘᡭᢞᡪᢑᡪᢛᡳ ᡴᡭᢑᡪᡪᡳ ᡥᡭᡬᡫ ᡥᡭᢑᡪᡧ ᢋᡭᡬᢎᡭᡧ ᡛ ᢘᡪᡪᢙᡧ ᡜ ᡴᡭᡫ ᠃",
                            style: TextStyle(
                              fontFamily: _bookCtrl.fontFamily.value.isEmpty
                                  ? MongolFonts.z52enkiragotig
                                  : _bookCtrl.fontFamily.value,
                              fontSize: 18,
                              color: isDark
                                  ? Colors.white.withOpacity(0.85)
                                  : const Color.fromARGB(255, 39, 41, 42),
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contact Section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : const Color(0xFF2D3436),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Text(
                    "Zmongolcode@gmail.com",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  /// First-run welcome: shown while the first sync downloads the
  /// library. Mongolian-first text + an indeterminate progress
  /// indicator (the sync exposes no byte-level progress signal).
  Widget _buildWelcomeState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Image.asset(
            'assets/images/znom_logo.png',
            width: 104,
            height: 104,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.menu_book,
              size: 64,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            child: Center(
              child: Obx(
                () => MongolText(
                  UiStrings.booksDownloading,
                  style: TextStyle(
                    fontFamily: _bookCtrl.fontFamily.value.isEmpty
                        ? MongolFonts.z52dardastig
                        : _bookCtrl.fontFamily.value,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withOpacity(0.95)
                        : const Color(0xFF2D3436),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Books are downloading…',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: AppColors.secondary),
          const SizedBox(height: 16),
          const Text(
            'Books download from the Znom book server when you are '
            'online. The library appears here automatically — if it '
            'stays empty, check your internet connection.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
      BuildContext context, IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: Colors.white),
      onPressed: onPressed,
    );
  }

  Widget _buildPopupMenu(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.settings_outlined, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "FontSize",
          child: Row(
            children: [
              const Icon(Icons.text_fields, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Obx(
                () => SizedBox(
                  width: 120,
                  child: BoundedMongolText(
                    UiStrings.fontSize,
                    maxHeight: 44,
                    maxColumns: 5,
                    style: TextStyle(
                        fontFamily: _bookCtrl.fontFamily.value.isEmpty
                            ? MongolFonts.z52dardastig
                            : _bookCtrl.fontFamily.value,
                        fontSize: 13.5,
                        color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: "FontFamily",
          child: Row(
            children: [
              const Icon(Icons.font_download_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Obx(
                () => SizedBox(
                  width: 120,
                  child: BoundedMongolText(
                    UiStrings.fontFamily,
                    maxHeight: 44,
                    maxColumns: 5,
                    style: TextStyle(
                        fontFamily: _bookCtrl.fontFamily.value.isEmpty
                            ? MongolFonts.z52dardastig
                            : _bookCtrl.fontFamily.value,
                        fontSize: 13.5,
                        color: Colors.black87),
                  ),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: "DarkMode",
          child: Row(
            children: [
              const Icon(Icons.dark_mode_outlined,
                  color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Obx(
                () => SizedBox(
                  width: 120,
                  child: BoundedMongolText(
                    UiStrings.darkMode,
                    maxHeight: 44,
                    maxColumns: 5,
                    style: TextStyle(
                        fontFamily: _bookCtrl.fontFamily.value.isEmpty
                            ? MongolFonts.z52dardastig
                            : _bookCtrl.fontFamily.value,
                        fontSize: 13.5,
                        color: Colors.black87),
                  ),
                ),
              ),
              const Spacer(),
              Obx(
                () => _bookCtrl.isDarkMode.value
                    ? const Icon(Icons.check,
                        color: AppColors.primary, size: 20)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == "FontSize") {
          _bookCtrl.changeFontScale();
        }
        if (val == "FontFamily") {
          _bookCtrl.changeFontFamily();
        }
        if (val == "DarkMode") {
          _bookCtrl.toggleThemeMode();
        }
      },
    );
  }
}

/// One in-progress book on the home screen: cover, title, where the
/// reader left off, and a slim progress line. Tapping resumes reading.
class _ContinueReadingRow extends StatelessWidget {
  final Book book;
  const _ContinueReadingRow({required this.book});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = ReadingProgress.load(book.title);
    final fraction = bookProgressFraction(book) ?? 0;
    final chapterNumberLabel =
        '${((progress?.$1 ?? 0) + 1)} / ${book.chapters.length}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            if (book.isImageBook) {
              ImageReadingScreen.open(context, book);
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReadingScreen(
                  book: book,
                  chapterIndex: progress?.$1 ?? 0,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).cardColor : Colors.white,
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: AspectRatio(
                    aspectRatio: 0.71,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BookCoverImage(book: book),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(
                        () => BoundedMongolText(
                          book.title,
                          maxHeight: 58,
                          maxColumns: 3,
                          style: TextStyle(
                            fontFamily: _bookCtrl.fontFamily.value.isEmpty
                                ? MongolFonts.z52dardastig
                                : _bookCtrl.fontFamily.value,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white.withOpacity(0.95)
                                : const Color(0xFF2D3436),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Caption: the Mongolian word stands in an upright
                      // column; only the numbers stay Latin.
                      if (book.isImageBook)
                        Text(
                          'Page ${((progress?.$2.round() ?? 0) + 1)} / ${book.pageCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Obx(
                              () => BoundedMongolText(
                                UiStrings.chapter,
                                maxHeight: 28,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontFamily: _bookCtrl.fontFamily.value.isEmpty
                                      ? MongolFonts.z52dardastig
                                      : _bookCtrl.fontFamily.value,
                                  color:
                                      isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              chapterNumberLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 3,
                          backgroundColor:
                              AppColors.secondary.withOpacity(0.18),
                          valueColor:
                              const AlwaysStoppedAnimation(AppColors.secondary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    size: 16, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Featured card for the newest book: real cover, "new book" badge,
/// title and author, on the brand gradient.
class _FeaturedBookCard extends StatelessWidget {
  final Book book;
  const _FeaturedBookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailsScreen(book: book)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              height: 168,
              child: AspectRatio(
                aspectRatio: 0.71,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BookCoverImage(book: book),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.logoPink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: SizedBox(
                      height: 40,
                      child: Obx(
                        () => MongolText(
                          UiStrings.newBook,
                          style: TextStyle(
                            fontFamily: _bookCtrl.fontFamily.value.isEmpty
                                ? MongolFonts.z52dardastig
                                : _bookCtrl.fontFamily.value,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 120,
                    child: Obx(
                      () => MongolText(
                        book.title,
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: _bookCtrl.fontFamily.value.isEmpty
                              ? MongolFonts.z52dardastig
                              : _bookCtrl.fontFamily.value,
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (book.auth.trim().isNotEmpty)
                    SizedBox(
                      height: 44,
                      child: Obx(
                        () => MongolText(
                          book.auth,
                          maxLines: 1,
                          style: TextStyle(
                            fontFamily: _bookCtrl.fontFamily.value.isEmpty
                                ? MongolFonts.z52dardastig
                                : _bookCtrl.fontFamily.value,
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
