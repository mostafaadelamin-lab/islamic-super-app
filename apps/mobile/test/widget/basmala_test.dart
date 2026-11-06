import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/text.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/surah_reader_screen.dart';

import '../helpers.dart';

/// DEF-001: the unnumbered basmala line before each surah (except 1 and 9),
/// as in the printed Madinah Mushaf and the web app.
void main() {
  setUpAll(loadContent);

  String basmalaDisplay(TestApp app) =>
      app.services.content.renderMap.forDisplay(app.services.content.quran.text(const AyahRef(1, 1)));

  void expectBasmala(WidgetTester tester, TestApp app, int surah) {
    final line = find.byKey(Key('basmala-$surah'));
    expect(line, findsOneWidget);
    final texts = tester.widgetList<Text>(find.descendant(of: line, matching: find.byType(Text))).toList();
    expect(texts, hasLength(1));
    expect(texts.single.data, basmalaDisplay(app), reason: 'canonical 1:1 text, render map applied, no ayah number');
    expect(texts.single.data, isNot(contains('﴿')));
    expect(
      find.descendant(of: line, matching: find.byType(IconButton)),
      findsNothing,
      reason: 'not bookmarkable',
    );
  }

  for (final surah in [2, 112]) {
    testWidgets('surah reader: surah $surah starts with the basmala line', (tester) async {
      final app = await pumpApp(tester);
      await pushScreen(tester, SurahReaderScreen(surah: surah));
      expectBasmala(tester, app, surah);
      final basmalaY = tester.getTopLeft(find.byKey(Key('basmala-$surah'))).dy;
      expect(basmalaY, lessThan(tester.getTopLeft(find.byKey(Key('ayah-$surah-1'))).dy));
      // Ayah 1 keeps its own number and bookmark button.
      expect(find.byKey(Key('bookmark-$surah-1')), findsOneWidget);
      expect(find.text('${basmalaDisplay(app)} ${ayahMarker(1)}'), findsNothing);
    });
  }

  for (final surah in [1, 9]) {
    testWidgets('surah reader: surah $surah has no separate basmala line', (tester) async {
      await pumpApp(tester);
      await pushScreen(tester, SurahReaderScreen(surah: surah));
      expect(find.byKey(Key('basmala-$surah')), findsNothing);
      expect(find.byKey(Key('ayah-$surah-1')), findsOneWidget);
    });
  }

  testWidgets('surah reader opened mid-surah shows the basmala when scrolled to the start', (tester) async {
    final app = await pumpApp(tester);
    await pushScreen(tester, const SurahReaderScreen(surah: 2, initialAyah: 3));
    await tester.drag(find.byKey(const Key('surahReader')), const Offset(0, 800));
    await tester.pumpAndSettle();
    expectBasmala(tester, app, 2);
  });

  testWidgets('page 604: three banners and three basmalas (112, 113, 114)', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const PageReaderScreen(initialPage: 604));
    for (final s in [112, 113, 114]) {
      expect(find.byKey(Key('surahBanner-$s')), findsOneWidget);
      expectBasmala(tester, app, s);
    }
    expect(
      find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('basmala-'),
      ),
      findsNWidgets(3),
    );
    expect(
      find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('surahBanner-'),
      ),
      findsNWidgets(3),
    );
  });

  testWidgets('page 1: Al-Fatihah banner only, no extra basmala line', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const PageReaderScreen(initialPage: 1));
    expect(find.byKey(const Key('surahBanner-1')), findsOneWidget);
    expect(find.byKey(const Key('basmala-1')), findsNothing);
    expect(
      find.byWidgetPredicate(
        (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('basmala-'),
      ),
      findsNothing,
    );
  });

  testWidgets('page where surah 9 starts: banner without basmala', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    final p = app.services.content.quran.pageOf(const AyahRef(9, 1));
    await pushScreen(tester, PageReaderScreen(initialPage: p));
    expect(find.byKey(const Key('surahBanner-9')), findsOneWidget);
    expect(find.byKey(const Key('basmala-9')), findsNothing);
  });

  testWidgets('page 2 (start of Al-Baqarah): banner then basmala then 2:1', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const PageReaderScreen(initialPage: 2));
    expectBasmala(tester, app, 2);
    final banner = tester.getTopLeft(find.byKey(const Key('surahBanner-2'))).dy;
    final basmala = tester.getTopLeft(find.byKey(const Key('basmala-2'))).dy;
    final ayah1 = tester.getTopLeft(find.byKey(const Key('pageAyah-2-1'))).dy;
    expect(banner < basmala && basmala < ayah1, isTrue);
  });
}
