import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'api_client.dart';
import 'models.dart';
import 'store.dart';

/// Sign-in state of a [ZmongolAccount]: either signed out, or signed in
/// with the shared user.
enum ZmongolAuthStatus { signedOut, signedIn }

/// An immutable snapshot of the account state.
class ZmongolAuthState {
  final ZmongolUser? user;

  const ZmongolAuthState.signedOut() : user = null;
  const ZmongolAuthState.signedIn(ZmongolUser this.user);

  bool get isSignedIn => user != null;

  ZmongolAuthStatus get status =>
      isSignedIn ? ZmongolAuthStatus.signedIn : ZmongolAuthStatus.signedOut;

  @override
  String toString() => isSignedIn
      ? 'ZmongolAuthState.signedIn(${user!.id})'
      : 'ZmongolAuthState.signedOut()';
}

/// A provider identity token plus the display name the provider shared
/// (Apple only shares the name on the very first sign-in).
class ZmongolProviderIdentity {
  final String token;
  final String? displayName;

  const ZmongolProviderIdentity(this.token, {this.displayName});
}

/// Source of Apple/Google identity tokens. The default implementation is
/// [SdkProviderAuth]; tests and previews may inject their own.
abstract interface class ZmongolProviderAuth {
  Future<ZmongolProviderIdentity> apple();
  Future<ZmongolProviderIdentity> google();

  /// Signs the Google SDK out so the next sign-in shows the account
  /// chooser. Called on sign-out and account deletion.
  Future<void> signOutGoogle();
}

/// [ZmongolProviderAuth] backed by the sign_in_with_apple and
/// google_sign_in SDKs — the same call pattern the fleet apps use.
final class SdkProviderAuth implements ZmongolProviderAuth {
  /// The host app's own Google OAuth client ID for this platform
  /// (each fleet app has its own Google Cloud project).
  final String? googleClientId;

  bool _googleInitialized = false;

  SdkProviderAuth({this.googleClientId});

  @override
  Future<ZmongolProviderIdentity> apple() async {
    if (!await SignInWithApple.isAvailable()) {
      throw Exception('Sign in with Apple is not available on this device');
    }
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.fullName],
    );
    final identityToken = credential.identityToken;
    if (identityToken == null || identityToken.isEmpty) {
      throw Exception('Apple did not return an identity token');
    }
    final name = [credential.givenName, credential.familyName]
        .whereType<String>()
        .join(' ')
        .trim();
    return ZmongolProviderIdentity(identityToken,
        displayName: name.isEmpty ? null : name);
  }

  @override
  Future<ZmongolProviderIdentity> google() async {
    final signIn = GoogleSignIn.instance;
    if (!_googleInitialized) {
      await signIn.initialize(clientId: googleClientId);
      _googleInitialized = true;
    }
    final account = await signIn.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('Google did not return an ID token');
    }
    return ZmongolProviderIdentity(idToken,
        displayName: account.displayName);
  }

  @override
  Future<void> signOutGoogle() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Not signed in with Google (e.g. an Apple session): fine.
    }
  }
}

/// The shared Zmongol account client — one login for the whole family.
///
/// Talks to the Stage 1 account service: the provider (Apple/Google)
/// proves who the user is, the service issues its own access/refresh
/// pair, and the pair is kept in secure storage. Authenticated requests
/// go through [ZmongolApiClient], which refreshes an expired access
/// token once, transparently.
///
/// Listen either as a [ChangeNotifier] (the fleet's pattern) or via the
/// [states] stream.
class ZmongolAccount extends ChangeNotifier {
  /// Catalogue id of the host app (e.g. "zmedee", "zocr", "zchat").
  /// Sent with every login so the service can attribute the session.
  final String appId;

  late final ZmongolApiClient _api;
  final ZmongolTokenStore _store;
  final ZmongolProviderAuth _provider;

  static const String _accessKey = 'zmongol_kit.access_token';
  static const String _refreshKey = 'zmongol_kit.refresh_token';
  static const String _userKey = 'zmongol_kit.user_json';

