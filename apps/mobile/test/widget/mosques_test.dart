import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/location.dart';
import 'package:rattil/data/mosques.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
      expect(q, contains('nwr["building"="mosque"](around:5000,30.044,31.236)'));
      expect(q, contains('(around:5000,30.044,31.236)'));
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
    test('roads, squares and districts are never listed as mosques (owner 2026-11-20)', () {
      expect(isMosqueName('طريق طلعت مصطفى'), isFalse);
      expect(isMosqueName('شارع التحرير'), isFalse);
      expect(isMosqueName('Road 90'), isFalse);
      expect(isMosqueName('مسجد الرحمة'), isTrue);
      expect(isMosqueName('سعد بن ابي وقاص'), isTrue);
      expect(isMosqueName(null), isTrue);
      final json = {
        'elements': [
          {
            'type': 'way',
            'id': 9,
            'center': {'lat': 30.05, 'lon': 31.24},
            'tags': {'amenity': 'place_of_worship', 'religion': 'muslim', 'name': 'طريق طلعت مصطفى'},
          },
          {
            'type': 'node',
            'id': 8,
            'lat': 30.05,
            'lon': 31.25,
            'tags': {'amenity': 'place_of_worship', 'religion': 'muslim', 'name': 'مسجد الرحمة'},
          },
        ],
      };
      expect(parseOverpass(json, 30.0444, 31.2357, arabic: true).map((m) => m.name), ['مسجد الرحمة']);
      final nominatim = [
        {
          'osm_type': 'way',
          'osm_id': 1,
          'lat': '30.05',
          'lon': '31.24',
          'category': 'highway',
          'type': 'primary',
          'name': 'طريق طلعت مصطفى',
          'display_name': 'طريق طلعت مصطفى، القاهرة',
        },
        {
          'osm_type': 'way',
          'osm_id': 2,
          'lat': '30.05',
          'lon': '31.24',
          'category': 'highway',
          'type': 'residential',
          'name': '',
          'display_name': 'مسجد ما، القاهرة',
        },
        {
          'osm_type': 'node',
          'osm_id': 3,
          'lat': '30.05',
          'lon': '31.25',
          'category': 'amenity',
          'type': 'place_of_worship',
          'name': 'سعد بن ابي وقاص',
        },
        {
          'osm_type': 'node',
          'osm_id': 4,
          'lat': '30.05',
          'lon': '31.25',
          'category': 'building',
          'type': 'yes',
          'name': 'جامع النور',
        },
      ];
      expect(parseNominatim(nominatim, 30.0444, 31.2357).map((m) => m.name), ['سعد بن ابي وقاص', 'جامع النور']);
      // The search box is a square: corners further than the distance are dropped.
      expect(parseNominatim(nominatim, 30.0444, 31.2357, maxDistance: 900), isEmpty);
      expect(isOtherFaithName('كنيسة مار جرجس'), isTrue);
      expect(isOtherFaithName('St Mark Church'), isTrue);
      expect(isOtherFaithName('مسجد الدير '), isFalse);
      expect(isOtherFaithName('مسجد الرحمة'), isFalse);
    });
    test('directions links', () {
      const m = Mosque(id: 'node/1', name: null, lat: 1, lng: 2, distance: 0);
      expect(directionsUri(m, ios: true).toString(), 'https://maps.apple.com/?daddr=1.000000,2.000000');
      expect(directionsUri(m, ios: false).toString(), 'geo:1.000000,2.000000?q=1.000000,2.000000');
    });
  });

  testWidgets('lists mosques around the prayer city from 1 km, busy server ignored, radius re-queries', (tester) async {
    final urls = <String>[];
    final bodies = <String>[];
    final client = MockClient((req) async {
      if (req.url.host == 'nominatim.openstreetmap.org') return http.Response('[]', 200);
      urls.add(req.url.toString());
      bodies.add(Uri.decodeQueryComponent(req.body));
      if (urls.length == 1) return http.Response('busy', 429);
      return http.Response.bytes(utf8.encode(jsonEncode(_sample)), 200);
    });
    await pumpApp(tester, size: tallPhone, locale: 'en');
    await pushScreen(tester, MosquesScreen(client: client));
    await tester.pumpAndSettle();
    // The first three servers are asked together; the busy one is ignored.
    expect(
      urls.take(3),
      unorderedEquals([contains('overpass-api.de'), contains('mail.ru'), contains('private.coffee')]),
    );
    expect(bodies[1], contains('around:1000,30.044,31.236')); // no GPS: Cairo, the default city
    expect(find.byKey(const Key('mosquesGeoFallback')), findsOneWidget);
    expect(find.byKey(const Key('mosque-node/1')), findsOneWidget);
    expect(find.text('Mosque B'), findsOneWidget);
    expect(find.text('Mosque (no name on the map)'), findsOneWidget);
    expect(find.text('67 m'), findsOneWidget);
    expect(find.textContaining('© OpenStreetMap contributors'), findsOneWidget);
    // Closest distances first, whole numbers: 500 m, 1 km (chosen), 2 km, 5 km.
    for (final t in ['500 m', '1 km', '2 km', '5 km']) {
      expect(find.widgetWithText(ChoiceChip, t), findsOneWidget);
    }
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('mosquesRadius-1000'))).selected, isTrue);
    // The corner button says what it does.
    expect(
      find.descendant(of: find.byKey(const Key('mosquesGoogleMaps')), matching: find.text('Google Maps')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('mosquesRadius-500')));
    await tester.pumpAndSettle();
    expect(bodies.last, contains('around:500,'));
  });

  testWidgets('nothing within 1 km: widens to 2 km by itself and says so', (tester) async {
    final bodies = <String>[];
    final client = MockClient((req) async {
      if (req.url.host == 'nominatim.openstreetmap.org') return http.Response('[]', 200);
      final body = Uri.decodeQueryComponent(req.body);
      bodies.add(body);
      final empty = body.contains('around:1000,');
      return http.Response.bytes(utf8.encode(jsonEncode(empty ? {'elements': []} : _sample)), 200);
    });
    await pumpApp(tester, size: tallPhone, locale: 'en');
    await pushScreen(tester, MosquesScreen(client: client));
    await tester.pumpAndSettle();
    expect(bodies.any((b) => b.contains('around:2000,')), isTrue);
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('mosquesRadius-2000'))).selected, isTrue);
    expect(find.text('No mosque is mapped within 1 km, so these are the nearest within 2 km.'), findsOneWidget);
    expect(find.byKey(const Key('mosque-node/1')), findsOneWidget);
    // Chosen by hand: no widening.
    await tester.tap(find.byKey(const Key('mosquesRadius-1000')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mosquesWidened')), findsNothing);
    expect(find.text('No mosques are mapped within this distance. Try a larger one.'), findsOneWidget);
  });

  testWidgets('slow map servers: the quick list shows within a second, then the full one', (tester) async {
    final nominatim = [
      {
        'osm_type': 'node',
        'osm_id': 1,
        'lat': '30.045',
        'lon': '31.2357',
        'category': 'amenity',
        'type': 'place_of_worship',
        'name': 'مسجد أ',
      },
      {
        'osm_type': 'node',
        'osm_id': 77,
        'lat': '30.046',
        'lon': '31.2357',
        'category': 'amenity',
        'type': 'place_of_worship',
        'name': 'كنيسة العذراء',
      },
    ];
    final client = MockClient((req) async {
      if (req.url.host == 'nominatim.openstreetmap.org') {
        return http.Response.bytes(utf8.encode(jsonEncode(nominatim)), 200);
      }
      await Future<void>.delayed(const Duration(seconds: 15));
      return http.Response.bytes(utf8.encode(jsonEncode(_sample)), 200);
    });
    await pumpApp(tester, size: tallPhone, locale: 'ar');
    // Not pushScreen: its pumpAndSettle would wait for the slow servers.
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(MaterialPageRoute<void>(builder: (_) => MosquesScreen(client: client))),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.byKey(const Key('mosque-node/1')), findsOneWidget);
    expect(find.text('كنيسة العذراء'), findsNothing, reason: 'churches are not mosques');
    expect(find.byKey(const Key('mosquesCompleting')), findsOneWidget);
    expect(find.byKey(const Key('mosquesLoading')), findsNothing);
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mosquesCompleting')), findsNothing);
    expect(find.byKey(const Key('mosque-way/2')), findsOneWidget);
    expect(find.byKey(const Key('mosque-node/1')), findsOneWidget);
    await tester.pump(const Duration(seconds: 30)); // the spare servers' answers, now ignored
  });

  testWidgets('offline: last saved list, else an error with retry', (tester) async {
    var online = true;
    final client = MockClient((req) async {
      if (!online) throw http.ClientException('offline');
      if (req.url.host == 'nominatim.openstreetmap.org') return http.Response('[]', 200);
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
    await tester.tap(find.byKey(const Key('mosquesRadius-1000')));
    await tester.pumpAndSettle();
    expect(find.textContaining('last saved result'), findsOneWidget);
    expect(find.byKey(const Key('mosque-node/1')), findsOneWidget);
  });

  testWidgets('searches around the GPS position, and again on "update my location"', (tester) async {
    final bodies = <String>[];
    final client = MockClient((req) async {
      if (req.url.host == 'nominatim.openstreetmap.org') return http.Response('[]', 200);
      bodies.add(Uri.decodeQueryComponent(req.body));
      return http.Response.bytes(utf8.encode(jsonEncode(_sample)), 200);
    });
    await pumpApp(tester, size: tallPhone, locale: 'en', location: const FakeLocation(LocationFound(30.0445, 31.2357)));
    await pushScreen(tester, MosquesScreen(client: client));
    await tester.pumpAndSettle();
    expect(bodies, hasLength(3), reason: 'three servers asked together');
    expect(bodies.first, contains('around:1000,30.044,31.236'));
    expect(find.text('Mosques around your current location'), findsOneWidget);
    expect(find.byKey(const Key('mosquesGeoFallback')), findsNothing);
    expect(find.text('56 m'), findsOneWidget);
    await tester.tap(find.byKey(const Key('mosquesLocate')));
    await tester.pumpAndSettle();
    expect(bodies, hasLength(6));
  });

  test('Google Places: parsed nearest first; the finder uses it when a key is set, else OpenStreetMap', () async {
    final places = {
      'places': [
        {
          'id': 'b',
          'displayName': {'text': 'مسجد نور الإيمان'},
          'location': {'latitude': 30.0490, 'longitude': 31.2357},
        },
        {
          'id': 'a',
          'displayName': {'text': 'مسجد الرحمن'},
          'location': {'latitude': 30.0460, 'longitude': 31.2357},
        },
        {'id': 'x'},
      ],
    };
    final list = parseGooglePlaces(places, 30.0445, 31.2357);
    expect([for (final m in list) m.name], ['مسجد الرحمن', 'مسجد نور الإيمان']);
    expect(list.first.distance, closeTo(167, 5));

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final hosts = <String>[];
    final client = MockClient((req) async {
      hosts.add(req.url.host);
      if (req.url.host == 'places.googleapis.com') {
        expect(req.headers['X-Goog-Api-Key'], 'k');
        expect(jsonDecode(req.body)['includedTypes'], ['mosque']);
        return http.Response.bytes(utf8.encode(jsonEncode(places)), 200);
      }
      return http.Response.bytes(utf8.encode(jsonEncode(_sample)), 200);
    });
    final g = await MosqueFinder(client, prefs, placesKey: 'k').find(30.0445, 31.2357, 5000, arabic: true);
    expect(g.fromGoogle, isTrue);
    expect(hosts, ['places.googleapis.com']);
    final o = await MosqueFinder(client, prefs, placesKey: '').find(30.0445, 31.2357, 5000, arabic: true);
    expect(o.fromGoogle, isFalse);
    expect(hosts.last, isNot('places.googleapis.com'));
  });
}
