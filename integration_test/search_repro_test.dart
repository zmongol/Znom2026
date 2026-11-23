import 'package:book_app/main.dart' as app;
import 'package:book_app/screens/home_screen.dart';
import 'package:book_app/screens/search_results_screen.dart';
import 'package:book_app/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mongol/mongol.dart';

// Search screen regression test (redesigned 24 Nov 2026).
// One test only: this app's GetX controllers + FTP timer do not survive a
// second app.main() in the same file (later tests find no welcome screen).
// Flow: welcome -> home -> search (assert redesigned UI) -> tap an example
// word card -> results with matches -> back -> type a Z52 word -> Search
// -> results with matches.
// NOTE: MongolTextField is built on MongolEditableText, not Flutter's
// EditableText, so tester.enterText cannot find it. Text is driven through
// the platform text-input channel instead (tap to focus, then enter).
// NOTE: the example card is tapped on the fresh search screen; tapping it
// after pageBack() misses hit-test in the harness (the scroll view state
// after the pop leaves the card's reported centre off the visible card),
// so the typed search runs second, after the back navigation.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('redesigned search: UI, example search, typed search',
      (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Znom-', findRichText: true), findsOneWidget);

    await tester.tap(find.text('уншиж эхлэх'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Featured Books'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SearchScreen), findsOneWidget);

    // ── Redesigned UI is present ──────────────────────────────────────
    expect(find.byType(MongolTextField), findsOneWidget);
    expect(find.textContaining('Type in Mongolian'), findsOneWidget);
    expect(find.text('Try one:'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.byIcon(Icons.paste), findsOneWidget);
    final mongolWord = find.byWidgetPredicate(
        (w) => w is MongolText && w.data == 'ᢌᡭᡪᢊᡱᡱᡭᢐ');
    expect(mongolWord, findsOneWidget);
    final exampleCard =
        find.byKey(const ValueKey('example-ᢌᡭᡪᢊᡱᡱᡭᢐ'));
    expect(exampleCard, findsOneWidget);

    // ── Example card: tap the Mongol word card, it searches directly ───
    await tester.ensureVisible(exampleCard);
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(exampleCard);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SearchResultsScreen), findsOneWidget);
    expect(find.textContaining('match'), findsWidgets);

    // ── Typed search: Z52 word known to occur in the books ────────────
    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SearchScreen), findsOneWidget);

    await tester.tap(find.byType(MongolTextField));
    await tester.pump(const Duration(seconds: 1));
    tester.testTextInput.enterText('ᡥᢚᡧ');
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Search'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(SearchResultsScreen), findsOneWidget);
    expect(find.textContaining('match'), findsWidgets);

    // ── Settle: close any late "Library Updated" snackbar (repeat: the
    // FTP reload notification can land after the first close). Otherwise
    // the Overlay ticker assertion fires when the binding disposes the
    // tree at teardown. ─────────────────────────────────────────────────
    for (var i = 0; i < 3; i++) {
      Get.closeAllSnackbars();
      await tester.pump(const Duration(seconds: 2));
    }
    await tester.pump(const Duration(seconds: 3));
  });
}
