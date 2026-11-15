import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/mp3quran.dart';
import 'package:rattil/domain/mp3quran.dart';
import 'package:rattil/ui/library_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:rattil/ui/radio_screen.dart';

import '../helpers.dart';

const _reciters = {
  'reciters': [
    {
      'id': 153,
      'name': 'أخيل عبدالحي روا',
      'letter': 'أ',
      'moshaf': [
        {
          'id': 153,
          'name': 'حفص عن عاصم - مرتل',
          'rewaya_id': 1,
          'server': 'https://cdn.mp3quran.net/audio/akhil-rawa/r1/',
          'surah_total': 4,
          'moshaf_type': 11,
          'surah_list': '50,51,52,56',
        },
      ],
    },
    {
      'id': 7,
      'name': 'إبراهيم الأخضر',
      'moshaf': [
        {
          'id': 7,
          'name': 'حفص عن عاصم - مرتل',
          'rewaya_id': 1,
          'server': 'https://server6.mp3quran.net/akdr',
          'surah_list': '1,2,114,115,x,2',
        },
        {'id': 70, 'name': 'ورش عن نافع', 'rewaya_id': 2, 'server': 'http://insecure.example/', 'surah_list': '1'},
        {
          'id': 71,
          'name': 'ورش عن نافع',
          'rewaya_id': 2,
          'server': 'https://cdn.mp3quran.net/warsh/',
          'surah_list': '1,36',
        },
      ],
    },
    {'id': 9, 'name': 'بلا تلاوات', 'moshaf': []},
    {'name': 'بلا رقم'},
  ],
};
const _riwayat = {
  'riwayat': [
    {'id': 1, 'name': 'حفص عن عاصم'},
    {'id': 2, 'name': 'ورش عن نافع'},
  ],
};
const _radios = {
  'radios': [
    {'id': 1, 'name': 'إبراهيم الأخضر', 'url': 'https://backup.qurango.net/radio/ibrahim_alakdar'},
    {'id': 2, 'name': 'غير آمن', 'url': 'http://example.com/radio'},
  ],
};

http.Client _api({bool fail = false, List<String>? calls}) => MockClient((req) async {
  calls?.add(req.url.toString());
  if (fail) throw const SocketException('offline');
  final body = switch (req.url.pathSegments.last) {
    'reciters' => _reciters,
    'riwayat' => _riwayat,
    'radios' => _radios,
    _ => null,
  };
  if (body == null) return http.Response('', 404);
  return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
});

