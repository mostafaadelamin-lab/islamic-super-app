// Preview pictures of «المساجد القريبة» (owner 2026-11-24): closest distances first (500 m, 1 km …),
// the quick list while the full one loads, and the labelled Google Maps button in the corner.
// Output: $RATTIL_SCREENSHOT_DIR/mosques, or build/screenshots/mosques.
// RATTIL_MOSQUES_FIXTURE = an Overpass JSON answer around 30.044, 31.236 (else a small sample).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/location.dart';
import 'package:rattil/domain/mosques.dart';
import 'package:rattil/ui/mosques_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/mosques');
  const here = (lat: 30.0445, lng: 31.2362);
  final fixture = Platform.environment['RATTIL_MOSQUES_FIXTURE'];
  final all = fixture == null
      ? {
          'elements': [
            {
              'type': 'node',
              'id': 1,
              'lat': 30.0451,
              'lon': 31.2366,
              'tags': {'amenity': 'place_of_worship', 'name': 'مسجد الرحمة'},
            },
            {
              'type': 'node',
              'id': 2,
              'lat': 30.0485,
              'lon': 31.2340,
              'tags': {'amenity': 'place_of_worship', 'name': 'مسجد النور'},
            },
          ],
        }
      : jsonDecode(File(fixture).readAsStringSync()) as Map<String, dynamic>;

  Map<String, dynamic> within(int radius, {int skipCloserThan = 0}) => {
    'elements': [
      for (final e in all['elements'] as List)
        if (() {
          final m = e as Map;
          final c = m['center'] as Map?;
          final lat = (m['lat'] ?? c?['lat']) as num?;
          final lng = (m['lon'] ?? c?['lon']) as num?;
          if (lat == null || lng == null) return false;
          final d = distanceM(here.lat, here.lng, lat.toDouble(), lng.toDouble());
          return d <= radius && d >= skipCloserThan;
        }())
          e,
    ],
  };

  Future<void> shot(WidgetTester tester, String name) async {
    final view = tester.binding.renderViews.first;
    void repaint(RenderObject o) {
      o.markNeedsPaint();
      o.visitChildren(repaint);
    }

    debugDisableShadows = false;
    repaint(view);
    await tester.pump();
    final layer = view.debugLayer! as OffsetLayer;
    final bytes = await tester.runAsync(() async {
      final ui.Image image = await layer.toImage(Offset.zero & view.size, pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    debugDisableShadows = true;
    repaint(view);
    await tester.pump();
    outDir.createSync(recursive: true);
    File('${outDir.path}/$name.png').writeAsBytesSync(bytes!);
  }

  int radiusOf(http.Request req) =>
      int.parse(RegExp(r'around:(\d+),').firstMatch(Uri.decodeQueryComponent(req.body))!.group(1)!);

  Future<void> open(WidgetTester tester, MockClient client) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(440, 956), location: const FakeLocation(LocationFound(30.0445, 31.2362)));
    unawaited(
      tester
          .state<NavigatorState>(find.byType(Navigator).first)
          .push(MaterialPageRoute<void>(builder: (_) => MosquesScreen(client: client))),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('app: quick list first, then the nearest mosques within 1 km', (tester) async {
    final client = MockClient((req) async {
      if (req.url.host == 'nominatim.openstreetmap.org') {
        // The quick search finds a few of them.
        final some = (within(1000)['elements'] as List).take(3).map((e) {
          final m = e as Map;
          final c = m['center'] as Map?;
          return {
            'osm_type': m['type'],
            'osm_id': m['id'],
            'lat': '${m['lat'] ?? c?['lat']}',
            'lon': '${m['lon'] ?? c?['lon']}',
            'category': 'amenity',
            'type': 'place_of_worship',
            'name': (m['tags'] as Map?)?['name:ar'] ?? (m['tags'] as Map?)?['name'] ?? '',
          };
        }).toList();
        return http.Response.bytes(utf8.encode(jsonEncode(some)), 200);
      }
      await Future<void>.delayed(const Duration(seconds: 6));
      return http.Response.bytes(utf8.encode(jsonEncode(within(radiusOf(req)))), 200);
    });
    await open(tester, client);
    await shot(tester, '01-app-quick-list-while-loading');
    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();
    await shot(tester, '02-app-nearest-within-1km');
    await tester.pump(const Duration(seconds: 30));
  });

  testWidgets('app: nothing within 1 km, widened to 2 km', (tester) async {
    final client = MockClient((req) async {
      if (req.url.host == 'nominatim.openstreetmap.org') return http.Response('[]', 200);
      return http.Response.bytes(utf8.encode(jsonEncode(within(radiusOf(req), skipCloserThan: 1000))), 200);
    });
    await open(tester, client);
    await tester.pumpAndSettle();
    await shot(tester, '03-app-widened-to-2km');
  });
}
