import 'dart:convert';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/audio_focus.dart';
import 'package:rattil/data/car_browser.dart';
import 'package:rattil/data/carplay.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/drive_mode.dart';
import 'package:rattil/data/mp3quran.dart';
import 'package:rattil/data/recitation.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/drive_mode.dart';
import 'package:rattil/domain/kids.dart';
import 'package:rattil/domain/lessons.dart';
import 'package:rattil/domain/teacher_timings.dart';
import 'package:rattil/domain/nasheeds.dart' show Munshid;
import 'package:rattil/domain/radios.dart';
import 'package:rattil/domain/sharawi.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';
import 'drive_mode_test.dart' show FakeCues, FakeFiles, FakePlayer, pump;

const _reciters = {
  'reciters': [
    {
      'id': 153,
      'name': 'أخيل عبدالحي روا',
      'moshaf': [
        {
          'id': 153,
          'name': 'حفص عن عاصم - مرتل',
          'rewaya_id': 1,
          'server': 'https://cdn.mp3quran.net/audio/akhil-rawa/r1/',
          'surah_list': '50,51,52,56',
        },
      ],
    },
    {
      'id': 7,
      'name': 'إبراهيم الأخضر',
      'moshaf': [
        {
          'id': 7,
          'name': 'حفص عن عاصم - مرتل',
          'rewaya_id': 1,
          'server': 'https://server6.mp3quran.net/akdr',
          'surah_list': '1,2,114',
        },
      ],
    },
    {
      'id': 8,
      'name': 'ورش فقط',
      'moshaf': [
        {
          'id': 80,
          'name': 'ورش عن نافع',
          'rewaya_id': 2,
          'server': 'https://cdn.mp3quran.net/warsh/',
          'surah_list': '1',
        },
      ],
    },
  ],
};

http.Client _api() => MockClient((req) async {
  final body = switch (req.url.pathSegments.last) {
    'reciters' => _reciters,
    'riwayat' => {'riwayat': []},
    'radios' => {'radios': []},
    _ => null,
  };
  if (body == null) return http.Response('', 404);
  return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
});

