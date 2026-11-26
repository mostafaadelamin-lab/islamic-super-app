import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/khatma_screen.dart';
import 'package:rattil/ui/worship_screen.dart';
import 'package:rattil/app.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/qibla.dart';
import 'package:rattil/domain/tasbih.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/hajj_hub_screen.dart';
import 'package:rattil/ui/hajj_screen.dart';
import 'package:rattil/ui/pilgrimage_screen.dart';
import 'package:rattil/ui/hisn_screen.dart';
import 'package:rattil/ui/home_shell.dart';
import 'package:rattil/ui/qibla_screen.dart';
import 'package:rattil/ui/settings_screen.dart';
import 'package:rattil/ui/misbaha.dart';
import 'package:rattil/ui/tasbih_screen.dart';

import 'package:rattil/data/notifications.dart';

import 'package:rattil/ui/zakat_screen.dart';

import 'package:rattil/data/sensors.dart';

import '../helpers.dart';

/// Wraps [s] in the left-to-right isolate used by context.numLtr.
String ltr(String s) => '\u2066$s\u2069';

void main() {
  setUpAll(loadContent);

  group('Adhkar', () {
    testWidgets('one dhikr per page: top bar, counter, moves on when a count is done', (tester) async {
      await pumpApp(tester, size: tallPhone);
      await goToTab(tester, 3);
      await tester.tap(find.byKey(const Key('adhkarHub.morning')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('adhkarTopBar')), findsOneWidget);
      expect(find.byKey(const Key('adhkarNotice')), findsNothing);
      expect(find.text('١ / ٢٦'), findsOneWidget);
      await tester.tap(find.byKey(const Key('dhikrTap-0')));
      await tester.pumpAndSettle();
      expect(find.text('٢ / ٢٦'), findsOneWidget, reason: 'a finished dhikr moves to the next page');
      expect(find.byKey(const Key('dhikrListen')), findsWidgets, reason: 'every dhikr can be listened to');
    });

    testWidgets('list mode: morning by default before Asr, per-item counters', (tester) async {
      final app = await pumpApp(tester, size: tallPhone, prefs: {'adhkar.cards': false});
      await goToTab(tester, 3);
      await tester.tap(find.byKey(const Key('adhkarHub.morning')));
      await tester.pumpAndSettle();
      expect(tester.state<AdhkarScreenState>(find.byType(AdhkarSessionScreen)).session, AdhkarSession.morning);
      // Item 3 (al-Ikhlas) is said three times.
      expect(find.descendant(of: find.byKey(const Key('dhikr-3')), matching: find.text('متبقٍّ ٣')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('dhikrTap-3')));
      for (var i = 0; i < 2; i++) {
        await tester.tap(find.byKey(const Key('dhikrTap-3')));
        await tester.pump();
      }
      expect(find.descendant(of: find.byKey(const Key('dhikr-3')), matching: find.text('متبقٍّ ١')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dhikrTap-3')));
      await tester.pump();
      expect(find.descendant(of: find.byKey(const Key('dhikr-3')), matching: find.text('تمّ')), findsOneWidget);
      await tester.tap(find.byKey(const Key('dhikrTap-3')));
      await tester.pump();
      expect(app.services.adhkar.progress(AdhkarSession.morning).countOf(app.services.content.adhkar.items[3]), 3);
      await tester.scrollUntilVisible(find.byKey(const Key('adhkarProgress')), -300);
      expect(find.text('أُنجز ١ من ٢٦'), findsOneWidget);
      // Saved for today.
      expect(app.prefs.getString('adhkar.progress.morning'), contains('"3":3'));
    });

    testWidgets('list mode: evening after Asr; switching sessions; reset', (tester) async {
      final app = await pumpApp(
        tester,
        size: tallPhone,
        clock: () => DateTime.utc(2026, 1, 15, 17),
        prefs: {'adhkar.cards': false},
      );
      await goToTab(tester, 3);
      await tester.tap(find.byKey(const Key('adhkarHub.evening')));
      await tester.pumpAndSettle();
      final state = tester.state<AdhkarScreenState>(find.byType(AdhkarSessionScreen));
      expect(state.session, AdhkarSession.evening);
      await tester.scrollUntilVisible(find.byKey(const Key('dhikr-7')), 300);
      expect(find.byKey(const Key('dhikr-7')), findsOneWidget, reason: 'أمسينا وأمسى الملك لله');
      expect(find.byKey(const Key('dhikr-6')), findsNothing, reason: 'its morning form is hidden');
      await tester.scrollUntilVisible(find.byKey(const Key('dhikrTap-0')), -300);
      await app.services.adhkar.tap(AdhkarSession.evening, app.services.content.adhkar.items[0]);
      await tester.pump();
      await tester.scrollUntilVisible(find.byKey(const Key('adhkarProgress')), -300);
      expect(find.text('أُنجز ١ من ٢٥'), findsOneWidget);
      await tester.tap(find.byKey(const Key('adhkarReset')));
      await tester.pump();
      expect(find.text('أُنجز ٠ من ٢٥'), findsOneWidget);
      await tester.scrollUntilVisible(find.byKey(const Key('adhkarSession')), -300);
      await tester.tap(find.text('الصباح'));
      await tester.pumpAndSettle();
      expect(state.session, AdhkarSession.morning);
      expect(find.byKey(const Key('dhikr-6')), findsOneWidget);
      expect(app.services.adhkar.progress(AdhkarSession.evening).completedItems, 0);
    });

    testWidgets('Hisn al-Muslim: 134 chapters, filter, chapter with copy', (tester) async {
      await pumpApp(tester, size: tallPhone);
      await goToTab(tester, 3);
      await tester.scrollUntilVisible(find.byKey(const Key('adhkarHub.hisn')), 200);
      await tester.tap(find.byKey(const Key('adhkarHub.hisn')));
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
    Future<void> openSheet(WidgetTester tester, String key) async {
      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();
    }

    Future<void> closeSheet(WidgetTester tester) async {
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    }

    testWidgets('counts, completes a round at 33, changes target, resets; survives a restart', (tester) async {
      final app = await pumpApp(tester, size: tallPhone, locale: 'en');
      await pushScreen(tester, const TasbihScreen());
      await openSheet(tester, 'tasbihLook');
      await tester.tap(find.text('Big button'));
      await tester.pumpAndSettle();
      await closeSheet(tester);
      for (var i = 0; i < 34; i++) {
        await tester.tap(find.byKey(const Key('tasbihButton')));
        await tester.pump();
      }
      expect(app.services.tasbih.state.count, 1);
      expect(tester.widget<Text>(find.byKey(const Key('tasbihCount'))).data, '1');
      expect(find.text('Rounds: 1'), findsOneWidget);
      expect(find.text('Total: 34'), findsOneWidget);
      await openSheet(tester, 'tasbihChangeDhikr');
      await tester.ensureVisible(find.byKey(const Key('tasbihTarget-100')));
      await tester.tap(find.byKey(const Key('tasbihTarget-100')));
      await tester.pump();
      expect(app.services.tasbih.state.target, 100);
      await closeSheet(tester);
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

    testWidgets('beads: style and colour change the beads; virtue from Hisn al-Muslim; own dhikr; history', (
      tester,
    ) async {
      final app = await pumpApp(tester, size: tallPhone, locale: 'en');
      await pushScreen(tester, const TasbihScreen());
      final t = app.services.tasbih;
      expect(t.book.mode, TasbihMode.beads, reason: 'the realistic misbaha is the default');
      expect(find.byType(RealMisbaha), findsOneWidget);
      expect(find.byKey(const Key('tasbihVirtue')), findsOneWidget, reason: 'subhan Allah has its virtue');
      expect(find.textContaining('يُسَبِّحُ مِائَةَ تَسْبِيحَةٍ'), findsOneWidget);
      await tester.tap(find.byKey(const Key('tasbihButton')));
      await tester.pump();
      await openSheet(tester, 'tasbihLook');
      await tester.tap(find.byKey(const Key('tasbihColor-plum')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('tasbihStyle-marble')));
      await tester.pump();
      expect(t.book.color, 'plum');
      expect(t.book.style, BeadStyle.marble);
      await closeSheet(tester);
      final m = tester.widget<RealMisbaha>(find.byType(RealMisbaha));
      expect(m.bead, Color(tasbihColors['plum']!), reason: 'the chosen colour reaches the beads');
      expect(m.style, BeadStyle.marble);
      await openSheet(tester, 'tasbihChangeDhikr');
      await tester.ensureVisible(find.byKey(const Key('tasbihNew')));
      await tester.enterText(find.byKey(const Key('tasbihNew')), 'سبحان الله وبحمده');
      await tester.pump();
      await tester.tap(find.byKey(const Key('tasbihAdd')));
      await tester.pumpAndSettle();
      expect(t.book.phrase, 'c1');
      await closeSheet(tester);
      expect(find.byKey(const Key('tasbihVirtue')), findsNothing, reason: 'no virtue is written for own adhkar');
      expect(t.state.count, 0);
      await tester.tap(find.byKey(const Key('tasbihButton')));
      await tester.pump();
      expect(t.state.count, 1);
      expect(t.book.counters['tasbih']!.count, 1);
      expect(t.book.historyRows().length, 2);
      await openSheet(tester, 'tasbihHistoryOpen');
      await tester.tap(find.byKey(const Key('tasbihClearHistory')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('tasbihClearOk')));
      await tester.pumpAndSettle();
      expect(t.book.history, isEmpty);
      expect(find.byKey(const Key('tasbihHistoryEmpty')), findsOneWidget);
      await closeSheet(tester);
      await openSheet(tester, 'tasbihChangeDhikr');
      await tester.tap(find.byKey(const Key('tasbihRemove-c1')));
      await tester.pumpAndSettle();
      expect(t.book.custom, isEmpty);
      expect(t.book.phrase, 'tasbih');
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
      // Magnetic north + the WMM2025 declination for Cairo (about +4.8°) = true heading.
      expect(st.declination, closeTo(4.8, 0.3));
      expect(st.heading, closeTo(st.declination!, 1e-6));
      expect(find.byKey(const Key('qiblaMode-live')), findsOneWidget);
      expect(find.byKey(const Key('qiblaDeclination')), findsOneWidget);
      expect(find.text('Turn right ${(qibla - st.declination!).round()}°'), findsOneWidget);
      // After the 3 s timeout the live mode stays.
      await tester.pump(QiblaScreen.timeout);
      expect(st.mode, CompassMode.live);
      await acc.close();
      await mag.close();
    });

    testWidgets('system compass heading is preferred and corrected to true north', (tester) async {
      final sys = StreamController<double>.broadcast();
      final app = await pumpApp(
        tester,
        size: tallPhone,
        locale: 'en',
        sensors: FakeSensors(const Stream.empty(), const Stream.empty(), systemHeading: sys.stream),
      );
      unawaited(pushRoute(tester, const QiblaScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      final st = tester.state<QiblaScreenState>(find.byType(QiblaScreen));
      final qibla = app.services.content.calculator.qiblaBearing(30.0444, 31.2357);
      // Magnetic heading that points the phone exactly at the qibla.
      sys.add(qibla - st.declination!);
      await tester.pump();
      expect(st.mode, CompassMode.live);
      expect(st.heading, closeTo(qibla, 1e-6));
      expect(find.text('You are facing the qibla'), findsOneWidget);
      await sys.close();
    });

    testWidgets('an uncalibrated compass asks for the figure-8 and shows its accuracy', (tester) async {
      final sys = StreamController<double>.broadcast();
      final q = StreamController<CompassQuality>.broadcast();
      await pumpApp(
        tester,
        size: tallPhone,
        locale: 'en',
        sensors: FakeSensors(const Stream.empty(), const Stream.empty(), systemHeading: sys.stream, quality: q.stream),
      );
      unawaited(pushRoute(tester, const QiblaScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      sys.add(100);
      q.add(const CompassQuality(calibration: 0));
      q.add(const CompassQuality(accuracyDeg: 30));
      await tester.pump();
      expect(find.byKey(const Key('qiblaCalibrate')), findsOneWidget);
      expect(find.byKey(const Key('qiblaAccuracy')), findsOneWidget);
      expect(find.byKey(const Key('qiblaMapCheck')), findsOneWidget);
      q.add(const CompassQuality(calibration: 3));
      await tester.pump();
      expect(find.byKey(const Key('qiblaCalibrate')), findsNothing);
      await sys.close();
      await q.close();
    });

    testWidgets('system compass error falls back to the raw sensors', (tester) async {
      final acc = StreamController<Vec3>.broadcast();
      final mag = StreamController<Vec3>.broadcast();
      await pumpApp(
        tester,
        size: tallPhone,
        locale: 'en',
        sensors: FakeSensors(acc.stream, mag.stream, systemHeading: Stream.error(Exception('no_sensor'))),
      );
      unawaited(pushRoute(tester, const QiblaScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      acc.add(const Vec3(0, 0, 9.81));
      mag.add(const Vec3(0, 20, -40));
      await tester.pump();
      final st = tester.state<QiblaScreenState>(find.byType(QiblaScreen));
      expect(st.mode, CompassMode.live);
      expect(st.heading, closeTo(st.declination!, 1e-6));
      await acc.close();
      await mag.close();
    });

    testWidgets('prayer tab links to the live qibla screen', (tester) async {
      await pumpApp(tester, size: tallPhone);
      await goToTab(tester, 2);
      await tester.tap(find.byKey(const Key('editPrayerTimes')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.byKey(const Key('openLiveQibla')), 300);
      await tester.tap(find.byKey(const Key('openLiveQibla')));
      await tester.pumpAndSettle();
      expect(find.byType(QiblaScreen), findsOneWidget);
    });
  });

  group('Hajj & Umrah', () {
    testWidgets('the ihram tab: the miqat of each country and the talbiyah, no review notice', (tester) async {
      await pumpApp(tester, size: tallPhone);
      await pushScreen(tester, const HajjScreen());
      expect(find.byKey(const Key('hajjNotice')), findsNothing);
      await tester.tap(find.byKey(const Key('hajjTab-ihram')));
      await tester.pumpAndSettle();
      final list = find
          .descendant(of: find.byKey(const Key('hajjList-ihram')), matching: find.byType(Scrollable))
          .first;
      await tester.scrollUntilVisible(find.byKey(const Key('guideTable')), 300, scrollable: list);
      final table = tester.widget<Table>(find.byKey(const Key('guideTable')));
      expect(table.children.length, 6, reason: 'heading + the five miqat');
      await tester.scrollUntilVisible(
        find.textContaining('لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ').first,
        300,
        scrollable: list,
      );
      expect(find.textContaining('لَبَّيْكَ اللَّهُمَّ لَبَّيْكَ'), findsWidgets);
    });

    testWidgets(
      'own section from home: no crowd card for now, live Haram audio, a screen per kind (owner, 2026-11-14)',
      (tester) async {
        await pumpApp(tester, size: tallPhone);
        await tester.ensureVisible(find.byKey(const Key('home.tile-hajj')));
        await tester.tap(find.byKey(const Key('home.tile-hajj')));
        await tester.pumpAndSettle();
        expect(find.byType(HajjHubScreen), findsOneWidget);
        expect(find.byKey(const Key('hajjHub.crowdOfficial')), findsNothing);
        for (final k in ['hajjHub.radio-makkah', 'hajjHub.radio-madinah']) {
          await tester.scrollUntilVisible(find.byKey(Key(k)), 200, scrollable: find.byType(Scrollable).first);
          expect(find.byKey(Key(k)), findsOneWidget, reason: k);
        }
        await tester.scrollUntilVisible(
          find.byKey(const Key('hajjHub.tamattu')),
          -200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.byKey(const Key('hajjHub.tamattu')));
        await tester.pumpAndSettle();
        expect(find.byType(PilgrimageScreen), findsOneWidget);
        expect(find.byKey(const Key('stepStrip-tamattu')), findsOneWidget);
        expect(find.byKey(const Key('stepCard-tamattu-1')), findsOneWidget);
        await tester.tap(find.byKey(const Key('stepStrip-tamattu-3')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('stepCard-tamattu-3')), findsOneWidget);
        expect(find.byKey(const Key('stepCard-tamattu-1')), findsNothing);
        expect(find.byKey(const Key('hajjScene-sai')), findsOneWidget);
        final top = tester.getRect(find.byKey(const Key('stepStrip-tamattu'))).top;
        await tester.drag(find.byKey(const Key('pilgrimage-tamattu')), const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(const Key('stepStrip-tamattu'))).top, top);
      },
    );

    testWidgets('Umrah: Next moves one step; the tawaf step has the two rak\'ahs\' surahs in full', (tester) async {
      final app = await pumpApp(tester, size: tallPhone);
      await pushScreen(tester, const PilgrimageScreen(kind: PilgrimageKind.umrah));
      expect(find.byKey(const Key('stepCard-umrah-1')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('stepNext-umrah')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.byKey(const Key('stepNext-umrah')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('stepCard-umrah-2')), findsOneWidget);
      expect(find.byKey(const Key('hajjScene-tawaf')), findsOneWidget);
      final c = app.services.content;
      final kafirun = c.renderMap.forDisplay(c.quran.surah(109).ayahs.last);
      await tester.scrollUntilVisible(
        find.byKey(const Key('guideSub-rakah-1')),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      final rich = find.descendant(of: find.byKey(const Key('guideSub-rakah-1')), matching: find.byType(RichText));
      final all = [for (final e in rich.evaluate()) (e.widget as RichText).text.toPlainText()].join();
      expect(all, contains(kafirun));
    });

    testWidgets('Umrah: tawaf and sa\'i steps have the 7-round counter, kept after closing (owner 2026-11-17)', (
      tester,
    ) async {
      final app = await pumpApp(tester, size: tallPhone);
      await pushScreen(tester, const PilgrimageScreen(kind: PilgrimageKind.umrah));
      expect(find.byKey(const Key('rounds-tawaf')), findsNothing); // miqat step: no counter
      Finder list() =>
          find.descendant(of: find.byKey(const Key('pilgrimage-umrah')), matching: find.byType(Scrollable)).first;
      Future<void> next() async {
        final b = find.byKey(const Key('stepNext-umrah'));
        await tester.scrollUntilVisible(b, 600, scrollable: list());
        await tester.tap(b);
        await tester.pumpAndSettle();
      }

      await next();
      final add = find.byKey(const Key('rounds-tawaf-add'));
      await tester.scrollUntilVisible(add, 600, scrollable: list());
      for (var i = 0; i < 3; i++) {
        await tester.tap(add);
        await tester.pumpAndSettle();
      }
      expect(find.text('٣ من ٧'), findsOneWidget);
      await tester.tap(find.byKey(const Key('rounds-tawaf-undo')));
      await tester.pumpAndSettle();
      expect(find.text('٢ من ٧'), findsOneWidget);
      for (var i = 0; i < 6; i++) {
        if (tester.widget<FilledButton>(add).onPressed == null) break;
        await tester.tap(add);
        await tester.pumpAndSettle();
      }
      expect(find.text('اكتمل العدد — تقبّل الله'), findsOneWidget);
      expect(tester.widget<FilledButton>(add).onPressed, isNull);
      expect(app.services.settings.rawJson('hajj.rounds'), contains('"tawaf":7'));

      await next();
      await tester.scrollUntilVisible(find.byKey(const Key('rounds-sai')), 600, scrollable: list());
      expect(find.byKey(const Key('rounds-sai')), findsOneWidget);
      expect(find.byKey(const Key('rounds-tawaf')), findsNothing);
      final saiAdd = find.byKey(const Key('rounds-sai-add'));
      await tester.ensureVisible(saiAdd);
      await tester.pumpAndSettle();
      await tester.tap(saiAdd);
      await tester.pumpAndSettle();
      expect(find.text('١ من ٧'), findsOneWidget);
      await tester.tap(find.byKey(const Key('rounds-sai-reset')));
      await tester.pumpAndSettle();
      expect(find.text('٠ من ٧'), findsOneWidget);
      expect(app.services.settings.rawJson('hajj.rounds'), contains('"tawaf":7'));
    });

    testWidgets('Umrah shows no picture of Mina, Arafah, Muzdalifah or the Jamarat (owner)', (tester) async {
      final app = await pumpApp(tester, size: tallPhone);
      final g = app.services.content.hajjGuide;
      final scenes = app.services.content.hajjScenes.scenes;
      for (final f in [...g.flows['umrah']!.map((s) => s.step), g.umrahIntro]) {
        for (final sc in g.scenesOf(f)) {
          for (final p in scenes[sc]!.places) {
            expect(['mina', 'arafah', 'muzdalifah', 'jamarat'], isNot(contains(p)), reason: '$f -> $sc');
          }
        }
      }
    });

    testWidgets('the Hajj tab: the days of Hajj, pillars, Madinah, the official guide and sources', (tester) async {
      final app = await pumpApp(tester, size: tallPhone);
      await pushScreen(tester, const HajjHubScreen());
      await tester.tap(find.byKey(const Key('hajjHub.hajj')));
      await tester.pumpAndSettle();
      final g = app.services.content.hajjGuide;
      final list = find.descendant(of: find.byKey(const Key('hajjList-hajj')), matching: find.byType(Scrollable)).first;
      for (final (i, _) in g.days.indexed) {
        await tester.scrollUntilVisible(find.byKey(Key('hajjStage-${i + 1}')), 600, scrollable: list);
      }
      for (final k in ['hajjPillars', 'guideStep-${g.madinah}', 'officialHajjGuide', 'guideSources']) {
        await tester.scrollUntilVisible(find.byKey(Key(k)), 600, scrollable: list);
        expect(find.byKey(Key(k)), findsOneWidget, reason: k);
      }
    });

    testWidgets('a kind of Hajj: Arafah has its picture, the official words and the Arafah dua', (tester) async {
      final app = await pumpApp(tester, size: tallPhone);
      await pushScreen(tester, const PilgrimageScreen(kind: PilgrimageKind.tamattu));
      final flow = app.services.content.hajjGuide.flows['tamattu']!;
      final arafah = flow.indexWhere((s) => s.step == 'arafah');
      final next = find.byKey(const Key('stepNext-tamattu'));
      for (var n = 0; n < arafah; n++) {
        // the step's own list (steps quote sunnah.com's longer wording since 1.2.25)
        final list = find.descendant(of: find.byKey(const Key('pilgrimage-tamattu')), matching: find.byType(Scrollable));
        await tester.scrollUntilVisible(next, 600, scrollable: list.first);
        await tester.ensureVisible(next);
        await tester.pumpAndSettle();
        await tester.tap(next);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('hajjScene-arafah')), findsOneWidget);
      expect(find.byKey(const Key('guideOfficial')), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('خَيْرُ الدُّعَاءِ دُعَاءُ يَوْمِ عَرَفَةَ').first,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('خَيْرُ الدُّعَاءِ دُعَاءُ يَوْمِ عَرَفَةَ'), findsWidgets);
    });

    testWidgets('English UI says the guide is Arabic only', (tester) async {
      await pumpApp(tester, size: tallPhone, locale: 'en');
      await pushScreen(tester, const HajjScreen());
      expect(find.text('This content is available in Arabic only.'), findsOneWidget);
      expect(find.textContaining('Pending religious review'), findsNothing);
    });
  });

  group('Home', () {
    testWidgets('live countdown, Hijri + Gregorian dates, city and today\'s times', (tester) async {
      var now = fixedNow;
      await pumpApp(tester, size: tallPhone, clock: () => now);
      expect(find.text('متبقي ${ltr('٠:٠٥:٠٠')}'), findsOneWidget);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('متبقي ${ltr('٠:٠٤:٥٩')}'), findsOneWidget, reason: 'ticks every second');
      expect(find.text('٢٦ رجب ١٤٤٧ هـ'), findsOneWidget);
      expect(find.text('١٥ يناير ٢٠٢٦'), findsOneWidget);
      expect(tester.widget<Text>(find.byKey(const Key('home.city'))).data, 'مصر - القاهرة');
      for (final k in ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']) {
        expect(find.byKey(Key('home.time-$k')), findsOneWidget);
      }
    });

    testWidgets('home tiles open Adhkar, Tasbih, Qibla; More opens Hajj, Hisn and Bookmarks', (tester) async {
      await pumpApp(tester, size: tallPhone);
      Future<void> tile(String id) async {
        await tester.ensureVisible(find.byKey(Key('home.tile-$id')));
        await tester.tap(find.byKey(Key('home.tile-$id')));
        await tester.pumpAndSettle();
      }

      await tile('adhkar');
      expect(tester.state<HomeShellState>(find.byType(HomeShell)).index, 3);
      await goToTab(tester, 0);
      for (final (id, type) in [('tasbih', TasbihScreen), ('qibla', QiblaScreen)]) {
        await tile(id);
        expect(find.byType(type), findsOneWidget, reason: id);
        await goBack(tester);
      }
      for (final (id, type) in [('hajj', HajjHubScreen), ('zakat', ZakatScreen)]) {
        await goToTab(tester, 5);
        await tester.tap(find.byKey(Key('more.$id')));
        await tester.pumpAndSettle();
        expect(find.byType(type), findsOneWidget, reason: id);
        await goBack(tester);
      }
    });
  });

  group('More and settings', () {
    testWidgets('More lists the sections in the owner\'s order and the settings', (tester) async {
      await pumpApp(tester, size: tallPhone);
      await goToTab(tester, 5);
      // Owner (2026-11-24): this order; home items (tasbih, qibla, kids, library, nasheeds) not repeated;
      // help and about live inside the settings.
      const order = [
        'tafsir',
        'hadith',
        'sharawi',
        'mosques',
        'zakat',
        'asma',
        'khatma',
        'tracker',
        'radio',
        'hajj',
        'lessons',
        'settings',
      ];
      final ys = [for (final id in order) tester.getTopLeft(find.byKey(Key('more.$id'))).dy];
      for (var i = 1; i < ys.length; i++) {
        expect(ys[i], greaterThan(ys[i - 1]), reason: order[i]);
      }
      for (final id in ['qibla', 'kids', 'library', 'nasheeds', 'stories', 'about', 'help']) {
        expect(find.byKey(Key('more.$id')), findsNothing, reason: id);
      }
      await tester.tap(find.byKey(const Key('more.settings')));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('More opens the full khatma planner and the worship tracker (owner, 2026-11-13)', (tester) async {
      await pumpApp(tester, size: tallPhone);
      await goToTab(tester, 5);
      await tester.tap(find.byKey(const Key('more.khatma')));
      await tester.pumpAndSettle();
      expect(find.byType(KhatmaScreen), findsOneWidget);
      Navigator.of(tester.element(find.byType(KhatmaScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('more.tracker')));
      await tester.pumpAndSettle();
      expect(find.byType(WorshipScreen), findsOneWidget);
    });

    testWidgets('adhan: permission denied keeps it off and says so', (tester) async {
      final n = FakeNotifications(grant: false);
      final app = await pumpApp(tester, size: tallPhone, locale: 'en', notifications: n);
      await goToTab(tester, 2);
      await tester.scrollUntilVisible(
        find.byKey(const Key('adhanSwitch')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('adhanSwitch')));
      await tester.pumpAndSettle();
      expect(n.permissionRequests, 1);
      expect(app.services.settings.adhanEnabled, isFalse);
      expect(find.text('Notifications are not allowed. Turn them on in the system settings.'), findsOneWidget);
      expect(n.scheduled, isEmpty);
    });

    testWidgets('adhan: granted → five prayers scheduled; a per-prayer switch removes one', (tester) async {
      final n = FakeNotifications();
      final app = await pumpApp(
        tester,
        size: tallPhone,
        locale: 'en',
        notifications: n,
        prefs: {'adhan.pre': 0, 'adhan.iqama': false},
      );
      await goToTab(tester, 2);
      await tester.scrollUntilVisible(
        find.byKey(const Key('adhanSwitch')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('adhanSwitch')));
      await tester.pumpAndSettle();
      expect(app.services.settings.adhanEnabled, isTrue);
      // Android plans a month ahead (iOS: 7 days, at most 60).
      expect(n.scheduled, hasLength(4 + 29 * 5), reason: '30 days from Dhuhr today');
      expect(n.scheduled.every((e) => e.sound == 'adhan'), isTrue, reason: 'adhan recording by default');
      expect(n.scheduled.first.title, 'Time for Dhuhr');
      await tester.ensureVisible(find.byKey(const Key('adhanSwitch-fajr')));
      await tester.tap(find.byKey(const Key('adhanSwitch-fajr')));
      await tester.pumpAndSettle();
      expect(app.prefs.getBool('adhan.fajr'), isFalse);
      expect(n.scheduled, hasLength(4 + 29 * 4));
      expect(n.scheduled.any((e) => e.title == 'Time for Fajr'), isFalse);
    });

    testWidgets('adhan: sound choice re-plans, listen plays the recording, test fires in 10 s', (tester) async {
      final n = FakeNotifications();
      final player = FakeAdhanPlayer();
      final app = await pumpApp(
        tester,
        size: tallPhone,
        locale: 'en',
        notifications: n,
        adhanPlayer: player,
        prefs: {'adhan.enabled': true},
      );
      await goToTab(tester, 2);
      await tester.scrollUntilVisible(
        find.byKey(const Key('adhanSound')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Silent'));
      await tester.pumpAndSettle();
      expect(app.prefs.getString('adhan.sound'), 'silent');
      expect(n.scheduled, isNotEmpty);
      expect(n.scheduled.every((e) => e.sound == 'silent'), isTrue);
      await tester.tap(find.text('Notification tone'));
      await tester.pumpAndSettle();
      expect(n.scheduled.every((e) => e.sound == 'tone'), isTrue);

      await tester.ensureVisible(find.byKey(const Key('adhanPreview')));
      await tester.tap(find.byKey(const Key('adhanPreview')));
      await tester.pumpAndSettle();
      expect(player.plays, 1);
      expect(find.text('Stop'), findsOneWidget);
      player.finish();
      await tester.pumpAndSettle();
      expect(find.text('Listen to the adhan'), findsOneWidget);
      await tester.tap(find.byKey(const Key('adhanPreview')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('adhanPreview')));
      await tester.pumpAndSettle();
      expect(player.stops, 1);

      final before = n.scheduled.length;
      await tester.tap(find.byKey(const Key('adhanTest')));
      await tester.pumpAndSettle();
      expect(n.scheduled, hasLength(before + 1));
      final t = n.scheduled.last;
      expect(t.id, adhanTestNotificationId);
      expect(t.title, 'Adhan alert test');
      expect(t.at, fixedNow.add(const Duration(seconds: 10)));
      expect(t.sound, 'tone');
      expect(find.text('A test alert will arrive in 10 seconds; you can close the app.'), findsOneWidget);
      expect(find.byKey(const Key('adhanCredit')), findsNothing, reason: 'credits live on the About page');

      // The preview plays the default muezzin (Ali Mulla, Makkah Haram).
      expect(player.lastAsset, 'assets/audio/adhan_mulla.m4a');
    });
  });
}

Future<void> pushRoute(WidgetTester tester, Widget screen) =>
    tester.state<NavigatorState>(find.byType(Navigator).first).push(MaterialPageRoute<void>(builder: (_) => screen));
