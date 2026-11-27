/// «سلاسل الدروس»: complete audio lesson series by well-known scholars, grouped by topic.
/// Streamed, or downloaded per lesson (or the whole series) for offline listening.
/// List: assets/content/lessons.v1.json, built by tools/lessons_build.py from
/// content/lessons/sources.json (sources in docs/CONTENT_SOURCES.md, never shown in the app).
library;

import 'dart:convert';

class LessonLabel {
  const LessonLabel(this.id, this.ar, this.en);
  final String id;
  final String ar;
  final String en;
  String of(bool arabic) => arabic ? ar : en;
}

class LessonSheikh extends LessonLabel {
  const LessonSheikh(super.id, super.ar, super.en, this.groups);

  /// "azhar", "egypt", "saudi".
  final List<String> groups;
}

class LessonEpisode {
  const LessonEpisode({
    required this.index,
    required this.url,
    this.title,
    this.seconds = 0,
    this.bytes = 0,
    this.skips = const [],
  });

  /// 1-based position in the series.
  final int index;
  final String url;

  /// The lesson's own title, when the recording has one.
  final String? title;
  final int seconds;
  final int bytes;

  /// Music stretches the player jumps over, in seconds [from, to).
  final List<(int, int)> skips;
}

class LessonSeries {
  const LessonSeries({
    required this.id,
    required this.topic,
    required this.sheikh,
    required this.ar,
    required this.en,
    required this.episodes,
    this.gainDb = 0,
    this.clarity = false,
    this.summary,
  });
  final String id;
  final LessonLabel topic;
  final LessonSheikh sheikh;
  final String ar;
  final String en;
  final List<LessonEpisode> episodes;

  /// Played louder / softer (dB) and with the voice lifted for an old tape (tools/lessons_loudness.py).
  final double gainDb;
  final bool clarity;

  /// (lessons, seconds) of a card whose lessons live elsewhere: al-Sha'rawi's Quran tafsir, chosen
  /// by surah in his section ([sharawiTafsirId]).
  final (int, int)? summary;

  int get lessonTotal => summary?.$1 ?? episodes.length;

  bool get isSharawiTafsir => id == sharawiTafsirId;

  /// A «بودكاست» show: its parts are episodes, not lessons.
  bool get isPodcast => topic.id == podcastTopicId;

  String title(bool arabic) => arabic ? ar : en;

  /// Audio-player series key (resume position, offline folder, "continue" entry).
  String get playerSeries => 'lessons-$id';

  String episodeId(LessonEpisode e) => '$id-${e.index}';

  int get seconds => summary?.$2 ?? episodes.fold(0, (a, e) => a + e.seconds);
}

/// The card of al-Sha'rawi's Quran tafsir in the lesson list and his section.
const sharawiTafsirId = 'sharawi-tafsir';

/// The «بودكاست» topic: a topic in «افهم دينك» and its own section under «المزيد».
const podcastTopicId = 'podcast';

class LessonCatalog {
  const LessonCatalog({
    required this.topics,
    required this.groups,
    required this.sheikhs,
    required this.series,
    this.sharawi = const [],
    this.sharawiTafsir,
  });
  final List<LessonLabel> topics;
  final List<LessonLabel> groups;
  final List<LessonSheikh> sheikhs;
  final List<LessonSeries> series;

  /// Al-Sha'rawi's seerah and prophets' stories: the parts of his own section, and listed in the lesson
  /// list under their topics too (owner 2026-11-24).
  final List<LessonSeries> sharawi;

  /// His Quran tafsir as a card ([LessonSeries.summary], no episodes): opens the surah list.
  final LessonSeries? sharawiTafsir;

  /// Everything the lesson list shows: each Sha'rawi part right after the last series of its topic.
  List<LessonSeries> get listed {
    final out = [...series];
    for (final s in [?sharawiTafsir, ...sharawi]) {
      final at = out.lastIndexWhere((x) => x.topic.id == s.topic.id);
      out.insert(at < 0 ? out.length : at + 1, s);
    }
    return out;
  }

  LessonSeries? sharawiById(String id) {
    for (final s in sharawi) {
      if (s.id == id) return s;
    }
    return null;
  }

  int get lessonCount => listed.fold(0, (a, s) => a + s.lessonTotal);

  LessonSeries? byId(String id) {
    for (final s in [...series, ...sharawi]) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// [group]/[topic] null = all.
  List<LessonSeries> filter({String? group, String? topic}) => [
    for (final s in listed)
      if ((group == null || s.sheikh.groups.contains(group)) && (topic == null || s.topic.id == topic)) s,
  ];

  static LessonCatalog parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    LessonLabel label(dynamic x) => LessonLabel(x['id'] as String, x['ar'] as String, x['en'] as String);
    final topics = [for (final x in j['topics'] as List) label(x)];
    final sheikhs = [
      for (final x in j['sheikhs'] as List)
        LessonSheikh(x['id'] as String, x['ar'] as String, x['en'] as String, [
          for (final g in x['groups'] as List) g as String,
        ]),
    ];
    final topicById = {for (final t in topics) t.id: t};
    final sheikhById = {for (final s in sheikhs) s.id: s};
    LessonSeries series(dynamic s) => LessonSeries(
      id: s['id'] as String,
      topic: topicById[s['topic']]!,
      sheikh: sheikhById[s['sheikh']]!,
      ar: s['ar'] as String,
      en: s['en'] as String,
      gainDb: ((s['fx'] as Map?)?['g'] as num?)?.toDouble() ?? 0,
      clarity: (s['fx'] as Map?)?['c'] == 1,
      episodes: [
        for (final (i, e) in (s['episodes'] as List).indexed)
          LessonEpisode(
            index: i + 1,
            url: e['u'] as String,
            title: e['t'] as String?,
            seconds: (e['s'] as num?)?.toInt() ?? 0,
            bytes: (e['b'] as num?)?.toInt() ?? 0,
            skips: [
              for (final m in (e['m'] as List?) ?? const []) (((m as List)[0] as num).toInt(), (m[1] as num).toInt()),
            ],
          ),
      ],
    );
    return LessonCatalog(
      topics: topics,
      groups: [for (final x in j['groups'] as List) label(x)],
      sheikhs: sheikhs,
      series: [for (final s in j['series'] as List) series(s)],
      sharawi: [for (final s in (j['sharawi'] as List?) ?? const []) series(s)],
      sharawiTafsir: switch (j['sharawiTafsir']) {
        final Map<String, dynamic> t => LessonSeries(
          id: t['id'] as String,
          topic: topicById[t['topic']]!,
          sheikh: sheikhById[t['sheikh']]!,
          ar: t['ar'] as String,
          en: t['en'] as String,
          episodes: const [],
          summary: ((t['n'] as num).toInt(), (t['s'] as num).toInt()),
        ),
        _ => null,
      },
    );
  }
}
