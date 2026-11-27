// Preview of «المصادر والإثبات» in «عن التطبيق» (owner 2026-11-26).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/about_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/about-proof');

  testWidgets('preview: about with the sources and proof link', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: const Size(390, 844), prefs: {'theme': 'light'});
    await pushScreen(tester, const AboutScreen());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aboutProof')), findsOneWidget);
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer! as OffsetLayer;
    final bytes = await tester.runAsync(() async {
      final ui.Image image = await layer.toImage(Offset.zero & view.size, pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    outDir.createSync(recursive: true);
    File('${outDir.path}/about.png').writeAsBytesSync(bytes!);
  });
}
