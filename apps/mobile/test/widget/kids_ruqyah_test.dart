import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/printed_mushaf.dart';
import 'package:rattil/data/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rattil/domain/kids.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/kids_screen.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/ruqyah_screen.dart';

import '../helpers.dart';

KidsContent _kids() => KidsContent.parse(File('assets/content/kids.v1.json').readAsStringSync());

void main() {
  setUpAll(loadContent);

  test('kids content: ruqyah verses are valid, duas have text, every episode has an https url', () async {
    final k = _kids();
    final q = (await loadContent()).quran;
    for (final r in [k.ruqyah, k.ruqyahKids]) {
      expect(r.items, isNotEmpty);
      for (final i in r.items) {
        switch (i) {
          case RuqyahQuran(:final range):
            expect(range.from <= range.to && range.to <= q.surah(range.surah).ayahCount, isTrue);
          case RuqyahDua(:final text):
            expect(text.length, greaterThan(10));
        }
      }
    }
    expect(k.ruqyah.full?.url, startsWith('https://'));
    expect(k.ruqyahKids.contains(const AyahRef(112, 1)), isTrue);
    expect(k.byId('kids-prophets')!.episodes.length, greaterThan(20));
    for (final s in k.series) {
      for (final e in s.episodes) {
        expect(e.url, startsWith('https://'));
      }
    }
    expect(k.teacherReciters, contains('Minshawy_Teacher_128kbps'));
  });

  testWidgets('ruqyah: verses in the Mushaf text, duas, and «listen» plays the verses', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    final data = _kids();
    await pushScreen(tester, RuqyahScreen(loader: () async => data));
    expect(find.byKey(const Key('ruqyah')), findsOneWidget);
    expect(find.byKey(const Key('ruqyah.full')), findsOneWidget);
    expect(find.byKey(const Key('ruqyahFlow-1-1')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ruqyah.play')));
    await tester.pump();
    expect(app.services.recitation.currentRef, const AyahRef(1, 1));
  });

  testWidgets('kids ruqyah: the Prophet\'s dua for al-Hasan and al-Husayn, then the three Quls', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final data = _kids();
    await pushScreen(tester, RuqyahScreen(kids: true, loader: () async => data));
    expect(find.byKey(const Key('ruqyahKids')), findsOneWidget);
    expect(find.byKey(const Key('ruqyah.item.0')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('ruqyahFlow-114-1')), 300);
    expect(find.byKey(const Key('ruqyahFlow-114-1')), findsOneWidget);
  });

  testWidgets('kids hub: prophets, teaching Mushaf (opens the kids Mushaf), stories, ruqyah', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    final data = _kids();
    await pushScreen(tester, KidsScreen(loader: () async => data));
    for (final id in ['prophets', 'teacher', 'stories', 'ruqyah']) {
      expect(find.byKey(Key('kids.$id')), findsOneWidget);
    }
    await tester.tap(find.byKey(const Key('kids.prophets')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kidsSeries.kids-prophets')), findsOneWidget);
    await goBack(tester);
    await tester.tap(find.byKey(const Key('kids.teacher')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('teacher.112')),
      400,
      scrollable: find.descendant(of: find.byKey(const Key('teacherList')), matching: find.byType(Scrollable)),
    );
    await tester.tap(find.byKey(const Key('teacher.112')));
    await tester.pumpAndSettle();
    // owner 2026-11-20: a surah opens the interactive kids' Mushaf
    expect(find.byKey(const Key('kidsMushaf.text')), findsOneWidget);
  });

  test('printed Mushaf look is the default; the old look only when chosen (owner 2026-11-20)', () async {
    SharedPreferences.setMockInitialValues({});
    final s = SettingsController(await SharedPreferences.getInstance());
    expect(s.mushafPrinted, isTrue);
    await s.setMushafPrinted(false);
    expect(s.mushafPrinted, isFalse);
  });

  testWidgets('printed Mushaf look: the page is drawn line by line from the page-font layout', (tester) async {
    final layout = PrintedLayout.parse(File('assets/content/mushaf-printed.v1.json').readAsStringSync());
    PrintedMushaf.instance.debugMarkReady(layout, [2, 3]);
    await pumpApp(tester, size: const Size(390, 844), prefs: {'mushaf.printed': true});
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    expect(find.byKey(const Key('mushafPage-3')), findsOneWidget);
    for (var i = 0; i < 15; i++) {
      expect(find.byKey(Key('mushafLine-3-$i')), findsOneWidget);
    }
    expect(find.byKey(const Key('pageAyah-2-6')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('printed layout: every ayah ends once, in Mushaf order, across 604 pages', () {
    final layout = PrintedLayout.parse(File('assets/content/mushaf-printed.v1.json').readAsStringSync());
    var ends = 0;
    for (var p = 1; p <= 604; p++) {
      for (final l in layout.page(p)) {
        if (l is PrintedText) ends += l.words.where((w) => w.isEnd).length;
      }
    }
    expect(ends, 6236);
  });
}
