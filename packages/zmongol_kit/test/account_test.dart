import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:zmongol_kit/zmongol_kit.dart';

import 'fake_http.dart';

const userJson = {
  'id': 7,
  'provider': 'google',
  'displayName': 'Test User',
  'email': 'test@example.com',
  'stars': 12,
  'badge': 'Helper',
  'contributionsBySource': {
    'zmedee': {'contributions': 2, 'stars': 10},
    'zocr': {'contributions': 1, 'stars': 2},
  },
  'createdAt': '2026-11-26T00:00:00Z',
};

Map<String, dynamic> loginBody(String access, String refresh) => {
      'token': access,
      'accessToken': access,
      'refreshToken': refresh,
      'tokenType': 'Bearer',
      'expiresIn': 2592000,
      'user': userJson,
    };

class FakeProviderAuth implements ZmongolProviderAuth {
  bool googleSignedOut = false;

  @override
  Future<ZmongolProviderIdentity> apple() async =>
      const ZmongolProviderIdentity('apple-id-token',
          displayName: 'Apple User');

  @override
  Future<ZmongolProviderIdentity> google() async =>
      const ZmongolProviderIdentity('google-id-token',
          displayName: 'Google User');

  @override
  Future<void> signOutGoogle() async {
    googleSignedOut = true;
  }
}

