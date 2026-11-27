// Preview pictures of the Mushaf page on a small Android phone with a bigger system font
// (owner's realme C21-Y, 2026-11-24: the first and last words of each line were cut off).
// Output: $RATTIL_SCREENSHOT_DIR/small-phone-mushaf, or build/screenshots/small-phone-mushaf.
// The printed look needs its page font: set RATTIL_PAGE_FONT_DIR to a folder with p562.ttf.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/printed_mushaf.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory(
    '${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/small-phone-mushaf',
  );
  final fontDir = Platform.environment['RATTIL_PAGE_FONT_DIR'];

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

  for (final printed in [true, false]) {
    for (final scale in [1.0, 1.15, 1.3]) {
      final look = printed ? 'printed' : 'standard';
      testWidgets('preview: page 562 at 360x800, $look, text size $scale', (tester) async {
        if (printed) {
          if (fontDir == null) return;
          final bytes = File('$fontDir/p562.ttf').readAsBytesSync();
          await tester.runAsync(() async {
            await (FontLoader(PrintedMushaf.family(562))..addFont(Future.value(ByteData.sublistView(bytes)))).load();
          });
          final layout = PrintedLayout.parse(File('assets/content/mushaf-printed.v1.json').readAsStringSync());
          PrintedMushaf.instance.debugMarkReady(layout, [562]);
        }
        tester.view.devicePixelRatio = 1;
        PageReaderScreen.startFullScreen = true;
        addTearDown(() => PageReaderScreen.startFullScreen = false);
        await pumpApp(
          tester,
          size: const Size(360, 800),
          textScale: scale,
          prefs: {'theme': 'light', 'reader.hintShown': 9, 'mushaf.printed.v3': printed},
          audio: FakeAudioBackend(),
        );
        await pushScreen(tester, const PageReaderScreen(initialPage: 562));
        await tester.pumpAndSettle();
        await shot(tester, '$look-text-${(scale * 100).round()}');
      });
    }
  }
}
