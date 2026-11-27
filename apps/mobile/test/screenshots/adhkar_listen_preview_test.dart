// Preview pictures (owner 2026-11-27): Alafasy's recording inside the adhkar page, saving dhikr recordings
// for listening offline, «إعدادات الأذكار», and the celebration after the last dhikr. iPhone 6.9" at 2x.
// Output: $RATTIL_SCREENSHOT_DIR/adhkar-listen, or build/screenshots/adhkar-listen.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/ui/adhkar_audio.dart';
import 'package:rattil/ui/adhkar_celebration.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/dhikr_audio.dart';

import '../helpers.dart';
import '../widget/dhikr_extras_test.dart' show FakeUrlAudio;

class _Asset implements AssetAudio {
  final _pos = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  @override
  Future<Duration?> load(String asset) async => const Duration(minutes: 22, seconds: 5);
  @override
  Future<void> play() async {
    _playing.add(true);
    _pos.add(const Duration(minutes: 8, seconds: 12));
  }

  @override
  Future<void> pause() async => _playing.add(false);
  @override
  Future<void> seek(Duration d) async => _pos.add(d);
  @override
  Future<void> dispose() async {}
  @override
  Stream<Duration> get position => _pos.stream;
  @override
  Stream<bool> get playing => _playing.stream;
}

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/adhkar-listen');

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

  Directory storage() {
    final d = Directory.systemTemp.createTempSync('rattil-shots');
    Directory('${d.path}/adhkar').createSync();
    File('${d.path}/adhkar/adhkar_morning_alafasy.mp3').writeAsBytesSync(List.filled(300 * 1024, 0xFF));
    return d;
  }

  testWidgets('preview: listening in the page and saving offline', (tester) async {
    tester.view.devicePixelRatio = 1;
    debugAssetAudioFactory = _Asset.new;
    final fake = FakeUrlAudio();
    debugUrlAudioFactory = () => fake;
    addTearDown(() {
      debugAssetAudioFactory = null;
      debugUrlAudioFactory = null;
    });
    final st = storage();
    final app = await pumpApp(tester, size: size, storage: st);
    final s = app.services;
    await s.settings.setAdhkarCards(false);
    // Two clips already saved on the phone.
    final m = (await DhikrAudioMap.load(DefaultAssetBundle.of(tester.element(find.byType(MaterialApp)))))!;
    final items = s.adhkar.progress(AdhkarSession.morning).items;
    Directory('${st.path}/dhikr').createSync();
    for (final d in items.take(3)) {
      final u = m.forDhikr(d.index);
      if (u == null) continue;
      File('${st.path}/dhikr/${u.split('/').last}').writeAsBytesSync([0x49, 0x44, 0x33, ...List.filled(20 * 1024, 0)]);
    }
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning, listen: true));
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 50));
    }
    await shot(tester, '01-app-alafasy-in-page');
    await tester.tap(find.byKey(const Key('adhkarAudioClose')));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(const Key('adhkarList')), const Offset(0, -380));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dhikrListen')).first);
    await tester.pumpAndSettle();
    await shot(tester, '02-app-dhikr-player-saved');
    await DhikrPlayer.instance.stop();
    await tester.pumpAndSettle();
  });

  testWidgets('preview: «إعدادات الأذكار» and a chosen background', (tester) async {
    tester.view.devicePixelRatio = 1;
    final app = await pumpApp(tester, size: size);
    final s = app.services;
    await s.settings.setAdhkarCards(true);
    await s.settings.setAdhkarBg('azure');
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    await tester.tap(find.byKey(const Key('adhkarSettings')));
    await tester.pumpAndSettle();
    await shot(tester, '03-app-settings-sheet');
    await tester.tap(find.byKey(const Key('adhkarSettingsClose')));
    await s.settings.setAdhkarBg('sand');
    await s.settings.setAdhkarScale(1.4);
    await s.settings.setAdhkarTashkeel(false);
    await tester.pumpAndSettle();
    await shot(tester, '04-app-sand-big-no-tashkeel');
    await s.settings.setAdhkarBg('');
    await s.settings.setAdhkarScale(1);
    await s.settings.setAdhkarTashkeel(true);
  });

  testWidgets('preview: the celebration after the last dhikr', (tester) async {
    tester.view.devicePixelRatio = 1;
    celebrationVibrate = () async {};
    await pumpApp(tester, size: size);
    unawaited(showAdhkarCelebration(tester.element(find.byType(Navigator).first), 'أتممت أذكار الصباح كلها'));
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }
    await shot(tester, '05-app-celebration');
  });
}
