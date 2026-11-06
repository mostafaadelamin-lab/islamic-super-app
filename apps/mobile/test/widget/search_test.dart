import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/text.dart';
import 'package:rattil/ui/search_screen.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  Future<TestApp> openSearch(WidgetTester tester, {String locale = 'ar'}) async {
    final app = await pumpApp(tester, locale: locale);
    await pushScreen(tester, const SearchScreen());
    return app;
  }

  testWidgets('initial hint, then too-short query message', (tester) async {
    await openSearch(tester);
    expect(find.text('البحث يتجاهل التشكيل'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('searchField')), 'ب');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('searchTooShort')), findsOneWidget);
  });

  testWidgets('no results', (tester) async {
    await openSearch(tester);
    await tester.enterText(find.byKey(const Key('searchField')), 'qwerty');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('searchNoResults')), findsOneWidget);
  });

  testWidgets('vocalised and plain queries give the same results; original text shown', (tester) async {
    final app = await openSearch(tester);
    await tester.enterText(find.byKey(const Key('searchField')), 'ٱلۡحَمۡدُ لِلَّهِ رَبِّ');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    final countVocalised = tester.widget<Text>(find.byKey(const Key('searchCount'))).data;
    expect(find.byKey(const Key('hit-1-2')), findsOneWidget);
    final c = app.services.content;
    final original = c.quran.text(const AyahRef(1, 2));
    expect(find.text('${c.renderMap.forDisplay(original)} ${ayahMarker(2)}'), findsOneWidget);
    expect(find.text('الفاتحة : ٢'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('searchField')), 'الحمد لله رب');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('searchCount'))).data, countVocalised);
    final total = c.search.search('الحمد لله رب')!.total;
    expect(countVocalised, '${toArabicIndic(total)} نتيجة');
  });

  testWidgets('tapping a result opens the ayah in the reader', (tester) async {
    await openSearch(tester, locale: 'en');
    await tester.enterText(find.byKey(const Key('searchField')), 'الله لا اله الا هو الحي القيوم');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();
    expect(find.text('2 results'), findsOneWidget);
    await tester.tap(find.byKey(const Key('hit-2-255')));
    await tester.pumpAndSettle();
    final r = tester.widget<SurahReaderScreen>(find.byType(SurahReaderScreen));
    expect((r.surah, r.initialAyah), (2, 255));
    expect(find.byKey(const Key('ayah-2-255')), findsOneWidget);
  });
}
