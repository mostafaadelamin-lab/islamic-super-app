import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/domain/hajj_guide.dart';
import 'package:rattil/ui/hajj_scene_view.dart';

import '../helpers.dart';

/// The sourced Hajj & Umrah guide (owner 2026-11-16): content/pilgrimage/build-guide.mjs cuts every text out of
/// its source; these checks hold the app's copy to the same rules as the website's.
void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  Iterable<QuranSeg> allQuran(SourcedHajjGuide g) sync* {
    Iterable<QuranSeg> of(List<GuideSeg> segs) => segs.whereType<QuranSeg>();
    for (final s in g.subs.values) {
      for (final it in s.items) {
        if (it.quran case final q?) yield q;
        yield* of(it.segs);
      }
    }
    for (final p in [...g.officialUmrah, ...g.officialHajj, for (final t in g.officialTypes) t.segs]) {
      yield* of(p);
    }
  }

  test('the bundled guide is the generated one', () {
    for (final (src, dst) in [
      ('content/pilgrimage/dist/hajj-guide.v2.json', 'assets/content/hajj-guide.v2.json'),
      ('content/pilgrimage/dist/hajj-scenes.v1.json', 'assets/content/hajj-scenes.v1.json'),
      ('content/pilgrimage/scene-roles.v1.json', 'assets/content/scene-roles.v1.json'),
    ]) {
      expect(File(dst).readAsStringSync(), File('$repoRoot/$src').readAsStringSync(), reason: dst);
    }
  });

  test('every ayah is the KFGQPC text unchanged; a quoted part is an exact part of its ayah', () {
    final qs = allQuran(c.hajjGuide).toList();
    expect(qs.length, greaterThan(10));
    for (final q in qs) {
      for (final (i, t) in q.texts.indexed) {
        expect(t, c.quran.surah(q.surah).ayahs[q.from + i - 1], reason: '${q.surah}:${q.from + i}');
      }
      if (q.part case final p?) expect(c.quran.surah(q.surah).ayahs[q.from - 1].contains(p), isTrue);
    }
  });

  test('Maqam Ibrahim: after the hadith, al-Baqarah 125 in full (owner 2026-11-16)', () {
    final items = c.hajjGuide.subs['to-maqam']!.items;
    expect(items.last.quran?.texts, [c.quran.surah(2).ayahs[124]]);
    expect(items.last.quran?.part, isNull);
  });

  test('the pillars of Hajj come from Ibn Baz\'s fatwa, word for word (owner 2026-11-16)', () {
    final fatwa = File('$repoRoot/content/pilgrimage/upstream/binbaz-fatwa-14833.txt').readAsStringSync();
    final it = c.hajjGuide.subs[c.hajjGuide.steps[c.hajjGuide.pillars]!.subs.single]!.items.single;
    final text = (it.segs.single as TextSeg).text;
    expect(text, startsWith('وأركان الحج أربعة'));
    expect(fatwa.contains(text), isTrue);
  });

  test('the sentence on women visiting graves is left out (owner chose to remove it)', () {
    final raw = File('assets/content/hajj-guide.v2.json').readAsStringSync();
    expect(raw.contains('زوارات'), isFalse);
    expect(raw.contains('في حق الرجال خاصة'), isFalse);
    expect(jsonDecode(raw)['steps']['madinah']['subs'], hasLength(greaterThan(3)));
  });

  test('every step of every kind exists, with its official paragraph when one is named', () {
    final g = c.hajjGuide;
    expect(g.flows.keys, containsAll(['umrah', 'tamattu', 'qiran', 'ifrad']));
    for (final e in g.flows.entries) {
      for (final s in e.value) {
        expect(g.steps[s.step], isNotNull, reason: s.step);
        if (s.dalil != null) expect(g.official(s.dalil, e.key), isNotNull, reason: '${e.key} ${s.dalil}');
        for (final k in g.steps[s.step]!.subs) {
          expect(g.subs[k], isNotNull, reason: k);
        }
      }
    }
  });

  test('every picture colour resolves in both brightnesses', () {
    for (final b in Brightness.values) {
      final colours = SceneColours(c.hajjScenes.roles, b);
      for (final s in c.hajjScenes.scenes.values) {
        for (final x in s.shapes) {
          if (x.fill case final f?) colours.of(f);
          if (x.stroke case final r?) colours.of(r);
        }
      }
    }
    expect(c.hajjScenes.scenes, hasLength(14));
  });
}
