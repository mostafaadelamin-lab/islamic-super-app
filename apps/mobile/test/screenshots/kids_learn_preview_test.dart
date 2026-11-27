// Preview pictures of the kids' learning corner (owner 2026-11-20), iPhone 6.9" size at 2x.
// Output: $RATTIL_SCREENSHOT_DIR/kids-learn, or build/screenshots/kids-learn.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/kids.dart';
import 'package:rattil/domain/kids_learn.dart';
import 'package:rattil/ui/kids_learn_screen.dart';
import 'package:rattil/ui/kids_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/kids-learn');
  final kids = KidsContent.parse(File('assets/content/kids.v1.json').readAsStringSync());
  Future<KidsContent> loader() async => kids;
  final learn = KidsLearnContent.parse(File('assets/content/kids-learn.v1.json').readAsStringSync());
  Future<KidsLearnContent> learnLoader() async => learn;

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
  const prefs = {'theme': 'light'};

  Future<void> settleImages(WidgetTester tester) async {
    await tester.runAsync(() async {
      for (final e in find.byType(Image).evaluate()) {
        await precacheImage((e.widget as Image).image, e);
      }
    });
    await tester.pumpAndSettle();
  }

  testWidgets('preview: kids hub', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs);
    await pushScreen(tester, KidsScreen(loader: loader));
    await shot(tester, '01a-kids-hub-top');
    await tester.drag(find.byKey(const Key('kidsHub')), const Offset(0, -260));
    await tester.pumpAndSettle();
    await shot(tester, '01-kids-hub');
  });

  testWidgets('preview: book shelf', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs);
    await pushScreen(tester, KidsBooksScreen(loader: learnLoader));
    await settleImages(tester);
    await shot(tester, '02-books');
  });

  testWidgets('preview: hadith levels and card', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(
      tester,
      size: size,
      prefs: {
        ...prefs,
        'kidsHadithMemorized': ['1', '2', '3'],
      },
    );
    await pushScreen(tester, KidsHadithScreen(loader: learnLoader));
    await shot(tester, '03-hadith-levels');
    await tester.tap(find.byKey(const Key('kidsHadith.level1')));
    await tester.pumpAndSettle();
    await shot(tester, '04-hadith-list');
    await tester.tap(find.byKey(const Key('kidsHadith.5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kidsHadith.repeat')));
    await tester.tap(find.byKey(const Key('kidsHadith.repeat')));
    await tester.pumpAndSettle();
    await shot(tester, '05-hadith-card');
  });

  testWidgets('preview: adhkar cards', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs);
    await pushScreen(tester, KidsCardsScreen(loader: learnLoader, evening: false));
    await tester.tap(find.byKey(const Key('kidsCardTap-1')));
    await tester.pumpAndSettle();
    await shot(tester, '06-cards');
    await tester.tap(find.byKey(const Key('kidsCardTap-2')));
    await tester.pumpAndSettle();
    for (final n in [3, 4, 5, 6, 7, 8, 10]) {
      await tester.tap(find.byKey(Key('kidsCardTap-$n')));
      await tester.pumpAndSettle();
    }
    await tester.pumpAndSettle();
    await shot(tester, '06b-cards-progress');
  });

  testWidgets('preview: wudu steps', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs);
    await pushScreen(tester, KidsStepsScreen(salah: false, loader: learnLoader));
    await tester.tap(find.byKey(const Key('pager.next')));
    await tester.pumpAndSettle();
    await settleImages(tester);
    await shot(tester, '07-wudu');
  });

  testWidgets('preview: salah steps', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs);
    await pushScreen(tester, KidsStepsScreen(salah: true, loader: learnLoader));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('pager.next')));
      await tester.pumpAndSettle();
    }
    await settleImages(tester);
    await shot(tester, '08-salah');
  });
}
