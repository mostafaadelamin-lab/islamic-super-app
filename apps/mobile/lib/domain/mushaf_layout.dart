// 15-line Madinah Mushaf layout (content/quran/dist/mushaf-lines.v1.json).
// The layout file only says WHICH canonical words go on each line: every word
// shown is taken from quran.v1.json by splitting the stored ayah string on
// single spaces. Nothing here creates, edits or reorders Quran text.
import 'quran.dart';

/// Words w0..w1-1 (0-based, end exclusive) of ayah [ref]; [endsAyah] means the
/// ayah ends on this line, so its number marker is drawn after the last word.
class LineSegment {
  const LineSegment(this.ref, this.w0, this.w1, this.endsAyah);
  final AyahRef ref;
  final int w0;
  final int w1;
  final bool endsAyah;
}

enum MushafLineKind { sura, basmala, text }

class MushafLine {
  const MushafLine.sura(this.surah) : kind = MushafLineKind.sura, segments = const [];
  const MushafLine.basmala(this.surah) : kind = MushafLineKind.basmala, segments = const [];
  const MushafLine.text(this.segments) : kind = MushafLineKind.text, surah = 0;

  final MushafLineKind kind;

  /// Surah number for sura/basmala lines (0 for text lines).
  final int surah;
  final List<LineSegment> segments;
}

class MushafLayoutPage {
  const MushafLayoutPage(this.page, this.lines);
  final int page;
  final List<MushafLine> lines;

  /// Pages 1 and 2 are drawn as centred lines inside an ornament (8 lines);
  /// all other pages have 15 justified lines.
  bool get centered => page <= 2;

  /// Ayahs that have at least one word on this page, in reading order.
  List<AyahRef> get ayahs {
    final out = <AyahRef>[];
    for (final l in lines) {
      for (final s in l.segments) {
        if (out.isEmpty || out.last != s.ref) out.add(s.ref);
      }
    }
    return out;
  }
}

/// One word as drawn: the canonical word string and the ayah it belongs to.
class MushafWord {
  const MushafWord(this.ref, this.index, this.text, {required this.endsAyah});
  final AyahRef ref;

  /// 0-based word index within the ayah.
  final int index;

  /// The canonical word, exactly as stored (display glyph map NOT applied).
  final String text;

  /// True for the last word of an ayah: the ayah marker follows it.
  final bool endsAyah;
}

class MushafLayout {
  MushafLayout(this.pages);

  factory MushafLayout.fromJson(Map<String, dynamic> j) {
    final pages = <MushafLayoutPage>[];
    for (final p in j['pages'] as List<dynamic>) {
      final pm = p as Map<String, dynamic>;
      final lines = <MushafLine>[];
      for (final l in pm['lines'] as List<dynamic>) {
        final lm = l as Map<String, dynamic>;
        switch (lm['k']) {
          case 'sura':
            lines.add(MushafLine.sura(lm['s'] as int));
          case 'basmala':
            lines.add(MushafLine.basmala(lm['s'] as int));
          case 'text':
            lines.add(
              MushafLine.text(
                List.unmodifiable([
                  for (final g in lm['g'] as List<dynamic>)
                    () {
                      final v = (g as List<dynamic>).cast<int>();
                      return LineSegment(AyahRef(v[0], v[1]), v[2], v[3], v[4] == 1);
                    }(),
                ]),
              ),
            );
          default:
            throw FormatException('unknown mushaf line kind ${lm['k']}');
        }
      }
      pages.add(MushafLayoutPage(pm['page'] as int, List.unmodifiable(lines)));
    }
    return MushafLayout(List.unmodifiable(pages));
  }

  final List<MushafLayoutPage> pages;

  int get pageCount => pages.length;

  MushafLayoutPage page(int p) {
    if (p < 1 || p > pages.length) throw RangeError.range(p, 1, pages.length);
    return pages[p - 1];
  }
}

/// The canonical words of one ayah: the stored string split on single spaces.
List<String> ayahWords(QuranContent q, AyahRef r) => q.text(r).split(' ');

/// The words of [line] (a text line), taken from the canonical text.
List<MushafWord> lineWords(QuranContent q, MushafLine line) {
  final out = <MushafWord>[];
  for (final s in line.segments) {
    final words = ayahWords(q, s.ref);
    if (s.w0 < 0 || s.w1 > words.length || s.w0 >= s.w1) {
      throw RangeError('segment ${s.ref} ${s.w0}..${s.w1} outside ${words.length} words');
    }
    for (var i = s.w0; i < s.w1; i++) {
      out.add(MushafWord(s.ref, i, words[i], endsAyah: s.endsAyah && i == s.w1 - 1));
    }
  }
  return out;
}
