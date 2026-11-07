import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/data/tafsir.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/tafsir.dart';
import 'package:rattil/ui/ayah_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  late AppContent c;
  late TafsirContent t;
  late Map<String, dynamic> src;
  setUpAll(() async {
    c = await loadContent(realFonts: false);
    t = testTafsir;
    src = readRepoJson('content/tafsir/dist/muyassar.v1.json');
  });

  test('the bundled file is byte-identical to content/tafsir/dist/muyassar.v1.json', () {
    final bundled = File(TafsirStore.assetKey).readAsBytesSync();
    final source = File('$repoRoot/content/tafsir/dist/muyassar.v1.json').readAsBytesSync();
    expect(bundled.length, source.length);
    expect(bundled, source);
  });

  test('6236 entries, one per ayah of every surah, texts exactly as stored', () {
    expect(t.id, 'muyassar');
    expect(t.nameAr, 'التفسير الميسر');
    expect(t.surahs, hasLength(114));
    expect(t.entryCount, 6236);
    final stored = src['surahs'] as List<dynamic>;
    for (var s = 1; s <= 114; s++) {
      expect(t.surahs[s - 1], hasLength(c.quran.surah(s).ayahCount), reason: 'surah $s');
      for (var a = 1; a <= t.surahs[s - 1].length; a++) {
        expect(t.text(s, a), (stored[s - 1] as List<dynamic>)[a - 1], reason: '$s:$a');
        expect(t.text(s, a)!.trim(), isNotEmpty, reason: '$s:$a');
      }
    }
  });

  test('lookup by surah and ayah', () {
    expect(t.text(2, 255), ((src['surahs'] as List<dynamic>)[1] as List<dynamic>)[254]);
    expect(t.text(2, 255), startsWith('الله الذي لا يستحق الألوهية والعبودية إلا هو'));
    expect(
      t.text(112, 1),
      'قل -أيها الرسول-: هو الله المتفرد بالألوهية والربوبية والأسماء والصفات، لا يشاركه أحد فيها.',
    );
    expect(t.text(1, 1), isNotNull);
    expect(t.text(114, 6), isNotNull);
  });

  test('out of range lookups return null', () {
    for (final (s, a) in [(0, 1), (115, 1), (-1, 1), (1, 0), (1, 8), (2, 287), (114, 7), (112, -1)]) {
      expect(t.text(s, a), isNull, reason: '$s:$a');
    }
  });

  test('rejects a file that is not tafsir.v1 or does not cover 114 surahs', () {
    expect(() => TafsirContent.parse('{"schema":"x","surahs":[]}'), throwsFormatException);
    expect(
      () => TafsirContent.parse('{"schema":"tafsir.v1","id":"m","nameAr":"","nameEn":"","surahs":[["a"]]}'),
      throwsFormatException,
    );
  });

  test('the store reads the asset lazily, decodes it in a background isolate, and loads once', () async {
    var reads = 0;
    final bundle = _CountingBundle(() => reads++);
    final store = TafsirStore.asset(bundle);
    expect(reads, 0, reason: 'nothing is read until asked');
    expect(store.loaded, isNull);
    final a = store.load();
    final b = store.load();
    expect(identical(a, b), isTrue);
    final loaded = await a;
    expect(reads, 1);
    expect(store.loaded, same(loaded));
    expect(loaded.text(2, 255), t.text(2, 255));
  });

  test('a failed load is reported and retried on the next request', () async {
    var calls = 0;
    final store = TafsirStore(() async {
      calls++;
      if (calls == 1) throw StateError('disk');
      return t;
    });
    await expectLater(store.load(), throwsStateError);
    expect(store.loaded, isNull);
    expect(await store.load(), same(t));
    expect(calls, 2);
  });

  test('previous / next ayah across surah boundaries', () {
    final q = c.quran;
    expect(stepAyah(q, const AyahRef(2, 255), 1), const AyahRef(2, 256));
    expect(stepAyah(q, const AyahRef(2, 255), -1), const AyahRef(2, 254));
    expect(stepAyah(q, const AyahRef(1, 7), 1), const AyahRef(2, 1));
    expect(stepAyah(q, const AyahRef(2, 1), -1), const AyahRef(1, 7));
    expect(stepAyah(q, const AyahRef(1, 1), -1), isNull);
    expect(stepAyah(q, const AyahRef(114, 6), 1), isNull);
  });

  test('"tafsir with recitation" is off by default and persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final a = SettingsController(prefs, defaultCityId: 'c1');
    expect(a.tafsirWithRecitation, isFalse);
    var notified = 0;
    a.addListener(() => notified++);
    await a.setTafsirWithRecitation(true);
    expect(notified, 1);
    expect(prefs.getBool('audio.tafsir'), isTrue);
    expect(SettingsController(prefs, defaultCityId: 'c1').tafsirWithRecitation, isTrue);
    await a.setTafsirWithRecitation(false);
    expect(SettingsController(prefs, defaultCityId: 'c1').tafsirWithRecitation, isFalse);
  });
}

/// rootBundle that counts reads of the tafsir asset.
class _CountingBundle extends CachingAssetBundle {
  _CountingBundle(this.onRead);
  final void Function() onRead;

  @override
  Future<ByteData> load(String key) {
    if (key == TafsirStore.assetKey) onRead();
    return rootBundle.load(key);
  }
}
