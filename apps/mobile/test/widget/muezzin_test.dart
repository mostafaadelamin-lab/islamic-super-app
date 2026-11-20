import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:rattil/domain/adhan_voices.dart';
import 'package:rattil/ui/muezzin_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(() async {
    registerFallbackValue(Uri());
    await loadContent();
  });

  test('the muezzins; only the Makkah Haram defaults are bundled, the others download from the website', () {
    expect(isAdhanVoiceId('haram'), isTrue);
    expect(isAdhanVoiceId('madinah'), isTrue);
    expect(isAdhanVoiceId('iw426698'), isFalse);
    expect(isAdhanVoiceId('../x'), isFalse);
    expect(findAdhanVoice(defaultFajrVoice)!.fajr, isTrue);
    expect(findAdhanVoice(defaultAdhanVoice)!.fajr, isFalse);
    expect(
      [
        for (final v in allAdhanVoices)
          if (v.bundled) v.id,
      ],
      [defaultAdhanVoice, defaultFajrVoice],
    );
    for (final v in allAdhanVoices) {
      if (v.bundled) {
        expect(File('assets/audio/${v.raw}.m4a').existsSync(), isTrue, reason: v.id);
        expect(File('android/app/src/main/res/raw/${v.raw}.ogg').existsSync(), isTrue, reason: v.id);
        expect(v.downloadUris, isEmpty, reason: v.id);
      } else {
        expect(v.raw, isNull, reason: v.id);
        expect(v.downloadUris.first, Uri.parse('https://rattilwasalli.com/audio/${v.remote}.mp3'), reason: v.id);
        // The website serves the same file (apps/web/public/audio).
        expect(File('../web/public/audio/${v.remote}.mp3').existsSync(), isTrue, reason: v.id);
        for (final u in v.downloadUris) {
          expect(u.scheme, 'https', reason: v.id);
        }
      }
    }
    // Nothing else is shipped (besides the short dhikr reminder clips, dhikr_*.ogg, owner 2026-11-20).
    expect(
      Directory(
        'android/app/src/main/res/raw',
      ).listSync().map((f) => f.uri.pathSegments.last).where((n) => !n.startsWith('dhikr_')).toSet(),
      {'adhan_mulla.ogg', 'adhan_daghriri_fajr.ogg', 'keep.xml'},
    );
    // Openly licensed recordings carry their credit; the owner's picks never show a source.
    for (final v in allAdhanVoices) {
      final owners = [
        'mulla',
        'makkah',
        'bukhari',
        'mismail',
        'banna',
        'rifaat',
        'daghriri_fajr',
        'afasy_fajr',
        'abdulbasit',
        'abdulbasit_fajr',
      ];
      expect(v.credit == null, owners.contains(v.id), reason: v.id);
    }
    expect(findAdhanVoice('afasy_fajr')!.fajr, isTrue);
    expect(findAdhanVoice('rifaat')!.fajr, isFalse);
  });

  testWidgets('defaults: Ali Mulla (Makkah Haram), and Al-Daghriri for Fajr', (tester) async {
    final app = await pumpApp(tester, size: tallPhone, locale: 'en');
    final s = app.services.settings;
    expect(s.adhanVoice, 'mulla');
    expect(s.adhanFajrVoice, 'daghriri_fajr');
    expect(s.adhanVoiceFor('fajr'), 'daghriri_fajr');
    expect(s.adhanVoiceFor('maghrib'), 'mulla');
    expect(app.services.adhan.nativeVoiceFor('fajr'), 'adhan_daghriri_fajr');
    expect(app.services.adhan.nativeVoiceFor('isha'), 'adhan_mulla');
    await expectLater(s.setAdhanVoice('nope'), throwsA(anything));
    expect(s.adhanVoice, 'mulla');
  });

  testWidgets('Fajr list shows only Fajr adhans; the main list the others; tapping one downloads and chooses it', (
    tester,
  ) async {
    final storage = Directory.systemTemp.createTempSync('rattil-muezzin');
    final client = MockHttpClient();
    final asked = <Uri>[];
    when(() => client.get(any())).thenAnswer((i) async {
      asked.add(i.positionalArguments.first as Uri);
      return http.Response.bytes([0x49, 0x44, 0x33, ...List.filled(64 * 1024, 0)], 200);
    });
    final app = await pumpApp(tester, size: tallPhone, locale: 'en', httpClient: client, storage: storage);
    await tester.runAsync(app.services.adhanVoices.catalog);
    await pushScreen(tester, const MuezzinScreen(fajr: true));
    for (final id in ['daghriri_fajr', 'afasy_fajr', 'haram_fajr']) {
      expect(find.byKey(Key('muezzin-$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('muezzin-haram')), findsNothing);
    expect(find.byKey(const Key('muezzin-mulla')), findsNothing);
    await goBack(tester);
    await pushScreen(tester, const MuezzinScreen(fajr: false));
    for (final id in [
      'mulla',
      'makkah',
      'bukhari',
      'mismail',
      'banna',
      'rifaat',
      'haram',
      'madinah',
      'fakhry',
      'v1',
      'v2',
    ]) {
      expect(find.byKey(Key('muezzin-$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('muezzin-haram_fajr')), findsNothing);
    expect(find.byKey(const Key('muezzin-afasy_fajr')), findsNothing);
    await tester.tap(find.byKey(const Key('muezzin-madinah')));
    await tester.pumpAndSettle();
    expect(asked, [Uri.parse('https://rattilwasalli.com/audio/adhan_madinah.mp3')]);
    expect(app.services.settings.adhanVoice, 'madinah');
    expect(app.services.adhan.nativeVoiceFor('dhuhr'), '${storage.path}/adhan/madinah.mp3');
    expect(app.services.adhan.nativeVoiceFor('fajr'), 'adhan_daghriri_fajr');
  });
}
