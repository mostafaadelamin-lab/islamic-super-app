import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/location.dart';
import 'package:rattil/domain/mosques.dart';
import 'package:rattil/ui/mosques_screen.dart';

import '../helpers.dart';

const _sample = {
  'elements': [
    {
      'type': 'way',
      'id': 2,
      'center': {'lat': 30.05, 'lon': 31.2357},
      'tags': {'amenity': 'place_of_worship', 'name': 'مسجد ب', 'name:en': 'Mosque B'},
    },
    {
      'type': 'node',
      'id': 1,
      'lat': 30.045,
      'lon': 31.2357,
      'tags': {'amenity': 'place_of_worship', 'name': 'مسجد أ'},
    },
    {
      'type': 'node',
      'id': 3,
      'lat': 30.06,
      'lon': 31.24,
      'tags': {'amenity': 'place_of_worship'},
    },
    // The outline of mosque 1, drawn as a building only: the same mosque.
    {
      'type': 'way',
      'id': 5,
      'center': {'lat': 30.0451, 'lon': 31.2357},
      'tags': {'building': 'mosque'},
    },
    // A mosque mapped only as a building.
    {
      'type': 'way',
      'id': 6,
      'center': {'lat': 30.07, 'lon': 31.2357},
      'tags': {'building': 'mosque', 'name': 'مسجد ج'},
    },
    {
      'type': 'node',
      'id': 1,
      'lat': 30.045,
      'lon': 31.2357,
      'tags': {'name': 'duplicate'},
    },
    {
      'type': 'node',
      'id': 4,
      'tags': {'name': 'no coordinates'},
    },
  ],
};

void main() {
  setUpAll(loadContent);

  group('domain', () {
    test('query asks for Muslim places of worship around the point', () {
      final q = overpassQuery(30.0444, 31.2357, 5000);
      expect(q, contains('["amenity"="place_of_worship"]["religion"="muslim"]'));
      expect(q, contains('nwr["building"="mosque"](around:5000,30.04440,31.23570)'));
      expect(q, contains('(around:5000,30.04440,31.23570)'));
    });
    test('haversine', () {
      expect(distanceM(0, 0, 0, 1), closeTo(111195, 10));
      expect(distanceM(21.4225, 39.8262, 24.4672, 39.6111), inInclusiveRange(330000, 345000));
    });
    test('parse: de-duplicates, drops malformed, sorts, picks the name language', () {
      final ar = parseOverpass(_sample, 30.0444, 31.2357, arabic: true);
      expect(ar.map((m) => m.id), ['node/1', 'way/2', 'node/3', 'way/6']);
      expect(ar.first.name, 'مسجد أ');
      expect(ar[2].name, isNull);
      expect(parseOverpass(_sample, 30.0444, 31.2357, arabic: false)[1].name, 'Mosque B');
      expect(parseOverpass(null, 0, 0, arabic: true), isEmpty);
    });
    test('directions links', () {
      const m = Mosque(id: 'node/1', name: null, lat: 1, lng: 2, distance: 0);
      expect(directionsUri(m, ios: true).toString(), 'https://maps.apple.com/?daddr=1.000000,2.000000');
      expect(directionsUri(m, ios: false).toString(), 'geo:1.000000,2.000000?q=1.000000,2.000000');
    });
  });

  testWidgets('lists mosques around the prayer city, falls back to the second server, radius re-queries', (
    tester,
  ) async {
    final urls = <String>[];
    final bodies = <String>[];
    final client = MockClient((req) async {
      urls.add(req.url.toString());
      bodies.add(Uri.decodeQueryComponent(req.body));
      if (urls.length == 1) return http.Response('busy', 429);
      return http.Response.bytes(utf8.encode(jsonEncode(_sample)), 200);
    });
    await pumpApp(tester, size: tallPhone, locale: 'en');
    await pushScreen(tester, MosquesScreen(client: client));
    await tester.pumpAndSettle();
    expect(urls.first, contains('overpass-api.de'));
    expect(urls[1], contains('kumi.systems'));
    expect(bodies[1], contains('around:5000,30.04440,31.23570')); // no GPS: Cairo, the default city
    expect(find.byKey(const Key('mosquesGeoFallback')), findsOneWidget);
    expect(find.byKey(const Key('mosque-node/1')), findsOneWidget);
    expect(find.text('Mosque B'), findsOneWidget);
    expect(find.text('Mosque (no name on the map)'), findsOneWidget);
    expect(find.text('67 m'), findsOneWidget);
    expect(find.textContaining('© OpenStreetMap contributors'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mosquesRadius-10000')));
    await tester.pumpAndSettle();
    expect(bodies.last, contains('around:10000,'));
  });

  testWidgets('offline: last saved list, else an error with retry', (tester) async {
    var online = true;
    final client = MockClient((req) async {
      if (!online) throw http.ClientException('offline');
      return http.Response.bytes(utf8.encode(jsonEncode(_sample)), 200);
    });
    await pumpApp(tester, size: tallPhone, locale: 'en');
    await pushScreen(tester, MosquesScreen(client: client));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mosque-node/1')), findsOneWidget);
    online = false;
    await tester.tap(find.byKey(const Key('mosquesRadius-2000')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mosquesError')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mosquesRadius-5000')));
    await tester.pumpAndSettle();
    expect(find.textContaining('last saved result'), findsOneWidget);
    expect(find.byKey(const Key('mosque-node/1')), findsOneWidget);
  });

  testWidgets('searches around the GPS position, and again on "update my location"', (tester) async {
    final bodies = <String>[];
    final client = MockClient((req) async {
      bodies.add(Uri.decodeQueryComponent(req.body));
      return http.Response.bytes(utf8.encode(jsonEncode(_sample)), 200);
    });
    await pumpApp(tester, size: tallPhone, locale: 'en', location: const FakeLocation(LocationFound(30.0445, 31.2357)));
    await pushScreen(tester, MosquesScreen(client: client));
    await tester.pumpAndSettle();
    expect(bodies, hasLength(1));
    expect(bodies.single, contains('around:5000,30.04450,31.23570'));
    expect(find.text('Mosques around your current location'), findsOneWidget);
    expect(find.byKey(const Key('mosquesGeoFallback')), findsNothing);
    expect(find.text('56 m'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mosquesLocate')));
    await tester.pumpAndSettle();
    expect(bodies, hasLength(2));
  });
}
