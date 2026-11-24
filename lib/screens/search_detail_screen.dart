import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mongol/mongol.dart';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/Component/find_ctrls.dart';
import 'package:book_app/models/search_result.dart';
import 'package:book_app/screens/reading_screen.dart';
import 'package:book_app/widgets/mongol_text_selector.dart';

/// Full-text search detail screen.
/// Shows a Mongolian-text snippet with the matched word highlighted.
/// Prev / Next navigate through every individual match across all books/chapters.
class SearchDetailScreen extends StatefulWidget {
  final List<FlatMatch> allMatches;
  final int initialIndex;

  const SearchDetailScreen({
    super.key,
    required this.allMatches,
    required this.initialIndex,
  });

  @override
  State<SearchDetailScreen> createState() => _SearchDetailScreenState();
}

class _SearchDetailScreenState extends State<SearchDetailScreen> {
  late int _current;
  final _bookCtrl = FindCtrl.book;
  final _scrollCtrl = ScrollController();

  // Characters of context shown before and after the highlighted match
  static const int _contextChars = 200;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMatch());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  FlatMatch get _flat => widget.allMatches[_current];

  void _go(int delta) {
    setState(() => _current += delta);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToMatch());
  }

  /// Auto-scroll the snippet so the highlighted match is centred horizontally.
  void _scrollToMatch() {
    if (!_scrollCtrl.hasClients) return;
    final result = _flat.result;
    final content = result.content;
    final matchStart = result.matchStarts[_flat.matchIndexInChapter];
    final snipStart = (matchStart - _contextChars).clamp(0, content.length);
    final before =
        (snipStart > 0 ? '…' : '') + content.substring(snipStart, matchStart);
    final beforeLen = before.length;

    final fontSize = _bookCtrl.contentStyle.value.fontSize ?? 22.0;
    final lineHeight = fontSize * 1.35;
    // Text area height = 60% of screen minus container padding (16×2)
    final textH = (MediaQuery.of(context).size.height * 0.60 - 32)
        .clamp(1.0, double.infinity);
    final charsPerCol = (textH / lineHeight).floor().clamp(1, 9999);
    final colWidth = fontSize * 0.65;

    final matchCol = beforeLen ~/ charsPerCol;
    final viewportWidth = _scrollCtrl.position.viewportDimension;
    final target = (matchCol * colWidth - viewportWidth / 2)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);

    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final flat = _flat;
    final result = flat.result;
    final content = result.content;
    final matchStart = result.matchStarts[flat.matchIndexInChapter];
    final matchEnd = matchStart + result.query.length;
    final total = widget.allMatches.length;

    // Build snippet: context before + match + context after
    final snipStart = (matchStart - _contextChars).clamp(0, content.length);
    final snipEnd = (matchEnd + _contextChars).clamp(0, content.length);
    final before =
        (snipStart > 0 ? '…' : '') + content.substring(snipStart, matchStart);
    final matchText = content.substring(matchStart, matchEnd);
    final after = content.substring(matchEnd, snipEnd) +
        (snipEnd < content.length ? '…' : '');

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.book.title,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Match ${_current + 1} of $total  •  ${result.chapterTitle}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.menu_book_outlined,
                color: Colors.white, size: 18),
            label: const Text('Read',
                style: TextStyle(color: Colors.white, fontSize: 13)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ReadingScreen(
                  book: result.book,
                  chapterIndex: result.chapterIndex,
                  highlightQuery: result.query,
                  highlightStart: matchStart,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Highlighted text snippet ──────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReadingScreen(
                    book: result.book,
                    chapterIndex: result.chapterIndex,
                    highlightQuery: result.query,
                    highlightStart: matchStart,
                  ),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Theme.of(context).cardColor
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                    },
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    controller: _scrollCtrl,
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.60,
                      child: Center(
                        child: Obx(
                          () {
                            final snipText = (snipStart > 0 ? '…' : '') +
                                content.substring(snipStart, snipEnd) +
                                (snipEnd < content.length ? '…' : '');
                            return MongolTextSelector(
                              text: snipText,
                              child: MongolText.rich(
                                TextSpan(
                                  style: _bookCtrl.contentStyle.value,
                                  children: [
                                    TextSpan(text: before),
                                    TextSpan(
                                      text: matchText,
                                      style: const TextStyle(
                                        backgroundColor:
                                            AppColors.highlightAmber,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(text: after),
                                  ],
                                ),
                                textAlign: MongolTextAlign.top,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // ── Prev / Next navigation bar ────────────────────────────────
          SafeArea(
            top: false,
            child: Container(
              color: Theme.of(context).cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.chevron_left),
                      label: const Text('Prev'),
                      onPressed: _current > 0 ? () => _go(-1) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: _current > 0
                                ? AppColors.primary
                                : Colors.grey.shade300),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '${_current + 1} / $total',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: OutlinedButton.icon(
                      label: const Text('Next'),
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _current < total - 1 ? () => _go(1) : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                            color: _current < total - 1
                                ? AppColors.primary
                                : Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
