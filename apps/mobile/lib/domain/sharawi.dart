/// Sheikh al-Sha'rawi's audio tafsir (khawatir): 1116 lessons by surah, each
/// with the ayah range it explains. Streamed, or downloaded per lesson for
/// offline listening. List: assets/content/sharawi.v1.json, built by
/// tools/sharawi_build.py (source in docs/CONTENT_SOURCES.md, never shown in the app).
library;

import 'dart:convert';

class SharawiLesson {
  const SharawiLesson({
    required this.id,
    required this.surah,
    required this.index,
    required this.url,
    this.from,
    this.to,
    this.bytes,
    this.seconds,
  });

  /// Global lesson number in the series (1..1116), stable across builds.
  final int id;

  /// 0 = the sheikh's introduction.
  final int surah;

  /// 1-based position of the lesson within its surah.
  final int index;
  final String url;
  final int? from;
  final int? to;
  final int? bytes;
  final int? seconds;

  bool get hasRange => from != null && to != null;
}

class SharawiSurah {
  const SharawiSurah(this.surah, this.lessons);
  final int surah;
  final List<SharawiLesson> lessons;

  int get seconds => lessons.fold(0, (a, l) => a + (l.seconds ?? 0));
}

class SharawiTafsir {
  const SharawiTafsir(this.surahs);
  final List<SharawiSurah> surahs;

  int get lessonCount => surahs.fold(0, (a, s) => a + s.lessons.length);

  SharawiSurah? bySurah(int n) {
    for (final s in surahs) {
      if (s.surah == n) return s;
    }
    return null;
  }

  static SharawiTafsir parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    final base = j['base'] as String;
    return SharawiTafsir([
      for (final s in j['surahs'] as List)
        SharawiSurah(s['n'] as int, [
          for (final (i, l) in (s['lessons'] as List).indexed)
            SharawiLesson(
              id: l['id'] as int,
              surah: s['n'] as int,
              index: i + 1,
              url: base + (l['p'] as String).split('/').map(Uri.encodeComponent).join('/'),
              from: l['f'] as int?,
              to: l['t'] as int?,
              bytes: l['b'] as int?,
              seconds: l['s'] as int?,
            ),
        ]),
    ]);
  }
}
