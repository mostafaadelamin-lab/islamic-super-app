// Preview pictures of the «download the Madina font once» offer in the Mushaf reader (owner 2026-11-26).
// Output: $RATTIL_SCREENSHOT_DIR/printed-download, or build/screenshots/printed-download.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/printed_mushaf.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/printed-download');

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

  testWidgets('preview: Madina font offer and progress', (tester) async {
    tester.view.devicePixelRatio = 1;
    final pm = PrintedMushaf.instance;
    pm.debugSetProgress(saved: 0);
    await pumpApp(
      tester,
      size: const Size(390, 844),
      prefs: {'theme': 'light', 'reader.hintShown': 9, 'reader.guideDone': true, 'mushaf.printed.v3': true},
      audio: FakeAudioBackend(),
    );
    await pushScreen(tester, const PageReaderScreen(initialPage: 50));
    await tester.pumpAndSettle();
    await shot(tester, '1-madina-default');
    await tester.tap(find.byKey(const Key('readerPrinted')));
    await tester.pumpAndSettle();
    await shot(tester, '2-font-menu');
    Navigator.of(tester.element(find.byKey(const Key('mushafFontMenu')))).pop();
    await tester.pumpAndSettle();
    pm.debugSetProgress(saved: 0, done: 250);
    await tester.pump();
    await shot(tester, '3-progress');
    pm.debugSetProgress();
  });
}
