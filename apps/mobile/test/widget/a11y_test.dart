// Accessibility guidelines on every tab and pushed screen. This file does NOT
// load the real fonts, so that textContrastGuideline measures solid test-font
// glyphs (see expectAccessible in helpers.dart).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  setUpAll(() => loadContent(realFonts: false));

  Future<void> visitAll(WidgetTester tester, {required bool contrast}) async {
    for (var i = 0; i < 5; i++) {
      await goToTab(tester, i);
      await expectAccessible(tester, contrast: contrast);
    }
    // Pushed screens.
    await goToTab(tester, 1);
    await tester.tap(find.byKey(const Key('surah-1')));
    await tester.pumpAndSettle();
    await expectAccessible(tester, contrast: contrast);
    await tester.tap(find.byKey(const Key('openInMushaf')));
    await tester.pumpAndSettle();
    await expectAccessible(tester, contrast: contrast);
    await goBack(tester);
    await goBack(tester);
    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('searchField')), 'الرحمن');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();
    await expectAccessible(tester, contrast: contrast);
    await goBack(tester);
    await goToTab(tester, 2);
    await tester.tap(find.byKey(const Key('cityTile')));
    await tester.pumpAndSettle();
    await expectAccessible(tester, contrast: contrast);
    await goBack(tester);
    await openSettings(tester);
    await tester.tap(find.byKey(const Key('accountTile')));
    await tester.pumpAndSettle();
    await expectAccessible(tester, contrast: contrast);
    await goBack(tester);
    await tester.tap(find.byKey(const Key('aboutTile')));
    await tester.pumpAndSettle();
    await expectAccessible(tester, contrast: contrast);
  }

  for (final theme in ['light', 'dark']) {
    testWidgets('en/$theme: tap targets, labels and text contrast on all screens', (tester) async {
      await pumpApp(tester, locale: 'en', prefs: {'theme': theme}, size: tallPhone);
      await visitAll(tester, contrast: true);
    });
    testWidgets('ar/$theme: tap targets and labels on all screens', (tester) async {
      await pumpApp(tester, locale: 'ar', prefs: {'theme': theme}, size: tallPhone);
      await visitAll(tester, contrast: false);
    });
  }

  testWidgets('bookmarked ayah and adjustment rows meet the guidelines (en)', (tester) async {
    await pumpApp(
      tester,
      locale: 'en',
      size: tallPhone,
      prefs: {'bookmarks.v1': '[{"id":"b-1-1","surah":1,"ayah":1,"updatedAt":1,"deleted":false}]'},
    );
    await openBookmarks(tester);
    await expectAccessible(tester, contrast: true);
    await goBack(tester);
    await goToTab(tester, 2);
    await tester.tap(find.byKey(const Key('adjustTile')));
    await tester.pumpAndSettle();
    await expectAccessible(tester, contrast: true);
  });
}
