
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/adhan_voices.dart';
import 'package:rattil/ui/muezzin_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  test('only the bundled, openly licensed voices are valid', () {
    expect(isAdhanVoiceId('haram'), isTrue);
    expect(isAdhanVoiceId('madinah'), isTrue);
    expect(isAdhanVoiceId('iw426698'), isFalse);
    expect(isAdhanVoiceId('../x'), isFalse);
    expect(remoteAdhanId('iw122646'), isNull);
    expect(bundledAdhanVoice(defaultFajrVoice)!.fajr, isTrue);
    expect(bundledAdhanVoice(defaultAdhanVoice)!.fajr, isFalse);
    // Openly licensed recordings carry their credit; the owner's picks never show a source.
    for (final v in bundledAdhanVoices) {
      final owners = ['mulla', 'makkah', 'bukhari', 'mismail', 'banna', 'rifaat', 'daghriri_fajr', 'afasy_fajr'];
      expect(v.credit == null, owners.contains(v.id), reason: v.id);
    }
    expect(bundledAdhanVoice('afasy_fajr')!.fajr, isTrue);
    expect(bundledAdhanVoice('rifaat')!.fajr, isFalse);
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

  testWidgets('Fajr list shows only Fajr adhans; the main list the others; tapping one chooses it', (tester) async {
    final app = await pumpApp(tester, size: tallPhone, locale: 'en');
    await tester.runAsync(app.services.adhanVoices.catalog);
    await pushScreen(tester, const MuezzinScreen(fajr: true));
    for (final id in ['daghriri_fajr', 'afasy_fajr', 'haram_fajr']) {
      expect(find.byKey(Key('muezzin-$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('muezzin-haram')), findsNothing);
    expect(find.byKey(const Key('muezzin-mulla')), findsNothing);
    await goBack(tester);
    await pushScreen(tester, const MuezzinScreen(fajr: false));
    for (final id in ['mulla', 'makkah', 'bukhari', 'mismail', 'banna', 'rifaat', 'haram', 'madinah', 'fakhry', 'v1', 'v2']) {
      expect(find.byKey(Key('muezzin-$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('muezzin-haram_fajr')), findsNothing);
    expect(find.byKey(const Key('muezzin-afasy_fajr')), findsNothing);
    await tester.tap(find.byKey(const Key('muezzin-madinah')));
    await tester.pumpAndSettle();
    expect(app.services.settings.adhanVoice, 'madinah');
    expect(app.services.adhan.nativeVoiceFor('dhuhr'), 'adhan_madinah');
    expect(app.services.adhan.nativeVoiceFor('fajr'), 'adhan_daghriri_fajr');
  });
}
