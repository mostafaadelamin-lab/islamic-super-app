import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/theme/app_theme.dart';
import 'package:rattil/ui/mushaf_page.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  setUp(() => PageReaderScreen.startFullScreen = true);
  tearDown(() => PageReaderScreen.startFullScreen = false);

  PageReaderScreenState reader(WidgetTester tester) =>
      tester.state<PageReaderScreenState>(find.byType(PageReaderScreen));

  Future<void> open(WidgetTester tester, int page, {Size size = const Size(390, 844)}) async {
    await pumpApp(tester, size: size);
    await pushScreen(tester, PageReaderScreen(initialPage: page));
  }

  testWidgets('full screen: only the page; tapping an ayah shows its options; «show tools» brings the tools back', (
    tester,
  ) async {
    await open(tester, 3);
    expect(reader(tester).fullScreen, isTrue);
    expect(find.byKey(const Key('readerFullScreen')), findsOneWidget);
    expect(find.byKey(const Key('readerBack')), findsNothing);
    expect(find.byKey(const Key('mushafControls')), findsNothing);
    expect(find.byKey(const Key('readerExitFull')), findsOneWidget);
    // A tap on the words selects that ayah and shows its options.
    await tester.tap(find.byKey(const Key('pageAyah-2-10')));
    await tester.pumpAndSettle();
    expect(reader(tester).selected, const AyahRef(2, 10));
    expect(find.byKey(const Key('ayahSheet')), findsOneWidget);
    // A tap beside the text closes them and stays in full screen (no tap-to-toggle).
    await tester.tapAt(tester.getTopLeft(find.byKey(const Key('mushafPage-3'))) + const Offset(3, 3));
    await tester.pumpAndSettle();
    expect(reader(tester).selected, isNull);
    expect(reader(tester).fullScreen, isTrue);
    await tester.tap(find.byKey(const Key('readerExitFull')));
    await tester.pumpAndSettle();
    expect(reader(tester).fullScreen, isFalse);
    expect(find.byKey(const Key('readerBack')), findsOneWidget);
    expect(find.byKey(const Key('mushafControls')), findsOneWidget);
  });

  testWidgets('full screen: an ayah number still opens that ayah', (tester) async {
    await open(tester, 3);
    final marker = find.byWidgetPredicate((w) => w is AyahMarker && w.number == 10);
    await tester.tap(marker.first);
    await tester.pumpAndSettle();
    expect(reader(tester).selected, const AyahRef(2, 10));
    expect(find.byKey(const Key('ayahSheet')), findsOneWidget);
  });

  testWidgets('a phone held sideways: the page fills the width and scrolls down', (tester) async {
    await open(tester, 4, size: const Size(844, 390));
    expect(reader(tester).fullScreen, isTrue);
    final page = tester.getSize(find.byKey(const Key('mushafPage-4')));
    final line = tester.getSize(find.byKey(const Key('mushafLine-4-0')));
    expect(line.height * 15, greaterThan(page.height)); // taller than the screen: it scrolls
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets('the reader follows the chosen colour style (owner 2026-11-15)', (tester) async {
    await open(tester, 3);
    final ctx = tester.element(find.byKey(const Key('mushafPage-3')));
    expect(AppTheme.of(ctx, 'paper'), AppTheme.token(Brightness.light, 'paper'));
    expect(AppTheme.of(ctx, 'frame'), AppTheme.token(Brightness.light, 'frame'));
    expect(Theme.of(ctx).colorScheme.primary, AppTheme.token(Brightness.light, 'primary'));
  });

  test('landscape fit only for phones held sideways', () {
    expect(isLandscapePhone(const Size(844, 390)), isTrue);
    expect(isLandscapePhone(const Size(390, 844)), isFalse);
    expect(isLandscapePhone(const Size(1180, 820)), isFalse);
  });

  testWidgets('«show tools» sits in a strip above the page, not over its first line', (tester) async {
    await open(tester, 3);
    final button = tester.getRect(find.byKey(const Key('readerExitFull')));
    final pageTop = tester.getTopLeft(find.byKey(const Key('mushafPageView'))).dy;
    expect(button.bottom, lessThanOrEqualTo(pageTop + 0.5));
  });

  testWidgets('two fingers zoom the page; the size is kept, and «normal size» resets it', (tester) async {
    await open(tester, 3);
    final settings = tester.element(find.byType(PageReaderScreen)).services.settings;
    expect(settings.mushafZoom, 1.0);
    final c = tester.getCenter(find.byKey(const Key('mushafPageView')));
    final a = await tester.startGesture(c - const Offset(40, 0), pointer: 1);
    final b = await tester.startGesture(c + const Offset(40, 0), pointer: 2);
    await tester.pump();
    for (var i = 1; i <= 8; i++) {
      await a.moveTo(c - Offset(40.0 + i * 10, 0));
      await b.moveTo(c + Offset(40.0 + i * 10, 0));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pumpAndSettle();
    expect(reader(tester).page, 3, reason: 'a pinch does not turn the page');
    expect(settings.mushafZoom, closeTo(3.0, 0.06));
    expect(find.byKey(const Key('mushafZoomV')), findsOneWidget);
    await tester.tap(find.byKey(const Key('mushafZoomReset')));
    await tester.pumpAndSettle();
    expect(settings.mushafZoom, 1.0);
    expect(find.byKey(const Key('mushafZoomReset')), findsNothing);
  });
}
