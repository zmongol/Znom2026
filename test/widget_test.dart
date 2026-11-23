import 'dart:convert';
import 'dart:io';

import 'package:book_app/functions/load_book_json.dart';
import 'package:book_app/main.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/services/book_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // path_provider has no platform implementation in flutter_test, so
  // getApplicationDocumentsDirectory() would hang. Point it at a temp dir.
  setUpAll(() {
    final docs = Directory('/tmp/znom-test-docs')..createSync(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall call) async {
        if (call.method == 'getApplicationDocumentsDirectory') {
          return docs.path;
        }
        return null;
      },
    );
  });

  test('bundled books are discovered and parse', () async {
    final files = await loadBookFiles();
    expect(files.length, 4, reason: 'the 4 bundled books in assets/json/books/');

    int parsed = 0;
    for (final f in files) {
      final data = await loadBookJson(f);
      expect(data, isNotNull);
      var book = Book.fetch(data!['items'] as List<dynamic>);
      if (book.title.trim().isEmpty) {
        // Same fallback as BookCtrl.loadBooks: filename stands in for title.
        book.title = f.split('/').last.replaceAll('.json', '');
      }
      expect(book.title.trim(), isNotEmpty);
      expect(book.chapters, isNotEmpty);
      parsed++;
    }
    expect(parsed, 4);
  });

  test('full-text search finds a word from the Secret History', () async {
    final files = await loadBookFiles();
    final books = <Book>[];
    for (final f in files) {
      final data = await loadBookJson(f);
      books.add(Book.fetch(data!['items'] as List<dynamic>));
    }
    // Take a real word straight out of the first chapter's content so the
    // test does not depend on hand-typed Z52.
    final first = books.first.chapters.first.content ?? '';
    expect(first.length, greaterThan(10));
    final word = first.split(' ').firstWhere((w) => w.length > 2);
    final results = BookSearchService.search(word, books);
    expect(results, isNotEmpty);
    expect(results.first.matchCount, greaterThan(0));
  });

  testWidgets('welcome screen renders', (tester) async {
    // Phone-sized surface: the welcome column overflows the 800x600 default.
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: WelcomeScreen()));
    // Title is a RichText with two spans, so match by containing text.
    expect(find.textContaining('Znom-', findRichText: true), findsOneWidget);
    expect(find.textContaining('CahimDorlal', findRichText: true),
        findsOneWidget);
  });

  test('book JSON files are valid JSON', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final name in [
      'assets/json/books/SecretHistoryOfMongols.json',
      'assets/json/books/Compendium of Chronicles.json',
      'assets/json/books/LookingForBook.json',
    ]) {
      final raw = await rootBundle.loadString(name);
      expect(jsonDecode(raw), isA<Map<String, dynamic>>());
    }
  });
}
