import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/home_shell.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/prayer_screen.dart';
import 'package:rattil/ui/search_screen.dart';
import 'package:rattil/ui/surah_list_screen.dart';
import 'package:rattil/ui/bookmarks_screen.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  testWidgets('shows greeting and the free tagline', (tester) async {
    await pumpApp(tester, locale: 'en');
    expect(find.text('Peace be upon you'), findsOneWidget);
    expect(find.text('Quran, prayer and remembrance — free, no ads'), findsOneWidget);
  });

  testWidgets('"Start reading" opens Al-Fatihah and records the position', (tester) async {
    final app = await pumpApp(tester);
    expect(find.text('ابدأ القراءة'), findsOneWidget);
    await tester.tap(find.text('ابدأ القراءة'));
    await tester.pumpAndSettle();
    final reader = tester.widget<SurahReaderScreen>(find.byType(SurahReaderScreen));
    expect(reader.surah, 1);
    expect(app.services.settings.lastRead, const AyahRef(1, 1));
    await goBack(tester);
    expect(find.text('متابعة القراءة'), findsOneWidget);
  });

  testWidgets('"Continue reading" reopens the last ayah', (tester) async {
    await pumpApp(tester, prefs: {'lastRead.surah': 2, 'lastRead.ayah': 255});
    expect(find.text('متابعة القراءة'), findsOneWidget);
    expect(find.text('البقرة : ٢٥٥'), findsOneWidget);
    await tester.tap(find.text('متابعة القراءة'));
    await tester.pumpAndSettle();
    final reader = tester.widget<SurahReaderScreen>(find.byType(SurahReaderScreen));
    expect(reader.surah, 2);
    expect(reader.initialAyah, 255);
    expect(find.byKey(const Key('ayah-2-255')), findsOneWidget);
  });

  testWidgets('next prayer card shows the computed time and opens the prayer tab', (tester) async {
    await pumpApp(tester);
    // fixedNow = 12:00 Cairo on 2026-01-15; Dhuhr is 12:05 (adhan-js vector).
    expect(find.text('الصلاة القادمة: الظهر'), findsOneWidget);
    expect(find.textContaining('١٢:٠٥'), findsOneWidget);
    expect(find.textContaining('٠:٠٥:٠٠'), findsOneWidget);
    await tester.tap(find.byKey(const Key('home.nextPrayer')));
    await tester.pumpAndSettle();
    expect(find.byType(PrayerScreen), findsOneWidget);
    expect(tester.state<HomeShellState>(find.byType(HomeShell)).index, 2);
  });

  testWidgets('quick links: surahs, Mushaf, search, bookmarks', (tester) async {
    await pumpApp(tester, locale: 'en', prefs: {'lastRead.surah': 2, 'lastRead.ayah': 255}, size: tallPhone);
    await tester.tap(find.text('Surahs'));
    await tester.pumpAndSettle();
    expect(find.byType(SurahListScreen), findsOneWidget);

    await goToTab(tester, 0);
    await tester.tap(find.text('Mushaf pages'));
    await tester.pumpAndSettle();
    expect(
      tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page,
      42,
      reason: 'opens the page of the last-read ayah (2:255)',
    );
    await goBack(tester);

    await tester.tap(find.text('Search the Quran'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchScreen), findsOneWidget);
    await goBack(tester);

    await tester.tap(find.text('Bookmarks').first);
    await tester.pumpAndSettle();
    expect(find.byType(BookmarksScreen), findsOneWidget);
  });

  testWidgets('home shows the polar message when no times exist', (tester) async {
    final c = await loadContent();
    await pumpApp(
      tester,
      locale: 'en',
      content: withPolarCity(c),
      prefs: {'cityId': 'polar'},
      clock: () => DateTime.utc(2026, 12, 21, 12),
    );
    expect(find.text('Prayer times cannot be calculated here today (polar day or night)'), findsOneWidget);
  });
}
