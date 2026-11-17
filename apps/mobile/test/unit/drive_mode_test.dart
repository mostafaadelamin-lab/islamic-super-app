import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/adhkar_audio_files.dart';
import 'package:rattil/data/audio_focus.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/drive_mode.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/drive_mode.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

class FakeFiles extends AdhkarAudioFiles {
  FakeFiles({this.ok = true}) : super(httpClient: MockHttpClient(), root: () async => Directory.systemTemp);
  bool ok;
  final fetched = <String>[];
  @override
  Future<String?> fetch(String name) async {
    fetched.add(name);
    return ok ? '/x/$name.mp3' : null;
  }
}

/// Clips end when the test says so ([auto]: at once).
class FakePlayer implements DrivePlayer {
  FakePlayer({this.auto = true});
  bool auto;
  String? loaded;
  final played = <DriveClip>[];
  Completer<void>? _c;
  int stops = 0;

  @override
  Future<void> load(String source) async => loaded = source;
  @override
  Future<void> playClip(DriveClip clip) {
    played.add(clip);
    if (auto) return Future<void>.delayed(Duration.zero);
    return (_c = Completer<void>()).future;
  }

  /// The clip playing now ends.
  Future<void> end() async {
    _c?.complete();
    _c = null;
    await pump();
  }

  @override
  Future<void> stop() async {
    stops++;
    _c?.complete();
    _c = null;
  }

  @override
  Future<void> dispose() async {}
}

class FakeCues implements DriveCues {
  final log = <String>[];
  @override
  Future<void> tick() async => log.add('tick');
  @override
  Future<void> done() async => log.add('done');
  @override
  Future<void> say(int n, {required bool arabic}) async => log.add('say $n');
  @override
  Future<void> dispose() async {}
}

