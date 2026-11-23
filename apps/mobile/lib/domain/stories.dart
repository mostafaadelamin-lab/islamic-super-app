/// Quranic stories, from trusted sources only (owner rule: no story text is
/// written by us):
///  * verse stories: each story is its Quranic verse ranges, shown as the
///    Mushaf text, recited with the app's reciters and explained with Tafsir
///    al-Muyassar;
///  * narrated series: audio-only episodes by a named narrator (Sheikh Nabil
///    al-Awadi's "Stories of the Prophets"), streamed from their source. Users
///    hear only episodes a named reviewer approved; reviewer mode also lists
///    pending ones, with a banner.
library;

import 'quran.dart';

enum ReviewStatus { approved, pending }

ReviewStatus? _status(Object? s) => switch (s) {
  'approved' => ReviewStatus.approved,
  'pending' => ReviewStatus.pending,
  _ => null,
};

final _id = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

class StoryRange {
  const StoryRange(this.surah, this.from, this.to);
  final int surah;
  final int from;
  final int to;
  int get length => to - from + 1;
  AyahRef get start => AyahRef(surah, from);
  AyahRef get end => AyahRef(surah, to);
  bool contains(AyahRef r) => r.surah == surah && r.ayah >= from && r.ayah <= to;
}

class QuranStory {
  const QuranStory({
    required this.id,
    required this.category,
    required this.titleAr,
    required this.titleEn,
    required this.ranges,
    required this.status,
    this.reviewer,
  });

  static const categories = ['prophets', 'others'];

  final String id;
  final String category;
  final String titleAr;
  final String titleEn;
  final List<StoryRange> ranges;
  final ReviewStatus status;
  final String? reviewer;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  int get ayahCount => ranges.fold(0, (n, r) => n + r.length);
  bool contains(AyahRef r) => ranges.any((x) => x.contains(r));

  /// Null for anything malformed, or whose verses do not exist in [ayahCounts].
  static QuranStory? tryParse(Object? raw, List<int> ayahCounts) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    final status = _status(raw['status']);
    final title = raw['title'];
    final segs = raw['segments'];
    if (id is! String || !_id.hasMatch(id) || status == null) return null;
    if (!categories.contains(raw['category']) || title is! Map<String, dynamic> || segs is! List || segs.isEmpty) {
      return null;
    }
    final ar = title['ar'];
    if (ar is! String || ar.trim().isEmpty) return null;
    final ranges = <StoryRange>[];
    for (final s in segs) {
      if (s is! List || s.length != 3 || s.any((x) => x is! int)) return null;
      final r = StoryRange(s[0] as int, s[1] as int, s[2] as int);
      if (r.surah < 1 || r.surah > ayahCounts.length || r.from < 1 || r.from > r.to) return null;
      if (r.to > ayahCounts[r.surah - 1]) return null;
      ranges.add(r);
    }
    return QuranStory(
      id: id,
      category: raw['category'] as String,
      titleAr: ar,
      titleEn: title['en'] is String && (title['en'] as String).isNotEmpty ? title['en'] as String : ar,
      ranges: List.unmodifiable(ranges),
      status: status,
      reviewer: status == ReviewStatus.approved ? raw['reviewer'] as String? : null,
    );
  }
}

/// An https link to an audio file, nothing else.
bool isAudioUrl(Object? url) {
  if (url is! String) return false;
  final u = Uri.tryParse(url);
  return u != null &&
      u.scheme == 'https' &&
      u.host.isNotEmpty &&
      RegExp(r'\.(mp3|m4a|aac|ogg|opus)$', caseSensitive: false).hasMatch(u.path);
}

