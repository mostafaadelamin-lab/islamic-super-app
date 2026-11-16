// App Store screenshots at the exact sizes App Store Connect asks for:
//   iPhone 6.9": 1320 x 2868 (440 x 956 points at 3x)
//   iPad 13":    2064 x 2752 (1032 x 1376 points at 2x)
// Rendered with the real bundled fonts. Output: $RATTIL_SCREENSHOT_DIR/store, or build/screenshots/store.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/hajj_hub_screen.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/store');

  Future<void> shot(WidgetTester tester, String name, double ratio, Size expectPx) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.descendant(of: find.byType(MaterialApp), matching: find.byType(RepaintBoundary)).first,
    );
    final bytes = await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: ratio);
      expect(Size(image.width.toDouble(), image.height.toDouble()), expectPx);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    expect(bytes!.length, greaterThan(10000), reason: 'a real, non-empty image');
    outDir.createSync(recursive: true);
    File('${outDir.path}/$name.png').writeAsBytesSync(bytes);
  }

  const devices = [
    ('iphone69', Size(440, 956), 3.0, Size(1320, 2868)),
    ('ipad13', Size(1032, 1376), 2.0, Size(2064, 2752)),
  ];

  for (final (tag, size, ratio, px) in devices) {
    testWidgets('App Store screenshots: $tag (ar, light)', (tester) async {
      tester.view.devicePixelRatio = 1;
      final prefs = <String, Object>{'theme': 'light', 'lastRead.surah': 2, 'lastRead.ayah': 255};
      await pumpApp(tester, size: size, prefs: prefs);
      await shot(tester, '${tag}_01_home', ratio, px);
      await pushScreen(tester, const PageReaderScreen(initialPage: 3));
      await shot(tester, '${tag}_02_mushaf', ratio, px);
      await goBack(tester);
      await goToTab(tester, 1);
      await shot(tester, '${tag}_03_quran_index', ratio, px);
      await goToTab(tester, 2);
      await shot(tester, '${tag}_04_prayer', ratio, px);
      await goToTab(tester, 3);
      await shot(tester, '${tag}_05_adhkar', ratio, px);
      await pushScreen(tester, const HajjHubScreen());
      await shot(tester, '${tag}_06_hajj', ratio, px);
    });
  }
}
