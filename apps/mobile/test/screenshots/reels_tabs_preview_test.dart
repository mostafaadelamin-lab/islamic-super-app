// Preview pictures of the video player's top tabs (owner 2026-11-28: unselected tabs showed as blank
// white pills on the iPhone). Output: $RATTIL_SCREENSHOT_DIR/reels-tabs, or build/screenshots/reels-tabs.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/domain/reels.dart';
import 'package:rattil/ui/reels_screen.dart';

import '../helpers.dart';

Widget _player(BuildContext context, Reel r) => const ColoredBox(color: Color(0xFF15110C), child: SizedBox.expand());
Widget _live(BuildContext context, LiveChannel c) => const ColoredBox(color: Color(0xFF15110C), child: SizedBox.expand());

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/reels-tabs');

  Future<void> shot(WidgetTester tester, String name) async {
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final bytes = await tester.runAsync(() async {
      final ui.Image image = await layer.toImage(Offset.zero & view.size, pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    outDir.createSync(recursive: true);
    File('${outDir.path}/$name.png').writeAsBytesSync(bytes!);
  }

  for (final tab in ['haramain', 'live']) {
    testWidgets('preview: player tabs, $tab selected', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(
        tester,
        size: const Size(390, 844),
        prefs: {'theme': 'light'},
        httpClient: MockClient((_) async => http.Response('', 404)),
      );
      await pushScreen(
        tester,
        ReelsScreen(initialTab: tab, playerBuilder: _player, livePlayerBuilder: _live, showPosters: false),
      );
      await tester.pumpAndSettle();
      await shot(tester, 'app-tabs-$tab');
    });
  }
}
