// Preview pictures of Sahih Muslim from sunnah.com with its numbers (owner 2026-11-26).
// Output: $RATTIL_SCREENSHOT_DIR/hadith-sunnah, or build/screenshots/hadith-sunnah.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart' show Key, TextInputAction;
import 'package:rattil/ui/hadith_screen.dart';

import '../helpers.dart';

void main() {
  late final content;
  setUpAll(() async => content = await loadContent());
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/hadith-sunnah');

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

  testWidgets('preview: Muslim 1218 and 2186 with sunnah.com numbers', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(390, 800), prefs: {'theme': 'light'});
    await pushScreen(tester, HadithBookScreen(book: content.hadith.book('muslim')!, start: 5644));
    await tester.pumpAndSettle();
    await shot(tester, 'muslim-2186');
    await tester.tap(find.byKey(const Key('hadithTools')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('hadithGo')), '١٢١٨');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    await shot(tester, 'muslim-go-1218');
  });
}
