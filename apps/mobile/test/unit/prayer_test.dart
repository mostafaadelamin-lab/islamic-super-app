import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/prayer.dart';
import 'package:rattil/domain/prayer_schedule.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../helpers.dart';

DateTime parseUtc(String s) => DateTime.parse(s.endsWith('Z') ? '${s.substring(0, s.length - 1)}:00Z' : s);

int minutesOfDay(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + int.parse(p[1]);
}

void main() {
  tzdata.initializeTimeZones();
  final config = PrayerConfig.fromJson(readAppJson('assets/schemas/methods.json'));
  final calc = PrayerCalculator(config);
  final vectors = readRepoJson('tests/vectors/prayer-times.json');
  final tolerance = (vectors['toleranceMinutes'] as num).toInt();
  final pyRef = readAppJson('test/fixtures/prayer_python_reference.json');

  PrayerDay run(Map<String, dynamic> c) {
    final d = DateTime.parse(c['date'] as String);
    return calc.times(
      year: d.year,
      month: d.month,
      day: d.day,
      lat: (c['lat'] as num).toDouble(),
      lng: (c['lng'] as num).toDouble(),
      method: c['method'] as String,
      asr: c['asr'] as String,
      adjustments: {
        for (final e in ((c['adjustments'] as Map<String, dynamic>?) ?? {}).entries) e.key: (e.value as num).toInt(),
      },
    );
  }

  test('bundled methods.json is identical to the shared schema', () {
    expect(
      File('assets/schemas/methods.json').readAsStringSync(),
      File('$repoRoot/packages/shared-schemas/prayer/methods.json').readAsStringSync(),
    );
  });

  test('there are 38 adhan-js vectors', () {
    expect((vectors['cases'] as List).length, 38);
  });

  group('adhan-js vectors (tolerance $tolerance min)', () {
    for (final raw in vectors['cases'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test(c['id'] as String, () {
        final r = run(c);
        final loc = tz.getLocation(c['tz'] as String);
        for (final k in prayerKeys) {
          final expectedUtc = parseUtc((c['utc'] as Map<String, dynamic>)[k] as String);
          final diff = r.utc[k]!.difference(expectedUtc).inMinutes.abs();
          expect(diff, lessThanOrEqualTo(tolerance), reason: '$k utc ${r.utc[k]} vs $expectedUtc');
          final local = tz.TZDateTime.from(r.utc[k]!, loc);
          final got = local.hour * 60 + local.minute;
          final want = minutesOfDay((c['local'] as Map<String, dynamic>)[k] as String);
          var d = (got - want).abs();
          if (d > 720) d = 1440 - d;
          expect(d, lessThanOrEqualTo(tolerance), reason: '$k local');
        }
      });
    }
  });

  group('exact match with the Python reference (services/api)', () {
    for (final raw in pyRef['cases'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      test(c['id'] as String, () {
        final r = run(c);
        final loc = tz.getLocation(c['tz'] as String);
        for (final k in prayerKeys) {
          expect(r.utc[k], parseUtc((c['utc'] as Map<String, dynamic>)[k] as String), reason: k);
          final l = tz.TZDateTime.from(r.utc[k]!, loc);
          final hhmm = '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
          expect(hhmm, (c['local'] as Map<String, dynamic>)[k], reason: '$k local');
        }
        expect(r.highLatitudeAdjusted, List<String>.from(c['highLatitudeAdjusted'] as List));
      });
    }
  });

  group('qibla', () {
    final tol = (vectors['qiblaToleranceDegrees'] as num).toDouble();
    for (final raw in vectors['qibla'] as List<dynamic>) {
      final q = raw as Map<String, dynamic>;
      test('${q['city']} within $tol°', () {
        final b = calc.qiblaBearing((q['lat'] as num).toDouble(), (q['lng'] as num).toDouble());
        expect((b - (q['bearing'] as num)).abs(), lessThanOrEqualTo(tol));
      });
    }
    test('matches the Python reference to 1e-9°', () {
      for (final raw in pyRef['qibla'] as List<dynamic>) {
        final q = raw as Map<String, dynamic>;
        expect(
          calc.qiblaBearing((q['lat'] as num).toDouble(), (q['lng'] as num).toDouble()),
          closeTo((q['bearing'] as num).toDouble(), 1e-9),
        );
      }
    });
    test('bearing is always in [0, 360)', () {
      for (var lat = -80; lat <= 80; lat += 20) {
        for (var lng = -180; lng <= 180; lng += 30) {
          final b = calc.qiblaBearing(lat.toDouble(), lng.toDouble());
          expect(b, inInclusiveRange(0, 360));
          expect(b, lessThan(360));
        }
      }
    });
  });

  group('DST transitions', () {
    // Pairs of consecutive days across a DST change: local clock times jump
    // by an hour while the UTC instants move by at most a few minutes.
    final pairs = [
      ['London-2026-03-28-mwl-standard', 'London-2026-03-29-mwl-standard', 60],
      ['NewYork-2026-03-07-isna-standard', 'NewYork-2026-03-08-isna-standard', 60],
      ['Sydney-2026-04-04-mwl-standard', 'Sydney-2026-04-05-mwl-standard', -60],
      ['Cairo-2026-10-29-egypt-standard', 'Cairo-2026-10-30-egypt-standard', -60],
    ];
    final byId = {for (final c in vectors['cases'] as List<dynamic>) (c as Map<String, dynamic>)['id']: c};
    for (final p in pairs) {
      test('${p[0]} -> ${p[1]}', () {
        final a = byId[p[0]] as Map<String, dynamic>;
        final b = byId[p[1]] as Map<String, dynamic>;
        final ra = run(a);
        final rb = run(b);
        final loc = tz.getLocation(a['tz'] as String);
        final offA = tz.TZDateTime.from(ra.utc['dhuhr']!, loc).timeZoneOffset.inMinutes;
        final offB = tz.TZDateTime.from(rb.utc['dhuhr']!, loc).timeZoneOffset.inMinutes;
        expect(offB - offA, p[2], reason: 'UTC offset change');
        final utcShift = rb.utc['dhuhr']!.difference(ra.utc['dhuhr']!).inMinutes - 1440;
        expect(utcShift.abs(), lessThanOrEqualTo(2));
        final la = tz.TZDateTime.from(ra.utc['dhuhr']!, loc);
        final lb = tz.TZDateTime.from(rb.utc['dhuhr']!, loc);
        final localShift = (lb.hour * 60 + lb.minute) - (la.hour * 60 + la.minute);
        expect((localShift - (p[2] as int)).abs(), lessThanOrEqualTo(2));
      });
    }

    test('local date is taken in the city time zone (Sydney is a day ahead of UTC)', () {
      final syd = tz.getLocation('Australia/Sydney');
      expect(PrayerSchedule.localDate(syd, DateTime.utc(2026, 4, 4, 20)), DateTime.utc(2026, 4, 5));
      final ny = tz.getLocation('America/New_York');
      expect(PrayerSchedule.localDate(ny, DateTime.utc(2026, 3, 8, 3)), DateTime.utc(2026, 3, 7));
    });
  });

  group('invalid input', () {
    PrayerDay t({
      double lat = 30,
      double lng = 31,
      String method = 'mwl',
      String asr = 'standard',
      int m = 1,
      int d = 1,
    }) => calc.times(year: 2026, month: m, day: d, lat: lat, lng: lng, method: method, asr: asr);

    test('latitude out of range', () {
      expect(() => t(lat: 90), throwsA(isA<InvalidPrayerInput>()));
      expect(() => t(lat: -90), throwsA(isA<InvalidPrayerInput>()));
      expect(() => t(lat: 123), throwsA(isA<InvalidPrayerInput>()));
    });
    test('longitude out of range', () {
      expect(() => t(lng: 180.5), throwsA(isA<InvalidPrayerInput>()));
      expect(() => t(lng: -181), throwsA(isA<InvalidPrayerInput>()));
      expect(t(lng: 180).utc, hasLength(6));
      expect(t(lng: -180).utc, hasLength(6));
    });
    test('NaN coordinates', () {
      expect(() => t(lat: double.nan), throwsA(isA<InvalidPrayerInput>()));
      expect(() => t(lng: double.nan), throwsA(isA<InvalidPrayerInput>()));
    });
    test('unknown method and asr', () {
      expect(() => t(method: 'nope'), throwsA(isA<InvalidPrayerInput>()));
      expect(() => t(asr: 'shafii'), throwsA(isA<InvalidPrayerInput>()));
      expect(() => calc.computeHours(2026, 1, 1, 30, 31, 'mwl', 3), throwsA(isA<InvalidPrayerInput>()));
    });
    test('impossible dates', () {
      expect(() => t(m: 2, d: 30), throwsA(isA<InvalidPrayerInput>()));
      expect(() => t(m: 13), throwsA(isA<InvalidPrayerInput>()));
      expect(() => t(d: 0), throwsA(isA<InvalidPrayerInput>()));
    });
    test('polar night (Tromsø, 21 Dec) is reported, not silently wrong', () {
      expect(
        () => calc.times(year: 2026, month: 12, day: 21, lat: 69.6492, lng: 18.9553, method: 'mwl'),
        throwsA(isA<InvalidPrayerInput>().having((e) => e.message, 'message', contains('polar'))),
      );
    });
    test('unsupported high-latitude rule in config is rejected', () {
      final j = readAppJson('assets/schemas/methods.json')..['highLatitudeRule'] = 'middleOfNight';
      expect(() => PrayerConfig.fromJson(j), throwsA(isA<InvalidPrayerInput>()));
    });
  });

  group('rules', () {
    test('Dhuhr includes the configured offset', () {
      expect(config.dhuhrOffsetMinutes, 1);
      final (h, _) = calc.computeHours(2026, 1, 15, 30.0444, 31.2357, 'egypt', 1);
      final noOffset = PrayerCalculator(
        PrayerConfig(
          dhuhrOffsetMinutes: 0,
          sunAltitude: config.sunAltitude,
          methods: config.methods,
          asrFactors: config.asrFactors,
          kaabaLat: config.kaabaLat,
          kaabaLng: config.kaabaLng,
        ),
      ).computeHours(2026, 1, 15, 30.0444, 31.2357, 'egypt', 1).$1;
      expect((h['dhuhr']! - noOffset['dhuhr']!) * 60, closeTo(1, 1e-9));
    });
    test('ishaMinutes methods put Isha a fixed time after Maghrib', () {
      final r = calc.times(year: 2026, month: 6, day: 21, lat: 21.3891, lng: 39.8579, method: 'makkah');
      expect(r.utc['isha']!.difference(r.utc['maghrib']!).inMinutes, inInclusiveRange(89, 91));
    });
    test('Hanafi Asr is later than standard', () {
      final a = calc.times(year: 2026, month: 11, day: 6, lat: 24.86, lng: 67.0, method: 'karachi');
      final b = calc.times(year: 2026, month: 11, day: 6, lat: 24.86, lng: 67.0, method: 'karachi', asr: 'hanafi');
      expect(b.utc['asr']!.isAfter(a.utc['asr']!), isTrue);
      expect(b.utc['dhuhr'], a.utc['dhuhr']);
    });
    test('twilight-angle rule caps Fajr/Isha at high latitudes', () {
      final r = calc.times(year: 2026, month: 6, day: 21, lat: 59.9139, lng: 10.7522, method: 'mwl');
      expect(r.highLatitudeAdjusted, ['fajr', 'isha']);
      final night = r.utc['sunrise']!.add(const Duration(days: 1)).difference(r.utc['maghrib']!).inMinutes % 1440;
      expect(r.utc['sunrise']!.difference(r.utc['fajr']!).inMinutes, closeTo(18 / 60 * night, 2));
    });
    test('manual adjustments shift each time by exactly that many minutes', () {
      final base = calc.times(year: 2026, month: 3, day: 1, lat: -6.2088, lng: 106.8456);
      final adj = calc.times(
        year: 2026,
        month: 3,
        day: 1,
        lat: -6.2088,
        lng: 106.8456,
        adjustments: {'fajr': -30, 'sunrise': 1, 'dhuhr': 30, 'asr': 0, 'maghrib': -1, 'isha': 7},
      );
      expect(adj.utc['fajr']!.difference(base.utc['fajr']!).inMinutes, -30);
      expect(adj.utc['sunrise']!.difference(base.utc['sunrise']!).inMinutes, 1);
      expect(adj.utc['dhuhr']!.difference(base.utc['dhuhr']!).inMinutes, 30);
      expect(adj.utc['asr'], base.utc['asr']);
      expect(adj.utc['maghrib']!.difference(base.utc['maghrib']!).inMinutes, -1);
      expect(adj.utc['isha']!.difference(base.utc['isha']!).inMinutes, 7);
    });
    test('times are whole minutes and in chronological order', () {
      final r = calc.times(year: 2026, month: 9, day: 10, lat: 48.8566, lng: 2.3522, method: 'france');
      for (final k in prayerKeys) {
        expect(r.utc[k]!.second, 0);
        expect(r.utc[k]!.isUtc, isTrue);
      }
      for (var i = 1; i < prayerKeys.length; i++) {
        expect(r.utc[prayerKeys[i]]!.isAfter(r.utc[prayerKeys[i - 1]]!), isTrue);
      }
    });
    test('roundHalfEven matches Python round()', () {
      expect(roundHalfEven(0.5), 0);
      expect(roundHalfEven(1.5), 2);
      expect(roundHalfEven(2.5), 2);
      expect(roundHalfEven(-0.5), 0);
      expect(roundHalfEven(-1.5), -2);
      expect(roundHalfEven(2.4999), 2);
      expect(roundHalfEven(2.5001), 3);
      expect(roundHalfEven(-2.6), -3);
    });
    test('julian day of J2000.0', () {
      expect(julianDay(2000, 1, 1), 2451544.5);
    });
  });

  group('schedule helpers', () {
    final cairo = tz.getLocation('Africa/Cairo');
    final schedule = PrayerSchedule(calc);
    LocalPrayerDay day(DateTime d) =>
        schedule.forDate(date: d, location: cairo, lat: 30.0444, lng: 31.2357, method: 'egypt', asr: 'standard');

    test('next prayer is the first obligatory prayer after now', () {
      final today = day(DateTime.utc(2026, 1, 15));
      final tomorrow = day(DateTime.utc(2026, 1, 16));
      // 10:00 UTC = 12:00 Cairo, before Dhuhr (12:05).
      final n = PrayerSchedule.next(DateTime.utc(2026, 1, 15, 10), today, tomorrow)!;
      expect(n.key, 'dhuhr');
      expect(today.hhmm('dhuhr'), '12:05');
      expect(n.remaining, n.at.difference(DateTime.utc(2026, 1, 15, 10)));
      // After Isha the next prayer is tomorrow's Fajr; sunrise is never "next".
      final late = PrayerSchedule.next(DateTime.utc(2026, 1, 15, 20), today, tomorrow)!;
      expect(late.key, 'fajr');
      expect(late.at, tomorrow.day.utc['fajr']);
      final early = PrayerSchedule.next(today.day.utc['fajr']!, today, tomorrow)!;
      expect(early.key, 'dhuhr');
      expect(PrayerSchedule.next(DateTime.utc(2026, 1, 16, 23), today, null), isNull);
    });
    test('countdown format', () {
      expect(PrayerSchedule.formatCountdown(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
      expect(PrayerSchedule.formatCountdown(const Duration(seconds: 59)), '0:00:59');
      expect(PrayerSchedule.formatCountdown(const Duration(seconds: -5)), '0:00:00');
    });
    test('adjustments clamp to -30..+30', () {
      expect(clampAdjustment(-31), -30);
      expect(clampAdjustment(31), 30);
      expect(clampAdjustment(5), 5);
    });
  });

  group('Umm al-Qura Ramadan rule', () {
    int gap(int y, int m, int d, [String method = 'makkah']) {
      final t = calc.times(year: y, month: m, day: d, lat: 21.4225, lng: 39.8262, method: method).utc;
      return t['isha']!.difference(t['maghrib']!).inMinutes;
    }

    test('Isha is 120 minutes after Maghrib in Ramadan and 90 otherwise (same as the Python reference)', () {
      // Ramadan 1447 by the Umm al-Qura calendar: 2026-02-18 .. 2026-03-19.
      expect(gap(2026, 2, 17), 90);
      expect(gap(2026, 2, 18), 120);
      expect(gap(2026, 3, 19), 120);
      expect(gap(2026, 3, 20), 90);
      expect(gap(2026, 3, 1, 'qatar'), 90);
    });
  });
}
