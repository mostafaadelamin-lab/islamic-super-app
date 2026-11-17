// Preview pictures of driving mode (1.2.2) for the owner (iPhone 6.9" size, 2x).
// Output: $RATTIL_SCREENSHOT_DIR/drive, or build/screenshots/drive.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/adhkar_screen.dart';

import '../helpers.dart';
import '../widget/drive_mode_test.dart' show driveStorage, settle;

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/drive');
  const size = Size(440, 956);

  Future<void> shot(WidgetTester tester, String name) async {
    // The whole view (the routes and any sheet over them), with real soft shadows (the test default
    // paints them as solid black bands); the flag is put back before the test ends.
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

  final prefs = <String, Object>{'theme': 'light'};

  testWidgets('preview: driving mode', (tester) async {
    tester.view.devicePixelRatio = 1;
    final player = TestDrivePlayer();
    final app = await pumpApp(tester, size: size, prefs: prefs, storage: driveStorage(), drivePlayer: player);
    await pushScreen(tester, const AdhkarScreen());
    await tester.scrollUntilVisible(find.byKey(const Key('adhkarDrive.evening')), 200);
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await shot(tester, '01_adhkar_tab_drive_buttons');

    await tester.ensureVisible(find.byKey(const Key('adhkarDrive.morning')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('adhkarDrive.morning')));
    await settle(tester);
    final drive = app.services.drive!;
    await shot(tester, '02_drive_first_dhikr');

    unawaited(drive.jumpTo(drive.items.indexWhere((it) => it.count == 100)));
    await settle(tester);
    for (var i = 0; i < 36; i++) {
      player.end();
      await settle(tester);
    }
    await shot(tester, '03_drive_37_of_100');

    await tester.tap(find.byKey(const Key('driveSettings')));
    await settle(tester);
    await shot(tester, '04_drive_settings');
    await drive.stop();
  });
}
