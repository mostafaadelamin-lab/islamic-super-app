import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/domain/kids.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/teacher_timings.dart';
import 'package:rattil/ui/dhikr_audio.dart';
import 'package:rattil/ui/kids_mushaf_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late AppContent content;
  setUpAll(() async => content = await loadContent());
  final timings = TeacherTimings.parse(File('assets/content/teacher-timings.v1.json').readAsStringSync());
  final kids = KidsContent.parse(File('assets/content/kids.v1.json').readAsStringSync());

  test('teacher timings: every teaching surah, every ayah, word tokens inside the KFGQPC text', () {
    final q = content.quran;
    for (final r in kids.teacherReciters) {
      final rec = timings.reciters[r]!;
      for (final s in kids.teacherSurahs) {
        final ay = rec.surahs[s]!;
        expect(ay.length, q.surah(s).ayahCount, reason: '$r $s');
        for (var a = 0; a < ay.length; a++) {
          final text = q.text(AyahRef(s, a + 1));
          final tk = ayahTokens(text);
          // joining the tokens gives the Mushaf text back, unchanged
          final joined = StringBuffer();
          for (var k = 0; k < tk.words.length; k++) {
            joined.write(tk.words[k]);
            if (k < tk.gaps.length) joined.write(tk.gaps[k]);
          }
          expect(joined.toString(), text);
          expect(ay[a].words, isNotEmpty, reason: '$r $s:${a + 1}');
          for (final w in ay[a].words) {
            expect(w.token, inInclusiveRange(0, tk.words.length - 1), reason: '$r $s:${a + 1}');
            expect(w.start, greaterThanOrEqualTo(ay[a].start));
            expect(w.end, lessThanOrEqualTo(ay[a].end));
          }
        }
      }
    }
    expect(timings.reciters['Husary_Muallim_128kbps']!.at(112, 1000), (ayah: 0, word: 2));
    expect(timings.wordAudio(112, 1, 3), 'https://audio.qurancdn.com/wbw/112_001_003.mp3');
  });

  test('Quran.com word numbers skip the rub el-hizb sign', () {
    final w = ayahTokens(content.quran.text(const AyahRef(100, 9))).words;
    expect(w.first, '۞');
    expect(quranComWord(w, 0), isNull);
    expect(quranComWord(w, 1), 1);
    expect(quranComWord(w, w.length - 1), w.length - 1);
  });

  testWidgets('kids Mushaf: plays the surah recording, an ayah alone, and a full listen earns a star', (tester) async {
    final audios = <_Audio>[];
    debugUrlAudioFactory = () => audios.last;
    addTearDown(() => debugUrlAudioFactory = null);
    audios.add(_Audio());
    SharedPreferences.setMockInitialValues({});
    await pumpApp(tester, size: tallPhone);
    await pushScreen(
      tester,
      KidsMushafScreen(surah: 112, reciters: kids.teacherReciters, loader: () async => timings),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kidsMushaf.text')), findsOneWidget);
    final rec = audios.last;
    await tester.tap(find.byKey(const Key('kidsMushaf.play')));
    await tester.pump();
    expect(rec.urls.single, 'https://download.quranicaudio.com/qdc/siddiq_minshawi/kids_repeat/112.mp3');
    expect(rec.seeks.last, Duration.zero);
    rec.positionC.add(const Duration(milliseconds: 1000));
    await tester.pump();
    rec.completedC.add(true);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kidsMushaf.cheer')), findsOneWidget);
    expect(await readTeacherStars(), {'112': 1});
    // the next ayah button starts the recording at ayah 1 again after the end
    await tester.tap(find.byKey(const Key('kidsMushaf.next')));
    await tester.pump();
    expect(rec.seeks.last, Duration(milliseconds: timings.reciters['Minshawy_Teacher_128kbps']!.surahs[112]![0].start));
  });
}
