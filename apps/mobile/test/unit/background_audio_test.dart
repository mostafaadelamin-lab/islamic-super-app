import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/media_session.dart';
import 'package:rattil/data/recitation.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/domain/audio_queue.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/stories.dart';
import 'package:rattil/ui/background_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

class RecordingSession implements MediaSession {
  final shown = <NowPlaying?>[];
  void Function(String action)? press;
  void Function(Duration to)? seek;
  @override
  void bind(void Function(String action) onAction, {void Function(Duration to)? onSeek}) {
    press = onAction;
    seek = onSeek;
  }

  @override
  void show(NowPlaying? now) => shown.add(now);
}

Episode ep(String id) =>
    Episode(id: id, titleAr: 'سورة $id', titleEn: 'Surah $id', url: 'https://x/$id.mp3', status: ReviewStatus.approved);

/// Owner, 2026-11-12: radio and recitation stopped seconds after leaving the app, and
/// the recitation must go on to the next page / surah by itself.
void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  late FakeAudioBackend audio;
  late FakeNarrationBackend voice;
  late SettingsController settings;
  late RecitationController rec;
  late NarrationController narration;
  late RecordingSession session;
  late RecitationMediaBridge bridge;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsController(await SharedPreferences.getInstance());
    audio = FakeAudioBackend();
    voice = FakeNarrationBackend();
    rec = RecitationController(content: c, settings: settings, backendFactory: () => audio);
    narration = NarrationController(settings: settings, recitation: rec, backendFactory: () => voice);
    session = RecordingSession();
    bridge = RecitationMediaBridge(
      recitation: rec,
      content: c,
      settings: settings,
      session: session,
      narration: narration,
    );
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('the reader goes on past the end of the page to the next pages', () async {
    await rec.playOnFrom(604);
    expect(rec.scope, PlayScope.toEnd);
    await rec.playOnFrom(1);
    // al-Fatihah (page 1) is followed by al-Baqarah on page 2.
    while (rec.currentRef!.surah == 1) {
      audio.finish();
      await settle();
    }
    expect(rec.isActive, isTrue);
    expect(rec.currentPage, 2);
  });

  test('ayahs follow each other without stopping the player in between', () async {
    await rec.playFrom(const AyahRef(114, 2), scope: PlayScope.surah);
    audio.calls.clear();
    audio.finish();
    await settle();
    expect(audio.calls, isNot(contains('stop')));
    expect(rec.currentRef, const AyahRef(114, 3));
  });

  test('a live radio station shows on the lock screen and notification, without skip buttons', () async {
    await narration.playEpisode('radio', ep('cairo'), remember: false);
    final now = session.shown.last!;
    expect(now.title, 'سورة cairo');
    expect(now.playing, isTrue);
    expect(now.canSkip, isFalse);
    session.press!('pause');
    await settle();
    expect(narration.state, RecitationState.paused);
    expect(session.shown.last!.playing, isFalse);
    session.press!('play');
    await settle();
    expect(narration.isPlaying, isTrue);
    session.press!('stop');
    await settle();
    expect(narration.isActive, isFalse);
    expect(session.shown.last, isNull);
  });

  test('a surah of the recitation library goes on to the next surah by itself', () async {
    final list = [ep('s1'), ep('s2'), ep('s3')];
    await narration.playEpisode('mp3quran-1', list[0], playlist: list);
    expect(session.shown.last!.canSkip, isTrue);
    voice.finish();
    await settle();
    await settle();
    expect(narration.episode!.id, 's2');
    expect(narration.isPlaying, isTrue);
    expect(voice.loaded.last, 'https://x/s2.mp3');
    session.press!('next');
    await settle();
    await settle();
    expect(narration.episode!.id, 's3');
    voice.finish();
    await settle();
    expect(narration.state, RecitationState.paused, reason: 'the last one ends the list');
  });

  test('going on to the next item starts it from the beginning', () async {
    final list = [ep('a'), ep('b')];
    await settings.setStoryPosition('lessons/b', 600);
    await narration.playEpisode('lessons', list[0], playlist: list);
    voice.finish();
    await settle();
    await settle();
    expect(narration.episode!.id, 'b');
    expect(voice.calls, isNot(contains('seek:600')));
  });

  test('the player in use owns the controls: starting the recitation takes them from the radio', () async {
    await narration.playEpisode('radio', ep('cairo'), remember: false);
    await rec.playFrom(const AyahRef(114, 1), scope: PlayScope.surah);
    expect(session.shown.last!.title, contains('الناس'));
    session.press!('pause');
    await settle();
    expect(rec.state, RecitationState.paused);
  });

  test('other players (adhkar recordings) can join the controls', () async {
    final pressed = <String>[];
    final src = SimpleMediaSource(id: 'adhkar/m', title: 'أذكار الصباح', artist: 'العفاسي', onAction: pressed.add);
    bridge.attach(src);
    src.playing = true;
    expect(session.shown.last!.title, 'أذكار الصباح');
    session.press!('pause');
    expect(pressed, ['pause']);
    src.loaded = false;
    bridge.detach(src);
    expect(session.shown.last, isNull);
  });

  /// Owner, 2026-11-15: the lock screen showed 00:00 / 00:00 while a surah from the library played.
  test('the lock screen gets the length, the position and a working seek bar', () async {
    var now = DateTime(2026, 11, 15, 12);
    bridge.clock = () => now;
    await narration.playEpisode('mp3quran-1', ep('2'));
    await settle();
    expect(session.shown.last!.duration, const Duration(minutes: 25));
    final shownBefore = session.shown.length;
    // Normal playback: the system moves its own bar, nothing new is sent.
    now = now.add(const Duration(seconds: 1));
    voice.emit(const Duration(seconds: 1));
    await settle();
    now = now.add(const Duration(seconds: 1));
    voice.emit(const Duration(seconds: 2));
    await settle();
    expect(session.shown.length, shownBefore);
    // A jump (+30 s) is sent with the new position.
    await narration.seekBy(const Duration(seconds: 30));
    await settle();
    expect(session.shown.length, shownBefore + 1);
    expect(session.shown.last!.position, const Duration(seconds: 32));
    // Dragging the lock-screen bar seeks the player.
    session.seek!(const Duration(minutes: 10));
    await settle();
    expect(voice.calls.last, 'seek:600');
    expect(narration.position, const Duration(minutes: 10));
  });

  test('live radio has no length or seek bar on the lock screen', () async {
    await narration.playEpisode('radio', ep('cairo'), remember: false);
    await settle();
    expect(session.shown.last!.duration, isNull);
  });
}
