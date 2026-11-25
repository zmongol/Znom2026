import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/core/constants/ui_strings.dart';
import 'package:book_app/Component/MongolFonts.dart';
import 'package:book_app/Component/find_ctrls.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/models/search_result.dart';
import 'package:book_app/screens/search_detail_screen.dart';
import 'package:book_app/services/book_search_service.dart';
import 'package:book_app/widgets/bounded_mongol_text.dart';

/// Displays search results as left-to-right columns of Mongolian text.
/// Each column represents one matching chapter — tap to open the detail viewer.
class SearchResultsScreen extends StatefulWidget {
  final String query;
  final List<Book> books;

  const SearchResultsScreen({
    super.key,
    required this.query,
    required this.books,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  late final List<ChapterSearchResult> _results;
  late final List<FlatMatch> _allMatches;

  @override
  void initState() {
    super.initState();
    _results = BookSearchService.search(widget.query, widget.books);
    _allMatches = BookSearchService.flatten(_results);
  }

  int _globalIndexFor(ChapterSearchResult result) =>
      _allMatches.indexWhere((m) => m.result == result);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fontFamily = FindCtrl.book.fontFamily.value.isEmpty
        ? MongolFonts.z52agolatig
        : FindCtrl.book.fontFamily.value;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        // The query itself stays in the search field on the previous
        // screen — the header here is the Mongolian-first results label
        // in the body, not the rotated query word.
        title: const Text(
          'Results',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mongolian-first header: Z52 label + English count line.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BoundedMongolText(
                  UiStrings.searchResults,
                  maxHeight: 84,
                  maxColumns: 5,
                  style: TextStyle(
                    fontFamily: fontFamily,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? Colors.white.withOpacity(0.95)
                        : const Color(0xFF2D3436),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_allMatches.length} match${_allMatches.length == 1 ? '' : 'es'}'
                  ' · ${_results.length} chapter${_results.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12.5,
                    letterSpacing: 0.4,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _results.isEmpty
                ? _buildEmpty(isDark)
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    itemCount: _results.length,
                    itemBuilder: (context, i) {
                      final result = _results[i];
                      return Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
                        child: _ResultCard(
                          result: result,
                          fontFamily: fontFamily,
                          isDark: isDark,
                          colorIndex: i,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SearchDetailScreen(
                                allMatches: _allMatches,
                                initialIndex: _globalIndexFor(result),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off,
              size: 54, color: isDark ? Colors.white24 : Colors.black26),
          const SizedBox(height: 12),
          Text(
            'No results for "${widget.query}"',
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black45, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Accent colour palette — brand-derived, one per card, cycles ───────────
// All shades come from the two logo colours (orange / green); see
// AppColors.cardAccents.
const _kCardColors = AppColors.cardAccents;

// ─── Card widget ──────────────────────────────────────────────────────────────

class _ResultCard extends StatelessWidget {
  final ChapterSearchResult result;
  final String fontFamily;
  final bool isDark;
  final int colorIndex;
  final VoidCallback onTap;

  const _ResultCard({
    required this.result,
    required this.fontFamily,
    required this.isDark,
    required this.colorIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _kCardColors[colorIndex % _kCardColors.length];
    final cardBg = isDark ? const Color(0xFF1E2D3E) : Colors.white;

    // Snippet segments
    final content = result.content;
    final start = result.matchStarts.first;
    final end = (start + result.query.length).clamp(0, content.length);
    final snipStart = (start - 50).clamp(0, content.length);
    final snipEnd = (end + 130).clamp(0, content.length);
    final before =
        (snipStart > 0 ? '…' : '') + content.substring(snipStart, start);
    final matched = content.substring(start, end);
    final after =
        content.substring(end, snipEnd) + (snipEnd < content.length ? '…' : '');

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Card(
          elevation: 5,
          shadowColor: accent.withValues(alpha: 0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: cardBg,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Accent header strip ──────────────────────────────────
                Container(
                  height: 26,
                  color: accent,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${result.matchCount}✕',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Icon(Icons.menu_book,
                          size: 12, color: Colors.white70),
                    ],
                  ),
                ),

                // ── Body: top 1/3 = titles row, bottom 2/3 = snippet ────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Top 1/3: book title (left) | chapter title (right)
                      Expanded(
                        flex: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                accent.withValues(alpha: isDark ? 0.15 : 0.06),
                            border: Border(
                              bottom: BorderSide(
                                  color: accent.withValues(alpha: 0.3),
                                  width: 1),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Book title
                              Expanded(
                                child: ClipRect(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: MongolText(
                                      result.book.title,
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : accent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              // Thin vertical divider
                              Container(
                                  width: 1,
                                  color: accent.withValues(alpha: 0.3)),
                              // Chapter title
                              Expanded(
                                child: ClipRect(
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: MongolText(
                                      result.chapterTitle,
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? accent.withValues(alpha: 0.85)
                                            : accent.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ── Bottom 2/3: snippet, no scroll, clips at boundary
                      Expanded(
                        flex: 2,
                        child: ClipRect(
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: MongolText.rich(
                              TextSpan(children: [
                                if (before.isNotEmpty)
                                  TextSpan(
                                    text: before,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 18,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                                if (matched.isNotEmpty)
                                  TextSpan(
                                    text: matched,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 18,
                                      backgroundColor: AppColors.highlightAmber,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                if (after.isNotEmpty)
                                  TextSpan(
                                    text: after,
                                    style: TextStyle(
                                      fontFamily: fontFamily,
                                      fontSize: 18,
                                      color: isDark
                                          ? Colors.white60
                                          : Colors.black54,
                                    ),
                                  ),
                              ]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Footer hint ──────────────────────────────────────────
                Container(
                  height: 20,
                  color: accent.withValues(alpha: isDark ? 0.18 : 0.07),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(Icons.chevron_right,
                          size: 14,
                          color: isDark
                              ? Colors.white30
                              : accent.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
