// Renders key screens with the real bundled fonts (Amiri Quran, IBM Plex Sans
// Arabic, Material Icons) and writes PNG screenshots. Output directory:
// $RATTIL_SCREENSHOT_DIR, or build/screenshots by default.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory(Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots');
  const phone = Size(412, 915);

  Future<void> shot(WidgetTester tester, String name) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.descendant(of: find.byType(MaterialApp), matching: find.byType(RepaintBoundary)).first,
    );
    final bytes = await tester.runAsync(() async {
      final ui.Image image = await boundary.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data!.buffer.asUint8List();
    });
    expect(bytes, isNotNull);
    expect(bytes!.length, greaterThan(10000), reason: 'a real, non-empty image');
    outDir.createSync(recursive: true);
    File('${outDir.path}/$name.png').writeAsBytesSync(bytes);
  }

  for (final locale in ['ar', 'en']) {
    testWidgets('screenshots ($locale, light)', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(
        tester,
        locale: locale,
        size: phone,
        prefs: {
          'theme': 'light',
          'lastRead.surah': 2,
          'lastRead.ayah': 255,
          'showTranslation': locale == 'en',
          'bookmarks.v1':
              '[{"id":"b-2-255","surah":2,"ayah":255,"updatedAt":2,"deleted":false},'
              '{"id":"b-36-1","surah":36,"ayah":1,"updatedAt":1,"deleted":false}]',
        },
      );
      await shot(tester, '${locale}_01_home');
      await goToTab(tester, 1);
      await shot(tester, '${locale}_02_surah_list');
      await pushScreen(tester, const SurahReaderScreen(surah: 1));
      await shot(tester, '${locale}_03_surah_reader');
      await goBack(tester);
      await pushScreen(tester, const PageReaderScreen(initialPage: 604));
      await shot(tester, '${locale}_04_mushaf_page_604');
      await goBack(tester);
      await goToTab(tester, 2);
      await shot(tester, '${locale}_05_prayer');
      await goToTab(tester, 3);
      await shot(tester, '${locale}_06_bookmarks');
      await goToTab(tester, 4);
      await shot(tester, '${locale}_07_settings');
    });

    testWidgets('screenshots ($locale, dark)', (tester) async {
      tester.view.devicePixelRatio = 1;
      await pumpApp(tester, locale: locale, size: phone, prefs: {'theme': 'dark'});
      await goToTab(tester, 1);
      await pushScreen(tester, const SurahReaderScreen(surah: 2, initialAyah: 1));
      await shot(tester, '${locale}_08_surah_reader_dark');
      await goBack(tester);
      await goToTab(tester, 2);
      await shot(tester, '${locale}_09_prayer_dark');
    });
  }
}
