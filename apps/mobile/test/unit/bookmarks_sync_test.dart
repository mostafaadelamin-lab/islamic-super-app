import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:rattil/data/account.dart';
import 'package:rattil/data/api.dart';
import 'package:rattil/data/bookmarks.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/data/sync.dart';
import 'package:rattil/domain/bookmark.dart';
import 'package:rattil/domain/quran.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fake_server.dart';
import '../helpers.dart';

void main() {
  setUpAll(registerHttpFallbacks);

  var now = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;
  DateTime clock() => DateTime.fromMillisecondsSinceEpoch(now, isUtc: true);

  Future<SharedPreferences> prefs([Map<String, Object> v = const {}]) async {
    SharedPreferences.setMockInitialValues(v);
    return SharedPreferences.getInstance();
  }

  group('Bookmark model', () {
    test('json round trip and validation', () {
      const b = Bookmark(id: 'b-2-255', surah: 2, ayah: 255, updatedAt: 5, note: 'n');
      expect(Bookmark.fromJson(b.toJson()), b);
      expect(b.toJson()['deleted'], false);
      expect(() => Bookmark.fromJson({...b.toJson(), 'id': 'bad id!'}), throwsFormatException);
      expect(() => Bookmark.fromJson({...b.toJson(), 'id': 'x' * 65}), throwsFormatException);
      expect(() => Bookmark.fromJson({...b.toJson(), 'surah': 115}), throwsFormatException);
      expect(() => Bookmark.fromJson({...b.toJson(), 'ayah': 0}), throwsFormatException);
      expect(() => Bookmark.fromJson({...b.toJson(), 'note': 'x' * 501}), throwsFormatException);
      expect(Bookmark.idFor(2, 255), 'b-2-255');
    });

    test('last-write-wins picks the greater updatedAt; ties keep local', () {
      const local = Bookmark(id: 'a', surah: 1, ayah: 1, updatedAt: 10);
      const newer = Bookmark(id: 'a', surah: 1, ayah: 1, updatedAt: 11, deleted: true);
      const older = Bookmark(id: 'a', surah: 1, ayah: 1, updatedAt: 9, deleted: true);
      const tie = Bookmark(id: 'a', surah: 1, ayah: 1, updatedAt: 10, deleted: true);
      expect(lastWriteWins(local, newer), newer);
      expect(lastWriteWins(local, older), local);
      expect(lastWriteWins(local, tie), local);
      expect(lastWriteWins(null, older), older);
      final (merged, changed) = mergeBookmarks(
        {'a': local},
        [older, const Bookmark(id: 'b', surah: 2, ayah: 1, updatedAt: 1)],
      );
      expect(merged['a'], local);
      expect(changed, {'b'});
    });
  });

  group('BookmarksController', () {
    test('add, toggle, remove (tombstone) and persistence', () async {
      final p = await prefs();
      final c = BookmarksController(p, clock: clock);
      await c.add(const AyahRef(2, 255));
      expect(c.isBookmarked(const AyahRef(2, 255)), isTrue);
      expect(c.dirty, {'b-2-255'});
      now += 1000;
      expect(await c.toggle(const AyahRef(1, 1)), isTrue);
      expect(c.active.map((b) => b.id), ['b-1-1', 'b-2-255'], reason: 'newest first');
      now += 1000;
      expect(await c.toggle(const AyahRef(1, 1)), isFalse);
      expect(c.isBookmarked(const AyahRef(1, 1)), isFalse);
      expect(c.all['b-1-1']!.deleted, isTrue, reason: 'kept as tombstone');
      expect(c.active.map((b) => b.id), ['b-2-255']);
      await c.remove('missing');
      await c.remove('b-1-1'); // already deleted: no-op
      final reloaded = BookmarksController(p, clock: clock);
      expect(reloaded.all, c.all);
      expect(reloaded.dirty, {'b-1-1', 'b-2-255'});
    });

    test('updatedAt strictly increases even if the clock does not move', () async {
      final c = BookmarksController(await prefs(), clock: clock);
      await c.add(const AyahRef(3, 1));
      final t1 = c.all['b-3-1']!.updatedAt;
      await c.remove('b-3-1');
      final t2 = c.all['b-3-1']!.updatedAt;
      await c.add(const AyahRef(3, 1));
      expect(t2, greaterThan(t1));
      expect(c.all['b-3-1']!.updatedAt, greaterThan(t2));
    });

    test('markPushed keeps items that changed after the push started', () async {
      final c = BookmarksController(await prefs(), clock: clock);
      await c.add(const AyahRef(4, 1));
      final pushed = c.all['b-4-1']!;
      now += 5;
      await c.remove('b-4-1');
      await c.markPushed('b-4-1', pushed);
      expect(c.dirty, contains('b-4-1'));
      await c.markPushed('b-4-1', c.all['b-4-1']!);
      expect(c.dirty, isEmpty);
    });
  });

  group('SyncService with a fake HTTP client', () {
    late FakeApiServer server;
    late MockHttpClient client;

    setUp(() {
      server = FakeApiServer();
      client = MockHttpClient();
      when(
        () => client.send(any()),
      ).thenAnswer((inv) => server.handle(inv.positionalArguments.first as http.BaseRequest));
    });

    test('pushes local changes and pulls remote ones', () async {
      final store = BookmarksController(await prefs(), clock: clock);
      await store.add(const AyahRef(2, 255));
      server.seed({'id': 'b-36-1', 'surah': 36, 'ayah': 1, 'updatedAt': 5, 'deleted': false});
      final report = await SyncService(ApiClient(client, 'http://api.test/'), store).sync(FakeApiServer.token);
      expect(report.pulled, 1);
      expect(report.pushed, 1);
      expect(report.active, 2);
      expect(store.isBookmarked(const AyahRef(36, 1)), isTrue);
      expect(server.bookmarks.keys, containsAll(['b-2-255', 'b-36-1']));
      expect(store.dirty, isEmpty);
      expect(store.since, server.serverTime - 1, reason: 'serverTime from the pull');
      final get = server.requests.firstWhere((r) => r.method == 'GET');
      expect(get.url.toString(), 'http://api.test/v1/bookmarks?since=0');
      final put = server.requests.firstWhere((r) => r.method == 'PUT');
      expect(put.url.path, '/v1/bookmarks/b-2-255');
      expect(jsonDecode(put.body), store.all['b-2-255']!.toJson()..remove('id'));
      expect((jsonDecode(put.body) as Map).containsKey('id'), isFalse, reason: 'id is in the path only');
      expect(put.headers['Authorization'], 'Bearer ${FakeApiServer.token}');
    });

    test('conflict: remote newer wins locally, local newer wins on the server', () async {
      final store = BookmarksController(await prefs(), clock: clock);
      await store.add(const AyahRef(1, 1)); // t = now
      await store.add(const AyahRef(1, 2));
      final t = store.all['b-1-1']!.updatedAt;
      // Another device deleted 1:1 later (newer) and deleted 1:2 earlier (older).
      server.seed({'id': 'b-1-1', 'surah': 1, 'ayah': 1, 'updatedAt': t + 100, 'deleted': true});
      server.seed({'id': 'b-1-2', 'surah': 1, 'ayah': 2, 'updatedAt': t - 100, 'deleted': true});
      await SyncService(ApiClient(client, 'http://api.test'), store).sync(FakeApiServer.token);
      expect(store.isBookmarked(const AyahRef(1, 1)), isFalse, reason: 'remote tombstone is newer');
      expect(store.all['b-1-1']!.deleted, isTrue);
      expect(store.isBookmarked(const AyahRef(1, 2)), isTrue, reason: 'local is newer');
      expect(server.bookmarks['b-1-2']!['deleted'], isFalse, reason: 'server took the newer local copy');
      expect(server.bookmarks['b-1-1']!['deleted'], isTrue);
    });

    test('server keeps its newer copy on PUT and the client adopts it', () async {
      final store = BookmarksController(await prefs(), clock: clock);
      await store.add(const AyahRef(5, 5));
      final t = store.all['b-5-5']!.updatedAt;
      // Server learns a newer tombstone between our pull and push.
      when(() => client.send(any())).thenAnswer((inv) async {
        final req = inv.positionalArguments.first as http.Request;
        if (req.method == 'PUT') {
          server.seed({'id': 'b-5-5', 'surah': 5, 'ayah': 5, 'updatedAt': t + 50, 'deleted': true});
        }
        return server.handle(req);
      });
      await SyncService(ApiClient(client, 'http://api.test'), store).sync(FakeApiServer.token);
      expect(store.all['b-5-5']!.deleted, isTrue);
      expect(store.all['b-5-5']!.updatedAt, t + 50);
    });

    test('second sync sends since=<serverTime> and pushes nothing new', () async {
      final store = BookmarksController(await prefs(), clock: clock);
      await store.add(const AyahRef(9, 1));
      final s = SyncService(ApiClient(client, 'http://api.test'), store);
      await s.sync(FakeApiServer.token);
      final since = store.since;
      server.requests.clear();
      final r = await s.sync(FakeApiServer.token);
      expect(r.pushed, 0);
      expect(server.requests.single.url.queryParameters['since'], '$since');
    });

    test('offline: SocketException becomes ApiErrorKind.offline and nothing is lost', () async {
      when(() => client.send(any())).thenThrow(const SocketException('Network is unreachable'));
      final store = BookmarksController(await prefs(), clock: clock);
      await store.add(const AyahRef(2, 1));
      await expectLater(
        SyncService(ApiClient(client, 'http://api.test'), store).sync(FakeApiServer.token),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.offline)),
      );
      expect(store.dirty, {'b-2-1'});
      expect(store.isBookmarked(const AyahRef(2, 1)), isTrue);
    });

    test('timeouts and client exceptions are offline errors too', () async {
      when(() => client.send(any())).thenAnswer((_) => Completer<http.StreamedResponse>().future);
      final api = ApiClient(client, 'http://api.test', timeout: const Duration(milliseconds: 10));
      await expectLater(
        api.getBookmarks('t'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.offline)),
      );
      when(() => client.send(any())).thenThrow(http.ClientException('boom'));
      await expectLater(
        api.login('a@b.co', 'x'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.offline)),
      );
    });

    test('server-shaped responses (note: null) parse', () async {
      when(() => client.send(any())).thenAnswer(
        (_) async => http.StreamedResponse(
          Stream.value(
            utf8.encode(
              '{"serverTime":5,"items":[{"id":"b-1-1","surah":1,"ayah":1,"note":null,"updatedAt":3,"deleted":true}]}',
            ),
          ),
          200,
        ),
      );
      final page = await ApiClient(client, 'http://api.test').getBookmarks('t');
      expect(page.serverTime, 5);
      expect(page.items.single, const Bookmark(id: 'b-1-1', surah: 1, ayah: 1, updatedAt: 3, deleted: true));
    });

    test('HTTP status codes map to error kinds', () async {
      Future<ApiErrorKind> kindFor(int code) async {
        when(
          () => client.send(any()),
        ).thenAnswer((_) async => http.StreamedResponse(Stream.value(utf8.encode('{"detail":"x"}')), code));
        try {
          await ApiClient(client, 'http://api.test').getBookmarks('t');
        } on ApiException catch (e) {
          expect(e.detail, 'x');
          expect(e.statusCode, code);
          return e.kind;
        }
        fail('no exception for $code');
      }

      expect(await kindFor(401), ApiErrorKind.unauthorized);
      expect(await kindFor(409), ApiErrorKind.conflict);
      expect(await kindFor(422), ApiErrorKind.validation);
      expect(await kindFor(429), ApiErrorKind.rateLimited);
      expect(await kindFor(500), ApiErrorKind.server);
    });

    test('malformed payloads are server errors', () async {
      when(() => client.send(any())).thenAnswer(
        (_) async =>
            http.StreamedResponse(Stream.value(utf8.encode('{"serverTime":1,"items":[{"id":"bad id"}]}')), 200),
      );
      await expectLater(
        ApiClient(client, 'http://api.test').getBookmarks('t'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.server)),
      );
      when(
        () => client.send(any()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.value(utf8.encode('[]')), 200));
      await expectLater(
        ApiClient(client, 'http://api.test').login('a@b.co', 'x'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.server)),
      );
    });

    test('invalid base URL is rejected before any request', () async {
      expect(ApiClient.isValidBaseUrl('http://10.0.2.2:8000'), isTrue);
      expect(ApiClient.isValidBaseUrl('https://api.example.org'), isTrue);
      expect(ApiClient.isValidBaseUrl('ftp://x'), isFalse);
      expect(ApiClient.isValidBaseUrl('not a url'), isFalse);
      await expectLater(
        ApiClient(client, 'nope').getBookmarks('t'),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.badUrl)),
      );
      verifyNever(() => client.send(any()));
    });
  });

  group('AccountController', () {
    late FakeApiServer server;
    late MockHttpClient client;
    late SharedPreferences p;
    late AccountController account;
    late BookmarksController store;

    setUp(() async {
      server = FakeApiServer();
      client = MockHttpClient();
      when(
        () => client.send(any()),
      ).thenAnswer((inv) => server.handle(inv.positionalArguments.first as http.BaseRequest));
      p = await prefs();
      final settings = SettingsController(p);
      store = BookmarksController(p, clock: clock);
      account = AccountController(p, settings, store, client, clock: clock);
    });

    test('default server address is the Android emulator host', () {
      expect(SettingsController(p).apiBaseUrl, 'http://10.0.2.2:8000');
    });

    test('client-side validation', () async {
      await account.register('not-an-email', 'longenough1');
      expect(account.message, AccountMessage.errEmail);
      await account.login('a@b.co', 'short');
      expect(account.message, AccountMessage.errPassword);
      expect(account.isError, isTrue);
      verifyNever(() => client.send(any()));
    });

    test('register, duplicate register, bad login, login, sync, logout', () async {
      await account.register('me@x.org', 'password123');
      expect(account.message, AccountMessage.registered);
      expect(account.isError, isFalse);
      await account.register('me@x.org', 'password123');
      expect(account.message, AccountMessage.errTaken);
      await account.login('me@x.org', 'wrongpassword');
      expect(account.message, AccountMessage.errAuth);
      expect(account.signedIn, isFalse);
      await account.login('me@x.org', 'password123');
      expect(account.signedIn, isTrue);
      expect(account.email, 'me@x.org');
      await store.add(const AyahRef(18, 10));
      await account.syncNow();
      expect(account.message, AccountMessage.syncDone);
      expect(account.messageArg, '1');
      expect(account.lastSync, isNotNull);
      expect(server.bookmarks, contains('b-18-10'));
      await account.logout();
      expect(account.signedIn, isFalse);
      expect(account.email, isNull);
    });

    test('offline sync shows a clear offline error and keeps the session', () async {
      await p.setString('account.token', FakeApiServer.token);
      await p.setString('account.email', 'me@x.org');
      when(() => client.send(any())).thenThrow(const SocketException('no route'));
      await account.syncNow();
      expect(account.message, AccountMessage.errOffline);
      expect(account.busy, isFalse);
      expect(account.signedIn, isTrue);
    });

    test('a rejected token signs out with a session-expired message', () async {
      await p.setString('account.token', 'stale');
      await p.setString('account.email', 'me@x.org');
      await account.syncNow();
      expect(account.message, AccountMessage.errSession);
      expect(account.signedIn, isFalse);
    });

    test('an expired token is not used', () async {
      await p.setString('account.token', FakeApiServer.token);
      await p.setString('account.email', 'me@x.org');
      await p.setInt('account.expiresAt', now - 1);
      expect(account.signedIn, isFalse);
      await account.syncNow();
      expect(account.message, AccountMessage.errSession);
      verifyNever(() => client.send(any()));
    });

    test('rate limiting and server errors', () async {
      when(
        () => client.send(any()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.value(utf8.encode('{}')), 429));
      await account.login('me@x.org', 'password123');
      expect(account.message, AccountMessage.errRateLimit);
      when(
        () => client.send(any()),
      ).thenAnswer((_) async => http.StreamedResponse(Stream.value(utf8.encode('oops')), 503));
      await account.login('me@x.org', 'password123');
      expect(account.message, AccountMessage.errServer);
      expect(account.messageArg, '503');
    });

    test('server address is validated and saved', () async {
      expect(await account.saveServer('localhost'), isFalse);
      expect(account.message, AccountMessage.serverInvalid);
      expect(await account.saveServer(' https://api.rattil.org '), isTrue);
      expect(account.message, AccountMessage.serverSaved);
      expect(p.getString('apiBaseUrl'), 'https://api.rattil.org');
    });
  });
}
