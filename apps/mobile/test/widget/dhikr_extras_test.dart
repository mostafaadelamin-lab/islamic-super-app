import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/home_widget_sync.dart';
import 'package:rattil/ui/dhikr_audio.dart';
import 'package:rattil/ui/dhikr_hadith.dart';
import 'package:rattil/ui/hisn_screen.dart';

import '../helpers.dart';

class FakeUrlAudio implements UrlAudio {
  final playingC = StreamController<bool>.broadcast();
  final completedC = StreamController<bool>.broadcast();
  final positionC = StreamController<Duration>.broadcast();
  final durationC = StreamController<Duration?>.broadcast();
  final calls = <String>[];

  @override
  Future<void> play(String url) async {
    calls.add('play');
    durationC.add(const Duration(seconds: 30));
    playingC.add(true);
  }

  @override
  Future<void> pause() async {
    calls.add('pause');
    playingC.add(false);
  }

  @override
  Future<void> resume() async {
    calls.add('resume');
    playingC.add(true);
  }

  @override
  Future<void> seek(Duration d) async => positionC.add(d);
  @override
  Future<void> stop() async {
    calls.add('stop');
    playingC.add(false);
  }

  @override
  Stream<bool> get playing => playingC.stream;
  @override
  Stream<bool> get completed => completedC.stream;
  @override
  Stream<Duration> get position => positionC.stream;
  @override
  Stream<Duration?> get duration => durationC.stream;
}

void main() {
  setUpAll(loadContent);

  testWidgets('dhikr audio: a play/pause bar while listening; stop hides it; the end does not loop', (tester) async {
    final fake = FakeUrlAudio();
    debugUrlAudioFactory = () => fake;
    addTearDown(() => debugUrlAudioFactory = null);
    final app = await pumpApp(tester, size: tallPhone);
    await app.services.settings.setAdhkarCards(false);
    await pushScreen(tester, HisnChapterScreen(chapter: app.services.content.adhkar.hisn[1]));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dhikrPlayerBar')), findsNothing);
    await tester.tap(find.byKey(const Key('dhikrListen')).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dhikrPlayerBar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dhikrPlayerToggle')));
    await tester.pumpAndSettle();
    expect(fake.calls.last, 'pause');
    await tester.tap(find.byKey(const Key('dhikrPlayerToggle')));
    await tester.pumpAndSettle();
    expect(fake.calls.last, 'resume');
    fake.completedC.add(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dhikrPlayerBar')), findsNothing, reason: 'finished: stopped, not repeated');
    await tester.tap(find.byKey(const Key('dhikrListen')).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dhikrPlayerStop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dhikrPlayerBar')), findsNothing);
    await DhikrPlayer.instance.stop();
  });

  testWidgets('the hadith icon under a dhikr opens its hadith and source', (tester) async {
    DhikrHadithMap.debugMap = DhikrHadithMap.fromJson(
      jsonDecode(File('assets/content/adhkar-hadith.v1.json').readAsStringSync()) as Map<String, dynamic>,
    );
    addTearDown(() => DhikrHadithMap.debugMap = null);
    final app = await pumpApp(tester, size: tallPhone);
    await app.services.settings.setAdhkarCards(false);
    await pushScreen(tester, HisnChapterScreen(chapter: app.services.content.adhkar.hisn[1]));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('hisnHadith-4')), 200);
    await tester.tap(find.byKey(const Key('hisnHadith-4')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dhikrHadithSheet')), findsOneWidget);
  });

  testWidgets('home-screen widget data: a week of Hijri dates and five prayer times', (tester) async {
    final app = await pumpApp(tester);
    final j = jsonDecode(HomeWidgetSync(app.services).build()) as Map<String, dynamic>;
    expect(j['lang'], 'ar');
    final days = j['days'] as List<dynamic>;
    expect(days.length, greaterThanOrEqualTo(HomeWidgetSync.days));
    for (final d in days.cast<Map<String, dynamic>>()) {
      final p = d['p'] as List<dynamic>;
      expect([for (final x in p) (x as List<dynamic>)[0]], ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']);
      final t = [for (final x in p) (x as List<dynamic>)[2] as int];
      expect(t, orderedEquals([...t]..sort()));
      expect(d['h'], matches(RegExp(r'^\d\d .+ \d{4}$')));
      // the medium widget's sixth time (owner 2026-11-20): sunrise, between Fajr and Dhuhr
      expect(d['sr'] as int, inExclusiveRange(t[0], t[1]));
    }
    // the widgets follow the app's clock (12 h by default; the tests run on 24 h)
    expect(j['c12'], isFalse);
    await app.services.settings.setClock12(true);
    expect((jsonDecode(HomeWidgetSync(app.services).build()) as Map<String, dynamic>)['c12'], isTrue);
  });
}
