// Quran content model. The ayah strings are kept exactly as decoded from
// assets/content/quran.v1.json (a byte-for-byte copy of content/quran/dist);
// nothing in this file modifies them.
import 'dart:convert';

import 'package:crypto/crypto.dart';

class Surah {
  const Surah({
    required this.n,
    required this.nameAr,
    required this.nameEn,
    required this.translit,
    required this.revelation,
    required this.ayahs,
    required this.en,
  });

  factory Surah.fromJson(Map<String, dynamic> j) => Surah(
    n: j['n'] as int,
    nameAr: j['nameAr'] as String,
    nameEn: j['nameEn'] as String,
    translit: j['translit'] as String,
    revelation: j['revelation'] as String,
    ayahs: List<String>.unmodifiable(j['ayahs'] as List<dynamic>),
    en: List<String>.unmodifiable(j['en'] as List<dynamic>),
  );

  final int n;
  final String nameAr;
  final String nameEn;
  final String translit;
  final String revelation; // "meccan" | "medinan"
  final List<String> ayahs;
  final List<String> en;

  int get ayahCount => ayahs.length;
  bool get isMeccan => revelation == 'meccan';
}

/// An ayah reference (surah, ayah), both 1-based.
class AyahRef implements Comparable<AyahRef> {
  const AyahRef(this.surah, this.ayah);
  final int surah;
  final int ayah;

  @override
  int compareTo(AyahRef o) => surah != o.surah ? surah.compareTo(o.surah) : ayah.compareTo(o.ayah);

  @override
  bool operator ==(Object other) => other is AyahRef && other.surah == surah && other.ayah == ayah;

  @override
  int get hashCode => Object.hash(surah, ayah);

  @override
  String toString() => '$surah:$ayah';
}

class MushafPage {
  const MushafPage(this.page, this.start, this.end);
  final int page;
  final AyahRef start;
  final AyahRef end;
}

class JuzStart {
  const JuzStart(this.juz, this.page, this.start);
  final int juz;
  final int page;
  final AyahRef start;
}

class QuranContent {
  QuranContent({
    required this.surahs,
    required this.pages,
    required this.juz,
    required this.version,
    required this.layout,
  }) {
    _pageStartIndex = [for (final p in pages) _flat(p.start)];
  }

  factory QuranContent.fromJson(Map<String, dynamic> quran, Map<String, dynamic> pagesJson) {
    AyahRef ref(Object? v) {
      final l = v as List<dynamic>;
      return AyahRef(l[0] as int, l[1] as int);
    }

    return QuranContent(
      surahs: List.unmodifiable([
        for (final s in quran['surahs'] as List<dynamic>) Surah.fromJson(s as Map<String, dynamic>),
      ]),
      pages: List.unmodifiable([
        for (final p in pagesJson['pages'] as List<dynamic>)
          MushafPage((p as Map<String, dynamic>)['page'] as int, ref(p['start']), ref(p['end'])),
      ]),
      juz: List.unmodifiable([
        for (final j in pagesJson['juz'] as List<dynamic>)
          JuzStart((j as Map<String, dynamic>)['juz'] as int, j['page'] as int, ref(j['start'])),
      ]),
      version: quran['version'] as String? ?? '',
      layout: pagesJson['layout'] as String? ?? '',
    );
  }

  final List<Surah> surahs;
  final List<MushafPage> pages;
  final List<JuzStart> juz;
  final String version;
  final String layout;
  late final List<int> _pageStartIndex;
  late final List<int> _surahOffsets = () {
    final out = <int>[0];
    for (final s in surahs) {
      out.add(out.last + s.ayahCount);
    }
    return out;
  }();

  int get pageCount => pages.length;
  int get ayahCount => _surahOffsets.last;

  Surah surah(int n) {
    if (n < 1 || n > surahs.length) throw RangeError.range(n, 1, surahs.length);
    return surahs[n - 1];
  }

  bool isValid(AyahRef r) =>
      r.surah >= 1 && r.surah <= surahs.length && r.ayah >= 1 && r.ayah <= surahs[r.surah - 1].ayahCount;

  String text(AyahRef r) => surah(r.surah).ayahs[r.ayah - 1];

  int _flat(AyahRef r) => _surahOffsets[r.surah - 1] + r.ayah - 1;

  AyahRef _unflat(int i) {
    var s = 0;
    while (_surahOffsets[s + 1] <= i) {
      s++;
    }
    return AyahRef(s + 1, i - _surahOffsets[s] + 1);
  }

  MushafPage page(int p) {
    if (p < 1 || p > pages.length) throw RangeError.range(p, 1, pages.length);
    return pages[p - 1];
  }

  /// All ayah references on Madinah Mushaf page [p], in reading order.
  List<AyahRef> ayahsOnPage(int p) {
    final mp = page(p);
    final a = _flat(mp.start);
    final b = _flat(mp.end);
    return [for (var i = a; i <= b; i++) _unflat(i)];
  }

  /// The Mushaf page on which ayah [r] starts.
  int pageOf(AyahRef r) {
    if (!isValid(r)) throw ArgumentError('invalid ayah $r');
    final i = _flat(r);
    var lo = 0;
    var hi = _pageStartIndex.length - 1;
    while (lo < hi) {
      final mid = (lo + hi + 1) ~/ 2;
      if (_pageStartIndex[mid] <= i) {
        lo = mid;
      } else {
        hi = mid - 1;
      }
    }
    return lo + 1;
  }

  /// The juz in which page [p] lies (by the juz start page).
  int juzOfPage(int p) {
    var j = 1;
    for (final js in juz) {
      if (js.page <= p) j = js.juz;
    }
    return j;
  }

  /// Distinct surahs that appear on page [p].
  List<int> surahsOnPage(int p) => ayahsOnPage(p).map((r) => r.surah).toSet().toList();
}

/// SHA-256 of `"<surah>|<ayah>|<text>\n"` for every ayah in order
/// (matches integrity.v1.json allAyahsSha256).
String allAyahsSha256(List<Surah> surahs) {
  final sb = StringBuffer();
  for (final s in surahs) {
    for (var i = 0; i < s.ayahs.length; i++) {
      sb.write('${s.n}|${i + 1}|${s.ayahs[i]}\n');
    }
  }
  return sha256.convert(utf8.encode(sb.toString())).toString();
}

/// SHA-256 of a surah's ayahs joined by "\n" (integrity.v1.json surahSha256).
String surahSha256(Surah s) => sha256.convert(utf8.encode(s.ayahs.join('\n'))).toString();
