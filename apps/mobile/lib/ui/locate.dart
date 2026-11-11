import 'dart:async';

import '../app_services.dart';
import '../data/content.dart';
import '../data/location.dart';
import '../data/place_names.dart';
import 'prayer_model.dart';

/// Gets the phone's position, uses it for prayer times, then looks up the
/// area name shown on the home screen.
Future<LocationResult> locateAndSave(AppServices s, {bool keepMethod = false}) async {
  final r = await s.location.current();
  if (r case LocationFound(:final lat, :final lng)) {
    final near = nearestCity(s.content.cities, lat, lng);
    final old = s.settings.gpsLocation;
    final moved = old == null || (old.lat - lat).abs() > 0.002 || (old.lng - lng).abs() > 0.002;
    if (moved || s.settings.cityId != 'gps') {
      await s.settings.setGpsLocation(lat, lng, near.id, near.method, keepMethod: keepMethod);
    }
    unawaited(refreshPlaceName(s));
  }
  return r;
}

/// Fills in the area name of the saved position (both languages) when missing.
Future<void> refreshPlaceName(AppServices s) async {
  final gps = s.settings.gpsLocation;
  if (gps == null) return;
  for (final lang in const ['ar', 'en']) {
    final saved = s.settings.gpsPlace(lang);
    if (saved != null && saved['v'] == PlaceNames.version && saved['area'] != null) continue;
    final p = await s.placeNames.lookup(gps.lat, gps.lng, arabic: lang == 'ar');
    if (p != null) await s.settings.setGpsPlace(lang, p.toJson());
  }
}

/// The home screen's place line: "country - area" from the GPS position, or
/// the chosen city.
String placeLabel(AppServices s, City city, {required bool arabic}) {
  if (city.id == 'gps') {
    final p = PlaceName.fromJson(s.settings.gpsPlace(arabic ? 'ar' : 'en'));
    final label = p?.label();
    if (label != null && label.isNotEmpty) return label;
  }
  return arabic ? '${city.countryAr} - ${city.nameAr}' : city.nameEn;
}
