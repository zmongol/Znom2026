import 'package:book_app/main.dart' as app;
import 'package:book_app/screens/details_screen.dart';
import 'package:book_app/screens/home_screen.dart';
import 'package:book_app/screens/reading_screen.dart';
import 'package:book_app/widgets/chapter_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mongol/mongol.dart';

// Same flow as app_test.dart, but pauses 15s on each screen so screenshots
// can be taken from outside with `xcrun simctl io booted screenshot`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot walkthrough', (tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('Znom-', findRichText: true), findsOneWidget);
    await Future.delayed(const Duration(seconds: 15));

    await tester.tap(find.text('уншиж эхлэх'));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Featured Books'), findsOneWidget);
    await Future.delayed(const Duration(seconds: 15));

    await tester.tap(find.byType(MongolText).at(1));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(DetailsScreen), findsOneWidget);
    await Future.delayed(const Duration(seconds: 15));

    await tester.tap(find.byType(ChapterCard).first);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(ReadingScreen), findsOneWidget);
    await Future.delayed(const Duration(seconds: 15));
  });
}
