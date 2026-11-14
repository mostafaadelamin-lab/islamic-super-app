import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/nasheeds.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/dhikr_audio.dart';
import 'package:rattil/ui/nasheeds_screen.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';
import 'dhikr_extras_test.dart' show FakeUrlAudio;

/// Owner's report 2026-11-14: page turning in full screen, controls and the ayah sheet covering the
/// page, adhkar and Quran playing together, the nasheed player away from the nasheed.
void main() {
  setUpAll(loadContent);

  PageReaderScreenState reader(WidgetTester tester) =>
      tester.state<PageReaderScreenState>(find.byType(PageReaderScreen));

  group('full screen', () {
    setUp(() => PageReaderScreen.startFullScreen = true);
    tearDown(() => PageReaderScreen.startFullScreen = false);

    testWidgets('arrows turn the pages (Arabic: next on the left) and a hint says how', (tester) async {
      await pumpApp(tester, size: const Size(390, 844));
      await pushScreen(tester, const PageReaderScreen(initialPage: 3));
      expect(find.byKey(const Key('readerHint')), findsOneWidget);
      final next = tester.getCenter(find.byKey(const Key('turnNext')));
      final prev = tester.getCenter(find.byKey(const Key('turnPrev')));
      expect(next.dx, lessThan(prev.dx), reason: 'the next page is on the left in Arabic');
      await tester.tap(find.byKey(const Key('turnNext')));
      await tester.pumpAndSettle();
      expect(reader(tester).page, 4);
      expect(reader(tester).fullScreen, isTrue, reason: 'turning does not bring the controls');
      await tester.tap(find.byKey(const Key('turnPrev')));
      await tester.pumpAndSettle();
      expect(reader(tester).page, 3);
      await tester.pump(const Duration(seconds: 8));
      expect(find.byKey(const Key('readerHint')), findsNothing, reason: 'the hint goes away by itself');
    });

    testWidgets('the hint is shown only the first three times', (tester) async {
      await pumpApp(tester, size: const Size(390, 844), prefs: {'reader.hintShown': 3});
      await pushScreen(tester, const PageReaderScreen(initialPage: 3));
      expect(find.byKey(const Key('readerHint')), findsNothing);
      expect(find.byKey(const Key('turnNext')), findsOneWidget);
    });
  });

  testWidgets('phone: the ayah sheet over the Mushaf is short and does not dim the page', (tester) async {
    await pumpApp(tester, size: const Size(390, 844));
    await pushScreen(tester, const PageReaderScreen(initialPage: 42));
    await tester.tap(find.byKey(const Key('pageAyah-2-255')));
    await tester.pumpAndSettle();
    final sheet = tester.getRect(find.byKey(const Key('ayahSheet')));
    expect(sheet.height, lessThanOrEqualTo(844 * 0.5));
    expect(find.byKey(const Key('ayahCopy')), findsOneWidget);
  });

  testWidgets('tablet sideways: player and tools beside the page; the ayah opens in a side panel', (tester) async {
    const size = Size(1280, 800);
    await pumpApp(tester, size: size);
    await pushScreen(tester, const PageReaderScreen(initialPage: 42));
    expect(find.byKey(const Key('readerSidePanel')), findsOneWidget);
    final page = tester.getRect(find.byKey(const Key('mushafPage-42')));
    final controls = tester.getRect(find.byKey(const Key('mushafControls')));
    expect(page.overlaps(controls), isFalse);
    await tester.tap(find.byKey(const Key('pageAyah-2-255')));
    await tester.pumpAndSettle();
    final panel = tester.getRect(find.byKey(const Key('ayahSidePanel')));
    expect(panel.width, lessThanOrEqualTo(400));
    expect(panel.left, lessThan(size.width / 2), reason: 'Arabic: the panel is on the left, the page on the right');
  });

  testWidgets('adhkar pause the recitation; the Mushaf reopens at the ayah it stopped at', (tester) async {
    final fake = FakeUrlAudio();
    debugUrlAudioFactory = () => fake;
    addTearDown(() => debugUrlAudioFactory = null);
    final app = await pumpApp(tester, size: const Size(390, 844));
    final rec = app.services.recitation;
    await rec.playFrom(const AyahRef(2, 255));
    expect(rec.isPlaying, isTrue);

    await DhikrPlayer.instance.toggle('https://example.org/dhikr.mp3');
    await tester.pump();
    expect(rec.isPlaying, isFalse);
    expect(rec.wasInterrupted, isTrue);
    expect(rec.currentRef, const AyahRef(2, 255));
    expect(app.services.settings.lastRead, const AyahRef(2, 255));

    // Opening the Mushaf elsewhere: it goes to the page of the ayah that was playing.
    await pushScreen(tester, const PageReaderScreen(initialPage: 1));
    await tester.pumpAndSettle();
    expect(reader(tester).page, 42);

    // Back to the recitation: it resumes from that ayah and the dhikr pauses.
    await rec.resume();
    await tester.pump();
    expect(rec.isPlaying, isTrue);
    expect(rec.currentRef, const AyahRef(2, 255));
    expect(fake.calls.last, 'pause', reason: fake.calls.join(','));
    await DhikrPlayer.instance.stop();
  });

  testWidgets('nasheeds: the player is under the nasheed playing, not in the bottom bar', (tester) async {
    final narration = FakeNarrationBackend();
    await pumpApp(tester, size: tallPhone, narration: narration);
    final list = Munshid.parse(File('assets/content/nasheeds.v2.json').readAsStringSync());
    final m = list.firstWhere((x) => x.id == 2);
    await pushScreen(tester, MunshidScreen(munshid: m));
    final first = m.items.first;
    await tester.tap(find.byKey(Key('nasheed-${first.id}')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nasheedInlinePlayer')), findsOneWidget);
    expect(find.byKey(const Key('narrationBar')), findsNothing);
    final tile = tester.getRect(find.byKey(Key('nasheed-${first.id}')));
    final player = tester.getRect(find.byKey(const Key('nasheedInlinePlayer')));
    expect(player.top, greaterThanOrEqualTo(tile.bottom - 0.5));
    expect(player.top - tile.bottom, lessThan(16));
    await tester.tap(find.byKey(const Key('nasheedNext')));
    await tester.pumpAndSettle();
    final second = m.items[1];
    expect(
      tester.getRect(find.byKey(const Key('nasheedInlinePlayer'))).top,
      greaterThanOrEqualTo(tester.getRect(find.byKey(Key('nasheed-${second.id}'))).bottom - 0.5),
    );
  });
}
