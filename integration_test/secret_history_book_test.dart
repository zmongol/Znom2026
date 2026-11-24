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

// Secret History (新译注《蒙古秘史》) as page images: home -> details ->
// image reader, turning pages by the Next button. Screenshots are taken
// from outside with `xcrun simctl io <UDID> screenshot` (explicit UDID —
// several simulators are booted, `booted` picks the wrong one) when the
// SHOT_* markers below appear in the test log (each pause is 15s).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('secret history image book: home, details, reader pages',
      (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Znom-', findRichText: true), findsOneWidget);

    await tester.tap(find.text('уншиж эхлэх'));
    await tester.pump(const Duration(seconds: 2));

    // The Secret History book is bundled in the app — it is in the library
    // at startup, no FTP wait. Poll briefly as a safety net.
    final ctrl = Get.find<BookCtrl>();
    var found = false;
    for (var i = 0; i < 12 && !found; i++) {
      await Future.delayed(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      found = ctrl.booksList
          .any((b) => b.isImageBook && b.pagePrefix == 'secret-history');
    }
    expect(found, isTrue, reason: 'Secret History image book in the library');
    // Both image books present: Folk Tales + Secret History.
    expect(
        ctrl.booksList.where((b) => b.isImageBook).length, greaterThanOrEqualTo(2),
        reason: 'both page-image books in the library');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Featured Books'), findsOneWidget);
    debugPrint('>>>SHOT_HOME<<<');
    await Future.delayed(const Duration(seconds: 15));

    // Open the Secret History card: grid titles follow booksList order, and
    // MongolText[0] is the hero banner.
    final imageIndex = ctrl.booksList
        .indexWhere((b) => b.isImageBook && b.pagePrefix == 'secret-history');
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
    expect(find.text('1 / 463'), findsOneWidget);
    debugPrint('>>>SHOT_READER_P1<<<');
    await Future.delayed(const Duration(seconds: 15));

    // Page-turning via the Next button (deterministic +1).
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('2 / 463'), findsOneWidget);
    debugPrint('>>>SHOT_READER_P2<<<');
    await Future.delayed(const Duration(seconds: 15));

    // Next button to page 3.
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('3 / 463'), findsOneWidget);
    debugPrint('>>>SHOT_READER_P3<<<');
    await Future.delayed(const Duration(seconds: 15));

    // Let any snackbar finish before teardown.
    await tester.pump(const Duration(seconds: 4));
  });
}
