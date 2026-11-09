import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/quran_index.dart';
import 'package:rattil/ui/search_screen.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  Future<void> open(WidgetTester tester, {String locale = 'ar'}) async {
    await pumpApp(tester, locale: locale);
    await goToTab(tester, 1);
  }

  int rows(WidgetTester tester, String key) =>
      (tester.widget<ListView>(find.byKey(Key(key))).childrenDelegate as SliverChildBuilderDelegate).childCount!;

  testWidgets('index lists 114 surahs under juz headers with page, ayah count and revelation', (tester) async {
    await open(tester);
    expect(find.text('فهرس السور'), findsOneWidget);
    expect(find.text('السور'), findsOneWidget);
    expect(find.text('الأرباع'), findsOneWidget);
    expect(find.text('الجزء الأول'), findsOneWidget);
    expect(find.text('سورة الفاتحة'), findsOneWidget);
    expect(find.text('الصفحة ١ - آياتها ٧ - مكية'), findsOneWidget);
    expect(find.text('سورة البقرة'), findsOneWidget);
    expect(find.text('الصفحة ٢ - آياتها ٢٨٦ - مدنية'), findsOneWidget);
    // Al-Imran starts in juz 3: juz 2 has no surah start, so it has no header.
    expect(find.text('الجزء الثالث'), findsOneWidget);
    expect(find.text('الجزء الثاني'), findsNothing);
    // 114 surahs + one header per juz that has a surah start.
    expect(rows(tester, 'surahList'), greaterThan(114));
    await tester.scrollUntilVisible(
      find.byKey(const Key('surah-114')),
      600,
      scrollable: find.descendant(of: find.byKey(const Key('surahList')), matching: find.byType(Scrollable)),
    );
    expect(find.text('سورة الناس'), findsOneWidget);
  });

  testWidgets('English UI', (tester) async {
    await open(tester, locale: 'en');
    expect(find.text('Al-Fatihah — The Opener'), findsOneWidget);
    expect(find.text('Page 2 · 286 ayahs · Medinan'), findsOneWidget);
    expect(find.text('Juz 1'), findsOneWidget);
  });

  testWidgets('quarters tab: hizb badges, fractions, surah:ayah and page', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('tabQuarters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('quarterList')), findsOneWidget);
    expect(rows(tester, 'quarterList'), 240 + 30);
    expect(find.text('الجزء الأول'), findsOneWidget);
    expect(find.text('سورة الفاتحة: ١ - الصفحة ١'), findsOneWidget);
    expect(find.text('سورة البقرة: ٢٦ - الصفحة ٥'), findsOneWidget);
    expect(find.text('١/٤'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('سورة البقرة: ٧٥ - الصفحة ١١'),
      200,
      scrollable: find.descendant(of: find.byKey(const Key('quarterList')), matching: find.byType(Scrollable)),
    );
    // Hizb 2 starts at 2:75: its badge shows the hizb number, not a fraction.
    expect(find.descendant(of: find.byKey(const Key('quarter-5')), matching: find.text('٢')), findsOneWidget);
    await tester.tap(find.byKey(const Key('quarter-5')));
    await tester.pumpAndSettle();
    expect(tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page, 11);
  });

  testWidgets('search filters by Arabic name, number and English, and clears', (tester) async {
    await open(tester);
    final filter = find.byKey(const Key('surahFilter'));

    await tester.enterText(filter, 'البقره');
    await tester.pumpAndSettle();
    expect(rows(tester, 'surahList'), 2); // juz header + 1 surah
    expect(find.byKey(const Key('surah-2')), findsOneWidget);

    await tester.enterText(filter, '١١٢');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surah-112')), findsOneWidget);
    expect(rows(tester, 'surahList'), 2);

    await tester.enterText(filter, 'kahf');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surah-18')), findsOneWidget);

    await tester.enterText(filter, 'qqqq');
    await tester.pumpAndSettle();
    expect(find.text('لا توجد نتائج'), findsOneWidget);

    await tester.tap(find.byKey(const Key('clearSearch')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surah-1')), findsOneWidget);

    await tester.tap(find.byKey(const Key('tabQuarters')));
    await tester.pumpAndSettle();
    await tester.enterText(filter, 'الكهف');
    await tester.pumpAndSettle();
    expect(rows(tester, 'quarterList'), greaterThan(1));
    expect(find.textContaining('سورة الكهف:'), findsWidgets);
  });

  testWidgets('tapping a surah opens the Mushaf at its page; the list icon opens the text view', (tester) async {
    await open(tester);
    await tester.tap(find.byKey(const Key('surah-2')));
    await tester.pumpAndSettle();
    expect(tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page, 2);
    await goBack(tester);
    await tester.tap(find.byKey(const Key('surahText-2')));
    await tester.pumpAndSettle();
    expect(tester.widget<SurahReaderScreen>(find.byType(SurahReaderScreen)).surah, 2);
  });

  testWidgets('the last-read surah and quarter are highlighted', (tester) async {
    await pumpApp(tester, prefs: {'lastRead.surah': 2, 'lastRead.ayah': 30});
    await goToTab(tester, 1);
    bool selected(String key) => find
        .descendant(
          of: find.byKey(Key(key)),
          matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.selected == true),
        )
        .evaluate()
        .isNotEmpty;
    expect(selected('surah-2'), isTrue);
    expect(selected('surah-1'), isFalse);
    await tester.tap(find.byKey(const Key('tabQuarters')));
    await tester.pumpAndSettle();
    // 2:30 lies in the quarter that starts at 2:26.
    expect(selected('quarter-2'), isTrue);
    expect(selected('quarter-1'), isFalse);
    expect(selected('quarter-3'), isFalse);
  });

  testWidgets('index sheet returns the chosen page', (tester) async {
    await open(tester);
    final ctx = tester.element(find.byType(QuranIndexView));
    // Page 300 is in al-Kahf: the sheet opens scrolled to it, highlighted.
    final result = showQuranIndexSheet(ctx, currentPage: 300);
    await tester.pumpAndSettle();
    final kahf = find.byKey(const Key('surah-18')).last;
    expect(kahf, findsOneWidget);
    expect(
      find.descendant(
        of: kahf,
        matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.selected == true),
      ),
      findsOneWidget,
    );
    await tester.tap(kahf);
    await tester.pumpAndSettle();
    expect(await result, 293);
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
