import 'dart:convert';

import 'package:http/http.dart' as http;

/// A place name for the home screen: the country and the exact area
/// (district, neighbourhood or compound) the phone is in.
class PlaceName {
  const PlaceName({required this.country, required this.area});
  final String? country;
  final String? area;

  Map<String, dynamic> toJson() => {'country': country, 'area': area, 'v': PlaceNames.version};
  static PlaceName? fromJson(Object? j) =>
      j is Map ? PlaceName(country: j['country'] as String?, area: j['area'] as String?) : null;

  /// "مصر - مدينتي" (or just one part when the other is unknown).
  String label() => [?country, ?area].where((s) => s.isNotEmpty).join(' - ');
}

/// Turns coordinates into a place name with OpenStreetMap's reverse geocoder
/// (Nominatim: free, no key), asked at two zoom levels: district (14) and
/// street (16). If Nominatim cannot be reached, BigDataCloud's free client
/// geocoder is tried.
class PlaceNames {
  PlaceNames(this._http);
  final http.Client _http;

  /// Version of the naming rules; names saved by older rules are looked up again.
  static const version = 2;

  /// Named districts, compounds and towns ("مدينتي", "مدينة نصر").
  static const _district = ['town', 'suburb', 'quarter', 'city_district'];

  /// Small places: used only when the street-level answer agrees, because at
  /// district zoom Nominatim can return a nearby village instead of the city.
  static const _small = ['village', 'hamlet', 'neighbourhood', 'residential'];

  /// What the street-level answer offers, most specific first.
  static const _street = ['suburb', 'town', 'quarter', 'city_district', 'village', 'hamlet', 'city', 'municipality', 'county', 'state'];
  static const _broad = ['city', 'municipality', 'county', 'state'];

  static String? _get(Map<dynamic, dynamic> a, String k) {
    final v = a[k];
    return v is String && v.trim().isNotEmpty ? v.trim() : null;
  }

  static Map<dynamic, dynamic>? _address(Object? json) => json is Map && json['address'] is Map ? json['address'] as Map<dynamic, dynamic> : null;

  /// [district]: Nominatim at zoom 14; [street]: at zoom 16 (either may be null).
  static PlaceName? parse(Object? district, [Object? street]) {
    final d = _address(district);
    final s = _address(street);
    if (d == null && s == null) return null;
    String? area;
    if (d != null) {
      for (final k in _district) {
        area ??= _get(d, k);
      }
      if (area == null) {
        for (final k in _small) {
          final v = _get(d, k);
          if (v == null) continue;
          if (s == null || s.values.contains(v)) area = v;
          break;
        }
      }
    }
    if (area == null && s != null) {
      for (final k in _street) {
        area ??= _get(s, k);
      }
    }
    if (area == null && d != null) {
      for (final k in _broad) {
        area ??= _get(d, k);
      }
    }
    final country = (d == null ? null : _get(d, 'country')) ?? (s == null ? null : _get(s, 'country'));
    return PlaceName(country: country, area: area);
  }

  /// BigDataCloud's reverse-geocode-client answer.
  static PlaceName? parseBigDataCloud(Object? json) {
    if (json is! Map) return null;
    String? s(String k) => json[k] is String && (json[k] as String).trim().isNotEmpty ? (json[k] as String).trim() : null;
    final area = s('locality') ?? s('city') ?? s('principalSubdivision');
    final country = s('countryName');
    if (area == null && country == null) return null;
    return PlaceName(country: country, area: area);
  }

  Future<Object?> _get2(Uri u) async {
    final res = await _http
        .get(u, headers: const {'User-Agent': 'Rattil-Quran-app/1.0 (place name for prayer times)'})
        .timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return null;
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  Uri _nominatim(double lat, double lng, int zoom, bool arabic) => Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'lat': lat.toStringAsFixed(5),
    'lon': lng.toStringAsFixed(5),
    'format': 'jsonv2',
    'zoom': '$zoom',
    'accept-language': arabic ? 'ar' : 'en',
  });

  Future<PlaceName?> lookup(double lat, double lng, {required bool arabic}) async {
    Object? district;
    Object? street;
    try {
      district = await _get2(_nominatim(lat, lng, 14, arabic));
    } catch (_) {}
    try {
      street = await _get2(_nominatim(lat, lng, 16, arabic));
    } catch (_) {}
    final p = parse(district, street);
    if (p != null && p.area != null) return p;
    try {
      final b = parseBigDataCloud(
        await _get2(Uri.https('api.bigdatacloud.net', '/data/reverse-geocode-client', {
          'latitude': lat.toStringAsFixed(5),
          'longitude': lng.toStringAsFixed(5),
          'localityLanguage': arabic ? 'ar' : 'en',
        })),
      );
      if (b != null) return b;
    } catch (_) {}
    return p;
  }
}
