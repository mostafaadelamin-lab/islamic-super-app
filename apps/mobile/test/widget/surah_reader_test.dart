import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/text.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

void main() {
  late final c = loadContent();
  setUpAll(() => c);

  Future<TestApp> openReader(
    WidgetTester tester,
    int surah, {
    int? ayah,
    String locale = 'ar',
    Map<String, Object> prefs = const {},
  }) async {
    final app = await pumpApp(tester, locale: locale, prefs: prefs);
    await pushScreen(tester, SurahReaderScreen(surah: surah, initialAyah: ayah));
    return app;
  }

  testWidgets('shows ayah text through the render map with Arabic-Indic ayah numbers', (tester) async {
    final app = await openReader(tester, 2);
    final content = app.services.content;
    final stored = content.quran.text(const AyahRef(2, 2));
    final display = content.renderMap.forDisplay(stored);
    expect(display, isNot(stored), reason: '2:2 contains an open tanween that the map changes');
    expect(find.text('$display ${ayahMarker(2)}'), findsOneWidget);
    expect(find.text('$stored ${ayahMarker(2)}'), findsNothing);
    expect(ayahMarker(2), '﴿٢﴾');
    expect(content.quran.text(const AyahRef(2, 2)), stored, reason: 'stored text untouched');
    expect(find.text('سورة البقرة'), findsOneWidget);
    final t = tester.widget<Text>(find.text('$display ${ayahMarker(2)}'));
    expect(t.style!.fontFamily, 'Amiri Quran');
    expect(t.style!.fontSize, 26);
    expect(t.textDirection, TextDirection.rtl);
  });

  testWidgets('font size setting is applied to Quran text', (tester) async {
    final app = await openReader(tester, 1, prefs: {'quranFontSize': 34.0});
    final display = app.services.content.renderMap.forDisplay(app.services.content.quran.text(const AyahRef(1, 1)));
    expect(tester.widget<Text>(find.text('$display ${ayahMarker(1)}')).style!.fontSize, 34);
  });

  testWidgets('translation toggle shows/hides English and persists', (tester) async {
    final app = await openReader(tester, 1);
    expect(find.byKey(const Key('en-1-1')), findsNothing);
    await tester.tap(find.byKey(const Key('toggleTranslation')));
    await tester.pumpAndSettle();
    expect(find.text('In the name of Allah, the Entirely Merciful, the Especially Merciful'), findsOneWidget);
    final en = tester.widget<Text>(find.byKey(const Key('en-1-1')));
    expect(en.textDirection, TextDirection.ltr);
    expect(app.prefs.getBool('showTranslation'), isTrue);
    expect(tester.widget<IconButton>(find.byKey(const Key('toggleTranslation'))).isSelected, isTrue);
    await tester.tap(find.byKey(const Key('toggleTranslation')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('en-1-1')), findsNothing);
    expect(app.prefs.getBool('showTranslation'), isFalse);
  });

  testWidgets('bookmark button adds and removes a bookmark', (tester) async {
    final app = await openReader(tester, 1);
    final btn = find.byKey(const Key('bookmark-1-3'));
    expect(tester.widget<IconButton>(btn).tooltip, 'حفظ علامة على الآية');
    await tester.tap(btn);
    await tester.pump();
    expect(app.services.bookmarks.isBookmarked(const AyahRef(1, 3)), isTrue);
    expect(find.text('تم حفظ العلامة'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(btn).isSelected, isTrue);
    expect(tester.widget<IconButton>(btn).tooltip, 'حذف العلامة');
    expect(app.prefs.getString('bookmarks.v1'), contains('"b-1-3"'));
    await tester.tap(btn);
    await tester.pump();
    expect(find.text('تم حذف العلامة'), findsOneWidget);
    expect(app.services.bookmarks.isBookmarked(const AyahRef(1, 3)), isFalse);
    await tester.pumpAndSettle();
  });

  testWidgets('opening at an ayah scrolls to it, highlights it and records it', (tester) async {
    final app = await openReader(tester, 2, ayah: 255);
    final tile = find.byKey(const Key('ayah-2-255'));
    expect(tile, findsOneWidget);
    expect(tester.getTopLeft(tile).dy, lessThan(200), reason: 'at the top of the viewport');
    final m = tester.widget<Material>(tile);
    expect(m.color, Theme.of(tester.element(tile)).colorScheme.primaryContainer);
    expect(app.services.settings.lastRead, const AyahRef(2, 255));
    // Earlier ayahs are reachable by scrolling up.
    await tester.drag(find.byKey(const Key('surahReader')), const Offset(0, 600));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ayah-2-254')), findsOneWidget);
  });

  testWidgets('tapping an ayah makes it the reading position', (tester) async {
    final app = await openReader(tester, 1);
    await tester.tap(find.byKey(const Key('ayah-1-4')));
    await tester.pumpAndSettle();
    expect(app.services.settings.lastRead, const AyahRef(1, 4));
  });

  testWidgets('"open in Mushaf" goes to the page of the current ayah', (tester) async {
    await openReader(tester, 2, ayah: 255);
    await tester.tap(find.byKey(const Key('openInMushaf')));
    await tester.pumpAndSettle();
    expect(tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page, 42);
  });

  testWidgets('invalid initial ayah falls back to the first ayah', (tester) async {
    final app = await openReader(tester, 1, ayah: 99);
    expect(app.services.settings.lastRead, const AyahRef(1, 1));
  });

  testWidgets('reader is RTL in Arabic UI and English UI keeps Quran text RTL', (tester) async {
    final app = await openReader(tester, 112, locale: 'en');
    expect(Directionality.of(tester.element(find.byType(SurahReaderScreen))), TextDirection.ltr);
    final display = app.services.content.renderMap.forDisplay(app.services.content.quran.text(const AyahRef(112, 1)));
    expect(tester.widget<Text>(find.text('$display ${ayahMarker(1)}')).textDirection, TextDirection.rtl);
    expect(find.text('Al-Ikhlas (The Sincerity)'), findsOneWidget);
  });
}
