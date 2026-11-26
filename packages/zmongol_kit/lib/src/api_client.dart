import 'dart:convert';

import 'package:http/http.dart' as http;

/// The Stage 1 account service, public via the Mac Mini Tailscale
/// Funnel. Every client takes a `baseUrl` override so host apps can
/// repoint to a future domain / Hong Kong host without code changes.
const String kZmongolDefaultBaseUrl =
    'https://ckss-mac-mini.taildb6449.ts.net/account';

/// A request to the account service failed with a non-success status.
class ZmongolApiException implements Exception {
  final int statusCode;
  final String message;
  final String? body;

  const ZmongolApiException(this.statusCode, this.message, {this.body});

  @override
  String toString() => 'ZmongolApiException($statusCode): $message';
}

/// The session is gone — the service answered 401 and the one permitted
/// refresh attempt did not recover it. The account client signs the user
/// out locally before this is thrown.
class ZmongolAuthException extends ZmongolApiException {
  const ZmongolAuthException([String message = 'Session expired'])
      : super(401, message);
}

/// Thin HTTP helper for the account service.
///
/// Attaches the current access token as `Authorization: Bearer …` on
/// authenticated calls and, on a 401, asks the refresh handler to renew
/// the session **once** and retries the request **once**. The refresh
/// handler belongs to the account client; unauthenticated calls (login,
/// refresh itself) never enter the retry loop.
class ZmongolApiClient {
  /// Service root, without a trailing slash
  /// (e.g. `https://…/account`).
  final String baseUrl;

  final http.Client _http;
  final Future<String?> Function()? _tokenProvider;
  final Future<bool> Function()? _refreshHandler;

  ZmongolApiClient({
    required String baseUrl,
    http.Client? client,
    this._tokenProvider,
    this._refreshHandler,
  })  : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _http = client ?? http.Client();

  Uri uri(String path) => Uri.parse('$baseUrl$path');

  Future<http.Response> get(String path, {bool auth = true}) =>
      _send('GET', path, auth: auth);

  Future<http.Response> post(String path,
          {Object? jsonBody, bool auth = false}) =>
      _send('POST', path, jsonBody: jsonBody, auth: auth);

  Future<http.Response> delete(String path, {bool auth = true}) =>
      _send('DELETE', path, auth: auth);

  Future<http.Response> _send(String method, String path,
      {Object? jsonBody, required bool auth}) async {
    Future<http.Response> once() async {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (auth) {
        final token = await _tokenProvider?.call();
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
      final body = jsonBody == null ? null : jsonEncode(jsonBody);
      final u = uri(path);
      switch (method) {
        case 'GET':
          return _http.get(u, headers: headers);
        case 'POST':
          return _http.post(u, headers: headers, body: body);
        case 'DELETE':
          return _http.delete(u, headers: headers);
        default:
          throw ArgumentError('Unsupported method $method');
      }
    }

    var response = await once();
    if (response.statusCode == 401 && auth && _refreshHandler != null) {
      if (await _refreshHandler()) {
        response = await once();
      }
    }
    return response;
  }
}
