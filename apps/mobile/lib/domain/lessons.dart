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
  const LessonEpisode({required this.index, required this.url, this.title, this.seconds = 0, this.bytes = 0});

  /// 1-based position in the series.
  final int index;
  final String url;

  /// The lesson's own title, when the recording has one.
  final String? title;
  final int seconds;
  final int bytes;
}

class LessonSeries {
  const LessonSeries({
    required this.id,
    required this.topic,
    required this.sheikh,
    required this.ar,
    required this.en,
    required this.episodes,
  });
  final String id;
  final LessonLabel topic;
  final LessonSheikh sheikh;
  final String ar;
  final String en;
  final List<LessonEpisode> episodes;

  String title(bool arabic) => arabic ? ar : en;

  /// Audio-player series key (resume position, offline folder, "continue" entry).
  String get playerSeries => 'lessons-$id';

  String episodeId(LessonEpisode e) => '$id-${e.index}';

  int get seconds => episodes.fold(0, (a, e) => a + e.seconds);
}

class LessonCatalog {
  const LessonCatalog({required this.topics, required this.groups, required this.sheikhs, required this.series});
  final List<LessonLabel> topics;
  final List<LessonLabel> groups;
  final List<LessonSheikh> sheikhs;
  final List<LessonSeries> series;

  int get lessonCount => series.fold(0, (a, s) => a + s.episodes.length);

  LessonSeries? byId(String id) {
    for (final s in series) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// [group]/[topic] null = all.
  List<LessonSeries> filter({String? group, String? topic}) => [
    for (final s in series)
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
    return LessonCatalog(
      topics: topics,
      groups: [for (final x in j['groups'] as List) label(x)],
      sheikhs: sheikhs,
      series: [
        for (final s in j['series'] as List)
          LessonSeries(
            id: s['id'] as String,
            topic: topicById[s['topic']]!,
            sheikh: sheikhById[s['sheikh']]!,
            ar: s['ar'] as String,
            en: s['en'] as String,
            episodes: [
              for (final (i, e) in (s['episodes'] as List).indexed)
                LessonEpisode(
                  index: i + 1,
                  url: e['u'] as String,
                  title: e['t'] as String?,
                  seconds: (e['s'] as num?)?.toInt() ?? 0,
                  bytes: (e['b'] as num?)?.toInt() ?? 0,
                ),
            ],
          ),
      ],
    );
  }
}
