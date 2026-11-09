// Nearby mosques from OpenStreetMap through the Overpass API (owner's choice,
// 2026-11-09: free, no key). Port of apps/web/src/lib/mosques.ts.
// Data © OpenStreetMap contributors (ODbL 1.0): the screen shows that credit.
import 'dart:math' as math;

const overpassEndpoints = ['https://overpass-api.de/api/interpreter', 'https://overpass.kumi.systems/api/interpreter'];
const mosqueRadii = [2000, 5000, 10000];
const defaultMosqueRadius = 5000;
const maxMosques = 60;

class Mosque {
  const Mosque({required this.id, required this.name, required this.lat, required this.lng, required this.distance});

  /// "node/123", "way/456" … (stable OSM id).
  final String id;
  final String? name;
  final double lat;
  final double lng;

  /// Straight-line distance from the search point, metres.
  final double distance;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'lat': lat, 'lng': lng, 'distance': distance};
  factory Mosque.fromJson(Map<String, dynamic> j) => Mosque(
    id: j['id'] as String,
    name: j['name'] as String?,
    lat: (j['lat'] as num).toDouble(),
    lng: (j['lng'] as num).toDouble(),
    distance: (j['distance'] as num).toDouble(),
  );
}

String overpassQuery(double lat, double lng, int radius) =>
    '[out:json][timeout:25];nwr["amenity"="place_of_worship"]["religion"="muslim"]'
    '(around:$radius,${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)});out center tags;';

/// Great-circle distance in metres.
double distanceM(double lat1, double lng1, double lat2, double lng2) {
  const rad = math.pi / 180;
  final dLat = (lat2 - lat1) * rad;
  final dLng = (lng2 - lng1) * rad;
  final a =
      math.pow(math.sin(dLat / 2), 2) + math.cos(lat1 * rad) * math.cos(lat2 * rad) * math.pow(math.sin(dLng / 2), 2);
  return 2 * 6371000 * math.asin(math.min(1, math.sqrt(a)));
}

String? _str(Object? v) => v is String && v.trim().isNotEmpty ? v.trim() : null;
double? _num(Object? v) => v is num && v.isFinite ? v.toDouble() : null;

/// Parses an Overpass JSON answer; ignores malformed elements. Sorted by
/// distance, capped at [maxMosques]. Names follow the app language when OSM has one.
List<Mosque> parseOverpass(Object? json, double lat, double lng, {required bool arabic}) {
  final elements = json is Map ? json['elements'] : null;
  if (elements is! List) return const [];
  final seen = <String>{};
  final out = <Mosque>[];
  for (final raw in elements) {
    if (raw is! Map) continue;
    final type = _str(raw['type']);
    final id = _num(raw['id']);
    final center = raw['center'] is Map ? raw['center'] as Map : const {};
    final mLat = _num(raw['lat']) ?? _num(center['lat']);
    final mLng = _num(raw['lon']) ?? _num(center['lon']);
    if (type == null || id == null || mLat == null || mLng == null) continue;
    final key = '$type/${id.toInt()}';
    if (!seen.add(key)) continue;
    final tags = raw['tags'] is Map ? raw['tags'] as Map : const {};
    final name = arabic
        ? _str(tags['name:ar']) ?? _str(tags['name']) ?? _str(tags['name:en'])
        : _str(tags['name:en']) ?? _str(tags['name']) ?? _str(tags['name:ar']);
    out.add(Mosque(id: key, name: name, lat: mLat, lng: mLng, distance: distanceM(lat, lng, mLat, mLng)));
  }
  out.sort((a, b) => a.distance.compareTo(b.distance));
  return out.length > maxMosques ? out.sublist(0, maxMosques) : out;
}

/// Opens the phone's maps app with directions: Apple Maps on iOS, any maps app (geo:) on Android.
Uri directionsUri(Mosque m, {required bool ios}) {
  final p = '${m.lat.toStringAsFixed(6)},${m.lng.toStringAsFixed(6)}';
  return ios ? Uri.parse('https://maps.apple.com/?daddr=$p') : Uri.parse('geo:$p?q=$p');
}
