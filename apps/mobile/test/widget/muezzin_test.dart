
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
    for (final v in bundledAdhanVoices) {
      expect(v.credit, isNotNull, reason: v.id);
    }
  });

  testWidgets('defaults: Makkah Haram adhan, and its own Fajr adhan', (tester) async {
    final app = await pumpApp(tester, size: tallPhone, locale: 'en');
    final s = app.services.settings;
    expect(s.adhanVoice, 'haram');
    expect(s.adhanFajrVoice, 'haram_fajr');
    expect(s.adhanVoiceFor('fajr'), 'haram_fajr');
    expect(s.adhanVoiceFor('maghrib'), 'haram');
    expect(app.services.adhan.nativeVoiceFor('fajr'), 'adhan_haram_fajr');
    expect(app.services.adhan.nativeVoiceFor('isha'), 'adhan_haram');
    await expectLater(s.setAdhanVoice('nope'), throwsA(anything));
    expect(s.adhanVoice, 'haram');
  });

  testWidgets('Fajr list shows only Fajr adhans; the main list the others; tapping one chooses it', (tester) async {
    final app = await pumpApp(tester, size: tallPhone, locale: 'en');
    await tester.runAsync(app.services.adhanVoices.catalog);
    await pushScreen(tester, const MuezzinScreen(fajr: true));
    expect(find.byKey(const Key('muezzin-haram_fajr')), findsOneWidget);
    expect(find.byKey(const Key('muezzin-haram')), findsNothing);
    await goBack(tester);
    await pushScreen(tester, const MuezzinScreen(fajr: false));
    for (final id in ['haram', 'madinah', 'fakhry', 'v1', 'v2']) {
      expect(find.byKey(Key('muezzin-$id')), findsOneWidget, reason: id);
    }
    expect(find.byKey(const Key('muezzin-haram_fajr')), findsNothing);
    await tester.tap(find.byKey(const Key('muezzin-madinah')));
    await tester.pumpAndSettle();
    expect(app.services.settings.adhanVoice, 'madinah');
    expect(app.services.adhan.nativeVoiceFor('dhuhr'), 'adhan_madinah');
    expect(app.services.adhan.nativeVoiceFor('fajr'), 'adhan_haram_fajr');
  });
}
