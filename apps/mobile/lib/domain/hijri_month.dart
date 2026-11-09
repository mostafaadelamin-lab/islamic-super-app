import 'package:hijri/hijri_calendar.dart';

import 'hijri.dart';

/// A Hijri (Umm al-Qura) month: its year, number and Gregorian days.
class HijriMonth {
  const HijriMonth(this.year, this.month, this.days);
  final int year;
  final int month;

  /// Gregorian dates (UTC-flagged, y/m/d only) of days 1..N of the month.
  final List<DateTime> days;
}

/// The Hijri month [delta] months away from the one containing [localDate], with the user's
/// manual offset (Settings) applied like everywhere else a Hijri date is shown.
HijriMonth hijriMonthAround(DateTime localDate, int delta, {int? offsetDays}) {
  final shift = clampHijriOffset(offsetDays ?? hijriOffsetDays);
  final h = HijriCalendar.fromDate(DateTime(localDate.year, localDate.month, localDate.day + shift));
  final i = h.hYear * 12 + (h.hMonth - 1) + delta;
  final y = i ~/ 12, m = i % 12 + 1;
  final cal = HijriCalendar();
  final n = cal.getDaysInMonth(y, m);
  return HijriMonth(y, m, [
    for (var d = 1; d <= n; d++)
      () {
        final g = cal.hijriToGregorian(y, m, d);
        return DateTime.utc(g.year, g.month, g.day - shift);
      }(),
  ]);
}

/// Name of Hijri month [m] (1-12).
String hijriMonthName(int m, {required bool arabic}) {
  HijriCalendar.setLocal(arabic ? 'ar' : 'en');
  final c = HijriCalendar()
    ..hMonth = m
    ..hYear = 1448
    ..hDay = 1;
  return c.getLongMonthName();
}
