import 'package:timezone/timezone.dart' as tz;

import 'prayer.dart';

/// The five obligatory prayers (sunrise is shown but is not a prayer).
const obligatoryPrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

const minAdjustment = -30;
const maxAdjustment = 30;

int clampAdjustment(int v) => v < minAdjustment ? minAdjustment : (v > maxAdjustment ? maxAdjustment : v);

/// A day of prayer times in a city's IANA time zone.
class LocalPrayerDay {
  LocalPrayerDay({required this.date, required this.location, required this.day});

  /// Local calendar date (time part is midnight, UTC-flagged, for y/m/d only).
  final DateTime date;
  final tz.Location location;
  final PrayerDay day;

  tz.TZDateTime local(String key) => tz.TZDateTime.from(day.utc[key]!, location);

  String hhmm(String key) {
    final t = local(key);
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}

class NextPrayer {
  const NextPrayer(this.key, this.at, this.remaining);
  final String key;
  final DateTime at;
  final Duration remaining;
}

class PrayerSchedule {
  const PrayerSchedule(this.calculator);
  final PrayerCalculator calculator;

  /// The local calendar date in [location] at instant [nowUtc].
  static DateTime localDate(tz.Location location, DateTime nowUtc) {
    final l = tz.TZDateTime.from(nowUtc, location);
    return DateTime.utc(l.year, l.month, l.day);
  }

  LocalPrayerDay forDate({
    required DateTime date,
    required tz.Location location,
    required double lat,
    required double lng,
    required String method,
    required String asr,
    Map<String, int> adjustments = const {},
  }) {
    final d = calculator.times(
      year: date.year,
      month: date.month,
      day: date.day,
      lat: lat,
      lng: lng,
      method: method,
      asr: asr,
      adjustments: adjustments,
    );
    return LocalPrayerDay(date: DateTime.utc(date.year, date.month, date.day), location: location, day: d);
  }

  /// The next obligatory prayer strictly after [nowUtc], looking at [today]
  /// first and then [tomorrow].
  static NextPrayer? next(DateTime nowUtc, LocalPrayerDay today, LocalPrayerDay? tomorrow) {
    for (final d in [today, ?tomorrow]) {
      for (final k in obligatoryPrayers) {
        final at = d.day.utc[k]!;
        if (at.isAfter(nowUtc)) return NextPrayer(k, at, at.difference(nowUtc));
      }
    }
    return null;
  }

  /// "H:MM:SS" for a countdown.
  static String formatCountdown(Duration d) {
    final s = d.inSeconds < 0 ? 0 : d.inSeconds;
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '$h:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }
}
