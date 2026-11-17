// Preview pictures of «معاني الكلمات» in the Mushaf (owner 2026-11-17), iPhone 6.9" size at 2x.
// Output: $RATTIL_SCREENSHOT_DIR/word-meanings, or build/screenshots/word-meanings.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/word-meanings');

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

  testWidgets('preview: word meanings', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(440, 956), prefs: const {'theme': 'light'}, audio: FakeAudioBackend());
    await pushScreen(tester, const PageReaderScreen(initialPage: 50));
    await shot(tester, 'app-1-bar');
    await tester.tap(find.byKey(const Key('barMeanings')));
    await tester.pumpAndSettle();
    await shot(tester, 'app-2-page');
    await tester.tap(find.byKey(const Key('wordMeaningsClose')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pageAyah-3-7')));
    await tester.pumpAndSettle();
    await shot(tester, 'app-3-ayah-menu');
    await tester.tap(find.byKey(const Key('ayahMeanings')));
    await tester.pumpAndSettle();
    await shot(tester, 'app-4-ayah');
  });
}
