import 'package:timezone/timezone.dart' as tz;

import '../app_services.dart';
import '../data/content.dart';
import '../domain/prayer.dart';
import '../domain/prayer_schedule.dart';

/// Today's prayer times for the selected city, computed on the device.
class PrayerView {
  PrayerView({
    required this.city,
    required this.method,
    required this.asr,
    required this.location,
    required this.date,
    this.today,
    this.tomorrow,
    this.next,
    this.error,
    required this.qibla,
  });

  final City city;
  final String method;
  final String asr;
  final tz.Location location;
  final DateTime date;
  final LocalPrayerDay? today;
  final LocalPrayerDay? tomorrow;
  final NextPrayer? next;
  final String? error;
  final double qibla;

  static PrayerView compute(AppServices s) {
    final content = s.content;
    final settings = s.settings;
    final city = content.city(settings.cityId) ?? content.cities.first;
    final method = settings.method != null && content.prayerConfig.methods.containsKey(settings.method)
        ? settings.method!
        : city.method;
    final asr = content.prayerConfig.asrFactors.containsKey(settings.asr) ? settings.asr : 'standard';
    final location = tz.getLocation(city.tz);
    final now = s.clock().toUtc();
    final date = PrayerSchedule.localDate(location, now);
    final schedule = PrayerSchedule(content.calculator);
    LocalPrayerDay? day(DateTime d) {
      try {
        return schedule.forDate(
          date: d,
          location: location,
          lat: city.lat,
          lng: city.lng,
          method: method,
          asr: asr,
          adjustments: settings.adjustments,
        );
      } on InvalidPrayerInput {
        return null;
      }
    }

    final today = day(date);
    final tomorrow = day(date.add(const Duration(days: 1)));
    return PrayerView(
      city: city,
      method: method,
      asr: asr,
      location: location,
      date: date,
      today: today,
      tomorrow: tomorrow,
      next: today == null ? null : PrayerSchedule.next(now, today, tomorrow),
      error: today == null ? 'polar' : null,
      qibla: content.calculator.qiblaBearing(city.lat, city.lng),
    );
  }
}
