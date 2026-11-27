// The app's lists on the car screen (Android Auto and CarPlay): the morning / evening adhkar
// in driving mode first, then the listening sections the owner asked for (2026-11-23, 2026-11-25):
// radio, the recitation library, al-Sha'rawi's whole library, «افهم دينك» (every lesson series),
// «علّم طفلك» (what children can listen to) and nasheeds.
//
// Picking an item plays it through the same players as the phone screens (driving mode, or the
// narration player with the same series and episode ids, so saved copies and the place where the
// listener stopped are used), and the car switches to its Now Playing screen.

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../domain/kids.dart';
import '../domain/lessons.dart';
import '../domain/mp3quran.dart';
import '../domain/nasheeds.dart' show Munshid, Nasheed;
import '../domain/radios.dart';
import '../domain/sharawi.dart';
import '../domain/stories.dart';
import '../domain/teacher_timings.dart';
import '../domain/text.dart';
import '../l10n/app_localizations.dart';
import 'content.dart';
import 'drive_mode.dart';
import 'media_session.dart';
import 'mp3quran.dart';
import 'recitation.dart';
import 'settings.dart';

/// mp3quran riwaya id of Hafs from Asim: the car's library lists the Hafs recordings.
const _hafs = 1;

class CarBrowser implements MediaBrowser {
  CarBrowser({
    required this.drive,
    required this.narration,
    required this.settings,
    required this.content,
    required this.library,
    this.recitation,
    Future<List<Munshid>> Function()? nasheeds,
    Future<SharawiTafsir> Function()? sharawi,
    Future<LessonCatalog> Function()? lessons,
    Future<KidsContent> Function()? kids,
    Future<TeacherTimings> Function(int surah)? teacher,
  }) : _drive = DriveBrowser(drive, settings),
       _loadNasheeds = nasheeds ?? _assetNasheeds,
       _loadSharawi = sharawi ?? _assetSharawi,
       _loadLessons = lessons ?? _assetLessons,
       _loadKids = kids ?? _assetKids,
       _loadTeacher = teacher ?? _assetTeacher;

  final DriveModeController drive;
  final NarrationController narration;

  /// Plays the Quran passages of the children's ruqyah. Null: that row is left out.
  final RecitationController? recitation;
  final SettingsController settings;
  final AppContent content;

  /// The recitation library (mp3quran.net, cached on the phone). Null: the section is left out.
  final Mp3QuranClient? library;
  final DriveBrowser _drive;
  final Future<List<Munshid>> Function() _loadNasheeds;
  final Future<SharawiTafsir> Function() _loadSharawi;
  final Future<LessonCatalog> Function() _loadLessons;
  final Future<KidsContent> Function() _loadKids;
  final Future<TeacherTimings> Function(int surah) _loadTeacher;
  Future<List<Munshid>>? _nasheeds;
  Future<SharawiTafsir>? _sharawi;
  Future<LessonCatalog>? _lessons;
  Future<KidsContent>? _kids;

  static Future<List<Munshid>> _assetNasheeds() async =>
      Munshid.parse(await rootBundle.loadString('assets/content/nasheeds.v2.json'));
  static Future<SharawiTafsir> _assetSharawi() async =>
      SharawiTafsir.parse(await rootBundle.loadString('assets/content/sharawi.v1.json'));

  static Future<LessonCatalog> _assetLessons() async =>
      LessonCatalog.parse(await rootBundle.loadString('assets/content/lessons.v1.json'));
  static Future<KidsContent> _assetKids() async =>
      KidsContent.parse(await rootBundle.loadString('assets/content/kids.v1.json'));
  static Future<TeacherTimings> _assetTeacher(int surah) async =>
      TeacherTimings.parse(await rootBundle.loadString(TeacherTimings.assetFor(surah)));

  static const radioId = 'car/radio';
  static const libraryId = 'car/lib';
  static const sharawiId = 'car/sharawi';
  static const afhamId = 'car/afham';
  static const lessonsId = 'car/ls';
  static const kidsId = 'car/kids';
  static const teacherId = 'car/kids/teacher';
  static const kidsSeriesId = 'car/kids/s';
  static const kidsRuqyahId = 'car/kids/ruqyah';

  /// The kids' series the car lists (audio; the YouTube-only series are left out), in the app's order.
  static const kidsSeries = ['kids-prophets', 'kids-rasoul', 'kids-ramadan'];
  static const nasheedsId = 'car/nasheeds';

