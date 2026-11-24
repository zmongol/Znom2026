import 'package:book_app/core/constants/ui_strings.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/models/search_result.dart';

class BookSearchService {
  /// Searches all chapters of every book for [query].
  /// Returns one [ChapterSearchResult] per (book, chapter) pair that has ≥1 match.
  /// Match is case-insensitive.
  static List<ChapterSearchResult> search(String query, List<Book> books) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    final lower = trimmed.toLowerCase();
    final results = <ChapterSearchResult>[];

    for (final book in books) {
      for (int ci = 0; ci < book.chapters.length; ci++) {
        final chapter = book.chapters[ci];
        final content = chapter.content ?? '';
        if (content.isEmpty) continue;

        final lowerContent = chapter.lowerContent;
        final matchStarts = <int>[];
        int from = 0;

        while (true) {
          final idx = lowerContent.indexOf(lower, from);
          if (idx == -1) break;
          matchStarts.add(idx);
          from = idx + lower.length;
        }

        if (matchStarts.isNotEmpty) {
          results.add(ChapterSearchResult(
            book: book,
            chapterIndex: ci,
            chapterTitle: (chapter.chapterTitle?.isNotEmpty == true)
                ? chapter.chapterTitle!
                : '${UiStrings.chapter} ${ci + 1}',
            query: trimmed,
            matchStarts: matchStarts,
          ));
        }
      }
    }

    return results;
  }

  /// Flattens a list of [ChapterSearchResult] into individual [FlatMatch] entries
  /// suitable for linear Prev/Next navigation.
  static List<FlatMatch> flatten(List<ChapterSearchResult> results) {
    final flat = <FlatMatch>[];
    for (final r in results) {
      for (int i = 0; i < r.matchCount; i++) {
        flat.add(FlatMatch(r, i));
      }
    }
    return flat;
  }
}
