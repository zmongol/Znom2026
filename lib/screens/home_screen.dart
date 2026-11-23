import 'dart:io';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/screens/details_screen.dart';
import 'package:book_app/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';

import '../Component/MongolFonts.dart';
import '../Component/find_ctrls.dart';
import 'Donate.dart';

final _bookCtrl = FindCtrl.book;

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            elevation: 0,
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
              Obx(
                () => _buildIconButton(
                  context,
                  _bookCtrl.isDarkMode.value
                      ? Icons.light_mode
                      : Icons.dark_mode,
                  _bookCtrl.toggleThemeMode,
                ),
              ),
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

          // Hero Section with Mongolian Text
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Color(0xFF202431), Color(0xFF2F3A55)]
                      : [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6C5CE7).withOpacity(0.3),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Discover',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Your next great read',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Obx(
                        () => MongolText(
                          "ᡯᡭᢍ ᡢ ᢚᡪᢊᡬᢍ ᢘᡭᢞᡪᢑᡪᢐ",
                          style: TextStyle(
                            fontFamily: _bookCtrl.fontFamily.value.isEmpty
                                ? MongolFonts.z52xanadutig
                                : _bookCtrl.fontFamily.value,
                            fontSize: 20,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Section Title - Featured Books
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Text(
                'Featured Books',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ),
          ),

          // Books Grid List
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            sliver: Obx(() {
              final count = _bookCtrl.booksList.length;
              return SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    // Read the book outside Obx so each card only rebuilds
                    // when the booksList length actually changes, not on
                    // unrelated font/theme updates.
                    final book = _bookCtrl.booksList[index];
                    return _buildModernBookCard(
                      context,
                      book,
                      () {
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
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? Theme.of(context).cardColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.4)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF6C5CE7),
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white.withOpacity(0.95)
                              : Color(0xFF2D3436),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
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
                                  : Color.fromARGB(255, 39, 41, 42),
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
              margin: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1A1D23) : Color(0xFF2D3436),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
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
          SliverToBoxAdapter(
            child: SizedBox(height: 40),
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
      icon: Icon(Icons.settings_outlined, color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "FontSize",
          child: Row(
            children: [
              Icon(Icons.text_fields, color: Color(0xFF6C5CE7), size: 20),
              SizedBox(width: 12),
              Obx(
                () => Text(
                  "ᡥᡭᡬᢔᡭᡬᡨ ᡭᡧ ᢜᡪᢊᡪᡨ ᡳᡪᢉᡨ",
                  style: TextStyle(
                      fontFamily: _bookCtrl.fontFamily.value.isEmpty
                          ? null
                          : _bookCtrl.fontFamily.value),
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: "FontFamily",
          child: Row(
            children: [
              Icon(Icons.font_download_outlined,
                  color: Color(0xFF6C5CE7), size: 20),
              SizedBox(width: 12),
              Obx(
                () => Text(
                  "ᢘᡬᡬᡨ ᢔᡭᢑᡬᡪᡪᡳ",
                  style: TextStyle(
                      fontFamily: _bookCtrl.fontFamily.value.isEmpty
                          ? null
                          : _bookCtrl.fontFamily.value),
                ),
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
      },
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
    // Read fontFamily once — the Obx on book title only subscribes to this one
    // observable rather than re-subscribing throughout the whole tree.
    return Row(
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
        // Book Title (Right side)
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Center(
              child: Obx(
                () => MongolText(
                  book.title,
                  style: TextStyle(
                    fontFamily: _bookCtrl.fontFamily.value.isEmpty
                        ? MongolFonts.z52dardastig
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
        ),
      ],
    );
  }

  Widget _buildBookImage(dynamic book) {
    // Check if there's a local downloaded image
    if (book.localImagePath != null && book.localImagePath.isNotEmpty) {
      return Image.file(
        File(book.localImagePath),
        fit: BoxFit.cover,
        width: double.infinity,
        // Limit decoded size to the card's display size (80×80 logical px).
        // Flutter will still decode at device pixel ratio, but avoids loading
        // the full-res PNG into memory on every rebuild.
        cacheWidth: 240,
        cacheHeight: 240,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderImage(book);
        },
      );
    }

    // Only use Image.asset for bundled assets — FTP books have bare filenames
    if (book.image != null &&
        (book.image as String).isNotEmpty &&
        (book.image as String).startsWith('assets/')) {
      return Image.asset(
        book.image,
        fit: BoxFit.cover,
        width: double.infinity,
        cacheWidth: 240,
        cacheHeight: 240,
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
