import 'dart:convert';

import 'package:http/http.dart' as http;

/// One request seen by [FakeHttpClient].
class RecordedRequest {
  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String? body;

  const RecordedRequest(this.method, this.url, this.headers, this.body);

  String get path => url.path;

  Map<String, dynamic> get jsonBody =>
      body == null ? {} : Map<String, dynamic>.from(jsonDecode(body!) as Map);
}

typedef FakeHandler = Future<http.Response> Function(RecordedRequest request);

/// An http client that routes every request to a handler function and
/// records what it saw — the fake HTTP layer for the kit's unit tests.
class FakeHttpClient extends http.BaseClient {
  FakeHandler handler;
  final List<RecordedRequest> requests = [];

  FakeHttpClient(this.handler);

  int countRequests(bool Function(RecordedRequest) test) =>
      requests.where(test).length;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final recorded = RecordedRequest(
      request.method,
      request.url,
      request.headers,
      request is http.Request ? request.body : null,
    );
    requests.add(recorded);
    final response = await handler(recorded);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

http.Response jsonResponse(Object body, {int status = 200}) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    );
