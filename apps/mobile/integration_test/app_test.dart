// End-to-end flow on a real device/emulator/simulator:
//   flutter test integration_test/app_test.dart -d <device>
// Opens a surah, bookmarks an ayah, checks the bookmark list, goes to a Mushaf
// page by number, turns a page by swiping, taps an ayah and bookmarks it from
// the ayah sheet, counts adhkar and tasbih, and changes the prayer city — with
// the real bundled assets and real shared_preferences storage.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rattil/app.dart';
import 'package:rattil/main.dart' as app;
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> back(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton).last);
    await tester.pumpAndSettle();
  }

  Future<void> tab(WidgetTester tester, int i) async {
    await tester.tap(
      find.descendant(of: find.byType(NavigationBar), matching: find.byType(NavigationDestination)).at(i),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('open surah, bookmark, Mushaf (go to page, swipe, tap ayah), adhkar, tasbih, change city', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setString('locale', 'en');
    final services = await app.bootstrap();
    await tester.pumpWidget(RattilApp(services: services));
    await tester.pumpAndSettle();

    // 1. Open Al-Baqarah from the surah list.
    await tab(tester, 1);
    await tester.tap(find.byKey(const Key('surah-2')));
    await tester.pumpAndSettle();
    expect(find.text('Al-Baqarah (The Cow)'), findsOneWidget);

    // 2. Bookmark 2:2 and see it in the bookmarks tab.
    await tester.tap(find.byKey(const Key('bookmark-2-2')));
    await tester.pumpAndSettle();
    expect(services.bookmarks.active.map((b) => b.id), contains('b-2-2'));
    await back(tester);
    await tab(tester, 4);
    await tester.tap(find.byKey(const Key('more.bookmarks')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('bm-b-2-2')), findsOneWidget);
    expect(prefs.getString('bookmarks.v1'), contains('b-2-2'));
    await back(tester);

    // 3. Go to Mushaf page 50 by number.
    await tab(tester, 1);
    await tester.tap(find.byTooltip('Open Mushaf pages'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('goToPageField')), '50');
    // On a real device the soft keyboard animates in and re-lays out the page,
    // so wait for it to settle before locating the button.
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('goToPageButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goToPageButton')));
    await tester.pumpAndSettle();
    expect(tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page, 50);
    expect(find.text('Page 50'), findsOneWidget);
    expect(find.byKey(const Key('pageAyah-3-1')), findsOneWidget);

    // 4. Swipe to the next page (English UI: LTR, drag left), tap its first ayah, bookmark it.
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    // Drag past the middle of the page so the turn completes on any screen size and binding.
    final pageView = find.byKey(const Key('mushafPageView'));
    await tester.drag(pageView, Offset(-tester.getSize(pageView).width * 0.6, 0));
    await tester.pumpAndSettle();
    expect(tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page, 51);
    expect(find.text('Page 51'), findsOneWidget);
    final first = services.content.quran.page(51).start;
    await tester.tap(find.byKey(Key('pageAyah-${first.surah}-${first.ayah}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ayahSheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ayahBookmark')));
    await tester.pumpAndSettle();
    expect(services.bookmarks.isBookmarked(first), isTrue);
    await back(tester);

    // 5. Morning/evening adhkar: count one item.
    await tab(tester, 3);
    expect(find.byKey(const Key('adhkarNotice')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dhikrTap-0')));
    await tester.pumpAndSettle();
    expect(find.text('Done'), findsWidgets);

    // 6. Tasbih: five taps, saved.
    await tab(tester, 4);
    await tester.tap(find.byKey(const Key('more.tasbih')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byKey(const Key('tasbihButton')));
      await tester.pumpAndSettle();
    }
    expect(find.byKey(const Key('tasbihCount')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('tasbihCount'))).data, '5');
    expect(prefs.getString('tasbih.v1'), contains('"count":5'));
    await back(tester);

    // 7. Change the prayer city to London.
    await tab(tester, 2);
    await tester.tap(find.byKey(const Key('cityTile')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('citySearch')), 'London');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('city-c54')));
    await tester.pumpAndSettle();
    expect(find.text('London'), findsOneWidget);
    expect(find.text('Time zone: Europe/London'), findsOneWidget);
    expect(prefs.getString('cityId'), 'c54');
    for (final k in ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha']) {
      expect(find.byKey(Key('time-$k')), findsOneWidget);
    }
  });
}
