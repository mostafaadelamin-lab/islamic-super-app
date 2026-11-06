import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/text.dart';
import 'package:timezone/timezone.dart' as tz;

import '../helpers.dart';

void main() {
  late AppContent content;
  final normJson = readRepoJson('packages/shared-schemas/search-normalization.json');
  final renderJson = readRepoJson('packages/shared-schemas/quran-render.json');

  setUpAll(() async => content = await loadContent());

  test('bundled schema copies are identical to packages/shared-schemas', () {
    for (final f in ['cities.json', 'quran-render.json', 'search-normalization.json']) {
      expect(
        File('assets/schemas/$f').readAsStringSync(),
        File('$repoRoot/packages/shared-schemas/$f').readAsStringSync(),
        reason: f,
      );
    }
  });

  group('search normalisation vectors', () {
    final n = SearchNormalizer.fromJson(normJson);
    for (final raw in normJson['vectors'] as List<dynamic>) {
      final v = raw as Map<String, dynamic>;
      test('"${v['in']}" -> "${v['out']}"', () {
        expect(n.normalize(v['in'] as String), v['out']);
        expect(content.normalizer.normalize(v['in'] as String), v['out']);
      });
    }
    test('is idempotent and strips every code point in removeRanges', () {
      for (final raw in normJson['vectors'] as List<dynamic>) {
        final out = n.normalize((raw as Map<String, dynamic>)['in'] as String);
        expect(n.normalize(out), out);
      }
      for (final r in normJson['removeRanges'] as List<dynamic>) {
        final a = int.parse((r as List)[0] as String, radix: 16);
        final b = int.parse(r[1] as String, radix: 16);
        for (var cp = a; cp <= b; cp++) {
          expect(n.normalize('ب${String.fromCharCode(cp)}ب'), 'بب', reason: cp.toRadixString(16));
        }
      }
    });
    test('maps alef forms, ya, ta marbuta; collapses whitespace', () {
      expect(n.normalize('أإآٱا'), 'ااااا');
      expect(n.normalize('ى ئ ؤ ة'), 'ي ي و ه');
      expect(n.normalize(' \t a \n  b '), 'a b');
      expect(n.letterCount('ا ب'), 2);
    });
    test('rejects multi-code-point map keys', () {
      expect(
        () => SearchNormalizer.fromJson({
          'removeRanges': <dynamic>[],
          'map': {'ab': 'c'},
        }),
        throwsFormatException,
      );
    });
  });

  group('render map (display only)', () {
    final m = QuranRenderMap.fromJson(renderJson);
    test('maps KFGQPC open tanween code points to the Amiri Quran ones', () {
      expect(m.forDisplay('ٖٗٞ'), 'ࣰࣱࣲ');
      expect(m.forDisplay('هُدٗى'), 'هُدࣰى');
      expect(m.forDisplay('بِسۡمِ'), 'بِسۡمِ');
    });
    test('does not touch stored, searched or hashed text', () {
      final q = content.quran;
      final before = allAyahsSha256(q.surahs);
      var changed = 0;
      for (final s in q.surahs) {
        for (final t in s.ayahs) {
          final d = content.renderMap.forDisplay(t);
          if (d != t) changed++;
          expect(d.runes.length, t.runes.length);
        }
      }
      expect(changed, greaterThan(0), reason: 'the map must matter for some ayahs');
      expect(allAyahsSha256(q.surahs), before);
      expect(allAyahsSha256(q.surahs), content.integrity['allAyahsSha256']);
      expect(q.text(const AyahRef(2, 2)), contains('ٗ'));
      expect(q.text(const AyahRef(2, 2)), isNot(contains('ࣰ')));
    });
    test('search results carry the original text, not the display text', () {
      final r = content.search.search('هدى للمتقين')!;
      expect(r.hits.map((h) => h.ref), contains(const AyahRef(2, 2)));
      final hit = r.hits.firstWhere((h) => h.ref == const AyahRef(2, 2));
      expect(hit.text, content.quran.text(const AyahRef(2, 2)));
      expect(hit.text, contains('ٗ'));
    });
  });

  group('Quran search', () {
    test('diacritic-insensitive: plain and vocalised queries match the same ayahs', () {
      final a = content.search.search('الحمد لله رب العلمين')!;
      final b = content.search.search('ٱلۡحَمۡدُ لِلَّهِ رَبِّ ٱلۡعَٰلَمِينَ')!;
      expect(a.hits.map((h) => h.ref), contains(const AyahRef(1, 2)));
      expect(a.total, b.total);
      expect(a.hits.first.ref, const AyahRef(1, 2));
    });
    test('fewer than 2 letters is rejected', () {
      expect(content.search.search('ا'), isNull);
      expect(content.search.search('  َ  '), isNull);
      expect(content.search.search(''), isNull);
    });
    test('no match gives zero total', () {
      expect(content.search.search('zzzz')!.total, 0);
    });
    test('limit caps hits but not total', () {
      final r = content.search.search('الله', limit: 5)!;
      expect(r.hits, hasLength(5));
      expect(r.total, greaterThan(1000));
      for (var i = 1; i < r.hits.length; i++) {
        expect(r.hits[i].ref.compareTo(r.hits[i - 1].ref), greaterThan(0));
      }
    });
  });

  group('digits and page input', () {
    test('Arabic-Indic digits', () {
      expect(toArabicIndic(1234567890), '١٢٣٤٥٦٧٨٩٠');
      expect(toArabicIndic('12:05'), '١٢:٠٥');
      expect(ayahMarker(255), '﴿٢٥٥﴾');
      expect(toAsciiDigits('٦٠٤ ۶۰۴'), '604 604');
    });
    test('parsePageNumber validates 1..604', () {
      expect(parsePageNumber('1'), 1);
      expect(parsePageNumber(' 604 '), 604);
      expect(parsePageNumber('٥٠'), 50);
      expect(parsePageNumber('0'), isNull);
      expect(parsePageNumber('605'), isNull);
      expect(parsePageNumber('-3'), isNull);
      expect(parsePageNumber('3.5'), isNull);
      expect(parsePageNumber('abc'), isNull);
      expect(parsePageNumber(''), isNull);
      expect(parsePageNumber('99999'), isNull);
    });
  });

  test('cities load with valid time zones and methods', () {
    expect(content.cities, isNotEmpty);
    for (final c in content.cities) {
      expect(content.prayerConfig.methods.containsKey(c.method), isTrue, reason: c.id);
      expect(c.lat, inInclusiveRange(-90, 90));
      expect(c.lng, inInclusiveRange(-180, 180));
      expect(tz.getLocation(c.tz).name, c.tz);
    }
    expect(content.city('c1')!.nameEn, 'Cairo');
    expect(content.city('nope'), isNull);
  });
}
