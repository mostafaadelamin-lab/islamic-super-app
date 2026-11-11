import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/adaptive.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/home_screen.dart';
import 'package:rattil/ui/more_screen.dart';
import 'package:rattil/ui/mushaf_page.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/prayer_screen.dart';
import 'package:rattil/ui/reels_screen.dart';
import 'package:rattil/ui/settings_screen.dart';
import 'package:rattil/ui/surah_list_screen.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

/// iPad sizes (points): 11" portrait and landscape, 13" landscape.
const ipadPortrait = Size(834, 1194);
const ipadLandscape = Size(1194, 834);
const ipadLarge = Size(1366, 1024);

void main() {
  setUpAll(loadContent);

  final tabs = <Type>[HomeScreen, SurahListScreen, PrayerScreen, AdhkarScreen, ReelsScreen, MoreScreen];

  for (final locale in ['ar', 'en']) {
    for (final size in [ipadPortrait, ipadLandscape, ipadLarge]) {
      testWidgets('a side rail reaches every tab on ${size.width.toInt()}x${size.height.toInt()} ($locale)', (
        tester,
      ) async {
        await pumpApp(tester, locale: locale, size: size);
        expect(find.byKey(const Key('navRail')), findsOneWidget);
        expect(find.byKey(const Key('navBar')), findsNothing);
        final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
        expect(rail.extended, size.width >= Adaptive.expanded);
        for (var i = 0; i < tabs.length; i++) {
          await goToTab(tester, i);
          expect(find.byType(tabs[i]), findsOneWidget, reason: 'tab $i');
          expect(tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex, i);
          expect(tester.takeException(), isNull, reason: 'tab $i');
          // The tab is centred at a comfortable width, not stretched edge to edge.
          expect(tester.getSize(find.byType(tabs[i])).width, lessThanOrEqualTo(Adaptive.tabWidth));
        }
      });
    }
  }

  testWidgets('the rail sits on the right in Arabic and on the left in English', (tester) async {
    await pumpApp(tester, size: ipadLandscape);
    expect(tester.getCenter(find.byType(NavigationRail)).dx, greaterThan(ipadLandscape.width / 2));
    await pumpApp(tester, locale: 'en', size: ipadLandscape);
    expect(tester.getCenter(find.byType(NavigationRail)).dx, lessThan(ipadLandscape.width / 2));
  });

  testWidgets('a phone keeps the bottom bar', (tester) async {
    await pumpApp(tester, size: const Size(412, 915));
    expect(find.byKey(const Key('navBar')), findsOneWidget);
    expect(find.byKey(const Key('navRail')), findsNothing);
  });

  testWidgets('pushed screens keep text at a readable width on a tablet', (tester) async {
    await pumpApp(tester, locale: 'en', size: ipadLarge);
    await pushScreen(tester, const SurahReaderScreen(surah: 1));
    expect(tester.getSize(find.byType(CustomScrollView).first).width, Adaptive.readableWidth);
    expect(tester.takeException(), isNull);
    await goBack(tester);
    await pushScreen(tester, const SettingsScreen());
    expect(tester.getSize(find.byType(ReadableWidth).first).width, ipadLarge.width);
    expect(tester.getSize(find.byType(Scrollable).first).width, Adaptive.readableWidth);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Mushaf page keeps book proportions on a tablet', (tester) async {
    await pumpApp(tester, size: ipadLarge);
    await pushScreen(tester, const PageReaderScreen(initialPage: 1));
    final page = tester.getSize(find.byType(MushafPageView));
    expect(page.width, lessThan(ipadLarge.width / 2));
    expect(page.width / page.height, closeTo(Adaptive.mushafAspect, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a Mushaf page fills a phone', (tester) async {
    await pumpApp(tester, size: const Size(412, 915));
    await pushScreen(tester, const PageReaderScreen(initialPage: 1));
    expect(tester.getSize(find.byType(MushafPageView)).width, 412);
  });
}
