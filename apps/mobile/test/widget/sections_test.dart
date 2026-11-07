import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/qibla.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/bookmarks_screen.dart';
import 'package:rattil/ui/hajj_screen.dart';
import 'package:rattil/ui/hisn_screen.dart';
import 'package:rattil/ui/home_shell.dart';
import 'package:rattil/ui/qibla_screen.dart';
import 'package:rattil/ui/settings_screen.dart';
import 'package:rattil/ui/tasbih_screen.dart';

import '../helpers.dart';

/// Wraps [s] in the left-to-right isolate used by context.numLtr.
String ltr(String s) => '\u2066$s\u2069';

void main() {
  setUpAll(loadContent);

  group('Adhkar', () {
    testWidgets('morning by default before Asr, with the review notice and per-item counters', (tester) async {
      final app = await pumpApp(tester, size: tallPhone);
      await goToTab(tester, 3);
      expect(tester.state<AdhkarScreenState>(find.byType(AdhkarScreen)).session, AdhkarSession.morning);
      expect(find.byKey(const Key('adhkarNotice')), findsOneWidget);
      expect(find.textContaining('بانتظار المراجعة الشرعية'), findsOneWidget);
      // Item 3 (al-Ikhlas) is said three times.
      expect(
        find.descendant(of: find.byKey(const Key('dhikrCount-3')), matching: find.text('متبقٍّ ٣')),
        findsOneWidget,
      );
      await tester.ensureVisible(find.byKey(const Key('dhikrTap-3')));
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('dhikrTap-3')));
        await tester.pump();
      }
      expect(
        find.descendant(of: find.byKey(const Key('dhikrCount-3')), matching: find.text('متبقٍّ ١')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('dhikrTap-3')));
      await tester.pump();
      expect(find.descendant(of: find.byKey(const Key('dhikrCount-3')), matching: find.text('تمّ')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dhikrTap-3')));
      await tester.pump();
      expect(app.services.adhkar.progress(AdhkarSession.morning).countOf(app.services.content.adhkar.items[3]), 3);
      await tester.scrollUntilVisible(find.byKey(const Key('adhkarProgress')), -300);
      expect(find.text('أُنجز ١ من ٢٦'), findsOneWidget);
      // Saved for today.
      expect(app.prefs.getString('adhkar.progress.morning'), contains('"3":3'));
    });

    testWidgets('evening after Asr; switching sessions; reset', (tester) async {
      final app = await pumpApp(tester, size: tallPhone, clock: () => DateTime.utc(2026, 1, 15, 17));
      await goToTab(tester, 3);
      final state = tester.state<AdhkarScreenState>(find.byType(AdhkarScreen));
      expect(state.session, AdhkarSession.evening);
      expect(find.byKey(const Key('dhikr-7')), findsOneWidget, reason: 'أمسينا وأمسى الملك لله');
      expect(find.byKey(const Key('dhikr-6')), findsNothing, reason: 'its morning form is hidden');
      await tester.tap(find.byKey(const Key('dhikrTap-0')));
      await tester.pump();
      expect(find.text('أُنجز ١ من ٢٥'), findsOneWidget);
      await tester.tap(find.byKey(const Key('adhkarReset')));
      await tester.pump();
      expect(find.text('أُنجز ٠ من ٢٥'), findsOneWidget);
      await tester.tap(find.text('الصباح'));
      await tester.pumpAndSettle();
      expect(state.session, AdhkarSession.morning);
      expect(find.byKey(const Key('dhikr-6')), findsOneWidget);
      expect(app.services.adhkar.progress(AdhkarSession.evening).completedItems, 0);
    });

    testWidgets('Hisn al-Muslim: 134 chapters, filter, chapter with copy', (tester) async {
      await pumpApp(tester, size: tallPhone);
      await goToTab(tester, 3);
      await tester.tap(find.byKey(const Key('openHisn')));
      await tester.pumpAndSettle();
      expect(find.byType(HisnScreen), findsOneWidget);
      await tester.enterText(find.byKey(const Key('hisnFilter')), 'السفر');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hisn-97')), findsOneWidget, reason: 'دعاء السفر');
      expect(find.byKey(const Key('hisn-0')), findsNothing);
      await tester.tap(find.byKey(const Key('hisn-97')));
      await tester.pumpAndSettle();
      expect(find.byType(HisnChapterScreen), findsOneWidget);
      expect(find.byKey(const Key('hisnItem-0')), findsOneWidget);
      expect(find.text('نسخ'), findsWidgets);
    });
  });

  group('Tasbih', () {
    testWidgets('counts, completes a round at 33, changes target, resets; survives a restart', (tester) async {
      final app = await pumpApp(tester, size: tallPhone, locale: 'en');
      await pushScreen(tester, const TasbihScreen());
      for (var i = 0; i < 34; i++) {
        await tester.tap(find.byKey(const Key('tasbihButton')));
        await tester.pump();
      }
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Rounds: 1'), findsOneWidget);
      expect(find.text('Total: 34'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tasbihTarget-100')));
      await tester.pump();
      expect(app.services.tasbih.state.target, 100);
      // Restart on the same storage.
      await tester.pumpWidget(const SizedBox());
      final again = AppServices.create(
        content: app.services.content,
        prefs: app.prefs,
        httpClient: MockHttpClient(),
        clock: () => fixedNow,
        audioBackend: FakeAudioBackend.new,
        notifications: FakeNotifications(),
      );
      await tester.pumpWidget(RattilApp(services: again));
      await tester.pumpAndSettle();
      expect(again.tasbih.state.total, 34);
      expect(again.tasbih.state.target, 100);
      await pushScreen(tester, const TasbihScreen());
      await tester.tap(find.byKey(const Key('tasbihReset')));
      await tester.pump();
      expect(find.text('Total: 0'), findsOneWidget);
    });
  });

  group('Qibla', () {
    testWidgets('no sensor readings: waits, then falls back to the static diagram', (tester) async {
      await pumpApp(tester, size: tallPhone);
      unawaited(pushRoute(tester, const QiblaScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('qiblaMode-waiting')), findsOneWidget);
      await tester.pump(QiblaScreen.timeout);
      await tester.pump();
      expect(find.byKey(const Key('qiblaMode-static')), findsOneWidget);
      expect(find.byKey(const Key('qiblaCompass')), findsOneWidget);
    });

    testWidgets('sensor error: static diagram straight away', (tester) async {
      await pumpApp(
        tester,
        size: tallPhone,
        sensors: FakeSensors(Stream.error(Exception('no sensor')), Stream.error(Exception('no sensor'))),
      );
      await pushScreen(tester, const QiblaScreen());
      expect(find.byKey(const Key('qiblaMode-static')), findsOneWidget);
    });

    testWidgets('live compass: heading from the sensors and the turn hint', (tester) async {
      final acc = StreamController<Vec3>.broadcast();
      final mag = StreamController<Vec3>.broadcast();
      final app = await pumpApp(tester, size: tallPhone, locale: 'en', sensors: FakeSensors(acc.stream, mag.stream));
      unawaited(pushRoute(tester, const QiblaScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final qibla = app.services.content.calculator.qiblaBearing(30.0444, 31.2357); // Cairo ≈ 136.1°
      // Phone flat, top pointing north.
      acc.add(const Vec3(0, 0, 9.81));
      mag.add(const Vec3(0, 20, -40));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final st = tester.state<QiblaScreenState>(find.byType(QiblaScreen));
      expect(st.mode, CompassMode.live);
      expect(st.heading, closeTo(0, 1e-6));
      expect(find.byKey(const Key('qiblaMode-live')), findsOneWidget);
      expect(find.text('Turn right ${qibla.round()}°'), findsOneWidget);
      // After the 3 s timeout the live mode stays.
      await tester.pump(QiblaScreen.timeout);
      expect(st.mode, CompassMode.live);
      await acc.close();
      await mag.close();
    });

    testWidgets('prayer tab links to the live qibla screen', (tester) async {
      await pumpApp(tester, size: tallPhone);
      await goToTab(tester, 2);
      await tester.tap(find.byKey(const Key('openLiveQibla')));
      await tester.pumpAndSettle();
      expect(find.byType(QiblaScreen), findsOneWidget);
    });
  });

  group('Hajj & Umrah', () {
    testWidgets('three tabs with the pending-review notice and the prototype text', (tester) async {
      final app = await pumpApp(tester, size: tallPhone);
      await pushScreen(tester, const HajjScreen());
      expect(find.byKey(const Key('hajjNotice')), findsOneWidget);
      expect(find.textContaining('بانتظار المراجعة الشرعية'), findsOneWidget);
      expect(find.text('الإحرام من الميقات'), findsOneWidget);
      await tester.tap(find.byKey(const Key('hajjTab-ihram')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('hajjNotice')), findsOneWidget);
      expect(find.text('محظورات الإحرام'), findsOneWidget);
      expect(find.text(app.services.content.hajj.talbiya), findsWidgets);
    });

    testWidgets('English UI says the guide is Arabic only', (tester) async {
      await pumpApp(tester, size: tallPhone, locale: 'en');
      await pushScreen(tester, const HajjScreen());
      expect(find.text('This content is available in Arabic only.'), findsOneWidget);
      expect(find.textContaining('Pending religious review'), findsOneWidget);
    });
  });

  group('Home', () {
    testWidgets('live countdown, Hijri + Gregorian dates, city and today\'s times', (tester) async {
      var now = fixedNow;
      await pumpApp(tester, size: tallPhone, clock: () => now);
      expect(find.text('بعد ${ltr('٠:٠٥:٠٠')}'), findsOneWidget);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('بعد ${ltr('٠:٠٤:٥٩')}'), findsOneWidget, reason: 'ticks every second');
      expect(find.text('٢٦ رجب ١٤٤٧ هـ'), findsOneWidget);
      expect(
        find.text(ltr('2026-01-15').replaceAllMapped(RegExp('[0-9]'), (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)])),
        findsOneWidget,
      );
      expect(tester.widget<Text>(find.byKey(const Key('home.city'))).data, 'القاهرة');
      for (final k in ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        expect(find.byKey(Key('home.time-$k')), findsOneWidget);
      }
    });

    testWidgets('section tiles open Adhkar, Tasbih, Qibla, Hajj, Hisn and Bookmarks', (tester) async {
      await pumpApp(tester, size: tallPhone);
      Future<void> tile(String id) async {
        await tester.ensureVisible(find.byKey(Key('home.tile-$id')));
        await tester.tap(find.byKey(Key('home.tile-$id')));
        await tester.pumpAndSettle();
      }

      await tile('adhkar');
      expect(tester.state<HomeShellState>(find.byType(HomeShell)).index, 3);
      await goToTab(tester, 0);
      for (final (id, type) in [
        ('tasbih', TasbihScreen),
        ('qibla', QiblaScreen),
        ('hajj', HajjScreen),
        ('hisn', HisnScreen),
        ('bookmarks', BookmarksScreen),
      ]) {
        await tile(id);
        expect(find.byType(type), findsOneWidget, reason: id);
        await goBack(tester);
      }
    });
  });

  group('More and settings', () {
    testWidgets('More lists the sections and settings', (tester) async {
      await pumpApp(tester, size: tallPhone);
      await goToTab(tester, 4);
      for (final id in ['bookmarks', 'search', 'hisn', 'tasbih', 'qibla', 'hajj', 'settings', 'about']) {
        expect(find.byKey(Key('more.$id')), findsOneWidget);
      }
      await tester.tap(find.byKey(const Key('more.settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('adhan: permission denied keeps it off and says so', (tester) async {
      final n = FakeNotifications(grant: false);
      final app = await pumpApp(tester, size: tallPhone, locale: 'en', notifications: n);
      await openSettings(tester);
      await tester.ensureVisible(find.byKey(const Key('adhanSwitch')));
      await tester.tap(find.byKey(const Key('adhanSwitch')));
      await tester.pumpAndSettle();
      expect(n.permissionRequests, 1);
      expect(app.services.settings.adhanEnabled, isFalse);
      expect(find.text('Notifications are not allowed. Turn them on in the system settings.'), findsOneWidget);
      expect(n.scheduled, isEmpty);
    });

    testWidgets('adhan: granted → five prayers scheduled; a per-prayer switch removes one', (tester) async {
      final n = FakeNotifications();
      final app = await pumpApp(tester, size: tallPhone, locale: 'en', notifications: n);
      await openSettings(tester);
      await tester.ensureVisible(find.byKey(const Key('adhanSwitch')));
      await tester.tap(find.byKey(const Key('adhanSwitch')));
      await tester.pumpAndSettle();
      expect(app.services.settings.adhanEnabled, isTrue);
      expect(n.scheduled, hasLength(4 + 6 * 5), reason: '7 days from Dhuhr today');
      expect(n.scheduled.first.title, 'Time for Dhuhr');
      await tester.ensureVisible(find.byKey(const Key('adhanSwitch-fajr')));
      await tester.tap(find.byKey(const Key('adhanSwitch-fajr')));
      await tester.pumpAndSettle();
      expect(app.prefs.getBool('adhan.fajr'), isFalse);
      expect(n.scheduled, hasLength(4 + 6 * 4));
      expect(n.scheduled.any((e) => e.title == 'Time for Fajr'), isFalse);
    });
  });
}

Future<void> pushRoute(WidgetTester tester, Widget screen) =>
    tester.state<NavigatorState>(find.byType(Navigator).first).push(MaterialPageRoute<void>(builder: (_) => screen));
