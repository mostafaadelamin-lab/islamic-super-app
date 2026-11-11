import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/prayer.dart';
import 'package:rattil/domain/text.dart';
import 'package:rattil/data/location.dart';
import 'package:rattil/ui/city_picker_screen.dart';
import 'package:rattil/ui/prayer_calendar_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final pyRef = {
    for (final c in readAppJson('test/fixtures/prayer_python_reference.json')['cases'] as List<dynamic>)
      (c as Map<String, dynamic>)['id'] as String: c,
  };
  Map<String, dynamic> local(String id) => pyRef[id]!['local'] as Map<String, dynamic>;

  String timeText(WidgetTester tester, String k) {
    final texts = tester.widgetList<Text>(find.descendant(of: find.byKey(Key('time-$k')), matching: find.byType(Text)));
    return texts.last.data!;
  }

  Future<TestApp> open(
    WidgetTester tester, {
    String locale = 'en',
    Map<String, Object> prefs = const {},
    DateTime Function()? clock,
    LocationProvider? location,
    bool edit = false,
  }) async {
    final app = await pumpApp(tester, locale: locale, prefs: prefs, clock: clock, size: tallPhone, location: location);
    await goToTab(tester, 2);
    if (edit) {
      await tester.tap(find.byKey(const Key('editPrayerTimes')));
      await tester.pumpAndSettle();
    }
    return app;
  }

  testWidgets("shows today's six times for the default city (Cairo) in its time zone", (tester) async {
    await open(tester);
    expect(find.text('Cairo'), findsOneWidget);
    expect(find.text('Time zone: Africa/Cairo'), findsOneWidget);
    expect(find.text('Date: \u20662026-01-15\u2069'), findsOneWidget);
    final want = local('Cairo-2026-01-15-egypt-standard');
    for (final k in prayerKeys) {
      expect(timeText(tester, k), want[k], reason: k);
    }
    expect(find.text('Next prayer: Dhuhr'), findsOneWidget);
    expect(find.text('in \u20660:05:00\u2069'), findsOneWidget);
    expect(find.byKey(const Key('highLatNote')), findsNothing);
  });

  testWidgets('Arabic UI uses Arabic-Indic digits and RTL', (tester) async {
    await open(tester, locale: 'ar');
    final want = local('Cairo-2026-01-15-egypt-standard');
    expect(timeText(tester, 'fajr'), toArabicIndic(want['fajr'] as String));
    expect(find.text('الصلاة القادمة: الظهر'), findsOneWidget);
    expect(find.text('بعد \u2066٠:٠٥:٠٠\u2069'), findsOneWidget);
    expect(Directionality.of(tester.element(find.byKey(const Key('time-fajr')))), TextDirection.rtl);
  });

  testWidgets('countdown ticks every second', (tester) async {
    var now = DateTime.utc(2026, 1, 15, 10, 0, 0);
    await open(tester, clock: () => now);
    expect(find.text('in \u20660:05:00\u2069'), findsOneWidget);
    now = now.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('in \u20660:03:59\u2069'), findsOneWidget);
  });

  testWidgets('after Isha the next prayer is tomorrow\'s Fajr', (tester) async {
    await open(tester, clock: () => DateTime.utc(2026, 1, 15, 20, 0));
    expect(find.text('Next prayer: Fajr'), findsOneWidget);
  });

  testWidgets('city picker: search and choose London; method follows the city', (tester) async {
    final app = await open(tester, edit: true);
    await tester.tap(find.byKey(const Key('cityTile')));
    await tester.pumpAndSettle();
    expect(find.byType(CityPickerScreen), findsOneWidget);
    expect(tester.widget<ListTile>(find.byKey(const Key('city-c1'))).selected, isTrue);
    await tester.enterText(find.byKey(const Key('citySearch')), 'lond');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('city-c54')), findsOneWidget);
    expect(find.byKey(const Key('city-c1')), findsNothing);
    await tester.tap(find.byKey(const Key('city-c54')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('cityName'))).data, 'London');
    expect(app.prefs.getString('cityId'), 'c54');
    expect(app.prefs.getString('method'), 'mwl');
    // London 2026-01-15 MWL, recomputed with the same calculator.
    final r = app.services.content.calculator.times(year: 2026, month: 1, day: 15, lat: 51.5074, lng: -0.1278);
    String hhmm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    expect(timeText(tester, 'dhuhr'), hhmm(r.utc['dhuhr']!), reason: 'London is UTC+0 in January');
  });

  testWidgets('city picker: Arabic search and no-results', (tester) async {
    await open(tester, locale: 'ar', edit: true);
    await tester.tap(find.byKey(const Key('cityTile')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('citySearch')), 'الرياض');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('city-c28')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('citySearch')), 'zzzz');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);
    await goBack(tester);
    expect(find.text('القاهرة'), findsOneWidget, reason: 'back without choosing keeps the city');
  });

  testWidgets('method selector changes the calculation and persists', (tester) async {
    final app = await open(tester, edit: true);
    final before = timeText(tester, 'fajr');
    await tester.tap(find.byKey(const Key('methodDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Islamic Society of North America').last);
    await tester.pumpAndSettle();
    expect(app.prefs.getString('method'), 'isna');
    expect(timeText(tester, 'fajr'), isNot(before), reason: 'ISNA uses 15° instead of 19.5°');
    final r = app.services.content.calculator.times(
      year: 2026,
      month: 1,
      day: 15,
      lat: 30.0444,
      lng: 31.2357,
      method: 'isna',
    );
    final l = r.utc['fajr']!.add(const Duration(hours: 2));
    expect(timeText(tester, 'fajr'), '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}');
  });

  testWidgets('Asr selector switches to Hanafi and persists', (tester) async {
    final app = await open(tester, edit: true);
    final std = timeText(tester, 'asr');
    await tester.tap(find.byKey(const Key('asrDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hanafi').last);
    await tester.pumpAndSettle();
    expect(app.prefs.getString('asr'), 'hanafi');
    expect(timeText(tester, 'asr').compareTo(std), greaterThan(0));
    expect(timeText(tester, 'dhuhr'), local('Cairo-2026-01-15-egypt-standard')['dhuhr']);
  });

  testWidgets('manual adjustment: +/- buttons, clamp at ±30, reset', (tester) async {
    final app = await open(tester, edit: true);
    await tester.tap(find.byKey(const Key('adjustTile')));
    await tester.pumpAndSettle();
    final want = local('Cairo-2026-01-15-egypt-standard');
    expect(find.text('0 min'), findsNWidgets(6));
    await tester.tap(find.byKey(const Key('adjustPlus-fajr')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('adjustValue-fajr'))).data, '+1 min');
    expect(timeText(tester, 'fajr'), '05:22');
    expect(want['fajr'], '05:21');
    await tester.tap(find.byKey(const Key('adjustMinus-isha')));
    await tester.tap(find.byKey(const Key('adjustMinus-isha')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('adjustValue-isha'))).data, '-2 min');
    expect(app.services.settings.adjustments, {'fajr': 1, 'isha': -2});
    for (var i = 0; i < 35; i++) {
      final b = tester.widget<IconButton>(find.byKey(const Key('adjustPlus-dhuhr')));
      if (b.onPressed == null) break;
      await tester.tap(find.byKey(const Key('adjustPlus-dhuhr')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('adjustValue-dhuhr'))).data, '+30 min');
    expect(tester.widget<IconButton>(find.byKey(const Key('adjustPlus-dhuhr'))).onPressed, isNull);
    expect(timeText(tester, 'dhuhr'), '12:35');
    await tester.tap(find.byKey(const Key('resetAdjust')));
    await tester.pumpAndSettle();
    expect(app.services.settings.adjustments, isEmpty);
    expect(timeText(tester, 'fajr'), want['fajr']);
    expect(find.text('0 min'), findsNWidgets(6));
  });

  testWidgets('adjustment minimum is -30', (tester) async {
    await open(tester, prefs: {'adjustments': '{"asr": -30}'}, edit: true);
    await tester.tap(find.byKey(const Key('adjustTile')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('adjustValue-asr'))).data, '-30 min');
    expect(tester.widget<IconButton>(find.byKey(const Key('adjustMinus-asr'))).onPressed, isNull);
  });

  testWidgets('high-latitude note appears for London at midsummer', (tester) async {
    await open(tester, prefs: {'cityId': 'c54'}, clock: () => DateTime.utc(2026, 6, 21, 9));
    expect(find.text('High-latitude rule applied to: Fajr, Isha'), findsOneWidget);
    final want = local('London-2026-06-21-mwl-standard');
    for (final k in prayerKeys) {
      expect(timeText(tester, k), want[k], reason: k);
    }
  });

  testWidgets('polar night shows an explanation instead of times', (tester) async {
    final c = await loadContent();
    await pumpApp(
      tester,
      locale: 'en',
      content: withPolarCity(c),
      prefs: {'cityId': 'polar'},
      clock: () => DateTime.utc(2026, 12, 21, 12),
      size: tallPhone,
    );
    await goToTab(tester, 2);
    expect(find.byKey(const Key('polarMessage')), findsOneWidget);
    expect(find.byKey(const Key('time-fajr')), findsNothing);
    expect(find.text('Tromsø'), findsOneWidget);
  });

  testWidgets('qibla bearing text and compass semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await open(tester, edit: true);
    expect(find.text('136.1° from true north'), findsOneWidget);
    expect(find.bySemanticsLabel('Compass: qibla is 136.1° clockwise from north'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('DST: New York before/after the March change shows local clock times', (tester) async {
    for (final (day, id) in [(7, 'NewYork-2026-03-07-isna-standard'), (8, 'NewYork-2026-03-08-isna-standard')]) {
      await open(tester, prefs: {'cityId': 'c57'}, clock: () => DateTime.utc(2026, 3, day, 15));
      final want = local(id);
      for (final k in prayerKeys) {
        expect(timeText(tester, k), want[k], reason: '$id $k');
      }
    }
  });

  testWidgets('adhan banner turns alerts on; a bell per prayer switches one off', (tester) async {
    final app = await open(tester);
    expect(find.byKey(const Key('adhanBell-dhuhr')), findsNothing);
    await tester.tap(find.byKey(const Key('adhanBannerEnable')));
    await tester.pumpAndSettle();
    expect(app.services.settings.adhanEnabled, isTrue);
    expect(find.byKey(const Key('adhanBanner')), findsNothing);
    for (final p in ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      expect(find.byKey(Key('adhanBell-$p')), findsOneWidget);
    }
    expect(find.byKey(const Key('adhanBell-sunrise')), findsNothing);
    await tester.tap(find.byKey(const Key('adhanBell-asr')));
    await tester.pumpAndSettle();
    expect(app.prefs.getBool('adhan.asr'), isFalse);
    expect(app.services.settings.adhanPrayers, {'fajr', 'dhuhr', 'maghrib', 'isha'});
    expect(find.byTooltip('Asr alert off'), findsOneWidget);
  });

  testWidgets('day arrows show another day with its Hijri date, then back to today', (tester) async {
    await open(tester);
    expect(find.text('Thursday 15 January 2026'), findsOneWidget);
    expect(find.byKey(const Key('dayHijri')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dayNext')));
    await tester.pumpAndSettle();
    expect(find.text('Friday 16 January 2026'), findsOneWidget);
    expect(find.text('Date: \u20662026-01-16\u2069'), findsOneWidget);
    expect(find.text('Next prayer: Dhuhr'), findsNothing);
    final app = tester.element(find.byKey(const Key('dayLabel')));
    expect(app, isNotNull);
    await tester.tap(find.byKey(const Key('dayToday')));
    await tester.pumpAndSettle();
    expect(find.text('Thursday 15 January 2026'), findsOneWidget);
    await tester.tap(find.byKey(const Key('dayPrev')));
    await tester.pumpAndSettle();
    expect(find.text('Wednesday 14 January 2026'), findsOneWidget);
  });

  testWidgets('12-hour clock shows AM/PM (ص/م in Arabic)', (tester) async {
    final app = await open(tester);
    await app.services.settings.setClock12(true);
    await tester.pumpAndSettle();
    expect(timeText(tester, 'fajr'), endsWith(' AM'));
    expect(timeText(tester, 'maghrib'), endsWith(' PM'));
    expect(timeText(tester, 'dhuhr'), matches(RegExp(r'^12:\d\d PM$')));
  });

  testWidgets('monthly calendar: every day of the month, month arrows', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('openCalendar')));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerCalendarScreen), findsOneWidget);
    expect(find.text('January 2026'), findsOneWidget);
    final table = tester.widget<DataTable>(find.byKey(const Key('calendar.table')));
    expect(table.rows, hasLength(31));
    expect(table.rows[14].selected, isTrue, reason: 'today (15th) highlighted');
    await tester.tap(find.byKey(const Key('calendar.next')));
    await tester.pumpAndSettle();
    expect(find.text('February 2026'), findsOneWidget);
    expect(tester.widget<DataTable>(find.byKey(const Key('calendar.table'))).rows, hasLength(28));
    expect(daysInMonth(2028, 2), 29);
  });

  testWidgets('use my location: GPS position with the nearest city time zone', (tester) async {
    final app = await open(tester, location: const FakeLocation(LocationFound(30.5, 31.2)), edit: true);
    await tester.tap(find.byKey(const Key('useLocation')));
    await tester.pumpAndSettle();
    expect(app.services.settings.cityId, 'gps');
    expect(find.textContaining('My location (near Cairo)'), findsWidgets);
    expect(app.services.settings.gpsLocation?.lat, 30.5);
  });

  testWidgets('use my location: denied shows a message and keeps the city', (tester) async {
    final app = await open(tester, location: const FakeLocation(LocationDenied()), edit: true);
    await tester.tap(find.byKey(const Key('useLocation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('geoError')), findsOneWidget);
    expect(app.services.settings.cityId, isNot('gps'));
  });

  testWidgets('reminder before the adhan and iqama minutes per prayer', (tester) async {
    final app = await open(tester, prefs: {'adhan.enabled': true}, edit: true);
    await tester.scrollUntilVisible(find.byKey(const Key('adhanExtrasTile')), 200);
    await tester.tap(find.byKey(const Key('adhanExtrasTile')));
    await tester.pumpAndSettle();
    await app.services.settings.setAdhanPreMinutes(10);
    await tester.tap(find.byKey(const Key('iqamaSwitch')));
    await tester.pumpAndSettle();
    expect(app.services.settings.iqamaEnabled, isTrue);
    expect(find.text('20 min after the adhan'), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('iqamaPlus-fajr')), 100);
    await tester.tap(find.byKey(const Key('iqamaPlus-fajr')));
    await tester.pumpAndSettle();
    expect(app.services.settings.iqamaMinutes('fajr'), 21);
    expect(app.services.settings.iqamaPlan, {'fajr': 21, 'dhuhr': 15, 'asr': 15, 'maghrib': 10, 'isha': 15});
  });

  testWidgets('calendar: Hijri month mode and sharing the table as an image', (tester) async {
    final sharer = FakeSharer();
    await pumpApp(tester, locale: 'en', size: tallPhone, sharer: sharer);
    await goToTab(tester, 2);
    await tester.tap(find.byKey(const Key('openCalendar')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byKey(const Key('calendar.kind')), matching: find.text('Hijri')));
    await tester.pumpAndSettle();
    final rows = tester.widget<DataTable>(find.byKey(const Key('calendar.table'))).rows;
    expect(rows.length, inInclusiveRange(29, 30));
    expect(rows.where((r) => r.selected), hasLength(1), reason: 'today is in this Hijri month');
    expect(find.textContaining('1447'), findsOneWidget);
    await tester.tap(find.byKey(const Key('calendar.next')));
    await tester.pumpAndSettle();
    expect(tester.widget<DataTable>(find.byKey(const Key('calendar.table'))).rows.where((r) => r.selected), isEmpty);
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('calendar.share')));
      await Future<void>.delayed(const Duration(milliseconds: 500));
    });
    await tester.pump();
    expect(sharer.images.single.fileName, 'prayer-calendar.png');
    expect(sharer.images.single.bytes, greaterThan(1000));
  });

  testWidgets('home shows time elapsed for 30 minutes after an adhan', (tester) async {
    // Cairo Dhuhr on 2026-01-15 is about 10:05 UTC; 10 minutes later.
    final dhuhr = DateTime.utc(2026, 1, 15, 10, 5);
    await pumpApp(tester, locale: 'en', size: tallPhone, clock: () => dhuhr.add(const Duration(minutes: 10)));
    expect(find.textContaining(' ago'), findsOneWidget);
    expect(find.text('Dhuhr prayer'), findsOneWidget);
  });

  testWidgets('sunrise / last third / Friday alerts and a sound per prayer', (tester) async {
    final n = FakeNotifications();
    final app = await pumpApp(tester, locale: 'en', size: tallPhone, notifications: n, prefs: {'adhan.enabled': true});
    final st = app.services.settings;
    await st.setSunriseAlert(true);
    await st.setLastThirdAlert(true);
    await st.setAdhanSoundFor('fajr', 'tone');
    await app.services.adhan.sync(force: true);
    final plan = app.services.adhan.lastPlan;
    expect(plan.where((x) => x.kind == 'sunrise'), isNotEmpty);
    final third = plan.firstWhere((x) => x.kind == 'lastThird');
    expect(third.at.isAfter(DateTime.utc(2026, 1, 15, 22)), isTrue);
    expect(n.scheduled.firstWhere((x) => x.title == 'Time for Fajr').sound, 'tone');
    expect(n.scheduled.firstWhere((x) => x.title == 'Time for Dhuhr').sound, 'adhan');
    expect(st.hasOwnSound('dhuhr'), isFalse);
    await st.setFridayReminder(10 * 60);
    await app.services.reminders.sync();
    expect(n.repeating[2004]?.weekday, DateTime.friday);
    expect(app.services.reminders.activeCount, 1);
  });
}