void main() {
  late AppContent c;
  late DriveClips clips;
  setUpAll(() async {
    c = await loadContent(realFonts: false);
    clips = DriveClips.fromJson(readAppJson(DriveClips.asset));
  });

  late SettingsController settings;
  late DriveModeController drive;
  late FakePlayer player;
  late FakeFiles files;
  late FakeNarrationBackend voice;
  late NarrationController narration;
  late CarBrowser car;
  late RecitationController rec;

  setUp(() async {
    AudioFocus.reset();
    SharedPreferences.setMockInitialValues({'locale': 'ar'});
    final prefs = await SharedPreferences.getInstance();
    settings = SettingsController(prefs);
    player = FakePlayer(auto: false);
    files = FakeFiles();
    drive = DriveModeController(
      content: c,
      settings: settings,
      files: files,
      clips: () async => clips,
      player: () => player,
      cues: FakeCues.new,
    );
    voice = FakeNarrationBackend();
    rec = RecitationController(content: c, settings: settings, backendFactory: FakeAudioBackend.new);
    narration = NarrationController(settings: settings, recitation: rec, backendFactory: () => voice);
    car = CarBrowser(
      drive: drive,
      narration: narration,
      settings: settings,
      content: c,
      library: Mp3QuranClient(httpClient: _api(), prefs: prefs),
      nasheeds: () async => Munshid.parse(File('assets/content/nasheeds.v2.json').readAsStringSync()),
      sharawi: () async => SharawiTafsir.parse(File('assets/content/sharawi.v1.json').readAsStringSync()),
      lessons: () async => LessonCatalog.parse(File('assets/content/lessons.v1.json').readAsStringSync()),
      kids: () async => KidsContent.parse(File('assets/content/kids.v1.json').readAsStringSync()),
      teacher: (n) async => TeacherTimings.parse(File(TeacherTimings.assetFor(n)).readAsStringSync()),
      recitation: rec,
    );
  });
  tearDown(() => drive.dispose());

  test('first list: adhkar, radio, library, Sha\'rawi, «افهم دينك», «علّم طفلك», nasheeds', () async {
    final root = await car.children(AudioService.browsableRootId);
    expect(root.map((e) => e.id), [
      DriveBrowser.morningId,
      DriveBrowser.eveningId,
      CarBrowser.radioId,
      CarBrowser.libraryId,
      CarBrowser.sharawiId,
      CarBrowser.afhamId,
      CarBrowser.kidsId,
      CarBrowser.nasheedsId,
    ]);
    expect(root.map((e) => e.title), [
      'أذكار الصباح',
      'أذكار المساء',
      'إذاعات متنوعة',
      'مكتبة التلاوات',
      'مكتبة دروس الشيخ الشعراوي',
      'افهم دينك',
      'علّم طفلك',
      'الأناشيد',
    ]);
    expect(root.take(2).every((e) => e.playable == true), isTrue);
    expect(root.skip(2).every((e) => e.playable == false), isTrue);
  });

  test('radio: the live stations, picking one plays it live', () async {
    final list = await car.children(CarBrowser.radioId);
    expect(list.map((e) => e.title), [for (final r in featuredRadios) r.nameAr]);
    await car.play(list.first.id);
    expect(narration.seriesId, 'radio');
    expect(narration.episode!.id, featuredRadios.first.id);
    expect(narration.isLive, isTrue);
    expect(voice.loaded.single, featuredRadios.first.url);
    expect(car.failed, isFalse);
  });

  test('library: Hafs reciters in name order, a reciter\'s surahs, a surah plays on to the next', () async {
    final reciters = await car.children(CarBrowser.libraryId);
    expect(reciters.map((e) => e.title), ['أخيل عبدالحي روا', 'إبراهيم الأخضر']);
    expect(reciters.every((e) => e.playable == false), isTrue);
    expect(reciters.map((e) => e.extras!['section']), ['ا', 'ا']);
    final surahs = await car.children('${CarBrowser.libraryId}/7');
    expect(surahs.map((e) => e.title), ['١. الفاتحة', '٢. البقرة', '١١٤. الناس']);
    await car.play(surahs[1].id);
    expect(narration.seriesId, 'mp3quran-7');
    expect(narration.episode!.id, 's2');
    expect(narration.playlist.map((e) => e.id), ['s1', 's2', 's114']);
    expect(voice.loaded.single, 'https://server6.mp3quran.net/akdr/002.mp3');
  });

  test('al-Sha\'rawi: his seerah and prophets\' stories first, then the tafsir surah by surah', () async {
    final list = await car.children(CarBrowser.sharawiId);
    expect(list.take(2).map((e) => e.title), ['السيرة النبوية', 'قصص الأنبياء']);
    expect(list.take(2).every((e) => e.playable == false), isTrue);
    final fatiha = list.firstWhere((e) => e.id == '${CarBrowser.sharawiId}/1');
    expect(fatiha.title, 'الفاتحة');
    expect(fatiha.extras!['section'], 'تفسير القرآن');
    final lessons = await car.children(fatiha.id);
    expect(lessons.first.title, 'الدرس ١');
    await car.play(lessons.first.id);
    expect(narration.seriesId, 'sharawi');
    expect(narration.episode!.id, 'sharawi-${lessons.first.id.split('/').last}');
    expect(narration.playlist, hasLength(lessons.length));

    // The seerah: its lessons, played with the lessons screen's ids.
    final seerah = await car.children(list.first.id);
    expect(seerah.length, greaterThan(100));
    await car.play(seerah[1].id);
    expect(narration.seriesId, 'lessons-seerah-shaarawi');
    expect(narration.episode!.id, 'seerah-shaarawi-2');
    expect(narration.playlist, hasLength(seerah.length));
  });

  test('«افهم دينك»: every topic, its series, their lessons; Abdelkafy\'s «أحسن القصص» is in it', () async {
    final catalog = LessonCatalog.parse(File('assets/content/lessons.v1.json').readAsStringSync());
    final topics = await car.children(CarBrowser.afhamId);
    expect(topics, hasLength(catalog.topics.length));
    final stories = topics.firstWhere((e) => e.title == 'الأنبياء والصحابة والقصص');
    final series = await car.children(stories.id);
    final qasas = series.firstWhere((e) => e.title == 'أحسن القصص');
    expect(qasas.artist, contains('عبد الكافي'));
    final eps = await car.children(qasas.id);
    expect(eps, hasLength(14));
    await car.play(eps.first.id);
    expect(narration.seriesId, startsWith('lessons-'));
    expect(narration.hasNext, isTrue);
    // Every series of the lessons list is reachable (al-Sha'rawi's tafsir is in his own section).
    var count = 0;
    for (final t in topics) {
      count += (await car.children(t.id)).length;
    }
    expect(count, catalog.listed.where((s) => !s.isSharawiTafsir).length);
  });

  test('«علّم طفلك»: teaching Mushaf, the audio stories and the ruqyah', () async {
    final list = await car.children(CarBrowser.kidsId);
    expect(list.map((e) => e.title), [
      'المصحف المعلّم للأطفال',
      'قصص الأنبياء: الحلقات الكاملة',
      'قصص الرسول ﷺ للأطفال',
      'قصص قصيرة هادفة',
      'الرقية الشرعية للأطفال',
    ]);
    final surahs = await car.children(CarBrowser.teacherId);
    expect(surahs.first.title, '١. الفاتحة');
    await car.play(surahs.first.id);
    expect(narration.seriesId, 'kids-teacher');
    expect(narration.playlist, hasLength(surahs.length));

    final rasoul = await car.children(list[2].id);
    expect(rasoul, hasLength(17));
    await car.play(rasoul.first.id);
    expect(narration.seriesId, 'kids-rasoul');

    await car.play(list.last.id);
    expect(rec.current, isNotNull);
  });

  test('nasheeds: munshids, then their nasheeds', () async {
    final singers = await car.children(CarBrowser.nasheedsId);
    expect(singers, isNotEmpty);
    final list = await car.children(singers.first.id);
    expect(list, isNotEmpty);
    await car.play(list.first.id);
    expect(narration.seriesId, 'nasheeds');
    expect(narration.episode!.id, startsWith('nasheed-'));
  });

  test('a failed stream is reported to the car', () async {
    voice.failNext = true;
    final list = await car.children(CarBrowser.radioId);
    await car.play(list.first.id);
    expect(car.failed, isTrue);
  });

  test('CarPlay: first list with sections, opening a section, the dhikr text button only in driving mode', () async {
    const channel = MethodChannel(CarPlayBridge.channelName);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final sent = <String, List<Map<Object?, Object?>>>{};
    messenger.setMockMethodCallHandler(channel, (call) async {
      sent.putIfAbsent(call.method, () => []).add(call.arguments as Map<Object?, Object?>);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    Future<Object?> fromCar(String method, [Object? args]) async {
      Object? reply;
      await messenger.handlePlatformMessage(
        CarPlayBridge.channelName,
        const StandardMethodCodec().encodeMethodCall(MethodCall(method, args)),
        (data) => reply = data == null ? null : const StandardMethodCodec().decodeEnvelope(data),
      );
      return reply;
    }

    final bridge = CarPlayBridge(car, settings);
    addTearDown(bridge.dispose);
    await pump();
    final root = (sent['items']!.single['items']! as List).cast<Map<Object?, Object?>>();
    expect(root, hasLength(8));
    expect(root.map((e) => e['browsable']), [false, false, true, true, true, true, true, true]);
    expect(sent['textButton']!.last, {'title': 'نص الذكر', 'on': false});

    final radio = (await fromCar('children', CarBrowser.radioId))! as Map;
    expect((radio['items']! as List), hasLength(featuredRadios.length));

    // Driving mode on: the button turns on and gives the whole dhikr in lines.
    expect(await fromCar('play', DriveBrowser.morningId), isNull);
    await pump();
    expect(drive.isPlaying, isTrue);
    expect(sent['textButton']!.last['on'], isTrue);
    final text = (await fromCar('text'))! as Map;
    final lines = (text['lines']! as List).cast<String>();
    expect(lines.join(' '), drive.current!.dhikr.text.trim().replaceAll(RegExp(r'\s+'), ' '));
    await drive.stop();
    expect(sent['textButton']!.last['on'], isFalse);

    // A failed download: the car shows the message.
    files.ok = false;
    expect(await fromCar('play', DriveBrowser.eveningId), contains('تعذّر'));
  });

  test('the text parts keep every word and fit the car title', () {
    const t =
        'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ';
    final parts = driveParts(t);
    expect(parts.join(' '), t);
    expect(parts.length, greaterThan(1));
    for (final p in parts) {
      expect(p.replaceAll(RegExp('[ؐ-ًؚ-ٰٟۖ-ۭـ]'), '').length, lessThanOrEqualTo(46));
    }
    expect(drivePartAt(parts, 0), 0);
    expect(drivePartAt(parts, 0.99), parts.length - 1);
    expect(drivePartTitle(parts, 0), endsWith(' …'));
    expect(drivePartTitle(parts, parts.length - 1), parts.last);
    expect(AdhkarSession.values, isNotEmpty);
  });
}
