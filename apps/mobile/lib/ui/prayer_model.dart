import 'dart:math' as math;

import 'package:timezone/timezone.dart' as tz;

import '../app_services.dart';
import '../data/content.dart';
import '../data/settings.dart';
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
    final inputs = PrayerInputs.resolve(content, settings);
    final now = s.clock().toUtc();
    final date = PrayerSchedule.localDate(inputs.location, now);
    final schedule = PrayerSchedule(content.calculator);
    final today = inputs.day(schedule, date, settings.adjustments);
    final tomorrow = inputs.day(schedule, date.add(const Duration(days: 1)), settings.adjustments);
    return PrayerView(
      city: inputs.city,
      method: inputs.method,
      asr: inputs.asr,
      location: inputs.location,
      date: date,
      today: today,
      tomorrow: tomorrow,
      next: today == null ? null : PrayerSchedule.next(now, today, tomorrow),
      error: today == null ? 'polar' : null,
      qibla: content.calculator.qiblaBearing(inputs.city.lat, inputs.city.lng),
    );
  }
}

/// The selected city, or "my location" (GPS coordinates with the time zone and
/// default method of the nearest listed city).
City resolveCity(AppContent content, SettingsController settings) {
  final gps = settings.gpsLocation;
  if (settings.cityId == SettingsController.gpsCityId && gps != null) {
    final near = content.city(gps.nearestCityId) ?? content.cities.first;
    return City(
      id: SettingsController.gpsCityId,
      nameAr: 'موقعي (قرب ${near.nameAr})',
      nameEn: 'My location (near ${near.nameEn})',
      countryAr: near.countryAr,
      lat: gps.lat,
      lng: gps.lng,
      tz: near.tz,
      method: near.method,
    );
  }
  return content.city(settings.cityId) ?? content.cities.first;
}

/// The listed city nearest to ([lat], [lng]) (great-circle distance).
City nearestCity(List<City> cities, double lat, double lng) {
  double d(City c) {
    final p1 = lat * math.pi / 180, p2 = c.lat * math.pi / 180;
    final dl = (c.lng - lng) * math.pi / 180;
    return math.acos((math.sin(p1) * math.sin(p2) + math.cos(p1) * math.cos(p2) * math.cos(dl)).clamp(-1.0, 1.0));
  }

  return cities.reduce((a, b) => d(a) <= d(b) ? a : b);
}

/// The selected city, method and Asr rule (falling back to valid values), shared
/// by the prayer screen, the home screen and the adhan scheduler.
class PrayerInputs {
  PrayerInputs(this.city, this.method, this.asr, this.location);

  factory PrayerInputs.resolve(AppContent content, SettingsController settings) {
    final city = resolveCity(content, settings);
    final method = settings.method != null && content.prayerConfig.methods.containsKey(settings.method)
        ? settings.method!
        : city.method;
    final asr = content.prayerConfig.asrFactors.containsKey(settings.asr) ? settings.asr : 'standard';
    return PrayerInputs(city, method, asr, tz.getLocation(city.tz));
  }

  final City city;
  final String method;
  final String asr;
  final tz.Location location;

  /// Times for local date [d], or null where they cannot be calculated.
  LocalPrayerDay? day(PrayerSchedule schedule, DateTime d, Map<String, int> adjustments) {
    try {
      return schedule.forDate(
        date: d,
        location: location,
        lat: city.lat,
        lng: city.lng,
        method: method,
        asr: asr,
        adjustments: adjustments,
      );
    } on InvalidPrayerInput {
      return null;
    }
  }
}
