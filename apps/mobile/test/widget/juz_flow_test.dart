import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/reader_widgets.dart';

import '../helpers.dart';

/// Owner 2026-11-20: the whole surah splits into tafsir + surah like the page does, and the Mushaf by ajzaa
/// («الجزء كاملاً» in the reader, «الأجزاء» in the index).
void main() {
  setUpAll(loadContent);

  test('juzRefs covers every ayah once, in order', () async {
    final q = (await loadContent()).quran;
    final all = [for (var j = 1; j <= 30; j++) ...q.juzRefs(j)];
    expect(all.length, 6236);
    expect(q.juzRefs(1).first, const AyahRef(1, 1));
    expect(q.juzRefs(1).last, const AyahRef(2, 141));
    expect(q.juzRefs(2).first, const AyahRef(2, 142));
    expect(q.juzRefs(30).first, const AyahRef(78, 1));
    expect(q.juzRefs(30).last, const AyahRef(114, 6));
    for (var i = 1; i < all.length; i++) {
      expect(all[i - 1].compareTo(all[i]), lessThan(0));
    }
  });

  testWidgets('whole surah beside its tafsir on a tablet; a tap shows that ayah\'s tafsir', (tester) async {
    await pumpApp(tester, audio: FakeAudioBackend(), size: const Size(1280, 800));
    await pushScreen(tester, const PageReaderScreen(initialPage: 50));
    await tester.tap(find.byKey(const Key('readerTab-surah')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('surahFlow-3')), findsOneWidget);
    expect(find.byKey(const Key('flowSplitView')), findsNothing);
    await tester.tap(find.byKey(const Key('readerTafsirBeside')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('flowSplitView')), findsOneWidget);
    expect(find.byKey(const Key('flowTafsir')), findsOneWidget);
    expect(find.text('التفسير بجانب السورة'), findsOneWidget);
    // Side by side: the tafsir and the surah share the width.
    final tafsir = tester.getRect(find.byKey(const Key('flowTafsir')));
    final flow = tester.getRect(find.byKey(const Key('surahFlow-3')));
    expect(tafsir.width, greaterThan(400));
    expect(flow.width, greaterThan(500));
    expect(tafsir.overlaps(flow), isFalse);
    await tester.tap(find.byKey(const Key('surahFlowAyah-3-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ayahSheet')), findsNothing, reason: 'the tafsir half shows it');
    expect(find.byKey(const Key('listTafsir-3-2')), findsOneWidget);
    await tester.tap(find.byKey(const Key('duoHideTafsir')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('flowSplitView')), findsNothing);
  });

  testWidgets('whole juz: opens at the page\'s juz, picker and next / previous juz', (tester) async {
    await pumpApp(tester, audio: FakeAudioBackend(), size: const Size(440, 956));
    await pushScreen(tester, const PageReaderScreen(initialPage: 582, initialTab: ReaderTab.juz));
    expect(find.byKey(const Key('juzFlow-30')), findsOneWidget);
    expect(find.text('الجزء الثلاثون'), findsWidgets);
    await tester.tap(find.byKey(const Key('juzPick')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('juzPick-29')).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('juzFlow-29')), findsOneWidget);
    // Phones: the halves one above the other.
    await tester.tap(find.byKey(const Key('readerTafsirBeside')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('flowSplitView')), findsOneWidget);
    expect(find.text('التفسير بجانب الجزء'), findsOneWidget);
    final tafsir = tester.getRect(find.byKey(const Key('flowTafsir')));
    final flow = tester.getRect(find.byKey(const Key('juzFlow-29')));
    expect(flow.bottom, lessThanOrEqualTo(tafsir.top + 1));
  });

  testWidgets('index «الأجزاء» lists 30 juz and opens the whole juz', (tester) async {
    await pumpApp(tester);
    await goToTab(tester, 1);
    await tester.tap(find.byKey(const Key('tabJuz')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('juz-1')), findsOneWidget);
    expect(find.text('يبدأ من سورة البقرة: ١٤٢ - الصفحة ٢٢'), findsOneWidget);
    await tester.tap(find.byKey(const Key('juz-2')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('juzFlow-2')), findsOneWidget);
  });
}
