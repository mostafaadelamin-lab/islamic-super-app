/// Kids section + ruqyah (owner, 2026-11-20). Built by tools/kids_build.py into
/// assets/content/kids.v1.json. Quran passages are references only (the text is
/// read from quran.v1.json, KFGQPC); dua texts are copied by the build tool from
/// Hisn al-Muslim / HadeethEnc, never written here. Sources: docs/CONTENT_SOURCES.md
/// (never shown in the app).
library;

import 'dart:convert';

import 'quran.dart';
import 'stories.dart';

/// One step of a ruqyah: a Quran passage, or a dua from the Sunnah.
sealed class RuqyahItem {
  const RuqyahItem();
}

class RuqyahQuran extends RuqyahItem {
  const RuqyahQuran(this.range);
  final StoryRange range;
}

class RuqyahDua extends RuqyahItem {
  const RuqyahDua({required this.text, required this.source, this.repeat = 1, this.audio});
  final String text;
  final String source;
  final int repeat;

  /// A recording of this dua (streamed), when there is one.
  final String? audio;
}

class Ruqyah {
  const Ruqyah(this.items, {this.full});
  final List<RuqyahItem> items;

  /// The whole ruqyah read in one recording (downloadable), when there is one.
  final KidsEpisode? full;

  List<StoryRange> get quranRanges => [
    for (final i in items)
      if (i is RuqyahQuran) i.range,
  ];

  bool contains(AyahRef r) => quranRanges.any((x) => x.contains(r));
}

/// One video (or the full ruqyah recording): streamed, or saved for offline.
class KidsEpisode {
  const KidsEpisode({required this.id, required this.title, required this.url, this.bytes, this.seconds});
  final String id;
  final String title;
  final String url;
  final int? bytes;
  final int? seconds;

  int? get megabytes => bytes == null ? null : (bytes! / 1e6).round().clamp(1, 1 << 30);
  int? get minutes => seconds == null ? null : (seconds! / 60).round().clamp(1, 1 << 20);
}

class KidsSeries {
  const KidsSeries({required this.id, required this.group, required this.episodes});

  /// Also the download folder name ("kids-…": saved as video files).
  final String id;

  /// "prophets" or "stories".
  final String group;
  final List<KidsEpisode> episodes;
}

class KidsContent {
  const KidsContent({
    required this.ruqyah,
    required this.ruqyahKids,
    required this.teacherReciters,
    required this.teacherSurahs,
    required this.series,
  });

  final Ruqyah ruqyah;
  final Ruqyah ruqyahKids;

  /// Reciter folders of "the teaching Mushaf" (the sheikh reads, children repeat).
  final List<String> teacherReciters;
  final List<int> teacherSurahs;
  final List<KidsSeries> series;

  KidsSeries? byId(String id) {
    for (final s in series) {
      if (s.id == id) return s;
    }
    return null;
  }

  static KidsEpisode _episode(Map<String, dynamic> e, {String? id, String? title}) => KidsEpisode(
    id: id ?? e['id'] as String,
    title: title ?? e['title'] as String,
    url: e['url'] as String,
    bytes: e['bytes'] as int?,
    seconds: e['seconds'] as int?,
  );

  static Ruqyah _ruqyah(Map<String, dynamic> j, {KidsEpisode? full}) => Ruqyah([
    for (final i in j['items'] as List)
      if ((i as Map<String, dynamic>)['t'] == 'q')
        RuqyahQuran(StoryRange(i['s'] as int, i['from'] as int, i['to'] as int))
      else
        RuqyahDua(
          text: i['text'] as String,
          source: (i['src'] as String?) ?? '',
          repeat: (i['repeat'] as int?) ?? 1,
          audio: i['audio'] as String?,
        ),
  ], full: full);

  static KidsContent parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final r = j['ruqyah'] as Map<String, dynamic>;
    final t = j['teacher'] as Map<String, dynamic>;
    return KidsContent(
      ruqyah: _ruqyah(
        r,
        full: r['full'] == null
            ? null
            : _episode(r['full'] as Map<String, dynamic>, id: 'ruqyah-full', title: 'ruqyah-full'),
      ),
      ruqyahKids: _ruqyah(j['ruqyahKids'] as Map<String, dynamic>),
      teacherReciters: [for (final x in t['reciters'] as List) x as String],
      teacherSurahs: [for (final x in t['surahs'] as List) x as int],
      series: [
        for (final s in j['series'] as List)
          KidsSeries(
            id: s['id'] as String,
            group: s['group'] as String,
            episodes: [for (final e in s['episodes'] as List) _episode(e as Map<String, dynamic>)],
          ),
      ],
    );
  }
}