  String? _accessToken;
  String? _refreshToken;
  ZmongolUser? _user;

  final StreamController<ZmongolAuthState> _states =
      StreamController<ZmongolAuthState>.broadcast();

  ZmongolAccount({
    required this.appId,
    String baseUrl = kZmongolDefaultBaseUrl,
    String? googleClientId,
    http.Client? httpClient,
    ZmongolTokenStore? tokenStore,
    ZmongolProviderAuth? providerAuth,
  })  : _store = tokenStore ?? const SecureTokenStore(),
        _provider =
            providerAuth ?? SdkProviderAuth(googleClientId: googleClientId) {
    _api = ZmongolApiClient(
      baseUrl: baseUrl,
      client: httpClient,
      tokenProvider: () async => _accessToken,
      refreshHandler: _refreshSession,
    );
  }

  /// Broadcast stream of sign-in state changes.
  Stream<ZmongolAuthState> get states => _states.stream;

  /// The current state snapshot.
  ZmongolAuthState get state => _user != null
      ? ZmongolAuthState.signedIn(_user!)
      : const ZmongolAuthState.signedOut();

  ZmongolUser? get user => _user;
  bool get isSignedIn => _accessToken != null;

  /// The current access token, for host code (and the promo client) that
  /// needs to call the service itself. Null when signed out.
  Future<String?> accessToken() async => _accessToken;

  void _emit() {
    if (!_states.isClosed) _states.add(state);
    notifyListeners();
  }

  @override
  void dispose() {
    _states.close();
    super.dispose();
  }

  /// Loads any saved session from secure storage. Call once at startup,
  /// before the first frame. A restored session may hold an expired
  /// access token — the first authenticated call refreshes it.
  Future<void> restore() async {
    try {
      _accessToken = await _store.read(_accessKey);
      _refreshToken = await _store.read(_refreshKey);
      final userJson = await _store.read(_userKey);
      if (userJson != null) {
        _user = ZmongolUser.fromJson(
            Map<String, dynamic>.from(jsonDecode(userJson) as Map));
      }
      if (_accessToken == null) _user = null;
    } catch (_) {
      // Secure storage unavailable (e.g. in tests): stay signed out.
      _accessToken = null;
      _refreshToken = null;
      _user = null;
    }
    _emit();
  }

  /// Interactive Sign in with Apple, then service login.
  ///
  /// Throws [SignInWithAppleAuthorizationException] (code `canceled`)
  /// when the user backs out, [ZmongolApiException] when the service
  /// refuses the token.
  Future<ZmongolUser> signInWithApple() => _signIn('apple');

  /// Interactive Google sign-in, then service login.
  ///
  /// Throws [GoogleSignInException] (code `canceled`) when the user
  /// backs out, [ZmongolApiException] when the service refuses the
  /// token.
  Future<ZmongolUser> signInWithGoogle() => _signIn('google');

