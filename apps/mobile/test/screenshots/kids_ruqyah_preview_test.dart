// Preview pictures of the ruqyah, the kids section and the home tile (owner 2026-11-20), iPhone 6.9" size at 2x.
// Output: $RATTIL_SCREENSHOT_DIR/kids-ruqyah, or build/screenshots/kids-ruqyah.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/kids.dart';
import 'package:rattil/ui/kids_screen.dart';
import 'package:rattil/ui/ruqyah_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/kids-ruqyah');
  final kids = KidsContent.parse(File('assets/content/kids.v1.json').readAsStringSync());
  Future<KidsContent> loader() async => kids;

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

  testWidgets('preview: home tile', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await tester.scrollUntilVisible(find.byKey(const Key('home.tile-library')), 300);
    await tester.drag(find.byKey(const Key('homeList')), const Offset(0, -120));
    await tester.pumpAndSettle();
    await shot(tester, '01-home');
  });

  testWidgets('preview: adhkar ruqyah section', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await goToTab(tester, 3);
    await tester.scrollUntilVisible(find.byKey(const Key('adhkarHub.ruqyahKids')), 300);
    await tester.drag(find.byKey(const Key('adhkarHub')), const Offset(0, -150));
    await tester.pumpAndSettle();
    await shot(tester, '02-adhkar');
  });

  testWidgets('preview: ruqyah', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, RuqyahScreen(loader: loader));
    await shot(tester, '03-ruqyah');
    await tester.scrollUntilVisible(find.byKey(const Key('ruqyah.item.1')), 400);
    await tester.pumpAndSettle();
    await shot(tester, '04-ruqyah-verses');
    final dua = kids.ruqyah.items.indexWhere((i) => i is RuqyahDua);
    await tester.scrollUntilVisible(find.byKey(Key('ruqyah.item.$dua')), 600);
    await tester.drag(find.byKey(const Key('ruqyah')), const Offset(0, 200));
    await tester.pumpAndSettle();
    await shot(tester, '05-ruqyah-dua');
  });

  testWidgets('preview: kids ruqyah', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, RuqyahScreen(kids: true, loader: loader));
    await shot(tester, '06-ruqyah-kids');
  });

  testWidgets('preview: kids section', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, KidsScreen(loader: loader));
    await shot(tester, '07-kids');
    await tester.tap(find.byKey(const Key('kids.prophets')));
    await tester.pumpAndSettle();
    await shot(tester, '08-kids-prophets');
    await goBack(tester);
    await tester.tap(find.byKey(const Key('kids.teacher')));
    await tester.pumpAndSettle();
    await shot(tester, '09-kids-teacher');
    await goBack(tester);
    await tester.tap(find.byKey(const Key('kids.stories')));
    await tester.pumpAndSettle();
    await shot(tester, '10-kids-stories');
  });

  testWidgets('preview: home 12-hour clock', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: const {'theme': 'light', 'clock': '12'}, audio: FakeAudioBackend());
    await shot(tester, '00-home-12h');
  });
}
