import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

// Owner 2026-11-17: a handle on top of the Mushaf player slides it down to a thin row and back.
void main() {
  setUpAll(loadContent);

  Future<void> open(WidgetTester tester, {Size size = const Size(390, 844), Map<String, Object>? prefs}) async {
    await pumpApp(tester, size: size, prefs: prefs ?? const {}, audio: FakeAudioBackend());
    await pushScreen(tester, const PageReaderScreen(initialPage: 3));
  }

  double pageHeight(WidgetTester tester) => tester.getSize(find.byKey(const Key('readerBody'))).height;

  testWidgets('tapping the handle hides the player and slider, the page grows, and it comes back', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('miniPlayer')), findsOneWidget);
    expect(find.byKey(const Key('miniPlayerStrip')), findsNothing);
    final before = pageHeight(tester);

    await tester.tap(find.byKey(const Key('playerHandle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('miniPlayer')), findsNothing);
    expect(find.byKey(const Key('miniPlayerStrip')), findsOneWidget);
    expect(pageHeight(tester), greaterThan(before + 60));
    final ctx = tester.element(find.byType(PageReaderScreen));
    expect(ctx.services.settings.readerPlayerMin, isTrue);

    await tester.tap(find.byKey(const Key('playerHandle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('miniPlayer')), findsOneWidget);
    expect(pageHeight(tester), closeTo(before, 0.5));
  });

  testWidgets('dragging the handle down hides the player, dragging up brings it back', (tester) async {
    await open(tester);
    await tester.fling(find.byKey(const Key('playerHandle')), const Offset(0, 80), 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('miniPlayerStrip')), findsOneWidget);
    await tester.fling(find.byKey(const Key('playerHandle')), const Offset(0, -80), 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('miniPlayer')), findsOneWidget);
  });

  testWidgets('the slid-down row plays the page and pauses', (tester) async {
    await open(tester, prefs: const {'reader.playerMin': true});
    expect(find.byKey(const Key('miniPlayerStrip')), findsOneWidget);
    final rec = tester.element(find.byType(PageReaderScreen)).services.recitation;
    await tester.tap(find.byKey(const Key('miniStripPlay')));
    await tester.pumpAndSettle();
    expect(rec.isActive, isTrue);
  });

  testWidgets('the slid-down row has a ✕ that closes the player (owner 2026-11-20)', (tester) async {
    await open(tester, prefs: const {'reader.playerMin': true});
    final rec = tester.element(find.byType(PageReaderScreen)).services.recitation;
    expect(find.byKey(const Key('miniStripClose')), findsNothing);
    await tester.tap(find.byKey(const Key('miniStripPlay')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('miniStripClose')));
    await tester.pumpAndSettle();
    expect(rec.isActive, isFalse);
    expect(find.byKey(const Key('miniStripClose')), findsNothing);
  });

  testWidgets('held sideways: the handle works there too', (tester) async {
    await open(tester, size: const Size(956, 440));
    await tester.tap(find.byKey(const Key('playerHandle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('miniPlayer')), findsNothing);
    expect(find.byKey(const Key('miniPlayerStrip')), findsOneWidget);
  });
}