Future<void> pump([int times = 20]) async {
  for (var i = 0; i < times; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  late AppContent c;
  late DriveClips clips;
  setUpAll(() async {
    c = await loadContent(realFonts: false);
    clips = DriveClips.fromJson(readAppJson(DriveClips.asset));
  });

  late SettingsController settings;
  late FakeFiles files;
  late FakePlayer player;
  late FakeCues cues;
  late DriveModeController drive;

  setUp(() async {
    AudioFocus.reset();
    SharedPreferences.setMockInitialValues({'locale': 'ar'});
    settings = SettingsController(await SharedPreferences.getInstance());
    await settings.setLocale('ar');
    files = FakeFiles();
    player = FakePlayer();
    cues = FakeCues();
    drive = DriveModeController(
      content: c,
      settings: settings,
      files: files,
      clips: () async => clips,
      player: () => player,
      cues: () => cues,
    );
  });
  tearDown(() => drive.dispose());

  group('clips file (assets/content/adhkar-drive.v1.json)', () {
    test('every morning and evening dhikr the recording reads has a clip, inside the recording', () {
      for (final s in AdhkarSession.values) {
        final sc = clips.sessions[s]!;
        expect(sc.file, s == AdhkarSession.morning ? 'adhkar_morning_alafasy' : 'adhkar_evening_alafasy');
        final plan = drivePlan(c.adhkar, clips, s);
        expect(plan.length, greaterThanOrEqualTo(c.adhkar.forSession(s).length - 2), reason: '$s');
        for (final it in plan) {
          expect(it.clip.start, lessThan(it.clip.end));
          expect(it.clip.length, greaterThan(const Duration(milliseconds: 900)), reason: '${it.dhikr.index}');
          expect(it.clip.length, lessThan(const Duration(seconds: 75)), reason: '${it.dhikr.index}');
          expect(it.clip.end, lessThan(const Duration(minutes: 20)));
        }
        // Clips follow the reading order of the recording and never overlap.
        final sorted = [...plan.where((it) => it.clip.file == null)]..sort((a, b) => a.clip.start.compareTo(b.clip.start));
        for (var i = 1; i < sorted.length; i++) {
          if (sorted[i].clip.start == sorted[i - 1].clip.start) continue; // one reading shared
          expect(sorted[i].clip.start, greaterThanOrEqualTo(sorted[i - 1].clip.end), reason: '${sorted[i].dhikr.index}');
        }
      }
    });

    test('counts come from Hisn al-Muslim, not from the clips file', () {
      final m = drivePlan(c.adhkar, clips, AdhkarSession.morning);
      for (final it in m) {
        expect(it.count, adhkarMeta[it.dhikr.index].count);
      }
      expect(m.where((it) => it.count == 100), isNotEmpty);
      expect(jsonEncode(readAppJson(DriveClips.asset)), isNot(contains('count')));
    });
  });

  test('driveTitle: first words, no diacritics, isti\'adha/basmala skipped, nothing added', () {
    expect(driveTitle('سُبْحَانَ اللَّهِ وَبِحَمْدِهِ.'), 'سبحان الله وبحمده');
    expect(driveTitle('أَعُوذُ بِاللَّهِ مِنَ الشَّيطَانِ الرَّجِيمِ ﴿اللَّهُ لاَ إِلَهَ إِلاَّ هُوَ الْحَيُّ الْقَيُّومُ'), 'الله لا إله إلا هو…');
    expect(driveTitle('بِسْمِ اللهِ الرَّحْمنِ الرَّحِيمِ ﴿قُلْ هُوَ اللَّهُ أَحَدٌ'), 'قل هو الله أحد');
  });

  test('isMilestone: every N, never on the last repetition, off with 0', () {
    expect(isMilestone(10, 100, 10), isTrue);
    expect(isMilestone(15, 100, 10), isFalse);
    expect(isMilestone(100, 100, 10), isFalse);
    expect(isMilestone(33, 100, 33), isTrue);
    expect(isMilestone(10, 100, 0), isFalse);
    expect(isMilestone(3, 3, 10), isFalse);
  });

  test('plays the whole morning session: each clip its Hisn count, ticks between, done sound at the end of each', () async {
    await drive.start(AdhkarSession.morning);
    await pump(4000);
    final plan = drivePlan(c.adhkar, clips, AdhkarSession.morning);
    expect(files.fetched, ['adhkar_morning_alafasy']);
    expect(player.loaded, '/x/adhkar_morning_alafasy.mp3');
    final total = plan.fold<int>(0, (a, it) => a + it.count);
    expect(player.played.length, total);
    expect(cues.log.where((e) => e == 'done').length, plan.length);
    expect(cues.log.where((e) => e == 'tick').length, total - plan.length);
    expect(drive.finished, isTrue);
    expect(drive.isPlaying, isFalse);
  });

  test('spoken count every 10 instead of the tick; no sounds when turned off', () async {
    await settings.setDriveSayEvery(10);
    await settings.setDriveCues(false);
    await drive.start(AdhkarSession.morning);
    await pump(4000);
    expect(cues.log.where((e) => e == 'tick' || e == 'done'), isEmpty);
    expect(cues.log, containsAllInOrder(['say 10', 'say 20', 'say 90']));
    expect(cues.log, isNot(contains('say 100')));
  });

  test('car / lock-screen title shows the dhikr and the live count; next, previous and pause keep the count right', () async {
    player.auto = false;
    final plan = drivePlan(c.adhkar, clips, AdhkarSession.morning);
    final hundred = plan.indexWhere((it) => it.count == 100);
    await drive.start(AdhkarSession.morning);
    await pump();
    expect(drive.isPlaying, isTrue);
    await drive.jumpTo(hundred);
    await pump();
    for (var i = 0; i < 36; i++) {
      await player.end();
    }
    expect(drive.done, 36);
    var now = drive.describe()!;
    expect(now.title, endsWith('· ٣٧ من ١٠٠'));
    expect(now.title, startsWith(driveTitle(plan[hundred].dhikr.text).replaceAll('…', '')));
    expect(now.artist, contains('أذكار الصباح'));
    expect(now.playing, isTrue);

    // Pause and resume: same count, the 37th repetition is said again from its start.
    drive.act('pause');
    await pump();
    expect(drive.isPlaying, isFalse);
    expect(drive.done, 36);
    final before = player.played.length;
    drive.act('play');
    await pump();
    expect(drive.isPlaying, isTrue);
    expect(player.played.length, before + 1);
    expect(drive.describe()!.title, endsWith('٣٧ من ١٠٠'));

    // Previous: this dhikr from the start.
    drive.act('previous');
    await pump();
    expect(drive.index, hundred);
    expect(drive.done, 0);
    // Previous again right away (still on its first repetition): the dhikr before.
    drive.act('previous');
    await pump();
    expect(drive.index, hundred - 1);

    // Next.
    drive.act('next');
    await pump();
    expect(drive.index, hundred);
    expect(drive.done, 0);
    now = drive.describe()!;
    expect(now.title, endsWith('١ من ١٠٠'));
  });

  test('a dhikr said once shows no count in the title', () async {
    player.auto = false;
    await drive.start(AdhkarSession.morning);
    await pump();
    final first = drive.current!;
    expect(first.count, 1);
    expect(drive.describe()!.title, isNot(contains(' من ')));
  });

  test('download failure: failed state, retry works', () async {
    files.ok = false;
    await drive.start(AdhkarSession.evening);
    expect(drive.failed, isTrue);
    expect(drive.describe(), isNull);
    files.ok = true;
    player.auto = false;
    await drive.start(AdhkarSession.evening);
    await pump();
    expect(drive.failed, isFalse);
    expect(drive.isPlaying, isTrue);
  });

  test('another player taking the sound pauses driving mode', () async {
    player.auto = false;
    await drive.start(AdhkarSession.morning);
    await pump();
    AudioFocus.claim(Object());
    await pump();
    expect(drive.isPlaying, isFalse);
  });

  test('Android Auto list: morning and evening, picking one starts it', () async {
    player.auto = false;
    final b = DriveBrowser(drive, settings);
    final root = b.children(AudioService.browsableRootId);
    expect(root.map((e) => e.id), [DriveBrowser.morningId, DriveBrowser.eveningId]);
    expect(root.every((e) => e.playable == true), isTrue);
    expect(b.children(AudioService.recentRootId), isEmpty);
    await b.play(DriveBrowser.eveningId);
    await pump();
    expect(drive.session, AdhkarSession.evening);
    expect(drive.isPlaying, isTrue);
    expect(b.children(AudioService.recentRootId).single.id, DriveBrowser.eveningId);
  });
}
