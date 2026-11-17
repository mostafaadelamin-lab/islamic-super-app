// Preview pictures of the slide-down Mushaf player (owner 2026-11-17), iPhone 6.9" size at 2x.
// Output: $RATTIL_SCREENSHOT_DIR/player-handle, or build/screenshots/player-handle.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/player-handle');

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

  for (final (name, size) in [('portrait', const Size(440, 956)), ('landscape', const Size(956, 440))]) {
    testWidgets('preview: player handle $name', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(tester, size: size, prefs: const {'theme': 'light'}, audio: FakeAudioBackend());
      await pushScreen(tester, const PageReaderScreen(initialPage: 2));
      await shot(tester, 'app-$name-open');
      await tester.tap(find.byKey(const Key('playerHandle')));
      await tester.pumpAndSettle();
      await shot(tester, 'app-$name-closed');
    });
  }
}
