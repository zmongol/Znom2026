import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zmongol_kit/zmongol_kit.dart';

import '../Component/MongolFonts.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/ui_strings.dart';
import '../services/access_service.dart';
import '../widgets/bounded_mongol_text.dart';

/// The account sheet behind the home screen's person button: sign in
/// with the shared Zmongol account, see the Pro state, refresh or
/// restore purchases, sign out. One account works across the whole
/// app family and every platform.
Future<void> showAccountSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (_) => const AccountSheet(),
  );
}

class AccountSheet extends StatelessWidget {
  const AccountSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final access = Get.find<AccessService>();
    return Obx(() {
      final account = access.account;
      final user = account.user;
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: BoundedMongolText(
                UiStrings.account,
                maxHeight: 44,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: MongolFonts.z52dardastig,
                  color: AppColors.primary,
                ),
              ),
            ),
            const Text('Zmongol Account',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black45, fontSize: 12)),
            const SizedBox(height: 18),
            if (user == null) ...[
              const Text(
                  'Sign in to keep your books and Pro on every device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.black54, fontSize: 13)),
              const SizedBox(height: 14),
              ZmongolSignInButtons(
                account: account,
                showApple: AccessService.isApplePlatform,
                showGoogle: !kIsWeb && (Platform.isAndroid || Platform.isIOS),
                onSignedIn: () => access.refreshEntitlements(),
                onError: (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sign-in failed.')));
                  }
                },
              ),
            ] else ...[
              Text(user.displayName ?? user.email ?? 'Signed in',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              if (user.email != null)
                Text(user.email!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.black45, fontSize: 12)),
              const SizedBox(height: 10),
              Text(
                access.proActive ? 'Znom Pro: active' : 'Znom Pro: not subscribed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: access.proActive
                      ? AppColors.secondary
                      : Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: () => access.refreshEntitlements(),
                child: const Text('Refresh'),
              ),
              if (AccessService.isApplePlatform)
                OutlinedButton(
                  onPressed: () => access.restoreIap(),
                  child: const Text('Restore purchases'),
                ),
              TextButton(
                onPressed: () async {
                  await access.signOut();
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('Sign out'),
              ),
            ],
          ],
        ),
      );
    });
  }
}
