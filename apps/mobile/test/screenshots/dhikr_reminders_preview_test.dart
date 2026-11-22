// Preview pictures of the dhikr reminders screen (owner 2026-11-20), iPhone 6.9" size at 2x.
// Output: $RATTIL_SCREENSHOT_DIR/dhikr-reminders, or build/screenshots/dhikr-reminders.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/ui/dhikr_reminders_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/dhikr-reminders');

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

  testWidgets('preview: dhikr reminders screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: {'dhikrRem.on': true, 'clock': '12'});
    await pushScreen(tester, const DhikrRemindersScreen());
    await shot(tester, '01-dhikr-reminders');
    await tester.scrollUntilVisible(find.byKey(const Key('dhikrRem-radeetu')), 300);
    await tester.pumpAndSettle();
    await shot(tester, '02-dhikr-reminders-list');
  });

  testWidgets('preview: adhkar reminders sheet entry', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    await tester.tap(find.byKey(const Key('adhkarReminders')));
    await tester.pumpAndSettle();
    await shot(tester, '03-adhkar-reminders-sheet');
  });

  testWidgets('preview: Adhkar tab card', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size);
    await pushScreen(tester, const AdhkarScreen());
    await shot(tester, '04-adhkar-tab-card');
  });

  // Owner 2026-11-22: between the adhan and the iqama the home and prayer tab count down to the iqama.
  final dhuhr = DateTime.utc(2026, 1, 15, 10, 5);
  testWidgets('preview: home iqama countdown', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, clock: () => dhuhr.add(const Duration(minutes: 6, seconds: 18)));
    await shot(tester, '05-home-iqama-countdown');
  });

  testWidgets('preview: prayer tab iqama countdown', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, clock: () => dhuhr.add(const Duration(minutes: 6, seconds: 18)));
    await goToTab(tester, 2);
    await shot(tester, '06-prayer-iqama-countdown');
  });
}
