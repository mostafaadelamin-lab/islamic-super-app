// Preview pictures of the owner's simple home design (2026-11-24): home, «الأذان», «الأقسام الرئيسية»,
// «افهم دينك», settings, the tour's privacy page and «بلّغ عن خطأ».
// Output: $RATTIL_SCREENSHOT_DIR/home-simple, or build/screenshots/home-simple.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/lessons.dart';
import 'package:rattil/ui/lessons_screen.dart';
import 'package:rattil/ui/more_screen.dart';
import 'package:rattil/ui/onboarding_screen.dart';
import 'package:rattil/ui/settings_screen.dart';
import 'package:rattil/ui/tafsir_library_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/home-simple');

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

  LessonCatalog read() => LessonCatalog.parse(File('assets/content/lessons.v1.json').readAsStringSync());

  Future<void> open(WidgetTester tester, {double h = 956}) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: Size(440, h));
  }

  testWidgets('home', (tester) async {
    await open(tester, h: 1500);
    await shot(tester, 'A1-home');
  });

  testWidgets('adhan tab', (tester) async {
    await open(tester, h: 1700);
    await goToTab(tester, 2);
    await shot(tester, 'A2-adhan');
  });

  testWidgets('sections', (tester) async {
    await open(tester, h: 1100);
    await pushScreen(tester, const MoreScreen());
    await shot(tester, 'A3-sections');
  });

  testWidgets('afham deenak', (tester) async {
    await open(tester, h: 1300);
    final data = read();
    await pushScreen(tester, LessonsScreen(loader: () async => data));
    await tester.pumpAndSettle();
    await shot(tester, 'A4-afham');
    await tester.tap(find.byKey(const Key('lessonsTopic.stories')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('lessonsSeries.ahsan-qasas-kafy')));
    await tester.pumpAndSettle();
    await shot(tester, 'A5-afham-stories');
  });

  testWidgets('settings', (tester) async {
    await open(tester, h: 3600);
    await pushScreen(tester, const SettingsScreen());
    await shot(tester, 'A6-settings');
  });

  testWidgets('tour privacy page', (tester) async {
    await open(tester);
    await pushScreen(tester, OnboardingScreen(replay: true, onDone: () {}));
    await tester.tap(find.byKey(const Key('tourNext')));
    await tester.pumpAndSettle();
    await shot(tester, 'A7-tour-privacy');
  });

  testWidgets('report a mistake on the tafsir books page', (tester) async {
    await open(tester, h: 1400);
    await pushScreen(tester, const TafsirLibraryScreen());
    await tester.ensureVisible(find.byKey(const Key('reportError')));
    await tester.pumpAndSettle();
    await shot(tester, 'A8-report');
  });
}
