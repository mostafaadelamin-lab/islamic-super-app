// The app's lists on the car screen (Android Auto and CarPlay): the morning / evening adhkar
// in driving mode first, then the listening sections the owner asked for on 2026-11-23:
// radio, the recitation library, al-Sha'rawi's tafsir, the prophets' stories and nasheeds.
//
// Picking an item plays it through the same players as the phone screens (driving mode, or the
// narration player with the same series and episode ids, so saved copies and the place where the
// listener stopped are used), and the car switches to its Now Playing screen.

import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../domain/mp3quran.dart';
import '../domain/nasheeds.dart' show Munshid, Nasheed;
import '../domain/radios.dart';
import '../domain/sharawi.dart';
import '../domain/stories.dart';
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
    Future<List<Munshid>> Function()? nasheeds,
    Future<SharawiTafsir> Function()? sharawi,
  }) : _drive = DriveBrowser(drive, settings),
       _loadNasheeds = nasheeds ?? _assetNasheeds,
       _loadSharawi = sharawi ?? _assetSharawi;

  final DriveModeController drive;
  final NarrationController narration;
  final SettingsController settings;
  final AppContent content;

  /// The recitation library (mp3quran.net, cached on the phone). Null: the section is left out.
  final Mp3QuranClient? library;
  final DriveBrowser _drive;
  final Future<List<Munshid>> Function() _loadNasheeds;
  final Future<SharawiTafsir> Function() _loadSharawi;
  Future<List<Munshid>>? _nasheeds;
  Future<SharawiTafsir>? _sharawi;

  static Future<List<Munshid>> _assetNasheeds() async =>
      Munshid.parse(await rootBundle.loadString('assets/content/nasheeds.v2.json'));
  static Future<SharawiTafsir> _assetSharawi() async =>
      SharawiTafsir.parse(await rootBundle.loadString('assets/content/sharawi.v1.json'));

  static const radioId = 'car/radio';
  static const libraryId = 'car/lib';
  static const sharawiId = 'car/sharawi';
  static const storiesId = 'car/stories';
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
        _folder(radioId, l.carRadio, l.libraryLive, 'antenna.radiowaves.left.and.right'),
        if (library != null) _folder(libraryId, l.carLibrary, l.carLibrarySub, 'person.wave.2'),
        _folder(sharawiId, l.sharawiTitle, l.carSharawiSub, 'book.closed'),
        _folder(storiesId, l.carStories, l.carStoriesSub, 'books.vertical'),
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
      final t = await (_sharawi ??= _loadSharawi());
      return [
        for (final s in t.surahs)
          _folder(
            '$sharawiId/${s.surah}',
            _sharawiSurah(s.surah),
            l.sharawiLessons(_n(s.lessons.length)),
            'book.closed',
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
    if (parentId == storiesId) {
      final series = content.stories.series.where((s) => s.episodes.isNotEmpty).toList();
      // One series (Sheikh Nabil al-Awadi's): its episodes straight away, one level less to tap.
      if (series.length == 1) return _episodes(series.single);
      return [for (final s in series) _folder('$storiesId/${s.id}', s.title(_ar), s.narrator(_ar), 'books.vertical')];
    }
    if (parentId.startsWith('$storiesId/')) {
      final id = parentId.substring(storiesId.length + 1);
      final s = content.stories.series.where((x) => x.id == id).firstOrNull;
      return s == null ? const [] : _episodes(s);
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

  List<MediaItem> _episodes(StorySeries s) => [
    for (final e in s.episodes) _item('$storiesId/${s.id}/${e.id}', e.title(_ar), s.narrator(_ar), 'play.circle'),
  ];

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
      case 'stories' when parts.length == 4:
        final s = content.stories.series.where((x) => x.id == parts[2]).firstOrNull;
        final e = s?.episodes.where((x) => x.id == parts[3]).firstOrNull;
        if (e != null) await narration.playEpisode(s!.id, e, playlist: s.episodes);
      case 'nasheeds' when parts.length == 4:
        final m = (await (_nasheeds ??= _loadNasheeds())).where((x) => x.id == int.parse(parts[2])).firstOrNull;
        if (m == null) return;
        final list = [for (final x in m.items) nasheedEpisode(x)];
        final e = list.where((x) => x.id == 'nasheed-${parts[3]}').firstOrNull;
        if (e != null) await narration.playEpisode(nasheedsSeries, e, remember: false, playlist: list);
    }
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
