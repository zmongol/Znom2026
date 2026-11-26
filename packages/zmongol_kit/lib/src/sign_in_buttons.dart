import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'account.dart';
import 'labels.dart';
import 'models.dart';

/// Ready-made Apple + Google sign-in buttons wired to a
/// [ZmongolAccount].
///
/// User cancellation is swallowed silently (it is not an error); any
/// other failure is passed to [onError]. After a successful sign-in,
/// [onSignedIn] is called — the account's own state stream / listener
/// notifications fire as well.
class ZmongolSignInButtons extends StatelessWidget {
  final ZmongolAccount account;
  final ZmongolLabels labels;
  final bool showApple;
  final bool showGoogle;
  final VoidCallback? onSignedIn;
  final void Function(Object error)? onError;

  const ZmongolSignInButtons({
    super.key,
    required this.account,
    this.labels = const ZmongolLabels(),
    this.showApple = true,
    this.showGoogle = true,
    this.onSignedIn,
    this.onError,
  });

  Future<void> _run(Future<ZmongolUser> Function() action) async {
    try {
      await action();
      onSignedIn?.call();
    } on GoogleSignInException catch (e) {
      if (e.code != GoogleSignInExceptionCode.canceled) onError?.call(e);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) onError?.call(e);
    } catch (e) {
      onError?.call(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showApple)
          SignInWithAppleButton(
            onPressed: () => _run(account.signInWithApple),
            text: labels.signInWithApple,
          ),
        if (showApple && showGoogle) const SizedBox(height: 12),
        if (showGoogle)
          OutlinedButton.icon(
            onPressed: () => _run(account.signInWithGoogle),
            icon: const Text('G',
                style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            label: Text(labels.signInWithGoogle),
          ),
      ],
    );
  }
}
