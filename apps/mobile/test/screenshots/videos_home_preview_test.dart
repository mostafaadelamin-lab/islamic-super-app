// Preview pictures of the «فيديوهات» page with real YouTube data (owner 2026-11-28, layout option 2).
// Needs network: run with RATTIL_LIVE_PREVIEW=1 (skipped otherwise). Output: $RATTIL_SCREENSHOT_DIR/videos-home.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:rattil/ui/videos_home_screen.dart';

import '../helpers.dart';

class _Net extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(context)..findProxy = HttpClient.findProxyFromEnvironment;
}

void main() {
  final live = Platform.environment['RATTIL_LIVE_PREVIEW'] == '1';
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/videos-home');

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

  Future<void> settleNetwork(WidgetTester tester, int seconds) async {
    for (var i = 0; i < seconds; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
      await tester.pump(const Duration(milliseconds: 100));
    }
    // Load the pictures on screen for real (the test clock does not run network image loading).
    final ctx = tester.element(find.byType(VideosHomeScreen));
    final providers = tester
        .widgetList<Image>(find.byType(Image))
        .map((i) => i.image)
        .whereType<NetworkImage>()
        .toList();
    await tester.runAsync(() async {
      await Future.wait([
        for (final p in providers) precacheImage(p, ctx).timeout(const Duration(seconds: 20), onTimeout: () {}),
      ]);
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  for (final theme in ['light', 'dark']) {
    testWidgets('preview: videos page, $theme', (tester) async {
      if (!live) return;
      HttpOverrides.global = _Net();
      tester.view.devicePixelRatio = 1;
      final client = http.Client();
      await pumpApp(tester, size: const Size(390, 844), prefs: {'theme': theme}, httpClient: client);
      await pushScreen(tester, const VideosHomeScreen());
      await settleNetwork(tester, 25);
      await shot(tester, 'app-videos-$theme');
      await tester.tap(find.byKey(const Key('videos.tab.golden')));
      await settleNetwork(tester, 15);
      await shot(tester, 'app-videos-golden-$theme');
      client.close();
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 16)));
    }, timeout: const Timeout(Duration(minutes: 3)));
  }
}
