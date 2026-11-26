import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zmongol_kit/zmongol_kit.dart';

import '../models/books/book_model.dart';
import 'book_catalog.dart';

/// Znom's Google OAuth client ids — filled in when Znom's own Google
/// Cloud project is created. While a platform's id is empty, Google
/// sign-in is simply unavailable there (Apple sign-in is unaffected).
const String kZnomGoogleIosClientId = '';
const String kZnomGoogleServerClientId = '';

/// Owns everything about charging: the shared Zmongol account, the
/// server catalogue, and who may read what.
///
/// Two entitlement sources, one answer:
///  * the account service (Stripe purchases on Android/Windows, checked
///    with the signed-in account): `znom`/`pro` and `znom-book:<id>`;
///  * Apple In-App Purchase on iOS/macOS, which lives on the device
///    (subscription status + restored purchases), persisted locally.
class AccessService extends GetxService {
  late final ZmongolAccount account;

  final catalog = BookCatalog.empty().obs;
  final serverPro = false.obs;
  final iapPro = false.obs;
  final ownedBooks = <String>{}.obs;
  final iapBooks = <String>{}.obs;

  static const proProductId = 'znom_pro_yearly';
  static String bookProductId(String bookId) =>
      'znom_book_${bookId.replaceAll('-', '_')}';
  static String bookIdFromProduct(String productId) =>
      productId.substring('znom_book_'.length).replaceAll('_', '-');

  static const _proLink = 'https://buy.stripe.com/4gM6oGcqVffAaIv7kucs808';
  static const _bookLinks = <String, String>{
    'tonggalag-tamir': 'https://buy.stripe.com/8x2eVcbmR2sO7wjfR0cs80b',
    'urun-toyaga': 'https://buy.stripe.com/6oU14m2Qlc3o5ob0W6cs80c',
    'soraaaaadani-baqi-qadun': 'https://buy.stripe.com/bJefZg9eJ8Rc6sf7kucs80d',
  };

  static bool get isApplePlatform =>
      !kIsWeb && (Platform.isIOS || Platform.isMacOS);

  bool get proActive => serverPro.value || iapPro.value;

  bool ownsBook(String? bookId) =>
      bookId != null &&
      (ownedBooks.contains(bookId) || iapBooks.contains(bookId));

  /// The one gating question every entry point asks. Safe to call from
  /// widgets before this service exists (tests, previews): an
  /// unregistered service means "no charging yet" — everything opens.
  static bool canOpenChapter(Book book, int chapterIndex) {
    if (!Get.isRegistered<AccessService>()) return true;
    return Get.find<AccessService>().canOpen(book, chapterIndex);
  }

  bool canOpen(Book book, int chapterIndex) {
    final entry = catalog.value.entryFor(book.sourceFile);
    if (entry == null || entry.tier == BookTier.free) return true;
    if (chapterIndex < catalog.value.previewChapters) return true;
    switch (entry.tier) {
      case BookTier.pro:
        return proActive;
      case BookTier.premium:
        return ownsBook(entry.bookId);
      case BookTier.free:
        return true;
    }
  }

  CatalogEntry? entryFor(Book book) => catalog.value.entryFor(book.sourceFile);

  @override
  void onInit() {
    super.onInit();
    account = ZmongolAccount(appId: 'znom', googleClientId: _googleClientId);
    _bootstrap();
  }

  String? get _googleClientId {
    if (kIsWeb) return null;
    if (Platform.isIOS) {
      return kZnomGoogleIosClientId.isEmpty ? null : kZnomGoogleIosClientId;
    }
    if (Platform.isAndroid) {
      return kZnomGoogleServerClientId.isEmpty
          ? null
          : kZnomGoogleServerClientId;
    }
    return null;
  }

  Future<void> _bootstrap() async {
    try {
      await account.restore();
    } catch (_) {
      // Offline or expired session: reading (and previews) still work.
    }
    await reloadCatalog();
    await refreshEntitlements();
    if (isApplePlatform) _initIap();
  }

  Future<void> reloadCatalog() async {
    catalog.value = await BookCatalog.loadLocal();
  }

  Future<void> refreshEntitlements() async {
    if (!account.isSignedIn) {
      serverPro.value = false;
      ownedBooks.clear();
      return;
    }
    try {
      final list = await account.entitlements();
      var pro = false;
      final books = <String>{};
      for (final e in list) {
        if (!e.isActive) continue;
        if (e.app == 'znom' && e.tier == 'pro') pro = true;
        if (e.app.startsWith('znom-book:')) {
          books.add(e.app.substring('znom-book:'.length));
        }
      }
      serverPro.value = pro;
      ownedBooks.assignAll(books);
    } catch (_) {
      // Keep the last known state on a network failure.
    }
  }

  Future<void> signOut() async {
    await account.signOut();
    await refreshEntitlements();
  }

  // ── Apple In-App Purchase (iOS/macOS) ─────────────────────────────

  // Lazy: touching InAppPurchase.instance starts a store connection,
  // which must only happen on Apple platforms, when IAP actually runs.
  InAppPurchase get _iap => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _iapSub;

  void _initIap() {
    final box = GetStorage();
    iapPro.value = box.read('znom.iap.pro') == true;
    final stored = box.read<List>('znom.iap.books') ?? const [];
    iapBooks.assignAll(stored.map((e) => e.toString()));
    _iapSub = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (_) {},
    );
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    final box = GetStorage();
    for (final p in purchases) {
      if (p.status == PurchaseStatus.purchased ||
          p.status == PurchaseStatus.restored) {
        if (p.productID == proProductId) {
          iapPro.value = true;
          await box.write('znom.iap.pro', true);
        } else if (p.productID.startsWith('znom_book_')) {
          iapBooks.add(bookIdFromProduct(p.productID));
          await box.write('znom.iap.books', iapBooks.toList());
        }
      }
      if (p.pendingCompletePurchase) {
        await _iap.completePurchase(p);
      }
    }
  }

  /// Buy [productId] through Apple. Returns false when the store is
  /// unreachable or the product does not exist (yet).
  Future<bool> buyViaIap(String productId) async {
    if (!await _iap.isAvailable()) return false;
    final response = await _iap.queryProductDetails({productId});
    if (response.productDetails.isEmpty) return false;
    return _iap.buyNonConsumable(
      purchaseParam:
          PurchaseParam(productDetails: response.productDetails.first),
    );
  }

  Future<void> restoreIap() => _iap.restorePurchases();

  // ── Stripe payment links (Android/Windows) ────────────────────────

  /// Open the Stripe checkout for Pro (book == null) or for a premium
  /// [book]. The signed-in account's id rides along as the checkout's
  /// client reference, so the webhook grants the entitlement to this
  /// account. Returns false when signed out or no link exists.
  Future<bool> buyViaStripe(Book? book) async {
    final user = account.user;
    if (user == null) return false;
    final String base;
    if (book == null) {
      base = _proLink;
    } else {
      final entry = entryFor(book);
      base = _bookLinks[entry?.bookId] ?? _proLink;
    }
    final uri = Uri.parse('$base?client_reference_id=${user.id}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void onClose() {
    _iapSub?.cancel();
    super.onClose();
  }
}
