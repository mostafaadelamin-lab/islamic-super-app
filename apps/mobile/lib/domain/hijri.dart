import 'package:hijri/hijri_calendar.dart';

/// Umm al-Qura Hijri date (via the `hijri` package) for a local calendar date.
class HijriDate {
  const HijriDate(this.day, this.month, this.year, this.monthName);
  final int day;
  final int month;
  final int year;
  final String monthName;
}

/// Largest manual shift (days) the user can apply to the Umm al-Qura date.
const hijriOffsetMax = 2;

/// The user's manual shift in days (Settings), kept here so every screen that
/// shows a Hijri date uses it. SettingsController keeps it in sync.
int hijriOffsetDays = 0;

int clampHijriOffset(int v) => v.clamp(-hijriOffsetMax, hijriOffsetMax);

/// Umm al-Qura date of [localDate], shifted by [offsetDays] (default: the
/// user's setting) to match the locally announced date (moon sighting).
HijriDate hijriFor(DateTime localDate, {required bool arabic, int? offsetDays}) {
  HijriCalendar.setLocal(arabic ? 'ar' : 'en');
  final shift = clampHijriOffset(offsetDays ?? hijriOffsetDays);
  final h = HijriCalendar.fromDate(DateTime(localDate.year, localDate.month, localDate.day + shift));
  return HijriDate(h.hDay, h.hMonth, h.hYear, h.getLongMonthName());
}
