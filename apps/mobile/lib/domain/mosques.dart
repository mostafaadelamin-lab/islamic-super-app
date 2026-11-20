// Nearby mosques from OpenStreetMap through the Overpass API (owner's choice,
// 2026-11-09: free, no key). Port of apps/web/src/lib/mosques.ts.
// Data © OpenStreetMap contributors (ODbL 1.0): the screen shows that credit.
import 'dart:math' as math;

const overpassEndpoints = [
  'https://overpass-api.de/api/interpreter',
  'https://overpass.private.coffee/api/interpreter',
  'https://maps.mail.ru/osm/tools/overpass/api/interpreter',
  'https://overpass.osm.jp/api/interpreter',
  'https://overpass.kumi.systems/api/interpreter',
];

/// Last resort when every Overpass server fails: OpenStreetMap's own search
/// (Nominatim) for mosques inside a box around the point.
Uri nominatimMosquesUri(double lat, double lng, int radius, {required bool arabic}) {
  final dLat = radius / 111320.0;
  final dLng = radius / (111320.0 * math.cos(lat * math.pi / 180).abs().clamp(0.1, 1.0));
  return Uri.https('nominatim.openstreetmap.org', '/search', {
    'q': arabic ? 'مسجد' : 'mosque',
    'format': 'jsonv2',
    'limit': '50',
    'bounded': '1',
    'viewbox': '${lng - dLng},${lat + dLat},${lng + dLng},${lat - dLat}',
    'accept-language': arabic ? 'ar' : 'en',
  });
}

/// Parses a Nominatim search answer into mosques sorted by distance.
List<Mosque> parseNominatim(Object? json, double lat, double lng) {
  if (json is! List) return const [];
  final out = <Mosque>[];
  final seen = <String>{};
  for (final raw in json) {
    if (raw is! Map) continue;
    final mLat = double.tryParse('${raw['lat']}');
    final mLng = double.tryParse('${raw['lon']}');
    final id = '${raw['osm_type']}/${raw['osm_id']}';
    if (mLat == null || mLng == null || !seen.add(id)) continue;
    final name = _str(raw['name']);
    final worship = raw['category'] == 'amenity' && raw['type'] == 'place_of_worship';
    if (!worship && !(name != null && _mosqueWord.hasMatch(name))) continue;
    if (!isMosqueName(name)) continue;
    out.add(Mosque(id: id, name: name, lat: mLat, lng: mLng, distance: distanceM(lat, lng, mLat, mLng)));
  }
  out.sort((a, b) => a.distance.compareTo(b.distance));
  return out.take(maxMosques).toList();
}

/// Google Maps search for mosques around a point (always available, even when
/// the free map data has gaps).
Uri googleMapsNearbyUri(double lat, double lng, {required bool arabic}) => Uri.parse(
  'https://www.google.com/maps/search/${Uri.encodeComponent(arabic ? 'مسجد' : 'mosque')}/@${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)},15z',
);

/// One mosque on Google Maps (by its name next to its position).
Uri googleMapsMosqueUri(Mosque m) {
  final p = '${m.lat.toStringAsFixed(6)},${m.lng.toStringAsFixed(6)}';
  return Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': m.name == null ? p : '${m.name} $p'});
}

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

/// Muslim places of worship, plus buildings drawn as mosques that nobody
/// tagged as a place of worship (common in Egypt and elsewhere).
String overpassQuery(double lat, double lng, int radius) {
  final a = '(around:$radius,${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)})';
  return '[out:json][timeout:20];(nwr["amenity"="place_of_worship"]["religion"="muslim"]$a;'
      'nwr["building"="mosque"]$a;);out center tags;';
}

/// A building-only element this close to a tagged mosque is the same mosque drawn twice.
const _sameMosqueM = 60.0;

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

/// Words that name a road, square or district, never a mosque (owner 2026-11-20: «طريق طلعت مصطفى»
/// was listed as a mosque).
final _notMosque = RegExp(
  r'^(طريق|شارع|ش\.|محور|ميدان|كوبري|كورنيش|حي|منطقة|مدينة|قرية|عزبة|road|street|st\.|avenue|square|highway)(\s|$)',
  caseSensitive: false,
);

/// Words that say a place is a mosque.
final _mosqueWord = RegExp(r'مسجد|جامع|زاوية|مصلى|mosque|masjid|masjed|jami|musalla', caseSensitive: false);

/// False for names of roads, squares, districts and the like.
bool isMosqueName(String? name) => name == null || !_notMosque.hasMatch(name.trim());
double? _num(Object? v) => v is num && v.isFinite ? v.toDouble() : null;

/// Parses an Overpass JSON answer; ignores malformed elements. Sorted by
/// distance, capped at [maxMosques]. Names follow the app language when OSM has one.
List<Mosque> parseOverpass(Object? json, double lat, double lng, {required bool arabic}) {
  final elements = json is Map ? json['elements'] : null;
  if (elements is! List) return const [];
  final seen = <String>{};
  final out = <Mosque>[];
  final buildingOnly = <Mosque>[];
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
    if (!isMosqueName(name)) continue;
    final m = Mosque(id: key, name: name, lat: mLat, lng: mLng, distance: distanceM(lat, lng, mLat, mLng));
    (tags['amenity'] == 'place_of_worship' ? out : buildingOnly).add(m);
  }
  final tagged = List.of(out);
  for (final b in buildingOnly) {
    if (!tagged.any((m) => distanceM(m.lat, m.lng, b.lat, b.lng) < _sameMosqueM)) out.add(b);
  }
  out.sort((a, b) => a.distance.compareTo(b.distance));
  return out.length > maxMosques ? out.sublist(0, maxMosques) : out;
}

/// Opens the phone's maps app with directions: Apple Maps on iOS, any maps app (geo:) on Android.
Uri directionsUri(Mosque m, {required bool ios}) {
  final p = '${m.lat.toStringAsFixed(6)},${m.lng.toStringAsFixed(6)}';
  return ios ? Uri.parse('https://maps.apple.com/?daddr=$p') : Uri.parse('geo:$p?q=$p');
}
