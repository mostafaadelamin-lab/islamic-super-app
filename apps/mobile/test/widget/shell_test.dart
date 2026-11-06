import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/bookmarks_screen.dart';
import 'package:rattil/ui/home_screen.dart';
import 'package:rattil/ui/prayer_screen.dart';
import 'package:rattil/ui/settings_screen.dart';
import 'package:rattil/ui/surah_list_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  final tabs = <Type>[HomeScreen, SurahListScreen, PrayerScreen, BookmarksScreen, SettingsScreen];

  testWidgets('Arabic is the default locale and the layout is RTL', (tester) async {
    await pumpApp(tester, prefs: const {});
    expect(find.text('رتّل'), findsWidgets);
    final dir = Directionality.of(tester.element(find.byType(HomeScreen)));
    expect(dir, TextDirection.rtl);
    expect(find.text('الرئيسية'), findsOneWidget);
  });

  testWidgets('English is LTR', (tester) async {
    await pumpApp(tester, locale: 'en');
    expect(Directionality.of(tester.element(find.byType(HomeScreen))), TextDirection.ltr);
    expect(find.text('Rattil'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('bottom navigation reaches every tab ($locale)', (tester) async {
      await pumpApp(tester, locale: locale);
      for (var i = 0; i < tabs.length; i++) {
        await goToTab(tester, i);
        expect(find.byType(tabs[i]), findsOneWidget, reason: 'tab $i');
        final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
        expect(bar.selectedIndex, i);
      }
    });

    for (final scale in [1.5, 2.0]) {
      testWidgets('every tab lays out without overflow at text scale $scale ($locale)', (tester) async {
        await pumpApp(tester, locale: locale, textScale: scale);
        for (var i = 0; i < tabs.length; i++) {
          await goToTab(tester, i);
          expect(tester.takeException(), isNull, reason: 'tab $i');
          final mq = MediaQuery.of(tester.element(find.byType(tabs[i])));
          expect(mq.textScaler.scale(10), closeTo(10 * scale, 1e-9));
        }
      });
    }
  }

  testWidgets('a small phone (320x568) renders every tab', (tester) async {
    await pumpApp(tester, size: const Size(320, 568));
    for (var i = 0; i < tabs.length; i++) {
      await goToTab(tester, i);
      expect(tester.takeException(), isNull, reason: 'tab $i');
    }
  });
}
