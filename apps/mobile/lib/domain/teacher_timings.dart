import 'dart:convert';

/// Where each ayah and word sits inside the one-file-per-surah teaching recordings
/// (assets/content/teacher-timings/{surah}.json, built by tools/kids_teacher_timings.py).
/// Owner 2026-11-20: the kids' teaching Mushaf lights up the word being read.
class TeacherTimings {
  TeacherTimings(this.wordUrl, this.reciters);

  factory TeacherTimings.parse(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    final rec = <String, TeacherRecording>{};
    for (final e in (j['reciters'] as Map<String, dynamic>).entries) {
      final r = e.value as Map<String, dynamic>;
      rec[e.key] = TeacherRecording(r['url'] as String, {
        for (final s in (r['surahs'] as Map<String, dynamic>).entries)
          int.parse(s.key): [
            for (final a in s.value as List)
              TeacherAyah((a as List)[0] as int, a[1] as int, [
                for (final w in a[2] as List) TeacherWord((w as List)[0] as int, w[1] as int, w[2] as int),
              ]),
          ],
      });
    }
    return TeacherTimings(j['word'] as String, rec);
  }

  /// One file per surah (built by tools/kids_teacher_timings.py); a reciter is missing where
  /// Quran.com has no timings for that recording.
  static String assetFor(int surah) => 'assets/content/teacher-timings/$surah.json';

  /// Quran.com word-by-word audio template ({sss}, {aaa}, {www}).
  final String wordUrl;
  final Map<String, TeacherRecording> reciters;

  String wordAudio(int s, int a, int w) {
    String p(int n) => n.toString().padLeft(3, '0');
    return wordUrl.replaceAll('{sss}', p(s)).replaceAll('{aaa}', p(a)).replaceAll('{www}', p(w));
  }
}

class TeacherRecording {
  TeacherRecording(this.urlTemplate, this.surahs);
  final String urlTemplate;
  final Map<int, List<TeacherAyah>> surahs;

  String url(int s) => urlTemplate.replaceAll('{sss}', s.toString().padLeft(3, '0')).replaceAll('{s}', '$s');

  /// The ayah (0-based) and word token being read at [ms]; null outside every ayah.
  ({int ayah, int? word})? at(int s, int ms) {
    final ay = surahs[s];
    if (ay == null) return null;
    for (var i = 0; i < ay.length; i++) {
      final a = ay[i];
      if (ms >= a.start && ms < a.end) {
        for (final w in a.words) {
          if (ms >= w.start && ms < w.end) return (ayah: i, word: w.token);
        }
        return (ayah: i, word: null);
      }
    }
    return null;
  }
}

class TeacherAyah {
  TeacherAyah(this.start, this.end, this.words);
  final int start;
  final int end;
  final List<TeacherWord> words;
}

class TeacherWord {
  TeacherWord(this.token, this.start, this.end);

  /// Index of the word among the KFGQPC ayah text split on spaces.
  final int token;
  final int start;
  final int end;
}

/// The ayah text as words and the spaces between them (joining them gives the text back).
({List<String> words, List<String> gaps}) ayahTokens(String text) {
  final words = <String>[];
  final gaps = <String>[];
  var last = 0;
  for (final m in RegExp(r'\s+').allMatches(text)) {
    words.add(text.substring(last, m.start));
    gaps.add(m.group(0)!);
    last = m.end;
  }
  words.add(text.substring(last));
  return (words: words, gaps: gaps);
}

/// Quran.com word number of KFGQPC token [k] (the rub el-hizb sign «۞» is its own token here,
/// glued to the next word there); null for that sign.
int? quranComWord(List<String> words, int k) {
  if (words[k] == '۞') return null;
  var n = 0;
  for (var i = 0; i <= k; i++) {
    if (words[i] != '۞') n++;
  }
  return n;
}
