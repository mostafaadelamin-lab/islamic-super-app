import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/domain/mushaf_layout.dart';
import 'package:rattil/domain/quran.dart';

import '../helpers.dart';

void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  test('bundled mushaf-lines.v1.json is the content/quran/dist file, byte for byte', () {
    expect(readAppJson('assets/content/mushaf-lines.v1.json'), readRepoJson('content/quran/dist/mushaf-lines.v1.json'));
  });

  test('604 pages; pages 1-2 have 8 lines, every other page 15', () {
    expect(c.mushaf.pageCount, 604);
    for (final p in c.mushaf.pages) {
      expect(p.lines.length, p.page <= 2 ? 8 : 15, reason: 'page ${p.page}');
      expect(p.centered, p.page <= 2);
    }
  });

  test('every word comes from the canonical text: each ayah is rebuilt exactly, once, in order', () {
    final q = c.quran;
    final rebuilt = <AyahRef, List<String>>{};
    var markers = 0;
    for (final p in c.mushaf.pages) {
      for (final l in p.lines.where((l) => l.kind == MushafLineKind.text)) {
        final words = lineWords(q, l);
        expect(words, isNotEmpty);
        for (final w in words) {
          final list = rebuilt.putIfAbsent(w.ref, () => []);
          expect(w.index, list.length, reason: '${w.ref} words in order, no gaps or repeats');
          list.add(w.text);
          if (w.endsAyah) markers++;
        }
      }
    }
    expect(rebuilt.length, 6236);
    expect(markers, 6236, reason: 'one ayah marker per ayah');
    for (final s in q.surahs) {
      for (var a = 1; a <= s.ayahCount; a++) {
        expect(rebuilt[AyahRef(s.n, a)]!.join(' '), s.ayahs[a - 1], reason: '${s.n}:$a');
      }
    }
  });

  test('the ayahs on each layout page are exactly the pages.v1.json range', () {
    for (var p = 1; p <= 604; p++) {
      expect(c.mushaf.page(p).ayahs, c.quran.ayahsOnPage(p), reason: 'page $p');
    }
  });

  test('114 surah title lines; basmala lines for every surah except 1 and 9, before ayah 1', () {
    final sura = <int>[];
    final basmala = <int>[];
    for (final p in c.mushaf.pages) {
      for (var i = 0; i < p.lines.length; i++) {
        final l = p.lines[i];
        if (l.kind == MushafLineKind.sura) sura.add(l.surah);
        if (l.kind == MushafLineKind.basmala) {
          basmala.add(l.surah);
          final next = p.lines[i + 1];
          expect(next.kind, MushafLineKind.text);
          expect(next.segments.first.ref, AyahRef(l.surah, 1));
          expect(next.segments.first.w0, 0);
        }
      }
    }
    expect(sura, [for (var s = 1; s <= 114; s++) s]);
    expect(basmala, [
      for (var s = 1; s <= 114; s++)
        if (s != 1 && s != 9) s,
    ]);
  });

  test('lineWords rejects a segment outside the ayah', () {
    final bad = MushafLine.text([LineSegment(const AyahRef(1, 1), 0, 99, true)]);
    expect(() => lineWords(c.quran, bad), throwsRangeError);
  });

  test('the display glyph map is never applied to layout words', () {
    final map = c.renderMap.map.keys.toSet();
    var withKeys = 0;
    for (final p in c.mushaf.pages) {
      for (final l in p.lines.where((l) => l.kind == MushafLineKind.text)) {
        for (final w in lineWords(c.quran, l)) {
          if (map.any(w.text.contains)) withKeys++;
          for (final v in c.renderMap.map.values) {
            expect(w.text.contains(v), isFalse, reason: 'canonical words never contain display code points');
          }
        }
      }
    }
    expect(withKeys, greaterThan(0), reason: 'the canonical text does use U+0657/U+065E/U+0656');
  });
}
