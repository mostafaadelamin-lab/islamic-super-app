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

  /// [key]'s time in the chosen clock style (24 h "13:05", or 12 h "1:05 PM" / "1:05 م").
  String clock(String key, {bool h12 = false, bool arabic = false}) =>
      formatClock(local(key), h12: h12, arabic: arabic);
}

/// Hour and minute of [t] as "13:05" (24 h) or "1:05 PM" / "1:05 م" (12 h). Digits stay Latin.
String formatClock(DateTime t, {bool h12 = false, bool arabic = false}) {
  final mm = t.minute.toString().padLeft(2, '0');
  if (!h12) return '${t.hour.toString().padLeft(2, '0')}:$mm';
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final pm = t.hour >= 12;
  final suffix = arabic ? (pm ? 'م' : 'ص') : (pm ? 'PM' : 'AM');
  return '$h:$mm $suffix';
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

  /// How long after an adhan the home screen counts up ("… ago") instead of
  /// down to the next prayer.
  static const elapsedWindow = Duration(minutes: 30);

  /// The obligatory prayer whose time passed less than [window] before
  /// [nowUtc] (remaining = time elapsed since it), or null.
  static NextPrayer? recent(DateTime nowUtc, LocalPrayerDay today, {Duration window = elapsedWindow}) {
    for (final k in obligatoryPrayers.reversed) {
      final at = today.day.utc[k]!;
      final ago = nowUtc.difference(at);
      if (!ago.isNegative) return ago < window ? NextPrayer(k, at, ago) : null;
    }
    return null;
  }

  /// Between an obligatory prayer's adhan and its iqama ([iqama]: minutes per prayer): that prayer,
  /// the iqama instant and the time left to it; null outside that wait or when [iqama] is null.
  static NextPrayer? iqamaWait(DateTime nowUtc, LocalPrayerDay today, Map<String, int>? iqama) {
    if (iqama == null) return null;
    for (final k in obligatoryPrayers.reversed) {
      final adhan = today.day.utc[k]!;
      if (nowUtc.isBefore(adhan)) continue;
      final at = adhan.add(Duration(minutes: iqama[k] ?? 0));
      return at.isAfter(nowUtc) ? NextPrayer(k, at, at.difference(nowUtc)) : null;
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