  /// Series ids the phone screens use (offline copies and saved places are kept per series).
  static const sharawiSeries = 'sharawi';
  static const nasheedsSeries = 'nasheeds';
  static const radioSeries = 'radio';

  bool get _ar => settings.isArabic;
  AppLocalizations get _l => lookupAppLocalizations(settings.locale);
  String _n(int x) => _ar ? toArabicIndic(x) : '$x';

  /// The SF Symbol CarPlay shows beside an item (Android Auto shows none).
  static Map<String, dynamic> _icon(String name, [String? section]) => {'icon': name, 'section': ?section};

  MediaItem _folder(String id, String title, String detail, String icon, [String? section]) =>
      MediaItem(id: id, title: title, artist: detail, playable: false, extras: _icon(icon, section));

  MediaItem _item(String id, String title, String detail, String icon, [String? section]) =>
      MediaItem(id: id, title: title, artist: detail, playable: true, extras: _icon(icon, section));

  @override
  Future<List<MediaItem>> children(String parentId) async {
    try {
      return await _children(parentId);
    } catch (e) {
      debugPrint('car list $parentId: $e');
      return const [];
    }
  }

  Future<List<MediaItem>> _children(String parentId) async {
    final l = _l;
    if (parentId == AudioService.recentRootId) return _drive.children(parentId);
    if (parentId == AudioService.browsableRootId) {
      return [
        for (final m in await _drive.children(parentId))
          m.copyWith(extras: _icon(m.id == DriveBrowser.eveningId ? 'moon.stars' : 'sun.max')),
        _folder(radioId, l.radiosTitle, l.libraryLive, 'antenna.radiowaves.left.and.right'),
        if (library != null) _folder(libraryId, l.libraryTitle, l.carLibrarySub, 'person.wave.2'),
        _folder(sharawiId, l.sharawiSection, l.carSharawiSub, 'book.closed'),
        _folder(afhamId, l.lessonsTitle, l.carAfhamSub, 'building.columns'),
        _folder('$afhamId/$podcastTopicId', l.podcastTitle, l.carPodcastSub, 'mic'),
        _folder(kidsId, l.kidsTitle, l.carKidsSub, 'figure.and.child.holdinghands'),
        _folder(nasheedsId, l.carNasheeds, l.carNasheedsSub, 'music.note'),
      ];
    }
    if (parentId == radioId) {
      return [
        for (final r in featuredRadios)
          _item('$radioId/${r.id}', _ar ? r.nameAr : r.nameEn, l.libraryLive, 'dot.radiowaves.left.and.right'),
      ];
    }
    if (parentId == libraryId) {
      final lib = await _library();
      return [
        for (final r in _hafsReciters(lib))
          _folder('$libraryId/${r.id}', r.name, _hafsMoshaf(r)!.name, 'person.wave.2', _initial(r.name)),
      ];
    }
    if (parentId.startsWith('$libraryId/')) {
      final r = await _reciter(int.parse(parentId.substring(libraryId.length + 1)));
      final m = r == null ? null : _hafsMoshaf(r);
      if (m == null) return const [];
      return [
        for (final n in m.surahs) _item('$libraryId/${r!.id}/${m.id}/$n', '${_n(n)}. ${_surahName(n)}', r.name, 'book'),
      ];
    }
    if (parentId == sharawiId) {
      // His whole library (owner 2026-11-25): the seerah and the prophets' stories, then the Quran tafsir
      // surah by surah in the same list (CarPlay allows only a few lists one inside another).
      final c = await (_lessons ??= _loadLessons());
      final t = await (_sharawi ??= _loadSharawi());
      return [
        for (final s in c.sharawi)
          if (s.episodes.isNotEmpty)
            _folder('$lessonsId/${s.id}', _ar ? s.ar : s.en, l.sharawiLessons(_n(s.episodes.length)), 'book.closed'),
        for (final s in t.surahs)
          _folder(
            '$sharawiId/${s.surah}',
            _sharawiSurah(s.surah),
            l.sharawiLessons(_n(s.lessons.length)),
            'book.closed',
            l.sharawiPartTafsir,
          ),
      ];
    }
    if (parentId.startsWith('$sharawiId/')) {
      final surah = int.parse(parentId.substring(sharawiId.length + 1));
      final s = (await (_sharawi ??= _loadSharawi())).surahs.where((x) => x.surah == surah).firstOrNull;
      if (s == null) return const [];
      return [
        for (final x in s.lessons) _item('$sharawiId/$surah/${x.id}', _lessonTitle(x), _lessonDetail(x), 'play.circle'),
      ];
    }
    if (parentId == afhamId) {
      final c = await (_lessons ??= _loadLessons());
      return [
        for (final t in c.topics)
          if (_topicSeries(c, t.id).isNotEmpty)
            _folder(
              '$afhamId/${t.id}',
              _ar ? t.ar : t.en,
              l.carSeriesCount(_n(_topicSeries(c, t.id).length)),
              'building.columns',
            ),
      ];
    }
    if (parentId.startsWith('$afhamId/')) {
      final c = await (_lessons ??= _loadLessons());
      return [
        for (final s in _topicSeries(c, parentId.substring(afhamId.length + 1)))
          _folder(
            '$lessonsId/${s.id}',
            _ar ? s.ar : s.en,
            '${_ar ? s.sheikh.ar : s.sheikh.en} · ${l.sharawiLessons(_n(s.episodes.length))}',
            'headphones',
          ),
      ];
    }
    if (parentId.startsWith('$lessonsId/')) {
      final s = await _series(parentId.substring(lessonsId.length + 1));
      if (s == null) return const [];
      return [
        for (final e in s.episodes)
          _item(
            '$lessonsId/${s.id}/${e.index}',
            e.title ?? (s.isPodcast ? l.podcastLesson : l.lessonsLesson)(_n(e.index)),
            [
              if (e.title != null) (s.isPodcast ? l.podcastLesson : l.lessonsLesson)(_n(e.index)),
              if (e.seconds > 0) l.sharawiMinutes(_n((e.seconds / 60).round())),
            ].join(' · '),
            'play.circle',
          ),
      ];
    }
    if (parentId == kidsId) {
      final k = await (_kids ??= _loadKids());
      return [
        if (k.teacherSurahs.isNotEmpty) _folder(teacherId, l.kidsTeacher, l.kidsTeacherSub, 'book'),
        for (final id in kidsSeries)
          if (_kidsAudio(k, id) case final eps when eps.isNotEmpty)
            _folder('$kidsSeriesId/$id', _kidsTitle(id), l.carEpisodes(_n(eps.length)), 'headphones'),
        if (recitation != null && k.ruqyahKids.quranRanges.isNotEmpty)
          _item(kidsRuqyahId, l.ruqyahKidsTitle, l.carKidsRuqyahSub, 'shield'),
      ];
    }
    if (parentId == teacherId) {
      final k = await (_kids ??= _loadKids());
      return [
        for (final n in k.teacherSurahs) _item('$teacherId/$n', '${_n(n)}. ${_surahName(n)}', l.kidsTeacher, 'book'),
      ];
    }
    if (parentId.startsWith('$kidsSeriesId/')) {
      final k = await (_kids ??= _loadKids());
      return [
        for (final e in _kidsAudio(k, parentId.substring(kidsSeriesId.length + 1)))
          _item(
            '$parentId/${e.id}',
            e.title,
            e.seconds == null ? '' : l.sharawiMinutes(_n((e.seconds! / 60).round())),
            'play.circle',
          ),
      ];
    }
    if (parentId == nasheedsId) {
      final all = await (_nasheeds ??= _loadNasheeds());
      return [
        for (final m in all)
          if (m.items.isNotEmpty)
            _folder('$nasheedsId/${m.id}', m.name, l.nasheedsCount(_n(m.items.length)), 'music.mic'),
      ];
    }
    if (parentId.startsWith('$nasheedsId/')) {
      final id = int.parse(parentId.substring(nasheedsId.length + 1));
      final m = (await (_nasheeds ??= _loadNasheeds())).where((x) => x.id == id).firstOrNull;
      if (m == null) return const [];
      return [for (final x in m.items) _item('$nasheedsId/${m.id}/${x.id}', x.title, m.name, 'music.note')];
    }
    return const [];
  }

