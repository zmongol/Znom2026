import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zmongol_kit/zmongol_kit.dart';

import '../Component/MongolFonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/ui_strings.dart';
import '../models/books/book_model.dart';
import '../services/access_service.dart';
import '../services/book_catalog.dart';
import '../widgets/bounded_mongol_text.dart';

/// The paywall shown when a reader reaches a locked chapter.
///
/// Premium books are bought per book; standard-library books are
/// unlocked by Znom Pro. On iOS/macOS the purchase runs through Apple
/// In-App Purchase; on Android it runs through the Stripe payment link
/// tied to the signed-in Zmongol account. The first chapters of every
/// paid book are always free (see the catalogue's preview count).
class PaywallScreen extends StatelessWidget {
  final Book book;
  const PaywallScreen({super.key, required this.book});

  static Future<void> open(BuildContext context, Book book) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaywallScreen(book: book)),
    );
  }

  AccessService get _access => Get.find<AccessService>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Znom Pro',
            style: TextStyle(color: Colors.white, fontSize: 17)),
      ),
      body: Obx(() {
        final access = _access;
        final entry = access.entryFor(book);
        final isPremium = entry?.tier == BookTier.premium;
        final hasAccess = isPremium
            ? access.ownsBook(entry?.bookId)
            : access.proActive;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.lock_outline,
                  size: 44, color: AppColors.primary),
              const SizedBox(height: 16),
              Center(
                child: BoundedMongolText(
                  UiStrings.lockedChapter,
                  maxHeight: 60,
                  maxColumns: 6,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    fontFamily: MongolFonts.z52dardastig,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              const Text('This chapter is locked',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 10),
              Center(
                child: BoundedMongolText(
                  UiStrings.firstThreeFree,
                  maxHeight: 44,
                  maxColumns: 8,
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: MongolFonts.z52dardastig,
                    color: Colors.black87,
                  ),
                ),
              ),
              const Text('The first 3 chapters of every paid book are free',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 28),
              if (hasAccess) ...[
                const Text('You already have access to this book.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Back to the book'),
                ),
              ] else if (isPremium) ...[
                _offerCard(
                  context,
                  title: book.title,
                  price: entry?.priceLabel ?? '\$4.99',
                  caption: 'One-time purchase — yours to read forever. '
                      'Premium books are sold separately; Znom Pro does '
                      'not include them.',
                ),
                const SizedBox(height: 18),
                _purchaseArea(context, forBook: book),
              ] else ...[
                _offerCard(
                  context,
                  title: null,
                  price: access.catalog.value.proPriceLabel,
                  caption: 'Znom Pro unlocks the whole standard library '
                      'on every device signed into your account.',
                  z52Title: UiStrings.unlockAllBooks,
                ),
                const SizedBox(height: 18),
                _purchaseArea(context, forBook: null),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _offerCard(
    BuildContext context, {
    required String? title,
    required String price,
    required String caption,
    String? z52Title,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        border: Border.all(color: AppColors.primary.withOpacity(0.45)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          if (z52Title != null)
            BoundedMongolText(
              z52Title,
              maxHeight: 48,
              maxColumns: 6,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                fontFamily: MongolFonts.z52dardastig,
                color: AppColors.primary,
              ),
            )
          else if (title != null)
            BoundedMongolText(
              title,
              maxHeight: 64,
              maxColumns: 6,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                fontFamily: MongolFonts.z52dardastig,
                color: AppColors.primary,
              ),
            ),
          const SizedBox(height: 8),
          Text(price,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          Text(caption,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
        ],
      ),
    );
  }

  /// Buy / sign-in / refresh controls, routed by platform.
  /// [forBook] == null buys Pro; otherwise it buys that premium book.
  Widget _purchaseArea(BuildContext context, {required Book? forBook}) {
    final access = _access;
    if (AccessService.isApplePlatform) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            onPressed: () async {
              final productId = forBook == null
                  ? AccessService.proProductId
                  : AccessService.bookProductId(
                      access.entryFor(forBook)?.bookId ?? '');
              final ok = await access.buyViaIap(productId);
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content:
                        Text('The store is not available right now.')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(forBook == null ? 'Subscribe' : 'Buy this book'),
          ),
          TextButton(
            onPressed: () => access.restoreIap(),
            child: const Text('Restore purchases'),
          ),
        ],
      );
    }

    // Android / Windows: Stripe checkout tied to the Zmongol account.
    final signedIn = access.account.isSignedIn;
    if (!signedIn) {
      final canSignIn = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: BoundedMongolText(
              UiStrings.signIn,
              maxHeight: 40,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: MongolFonts.z52dardastig,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Sign in first, so the purchase lands on your account',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13)),
          const SizedBox(height: 14),
          if (canSignIn)
            ZmongolSignInButtons(
              account: access.account,
              showApple: false,
              showGoogle: true,
              onSignedIn: () => access.refreshEntitlements(),
              onError: (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sign-in failed.')));
                }
              },
            )
          else
            const Text(
                'Purchases are not available in the Windows app yet — '
                'buy on your phone with the same account, then tap '
                'Refresh here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 13)),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () => access.buyViaStripe(forBook),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Text(forBook == null ? 'Subscribe' : 'Buy this book'),
        ),
        TextButton(
          onPressed: () async {
            await access.refreshEntitlements();
            if (context.mounted &&
                AccessService.canOpenChapter(
                    book, access.catalog.value.previewChapters)) {
              Navigator.pop(context);
            }
          },
          child: const Text('I have paid — refresh'),
        ),
      ],
    );
  }
}
