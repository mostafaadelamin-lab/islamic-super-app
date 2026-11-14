import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/notifications.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/domain/adhan_schedule.dart';
import 'package:rattil/domain/prayer_schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import '../helpers.dart';

void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  // The default city (Cairo) with its recommended method.
  LocalPrayerDay? cairo(DateTime d) {
    final city = c.cities.first;
    return PrayerSchedule(c.calculator).forDate(
      date: d,
      location: tz.getLocation(city.tz),
      lat: city.lat,
      lng: city.lng,
      method: city.method,
      asr: 'standard',
    );
  }

  final all = obligatoryPrayers.toSet();

  test('only prayers strictly after now; 7 days of five prayers otherwise', () {
    // 12:00 Cairo on 2026-01-15: Fajr (05:2x) has passed, Dhuhr (12:05) has not.
    final plan = planAdhanNotifications(
      nowUtc: fixedNow,
      today: DateTime.utc(2026, 1, 15),
      enabled: all,
      dayFor: cairo,
    );
    expect(plan.first.prayer, 'dhuhr');
    expect(plan.first.date, DateTime.utc(2026, 1, 15));
    expect(plan, hasLength(4 + 6 * 5));
    expect(plan.every((n) => n.at.isAfter(fixedNow)), isTrue);
    for (var i = 1; i < plan.length; i++) {
      expect(plan[i].at.isAfter(plan[i - 1].at), isTrue, reason: 'sorted by time');
    }
    expect(plan.map((n) => n.id).toSet(), hasLength(plan.length), reason: 'unique ids');
    expect(plan.last.date, DateTime.utc(2026, 1, 21));
    // Same times as the prayer screen calculation.
    expect(plan.first.at, cairo(DateTime.utc(2026, 1, 15))!.day.utc['dhuhr']);
  });

  test('per-prayer switches', () {
    final plan = planAdhanNotifications(
      nowUtc: fixedNow,
      today: DateTime.utc(2026, 1, 15),
      enabled: {'fajr', 'maghrib'},
      days: 3,
      dayFor: cairo,
    );
    expect(plan.map((n) => n.prayer).toSet(), {'fajr', 'maghrib'});
    expect(plan, hasLength(1 + 2 + 2), reason: 'today: maghrib only (fajr passed)');
    expect(
      planAdhanNotifications(nowUtc: fixedNow, today: DateTime.utc(2026, 1, 15), enabled: {}, dayFor: cairo),
      isEmpty,
    );
  });

  test('ids are stable for a date and prayer, so re-planning replaces rather than duplicates', () {
    expect(adhanNotificationId(DateTime.utc(2026, 1, 15), 'fajr'), 202601150);
    expect(adhanNotificationId(DateTime.utc(2026, 1, 15), 'isha'), 202601154);
    expect(() => adhanNotificationId(DateTime.utc(2026, 1, 15), 'sunrise'), throwsArgumentError);
  });

  test('days without times (polar) are skipped; the iOS limit caps the list', () {
    final plan = planAdhanNotifications(
      nowUtc: fixedNow,
      today: DateTime.utc(2026, 1, 15),
      enabled: all,
      days: 30,
      dayFor: (d) => d.day.isEven ? null : cairo(d),
    );
    expect(plan.every((n) => n.date.day.isOdd), isTrue);
    final capped = planAdhanNotifications(
      nowUtc: fixedNow,
      today: DateTime.utc(2026, 1, 15),
      enabled: all,
      days: 30,
      dayFor: cairo,
    );
    expect(capped, hasLength(60));
  });

  group('AdhanScheduler', () {
    Future<(AdhanScheduler, FakeNotifications, SettingsController)> make(Map<String, Object> prefs) async {
      SharedPreferences.setMockInitialValues({'locale': 'ar', ...prefs});
      final settings = SettingsController(await SharedPreferences.getInstance(), defaultCityId: c.cities.first.id);
      final fake = FakeNotifications();
      return (AdhanScheduler(content: c, settings: settings, backend: fake, clock: () => fixedNow), fake, settings);
    }

    test('never enabled: the plugin is not touched', () async {
      final (sch, fake, _) = await make({});
      await sch.sync(force: true);
      expect(fake.cancels, 0);
      expect(fake.scheduled, isEmpty);
    });

    test('enabled: schedules the selected city\'s next 7 days with localised text', () async {
      final (sch, fake, settings) = await make({'adhan.enabled': true, 'adhan.asr': false});
      await sch.sync(force: true);
      expect(fake.cancels, 1);
      expect(fake.scheduled, hasLength(sch.lastPlan.length));
      expect(fake.scheduled.length, 3 + 6 * 4, reason: 'Asr switched off; today from Dhuhr');
      final first = fake.scheduled.first;
      expect(first.title, 'حان وقت صلاة الظهر');
      expect(first.body, contains(c.city(settings.cityId)!.nameAr));
      // Unchanged settings: no re-planning.
      await sch.sync();
      expect(fake.cancels, 1);
      // A different sound re-plans with that sound.
      await settings.setAdhanSound('tone');
      await sch.sync();
      expect(fake.cancels, 2);
      expect(fake.scheduled.every((e) => e.sound == 'tone'), isTrue);
      expect(() => settings.setAdhanSound('loud'), throwsArgumentError);
      // "Adhan when the phone is silent" (Android) re-plans so the alarms carry it.
      expect(settings.adhanPlayOnSilent, isFalse);
      await settings.setAdhanPlayOnSilent(true);
      await sch.sync();
      expect(fake.cancels, 3);
      expect(settings.adhanPlayOnSilent, isTrue);
      // Turning it off cancels everything.
      await settings.setAdhanEnabled(false);
      await sch.sync();
      expect(fake.cancels, 4);
      expect(fake.scheduled, isEmpty);
    });
  });

  test('reminder before the adhan and iqama share one budget, with distinct ids', () {
    final plan = planAdhanNotifications(
      nowUtc: fixedNow,
      today: DateTime.utc(2026, 1, 15),
      enabled: all,
      days: 2,
      dayFor: cairo,
      preMinutes: 10,
      iqama: const {'fajr': 20, 'dhuhr': 15, 'asr': 15, 'maghrib': 10, 'isha': 15},
    );
    final dhuhr = cairo(DateTime.utc(2026, 1, 15))!.day.utc['dhuhr']!;
    // 12:00 Cairo: the Dhuhr reminder (11:55) has passed, the Dhuhr adhan and iqama have not.
    expect(plan.first.kind, adhanKind);
    expect(plan.first.prayer, 'dhuhr');
    final iq = plan.firstWhere((n) => n.kind == iqamaKind && n.prayer == 'dhuhr');
    expect(iq.at, dhuhr.add(const Duration(minutes: 15)));
    expect(iq.minutes, 15);
    final pre = plan.firstWhere((n) => n.kind == preAdhanKind && n.prayer == 'asr');
    expect(pre.at, cairo(DateTime.utc(2026, 1, 15))!.day.utc['asr']!.subtract(const Duration(minutes: 10)));
    expect(plan.map((n) => n.id).toSet(), hasLength(plan.length), reason: 'unique ids');
    expect(plan.every((n) => n.id > 0 && n.id < 0x7fffffff), isTrue);
    // 4 prayers left today + 5 tomorrow, three kinds each, minus the passed Dhuhr reminder.
    expect(plan, hasLength(9 * 3 - 1));
    final capped = planAdhanNotifications(
      nowUtc: fixedNow,
      today: DateTime.utc(2026, 1, 15),
      enabled: all,
      dayFor: cairo,
      preMinutes: 10,
      iqama: const {},
      max: 60,
    );
    expect(capped, hasLength(60));
    expect(capped.last.date.isBefore(DateTime.utc(2026, 1, 21)), isTrue, reason: 'fewer days fit the budget');
  });

  test('formatClock 12/24 h', () {
    expect(formatClock(DateTime(2026, 1, 1, 0, 5)), '00:05');
    expect(formatClock(DateTime(2026, 1, 1, 0, 5), h12: true), '12:05 AM');
    expect(formatClock(DateTime(2026, 1, 1, 12, 30), h12: true), '12:30 PM');
    expect(formatClock(DateTime(2026, 1, 1, 13, 5), h12: true, arabic: true), '1:05 م');
    expect(formatClock(DateTime(2026, 1, 1, 9, 0), h12: true, arabic: true), '9:00 ص');
  });
}