  Future<ZmongolUser> _signIn(String provider) async {
    final identity = provider == 'apple'
        ? await _provider.apple()
        : await _provider.google();
    final response = await _api.post(
      provider == 'apple' ? '/auth/apple' : '/auth/google',
      jsonBody: {
        provider == 'apple' ? 'identityToken' : 'idToken': identity.token,
        'app': appId,
        if (identity.displayName != null)
          'displayName': identity.displayName,
      },
    );
    if (response.statusCode != 200) {
      throw ZmongolApiException(response.statusCode,
          'Login refused by the account service',
          body: response.body);
    }
    final session = ZmongolSession.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map));
    if (session.accessToken.isEmpty || session.user == null) {
      throw const ZmongolApiException(200, 'Malformed login response');
    }
    await _saveSession(session);
    return _user!;
  }

  Future<void> _saveSession(ZmongolSession session) async {
    _accessToken = session.accessToken;
    _refreshToken = session.refreshToken ?? _refreshToken;
    _user = session.user ?? _user;
    try {
      await _store.write(_accessKey, _accessToken!);
      if (_refreshToken != null) {
        await _store.write(_refreshKey, _refreshToken!);
      }
      if (_user != null) {
        await _store.write(_userKey, jsonEncode(_user!.toJson()));
      }
    } catch (_) {
      // The in-memory session still works for this run.
    }
    _emit();
  }

  /// The refresh handler behind [ZmongolApiClient]: exchanges the stored
  /// refresh token (rotating) — or, when there is none, the still-valid
  /// access token — for a fresh pair. Returns false when the service
  /// refuses, leaving the caller to surface the 401.
  Future<bool> _refreshSession() async {
    final refreshToken = _refreshToken;
    final accessToken = _accessToken;
    if (refreshToken == null && accessToken == null) return false;
    try {
      final response = await _api.post(
        '/auth/refresh',
        jsonBody: refreshToken != null
            ? {'refreshToken': refreshToken}
            : {'token': accessToken},
      );
      if (response.statusCode != 200) return false;
      final session = ZmongolSession.fromJson(
          Map<String, dynamic>.from(jsonDecode(response.body) as Map));
      if (session.accessToken.isEmpty) return false;
      await _saveSession(session);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// The signed-in user, from the in-memory / stored cache when
  /// available. Pass `forceRefresh: true` to re-read `GET /users/me`.
  ///
  /// Throws [ZmongolAuthException] (and signs out locally) when the
  /// session can no longer be refreshed.
  Future<ZmongolUser> currentUser({bool forceRefresh = false}) async {
    if (_user != null && !forceRefresh) return _user!;
    final response = await _api.get('/users/me');
    if (response.statusCode == 401) {
      await _clearLocal();
      throw const ZmongolAuthException();
    }
    if (response.statusCode != 200) {
      throw ZmongolApiException(
          response.statusCode, 'Could not load the account',
          body: response.body);
    }
    _user = ZmongolUser.fromJson(
        Map<String, dynamic>.from(jsonDecode(response.body) as Map));
    try {
      await _store.write(_userKey, jsonEncode(_user!.toJson()));
    } catch (_) {
      // Cache write is best-effort.
    }
    _emit();
    return _user!;
  }

  /// The caller's Pro entitlements (`GET /entitlements`) — a purchase on
  /// any platform, recorded on the account, is honoured by all of them.
  Future<List<ZmongolEntitlement>> entitlements() async {
    final response = await _api.get('/entitlements');
    if (response.statusCode == 401) {
      await _clearLocal();
      throw const ZmongolAuthException();
    }
    if (response.statusCode != 200) {
      throw ZmongolApiException(
          response.statusCode, 'Could not load entitlements',
          body: response.body);
    }
    final decoded = jsonDecode(response.body);
    final rows = decoded is Map ? decoded['entitlements'] : decoded;
    if (rows is! List) return const [];
    return rows
        .whereType<Map>()
        .map((r) => ZmongolEntitlement.fromJson(
            Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Deletes the shared account on the service (`DELETE /users/me`) and
  /// signs out locally. Deletion removes the account across the whole
  /// family; per-app domain data remains each app's own responsibility.
  Future<void> deleteAccount() async {
    final response = await _api.delete('/users/me');
    if (response.statusCode != 204 && response.statusCode != 200) {
      if (response.statusCode == 401) {
        await _clearLocal();
        throw const ZmongolAuthException();
      }
      throw ZmongolApiException(
          response.statusCode, 'Account deletion failed',
          body: response.body);
    }
    await _clearLocal();
    await _provider.signOutGoogle();
  }

  /// Clears the session locally and from secure storage. Also signs the
  /// Google SDK out so the next sign-in shows the account chooser.
  Future<void> signOut() async {
    await _clearLocal();
    await _provider.signOutGoogle();
  }

  Future<void> _clearLocal() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    try {
      await _store.delete(_accessKey);
      await _store.delete(_refreshKey);
      await _store.delete(_userKey);
    } catch (_) {
      // The in-memory session is already gone.
    }
    _emit();
  }
}
