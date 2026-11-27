// Preview pictures of the ✕ on the Mushaf players (owner 2026-11-20).
// Output: $RATTIL_SCREENSHOT_DIR/player-close, or build/screenshots/player-close.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/player-close');

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

  Future<void> openPlaying(WidgetTester tester, {required bool min}) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(440, 956), prefs: {'reader.playerMin': min}, audio: FakeAudioBackend());
    await pushScreen(tester, const PageReaderScreen(initialPage: 440));
    final rec = tester.element(find.byType(PageReaderScreen)).services.recitation;
    await rec.playOnFrom(440);
    await tester.pumpAndSettle();
  }

  testWidgets('app: Mushaf player open, with its ✕', (tester) async {
    await openPlaying(tester, min: false);
    await shot(tester, '01-app-mushaf-player');
  });

  testWidgets('app: Mushaf player slid down, with its new ✕', (tester) async {
    await openPlaying(tester, min: true);
    expect(find.byKey(const Key('miniStripClose')), findsOneWidget);
    await shot(tester, '02-app-mushaf-player-small');
  });
}
