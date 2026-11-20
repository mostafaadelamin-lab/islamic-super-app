import 'dart:async';
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
Future<List<Mosque>> googlePlacesMosques(
  http.Client client,
  String key,
  double lat,
  double lng,
  int radius, {
  required bool arabic,
}) async {
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
              'center': {'latitude': coarseCoord(lat), 'longitude': coarseCoord(lng)},
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
    final name = dn is Map && dn['text'] is String && (dn['text'] as String).trim().isNotEmpty
        ? (dn['text'] as String).trim()
        : null;
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
    // Two waves of servers asked at the same time, so a slow server does not
    // keep the user waiting: the first non-empty answer wins.
    Future<List<Mosque>> overpass(String url) async {
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
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}');
      return parseOverpass(jsonDecode(utf8.decode(res.bodyBytes)), lat, lng, arabic: arabic);
    }

    Future<List<Mosque>> nominatim() async {
      final res = await _http
          .get(nominatimMosquesUri(lat, lng, radius, arabic: arabic), headers: const {'User-Agent': _ua})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}');
      return parseNominatim(jsonDecode(utf8.decode(res.bodyBytes)), lat, lng);
    }

    final waves = <List<Future<List<Mosque>> Function()>>[
      [for (final u in overpassEndpoints.take(2)) () => overpass(u)],
      [for (final u in overpassEndpoints.skip(2)) () => overpass(u), nominatim],
    ];
    for (final wave in waves) {
      final r = await _firstNonEmpty(wave);
      if (r.list != null) {
        await _save(key, r.list!);
        return MosqueResult(r.list!);
      }
      last = r.error ?? last;
    }
    final raw = _prefs.getString(_cacheKey);
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['key'] == key) {
        return MosqueResult(
          [for (final m in j['items'] as List<dynamic>) Mosque.fromJson(m as Map<String, dynamic>)],
          offline: true,
          fromGoogle: j['google'] == true,
        );
      }
    }
    throw last ?? Exception('Overpass unavailable');
  }

  /// Runs [jobs] together; completes with the first non-empty list, or with
  /// no list (and the last error) once every job has finished.
  static Future<({List<Mosque>? list, Object? error})> _firstNonEmpty(List<Future<List<Mosque>> Function()> jobs) {
    final done = Completer<({List<Mosque>? list, Object? error})>();
    var left = jobs.length;
    Object? error;
    for (final job in jobs) {
      Future<void> run() async {
        try {
          final list = await job();
          if (list.isNotEmpty && !done.isCompleted) done.complete((list: list, error: null));
        } catch (e) {
          error = e;
        } finally {
          left--;
          if (left == 0 && !done.isCompleted) done.complete((list: null, error: error));
        }
      }

      unawaited(run());
    }
    return done.future;
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
