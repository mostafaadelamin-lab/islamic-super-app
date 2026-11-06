import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/search_screen.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  Future<void> open(WidgetTester tester, {String locale = 'ar'}) async {
    await pumpApp(tester, locale: locale);
    await goToTab(tester, 1);
  }

  testWidgets('lists all 114 surahs with Arabic and English names, ayah count, revelation', (tester) async {
    await open(tester, locale: 'en');
    expect(find.text('الفاتحة'), findsOneWidget);
    expect(find.text('Al-Fatihah — The Opener · 7 ayahs · Meccan'), findsOneWidget);
    expect(find.text('Al-Baqarah — The Cow · 286 ayahs · Medinan'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('surah-114')),
      500,
      scrollable: find.descendant(of: find.byKey(const Key('surahList')), matching: find.byType(Scrollable)),
    );
    expect(find.text('الناس'), findsOneWidget);
    final list = tester.widget<ListView>(find.byKey(const Key('surahList')));
    expect((list.childrenDelegate as SliverChildBuilderDelegate).childCount, 114);
  });

  testWidgets('Arabic UI shows Arabic-Indic numbers', (tester) async {
    await open(tester);
    expect(find.text('Al-Baqarah — The Cow · ٢٨٦ آية · مدنية'), findsOneWidget);
    expect(find.text('٢'), findsWidgets);
  });

  testWidgets('filter by Arabic name (diacritic-insensitive), number, and English', (tester) async {
    await open(tester);
    final filter = find.byKey(const Key('surahFilter'));
    int count() =>
        (tester.widget<ListView>(find.byKey(const Key('surahList'))).childrenDelegate as SliverChildBuilderDelegate)
            .childCount!;

    await tester.enterText(filter, 'البقره');
    await tester.pumpAndSettle();
    expect(count(), 1);
    expect(find.byKey(const Key('surah-2')), findsOneWidget);

    await tester.enterText(filter, '١١٢');
    await tester.pumpAndSettle();
    expect(count(), 1);
    expect(find.byKey(const Key('surah-112')), findsOneWidget);

    await tester.enterText(filter, 'kahf');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surah-18')), findsOneWidget);
    expect(count(), 1);

    await tester.enterText(filter, 'qqqq');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);

    await tester.enterText(filter, '');
    await tester.pumpAndSettle();
    expect(count(), 114);
  });

  testWidgets('tapping a surah opens the reader', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('surah-2')));
    await tester.pumpAndSettle();
    expect(tester.widget<SurahReaderScreen>(find.byType(SurahReaderScreen)).surah, 2);
  });

  testWidgets('app bar actions open search and Mushaf page 1', (tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('البحث في القرآن'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    await goBack(tester);
    await tester.tap(find.byTooltip('فتح صفحات المصحف'));
    await tester.pumpAndSettle();
    expect(tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page, 1);
  });
}