class Episode {
  const Episode({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.url,
    required this.status,
    this.durationSec,
    this.story,
    this.reviewer,
    this.skips = const [],
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String url;
  final int? durationSec;
  final String? story;
  final ReviewStatus status;
  final String? reviewer;

  /// Stretches the player jumps over, in seconds [from, to): music before, between and after a lesson
  /// (owner 2026-11-23: no music in lessons).
  final List<(int, int)> skips;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  bool get isPending => status == ReviewStatus.pending;
  int? get minutes => durationSec == null ? null : (durationSec! / 60).round().clamp(1, 1 << 20);

  static Episode? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    final status = _status(raw['status']);
    final title = raw['title'];
    if (id is! String || !_id.hasMatch(id) || status == null || !isAudioUrl(raw['url'])) return null;
    if (title is! Map<String, dynamic> || title['ar'] is! String || (title['ar'] as String).trim().isEmpty) return null;
    final d = raw['durationSec'];
    return Episode(
      id: id,
      titleAr: title['ar'] as String,
      titleEn: title['en'] is String ? title['en'] as String : title['ar'] as String,
      url: raw['url'] as String,
      durationSec: d is int && d > 0 ? d : null,
      story: raw['story'] is String ? raw['story'] as String : null,
      status: status,
      reviewer: status == ReviewStatus.approved ? raw['reviewer'] as String? : null,
    );
  }
}

class StorySeries {
  const StorySeries({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.narratorAr,
    required this.narratorEn,
    required this.source,
    required this.licence,
    required this.episodes,
  });

  final String id;
  final String titleAr;
  final String titleEn;
  final String narratorAr;
  final String narratorEn;
  final String source;
  final String licence;
  final List<Episode> episodes;

  String title(bool arabic) => arabic ? titleAr : titleEn;
  String narrator(bool arabic) => arabic ? narratorAr : narratorEn;

  /// Approved episodes for everyone; reviewers also get pending ones.
  List<Episode> visible({required bool reviewer}) => [
    for (final e in episodes)
      if (e.status == ReviewStatus.approved || (reviewer && e.isPending)) e,
  ];

  static StorySeries? tryParse(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final id = raw['id'];
    final title = raw['title'];
    final narrator = raw['narrator'];
    final licence = raw['licence'];
    if (id is! String || !_id.hasMatch(id) || title is! Map<String, dynamic> || narrator is! Map<String, dynamic>) {
      return null;
    }
    if (licence is! String || licence.trim().isEmpty || title['ar'] is! String || narrator['ar'] is! String) {
      return null;
    }
    final eps = [if (raw['episodes'] is List) ...(raw['episodes'] as List).map(Episode.tryParse).whereType<Episode>()];
    if (eps.isEmpty) return null;
    return StorySeries(
      id: id,
      titleAr: title['ar'] as String,
      titleEn: (title['en'] as String?) ?? title['ar'] as String,
      narratorAr: narrator['ar'] as String,
      narratorEn: (narrator['en'] as String?) ?? narrator['ar'] as String,
      source: (raw['source'] as String?) ?? '',
      licence: licence,
      episodes: List.unmodifiable(eps),
    );
  }
}

class StoryCatalog {
  const StoryCatalog(this.stories, this.series);

  factory StoryCatalog.fromJson(Map<String, dynamic> j, List<int> ayahCounts) {
    if (j['schema'] != 'stories.v1') return empty;
    final items = j['items'];
    final series = j['series'];
    return StoryCatalog(
      List.unmodifiable([
        if (items is List) ...items.map((x) => QuranStory.tryParse(x, ayahCounts)).whereType<QuranStory>(),
      ]),
      List.unmodifiable([if (series is List) ...series.map(StorySeries.tryParse).whereType<StorySeries>()]),
    );
  }

  static const empty = StoryCatalog([], []);

  final List<QuranStory> stories;
  final List<StorySeries> series;

  QuranStory? byId(String? id) {
    for (final s in stories) {
      if (s.id == id) return s;
    }
    return null;
  }

  List<QuranStory> inCategory(String c) => [
    for (final s in stories)
      if (s.category == c) s,
  ];
}

/// Where to jump to when [sec] falls inside one of [skips] ([from, to) seconds), or null.
int? skipEnd(List<(int, int)> skips, int sec) {
  for (final (from, to) in skips) {
    if (sec >= from && sec < to) return to;
  }
  return null;
}
