import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/domain/quran.dart';

import '../helpers.dart';

void main() {
  late AppContent content;
  late QuranContent q;
  final integrity = readRepoJson('content/quran/dist/integrity.v1.json');
  final reference = readRepoJson('tests/vectors/quran-reference.json');

  setUpAll(() async {
    content = await loadContent();
    q = content.quran;
  });

  test('bundled Quran assets are byte-identical to content/quran/dist', () async {
    for (final f in ['quran.v1.json', 'pages.v1.json', 'integrity.v1.json']) {
      final bundled = (await rootBundle.load('assets/content/$f')).buffer.asUint8List();
      final source = File('$repoRoot/content/quran/dist/$f').readAsBytesSync();
      expect(sha256.convert(bundled), sha256.convert(source), reason: f);
    }
  });

  test('114 surahs and 6236 ayahs', () {
    expect(q.surahs, hasLength(114));
    expect(q.ayahCount, 6236);
    expect(integrity['surahCount'], 114);
    expect(integrity['ayahCount'], 6236);
  });

  test('ayah counts equal the independent reference (quran-reference.json)', () {
    expect([for (final s in q.surahs) s.ayahCount], List<int>.from(reference['ayahCounts'] as List));
    expect([for (final s in q.surahs) s.n], List.generate(114, (i) => i + 1));
  });

  test('allAyahsSha256 of the bundled text matches integrity.v1.json', () {
    expect(allAyahsSha256(q.surahs), integrity['allAyahsSha256']);
  });

  test('every surahSha256 matches integrity.v1.json', () {
    final hashes = List<String>.from(integrity['surahSha256'] as List);
    expect(hashes, hasLength(114));
    for (final s in q.surahs) {
      expect(surahSha256(s), hashes[s.n - 1], reason: 'surah ${s.n}');
    }
  });

  test('hash is sensitive to a single changed code point', () {
    final s = q.surahs.first;
    final tampered = Surah(
      n: s.n,
      nameAr: s.nameAr,
      nameEn: s.nameEn,
      translit: s.translit,
      revelation: s.revelation,
      ayahs: [s.ayahs.first.replaceFirst('ٱ', 'ا'), ...s.ayahs.skip(1)],
      en: s.en,
    );
    expect(surahSha256(tampered), isNot(surahSha256(s)));
    expect(allAyahsSha256([tampered, ...q.surahs.skip(1)]), isNot(integrity['allAyahsSha256']));
  });

  test('every ayah has non-empty text and an English translation', () {
    for (final s in q.surahs) {
      expect(s.en, hasLength(s.ayahCount));
      for (final t in s.ayahs) {
        expect(t.trim(), isNotEmpty);
      }
      expect(s.revelation, anyOf('meccan', 'medinan'));
      expect(s.nameAr, isNotEmpty);
      expect(s.nameEn, isNotEmpty);
    }
  });

  test('604 Madinah pages, contiguous, covering 1:1..114:6', () {
    expect(q.pageCount, 604);
    expect(integrity['pageCount'], 604);
    expect(q.pages.first.start, const AyahRef(1, 1));
    expect(q.pages.last.end, const AyahRef(114, 6));
    for (var i = 0; i < q.pages.length; i++) {
      final p = q.pages[i];
      expect(p.page, i + 1);
      expect(p.start.compareTo(p.end), lessThanOrEqualTo(0), reason: 'page ${p.page}');
      expect(q.isValid(p.start) && q.isValid(p.end), isTrue);
      if (i > 0) {
        final prev = q.pages[i - 1].end;
        final expected = prev.ayah < q.surah(prev.surah).ayahCount
            ? AyahRef(prev.surah, prev.ayah + 1)
            : AyahRef(prev.surah + 1, 1);
        expect(p.start, expected, reason: 'gap/overlap before page ${p.page}');
      }
    }
    final total = [for (var p = 1; p <= 604; p++) q.ayahsOnPage(p).length].reduce((a, b) => a + b);
    expect(total, 6236);
  });

  test('page spot checks from quran-reference.json', () {
    for (final raw in reference['madinahPageSpotChecks'] as List<dynamic>) {
      final c = raw as Map<String, dynamic>;
      final p = q.page(c['page'] as int);
      expect([p.start.surah, p.start.ayah], c['start']);
      expect([p.end.surah, p.end.ayah], c['end']);
    }
  });

  test('pageOf is the inverse of ayahsOnPage for all 6236 ayahs', () {
    for (var p = 1; p <= 604; p++) {
      for (final r in q.ayahsOnPage(p)) {
        expect(q.pageOf(r), p);
      }
    }
    expect(() => q.pageOf(const AyahRef(1, 8)), throwsArgumentError);
    expect(() => q.page(0), throwsRangeError);
    expect(() => q.page(605), throwsRangeError);
  });

  test('30 juz, juz 30 starts on page 582 at 78:1', () {
    expect(q.juz, hasLength(30));
    expect(q.juz.last.page, 582);
    expect(q.juz.last.start, const AyahRef(78, 1));
    expect(q.juzOfPage(1), 1);
    expect(q.juzOfPage(21), 1);
    expect(q.juzOfPage(22), 2);
    expect(q.juzOfPage(604), 30);
  });

  test('text spot checks', () {
    expect(content.normalizer.normalize(q.text(const AyahRef(1, 1))), 'بسم الله الرحمن الرحيم');
    expect(content.normalizer.normalize(q.text(const AyahRef(1, 2))), 'الحمد لله رب العلمين');
    expect(content.normalizer.normalize(q.text(const AyahRef(112, 1))), 'قل هو الله احد');
    expect(q.surah(1).nameAr, 'الفاتحة');
    expect(q.surah(2).ayahCount, 286);
    expect(q.surah(2).isMeccan, isFalse);
    expect(q.surah(114).ayahCount, 6);
    expect(q.pageOf(const AyahRef(2, 255)), 42);
    expect(q.pageOf(const AyahRef(18, 1)), 293);
    expect(() => q.surah(115), throwsRangeError);
  });

  test('every bundled ayah equals the pinned upstream quran-json 3.1.2 text', () {
    final upstreamFile = File('$repoRoot/content/quran/upstream/quran-json-3.1.2.quran.json');
    expect(sha256.convert(upstreamFile.readAsBytesSync()).toString(), reference['upstreamFileSha256']);
    final upstream = jsonDecode(upstreamFile.readAsStringSync()) as List<dynamic>;
    expect(upstream, hasLength(114));
    var n = 0;
    for (final raw in upstream) {
      final u = raw as Map<String, dynamic>;
      final s = q.surah(u['id'] as int);
      final verses = u['verses'] as List<dynamic>;
      expect(verses, hasLength(s.ayahCount));
      for (final v in verses) {
        final m = v as Map<String, dynamic>;
        expect(s.ayahs[(m['id'] as int) - 1], m['text'], reason: '${s.n}:${m['id']}');
        n++;
      }
    }
    expect(n, 6236);
  });

  test('integrity.v1.json is the copy bundled with the app', () async {
    final bundled = jsonDecode(await rootBundle.loadString('assets/content/integrity.v1.json'));
    expect(bundled, integrity);
    expect(content.integrity, integrity);
  });
}
