import 'package:book_app/global_controllers/books_ctrl.dart';
import 'package:book_app/main.dart' as app;
import 'package:book_app/screens/details_screen.dart';
import 'package:book_app/screens/home_screen.dart';
import 'package:book_app/screens/image_reading_screen.dart';
import 'package:book_app/widgets/chapter_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mongol/mongol.dart';

// Folk Tales (1979) as page images: home -> details -> image reader,
// turning pages by swipe and by the Next button. Screenshots are taken
// from outside with `xcrun simctl io <UDID> screenshot` (explicit UDID —
// several simulators are booted, `booted` picks the wrong one) when the
// SHOT_* markers below appear in the test log (each pause is 15s).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('folk tales image book: home, details, reader pages',
      (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Znom-', findRichText: true), findsOneWidget);

    await tester.tap(find.text('уншиж эхлэх'));
    await tester.pump(const Duration(seconds: 2));

    // The Folk Tales book is bundled in the app — it is in the library at
    // startup, no FTP wait. Poll briefly as a safety net.
    final ctrl = Get.find<BookCtrl>();
    var found = false;
    for (var i = 0; i < 12 && !found; i++) {
      await Future.delayed(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      found = ctrl.booksList.any((b) => b.isImageBook);
    }
    expect(found, isTrue, reason: 'Folk Tales image book in the library');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Featured Books'), findsOneWidget);
    debugPrint('>>>SHOT_HOME<<<');
    await Future.delayed(const Duration(seconds: 15));

    // Open the Folk Tales card: grid titles follow booksList order, and
    // MongolText[0] is the hero banner.
    final imageIndex =
        ctrl.booksList.indexWhere((b) => b.isImageBook);
    expect(imageIndex, greaterThanOrEqualTo(0));
    await tester.tap(find.byType(MongolText).at(imageIndex + 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DetailsScreen), findsOneWidget);
    debugPrint('>>>SHOT_DETAILS<<<');
    await Future.delayed(const Duration(seconds: 15));

    // Open the reader from the first chapter card.
    await tester.tap(find.byType(ChapterCard).first);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ImageReadingScreen), findsOneWidget);
    expect(find.text('1 / 274'), findsOneWidget);
    debugPrint('>>>SHOT_READER_P1<<<');
    await Future.delayed(const Duration(seconds: 15));

    // Page-turning via the Next button (deterministic +1). A test-harness
    // drag cannot land on exactly one page: tester drags move at constant
    // velocity and never decelerate, so the PageView's friction ballistic
    // carries them several pages (verified: a -300px/1s drag built pages
    // 1-6). A real finger decelerates before lifting, so a gentle swipe
    // on the phone lands on the next page.
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2 / 274'), findsOneWidget);
    debugPrint('>>>SHOT_READER_P2<<<');
    await Future.delayed(const Duration(seconds: 15));

    // Next button to page 3.
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('3 / 274'), findsOneWidget);
    debugPrint('>>>SHOT_READER_P3<<<');
    await Future.delayed(const Duration(seconds: 15));

    // Swipe diagnostic (no assert): a decelerating finger-style drag.
    // Prints the page it lands on.
    final gesture = await tester.startGesture(
        tester.getCenter(find.byType(ImageReadingScreen)));
    for (final step in <double>[60, 55, 50, 45, 40, 30, 20, 10, 5, 2, 1, 0.5]) {
      await gesture.moveBy(Offset(-step, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    final pageCtrl =
        tester.widget<PageView>(find.byType(PageView)).controller;
    debugPrint('>>>DIAG decelerating swipe landed on page: ${pageCtrl?.page}');

    // Let any snackbar finish before teardown.
    await tester.pump(const Duration(seconds: 4));
  });
}
