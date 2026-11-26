import 'package:book_app/models/books/book_model.dart';
import 'package:book_app/services/access_service.dart';
import 'package:book_app/services/book_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

Book bookWith(String sourceFile, int chapters) {
  final b = Book(title: sourceFile);
  b.sourceFile = sourceFile;
  b.chapters = const [];
  return b;
}

void main() {
  // AccessService's field initializers touch InAppPurchase.instance,
  // which needs the binding even though no store call is made.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BookCatalog.fromJson', () {
    test('parses tiers, preview count and defaults', () {
      final catalog = BookCatalog.fromJson({
        'previewChapters': 3,
        'proPriceLabel': '\$4.99/year',
        'books': {
          'A.json': {'tier': 'free'},
          'B.json': {'tier': 'pro'},
          'C.json': {
            'tier': 'premium',
            'bookId': 'book-c',
            'priceLabel': '\$4.99',
          },
          'D.json': {'tier': 'something-else'},
        },
      });
      expect(catalog.previewChapters, 3);
      expect(catalog.entryFor('A.json')!.tier, BookTier.free);
      expect(catalog.entryFor('B.json')!.tier, BookTier.pro);
      expect(catalog.entryFor('C.json')!.tier, BookTier.premium);
      expect(catalog.entryFor('C.json')!.bookId, 'book-c');
      expect(catalog.entryFor('D.json')!.tier, BookTier.free);
      expect(catalog.entryFor('missing.json'), isNull);
    });
  });

  group('AccessService.canOpen', () {
    late AccessService access;

    setUp(() {
      // Direct construction: Get lifecycle (onInit) never runs, so no
      // account, storage or store calls happen — only the Rx fields
      // below drive the gate.
      access = AccessService();
      access.catalog.value = BookCatalog.fromJson({
        'previewChapters': 3,
        'books': {
          'Free.json': {'tier': 'free'},
          'Pro.json': {'tier': 'pro'},
          'Novel.json': {
            'tier': 'premium',
            'bookId': 'novel',
            'priceLabel': '\$4.99',
          },
        },
      });
    });

    test('free and unlisted books open at any chapter', () {
      expect(access.canOpen(bookWith('Free.json', 10), 9), isTrue);
      expect(access.canOpen(bookWith('Unknown.json', 10), 9), isTrue);
    });

    test('paid books open their first 3 chapters to everyone', () {
      expect(access.canOpen(bookWith('Pro.json', 10), 0), isTrue);
      expect(access.canOpen(bookWith('Pro.json', 10), 2), isTrue);
      expect(access.canOpen(bookWith('Novel.json', 10), 2), isTrue);
    });

    test('pro chapters past the preview need Pro', () {
      expect(access.canOpen(bookWith('Pro.json', 10), 3), isFalse);
      access.serverPro.value = true;
      expect(access.canOpen(bookWith('Pro.json', 10), 3), isTrue);
    });

    test('premium chapters past the preview need ownership, not Pro', () {
      access.serverPro.value = true;
      expect(access.canOpen(bookWith('Novel.json', 10), 3), isFalse);
      access.ownedBooks.add('novel');
      expect(access.canOpen(bookWith('Novel.json', 10), 3), isTrue);
    });

    test('iap state also unlocks (Apple platforms)', () {
      access.iapPro.value = true;
      expect(access.canOpen(bookWith('Pro.json', 10), 5), isTrue);
      access.iapBooks.add('novel');
      expect(access.canOpen(bookWith('Novel.json', 10), 5), isTrue);
    });
  });

  group('product id mapping', () {
    test('book product ids round-trip', () {
      expect(AccessService.bookProductId('tonggalag-tamir'),
          'znom_book_tonggalag_tamir');
      expect(
          AccessService.bookIdFromProduct('znom_book_soraaaaadani_baqi_qadun'),
          'soraaaaadani-baqi-qadun');
    });
  });
}
