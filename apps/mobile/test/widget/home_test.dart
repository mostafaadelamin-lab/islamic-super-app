import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/audio_queue.dart';
import 'package:rattil/ui/home_shell.dart';
import 'package:rattil/ui/more_screen.dart';
import 'package:rattil/ui/prayer_screen.dart';
import 'package:rattil/ui/qibla_screen.dart';
import 'package:rattil/ui/kids_screen.dart';
import 'package:rattil/ui/lessons_screen.dart';
import 'package:rattil/ui/surah_list_screen.dart';
import 'package:rattil/ui/tasbih_screen.dart';

import 'package:rattil/ui/prayer_calendar_screen.dart';

import 'package:rattil/domain/reels.dart';
import 'package:rattil/ui/home_screen.dart';

import '../helpers.dart';

String ltr(String s) => '\u2066$s\u2069';

void main() {
  setUpAll(loadContent);

  testWidgets('hero: place, next prayer with its time and countdown; opens the prayer tab', (tester) async {
    await pumpApp(tester, size: tallPhone);
    // fixedNow = 12:00 Cairo on 2026-01-15 (Thursday); Dhuhr is 12:05 (adhan-js vector).
    expect(find.text('توقيت'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('home.city'))).data, 'مصر - القاهرة');
    expect(find.text('صلاة الظهر'), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('home.nextTime'))).textSpan!.toPlainText(), '١٢:٠٥');
    expect(find.text('متبقي ${ltr('٠:٠٥:٠٠')}'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home.nextPrayer')));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerScreen), findsOneWidget);
    expect(tester.state<HomeShellState>(find.byType(HomeShell)).index, 2);
  });

  testWidgets('day card: weekday, dates, five prayers, sunrise and sunset, calendar', (tester) async {
    await pumpApp(tester, size: tallPhone);
    expect(find.text('الخميس'), findsOneWidget);
    expect(find.text('١٥ يناير ٢٠٢٦'), findsOneWidget);
    expect(find.text('٢٦ رجب ١٤٤٧ هـ'), findsOneWidget);
    for (final k in homePrayersForTest) {
      expect(find.byKey(Key('home.time-$k')), findsOneWidget);
    }
    expect(find.byKey(const Key('home.time-sunrise')), findsOneWidget);
    expect(find.byKey(const Key('home.sunset')), findsOneWidget);
    expect(find.text('الغروب  '), findsOneWidget);
    await tester.tap(find.byKey(const Key('home.calendar')));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerCalendarScreen), findsOneWidget);
  });

  testWidgets('no settings icon on the prayer card (owner 2026-11-15); main sections opens More', (tester) async {
    await pumpApp(tester, size: tallPhone);
    expect(find.byKey(const Key('home.settings')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('home.mainSections')));
    await tester.tap(find.byKey(const Key('home.mainSections')));
    await tester.pumpAndSettle();
    expect(find.byType(MoreScreen), findsOneWidget);
  });

  testWidgets('tiles: Quran, adhkar, prayer tabs; tasbih, qibla, kids, lessons screens (owner 2026-11-24)', (
    tester,
  ) async {
    await pumpApp(tester, size: tallPhone);
    Future<void> tile(String id) async {
      await tester.ensureVisible(find.byKey(Key('home.tile-$id')));
      await tester.tap(find.byKey(Key('home.tile-$id')));
      await tester.pumpAndSettle();
    }

    for (final (id, tab) in [('quran', 1), ('adhkar', 3), ('prayer', 2)]) {
      await tile(id);
      expect(tester.state<HomeShellState>(find.byType(HomeShell)).index, tab, reason: id);
      if (id == 'quran') expect(find.byType(SurahListScreen), findsOneWidget);
      await goToTab(tester, 0);
    }
    for (final (id, type) in [('tasbih', TasbihScreen), ('qibla', QiblaScreen), ('kids', KidsScreen)]) {
      await tile(id);
      expect(find.byType(type), findsOneWidget, reason: id);
      await goBack(tester);
    }
    // «افهم دينك» loads its catalogue from the assets: only check that it opens.
    await tester.ensureVisible(find.byKey(const Key('home.tile-lessons')));
    await tester.tap(find.byKey(const Key('home.tile-lessons')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LessonsScreen), findsOneWidget);
  });

  testWidgets('Quran radio: chosen reciter, whole Mushaf, duration stops it, pause/resume', (tester) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, size: tallPhone, audio: audio);
    final s = app.services;
    await tester.ensureVisible(find.byKey(const Key('radio.play')));
    // The play duration sits inside the player bar (owner 2026-11-24): ∞ until a time is chosen.
    expect(find.text('∞'), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.duration')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.duration-15')).last);
    await tester.pumpAndSettle();
    expect(find.text('١٥'), findsOneWidget);
    await s.settings.setReciter('Yasser_Ad-Dussary_128kbps');
    await s.settings.setRadioStation('mushaf');
    await tester.pump();
    await tester.tap(find.byKey(const Key('radio.play')));
    await tester.pump();
    expect(s.recitation.scope, PlayScope.radio);
    expect(s.recitation.isPlaying, isTrue);
    expect(audio.loaded.single, contains('/Yasser_Ad-Dussary_128kbps/'));
    // every surah once: 6236 ayahs plus 112 basmalas
    expect(s.recitation.queue.where((q) => !q.isBasmala), hasLength(6236));
    expect(s.sleepTimer.isOn, isTrue);
    expect(s.sleepTimer.minutesLeft, 15);
    expect(find.textContaining('سورة '), findsWidgets);
    await tester.tap(find.byKey(const Key('radio.play')));
    await tester.pump();
    expect(s.recitation.isPlaying, isFalse);
    await s.recitation.stop();
    s.sleepTimer.set(null);
    await tester.pump();
  });

  testWidgets('Quran radio: «صوتي» on every station + Haramain «مباشر الآن فيديو» buttons (owner 2026-11-28)', (
    tester,
  ) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, size: tallPhone, audio: audio);
    final s = app.services;
    expect(s.reelsFeed.live.map((c) => c.place), ['makkah', 'madinah']);
    await pushScreen(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: QuranRadioCard(
            livePlayerBuilder: (context, LiveChannel c) =>
                ColoredBox(key: Key('live.player.${c.id}'), color: Colors.red, child: const SizedBox.expand()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // the closed station field already says «صوتي»; the open list says it on every station
    expect(find.byKey(const Key('radio.audioTag')), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.station')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio.audioTag')), findsNWidgets(1 + 5));
    expect(find.text('صوتي'), findsNWidgets(1 + 5));
    await tester.tap(find.text('إذاعة القرآن الكريم من القاهرة').last);
    await tester.pumpAndSettle();
    // the two live-video buttons
    expect(find.text('مباشر الآن فيديو'), findsNWidgets(2));
    expect(find.text('مكة المكرمة'), findsOneWidget);
    expect(find.text('المدينة المنورة'), findsOneWidget);
    expect(find.byKey(const Key('radio.video')), findsNothing);
    // audio on, then the Makkah video: the audio stops and the video opens in the card
    await tester.tap(find.byKey(const Key('radio.play')));
    await tester.pump();
    expect(s.narration.isActive, isTrue);
    await tester.tap(find.byKey(const Key('radio.live-makkah')));
    await tester.pumpAndSettle();
    expect(s.narration.isActive, isFalse);
    expect(find.byKey(const Key('live.player.live-makkah')), findsOneWidget);
    // switch to Madinah
    await tester.tap(find.byKey(const Key('radio.live-madinah')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('live.player.live-madinah')), findsOneWidget);
    expect(find.byKey(const Key('live.player.live-makkah')), findsNothing);
    // the audio play button closes the video
    await tester.tap(find.byKey(const Key('radio.play')));
    await tester.pump();
    expect(find.byKey(const Key('radio.video')), findsNothing);
    await s.narration.stop();
    await tester.pump();
    // ✕ closes it
    await tester.tap(find.byKey(const Key('radio.live-makkah')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('radio.videoClose')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('radio.video')), findsNothing);
  });
}

const homePrayersForTest = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