void main() {
  setUpAll(() async => loadContent());

  group('mp3quran library', () {
    test('keeps only well-formed, https recordings and radios', () {
      final lib = Mp3Library.fromApi(reciters: _reciters, riwayat: _riwayat, radios: _radios);
      expect(lib.reciters.map((r) => r.id), [153, 7]);
      final akdr = lib.reciters.firstWhere((r) => r.id == 7);
      expect(akdr.moshafs.map((m) => m.id), [7, 71]);
      expect(akdr.moshafs.first.surahs, [1, 2, 114]);
      expect(akdr.moshafs.first.url(1), 'https://server6.mp3quran.net/akdr/001.mp3');
      expect(
        lib.reciters.firstWhere((r) => r.id == 153).moshafs.single.url(56),
        'https://cdn.mp3quran.net/audio/akhil-rawa/r1/056.mp3',
      );
      expect(lib.radios.map((r) => r.id), [1]);
      expect(lib.riwayat.map((w) => w.id), [1, 2]);
      String norm(String s) => s.replaceAll(RegExp('[إأآ]'), 'ا');
      expect(lib.filterReciters('', 2, norm).map((r) => r.id), [7]);
      expect(lib.filterReciters('ابراهيم', null, norm).map((r) => r.id), [7]);
      expect(lib.filterRadios('xyz', norm), isEmpty);
      expect(Mp3Library.fromApi(reciters: 'x', riwayat: null, radios: 3).reciters, isEmpty);
      expect(parseSurahList(null), isEmpty);
    });

    test('caches the answer for a week and falls back to it offline', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var now = DateTime.utc(2026, 11, 10);
      final calls = <String>[];
      Mp3QuranClient make(http.Client c) => Mp3QuranClient(httpClient: c, prefs: prefs, clock: () => now);
      final lib = await make(_api(calls: calls)).load('ar');
      expect(lib.reciters, hasLength(2));
      expect(calls, hasLength(3));
      expect(calls.first, startsWith('https://www.mp3quran.net/api/v3/'));
      expect(calls.first, endsWith('?language=ar'));
      await make(_api(calls: calls)).load('ar');
      expect(calls, hasLength(3)); // fresh cache, no network
      now = now.add(const Duration(days: 8));
      expect((await make(_api(fail: true)).load('ar')).radios, hasLength(1)); // stale cache, offline
      await expectLater(make(_api(fail: true)).load('eng'), throwsA(isA<SocketException>()));
    });
  });

  testWidgets('library: filter by riwaya, play a surah, play a radio', (tester) async {
    final audio = FakeNarrationBackend();
    final app = await pumpApp(tester, httpClient: _api(), narration: audio, size: tallPhone);
    await pushScreen(tester, const LibraryScreen());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reciter-7')), findsOneWidget);
    expect(find.byKey(const Key('reciter-153')), findsOneWidget);
    expect(find.byKey(const Key('librarySource')), findsOneWidget);

    await tester.tap(find.byKey(const Key('libraryRewaya')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ورش عن نافع').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reciter-153')), findsNothing);

    await tester.tap(find.byKey(const Key('reciter-7')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surah-36')), findsOneWidget);
    await tester.tap(find.byKey(const Key('surah-36')));
    await tester.pumpAndSettle();
    expect(app.services.narration.episode?.url, 'https://cdn.mp3quran.net/warsh/036.mp3');
    // Owner 2026-11-15: the player is under the surah playing, not in a bar away from it.
    expect(
      find.descendant(of: find.byKey(const Key('surah-36')), matching: find.byKey(const Key('inlinePlayer'))),
      findsOneWidget,
    );
    expect(find.byKey(const Key('narrationBar')), findsNothing);

    await goBack(tester);
    await tester.pumpAndSettle();
    // Leaving the reciter's page: the bar at the bottom takes over.
    expect(find.byKey(const Key('narrationBar')), findsOneWidget);
    await goBack(tester);
    await pushScreen(tester, const RadioScreen());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio-eg')), findsOneWidget);
    expect(find.byKey(const Key('radio-sa')), findsOneWidget);
    expect(find.byKey(const Key('radio-makkah')), findsOneWidget);
    expect(find.byKey(const Key('radio-madinah')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('radio-1')), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('radio-1')));
    await tester.pumpAndSettle();
    expect(app.services.narration.episode?.url, 'https://backup.qurango.net/radio/ibrahim_alakdar');
    expect(
      find.descendant(of: find.byKey(const Key('radio-1')), matching: find.byKey(const Key('inlinePlayer'))),
      findsOneWidget,
    );
    expect(find.byKey(const Key('inlineSlider')), findsNothing, reason: 'a live station has no seek bar');
    await app.services.narration.stop();
    expect(app.services.settings.storyPosition('radio/radio-1'), 0);
  });

  testWidgets('library: offline with nothing saved shows a retry', (tester) async {
    await pumpApp(tester, httpClient: _api(fail: true), size: tallPhone);
    await pushScreen(tester, const LibraryScreen());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('libraryError')), findsOneWidget);
    expect(find.byKey(const Key('libraryRetry')), findsOneWidget);
  });

  testWidgets('More opens the library', (tester) async {
    await pumpApp(tester, httpClient: _api(), size: tallPhone);
    await goToTab(tester, 5);
    await tester.scrollUntilVisible(
      find.byKey(const Key('more.library')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('more.library')));
    await tester.pumpAndSettle();
    expect(find.byType(LibraryScreen), findsOneWidget);
  });
}
