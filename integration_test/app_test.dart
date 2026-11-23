import 'package:book_app/global_controllers/books_ctrl.dart';
import 'package:book_app/main.dart' as app;
import 'package:book_app/screens/details_screen.dart';
import 'package:book_app/screens/home_screen.dart';
import 'package:book_app/screens/reading_screen.dart';
import 'package:book_app/widgets/chapter_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mongol/mongol.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('launch, home shows books, open a book in the reader',
      (tester) async {
    // Real app entry: GetStorage init + controllers + runApp.
    // (void async: cannot be awaited; the pumps below let it finish.)
    app.main();
    // Explicit pumps only: the 1-minute FTP sync timer blocks pumpAndSettle.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Znom-', findRichText: true), findsOneWidget);

    // Start reading -> home.
    await tester.tap(find.text('уншиж эхлэх'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Featured Books'), findsOneWidget);
    // MongolText[0] is the hero banner; grid titles follow in booksList
    // order. Tap the first TEXT book card — the Folk Tales image book may
    // sort first after the FTP sync, and it opens the image reader,
    // not the text reader this test exercises.
    final ctrl = Get.find<BookCtrl>();
    final textIndex = ctrl.booksList.indexWhere((b) => !b.isImageBook);
    expect(textIndex, greaterThanOrEqualTo(0));
    await tester.tap(find.byType(MongolText).at(textIndex + 1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DetailsScreen), findsOneWidget);

    // Open the first chapter -> reader.
    await tester.tap(find.byType(ChapterCard).first);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ReadingScreen), findsOneWidget);
    // Let any "Library Updated" snackbar from the first FTP sync finish
    // its animation before teardown (else the overlay ticker assertion
    // fires when the test binding disposes the tree).
    await tester.pump(const Duration(seconds: 4));
  });
}
