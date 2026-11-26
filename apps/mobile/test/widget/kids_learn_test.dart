import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/kids.dart';
import 'package:rattil/domain/kids_learn.dart';
import 'package:rattil/ui/kids_learn_screen.dart';
import 'package:rattil/ui/kids_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

KidsLearnContent _learn() => KidsLearnContent.parse(File('assets/content/kids-learn.v1.json').readAsStringSync());

void main() {
  setUpAll(loadContent);

  test('kids learn content: 600 hadith in four contiguous levels, every picture is bundled', () {
    final k = _learn();
    expect(k.hadith, hasLength(600));
    expect(k.levels.map((l) => l.level), [1, 2, 3, 4]);
    expect(k.levels.first.from, 1);
    expect(k.levels.last.to, 600);
    for (var i = 1; i < k.levels.length; i++) {
      expect(k.levels[i].from, k.levels[i - 1].to + 1);
    }
    for (final h in k.hadith) {
      expect(h.trim(), isNotEmpty);
      expect(h.runes.any((r) => r >= 0xE000 && r <= 0xF8FF), isFalse, reason: 'no private-use glyphs: $h');
    }
    expect(k.books.length, greaterThan(30));
    for (final b in k.books) {
      expect(k.shelves, contains(b.shelf));
      expect(b.pages, greaterThan(0));
      expect(File(b.cover).existsSync(), isTrue, reason: b.cover);
      expect(b.pageUrl(k.booksBase, 1), startsWith('https://'));
    }
    for (final s in k.shelves) {
      expect(k.onShelf(s), isNotEmpty, reason: s);
    }
    // Wudu / salah: the book's title and text per step, our own 3D picture on each step page.
    expect(k.wudu.where((s) => s.pic != null), hasLength(8));
    expect(k.salah.where((s) => s.pic != null), hasLength(12));
    for (final s in [...k.wudu, ...k.salah]) {
      expect(s.title.trim(), isNotEmpty);
      expect(s.text.trim(), isNotEmpty);
      if (s.pic != null) expect(File('assets/kids/steps/${s.pic}.webp').existsSync(), isTrue, reason: s.pic);
    }
    expect(k.wudu[1].title, 'النية والتسمية وغسل الكفين');
    expect(k.salah.last.ayah, contains('الْقَيُّومُ'));
    expect(k.stepsCredit, isNotEmpty);
    // Pillars of Islam (5) / faith (6): intro page + one pictured page per pillar, hadith text.
    expect(k.islam, hasLength(6));
    expect(k.iman, hasLength(7));
    expect(k.islam.where((s) => s.pic != null), hasLength(5));
    expect(k.iman.where((s) => s.pic != null), hasLength(6));
    expect(k.islam.first.text, contains('بُنِيَ الْإِسْلَامُ عَلَى خَمْسٍ'));
    for (final s in [...k.islam, ...k.iman]) {
      expect(s.text.trim(), isNotEmpty);
      if (s.pic != null) expect(File('assets/kids/steps/${s.pic}.webp').existsSync(), isTrue, reason: s.pic);
    }
  });

  testWidgets('kids hub shows the four learning corners', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final kids = KidsContent.parse(File('assets/content/kids.v1.json').readAsStringSync());
    await pushScreen(tester, KidsScreen(loader: () async => kids));
    for (final id in ['books', 'hadith', 'cards', 'wudu', 'salah']) {
      expect(find.byKey(Key('kids.$id')), findsOneWidget, reason: id);
    }
  });

  testWidgets('book shelf: shelves with covers', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final k = _learn();
    await pushScreen(tester, KidsBooksScreen(loader: () async => k));
    expect(find.byKey(const Key('kidsBooks')), findsOneWidget);
    expect(find.byKey(Key('kidsShelf.${k.shelves.first}')), findsOneWidget);
    expect(find.byKey(Key('kidsBook.${k.onShelf(k.shelves.first).first.id}')), findsOneWidget);
  });

  testWidgets('memorise a hadith: the text is the book\'s, «حفظته» is saved and counted', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    final k = _learn();
    await pushScreen(tester, KidsHadithScreen(loader: () async => k));
    expect(find.byKey(const Key('kidsHadith.level4')), findsOneWidget);
    await tester.tap(find.byKey(const Key('kidsHadith.level1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kidsHadith.1')));
    await tester.pumpAndSettle();
    final text = tester.widget<SelectableText>(find.byKey(const Key('kidsHadith.text1')));
    expect(text.data, k.hadithText(1));
    await tester.tap(find.byKey(const Key('kidsHadith.repeat')));
    await tester.tap(find.byKey(const Key('kidsHadith.memorized')));
    await tester.pumpAndSettle();
    expect(app.prefs.getStringList('kidsHadithMemorized'), ['1']);
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    nav.pop();
    await tester.pumpAndSettle();
    nav.pop();
    await tester.pumpAndSettle();
    expect(find.textContaining('حفظت ١ من ٢٠٠'), findsOneWidget);
  });

  test('adhkar cards as text: 19 adhkar from the cards book with their morning / evening counts', () {
    final k = _learn();
    expect(k.cardAdhkar.map((c) => c.n), List.generate(19, (i) => i + 1));
    for (final c in k.cardAdhkar) {
      expect(c.text.trim(), isNotEmpty);
      expect(c.text.runes.any((r) => r >= 0xE000 && r <= 0xF8FF), isFalse, reason: c.text);
      expect(c.morning + c.evening, greaterThan(0));
    }
    // «أعوذ بكلمات الله التامات» is said in the evening only (the card says so).
    expect(k.cardAdhkar[8].morning, 0);
    expect(k.cardAdhkar[8].evening, 1);
    expect(k.cardAdhkar[16].morning, 100);
    expect(k.cardAdhkar[13].surahs, hasLength(3));
    expect(k.cardAdhkarFor(evening: false), hasLength(18));
    expect(k.cardAdhkarFor(evening: true), hasLength(19));
  });

  testWidgets('adhkar cards: tap the counter, a finished dhikr moves on to the next', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final k = _learn();
    await pushScreen(tester, KidsCardsScreen(loader: () async => k, evening: false));
    expect(find.byKey(const Key('kidsCardText-1')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('kidsCardText-1'))).data, k.cardAdhkar.first.text);
    await tester.tap(find.byKey(const Key('kidsCardTap-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kidsCardText-2')), findsOneWidget);
    expect(find.textContaining('أُنجز ١ من ١٨'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('kidsCardsCount'), contains('"m1":1'));
    await tester.tap(find.text('المساء'));
    await tester.pumpAndSettle();
    expect(find.textContaining('أُنجز ٠ من ١٩'), findsOneWidget);
  });

  testWidgets('wudu steps: next to the last step says well done, with the book credit', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final k = _learn();
    await pushScreen(tester, KidsStepsScreen(salah: false, loader: () async => k));
    expect(find.byKey(const Key('kidsSteps.done')), findsNothing);
    expect(tester.widget<Text>(find.byKey(const Key('kidsStep.text.0'))).data, k.wudu.first.text);
    await tester.tap(find.byKey(const Key('pager.next')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('kidsStep.pic.w-hands')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('kidsStep.title.1'))).data, k.wudu[1].title);
    for (var i = 2; i < k.wudu.length; i++) {
      await tester.tap(find.byKey(const Key('pager.next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('kidsSteps.done')), findsOneWidget);
    expect(find.textContaining(k.stepsCredit), findsOneWidget);
  });

  testWidgets('pillars of faith: hadith pages with the generic source line, not the book credit', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final k = _learn();
    await pushScreen(tester, KidsStepsScreen(salah: false, section: 'iman', loader: () async => k));
    expect(find.byKey(const Key('kidsIman.pages')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('kidsStep.text.0'))).data, k.iman.first.text);
    expect(find.textContaining('موسوعة حديثية'), findsOneWidget);
    expect(find.textContaining(k.stepsCredit), findsNothing);
  });
}
