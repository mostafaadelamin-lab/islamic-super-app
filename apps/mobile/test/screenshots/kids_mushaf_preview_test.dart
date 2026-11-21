// Preview pictures of the interactive kids' teaching Mushaf and the flowing ruqyah verses (owner 2026-11-20),
// iPhone 6.9" size at 2x. Output: $RATTIL_SCREENSHOT_DIR/kids-mushaf, or build/screenshots/kids-mushaf.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/kids.dart';
import 'package:rattil/domain/teacher_timings.dart';
import 'package:rattil/ui/dhikr_audio.dart';
import 'package:rattil/ui/kids_mushaf_screen.dart';
import 'package:rattil/ui/kids_screen.dart';
import 'package:rattil/ui/ruqyah_screen.dart';

import '../helpers.dart';

class _Audio implements UrlAudio {
  final playingC = StreamController<bool>.broadcast();
  final completedC = StreamController<bool>.broadcast();
  final positionC = StreamController<Duration>.broadcast();
  final urls = <String>[];
  final seeks = <Duration>[];

  @override
  Future<void> play(String url) async {
    urls.add(url);
    playingC.add(true);
  }

  @override
  Future<void> pause() async => playingC.add(false);
  @override
  Future<void> resume() async => playingC.add(true);
  @override
  Future<void> seek(Duration d) async => seeks.add(d);
  @override
  Future<void> stop() async => playingC.add(false);
  @override
  Stream<bool> get playing => playingC.stream;
  @override
  Stream<bool> get completed => completedC.stream;
  @override
  Stream<Duration> get position => positionC.stream;
  @override
  Stream<Duration?> get duration => const Stream.empty();
}

void main() {
  setUpAll(loadContent);
  final outDir = Directory('${Platform.environment['RATTIL_SCREENSHOT_DIR'] ?? 'build/screenshots'}/kids-mushaf');
  final kids = KidsContent.parse(File('assets/content/kids.v1.json').readAsStringSync());
  final timings = TeacherTimings.parse(File('../../content/kids/dist/teacher-timings.v1.json').readAsStringSync());

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
  const prefs = {'theme': 'light', 'kidsTeacherStars': '{"112":2,"1":1}'};

  testWidgets('preview: teacher list', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, TeacherMushafScreen(content: kids));
    await tester.pumpAndSettle();
    await shot(tester, '01-teacher-list');
  });

  testWidgets('preview: kids Mushaf reading (al-Ikhlas)', (tester) async {
    tester.view.devicePixelRatio = 1;
    final a = _Audio();
    debugUrlAudioFactory = () => a;
    addTearDown(() => debugUrlAudioFactory = null);
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, KidsMushafScreen(surah: 112, reciters: kids.teacherReciters, loader: () async => timings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kidsMushaf.play')));
    await tester.pump();
    a.positionC.add(const Duration(milliseconds: 1000)); // ayah 1, «ٱللَّهُ»
    await tester.pump();
    await shot(tester, '02-mushaf-reading');
    await tester.tap(find.byKey(const Key('kidsMushaf.bigger')));
    await tester.tap(find.byKey(const Key('kidsMushaf.bigger')));
    await tester.pump();
    await shot(tester, '03-mushaf-big');
  });

  testWidgets('preview: kids Mushaf an-Naba', (tester) async {
    tester.view.devicePixelRatio = 1;
    final a = _Audio();
    debugUrlAudioFactory = () => a;
    addTearDown(() => debugUrlAudioFactory = null);
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, KidsMushafScreen(surah: 78, reciters: kids.teacherReciters, loader: () async => timings));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kidsMushaf.repeat')));
    await tester.tap(find.byKey(const Key('kidsMushaf.play')));
    await tester.pump();
    final w = timings.reciters[kids.teacherReciters.first]!.surahs[78]![5].words[1];
    a.positionC.add(Duration(milliseconds: w.start + 10));
    await tester.pump();
    await shot(tester, '04-mushaf-naba-repeat');
  });

  testWidgets('preview: ruqyah flowing verses', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, RuqyahScreen(kids: true, loader: () async => kids));
    await tester.scrollUntilVisible(find.byKey(const Key('ruqyahFlow-112-1')), 300);
    await tester.drag(find.byKey(const Key('ruqyahKids')), const Offset(0, -100));
    await tester.pumpAndSettle();
    await shot(tester, '05-kids-ruqyah-flow');
    await pushScreen(tester, RuqyahScreen(loader: () async => kids));
    await tester.scrollUntilVisible(find.byKey(const Key('ruqyahFlow-2-255')), 300);
    await tester.pumpAndSettle();
    await shot(tester, '06-ruqyah-flow');
  });

  testWidgets('preview: ruqyah dua counter', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, RuqyahScreen(loader: () async => kids));
    final i = kids.ruqyah.items.indexWhere((x) => x is RuqyahDua && x.repeat > 1);
    await tester.scrollUntilVisible(find.byKey(Key('ruqyah.count.$i')), 300);
    await tester.drag(find.byKey(const Key('ruqyah')), const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('ruqyah.count.$i')));
    await tester.pumpAndSettle();
    await shot(tester, '07-ruqyah-counter');
  });

  testWidgets('preview: prophets stories (drop-down of three series)', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, KidsScreen(loader: () async => kids));
    await tester.tap(find.byKey(const Key('kids.prophets')));
    await tester.pumpAndSettle();
    await shot(tester, '08-prophets-dropdown');
    await tester.tap(find.byKey(const Key('kidsSeries.pick')));
    await tester.pumpAndSettle();
    await shot(tester, '09-prophets-dropdown-open');
    await tester.tap(find.text('قصص الأنبياء: ثلاثي الأبعاد').last);
    await tester.pumpAndSettle();
    await shot(tester, '10-prophets-3d');
  });

  testWidgets('preview: teacher list, whole Quran, and al-Ahzab', (tester) async {
    tester.view.devicePixelRatio = 1;
    await pumpApp(tester, size: size, prefs: prefs, audio: FakeAudioBackend());
    await pushScreen(tester, TeacherMushafScreen(content: kids));
    await tester.pumpAndSettle();
    await shot(tester, '11-teacher-list-all');
    await pushScreen(tester, KidsMushafScreen(surah: 2, reciters: kids.teacherReciters, loader: () async => timings));
    await tester.pumpAndSettle();
    await shot(tester, '12-mushaf-baqarah');
  });
}
