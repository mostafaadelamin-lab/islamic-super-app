
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  test('the in-app map is Google Maps\' mosque search, zoomed to the radius', () {
    final u = googleMapsMosquesInApp(30.0445, 31.2357, 2000, arabic: true);
    expect(u.host, 'www.google.com');
    expect(u.toString(), contains('/maps/search/'));
    expect(u.toString(), contains('@30.044500,31.235700,15z'));
    expect(u.queryParameters['hl'], 'ar');
    expect(mosqueZoom(10000), 13);
    expect(mosqueMapNavigationAllowed(Uri.parse('https://www.google.com/maps/place/x')), isTrue);
    expect(mosqueMapNavigationAllowed(Uri.parse('intent://maps')), isFalse);
    expect(mosqueMapNavigationAllowed(Uri.parse('https://example.com/')), isFalse);
  });

  group('screen', () {
    final shown = <Uri>[];
    setUp(() => debugMapBuilder = (_, u) {
      shown.add(u);
      return const SizedBox.expand();
    });
    tearDown(() {
      debugMapBuilder = null;
      shown.clear();
    });

    testWidgets('shows Google Maps around the GPS position; radius and "update my location" reload it', (tester) async {
      await pumpApp(tester, size: tallPhone, locale: 'en', location: const FakeLocation(LocationFound(30.0445, 31.2357)));
      await pushScreen(tester, const MosquesScreen());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mosquesMap')), findsOneWidget);
      expect(shown.last.toString(), contains('@30.044500,31.235700,14z'));
      expect(find.text('Mosques around your current location'), findsOneWidget);
      expect(find.textContaining('OpenStreetMap'), findsNothing);
      await tester.tap(find.byKey(const Key('mosquesRadius-2000')));
      await tester.pumpAndSettle();
      expect(shown.last.toString(), contains(',15z'));
      await tester.tap(find.byKey(const Key('mosquesLocate')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mosquesMap')), findsOneWidget);
    });

    testWidgets('without a position it uses the prayer city', (tester) async {
      await pumpApp(tester, size: tallPhone, locale: 'en');
      await pushScreen(tester, const MosquesScreen());
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('mosquesGeoFallback')), findsOneWidget);
      expect(find.byKey(const Key('mosquesMap')), findsOneWidget);
    });
  });
}
