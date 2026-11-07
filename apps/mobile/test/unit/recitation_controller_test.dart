import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/recitation.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/domain/audio_queue.dart';
import 'package:rattil/domain/quran.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  late FakeAudioBackend audio;
  late SettingsController settings;
  late RecitationController rec;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsController(await SharedPreferences.getInstance());
    audio = FakeAudioBackend();
    rec = RecitationController(content: c, settings: settings, backendFactory: () => audio);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);
  String file(String url) => url.split('/').last;

  test('plays the basmala (001001) before 2:1, highlighting 2:1, then 2:1', () async {
    await rec.playFrom(const AyahRef(2, 1), scope: PlayScope.surah);
    expect(rec.state, RecitationState.playing);
    expect(file(audio.loaded.last), '001001.mp3');
    expect(rec.current!.isBasmala, isTrue);
    expect(rec.currentRef, const AyahRef(2, 1));
    audio.finish();
    await settle();
    expect(file(audio.loaded.last), '002001.mp3');
    expect(rec.current!.isBasmala, isFalse);
    audio.finish();
    await settle();
    expect(file(audio.loaded.last), '002002.mp3');
  });

  test('continues across pages: page 2 ends with 2:5, then 2:6 on page 3', () async {
    expect(c.quran.page(2).end, const AyahRef(2, 5));
    await rec.playFrom(const AyahRef(2, 5));
    expect(rec.currentPage, 2);
    final pages = <int?>[];
    rec.addListener(() => pages.add(rec.currentPage));
    audio.finish();
    await settle();
    expect(rec.currentRef, const AyahRef(2, 6));
    expect(rec.currentPage, 3);
    expect(pages, contains(3));
    expect(file(audio.loaded.last), '002006.mp3');
  });

  test('page scope stops at the end of the page', () async {
    await rec.playPage(604);
    final n = rec.queue.length;
    expect(rec.queue.last.ref, const AyahRef(114, 6));
    for (var i = 0; i < n; i++) {
      audio.finish();
      await settle();
    }
    expect(rec.state, RecitationState.idle);
    expect(rec.currentRef, isNull);
  });

  test('surah scope plays the whole surah (al-Ikhlas: basmala + 4 ayahs)', () async {
    await rec.playSurah(112);
    expect(rec.queue.map((e) => e.toString()), ['basmala→112:1', '112:1', '112:2', '112:3', '112:4']);
  });

  test('chosen reciter and repeat count are used', () async {
    await settings.setReciter('Husary_128kbps');
    await settings.setRepeat(2);
    await rec.playFrom(const AyahRef(1, 1), scope: PlayScope.ayah);
    expect(audio.loaded.single, 'https://everyayah.com/data/Husary_128kbps/001001.mp3');
    audio.finish();
    await settle();
    expect(audio.loaded, hasLength(2), reason: 'played twice');
    expect(rec.state, RecitationState.playing);
    audio.finish();
    await settle();
    expect(rec.state, RecitationState.idle);
  });

  test('offline: a failed load is an error state; resume retries the same ayah', () async {
    audio.failNext = true;
    await rec.playFrom(const AyahRef(36, 5));
    expect(rec.state, RecitationState.error);
    expect(rec.currentRef, const AyahRef(36, 5));
    await rec.resume();
    expect(rec.state, RecitationState.playing);
    expect(file(audio.loaded.last), '036005.mp3');
  });

  test('pause / resume / next / previous / stop', () async {
    await settings.setRepeat(2);
    await rec.playFrom(const AyahRef(1, 2));
    await rec.pause();
    expect(rec.state, RecitationState.paused);
    audio.finish(); // a stray completion while paused is ignored
    await settle();
    expect(rec.index, 0);
    await rec.resume();
    expect(rec.state, RecitationState.playing);
    await rec.next();
    expect(rec.currentRef, const AyahRef(1, 3), reason: 'skips the remaining repeat of 1:2');
    await rec.previous();
    expect(rec.currentRef, const AyahRef(1, 2));
    expect(rec.index, 0);
    await rec.stop();
    expect(rec.state, RecitationState.idle);
    expect(audio.calls.last, 'stop');
  });
}
