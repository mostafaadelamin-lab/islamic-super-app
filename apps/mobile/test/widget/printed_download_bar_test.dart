import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/printed_mushaf.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

/// Owner 2026-11-26: with the Madina font on, the reader offers the whole Mushaf's font once for offline reading.
void main() {
  setUpAll(loadContent);
  tearDown(() => PrintedMushaf.instance.debugSetProgress());

  testWidgets('the offer shows with the Madina font only, until every page is saved', (tester) async {
    final pm = PrintedMushaf.instance;
    pm.debugSetProgress(saved: 12);
    final app = await pumpApp(
      tester,
      size: const Size(390, 844),
      prefs: {'reader.hintShown': 9, 'reader.guideDone': true, 'mushaf.printed.v2': false},
    );
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    expect(find.byKey(const Key('printedDownloadBar')), findsNothing);

    await app.services.settings.setMushafPrinted(true);
    await tester.pump();
    expect(find.byKey(const Key('printedDownloadBar')), findsOneWidget);
    expect(find.textContaining('مرة واحدة'), findsOneWidget);
    expect(find.byKey(const Key('printedDownloadAll')), findsOneWidget);

    pm.debugSetProgress(saved: 12, done: 250);
    await tester.pump();
    expect(find.textContaining('٢٥٠'), findsOneWidget);

    pm.debugSetProgress(saved: PrintedMushaf.pages);
    await tester.pump();
    expect(find.byKey(const Key('printedDownloadBar')), findsNothing);
  });

  testWidgets('«لاحقًا» hides the offer for this visit', (tester) async {
    PrintedMushaf.instance.debugSetProgress(saved: 0);
    await pumpApp(
      tester,
      size: const Size(390, 844),
      prefs: {'reader.hintShown': 9, 'reader.guideDone': true, 'mushaf.printed.v2': true},
    );
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    await tester.tap(find.byKey(const Key('printedDownloadLater')));
    await tester.pump();
    expect(find.byKey(const Key('printedDownloadBar')), findsNothing);
  });
}
