// Preview pictures of the Hajj/Umrah round counter (owner 2026-11-17), iPhone 6.9" size at 2x.
// Output: $RATTIL_SCREENSHOT_DIR/round-counter, or build/screenshots/round-counter.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/pilgrimage_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/round-counter');

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

  Finder list(String k) =>
      find.descendant(of: find.byKey(Key('pilgrimage-$k')), matching: find.byType(Scrollable)).first;

  Future<void> goTo(WidgetTester tester, String kind, String step) async {
    final app = await pumpApp(tester, size: const Size(440, 956), prefs: const {'theme': 'light'});
    final flow = app.services.content.hajjGuide.flows[kind]!;
    final n = flow.indexWhere((s) => s.step == step);
    await pushScreen(tester, PilgrimageScreen(kind: PilgrimageKind.values.byName(kind)));
    for (var i = 0; i < n; i++) {
      final next = find.byKey(Key('stepNext-$kind'));
      await tester.scrollUntilVisible(next, 600, scrollable: list(kind));
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
  }

  Future<void> taps(WidgetTester tester, String tool, int n) async {
    final add = find.byKey(Key('rounds-$tool-add'));
    await tester.ensureVisible(add);
    await tester.pumpAndSettle();
    for (var i = 0; i < n; i++) {
      await tester.tap(add);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byKey(Key('rounds-$tool')));
    await tester.pumpAndSettle();
  }

  testWidgets('preview: umrah tawaf counter at 3', (tester) async {
    tester.view.devicePixelRatio = 1;
    await goTo(tester, 'umrah', 'tawaf-first');
    await taps(tester, 'tawaf', 3);
    await shot(tester, '01-umrah-tawaf-3-of-7');
  });

  testWidgets('preview: umrah sai counter complete', (tester) async {
    tester.view.devicePixelRatio = 1;
    await goTo(tester, 'umrah', 'sai');
    await taps(tester, 'sai', 7);
    await shot(tester, '02-umrah-sai-done');
  });

  testWidgets('preview: tamattu ifadah tawaf + sai', (tester) async {
    tester.view.devicePixelRatio = 1;
    await goTo(tester, 'tamattu', 'ifadah-tamattu');
    await taps(tester, 'tawaf', 5);
    await taps(tester, 'sai', 0);
    await tester.drag(list('tamattu'), const Offset(0, 250));
    await tester.pumpAndSettle();
    await shot(tester, '03-tamattu-ifadah-tawaf-and-sai');
  });

  testWidgets('preview: jamarat pebbles', (tester) async {
    tester.view.devicePixelRatio = 1;
    await goTo(tester, 'tamattu', 'aqaba');
    await taps(tester, 'jamarat', 2);
    await shot(tester, '04-jamarat-2-of-7');
  });
}
