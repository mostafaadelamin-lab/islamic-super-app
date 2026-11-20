// Preview pictures of the parent lock on the videos tab (owner 2026-11-20).
// Output: $RATTIL_SCREENSHOT_DIR/parent-lock, or build/screenshots/parent-lock.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rattil/domain/parent_lock.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/parent-lock');

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

  const size = Size(440, 956);

  Future<void> openVideos(WidgetTester tester, Map<String, Object> prefs) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, videosUnlocked: false);
    await tester.tap(find.text('فيديوهات').last);
    await tester.pumpAndSettle();
  }

  testWidgets('preview: first time, parent chooses a PIN', (tester) async {
    await openVideos(tester, {});
    await shot(tester, '01-set-pin');
  });

  testWidgets('preview: locked, enter the PIN', (tester) async {
    await openVideos(tester, {'parentLock.pin': hashPin('1234')});
    await tester.enterText(find.byKey(const Key('parentGate.pin')), '12');
    await tester.pumpAndSettle();
    await shot(tester, '02-enter-pin');
  });

  testWidgets('preview: forgot the PIN', (tester) async {
    await openVideos(tester, {'parentLock.pin': hashPin('1234')});
    await tester.tap(find.byKey(const Key('parentGate.forgot')));
    await tester.pumpAndSettle();
    await shot(tester, '03-forgot');
  });
}
