import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/audio_queue.dart';
import 'package:rattil/domain/nasheeds.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/nasheeds_screen.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/play_origin.dart';

import '../helpers.dart';

/// Owner 2026-11-15: after leaving the screen of what is playing (e.g. the recitation
/// library) there was no direct way back to it from the player at the bottom.
void main() {
  setUpAll(loadContent);
  setUp(PlayOrigin.reset);

  testWidgets('the narration player takes you back to the screen it was started on', (tester) async {
    final narration = FakeNarrationBackend();
    await pumpApp(tester, size: const Size(390, 900), narration: narration);
    final list = Munshid.parse(File('assets/content/nasheeds.v2.json').readAsStringSync());
    final m = list.firstWhere((x) => x.id == 2);
    await pushScreen(tester, MunshidScreen(munshid: m));
    await tester.tap(find.byKey(Key('nasheed-${m.items.first.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('narrationOpen')), findsNothing, reason: 'already on its screen');
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(find.byType(MunshidScreen), findsNothing);
    expect(find.byKey(const Key('narrationBar')), findsOneWidget);
    await tester.tap(find.byKey(const Key('narrationOpen')));
    await tester.pumpAndSettle();
    expect(find.byType(MunshidScreen), findsOneWidget);
    expect(find.byKey(const Key('nasheedInlinePlayer')), findsOneWidget);
  });

  testWidgets('the recitation mini player opens the Mushaf on the page being recited', (tester) async {
    final app = await pumpApp(tester, size: const Size(390, 900));
    await app.services.recitation.playFrom(const AyahRef(2, 255), scope: PlayScope.ayah);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('miniPlayerOpen')));
    await tester.pumpAndSettle();
    expect(tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page, 42);
  });
}