  // ---- «افهم دينك» (lesson series) ----

  /// The series of [topic] the car can play: every lesson series, al-Sha'rawi's seerah / stories too
  /// (his Quran tafsir card is left out: it is in his section, chosen by surah).
  List<LessonSeries> _topicSeries(LessonCatalog c, String topic) => [
    for (final s in c.filter(topic: topic))
      if (!s.isSharawiTafsir && s.episodes.isNotEmpty) s,
  ];

  Future<LessonSeries?> _series(String id) async {
    final c = await (_lessons ??= _loadLessons());
    return [...c.series, ...c.sharawi].where((s) => s.id == id).firstOrNull;
  }

  /// The same episode as the lessons screen's (same id and player series: places and saved copies shared).
  Episode _lessonEpisode(LessonSeries s, LessonEpisode e) {
    final ar = '${s.ar} · ${s.sheikh.ar.replaceFirst('الشيخ ', '')} · الدرس ${_n(e.index)}';
    final en = '${s.en} · ${s.sheikh.en.replaceFirst('Sheikh ', '')} · lesson ${e.index}';
    return Episode(
      id: s.episodeId(e),
      titleAr: e.title == null ? ar : '$ar · ${e.title}',
      titleEn: en,
      url: e.url,
      durationSec: e.seconds > 0 ? e.seconds : null,
      status: ReviewStatus.approved,
      skips: e.skips,
      gainDb: s.gainDb,
      clarity: s.clarity,
    );
  }

