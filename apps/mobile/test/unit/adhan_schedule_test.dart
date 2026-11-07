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
      // Turning it off cancels everything.
      await settings.setAdhanEnabled(false);
      await sch.sync();
      expect(fake.cancels, 2);
      expect(fake.scheduled, isEmpty);
    });
  });
}
