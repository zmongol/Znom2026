// MongolTextSelector
//
// Wraps a MongolText widget with a long-press gesture that immediately
// identifies the exact word under the finger using MongolTextPainter's own
// layout engine (getPositionForOffset → getWordBoundary), then shows a small
// confirmation sheet with ◀ ▶ neighbour buttons for minor corrections.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mongol/mongol.dart';
import 'package:book_app/core/constants/app_colors.dart';
import 'package:book_app/Component/find_ctrls.dart';
import 'package:book_app/screens/search_detail_screen.dart';
import 'package:book_app/services/book_search_service.dart';

// ── Public widget ─────────────────────────────────────────────────────────────

class MongolTextSelector extends StatefulWidget {
  const MongolTextSelector({
    super.key,
    required this.text,
    required this.child,
  });

  final String text;
  final Widget child;

  @override
  State<MongolTextSelector> createState() => _MongolTextSelectorState();
}

class _MongolTextSelectorState extends State<MongolTextSelector> {
  double _widgetHeight = 0;
  BuildContext? _layoutCtx;

  static List<_WordToken> _tokenize(String text) {
    final tokens = <_WordToken>[];
    final re = RegExp(r'\S+');
    for (final m in re.allMatches(text)) {
      tokens.add(_WordToken(m.group(0)!, m.start, m.end));
    }
    return tokens;
  }

  // Return the token that contains [charOffset], or the nearest one if
  // [charOffset] falls on whitespace.
  static int _tokenAtOffset(List<_WordToken> tokens, int charOffset) {
    for (int i = 0; i < tokens.length; i++) {
      if (charOffset >= tokens[i].start && charOffset < tokens[i].end) {
        return i;
      }
    }
    // Landed on whitespace — pick the token with the closest boundary.
    int best = 0;
    int bestDist = 0x7fffffff;
    for (int i = 0; i < tokens.length; i++) {
      final dStart = (charOffset - tokens[i].start).abs();
      final dEnd = (charOffset - tokens[i].end).abs();
      final dist = dStart < dEnd ? dStart : dEnd;
      if (dist < bestDist) {
        bestDist = dist;
        best = i;
      }
    }
    return best;
  }

  // Finds the token whose painted bounding box contains [localPos] using
  // getBoxesForSelection (exact screen-coordinate rects).
  //
  // Strategy:
  //  1. Get an approximate index via getPositionForOffset (fast, sometimes wrong).
  //  2. Search a ±15 window around it for exact containment.
  //  3. If no exact hit, return the token with the nearest box-centre.
  static int _findTokenByBoxes(
    MongolTextPainter painter,
    List<_WordToken> tokens,
    Offset localPos,
  ) {
    if (tokens.isEmpty) return 0;

    // Fast approximate position (may be off by a few tokens).
    final approxPos = painter.getPositionForOffset(localPos);
    final approxRange = painter.getWordBoundary(approxPos);
    final approxMid = approxRange.isCollapsed
        ? approxPos.offset
        : (approxRange.start + approxRange.end) ~/ 2;
    final approxIdx = _tokenAtOffset(tokens, approxMid);

    final lo = (approxIdx - 15).clamp(0, tokens.length - 1);
    final hi = (approxIdx + 16).clamp(0, tokens.length);

    // Pass 1: exact box containment.
    for (int i = lo; i < hi; i++) {
      final boxes = painter.getBoxesForSelection(
        TextSelection(
            baseOffset: tokens[i].start, extentOffset: tokens[i].end),
      );
      for (final box in boxes) {
        if (box.contains(localPos)) return i;
      }
    }

    // Pass 2: nearest box-centre (handles gaps between tokens).
    int bestIdx = approxIdx;
    double bestDist = double.infinity;
    for (int i = lo; i < hi; i++) {
      final boxes = painter.getBoxesForSelection(
        TextSelection(
            baseOffset: tokens[i].start, extentOffset: tokens[i].end),
      );
      for (final box in boxes) {
        final dist = (box.center - localPos).distance;
        if (dist < bestDist) {
          bestDist = dist;
          bestIdx = i;
        }
      }
    }
    return bestIdx;
  }

