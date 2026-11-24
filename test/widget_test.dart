import 'dart:convert';
import 'dart:io';

import 'package:book_app/functions/load_book_json.dart';
import 'package:book_app/main.dart';
import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/services/book_search_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// Books are no longer bundled in the app: the library loads ONLY from the
// local books dir (files downloaded from the book server by
// BookSyncService). These tests therefore seed that dir with small fixture
// JSONs instead of reading bundled assets.

const _textBookOne = '''
{"items": [
  {"title": "Test Book One", "image": "assets/images/book1.png",
   "auth": "Test Author", "content": "First chapter text with searchableword inside.",
   "rating": 4.5, "chapterNumber": 1, "chapterTitle": "Chapter One"},
  {"title": "Test Book One", "image": "", "auth": "",
   "content": "Second chapter content here.",
   "rating": 4.5, "chapterNumber": 2, "chapterTitle": "Chapter Two"}
]}
''';

const _textBookTwo = '''
{"items": [
  {"title": "Test Book Two", "image": "assets/images/book-2.png",
   "auth": "Another Author", "content": "Unrelated second book text.",
   "rating": 4.0, "chapterNumber": 1, "chapterTitle": "Only Chapter"}
]}
''';

const _imageBook = '''
{"items": [
  {"title": "Test Image Book", "image": "folktales-test.jpg",
   "auth": "Tester", "content": "A scanned book.",
   "rating": 4.9, "type": "image", "pageCount": 12, "pagePrefix": "folktales-test",
   "chapterNumber": 1, "chapterTitle": "Pages"}
]}
''';

void main() {
  // path_provider has no platform implementation in flutter_test, so
  // getApplicationDocumentsDirectory() would hang. Point it at a temp dir.
  final docs = Directory('/tmp/znom-test-docs');
  final booksDir = Directory('${docs.path}/books');

  setUpAll(() {
    docs.createSync(recursive: true);
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

  setUp(() {
    // Fresh-install state by default: empty books dir.
    if (booksDir.existsSync()) booksDir.deleteSync(recursive: true);
    booksDir.createSync(recursive: true);
  });

  Future<void> seedBooks() async {
    await File('${booksDir.path}/Test Book One.json').writeAsString(_textBookOne);
    await File('${booksDir.path}/Test Book Two.json').writeAsString(_textBookTwo);
    await File('${booksDir.path}/Test Image Book.json').writeAsString(_imageBook);
  }

  test('loadBookFiles returns only server-synced local books', () async {
    await seedBooks();
    final files = await loadBookFiles();
    expect(files.length, 3,
        reason: 'the 3 seeded books in the local books dir');
    for (final f in files) {
      expect(f.startsWith(booksDir.path), isTrue);
      expect(f.endsWith('.json'), isTrue);
    }
  });

  test('empty books dir returns an empty list (fresh install, no crash)',
      () async {
    final files = await loadBookFiles();
    expect(files, isEmpty);
    expect(await loadBookJson('${booksDir.path}/missing.json'), isNull);
  });

  test('loadBookJson ignores non-file (asset) paths', () async {
    expect(await loadBookJson('assets/json/books/SecretHistoryOfMongols.json'),
        isNull);
  });

  test('seeded books parse and full-text search finds a word', () async {
    await seedBooks();
    final files = await loadBookFiles();
    final books = <Book>[];
    for (final f in files) {
      final data = await loadBookJson(f);
      expect(data, isNotNull);
      var book = Book.fetch(data!['items'] as List<dynamic>);
      if (book.title.trim().isEmpty) {
        book.title = f.split('/').last.replaceAll('.json', '');
      }
      expect(book.title.trim(), isNotEmpty);
      expect(book.chapters, isNotEmpty);
      books.add(book);
    }
    expect(books.length, 3);
    expect(books.where((b) => b.isImageBook).length, 1);
    final results = BookSearchService.search('searchableword', books);
    expect(results, isNotEmpty);
    expect(results.first.matchCount, greaterThan(0));
    expect(results.first.book.title, 'Test Book One');
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

  test('seeded book JSON files are valid JSON', () async {
    await seedBooks();
    for (final f in await loadBookFiles()) {
      final raw = await File(f).readAsString();
      expect(jsonDecode(raw), isA<Map<String, dynamic>>());
    }
  });
}
