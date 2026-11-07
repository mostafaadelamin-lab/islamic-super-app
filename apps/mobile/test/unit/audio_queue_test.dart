import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/domain/audio_queue.dart';
import 'package:rattil/domain/quran.dart';

import '../helpers.dart';

void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  test('bundled reciters.json is the shared schema copy', () {
    expect(readAppJson('assets/schemas/reciters.json'), readRepoJson('packages/shared-schemas/audio/reciters.json'));
  });

  test('catalogue: 8 reciters, unique folders, default first-class', () {
    final r = c.reciters;
    expect(r.reciters, hasLength(8));
    expect(r.reciters.map((x) => x.folder).toSet(), hasLength(8));
    expect(r.byFolder(null).folder, 'Alafasy_128kbps');
    expect(r.byFolder('nope').folder, 'Alafasy_128kbps');
    expect(r.byFolder('Husary_128kbps').nameAr, 'محمود خليل الحصري');
  });

  test('URL building pads surah and ayah to 3 digits', () {
    final r = c.reciters;
    expect(r.url('Alafasy_128kbps', const AyahRef(2, 255)), 'https://everyayah.com/data/Alafasy_128kbps/002255.mp3');
    expect(r.url('Husary_128kbps', const AyahRef(1, 1)), 'https://everyayah.com/data/Husary_128kbps/001001.mp3');
    expect(
      r.url('Maher_AlMuaiqly_64kbps', const AyahRef(114, 6)),
      'https://everyayah.com/data/Maher_AlMuaiqly_64kbps/114006.mp3',
    );
  });

  test('basmala rule: before ayah 1 of every surah except 1 and 9', () {
    for (var s = 1; s <= 114; s++) {
      expect(basmalaBeforeSurah(s), s != 1 && s != 9, reason: 'surah $s');
    }
    final q2 = buildQueue(c.quran, const AyahRef(2, 1), const AyahRef(2, 2));
    expect(q2, [
      const QueueItem(AyahRef(2, 1), isBasmala: true),
      const QueueItem(AyahRef(2, 1)),
      const QueueItem(AyahRef(2, 2)),
    ]);
    expect(q2.first.audioRef, const AyahRef(1, 1), reason: 'the basmala file is 001001');
    expect(q2.first.ref, const AyahRef(2, 1), reason: 'highlight stays on 2:1');
    final q1 = buildQueue(c.quran, const AyahRef(1, 1), const AyahRef(1, 2));
    expect(q1, [const QueueItem(AyahRef(1, 1)), const QueueItem(AyahRef(1, 2))], reason: '1:1 IS the basmala');
    final q9 = buildQueue(c.quran, const AyahRef(9, 1), const AyahRef(9, 1));
    expect(q9, [const QueueItem(AyahRef(9, 1))], reason: 'no basmala before at-Tawbah');
  });

  test('starting mid-surah adds no basmala; crossing into the next surah adds one', () {
    final q = buildQueue(c.quran, const AyahRef(1, 6), const AyahRef(2, 1));
    expect(q.map((e) => e.toString()), ['1:6', '1:7', 'basmala→2:1', '2:1']);
    final t = buildQueue(c.quran, const AyahRef(8, 75), const AyahRef(9, 1));
    expect(t.map((e) => e.toString()), ['8:75', '9:1']);
  });

  test('repeat count repeats each ayah but not the basmala', () {
    final q = buildQueue(c.quran, const AyahRef(112, 1), const AyahRef(112, 2), repeat: 3);
    expect(q.map((e) => e.toString()), ['basmala→112:1', '112:1', '112:1', '112:1', '112:2', '112:2', '112:2']);
    expect(buildQueue(c.quran, const AyahRef(1, 1), const AyahRef(1, 1), repeat: 0), hasLength(1));
  });

  test('scope ends: ayah, page, surah, whole Quran', () {
    final q = c.quran;
    expect(scopeEnd(q, const AyahRef(2, 3), PlayScope.ayah), const AyahRef(2, 3));
    expect(scopeEnd(q, const AyahRef(2, 3), PlayScope.page), q.page(2).end);
    expect(scopeEnd(q, const AyahRef(2, 3), PlayScope.surah), const AyahRef(2, 286));
    expect(scopeEnd(q, const AyahRef(2, 3), PlayScope.toEnd), const AyahRef(114, 6));
    expect(nextAyah(q, const AyahRef(1, 7)), const AyahRef(2, 1));
    expect(nextAyah(q, const AyahRef(114, 6)), isNull);
  });

  test('a whole-Quran queue has 6236 ayahs + 112 basmalas and maps every item to its page', () {
    final all = buildQueue(c.quran, const AyahRef(1, 1), const AyahRef(114, 6));
    expect(all.where((e) => !e.isBasmala), hasLength(6236));
    expect(all.where((e) => e.isBasmala), hasLength(112));
    var last = 1;
    for (final e in all) {
      final p = pageForItem(c.quran, e);
      expect(p, greaterThanOrEqualTo(last), reason: 'pages only move forward ($e)');
      last = p;
    }
    expect(last, 604);
  });

  test('invalid ranges are rejected', () {
    expect(() => buildQueue(c.quran, const AyahRef(2, 5), const AyahRef(2, 4)), throwsArgumentError);
    expect(() => buildQueue(c.quran, const AyahRef(1, 8), const AyahRef(2, 1)), throwsArgumentError);
  });
}