  void _onLongPressStart(BuildContext context, LongPressStartDetails details) {
    final tokens = _tokenize(widget.text);
    if (tokens.isEmpty) return;

    // Use the LayoutBuilder render box for accurate local coordinates.
    final RenderBox? rb = _layoutCtx?.findRenderObject() as RenderBox?;
    final localPos = (rb != null && rb.hasSize)
        ? rb.globalToLocal(details.globalPosition)
        : details.localPosition;

    // Compute the effective style the same way MongolText.build() does:
    // merge DefaultTextStyle (which carries Material3 height/letterSpacing)
    // with contentStyle, then override with the provided style.
    final rawStyle = FindCtrl.book.contentStyle.value;
    final defaultTextStyle = DefaultTextStyle.of(context);
    final mergedStyle =
        rawStyle.inherit ? defaultTextStyle.style.merge(rawStyle) : rawStyle;
    final effectiveStyle = MediaQuery.boldTextOf(context)
        ? mergedStyle.merge(const TextStyle(fontWeight: FontWeight.bold))
        : mergedStyle;

    final effectiveH =
        _widgetHeight > 0 ? _widgetHeight : MediaQuery.of(context).size.height;
    final textScaleFactor = MediaQuery.textScaleFactorOf(context);

    // Build a painter that matches the real MongolText widget exactly.
    // Use minHeight: 0 (not effectiveH) to replicate what MongolRenderParagraph
    // does: it passes constraints.minHeight (= 0) + constraints.maxHeight.
    // Using minHeight = maxHeight forces a tight layout that differs from the
    // real widget for short chapters (text shorter than the viewport), causing
    // different column-break positions.
    final painter = MongolTextPainter(
      text: TextSpan(text: widget.text, style: effectiveStyle),
      textAlign: MongolTextAlign.top,
      textScaleFactor: textScaleFactor,
    );
    painter.layout(minHeight: 0, maxHeight: effectiveH);

    // Use getBoxesForSelection (pixel-accurate bounding rects) rather than
    // getPositionForOffset, which has a documented bug in mongol's source
    // (rotatedRunDx is always 0, so paragraphDy = absolute dx instead of
    // column-relative dx).  getBoxesForSelection returns a Rect in the same
    // screen-coordinate space as localPos, so box.contains(localPos) is exact.
    final tokenIndex = _findTokenByBoxes(painter, tokens, localPos);
    painter.dispose();

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectionSheet(
        tokens: tokens,
        initialIndex: tokenIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        _layoutCtx = ctx;
        if (constraints.maxHeight.isFinite && constraints.maxHeight > 0) {
          _widgetHeight = constraints.maxHeight;
        }
        return GestureDetector(
          onLongPressStart: (d) => _onLongPressStart(context, d),
          child: widget.child,
        );
      },
    );
  }
}

// ── Word token ────────────────────────────────────────────────────────────────

class _WordToken {
  const _WordToken(this.word, this.start, this.end);
  final String word;
  final int start;
  final int end;
}

// ── Selection sheet ───────────────────────────────────────────────────────────
//
// Shows the detected word prominently. ◀ ▶ buttons step to a neighbour for
// minor corrections. Copy and Search in Books actions.

class _SelectionSheet extends StatefulWidget {
  const _SelectionSheet({
    required this.tokens,
    required this.initialIndex,
  });

  final List<_WordToken> tokens;
  final int initialIndex;

  @override
  State<_SelectionSheet> createState() => _SelectionSheetState();
}

class _SelectionSheetState extends State<_SelectionSheet> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  String get _word => widget.tokens[_index].word;
  bool get _hasPrev => _index > 0;
  bool get _hasNext => _index < widget.tokens.length - 1;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _word));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Copied'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _searchInBooks() {
    final query = _word.trim();
    if (query.isEmpty) return;
    Navigator.pop(context);

    final books = FindCtrl.book.booksList;
    final results = BookSearchService.search(query, books);
    final flat = BookSearchService.flatten(results);

    if (flat.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No results found'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchDetailScreen(
          allMatches: flat,
          initialIndex: 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawStyle = FindCtrl.book.contentStyle.value;
    final style = rawStyle.inherit
        ? DefaultTextStyle.of(context).style.merge(rawStyle)
        : rawStyle;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2228) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ─────────────────────────────────────────
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── Word + prev/next ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _hasPrev ? () => setState(() => _index--) : null,
                    icon: const Icon(Icons.chevron_left_rounded, size: 32),
                    color: AppColors.primary,
                    disabledColor: Colors.grey.shade300,
                  ),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 140),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 120),
                          child: MongolText(
                            _word,
                            key: ValueKey(_index),
                            style: style.copyWith(
                              fontSize: (style.fontSize ?? 18) * 1.2,
                            ),
                            textAlign: MongolTextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _hasNext ? () => setState(() => _index++) : null,
                    icon: const Icon(Icons.chevron_right_rounded, size: 32),
                    color: AppColors.primary,
                    disabledColor: Colors.grey.shade300,
                  ),
                ],
              ),
            ),

            // ── Position indicator ───────────────────────────────────
            Text(
              '${_index + 1} / ${widget.tokens.length}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),

            const SizedBox(height: 12),

            // ── Action buttons ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _copy,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search_rounded, size: 18),
                      label: const Text('Search in books'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _searchInBooks,
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
