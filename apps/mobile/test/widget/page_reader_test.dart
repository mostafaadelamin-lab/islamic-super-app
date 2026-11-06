import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  Future<TestApp> openPage(WidgetTester tester, int page, {String locale = 'ar'}) async {
    final app = await pumpApp(tester, locale: locale);
    await pushScreen(tester, PageReaderScreen(initialPage: page));
    return app;
  }

  Future<void> scrollTo(WidgetTester tester, int p, Key key) => tester.scrollUntilVisible(
    find.byKey(key),
    300,
    scrollable: find.descendant(of: find.byKey(Key('mushafPage-$p')), matching: find.byType(Scrollable)),
  );

  int page(WidgetTester tester) => tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page;

  testWidgets('page 1 shows Al-Fatihah with page/juz header', (tester) async {
    await openPage(tester, 1);
    expect(find.text('صفحة ١'), findsOneWidget);
    expect(find.text('الجزء ١'), findsOneWidget);
    for (var a = 1; a <= 7; a++) {
      expect(find.byKey(Key('pageAyah-1-$a')), findsOneWidget);
    }
    expect(find.byKey(const Key('pageAyah-2-1')), findsNothing);
    expect(find.text('سورة الفاتحة'), findsOneWidget);
  });

  testWidgets('next/previous buttons move one page and disable at the ends', (tester) async {
    final app = await openPage(tester, 1);
    final prev = find.byKey(const Key('prevPage'));
    final next = find.byKey(const Key('nextPage'));
    expect(tester.widget<IconButton>(prev).onPressed, isNull);
    await tester.tap(next);
    await tester.pumpAndSettle();
    expect(page(tester), 2);
    expect(find.text('صفحة ٢'), findsOneWidget);
    expect(find.byKey(const Key('pageAyah-2-1')), findsOneWidget);
    expect(app.services.settings.lastRead, const AyahRef(2, 1));
    await tester.tap(prev);
    await tester.pumpAndSettle();
    expect(page(tester), 1);
  });

  testWidgets('last page has next disabled and shows 112..114', (tester) async {
    await openPage(tester, 604);
    expect(tester.widget<IconButton>(find.byKey(const Key('nextPage'))).onPressed, isNull);
    expect(find.text('صفحة ٦٠٤'), findsOneWidget);
    expect(find.text('الجزء ٣٠'), findsOneWidget);
    expect(find.byKey(const Key('pageAyah-112-1')), findsOneWidget);
    await scrollTo(tester, 604, const Key('pageAyah-114-6'));
    expect(find.byKey(const Key('pageAyah-114-6')), findsOneWidget);
    expect(find.byKey(const Key('pageAyah-111-5')), findsNothing);
  });

  testWidgets('swiping changes the page (RTL: drag right for the next page)', (tester) async {
    await openPage(tester, 10);
    await tester.fling(find.byKey(const Key('mushafPageView')), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();
    expect(page(tester), 11);
    await tester.fling(find.byKey(const Key('mushafPageView')), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(page(tester), 10);
  });

  testWidgets('swiping in English UI follows LTR (drag left for the next page)', (tester) async {
    await openPage(tester, 10, locale: 'en');
    await tester.fling(find.byKey(const Key('mushafPageView')), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(page(tester), 11);
    expect(find.text('Page 11'), findsOneWidget);
  });

  testWidgets('go to page: valid numbers in Latin and Arabic-Indic digits', (tester) async {
    await openPage(tester, 1);
    await tester.enterText(find.byKey(const Key('goToPageField')), '604');
    await tester.tap(find.byKey(const Key('goToPageButton')));
    await tester.pumpAndSettle();
    expect(page(tester), 604);
    await scrollTo(tester, 604, const Key('pageAyah-114-6'));
    expect(find.byKey(const Key('pageAyah-114-6')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('goToPageField')), '٥٠');
    await tester.testTextInput.receiveAction(TextInputAction.go);
    await tester.pumpAndSettle();
    expect(page(tester), 50);
    expect(find.byKey(const Key('pageAyah-3-1')), findsOneWidget);
    expect(find.text('الجزء ٣'), findsOneWidget);
  });

  for (final bad in ['0', '605', 'abc', '', '-1', '2.5']) {
    testWidgets('go to page rejects "$bad" with a validation message', (tester) async {
      await openPage(tester, 7);
      await tester.enterText(find.byKey(const Key('goToPageField')), bad);
      await tester.tap(find.byKey(const Key('goToPageButton')));
      await tester.pumpAndSettle();
      expect(find.text('أدخل رقمًا صحيحًا من ١ إلى ٦٠٤'), findsOneWidget);
      expect(page(tester), 7);
      await tester.enterText(find.byKey(const Key('goToPageField')), '8');
      await tester.tap(find.byKey(const Key('goToPageButton')));
      await tester.pumpAndSettle();
      expect(find.text('أدخل رقمًا صحيحًا من ١ إلى ٦٠٤'), findsNothing);
      expect(page(tester), 8);
    });
  }

  testWidgets('a leftover snackbar is cleared so the Go button is tappable (DEF-008)', (tester) async {
    await pumpApp(tester, locale: 'en');
    final messenger = ScaffoldMessenger.of(tester.element(find.byType(Navigator).first));
    messenger.showSnackBar(const SnackBar(content: Text('Bookmarked'), duration: Duration(minutes: 1)));
    await tester.pumpAndSettle();
    expect(find.text('Bookmarked'), findsOneWidget);
    await pushScreen(tester, const PageReaderScreen(initialPage: 1));
    expect(find.text('Bookmarked'), findsNothing);
    await tester.enterText(find.byKey(const Key('goToPageField')), '50');
    await tester.tap(find.byKey(const Key('goToPageButton')), warnIfMissed: true);
    await tester.pumpAndSettle();
    expect(page(tester), 50);
  });
}
