/// Zmongol Kit — the shared ecosystem layer for the Zmongol app family.
///
/// One account across every app and platform (Stage 1 account service),
/// the shared app catalogue / cross-promo config, and the cross-promotion
/// widgets. Host apps repoint everything by passing a different
/// [ZmongolKit.defaultBaseUrl] replacement to the client constructors —
/// no code changes are needed when the backend moves to a domain or a
/// Hong Kong host.
library;

import 'src/api_client.dart';

export 'src/account.dart';
export 'src/api_client.dart';
export 'src/config.dart';
export 'src/labels.dart';
export 'src/models.dart';
export 'src/promo.dart';
export 'src/sign_in_buttons.dart';
export 'src/store.dart';

/// Shared constants for the kit.
abstract final class ZmongolKit {
  /// The Stage 1 account service, public via the Mac Mini Tailscale
  /// Funnel. Every client accepts a `baseUrl` override; this is only the
  /// default.
  static const String defaultBaseUrl = kZmongolDefaultBaseUrl;
}
