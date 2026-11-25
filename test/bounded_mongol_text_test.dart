import 'package:book_app/core/constants/app_fonts.dart';
import 'package:book_app/core/constants/ui_strings.dart';
import 'package:book_app/widgets/bounded_mongol_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mongol/mongol.dart';

// Regression lock for the 1.0.3 "columns, not rows" defect: Mongolian
// text must stand in upright columns that fit their box — a single
// word taller than the box (the old home header, the settings-sheet
// heading) must be split/shrunk, never painted past the box.
void main() {
  const style = TextStyle(
    fontFamily: AppFonts.dardastig,
    fontSize: 21,
    fontWeight: FontWeight.bold,
  );

  test('a too-tall single word is split into columns that each fit', () {
    // UiStrings.settings is one 13-glyph word — at 18pt its single
    // column is far taller than the 48pt sheet-heading box.
    const wordStyle = TextStyle(
      fontFamily: AppFonts.dardastig,
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );
    final whole = measureMongolColumn(UiStrings.settings, wordStyle);
    expect(whole.height, greaterThan(48),
        reason: 'precondition: the unsplit word really is too tall');
    final columns = splitMongolColumns(
      UiStrings.settings,
      style: wordStyle,
      maxHeight: 48,
    );
    expect(columns.length, greaterThan(1));
    for (final column in columns) {
      expect(
          measureMongolColumn(column, wordStyle).height, lessThanOrEqualTo(48));
    }
    // No glyphs lost or duplicated by the split.
    expect(columns.join(), UiStrings.settings.replaceAll(' ', ''));
  });

  test('a two-word header splits by whole words first', () {
    final columns = splitMongolColumns(
      UiStrings.continueReading,
      style: style,
      maxHeight: 88,
    );
    for (final column in columns) {
      expect(measureMongolColumn(column, style).height, lessThanOrEqualTo(88));
    }
    // No glyphs lost or duplicated (a too-tall word is split between
    // code points, so compare with spaces removed).
    expect(columns.join().replaceAll(' ', ''),
        UiStrings.continueReading.replaceAll(' ', ''));
  });

  testWidgets('widget height never exceeds maxHeight, no overflow',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: BoundedMongolText(
              UiStrings.continueReading,
              maxHeight: 88,
              maxColumns: 4,
              style: style,
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(BoundedMongolText));
    expect(size.height, lessThanOrEqualTo(88));
    expect(size.width, lessThanOrEqualTo(360));
    // Regression: a caller style with no color must still paint —
    // the rendered MongolText has to carry a concrete color (with
    // inherit off and color null, the paragraph paints nothing).
    final rendered = tester.widgetList<MongolText>(find.byType(MongolText));
    expect(rendered, isNotEmpty);
    for (final w in rendered) {
      expect(w.style?.color, isNotNull);
    }
  });

  testWidgets('long book title in a narrow app-bar box stays inside',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            child: BoundedMongolText(
              'ᢘᡭᡪᢊᡱᡱᡪᢑᡪᢇ ᢘᡪᢎᡬᢝ',
              maxHeight: 42,
              maxColumns: 8,
              minFontSize: 8,
              style: TextStyle(
                fontFamily: AppFonts.dardastig,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final size = tester.getSize(find.byType(BoundedMongolText));
    expect(size.height, lessThanOrEqualTo(42));
    expect(size.width, lessThanOrEqualTo(180));
  });
}
