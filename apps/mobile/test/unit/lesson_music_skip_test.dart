import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/lessons.dart';
import 'package:rattil/domain/stories.dart';

void main() {
  test('skipEnd jumps over a music stretch and nowhere else (owner 2026-11-23)', () {
    const skips = [(0, 45), (380, 397), (1040, 1104)];
    expect(skipEnd(skips, 0), 45);
    expect(skipEnd(skips, 44), 45);
    expect(skipEnd(skips, 45), isNull);
    expect(skipEnd(skips, 390), 397);
    expect(skipEnd(skips, 600), isNull);
    expect(skipEnd(const [], 10), isNull);
  });

  test("the Grand Imam's lessons carry their music stretches from the list", () {
    final c = LessonCatalog.parse(File('assets/content/lessons.v1.json').readAsStringSync());
    final asma = c.byId('asma-tayeb')!;
    expect(asma.episodes.where((e) => e.skips.isNotEmpty).length, greaterThan(asma.episodes.length ~/ 2));
    for (final e in asma.episodes) {
      for (final (from, to) in e.skips) {
        expect(from, lessThan(to));
      }
    }
  });

  test('quiet and old series carry their gain / clarity from the list (owner 2026-11-24)', () {
    final c = LessonCatalog.parse(File('assets/content/lessons.v1.json').readAsStringSync());
    expect(c.byId('muamalat-khathlan')!.gainDb, greaterThan(6));
    expect(c.byId('tawhid-alsheikh')!.clarity, isTrue);
    expect(c.byId('usul-uthaymeen'), isNull, reason: 'replaced by al-Qasim (owner 2026-11-24)');
    expect(c.byId('shamail-gabr')!.clarity, isTrue);
    for (final s in c.series) {
      expect(s.gainDb, inInclusiveRange(-10, 12));
    }
  });
}
