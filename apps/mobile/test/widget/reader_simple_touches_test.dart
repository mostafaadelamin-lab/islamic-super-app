import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

/// Owner 2026-11-15: simpler touches in the Mushaf, a short guide the first time it opens, and the page
/// never shrinking when an ayah's options show on big screens.
void main() {
  setUpAll(loadContent);

  testWidgets('the first open shows a short guide once', (tester) async {
    final app = await pumpApp(tester, size: const Size(390, 844), prefs: {'reader.guideDone': false});
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    expect(find.byKey(const Key('readerGuide')), findsOneWidget);
    expect(find.text('طريقة استخدام المصحف'), findsOneWidget);
    await tester.tap(find.byKey(const Key('readerGuideOk')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('readerGuide')), findsNothing);
    expect(app.services.settings.readerGuideDone, isTrue);
  });

  testWidgets('big screen: the ayah row has its own room, so the page keeps its size', (tester) async {
    await pumpApp(tester, size: const Size(1280, 800));
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
    expect(find.byKey(const Key('stripPickAyah')), findsOneWidget);
    final before = tester.getSize(find.byKey(const Key('mushafPage-3')));
    await tester.tap(find.byKey(const Key('pageAyah-2-10')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ayahSheet')), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('mushafPage-3'))), before);
  });
}
