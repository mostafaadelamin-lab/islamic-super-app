import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/printed_mushaf.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

/// Owner 2026-11-27: the Madina font is the default; «تغيير الخط» opens three choices (switch the font, download
/// this surah, download the whole Mushaf once), and a download shows its progress at the top of the reader.
void main() {
  setUpAll(loadContent);
  tearDown(() => PrintedMushaf.instance.debugSetProgress());

  testWidgets('«تغيير الخط» opens the three choices and switches the font', (tester) async {
    PrintedMushaf.instance.debugSetProgress(saved: 0);
    final app = await pumpApp(
      tester,
      size: const Size(390, 844),
      prefs: {'reader.hintShown': 9, 'reader.guideDone': true, 'mushaf.printed.v3': true},
    );
    await pushScreen(tester, const PageReaderScreen(initialPage: 50));
    await tester.tap(find.byKey(const Key('readerPrinted')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mushafFontMenu')), findsOneWidget);
    expect(find.text('التبديل إلى الخط العثماني'), findsOneWidget);
    expect(find.text('تحميل سورة آل عمران كاملة'), findsOneWidget);
    expect(find.text('تحميل المصحف كامل مرة واحدة'), findsOneWidget);
    expect(find.textContaining('ميجا'), findsNothing); // no file size (owner)
    await tester.tap(find.byKey(const Key('fontOptSwitch')));
    await tester.pumpAndSettle();
    expect(app.services.settings.mushafPrinted, isFalse);
  });

  testWidgets('a running download shows its progress at the top', (tester) async {
    final pm = PrintedMushaf.instance;
    await pumpApp(
      tester,
      size: const Size(390, 844),
      prefs: {'reader.hintShown': 9, 'reader.guideDone': true, 'mushaf.printed.v3': true},
    );
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    expect(find.byKey(const Key('printedDownloadBar')), findsNothing);
    pm.debugSetProgress(saved: 0, done: 250);
    await tester.pump();
    expect(find.byKey(const Key('printedDownloadBar')), findsOneWidget);
    expect(find.textContaining('٢٥٠'), findsOneWidget);
    pm.debugSetProgress(saved: PrintedMushaf.pages);
    await tester.pump();
    expect(find.text('محفوظ على الجهاز'), findsOneWidget);
  });

}
