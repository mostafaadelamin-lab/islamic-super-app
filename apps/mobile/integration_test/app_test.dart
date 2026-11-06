// End-to-end flow on a real device/emulator/simulator:
//   flutter test integration_test/app_test.dart -d <device>
// Opens a surah, bookmarks an ayah, checks the bookmark list, goes to a Mushaf
// page by number and changes the prayer city — with the real bundled assets
// and real shared_preferences storage.
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

  testWidgets('open surah, bookmark, go to page, change city', (tester) async {
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
    await tab(tester, 3);
    expect(find.byKey(const Key('bm-b-2-2')), findsOneWidget);
    expect(prefs.getString('bookmarks.v1'), contains('b-2-2'));

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
    await back(tester);

    // 4. Change the prayer city to London.
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
