import 'dart:convert';

import 'package:http/http.dart' as http;

/// A place name for the home screen: the country and the exact area
/// (district, neighbourhood or compound) the phone is in.
class PlaceName {
  const PlaceName({required this.country, required this.area});
  final String? country;
  final String? area;

  Map<String, dynamic> toJson() => {'country': country, 'area': area};
  static PlaceName? fromJson(Object? j) =>
      j is Map ? PlaceName(country: j['country'] as String?, area: j['area'] as String?) : null;

  /// "مصر - مدينتي" (or just one part when the other is unknown).
  String label() => [?country, ?area].where((s) => s.isNotEmpty).join(' - ');
}

/// Turns coordinates into a place name with OpenStreetMap's reverse geocoder
/// (Nominatim: free, no key; one request per location change).
class PlaceNames {
  PlaceNames(this._http);
  final http.Client _http;

  /// The most specific named area first.
  static const _areaKeys = [
    'residential',
    'neighbourhood',
    'quarter',
    'suburb',
    'city_district',
    'village',
    'town',
    'municipality',
    'city',
    'county',
    'state',
  ];

  static PlaceName? parse(Object? json) {
    if (json is! Map || json['address'] is! Map) return null;
    final a = json['address'] as Map;
    String? area;
    for (final k in _areaKeys) {
      final v = a[k];
      if (v is String && v.trim().isNotEmpty) {
        area = v.trim();
        break;
      }
    }
    final country = a['country'];
    return PlaceName(country: country is String ? country.trim() : null, area: area);
  }

  Future<PlaceName?> lookup(double lat, double lng, {required bool arabic}) async {
    try {
      final res = await _http
          .get(
            Uri.https('nominatim.openstreetmap.org', '/reverse', {
              'lat': lat.toStringAsFixed(5),
              'lon': lng.toStringAsFixed(5),
              'format': 'jsonv2',
              'zoom': '16',
              'accept-language': arabic ? 'ar' : 'en',
            }),
            headers: const {'User-Agent': 'Rattil-Quran-app/1.0 (place name for prayer times)'},
          )
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      return parse(jsonDecode(utf8.decode(res.bodyBytes)));
    } catch (_) {
      return null;
    }
  }
}
