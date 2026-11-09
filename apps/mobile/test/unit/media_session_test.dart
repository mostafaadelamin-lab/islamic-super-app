import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/media_session.dart';
import 'package:rattil/data/recitation.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/domain/audio_queue.dart';
import 'package:rattil/domain/quran.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

class RecordingSession implements MediaSession {
  final shown = <NowPlaying?>[];
  void Function(String action)? press;
  @override
  void bind(void Function(String action) onAction) => press = onAction;
  @override
  void show(NowPlaying? now) => shown.add(now);
}

void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  late FakeAudioBackend audio;
  late SettingsController settings;
  late RecitationController rec;
  late RecordingSession session;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsController(await SharedPreferences.getInstance());
    audio = FakeAudioBackend();
    rec = RecitationController(content: c, settings: settings, backendFactory: () => audio);
    session = RecordingSession();
    RecitationMediaBridge(recitation: rec, content: c, settings: settings, session: session);
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('shows the surah, ayah and reciter on the lock screen and follows the player', () async {
    await rec.playFrom(const AyahRef(114, 2), scope: PlayScope.surah);
    final now = session.shown.last!;
    expect(now.title, 'الناس ٢');
    expect(now.artist, rec.reciter.nameAr);
    expect(now.playing, isTrue);
    audio.finish();
    await settle();
    expect(session.shown.last!.title, 'الناس ٣');
    await rec.pause();
    expect(session.shown.last!.playing, isFalse);
    await rec.stop();
    expect(session.shown.last, isNull);
  });

  test('English titles use the transliterated surah name', () async {
    await settings.setLocale('en');
    await rec.playFrom(const AyahRef(1, 2), scope: PlayScope.ayah);
    expect(session.shown.last!.title, 'Al-Fatihah 2');
    expect(session.shown.last!.artist, rec.reciter.nameEn);
  });

  test('lock-screen buttons drive the player', () async {
    await rec.playFrom(const AyahRef(114, 2), scope: PlayScope.surah);
    session.press!('pause');
    await settle();
    expect(rec.state, RecitationState.paused);
    session.press!('play');
    await settle();
    expect(rec.state, RecitationState.playing);
    session.press!('next');
    await settle();
    expect(rec.currentRef, const AyahRef(114, 3));
    session.press!('previous');
    await settle();
    expect(rec.currentRef, const AyahRef(114, 2));
    session.press!('stop');
    await settle();
    expect(rec.isActive, isFalse);
  });
}
