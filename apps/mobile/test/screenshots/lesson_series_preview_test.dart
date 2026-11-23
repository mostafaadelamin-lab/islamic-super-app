// Preview pictures of «سلاسل الدروس» (owner 2026-11-23): the series cards and one series with a lesson playing.
// Output: $RATTIL_SCREENSHOT_DIR/lesson-series, or build/screenshots/lesson-series.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/domain/lessons.dart';
import 'package:rattil/ui/lessons_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/lesson-series');

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

  testWidgets('app: series cards', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(440, 956));
    final data = read();
    await pushScreen(tester, LessonsScreen(loader: () async => data));
    await tester.pumpAndSettle();
    await shot(tester, '01-app-lesson-series');
  });

  testWidgets('app: Al-Azhar scholars (the Grand Imam first), and the simple purity lessons', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(440, 956));
    final data = read();
    await pushScreen(tester, LessonsScreen(loader: () async => data));
    await tester.tap(find.byKey(const Key('lessonsGroup.azhar')));
    await tester.pumpAndSettle();
    await shot(tester, '03-app-azhar');
    await tester.tap(find.byKey(const Key('lessonsGroup.all')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('lessonsTopic.tahara')));
    await tester.tap(find.byKey(const Key('lessonsTopic.tahara')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lessonsSeries.tahara-muyassar-alaa')));
    await tester.pumpAndSettle();
    await shot(tester, '04-app-tahara-simple');
  });

  testWidgets('app: one series, lessons heard ✓, the player under the lesson playing', (tester) async {
    tester.view.devicePixelRatio = 1;
    final backend = FakeNarrationBackend(length: const Duration(minutes: 57, seconds: 12));
    await pumpApp(tester, size: const Size(440, 956), narration: backend);
    final s = read().byId('seerah-hassan')!;
    await pushScreen(tester, LessonSeriesScreen(series: s));
    final settings = tester.element(find.byType(LessonSeriesScreen)).services.settings;
    for (final e in s.episodes.take(2)) {
      await settings.setEpisodeDone('${s.playerSeries}/${s.episodeId(e)}', true);
    }
    await tester.tap(find.byKey(Key('lesson-${s.episodeId(s.episodes[2])}')));
    await tester.pumpAndSettle();
    backend.emit(const Duration(minutes: 21, seconds: 50));
    await tester.pumpAndSettle();
    await shot(tester, '02-app-series-playing');
  });
}
