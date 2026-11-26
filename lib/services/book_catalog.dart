import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Which shelf a book sits on.
enum BookTier { free, pro, premium }

class CatalogEntry {
  final BookTier tier;

  /// Premium books only: the stable book id used for entitlements and
  /// purchase products (e.g. "tonggalag-tamir").
  final String? bookId;

  /// Premium books only: display price, e.g. "$4.99".
  final String? priceLabel;

  const CatalogEntry(this.tier, {this.bookId, this.priceLabel});
}

/// The charging catalogue. The book server serves it as `catalog.json`;
/// the normal book sync downloads it into the books folder like any
/// other file, so tiers can be changed on the server with no app
/// update. When no catalogue has been downloaded yet (first launch,
/// before the first sync lands), every book reads as free.
class BookCatalog {
  final Map<String, CatalogEntry> entries;

  /// How many chapters of a paid book anyone may read free.
  final int previewChapters;

  /// Display price of the Pro subscription, e.g. "$4.99/year".
  final String proPriceLabel;

  const BookCatalog({
    required this.entries,
    this.previewChapters = 3,
    this.proPriceLabel = '\$4.99/year',
  });

  factory BookCatalog.empty() => const BookCatalog(entries: {});

  factory BookCatalog.fromJson(Map<String, dynamic> json) {
    final raw = (json['books'] as Map?) ?? {};
    final map = <String, CatalogEntry>{};
    raw.forEach((key, value) {
      final v = (value as Map?) ?? {};
      final tierName = v['tier']?.toString() ?? 'free';
      map[key.toString()] = CatalogEntry(
        tierName == 'pro'
            ? BookTier.pro
            : tierName == 'premium'
                ? BookTier.premium
                : BookTier.free,
        bookId: v['bookId']?.toString(),
        priceLabel: v['priceLabel']?.toString(),
      );
    });
    return BookCatalog(
      entries: map,
      previewChapters: (json['previewChapters'] as num?)?.toInt() ?? 3,
      proPriceLabel: json['proPriceLabel']?.toString() ?? '\$4.99/year',
    );
  }

  CatalogEntry? entryFor(String sourceFile) => entries[sourceFile];

  /// Load `catalog.json` from the downloaded books folder, if present.
  static Future<BookCatalog> loadLocal() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(path.join(dir.path, 'books', 'catalog.json'));
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          return BookCatalog.fromJson(decoded);
        }
      }
    } catch (_) {
      // A broken catalogue must never break the library: fall through.
    }
    return BookCatalog.empty();
  }
}
