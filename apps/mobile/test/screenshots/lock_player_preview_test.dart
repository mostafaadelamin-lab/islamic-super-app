// Preview pictures of the one player look (owner 2026-11-22): right under the item playing,
// with the time and a seek bar like the lock screen; names of Allah play under the name.
// Output: $RATTIL_SCREENSHOT_DIR/lock-player, or build/screenshots/lock-player.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/sharawi.dart';
import 'package:rattil/ui/asma_screen.dart';
import 'package:rattil/ui/dhikr_audio.dart';
import 'package:rattil/ui/sharawi_screen.dart';

import '../helpers.dart';

class _Url implements UrlAudio {
  final _playing = StreamController<bool>.broadcast();
  final _pos = StreamController<Duration>.broadcast();
  final _dur = StreamController<Duration?>.broadcast();
  @override
  Future<void> play(String url) async {
    _playing.add(true);
    _dur.add(const Duration(minutes: 41, seconds: 12));
    _pos.add(const Duration(minutes: 6, seconds: 35));
  }

  @override
  Future<void> pause() async => _playing.add(false);
  @override
  Future<void> resume() async => _playing.add(true);
  @override
  Future<void> seek(Duration d) async => _pos.add(d);
  @override
  Future<void> stop() async => _playing.add(false);
  @override
  Stream<bool> get playing => _playing.stream;
  @override
  Stream<bool> get completed => const Stream.empty();
  @override
  Stream<Duration> get position => _pos.stream;
  @override
  Stream<Duration?> get duration => _dur.stream;
}

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/lock-player');

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

  testWidgets('app: al-Sha\'rawi lesson playing, player under it', (tester) async {
    tester.view.devicePixelRatio = 1;
    final backend = FakeNarrationBackend(length: null);
    await pumpApp(tester, size: const Size(440, 956), narration: backend);
    final data = SharawiTafsir.parse(File('assets/content/sharawi.v1.json').readAsStringSync());
    final fatiha = data.bySurah(1)!;
    await pushScreen(tester, SharawiSurahScreen(surah: fatiha));
    await tester.tap(find.byKey(Key('sharawi-${fatiha.lessons[1].id}')));
    await tester.pumpAndSettle();
    backend.emit(const Duration(minutes: 7, seconds: 48));
    await tester.pumpAndSettle();
    await shot(tester, '01-app-sharawi-lesson');
  });

  testWidgets('app: names of Allah, the explanation plays under the name', (tester) async {
    tester.view.devicePixelRatio = 1;
    debugUrlAudioFactory = _Url.new;
    addTearDown(() => debugUrlAudioFactory = null);
    await pumpApp(tester, size: const Size(440, 956));
    final names = AsmaEntry.parse(File('assets/content/asma.v1.json').readAsStringSync());
    final j = jsonDecode(File('assets/content/asma-audio.v1.json').readAsStringSync()) as Map<String, dynamic>;
    final lessons = {
      for (final e in (j['names'] as Map<String, dynamic>).entries)
        int.parse(e.key): (e.value as List<dynamic>).cast<String>(),
    };
    await pushScreen(tester, AsmaScreen(loader: () async => names, lessons: () async => lessons));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('asmaListen-0')));
    await tester.pumpAndSettle();
    await shot(tester, '02-app-asma-inline');
    await DhikrPlayer.instance.stop();
  });
}
