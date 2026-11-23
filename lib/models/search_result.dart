import 'package:book_app/models/books/book_model.dart';

/// All matches for a single [book] + [chapterIndex] combination.
class ChapterSearchResult {
  final Book book;
  final int chapterIndex;
  final String chapterTitle;
  final String query;
  final List<int> matchStarts; // start character offsets in chapter content

  ChapterSearchResult({
    required this.book,
    required this.chapterIndex,
    required this.chapterTitle,
    required this.query,
    required this.matchStarts,
  });

  int get matchCount => matchStarts.length;

  String get content => book.chapters[chapterIndex].content ?? '';
}

/// One individual match — used for flat Prev/Next navigation in the detail screen.
class FlatMatch {
  final ChapterSearchResult result;
  final int matchIndexInChapter;

  FlatMatch(this.result, this.matchIndexInChapter);
}
