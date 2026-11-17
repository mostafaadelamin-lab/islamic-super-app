import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

// Owner 2026-11-17: «معاني الكلمات» of each Mushaf page from a small icon in the reader's options,
// and of one ayah from its menu. Text: «السراج في بيان غريب القرآن», verbatim.
void main() {
  setUpAll(loadContent);

  Future<void> open(WidgetTester tester, int page) async {
    await pumpApp(tester, size: const Size(390, 844));
    await pushScreen(tester, PageReaderScreen(initialPage: page));
  }

  test('the bundled file is the repository file, one list per ayah', () {
    final dist = jsonDecode(File('../../content/word-meanings/dist/siraj.v1.json').readAsStringSync()) as Map;
    final m = testMeanings;
    expect(m.nameAr, 'السراج في بيان غريب القرآن');
    expect(m.wordCount, dist['wordCount']);
    expect(m.wordCount, greaterThan(6000));
    final surahs = dist['surahs'] as List;
    for (var s = 1; s <= 114; s++) {
      final ayahs = surahs[s - 1] as List;
      for (var a = 1; a <= ayahs.length; a++) {
        expect([
          for (final w in m.words(s, a)) [w.word, w.meaning],
        ], ayahs[a - 1]);
      }
    }
    expect(m.words(114, 4), hasLength(2));
    expect(m.words(115, 1), isEmpty);
  });

  testWidgets('the bottom bar opens the page\'s word meanings; an ayah name selects it', (tester) async {
    await open(tester, 50);
    await tester.tap(find.byKey(const Key('barMeanings')));
    await tester.pumpAndSettle();
    expect(find.text('معاني كلمات الصفحة ٥٠'), findsOneWidget);
    final first = testMeanings.words(3, 2).first;
    expect(find.textContaining(first.meaning, findRichText: true), findsOneWidget);
    expect(find.byKey(const Key('wordMeaningsSource')), findsOneWidget);

    await tester.tap(find.byKey(const Key('wordMeaningsAyah-3:7')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wordMeanings')), findsNothing);
    expect(find.byKey(const Key('ayahActions')), findsOneWidget);
    expect(find.byKey(const Key('ayahSheetTitle')), findsOneWidget);
  });

  testWidgets('the ayah menu shows that ayah\'s words, or says there are none', (tester) async {
    await open(tester, 50);
    await tester.tap(find.byKey(const Key('pageAyah-3-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahMeanings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wordMeaningItem')), findsNWidgets(testMeanings.words(3, 7).length));
    await tester.tap(find.byKey(const Key('wordMeaningsClose')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pageAyah-3-3')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahMeanings')));
    await tester.pumpAndSettle();
    expect(testMeanings.words(3, 3), isEmpty);
    expect(find.byKey(const Key('wordMeaningsNone')), findsOneWidget);
  });
}