  // ---- «علّم طفلك» ----

  /// The episodes of a kids' series that can be heard (not the YouTube-only ones).
  static List<KidsEpisode> _kidsAudio(KidsContent k, String id) => [
    for (final e in k.byId(id)?.episodes ?? const <KidsEpisode>[])
      if (e.youtube == null) e,
  ];

  String _kidsTitle(String id) => switch (id) {
    'kids-prophets' => _l.kidsProphetsClassic,
    'kids-rasoul' => _l.kidsRasoul,
    'kids-ramadan' => _l.kidsRamadan,
    _ => id,
  };

  static Episode _kidsEpisode(KidsEpisode e) => Episode(
    id: e.id,
    titleAr: e.title,
    titleEn: e.title,
    url: e.url,
    durationSec: e.seconds,
    status: ReviewStatus.approved,
  );

  @override
  Future<void> play(String id) async {
    if (id.startsWith('drive/')) return _drive.play(id);
    final parts = id.split('/');
    if (parts.length < 3 || parts.first != 'car') return;
    switch (parts[1]) {
      case 'radio':
        final r = featuredRadios.where((x) => x.id == parts[2]).firstOrNull;
        if (r == null) return;
        await narration.playEpisode(
          radioSeries,
          Episode(id: r.id, titleAr: r.nameAr, titleEn: r.nameEn, url: r.url, status: ReviewStatus.approved),
          remember: false,
        );
      case 'lib' when parts.length == 5:
        final r = await _reciter(int.parse(parts[2]));
        final m = r?.moshafs.where((x) => x.id == int.parse(parts[3])).firstOrNull;
        if (r == null || m == null) return;
        final list = [for (final n in m.surahs) _surahEpisode(r, m, n)];
        final e = list.where((x) => x.id == 's${parts[4]}').firstOrNull;
        if (e != null) await narration.playEpisode('mp3quran-${m.id}', e, playlist: list);
      case 'sharawi' when parts.length == 4:
        final s = (await (_sharawi ??= _loadSharawi())).surahs.where((x) => x.surah == int.parse(parts[2])).firstOrNull;
        if (s == null) return;
        final list = [for (final x in s.lessons) _sharawiEpisode(x)];
        final e = list.where((x) => x.id == 'sharawi-${parts[3]}').firstOrNull;
        if (e != null) await narration.playEpisode(sharawiSeries, e, playlist: list);
      case 'ls' when parts.length == 4:
        final s = await _series(parts[2]);
        if (s == null) return;
        final list = [for (final e in s.episodes) _lessonEpisode(s, e)];
        final i = s.episodes.indexWhere((e) => '${e.index}' == parts[3]);
        if (i >= 0) await narration.playEpisode(s.playerSeries, list[i], playlist: list);
      case 'kids' when parts.length == 3 && parts[2] == 'ruqyah':
        // The Quran passages of the children's ruqyah, as its «listen» button on the phone.
        final k = await (_kids ??= _loadKids());
        await recitation?.playRanges(k.ruqyahKids.quranRanges);
      case 'kids' when parts.length == 4 && parts[2] == 'teacher':
        await _playTeacher(int.parse(parts[3]));
      case 'kids' when parts.length == 5 && parts[2] == 's':
        final k = await (_kids ??= _loadKids());
        final list = [for (final e in _kidsAudio(k, parts[3])) _kidsEpisode(e)];
        final e = list.where((x) => x.id == parts[4]).firstOrNull;
        if (e != null) await narration.playEpisode(parts[3], e, playlist: list);
      case 'nasheeds' when parts.length == 4:
        final m = (await (_nasheeds ??= _loadNasheeds())).where((x) => x.id == int.parse(parts[2])).firstOrNull;
        if (m == null) return;
        final list = [for (final x in m.items) nasheedEpisode(x)];
        final e = list.where((x) => x.id == 'nasheed-${parts[3]}').firstOrNull;
        if (e != null) await narration.playEpisode(nasheedsSeries, e, remember: false, playlist: list);
    }
  }

