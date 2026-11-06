// Contract tests of the app's real HTTP client and sync logic against a live
// services/api server. Not part of `flutter test` (which runs test/ only):
//   RATTIL_API_URL=http://<host>:8000 flutter test test_contract
// The server must allow a few auth requests per minute (ISA_AUTH_RATE).
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rattil/data/account.dart';
import 'package:rattil/data/api.dart';
import 'package:rattil/data/bookmarks.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/data/sync.dart';
import 'package:rattil/domain/bookmark.dart';
import 'package:rattil/domain/quran.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final base = Platform.environment['RATTIL_API_URL'];
  if (base == null) {
    throw StateError('Set RATTIL_API_URL to a running services/api server');
  }
  final client = http.Client();
  final api = ApiClient(client, base);
  final email = 'contract-${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(1 << 30)}@example.org';
  const password = 'correct horse battery';
  late String token;

  Future<SharedPreferences> freshPrefs() async {
    // flutter test has no platform plugins: use the in-memory store (this IS test code,
    // but test_contract/ is not a directory the analyzer recognises as tests).
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({'apiBaseUrl': base});
    return SharedPreferences.getInstance();
  }

  test('register -> 201, duplicate -> 409 conflict', () async {
    await api.register(email, password);
    await expectLater(
      api.register(email, password),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.conflict)),
    );
  });

  test('login: wrong password -> 401, right password -> bearer token', () async {
    await expectLater(
      api.login(email, 'wrong password!!'),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
    );
    final r = await api.login(email, password);
    expect(r.accessToken, isNotEmpty);
    expect(r.expiresIn, greaterThan(0));
    token = r.accessToken;
  });

  test('bad token -> unauthorized', () async {
    await expectLater(
      api.getBookmarks('not-a-token'),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.unauthorized)),
    );
  });

  test('PUT body is accepted by the server and round-trips', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final stored = await api.putBookmark(token, Bookmark(id: 'b-2-255', surah: 2, ayah: 255, updatedAt: now));
    expect(stored, Bookmark(id: 'b-2-255', surah: 2, ayah: 255, updatedAt: now));
    final page = await api.getBookmarks(token);
    expect(page.items.map((b) => b.id), contains('b-2-255'));
    expect(page.serverTime, greaterThan(0));
  });

  test('server rejects an ayah beyond the surah length (validation)', () async {
    await expectLater(
      api.putBookmark(token, const Bookmark(id: 'b-1-8', surah: 1, ayah: 8, updatedAt: 1)),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.validation)),
    );
  });

  test('server keeps the newer copy (LWW) and returns it', () async {
    final stored = await api.putBookmark(token, const Bookmark(id: 'b-2-255', surah: 2, ayah: 255, updatedAt: 1));
    expect(stored.updatedAt, greaterThan(1), reason: 'older write ignored');
  });

  test('two devices converge through SyncService (LWW + tombstones)', () async {
    // Device A
    final prefsA = await freshPrefs();
    var t = DateTime.now().millisecondsSinceEpoch + 10000;
    final a = BookmarksController(prefsA, clock: () => DateTime.fromMillisecondsSinceEpoch(t));
    await a.add(const AyahRef(36, 1));
    await a.add(const AyahRef(18, 10));
    await SyncService(api, a).sync(token);

    // Device B (separate storage) pulls everything, then deletes 36:1 later.
    final prefsB = await freshPrefs();
    final b = BookmarksController(prefsB, clock: () => DateTime.fromMillisecondsSinceEpoch(t + 5000));
    await SyncService(api, b).sync(token);
    expect(b.isBookmarked(const AyahRef(36, 1)), isTrue);
    expect(b.isBookmarked(const AyahRef(18, 10)), isTrue);
    expect(b.isBookmarked(const AyahRef(2, 255)), isTrue);
    await b.remove('b-36-1');
    await SyncService(api, b).sync(token);

    // Meanwhile A re-touched 36:1 *earlier* than B's delete: B's tombstone wins.
    t += 1000;
    final aRestored = BookmarksController(prefsA, clock: () => DateTime.fromMillisecondsSinceEpoch(t));
    final report = await SyncService(api, aRestored).sync(token);
    expect(aRestored.isBookmarked(const AyahRef(36, 1)), isFalse);
    expect(aRestored.all['b-36-1']!.deleted, isTrue);
    expect(report.active, aRestored.active.length);
    expect(aRestored.dirty, isEmpty);
  });

  test('AccountController end to end with the real client', () async {
    final prefs = await freshPrefs();
    final settings = SettingsController(prefs);
    final store = BookmarksController(prefs);
    final account = AccountController(prefs, settings, store, client);
    await account.login(email, password);
    expect(account.signedIn, isTrue);
    await store.add(const AyahRef(112, 1));
    await account.syncNow();
    expect(account.message, AccountMessage.syncDone);
    expect(store.isBookmarked(const AyahRef(18, 10)), isTrue, reason: 'pulled from the server');
    final page = await api.getBookmarks(account.token!);
    expect(page.items.map((b) => b.id), contains('b-112-1'));
  });

  test('unreachable server -> offline error', () async {
    final dead = ApiClient(client, 'http://127.0.0.1:9', timeout: const Duration(seconds: 3));
    await expectLater(
      dead.getBookmarks(token),
      throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.offline)),
    );
  });
}
