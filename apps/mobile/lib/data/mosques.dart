import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/mosques.dart';

/// Result of a nearby-mosques search; [offline] when it is the last saved list.
class MosqueResult {
  const MosqueResult(this.mosques, {this.offline = false, this.fromGoogle = false});
  final List<Mosque> mosques;
  final bool offline;

  /// From Google Places (no OpenStreetMap credit needed).
  final bool fromGoogle;
}

/// Google Places API key, passed at build time:
/// `flutter build apk --dart-define=GOOGLE_PLACES_KEY=...`. Empty = OpenStreetMap only.
const googlePlacesKey = String.fromEnvironment('GOOGLE_PLACES_KEY');

/// Google Places "Nearby Search (New)": up to 20 mosques, nearest first.
Future<List<Mosque>> googlePlacesMosques(http.Client client, String key, double lat, double lng, int radius, {required bool arabic}) async {
  final res = await client
      .post(
        Uri.https('places.googleapis.com', '/v1/places:searchNearby'),
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': key,
          'X-Goog-FieldMask': 'places.id,places.displayName,places.location',
        },
        body: jsonEncode({
          'includedTypes': ['mosque'],
          'maxResultCount': 20,
          'rankPreference': 'DISTANCE',
          'languageCode': arabic ? 'ar' : 'en',
          'locationRestriction': {
            'circle': {
              'center': {'latitude': lat, 'longitude': lng},
              'radius': radius.toDouble(),
            },
          },
        }),
      )
      .timeout(const Duration(seconds: 20));
  if (res.statusCode != 200) throw http.ClientException('Places HTTP ${res.statusCode}');
  return parseGooglePlaces(jsonDecode(utf8.decode(res.bodyBytes)), lat, lng);
}

List<Mosque> parseGooglePlaces(Object? json, double lat, double lng) {
  if (json is! Map || json['places'] is! List) return const [];
  final out = <Mosque>[];
  for (final p in json['places'] as List) {
    if (p is! Map || p['location'] is! Map) continue;
    final loc = p['location'] as Map;
    final mLat = (loc['latitude'] as num?)?.toDouble();
    final mLng = (loc['longitude'] as num?)?.toDouble();
    if (mLat == null || mLng == null) continue;
    final dn = p['displayName'];
    final name = dn is Map && dn['text'] is String && (dn['text'] as String).trim().isNotEmpty ? (dn['text'] as String).trim() : null;
    out.add(Mosque(id: 'g/${p['id']}', name: name, lat: mLat, lng: mLng, distance: distanceM(lat, lng, mLat, mLng)));
  }
  out.sort((a, b) => a.distance.compareTo(b.distance));
  return out;
}

/// Asks the public Overpass servers in turn; keeps the last answer so the list
/// still shows without internet.
class MosqueFinder {
  MosqueFinder(this._http, this._prefs, {this.placesKey = googlePlacesKey});
  final http.Client _http;
  final SharedPreferences _prefs;
  final String placesKey;
  static const _cacheKey = 'mosques.cache';
  static const _ua = 'Rattil-Quran-app/1.0 (nearby mosques)';

  static String _key(double lat, double lng, int radius, bool arabic) =>
      '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)},$radius,${arabic ? 'ar' : 'en'}';

  /// Throws when no server answers and nothing is saved for this place.
  Future<MosqueResult> find(double lat, double lng, int radius, {required bool arabic}) async {
    final key = _key(lat, lng, radius, arabic);
    Object? last;
    if (placesKey.isNotEmpty) {
      try {
        final list = await googlePlacesMosques(_http, placesKey, lat, lng, radius, arabic: arabic);
        await _save(key, list, google: true);
        return MosqueResult(list, fromGoogle: true);
      } catch (e) {
        last = e; // fall back to OpenStreetMap
      }
    }
    for (final url in overpassEndpoints) {
      try {
        final res = await _http
            .post(
              Uri.parse(url),
              headers: const {
                'Content-Type': 'application/x-www-form-urlencoded',
                // Overpass asks clients to identify themselves.
                'User-Agent': _ua,
              },
              body: 'data=${Uri.encodeQueryComponent(overpassQuery(lat, lng, radius))}',
            )
            .timeout(const Duration(seconds: 25));
        if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}');
        final list = parseOverpass(jsonDecode(utf8.decode(res.bodyBytes)), lat, lng, arabic: arabic);
        await _save(key, list);
        if (list.isEmpty) continue; // an empty answer from one server: try the next
        return MosqueResult(list);
      } catch (e) {
        last = e;
      }
    }
    try {
      final res = await _http
          .get(nominatimMosquesUri(lat, lng, radius, arabic: arabic), headers: const {'User-Agent': _ua})
          .timeout(const Duration(seconds: 20));
      if (res.statusCode == 200) {
        final list = parseNominatim(jsonDecode(utf8.decode(res.bodyBytes)), lat, lng);
        if (list.isNotEmpty) return MosqueResult(list);
      }
    } catch (e) {
      last = e;
    }
    final raw = _prefs.getString(_cacheKey);
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['key'] == key) {
        return MosqueResult([
          for (final m in j['items'] as List<dynamic>) Mosque.fromJson(m as Map<String, dynamic>),
        ], offline: true, fromGoogle: j['google'] == true);
      }
    }
    throw last ?? Exception('Overpass unavailable');
  }

  Future<void> _save(String key, List<Mosque> list, {bool google = false}) => _prefs.setString(
    _cacheKey,
    jsonEncode({
      'key': key,
      'google': google,
      'items': [for (final m in list) m.toJson()],
    }),
  );
}
