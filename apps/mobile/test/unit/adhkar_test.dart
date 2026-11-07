import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/data/devotions.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  late AppContent c;
  setUpAll(() async => c = await loadContent(realFonts: false));

  test('bundled adhkar and Hisn files are the content/ copies', () {
    expect(readAppJson('assets/content/adhkar.v1.json'), readRepoJson('content/adhkar/dist/adhkar.v1.json'));
    expect(c.adhkar.hisn, hasLength(134));
  });

  test('34 items, texts unchanged from adhkar.v1.json', () {
    final src = readRepoJson('content/adhkar/dist/adhkar.v1.json')['items'] as List<dynamic>;
    expect(c.adhkar.items, hasLength(34));
    for (var i = 0; i < src.length; i++) {
      expect(c.adhkar.items[i].text, src[i]);
    }
  });

  group('counts and sessions are those stated in Hisn al-Muslim "أذكار الصباح والمساء"', () {
    late HisnChapter chapter;
    setUpAll(() => chapter = c.adhkar.hisn.firstWhere((h) => h.title == hisnMorningEveningTitle));

    String norm(String s) =>
        c.normalizer.normalize(s).replaceAll(RegExp(r'[^\u0621-\u064A ]'), ' ').replaceAll(RegExp(r' +'), ' ').trim();

    test('every item points at the matching Hisn entry (same opening words)', () {
      for (final d in c.adhkar.items) {
        final i = d.meta.hisnIndex;
        if (i == null) {
          expect(d.index, 2, reason: 'only al-Baqarah 285-286 is not in the chapter');
          continue;
        }
        final h = norm(chapter.items[i]);
        // Drop the isti'adha / basmala openers and compare the first words.
        final words = norm(
          d.text,
        ).replaceFirst('اعوذ بالله من الشيطان الرجيم', '').split(' ').where((w) => w.length > 1).toList();
        final probe = words.take(3).join(' ');
        expect(
          h.contains(probe.replaceAll('امسي', 'اصبح').replaceAll('امسينا', 'اصبحنا')) || h.contains(probe),
          isTrue,
          reason: 'item ${d.index}: "$probe" in Hisn entry $i',
        );
      }
    });

    test('repetition counts', () {
      for (final d in c.adhkar.items) {
        final i = d.meta.hisnIndex;
        final expected = i == null ? 1 : countStatedIn(chapter.items[i]);
        expect(d.meta.count, expected, reason: 'item ${d.index}');
      }
    });

    test('morning / evening', () {
      for (final d in c.adhkar.items) {
        final i = d.meta.hisnIndex;
        if (i == null) continue;
        final h = chapter.items[i];
        final t = norm(d.text);
        final m = t.indexOf('اصبح');
        final e = t.indexOf('امسي');
        final Set<AdhkarSession> expected;
        if (h.contains('إذا أصبح')) {
          expected = {AdhkarSession.morning};
        } else if (h.contains('إذا أمسى')) {
          expected = {AdhkarSession.evening};
        } else if (m >= 0 && (e < 0 || m < e)) {
          expected = {AdhkarSession.morning};
        } else if (e >= 0) {
          expected = {AdhkarSession.evening};
        } else {
          expected = {AdhkarSession.morning, AdhkarSession.evening};
        }
        expect(d.meta.sessions, expected, reason: 'item ${d.index}');
      }
      expect(c.adhkar.forSession(AdhkarSession.morning), hasLength(26));
      expect(c.adhkar.forSession(AdhkarSession.evening), hasLength(25));
    });
  });

  test('countStatedIn reads the Arabic count phrases', () {
    expect(countStatedIn('... ( ثلاث مرات )'), 3);
    expect(countStatedIn('(مائة مرة إذا أصبح )'), 100);
    expect(countStatedIn('بلا عدد'), 1);
  });

  test('AdhkarProgress counts down per item and stops at zero', () {
    final items = c.adhkar.forSession(AdhkarSession.morning);
    final p = AdhkarProgress(items);
    final three = items.firstWhere((d) => d.meta.count == 3);
    expect(p.remaining(three), 3);
    expect(p.tap(three), isTrue);
    expect(p.tap(three), isTrue);
    expect(p.remaining(three), 1);
    expect(p.isDone(three), isFalse);
    expect(p.tap(three), isTrue);
    expect(p.isDone(three), isTrue);
    expect(p.tap(three), isFalse, reason: 'no counting past the target');
    expect(p.completedItems, 1);
    expect(p.fraction, closeTo(1 / items.length, 1e-12));
    p.reset(three);
    expect(p.remaining(three), 3);
  });

  test('AdhkarController persists today and resets on a new day', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsController(prefs);
    var today = DateTime.utc(2026, 1, 15);
    final ctl = AdhkarController(c, settings, () => today);
    final d = ctl.progress(AdhkarSession.evening).items.first;
    await ctl.tap(AdhkarSession.evening, d);
    expect(ctl.progress(AdhkarSession.evening).countOf(d), 1);
    // A new controller on the same storage (app restart) keeps the count.
    final again = AdhkarController(c, settings, () => today);
    expect(again.progress(AdhkarSession.evening).countOf(d), 1);
    expect(again.progress(AdhkarSession.morning).completedItems, 0, reason: 'sessions are separate');
    today = DateTime.utc(2026, 1, 16);
    expect(again.progress(AdhkarSession.evening).countOf(d), 0, reason: 'new day, fresh counters');
  });
}
