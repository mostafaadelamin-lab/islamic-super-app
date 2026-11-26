// Preview pictures (owner 2026-11-26): «أذكاري» (user-added adhkar) and the driving-mode bar after
// leaving the driving screen. iPhone 6.9" size at 2x.
// Output: $RATTIL_SCREENSHOT_DIR/custom-adhkar, or build/screenshots/custom-adhkar.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/drive_mode.dart';
import 'package:rattil/ui/adhkar_screen.dart';

import '../helpers.dart';
import '../widget/drive_mode_test.dart' show driveStorage;

void main() {
  setUpAll(loadContent);
  setUp(() => rootBundle.evict(DriveClips.asset));
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/custom-adhkar');

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

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  const size = Size(440, 956);

  testWidgets('preview: «أذكاري» in the list, the add sheet, the cards view', (tester) async {
    tester.view.devicePixelRatio = 1;
    final app = await pumpApp(tester, size: size);
    final s = app.services;
    await s.settings.setAdhkarCards(false);
    await s.adhkar.saveCustom(text: 'قراءة سورة الملك', count: 1, sessions: {AdhkarSession.morning});
    await s.adhkar.saveCustom(
      text: 'الصلاة على النبي ﷺ',
      count: 10,
      sessions: {AdhkarSession.morning, AdhkarSession.evening},
    );
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    await tester.scrollUntilVisible(find.byKey(const Key('customDhikrAddBig')), 600);
    await tester.pumpAndSettle();
    await shot(tester, '01-app-my-adhkar-list');

    await tester.tap(find.byKey(const Key('customDhikrAdd')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('customDhikrText')), 'دعاء لوالديّ');
    await tester.tap(find.byKey(const Key('customDhikrQuick-3')));
    await tester.pumpAndSettle();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await shot(tester, '02-app-add-sheet');
  });

  testWidgets('preview: driving-mode bar after leaving the driving screen', (tester) async {
    tester.view.devicePixelRatio = 1;
    final app = await pumpApp(tester, size: size, storage: driveStorage(), drivePlayer: TestDrivePlayer());
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    await tester.tap(find.byKey(const Key('adhkarDriveMode')));
    await settle(tester);
    final drive = app.services.drive!;
    expect(drive.isPlaying, isTrue);
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await settle(tester);
    await shot(tester, '03-app-drive-bar-adhkar');
    await tester.state<NavigatorState>(find.byType(Navigator).first).maybePop();
    await settle(tester);
    await shot(tester, '04-app-drive-bar-home');
    await drive.stop();
  });
}
