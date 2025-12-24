import 'dart:io';

import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/models/books/book_model.dart';
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

  DetailsScreen({required this.book});

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
                      ? MongolFonts.z52ordostig
                      : _bookCtrl.fontFamily.value,
                  color: Colors.white)),
        ),
        backgroundColor: isDark
            ? Theme.of(context).cardColor
            : Color.fromARGB(255, 164, 166, 168),
        actions: [
          IconButton(
            icon: Icon(Icons.coffee), //Go to Donation page
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
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReadingScreen(
                                      book: book,
                                      chapterIndex: i,
                                    ),
                                  ), //Go to Donation page
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
