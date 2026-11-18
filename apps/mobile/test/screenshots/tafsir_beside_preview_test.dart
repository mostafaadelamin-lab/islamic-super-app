// Preview pictures of the Mushaf beside the tafsir and full screen with the tafsir (owner 2026-11-18).
// Output: $RATTIL_SCREENSHOT_DIR/tafsir-beside, or build/screenshots/tafsir-beside.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/tafsir-beside');

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

  for (final (name, size) in [('tablet', const Size(1280, 800)), ('phone', const Size(440, 956))]) {
    testWidgets('preview: tafsir beside the page, $name', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(tester, size: size, prefs: const {'theme': 'light', 'reader.hintShown': 9}, audio: FakeAudioBackend());
      await pushScreen(tester, const PageReaderScreen(initialPage: 3));
      await tester.tap(find.byKey(const Key('pageAyah-2-6')).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('ayahTafsir')));
      await tester.pumpAndSettle();
      await shot(tester, 'app-$name-1-ayah-tafsir');
      await tester.tap(find.byKey(const Key('ayahSheetClose')));
      await tester.pumpAndSettle();
      if (find.byKey(const Key('splitView')).evaluate().isEmpty) {
        await tester.tap(find.byKey(const Key('readerTafsirBeside')));
        await tester.pumpAndSettle();
      }
      await shot(tester, 'app-$name-2-tafsir-beside');
      await tester.tap(find.byKey(const Key('readerFull')));
      await tester.pumpAndSettle();
      await shot(tester, 'app-$name-3-full-with-tafsir');
    });
  }
}
