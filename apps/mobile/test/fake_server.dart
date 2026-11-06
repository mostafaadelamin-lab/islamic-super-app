import 'dart:convert';

import 'package:http/http.dart' as http;

/// In-memory implementation of the bookmark/auth part of API.md, used with a
/// mocktail http.Client to exercise the real ApiClient + SyncService.
class FakeApiServer {
  final users = <String, String>{};
  final bookmarks = <String, Map<String, dynamic>>{};
  final requests = <http.Request>[];
  int serverTime = 1000000;
  static const token = 'tok-123';

  http.StreamedResponse _json(int code, Object body) => http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    code,
    headers: {'content-type': 'application/json'},
  );

  Future<http.StreamedResponse> handle(http.BaseRequest base) async {
    final req = base as http.Request;
    requests.add(req);
    final path = req.url.path;
    if (path == '/v1/auth/register' && req.method == 'POST') {
      final b = jsonDecode(req.body) as Map<String, dynamic>;
      if (users.containsKey(b['email'])) return _json(409, {'detail': 'email already registered'});
      users[b['email'] as String] = b['password'] as String;
      return _json(201, {'id': users.length, 'email': b['email']});
    }
    if (path == '/v1/auth/login' && req.method == 'POST') {
      final b = jsonDecode(req.body) as Map<String, dynamic>;
      if (users[b['email']] != b['password']) return _json(401, {'detail': 'bad credentials'});
      return _json(200, {'access_token': token, 'token_type': 'bearer', 'expires_in': 3600});
    }
    if (req.headers['Authorization'] != 'Bearer $token') return _json(401, {'detail': 'unauthorized'});
    if (path == '/v1/bookmarks' && req.method == 'GET') {
      final since = int.parse(req.url.queryParameters['since'] ?? '0');
      return _json(200, {
        'serverTime': serverTime,
        'items': [
          for (final b in bookmarks.values)
            if ((b['_serverUpdated'] as int) > since) Map.of(b)..remove('_serverUpdated'),
        ],
      });
    }
    if (path.startsWith('/v1/bookmarks/') && req.method == 'PUT') {
      final id = path.substring('/v1/bookmarks/'.length);
      final b = jsonDecode(req.body) as Map<String, dynamic>;
      // Mirrors services/api BookmarkIn (extra="forbid"): only these fields.
      const allowed = {'surah', 'ayah', 'note', 'updatedAt', 'deleted'};
      final extra = b.keys.where((k) => !allowed.contains(k)).toList();
      if (extra.isNotEmpty) return _json(422, {'detail': 'extra fields not permitted: $extra'});
      final cur = bookmarks[id];
      if (cur == null || (b['updatedAt'] as int) > (cur['updatedAt'] as int)) {
        bookmarks[id] = {...b, 'id': id, 'note': b['note'], '_serverUpdated': ++serverTime};
      }
      return _json(200, Map.of(bookmarks[id]!)..remove('_serverUpdated'));
    }
    return _json(404, {'detail': 'not found'});
  }

  /// Seeds an item as if another device had pushed it.
  void seed(Map<String, dynamic> b) => bookmarks[b['id'] as String] = {...b, '_serverUpdated': ++serverTime};
}
