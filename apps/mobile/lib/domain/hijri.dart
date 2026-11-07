import 'package:hijri/hijri_calendar.dart';

/// Umm al-Qura Hijri date (via the `hijri` package) for a local calendar date.
class HijriDate {
  const HijriDate(this.day, this.month, this.year, this.monthName);
  final int day;
  final int month;
  final int year;
  final String monthName;
}

HijriDate hijriFor(DateTime localDate, {required bool arabic}) {
  HijriCalendar.setLocal(arabic ? 'ar' : 'en');
  final h = HijriCalendar.fromDate(DateTime(localDate.year, localDate.month, localDate.day));
  return HijriDate(h.hDay, h.hMonth, h.hYear, h.getLongMonthName());
}
