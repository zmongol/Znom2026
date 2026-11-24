import 'package:book_app/services/book_server_config.dart';
import 'package:book_app/services/book_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parseManifest accepts a top-level list', () {
    final entries = BookSyncService.parseManifest([
      {
        'path': 'SecretHistoryOfMongols.json',
        'size': 1234,
        'mtime': 1790000000, // epoch seconds
      },
      {
        'path': 'output/folktales-1979-p001.jpg',
        'size': 5678,
        'mtime': 1790000000000, // epoch milliseconds
      },
      {'path': 'notes.txt', 'size': 10, 'mtime': 1},
      {
        'path': 'other/folktales-1979-p001.jpg',
        'size': 9999,
        'mtime': 1,
      },
    ]);
    // .txt is filtered out; the duplicate basename keeps the first entry.
    expect(entries.length, 2);
    expect(entries[0].relativePath, 'SecretHistoryOfMongols.json');
    expect(entries[0].fileName, 'SecretHistoryOfMongols.json');
    expect(entries[0].size, 1234);
    expect(entries[0].mtime, isNotNull);
    expect(entries[1].relativePath, 'output/folktales-1979-p001.jpg');
    expect(entries[1].fileName, 'folktales-1979-p001.jpg');
    expect(entries[1].size, 5678);
  });

  test('parseManifest accepts an object with a files list', () {
    final entries = BookSyncService.parseManifest({
      'files': [
        {'name': 'a.json', 'bytes': 42, 'modified': '2026-11-24T10:00:00Z'},
      ],
    });
    expect(entries.length, 1);
    expect(entries[0].relativePath, 'a.json');
    expect(entries[0].size, 42);
    expect(entries[0].mtime?.toUtc().toIso8601String(),
        '2026-11-24T10:00:00.000Z');
  });

  test('parseManifest throws on a manifest with no file list', () {
    expect(() => BookSyncService.parseManifest({'nope': true}),
        throwsA(isA<FormatException>()));
    expect(() => BookSyncService.parseManifest('garbage'),
        throwsA(isA<FormatException>()));
  });

  test('fileUri percent-encodes spaces and non-ASCII names', () {
    final spaced = BookSyncService.fileUri('Compendium of Chronicles.json');
    expect(spaced.path, endsWith('/Compendium%20of%20Chronicles.json'));
    final nested =
        BookSyncService.fileUri('output/folktales-1979-p001.jpg');
    expect(nested.path, endsWith('/output/folktales-1979-p001.jpg'));
    final unicode = BookSyncService.fileUri('books/abc.json');
    // Scheme/host come from the configured server URL (public HTTPS URL
    // now; was the loopback HTTP test URL before) — not hardcoded.
    final base = Uri.parse(BookServerConfig.baseUrl);
    expect(unicode.scheme, base.scheme);
    expect(unicode.host, base.host);
  });
}
