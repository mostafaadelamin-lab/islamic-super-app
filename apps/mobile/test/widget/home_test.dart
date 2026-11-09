import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/audio_queue.dart';
import 'package:rattil/ui/home_shell.dart';
import 'package:rattil/ui/more_screen.dart';
import 'package:rattil/ui/prayer_screen.dart';
import 'package:rattil/ui/qibla_screen.dart';
import 'package:rattil/ui/reels_screen.dart';
import 'package:rattil/ui/settings_screen.dart';
import 'package:rattil/ui/stories_screen.dart';
import 'package:rattil/ui/surah_list_screen.dart';
import 'package:rattil/ui/tasbih_screen.dart';

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
    expect(tester.widget<Text>(find.byKey(const Key('home.nextTime'))).data, '١٢:٠٥');
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
    expect(tester.state<HomeShellState>(find.byType(HomeShell)).index, 2);
  });

  testWidgets('settings icon opens Settings; main sections opens More', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await tester.tap(find.byKey(const Key('home.settings')));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await goBack(tester);
    await tester.ensureVisible(find.byKey(const Key('home.mainSections')));
    await tester.tap(find.byKey(const Key('home.mainSections')));
    await tester.pumpAndSettle();
    expect(find.byType(MoreScreen), findsOneWidget);
  });

  testWidgets('tiles: Quran, adhkar, prayer tabs; tasbih, qibla, reels, stories screens', (tester) async {
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
    for (final (id, type) in [
      ('tasbih', TasbihScreen),
      ('qibla', QiblaScreen),
      ('reels', ReelsScreen),
      ('stories', StoriesScreen),
    ]) {
      await tile(id);
      expect(find.byType(type), findsOneWidget, reason: id);
      await goBack(tester);
    }
  });

  testWidgets('Quran radio: chosen reciter, whole Mushaf, duration stops it, pause/resume', (tester) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, size: tallPhone, audio: audio);
    final s = app.services;
    await tester.ensureVisible(find.byKey(const Key('radio.play')));
    expect(find.text('غير محدود'), findsOneWidget);
    await tester.tap(find.byKey(const Key('radio.longer')));
    await tester.pump();
    expect(find.text('١٥ دقيقة'), findsOneWidget);
    await s.settings.setReciter('Yasser_Ad-Dussary_128kbps');
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
}

const homePrayersForTest = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
