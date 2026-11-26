// Preview pictures of the Uthmani / Madina font switch in the Mushaf reader's top bar (owner 2026-11-26).
// Output: $RATTIL_SCREENSHOT_DIR/reader-font-switch, or build/screenshots/reader-font-switch.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/reader-font-switch');

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

  for (final width in [360.0, 390.0]) {
    testWidgets('preview: font switch in the reader bar at ${width.round()} wide', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(
        tester,
        size: Size(width, 800),
        prefs: {'theme': 'light', 'reader.hintShown': 9, 'reader.guideDone': true},
        audio: FakeAudioBackend(),
      );
      await pushScreen(tester, const PageReaderScreen(initialPage: 50));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('readerPrinted')), findsOneWidget);
      await shot(tester, 'uthmani-${width.round()}');
      await tester.tap(find.byKey(const Key('readerPrinted')));
      await tester.pumpAndSettle();
      await shot(tester, 'madina-${width.round()}');
    });
  }
}
