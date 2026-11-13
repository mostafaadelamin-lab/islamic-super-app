import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

  testWidgets('opens full screen: only the page; a tap on the words shows the controls, a second tap hides them', (
    tester,
  ) async {
    await open(tester, 3);
    expect(reader(tester).fullScreen, isTrue);
    expect(find.byKey(const Key('readerFullScreen')), findsOneWidget);
    expect(find.byKey(const Key('readerBack')), findsNothing);
    expect(find.byKey(const Key('mushafControls')), findsNothing);
    // A tap on the words does not select an ayah in full screen: it brings the controls back.
    await tester.tap(find.byKey(const Key('pageAyah-2-10')));
    await tester.pumpAndSettle();
    expect(reader(tester).selected, isNull);
    expect(reader(tester).fullScreen, isFalse);
    expect(find.byKey(const Key('readerBack')), findsOneWidget);
    expect(find.byKey(const Key('mushafControls')), findsOneWidget);
    await tester.tapAt(tester.getTopLeft(find.byKey(const Key('mushafPage-3'))) + const Offset(3, 3));
    await tester.pumpAndSettle();
    expect(reader(tester).fullScreen, isTrue);
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

  testWidgets('the reader uses the Mushaf colours (cream paper, brown frame)', (tester) async {
    await open(tester, 3);
    final ctx = tester.element(find.byKey(const Key('mushafPage-3')));
    expect(AppTheme.of(ctx, 'paper'), AppTheme.mushafLight['paper']);
    expect(AppTheme.of(ctx, 'frame'), AppTheme.mushafLight['frame']);
    expect(Theme.of(ctx).colorScheme.primary, AppTheme.mushafLight['primary']);
  });

  test('landscape fit only for phones held sideways', () {
    expect(isLandscapePhone(const Size(844, 390)), isTrue);
    expect(isLandscapePhone(const Size(390, 844)), isFalse);
    expect(isLandscapePhone(const Size(1180, 820)), isFalse);
  });
}