void main() {
  late MemoryTokenStore store;
  late FakeProviderAuth provider;

  ZmongolAccount makeAccount(FakeHttpClient client) => ZmongolAccount(
        appId: 'zchat',
        httpClient: client,
        tokenStore: store,
        providerAuth: provider,
      );

  setUp(() {
    store = MemoryTokenStore();
    provider = FakeProviderAuth();
  });

  test('google sign-in posts the provider token and stores the pair',
      () async {
    final client = FakeHttpClient((request) async {
      if (request.path.endsWith('/auth/google')) {
        expect(request.jsonBody['idToken'], 'google-id-token');
        expect(request.jsonBody['app'], 'zchat');
        return jsonResponse(loginBody('a1', 'r1'));
      }
      return http.Response('not found', 404);
    });
    final account = makeAccount(client);

    final user = await account.signInWithGoogle();

    expect(user.id, 7);
    expect(user.displayName, 'Test User');
    expect(user.contributionsBySource['zmedee']?.stars, 10);
    expect(account.isSignedIn, isTrue);
    expect(account.state.status, ZmongolAuthStatus.signedIn);
    expect(await account.accessToken(), 'a1');
    expect(store.values.values, containsAll(['a1', 'r1']));
  });

  test('a restored account comes back signed in from storage', () async {
    final client = FakeHttpClient((request) async {
      if (request.path.endsWith('/auth/apple')) {
        return jsonResponse(loginBody('a1', 'r1'));
      }
      return http.Response('not found', 404);
    });
    await makeAccount(client).signInWithApple();

    final restored = makeAccount(client);
    await restored.restore();
    expect(restored.isSignedIn, isTrue);
    expect(restored.user?.id, 7);
    expect(restored.state.status, ZmongolAuthStatus.signedIn);
  });

  test('401 triggers exactly one refresh and a retry with the new token',
      () async {
    var refreshCalls = 0;
    final meAuths = <String?>[];
    final client = FakeHttpClient((request) async {
      if (request.path.endsWith('/auth/google')) {
        return jsonResponse(loginBody('a1', 'r1'));
      }
      if (request.path.endsWith('/auth/refresh')) {
        refreshCalls++;
        expect(request.jsonBody['refreshToken'], 'r1');
        return jsonResponse(loginBody('a2', 'r2'));
      }
      if (request.path.endsWith('/users/me')) {
        meAuths.add(request.headers['authorization']);
        if (request.headers['authorization'] == 'Bearer a2') {
          return jsonResponse(userJson);
        }
        return http.Response('expired', 401);
      }
      return http.Response('not found', 404);
    });
    final account = makeAccount(client);
    await account.signInWithGoogle();

    final user = await account.currentUser(forceRefresh: true);

    expect(user.id, 7);
    expect(refreshCalls, 1);
    expect(meAuths, ['Bearer a1', 'Bearer a2']);
    expect(await account.accessToken(), 'a2');
  });

  test('a failed refresh signs the user out and throws', () async {
    final client = FakeHttpClient((request) async {
      if (request.path.endsWith('/auth/google')) {
        return jsonResponse(loginBody('a1', 'r1'));
      }
      if (request.path.endsWith('/auth/refresh')) {
        return http.Response('revoked', 401);
      }
      if (request.path.endsWith('/users/me')) {
        return http.Response('expired', 401);
      }
      return http.Response('not found', 404);
    });
    final account = makeAccount(client);
    await account.signInWithGoogle();

    await expectLater(account.currentUser(forceRefresh: true),
        throwsA(isA<ZmongolAuthException>()));
    expect(account.isSignedIn, isFalse);
    expect(account.state.status, ZmongolAuthStatus.signedOut);
    expect(store.values, isEmpty);
  });

  test('entitlements parse the service wrapper and snake_case fields',
      () async {
    final client = FakeHttpClient((request) async {
      if (request.path.endsWith('/auth/google')) {
        return jsonResponse(loginBody('a1', 'r1'));
      }
      if (request.path.endsWith('/entitlements')) {
        return jsonResponse({
          'entitlements': [
            {
              'app': 'zmongol2',
              'tier': 'pro',
              'source': 'apple',
              'expires_at': null,
              'updated_at': '2026-11-26T00:00:00Z',
            },
            {
              'app': 'znom',
              'tier': 'pro',
              'source': 'manual',
              'expires_at': '2020-01-01T00:00:00Z',
              'updated_at': '2026-11-26T00:00:00Z',
            },
          ],
        });
      }
      return http.Response('not found', 404);
    });
    final account = makeAccount(client);
    await account.signInWithGoogle();

    final entitlements = await account.entitlements();
    expect(entitlements, hasLength(2));
    expect(entitlements.first.app, 'zmongol2');
    expect(entitlements.first.tier, 'pro');
    expect(entitlements.first.isActive, isTrue);
    expect(entitlements.last.isActive, isFalse,
        reason: 'a 2020 expiry is in the past');
  });

  test('deleteAccount calls DELETE and clears the local session',
      () async {
    var deleteCalls = 0;
    final client = FakeHttpClient((request) async {
      if (request.path.endsWith('/auth/google')) {
        return jsonResponse(loginBody('a1', 'r1'));
      }
      if (request.method == 'DELETE' &&
          request.path.endsWith('/users/me')) {
        deleteCalls++;
        return http.Response('', 204);
      }
      return http.Response('not found', 404);
    });
    final account = makeAccount(client);
    await account.signInWithGoogle();

    await account.deleteAccount();

    expect(deleteCalls, 1);
    expect(account.isSignedIn, isFalse);
    expect(store.values, isEmpty);
    expect(provider.googleSignedOut, isTrue);
  });

  test('signOut clears storage and signs the Google SDK out', () async {
    final client = FakeHttpClient((request) async {
      if (request.path.endsWith('/auth/google')) {
        return jsonResponse(loginBody('a1', 'r1'));
      }
      return http.Response('not found', 404);
    });
    final account = makeAccount(client);
    await account.signInWithGoogle();
    await account.signOut();

    expect(account.isSignedIn, isFalse);
    expect(store.values, isEmpty);
    expect(provider.googleSignedOut, isTrue);
  });

  test('the states stream reports the sign-in transition', () async {
    final client = FakeHttpClient((request) async {
      if (request.path.endsWith('/auth/google')) {
        return jsonResponse(loginBody('a1', 'r1'));
      }
      return http.Response('not found', 404);
    });
    final account = makeAccount(client);
    final seen = <ZmongolAuthStatus>[];
    final sub = account.states.listen((s) => seen.add(s.status));

    await account.signInWithGoogle();
    await Future<void>.delayed(Duration.zero);

    expect(seen, contains(ZmongolAuthStatus.signedIn));
    await sub.cancel();
    account.dispose();
  });

  test('login response body is valid JSON the models round-trip',
      () async {
    final session = ZmongolSession.fromJson(loginBody('x', 'y'));
    expect(session.accessToken, 'x');
    expect(session.refreshToken, 'y');
    final roundTripped = ZmongolUser.fromJson(
        Map<String, dynamic>.from(
            jsonDecode(jsonEncode(session.user!.toJson())) as Map));
    expect(roundTripped.id, 7);
    expect(roundTripped.contributionsBySource['zocr']?.contributions, 1);
  });
}