  /// The teaching Mushaf: the whole surah as the teacher reads it (the first teacher, as on the phone),
  /// going on to the next surah.
  Future<void> _playTeacher(int surah) async {
    final k = await (_kids ??= _loadKids());
    final t = await _loadTeacher(surah);
    final rec =
        (k.teacherReciters.isEmpty ? null : t.reciters[k.teacherReciters.first]) ?? t.reciters.values.firstOrNull;
    if (rec == null) return;
    final name = k.teacherReciters.isEmpty ? 'teacher' : k.teacherReciters.first;
    final list = [
      for (final n in k.teacherSurahs)
        Episode(
          id: 'teacher-$name-$n',
          titleAr: '${_l.kidsTeacher} · ${content.quran.surah(n).nameAr}',
          titleEn: '${_l.kidsTeacher} · ${content.quran.surah(n).translit}',
          url: rec.url(n),
          status: ReviewStatus.approved,
        ),
    ];
    final e = list.where((x) => x.id == 'teacher-$name-$surah').firstOrNull;
    if (e != null) await narration.playEpisode('kids-teacher', e, playlist: list);
  }

  /// True when the last pick could not start (no internet for the recording or the stream).
  bool get failed => narration.state == RecitationState.error || drive.failed;

  // ---- Recitation library ----

  Future<Mp3Library> _library() => library!.load(_ar ? 'ar' : 'eng');

  Future<Mp3Reciter?> _reciter(int id) async => (await _library()).reciters.where((r) => r.id == id).firstOrNull;

  static Mp3Moshaf? _hafsMoshaf(Mp3Reciter r) => r.moshafs.where((m) => m.rewayaId == _hafs).firstOrNull;

  static List<Mp3Reciter> _hafsReciters(Mp3Library lib) {
    final list = [
      for (final r in lib.reciters)
        if (_hafsMoshaf(r) != null) r,
    ]..sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  /// The letter a reciter is listed under (CarPlay's index on the side of a long list).
  static String _initial(String name) {
    final t = name.trim();
    if (t.isEmpty) return '#';
    final c = t.substring(0, 1);
    return const {'أ': 'ا', 'إ': 'ا', 'آ': 'ا'}[c] ?? c.toUpperCase();
  }

  String _surahName(int n) {
    final s = content.quran.surah(n);
    return _ar ? s.nameAr : s.translit;
  }

  /// The same episode the reciter screen plays (same id: saved copies and places are shared).
  Episode _surahEpisode(Mp3Reciter r, Mp3Moshaf m, int n) {
    final s = content.quran.surah(n);
    return Episode(
      id: 's$n',
      titleAr: _l.librarySurahTitle(r.name, s.nameAr),
      titleEn: lookupAppLocalizations(const Locale('en')).librarySurahTitle(r.name, s.translit),
      url: m.url(n),
      status: ReviewStatus.approved,
    );
  }

  // ---- al-Sha'rawi ----

  String _sharawiSurah(int n) {
    if (n == 0) return _l.sharawiIntro;
    final s = content.quran.surahs[n - 1];
    return _ar ? s.nameAr : s.nameEn;
  }

  String _lessonTitle(SharawiLesson x) => _l.sharawiLesson(_n(x.index));

  String _lessonDetail(SharawiLesson x) {
    final l = _l;
    return [
      if (x.hasRange) x.from == x.to ? l.sharawiAyah(_n(x.from!)) : l.sharawiAyahs(_n(x.from!), _n(x.to!)),
      if ((x.seconds ?? 0) > 0) l.sharawiMinutes(_n((x.seconds! / 60).round())),
    ].join(' · ');
  }

  /// The same episode as the Sha'rawi screen's (id `sharawi-<lesson>`).
  Episode _sharawiEpisode(SharawiLesson x) {
    final title = '${_l.sharawiTitle} · ${_sharawiSurah(x.surah)} · ${_lessonTitle(x)}';
    return Episode(
      id: 'sharawi-${x.id}',
      titleAr: title,
      titleEn: title,
      url: x.url,
      durationSec: x.seconds,
      status: ReviewStatus.approved,
    );
  }
}

/// A nasheed as the shared audio player plays it (same id as the nasheeds screen).
Episode nasheedEpisode(Nasheed n) =>
    Episode(id: 'nasheed-${n.id}', titleAr: n.title, titleEn: n.title, url: n.url, status: ReviewStatus.approved);
