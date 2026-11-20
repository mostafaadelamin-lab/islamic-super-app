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
    for (final p in [...k.wudu, ...k.salah]) {
      expect(File('assets/kids/wudu/$p.webp').existsSync(), isTrue);
    }
    for (final p in k.cards) {
      expect(File('assets/kids/cards/b$p.webp').existsSync(), isTrue);
      expect(File('assets/kids/cards/g$p.webp').existsSync(), isTrue);
    }
    expect(k.stepsCredit, isNotEmpty);
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

  testWidgets('adhkar cards: boys / girls, a star for a card said today', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final k = _learn();
    await pushScreen(tester, KidsCardsScreen(loader: () async => k));
    expect(find.byKey(const Key('kidsCards.pages')), findsOneWidget);
    await tester.tap(find.text('بنات'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('kidsCards.done')));
    await tester.pumpAndSettle();
    expect(find.textContaining('نجومك اليوم'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('kidsCardsDone'), contains('${k.cards.first}'));
  });

  testWidgets('wudu steps: next to the last step says well done, with the book credit', (tester) async {
    await pumpApp(tester, size: tallPhone);
    final k = _learn();
    await pushScreen(tester, KidsStepsScreen(salah: false, loader: () async => k));
    expect(find.byKey(const Key('kidsSteps.done')), findsNothing);
    for (var i = 1; i < k.wudu.length; i++) {
      await tester.tap(find.byKey(const Key('pager.next')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('kidsSteps.done')), findsOneWidget);
    expect(find.textContaining(k.stepsCredit), findsOneWidget);
  });
}
