import 'package:flutter/material.dart';
import 'package:mongol/mongol.dart';

/// Vertical Mongolian text that can never lie sideways and never
/// overflow its box.
///
/// Why this exists: a plain Flutter [Text] lays Mongolian glyphs out
/// horizontally — the text "lies down" sideways, which is wrong for
/// Mongolian. The mongol package's [MongolText] stands text upright in
/// columns, but its paragraph engine only breaks between words: a
/// single word taller than the available height is painted as one long
/// column straight past the box (the 1.0.3 home header and reader
/// settings heading did exactly that on the user's phone).
///
/// This widget follows the approach proven in the Mongolian! app
/// (measure with [MongolTextPainter], split into columns, fit the
/// size): the string is measured in its real font, split into upright
/// columns that each fit [maxHeight] — whole words first, a too-tall
/// word split between code points (safe in Z52, a glyph-per-codepoint
/// encoding) — and the font size is reduced until the columns also fit
/// the available width and [maxColumns]. The result is clipped as a
/// last resort, so overflow is impossible.
///
/// [style.fontSize] is the preferred size; the rendered size is the
/// largest size at or below it that fits. The widget's height is
/// exactly [maxHeight] — the headroom matters: a column whose measured
/// run equals the box height to the pixel would be re-wrapped by the
/// paragraph engine into a second column, so the columns are split
/// against a slightly smaller target and painted in the full box.
class BoundedMongolText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double maxHeight;
  final int maxColumns;
  final double minFontSize;
  final double columnSpacing;

  /// Center the columns in the box instead of top-aligning them —
  /// for picker tiles, where the sample should sit in the middle of
  /// its tile rather than hug the top.
  final bool centerVertically;

  const BoundedMongolText(
    this.text, {
    super.key,
    required this.style,
    required this.maxHeight,
    this.maxColumns = 6,
    this.minFontSize = 9,
    this.columnSpacing = 3,
    this.centerVertically = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final availWidth = constraints.maxWidth;
        var size = style.fontSize ?? 14;
        var fitted = _fit(size, availWidth);
        while ((fitted.columns.length > maxColumns ||
                fitted.totalWidth > availWidth) &&
            size > minFontSize) {
          size = (size * 0.92).clamp(minFontSize, double.infinity);
          fitted = _fit(size, availWidth);
        }
        // inherit: false is load-bearing: the ambient DefaultTextStyle
        // (Material 3 bodyMedium carries height 1.4 and letterSpacing)
        // would otherwise merge into every MongolText and fatten each
        // column ~1.4x beyond what the painter measured above — one of
        // the ways the old headers overflowed their boxes. But a style
        // with no color of its own must still borrow the ambient text
        // color: with inherit off and color null the paragraph paints
        // nothing at all (the first settings-sheet build had invisible
        // size/font tiles for exactly this reason).
        final renderStyle = style.copyWith(
          fontSize: size,
          inherit: false,
          color: style.color ??
              DefaultTextStyle.of(context).style.color ??
              Colors.black,
        );
        final columns = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < fitted.columns.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  right: i < fitted.columns.length - 1 ? columnSpacing : 0,
                ),
                child: MongolText(
                  fitted.columns[i],
                  textAlign: MongolTextAlign.top,
                  style: renderStyle,
                ),
              ),
          ],
        );
        return ClipRect(
          child: SizedBox(
            height: maxHeight,
            child: centerVertically
                ? Align(alignment: Alignment.center, child: columns)
                : columns,
          ),
        );
      },
    );
  }

  _Fitted _fit(double fontSize, double availWidth) {
    final s = style.copyWith(fontSize: fontSize);
    // Split against a hair less than the box so no rendered column
    // sits exactly on the paragraph engine's wrap boundary.
    final columns =
        splitMongolColumns(text, style: s, maxHeight: maxHeight - 1);
    var width = 0.0;
    for (final column in columns) {
      width += measureMongolColumn(column, s).width;
    }
    if (columns.length > 1) width += columnSpacing * (columns.length - 1);
    return _Fitted(columns, width);
  }
}

class _Fitted {
  final List<String> columns;
  final double totalWidth;
  const _Fitted(this.columns, this.totalWidth);
}

/// Measures [text] in [style] as ONE vertical column: [Size.width] is
/// the horizontal cross extent of the column, [Size.height] is the
/// vertical run length. Measured with the same [MongolTextPainter] the
/// widgets paint with, so the numbers are the numbers the glyphs will
/// actually occupy — in the exact font (fonts differ by up to ~2x in
/// run length at the same point size, so no constant factor works).
Size measureMongolColumn(String text, TextStyle style) {
  final painter = MongolTextPainter(
    text: TextSpan(text: text, style: style),
    textAlign: MongolTextAlign.top,
  );
  painter.layout(maxHeight: double.infinity);
  return painter.size;
}

/// Splits [text] into vertical columns that each fit [maxHeight] in
/// [style] — letters flow top-to-bottom within a column, columns read
/// left-to-right. Whole words are packed into a column first; a single
/// word taller than [maxHeight] is split between code points (Z52 is
/// a glyph-per-codepoint encoding, so a split never changes how the
/// glyphs render). Returns `[text]` unchanged when it already fits.
List<String> splitMongolColumns(
  String text, {
  required TextStyle style,
  required double maxHeight,
}) {
  if (text.isEmpty || !maxHeight.isFinite || maxHeight <= 0) {
    return <String>[text];
  }
  if (measureMongolColumn(text, style).height <= maxHeight) {
    return <String>[text];
  }
  final atoms = <String>[];
  for (final word in text.split(' ')) {
    if (word.isEmpty) continue;
    if (measureMongolColumn(word, style).height <= maxHeight) {
      atoms.add(word);
    } else {
      atoms.addAll(
          _splitWordIntoColumns(word, style: style, maxHeight: maxHeight));
    }
  }
  if (atoms.isEmpty) return <String>[text];
  final columns = <String>[];
  var current = '';
  for (final atom in atoms) {
    final candidate = current.isEmpty ? atom : '$current $atom';
    if (measureMongolColumn(candidate, style).height <= maxHeight) {
      current = candidate;
    } else {
      if (current.isNotEmpty) columns.add(current);
      current = atom;
    }
  }
  if (current.isNotEmpty) columns.add(current);
  return columns;
}

/// Splits one over-tall word into the fewest balanced code-point
/// chunks that each fit [maxHeight].
List<String> _splitWordIntoColumns(
  String word, {
  required TextStyle style,
  required double maxHeight,
}) {
  final runes = word.runes.toList();
  var n = (measureMongolColumn(word, style).height / maxHeight).ceil();
  if (n < 1) n = 1;
  while (true) {
    final per = (runes.length / n).ceil();
    final chunks = <String>[];
    var ok = true;
    for (var i = 0; i < runes.length; i += per) {
      final end = (i + per).clamp(0, runes.length);
      final chunk = String.fromCharCodes(runes.sublist(i, end));
      chunks.add(chunk);
      if (measureMongolColumn(chunk, style).height > maxHeight) {
        ok = false;
      }
    }
    if (ok || n >= runes.length) return chunks;
    n++;
  }
}
