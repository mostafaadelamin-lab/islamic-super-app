import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/tafsir.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/tafsir.dart';
import 'package:rattil/theme/design_tokens.dart';
import 'package:rattil/ui/ayah_sheet.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

void main() {
  late Map<String, dynamic> stored;
  setUpAll(() async {
    await loadContent();
    stored = readRepoJson('content/tafsir/dist/muyassar.v1.json');
  });

  /// The entry for s:a read straight from content/ (independent of the app's parser).
  String source(int s, int a) => ((stored['surahs'] as List<dynamic>)[s - 1] as List<dynamic>)[a - 1] as String;

  Text shown(WidgetTester tester) => tester.widget<Text>(find.byKey(const Key('tafsirText')));
  AyahRef sheetRef(WidgetTester tester) => tester.state<AyahSheetState>(find.byType(AyahSheet)).ref;

  Future<TestApp> openMushaf(
    WidgetTester tester,
    int page, {
    String locale = 'ar',
    Size size = const Size(390, 844),
    TafsirStore? tafsir,
  }) async {
    final app = await pumpApp(tester, locale: locale, size: size, tafsir: tafsir);
    await pushScreen(tester, PageReaderScreen(initialPage: page));
    return app;
  }

  Future<TestApp> openSurah(
    WidgetTester tester,
    int surah,
    int ayah, {
    String locale = 'ar',
    Size size = const Size(390, 844),
  }) async {
    final app = await pumpApp(tester, locale: locale, size: size);
    await pushScreen(tester, SurahReaderScreen(surah: surah, initialAyah: ayah));
    return app;
  }

  testWidgets('Mushaf: tapping 2:255 shows its Tafsir al-Muyassar exactly as stored, in the UI font', (tester) async {
    final app = await openMushaf(tester, 42);
    await tester.tap(find.byKey(const Key('pageAyah-2-255')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ayahSheet')), findsOneWidget);
    expect(find.text('التفسير الميسر'), findsOneWidget);
    expect(find.text('مجمع الملك فهد لطباعة المصحف الشريف'), findsOneWidget);
    expect(find.byKey(const Key('tafsirArabicOnly')), findsNothing);
    expect(shown(tester).data, source(2, 255));
    expect(shown(tester).style?.fontFamily, DesignTokens.fontUi);
    expect(shown(tester).style?.fontFamily, isNot(DesignTokens.fontQuran));
    // The tafsir comes before the actions.
    expect(
      tester.getTopLeft(find.byKey(const Key('tafsirCard'))).dy,
      lessThan(tester.getTopLeft(find.byKey(const Key('ayahPlay'))).dy),
    );
    expect(app.services.content.quran.text(const AyahRef(2, 255)), isNot(contains(shown(tester).data!)));
  });

  testWidgets('surah reader: tapping 112:1 opens the sheet with its tafsir', (tester) async {
    final app = await openSurah(tester, 112, 1);
    await tester.tap(find.byKey(const Key('ayah-112-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ayahSheet')), findsOneWidget);
    expect(shown(tester).data, source(112, 1));
    expect(find.text('الإخلاص : ١'), findsOneWidget);
    expect(app.services.settings.lastRead, const AyahRef(112, 1));
    expect(find.byKey(const Key('ayahReadList')), findsNothing, reason: 'already reading as a list');
    expect(find.byKey(const Key('ayahBookmark')), findsOneWidget);
  });

  testWidgets('next / previous ayah, across surahs; the Mushaf follows', (tester) async {
    await openMushaf(tester, 42);
    await tester.tap(find.byKey(const Key('pageAyah-2-255')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tafsirNext')));
    await tester.pumpAndSettle();
    expect(sheetRef(tester), const AyahRef(2, 256));
    expect(shown(tester).data, source(2, 256));
    expect(find.text('البقرة : ٢٥٦'), findsOneWidget);
    expect(tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).selected, const AyahRef(2, 256));
    await tester.tap(find.byKey(const Key('tafsirPrev')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tafsirPrev')));
    await tester.pumpAndSettle();
    expect(sheetRef(tester), const AyahRef(2, 254));
    expect(shown(tester).data, source(2, 254));
  });

  testWidgets('next from the last ayah of a surah opens the next surah; no previous before 1:1', (tester) async {
    await openSurah(tester, 1, 7);
    await tester.tap(find.byKey(const Key('ayah-1-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tafsirNext')));
    await tester.pumpAndSettle();
    expect(sheetRef(tester), const AyahRef(2, 1));
    expect(shown(tester).data, source(2, 1));
    await tester.tap(find.byKey(const Key('tafsirPrev')));
    await tester.pumpAndSettle();
    for (var i = 0; i < 6; i++) {
      await tester.tap(find.byKey(const Key('tafsirPrev')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(sheetRef(tester), const AyahRef(1, 1));
    expect(tester.widget<IconButton>(find.byKey(const Key('tafsirPrev'))).onPressed, isNull);
    expect(tester.widget<IconButton>(find.byKey(const Key('tafsirNext'))).onPressed, isNotNull);
  });

  testWidgets('actions in the sheet apply to the ayah shown', (tester) async {
    final app = await openMushaf(tester, 42);
    await tester.tap(find.byKey(const Key('pageAyah-2-255')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('tafsirNext')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahBookmark')));
    await tester.pumpAndSettle();
    expect(app.services.bookmarks.isBookmarked(const AyahRef(2, 256)), isTrue);
    expect(app.services.bookmarks.isBookmarked(const AyahRef(2, 255)), isFalse);
  });

  for (final size in [const Size(320, 568), const Size(390, 844)]) {
    testWidgets('the longest entry (2:282) scrolls inside the sheet without overflow at ${size.width.toInt()}', (
      tester,
    ) async {
      final longest = [
        for (var s = 1; s <= 114; s++)
          for (var a = 1; a <= testTafsir.surahs[s - 1].length; a++) (s, a),
      ].reduce((x, y) => testTafsir.text(x.$1, x.$2)!.length >= testTafsir.text(y.$1, y.$2)!.length ? x : y);
      expect(longest, (2, 282));
      await openSurah(tester, 2, 282, size: size);
      // 2:282 is taller than a small screen: tap its heading row (on the ayah-number label).
      await tester.tapAt(tester.getTopRight(find.byKey(const Key('ayah-2-282'))) + const Offset(-60, 24));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(shown(tester).data, source(2, 282));
      final sheet = tester.getRect(find.byKey(const Key('ayahSheet')));
      expect(sheet.bottom, lessThanOrEqualTo(size.height + 0.01));
      for (final k in ['tafsirCard', 'ayahPlay', 'ayahCopy', 'tafsirNext']) {
        final r = tester.getRect(find.byKey(Key(k)));
        expect(r.left, greaterThanOrEqualTo(-0.01), reason: k);
        expect(r.right, lessThanOrEqualTo(size.width + 0.01), reason: k);
        expect(r.bottom, lessThanOrEqualTo(size.height + 0.01), reason: k);
      }
      final scrollable = find.descendant(of: find.byKey(const Key('tafsirScroll')), matching: find.byType(Scrollable));
      final position = tester.state<ScrollableState>(scrollable).position;
      expect(position.maxScrollExtent, greaterThan(0), reason: 'a 1451-character entry does not fit; it scrolls');
      await tester.drag(find.byKey(const Key('tafsirScroll')), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English UI shows the Arabic tafsir with an "Arabic only" note', (tester) async {
    await openMushaf(tester, 42, locale: 'en');
    await tester.tap(find.byKey(const Key('pageAyah-2-255')));
    await tester.pumpAndSettle();
    expect(find.text('Al-Tafsir al-Muyassar'), findsOneWidget);
    expect(find.text('This tafsir is available in Arabic only.'), findsOneWidget);
    expect(shown(tester).data, source(2, 255));
    expect(shown(tester).textDirection, TextDirection.rtl);
  });

  testWidgets('loads lazily: a spinner until the file is decoded, then the text', (tester) async {
    final done = Completer<TafsirContent>();
    var started = 0;
    final store = TafsirStore(() {
      started++;
      return done.future;
    });
    await openMushaf(tester, 42, tafsir: store);
    expect(started, 0, reason: 'opening the Mushaf does not load the tafsir');
    await tester.tap(find.byKey(const Key('pageAyah-2-255')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(started, 1);
    expect(find.byKey(const Key('tafsirLoading')), findsOneWidget);
    done.complete(testTafsir);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tafsirLoading')), findsNothing);
    expect(shown(tester).data, source(2, 255));
  });

  testWidgets('a load failure shows a message; the actions still work', (tester) async {
    final store = TafsirStore(() async => throw StateError('missing'));
    final app = await openMushaf(tester, 42, tafsir: store);
    await tester.tap(find.byKey(const Key('pageAyah-2-255')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tafsirError')), findsOneWidget);
    await tester.tap(find.byKey(const Key('ayahBookmark')));
    await tester.pumpAndSettle();
    expect(app.services.bookmarks.isBookmarked(const AyahRef(2, 255)), isTrue);
  });
}
