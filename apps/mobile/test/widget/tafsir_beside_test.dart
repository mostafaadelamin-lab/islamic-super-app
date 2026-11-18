import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

/// Owner 2026-11-18: a big Mushaf page beside the tafsir, the tafsir beside the page without listening,
/// and full screen together with the tafsir (listening or only reading).
void main() {
  setUpAll(loadContent);

  testWidgets('«التفسير» shows the page and its tafsir without listening; full screen keeps both', (tester) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, audio: audio, size: const Size(1280, 800));
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    expect(find.byKey(const Key('splitView')), findsNothing);
    await tester.tap(find.byKey(const Key('readerTafsirBeside')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splitView')), findsOneWidget);
    expect(find.byKey(const Key('duoTitle')), findsOneWidget);
    expect(find.text('التفسير بجانب الصفحة'), findsWidgets);
    expect(app.services.recitation.isActive, isFalse, reason: 'nothing plays');

    await tester.tap(find.byKey(const Key('readerFull')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('readerFullScreen')), findsOneWidget);
    expect(find.byKey(const Key('splitView')), findsOneWidget, reason: 'full screen keeps the tafsir');
    expect(find.byKey(const Key('readerFullTools')), findsOneWidget);
    // A tap on an ayah shows its tafsir and stays full screen.
    await tester.tap(find.byKey(const Key('pageAyah-2-10')).first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('readerFullScreen')), findsOneWidget);
    expect(find.byKey(const Key('ayahSheet')), findsNothing);
    // The page fills the height beside the tafsir.
    final page = tester.getSize(find.byKey(const Key('duoPage')));
    expect(page.height, greaterThan(700));
    // Hide the tafsir from the full-screen strip: the page alone, still full screen.
    await tester.tap(find.byKey(const Key('fullTafsirBeside')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splitView')), findsNothing);
    expect(find.byKey(const Key('readerFullScreen')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('big screen: «تفسير الآية» opens beside the page, which keeps its size', (tester) async {
    await pumpApp(tester, size: const Size(1280, 800));
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    await tester.tap(find.byKey(const Key('pageAyah-2-10')));
    await tester.pumpAndSettle();
    final strip = tester.getSize(find.byKey(const Key('readerStrip')));
    await tester.tap(find.byKey(const Key('ayahTafsir')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splitView')), findsOneWidget);
    expect(find.byKey(const Key('tafsirScroll')), findsNothing, reason: 'no tafsir card in the bottom strip');
    expect(tester.getSize(find.byKey(const Key('readerStrip'))), strip);
    expect(tester.takeException(), isNull);
  });

  testWidgets('phone: «التفسير» from the menu stacks page and tafsir', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    await tester.tap(find.byKey(const Key('readerTafsirBeside')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splitView')), findsOneWidget);
    await tester.tap(find.byKey(const Key('duoHideTafsir')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('splitView')), findsNothing);
  });
}
