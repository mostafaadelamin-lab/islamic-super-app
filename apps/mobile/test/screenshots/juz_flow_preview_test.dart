// Preview pictures: whole surah / whole juz beside the tafsir, and «الأجزاء» in the index (owner 2026-11-20).
// Output: $RATTIL_SCREENSHOT_DIR/juz-and-surah-tafsir, or build/screenshots/juz-and-surah-tafsir.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/reader_widgets.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory(
    '${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/juz-and-surah-tafsir',
  );

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
    testWidgets('preview: whole surah and whole juz beside the tafsir, $name', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(
        tester,
        size: size,
        prefs: const {'theme': 'light', 'reader.hintShown': 9},
        audio: FakeAudioBackend(),
      );
      await pushScreen(tester, const PageReaderScreen(initialPage: 50));
      await tester.tap(find.byKey(const Key('readerTab-surah')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('readerTafsirBeside')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('surahFlowAyah-3-2')));
      await tester.pumpAndSettle();
      await shot(tester, 'app-$name-1-surah-with-tafsir');
      await tester.tap(find.byKey(const Key('readerTab-juz')));
      await tester.pumpAndSettle();
      await shot(tester, 'app-$name-2-juz-with-tafsir');
      await tester.tap(find.byKey(const Key('duoHideTafsir')));
      await tester.pumpAndSettle();
      await shot(tester, 'app-$name-3-juz-reading');
    });
  }

  testWidgets('preview: index «الأجزاء», phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(440, 956), prefs: const {'theme': 'light'});
    await goToTab(tester, 1);
    await tester.tap(find.byKey(const Key('tabJuz')));
    await tester.pumpAndSettle();
    await shot(tester, 'app-phone-4-index-juz');
  });

  testWidgets('preview: whole juz 30 from its first page, phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(
      tester,
      size: const Size(440, 956),
      prefs: const {'theme': 'light', 'reader.hintShown': 9},
      audio: FakeAudioBackend(),
    );
    await pushScreen(tester, const PageReaderScreen(initialPage: 582, initialTab: ReaderTab.juz));
    await shot(tester, 'app-phone-5-juz30');
  });
}
