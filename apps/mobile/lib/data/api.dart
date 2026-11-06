import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../domain/bookmark.dart';

enum ApiErrorKind { offline, unauthorized, conflict, validation, rateLimited, server, badUrl }

class ApiException implements Exception {
  const ApiException(this.kind, {this.statusCode, this.detail});
  final ApiErrorKind kind;
  final int? statusCode;
  final String? detail;
  @override
  String toString() => 'ApiException($kind, $statusCode, $detail)';
}

class LoginResult {
  const LoginResult(this.accessToken, this.expiresIn);
  final String accessToken;
  final int expiresIn;
}

class BookmarkPage {
  const BookmarkPage(this.serverTime, this.items);
  final int serverTime;
  final List<Bookmark> items;
}

/// Client for packages/api-contracts/API.md (v1).
class ApiClient {
  ApiClient(this._http, String baseUrl, {this.timeout = const Duration(seconds: 10)})
    : baseUrl = baseUrl.replaceAll(RegExp(r'/+$'), '');

  final http.Client _http;
  final String baseUrl;
  final Duration timeout;

  static bool isValidBaseUrl(String url) {
    final u = Uri.tryParse(url.trim());
    return u != null && (u.scheme == 'http' || u.scheme == 'https') && u.host.isNotEmpty;
  }

  Uri _uri(String path, [Map<String, String>? q]) {
    if (!isValidBaseUrl(baseUrl)) throw const ApiException(ApiErrorKind.badUrl);
    return Uri.parse('$baseUrl$path').replace(queryParameters: q);
  }

  Future<Object?> _send(String method, String path, {Object? body, String? token, Map<String, String>? query}) async {
    final req = http.Request(method, _uri(path, query));
    req.headers['Accept'] = 'application/json';
    if (body != null) {
      req.headers['Content-Type'] = 'application/json; charset=utf-8';
      req.body = jsonEncode(body);
    }
    if (token != null) req.headers['Authorization'] = 'Bearer $token';
    final http.Response res;
    try {
      res = await http.Response.fromStream(await _http.send(req).timeout(timeout));
    } on SocketException {
      throw const ApiException(ApiErrorKind.offline);
    } on TimeoutException {
      throw const ApiException(ApiErrorKind.offline);
    } on HandshakeException {
      throw const ApiException(ApiErrorKind.offline);
    } on http.ClientException {
      throw const ApiException(ApiErrorKind.offline);
    }
    Object? decoded;
    if (res.body.isNotEmpty) {
      try {
        decoded = jsonDecode(utf8.decode(res.bodyBytes));
      } on FormatException {
        decoded = null;
      }
    }
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    final detail = decoded is Map<String, dynamic> ? decoded['detail']?.toString() : null;
    final kind = switch (res.statusCode) {
      401 || 403 => ApiErrorKind.unauthorized,
      409 => ApiErrorKind.conflict,
      400 || 422 => ApiErrorKind.validation,
      429 => ApiErrorKind.rateLimited,
      _ => ApiErrorKind.server,
    };
    throw ApiException(kind, statusCode: res.statusCode, detail: detail);
  }

  Map<String, dynamic> _obj(Object? v) {
    if (v is Map<String, dynamic>) return v;
    throw const ApiException(ApiErrorKind.server, detail: 'unexpected response');
  }

  Future<void> register(String email, String password) async {
    await _send('POST', '/v1/auth/register', body: {'email': email, 'password': password});
  }

  Future<LoginResult> login(String email, String password) async {
    final j = _obj(await _send('POST', '/v1/auth/login', body: {'email': email, 'password': password}));
    final token = j['access_token'];
    if (token is! String) {
      throw const ApiException(ApiErrorKind.server, detail: 'missing access_token');
    }
    return LoginResult(token, (j['expires_in'] as num?)?.toInt() ?? 0);
  }

  Future<BookmarkPage> getBookmarks(String token, {int since = 0}) async {
    final j = _obj(await _send('GET', '/v1/bookmarks', token: token, query: {'since': '$since'}));
    try {
      return BookmarkPage((j['serverTime'] as num).toInt(), [
        for (final i in j['items'] as List<dynamic>) Bookmark.fromJson(i as Map<String, dynamic>),
      ]);
    } on Object catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(ApiErrorKind.server, detail: 'bad bookmark payload: $e');
    }
  }

  Future<Bookmark> putBookmark(String token, Bookmark b) async {
    // The id travels in the path only; the server rejects unknown body fields.
    final body = b.toJson()..remove('id');
    final j = _obj(await _send('PUT', '/v1/bookmarks/${b.id}', token: token, body: body));
    try {
      return Bookmark.fromJson(j);
    } on Object catch (e) {
      throw ApiException(ApiErrorKind.server, detail: 'bad bookmark payload: $e');
    }
  }
}
