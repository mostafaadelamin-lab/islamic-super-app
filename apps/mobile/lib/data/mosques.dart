import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/mosques.dart';

/// Result of a nearby-mosques search; [offline] when it is the last saved list.
class MosqueResult {
  const MosqueResult(this.mosques, {this.offline = false});
  final List<Mosque> mosques;
  final bool offline;
}

/// Asks the public Overpass servers in turn; keeps the last answer so the list
/// still shows without internet.
class MosqueFinder {
  MosqueFinder(this._http, this._prefs);
  final http.Client _http;
  final SharedPreferences _prefs;
  static const _cacheKey = 'mosques.cache';

  static String _key(double lat, double lng, int radius, bool arabic) =>
      '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)},$radius,${arabic ? 'ar' : 'en'}';

  /// Throws when no server answers and nothing is saved for this place.
  Future<MosqueResult> find(double lat, double lng, int radius, {required bool arabic}) async {
    final key = _key(lat, lng, radius, arabic);
    Object? last;
    for (final url in overpassEndpoints) {
      try {
        final res = await _http
            .post(
              Uri.parse(url),
              headers: const {
                'Content-Type': 'application/x-www-form-urlencoded',
                // Overpass asks clients to identify themselves.
                'User-Agent': 'Rattil-Quran-app/1.0 (nearby mosques)',
              },
              body: 'data=${Uri.encodeQueryComponent(overpassQuery(lat, lng, radius))}',
            )
            .timeout(const Duration(seconds: 30));
        if (res.statusCode != 200) throw http.ClientException('HTTP ${res.statusCode}');
        final list = parseOverpass(jsonDecode(utf8.decode(res.bodyBytes)), lat, lng, arabic: arabic);
        await _prefs.setString(
          _cacheKey,
          jsonEncode({
            'key': key,
            'items': [for (final m in list) m.toJson()],
          }),
        );
        return MosqueResult(list);
      } catch (e) {
        last = e;
      }
    }
    final raw = _prefs.getString(_cacheKey);
    if (raw != null) {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      if (j['key'] == key) {
        return MosqueResult([
          for (final m in j['items'] as List<dynamic>) Mosque.fromJson(m as Map<String, dynamic>),
        ], offline: true);
      }
    }
    throw last ?? Exception('Overpass unavailable');
  }
}
