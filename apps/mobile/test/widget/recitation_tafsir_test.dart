import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/audio_queue.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/home_screen.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  late Map<String, dynamic> stored;
  setUpAll(() async {
    await loadContent();
    stored = readRepoJson('content/tafsir/dist/muyassar.v1.json');
  });

  String source(int s, int a) => ((stored['surahs'] as List<dynamic>)[s - 1] as List<dynamic>)[a - 1] as String;
  String? panelText(WidgetTester tester) {
    final f = find.byKey(const Key('recitationTafsirText'));
    return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
  }

  int page(WidgetTester tester) => tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).page;

  Future<(TestApp, FakeAudioBackend)> openAndPlay(
    WidgetTester tester,
    int startPage,
    AyahRef from, {
    Map<String, Object> prefs = const {},
    Size size = const Size(390, 844),
    String locale = 'ar',
    PlayScope scope = PlayScope.toEnd,
  }) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, audio: audio, prefs: prefs, size: size, locale: locale);
    await pushScreen(tester, PageReaderScreen(initialPage: startPage));
    await app.services.recitation.playFrom(from, scope: scope);
    await tester.pumpAndSettle();
    return (app, audio);
  }

  testWidgets('off by default: the mini player shows no tafsir', (tester) async {
    final (app, _) = await openAndPlay(tester, 2, const AyahRef(2, 5));
    expect(app.services.settings.tafsirWithRecitation, isFalse);
    expect(find.byKey(const Key('miniPlayer')), findsOneWidget);
    expect(find.byKey(const Key('audioTafsirToggle')), findsOneWidget);
    expect(find.byKey(const Key('recitationTafsir')), findsNothing);
    expect(find.byKey(const Key('splitView')), findsNothing);
    expect(find.byKey(const Key('mushafPageView')), findsOneWidget);
  });

  String? duoText(WidgetTester tester, int s, int a) {
    final f = find.descendant(of: find.byKey(Key('listTafsir-$s-$a')), matching: find.byType(Text));
    return f.evaluate().isEmpty ? null : tester.widget<Text>(f).data;
  }

  testWidgets(
    'on: the whole page and its tafsir in two halves, following the recitation across a page turn; off hides it',
    (tester) async {
      final (app, audio) = await openAndPlay(tester, 2, const AyahRef(2, 4));
      await tester.tap(find.byKey(const Key('audioTafsirToggle')));
      await tester.pumpAndSettle();
      expect(app.prefs.getBool('audio.tafsir'), isTrue);
      // owner 2026-11-15: the Mushaf page on top, the page's tafsir under it
      expect(find.byKey(const Key('splitView')), findsOneWidget);
      expect(find.byKey(const Key('mushafPage-2')), findsOneWidget);
      final top = tester.getRect(find.byKey(const Key('duoPage')));
      final bottom = tester.getRect(find.byKey(const Key('duoTafsir')));
      expect(top.bottom, lessThan(bottom.top));
      expect((top.height - bottom.height).abs(), lessThan(1), reason: 'two equal halves');
      expect(duoText(tester, 2, 4), source(2, 4));

      audio.finish();
      await tester.pumpAndSettle();
      expect(app.services.recitation.currentRef, const AyahRef(2, 5));
      expect(duoText(tester, 2, 5), source(2, 5));
      expect(page(tester), 2);

      audio.finish(); // 2:6 is on page 3
      await tester.pumpAndSettle();
      expect(app.services.recitation.currentRef, const AyahRef(2, 6));
      expect(page(tester), 3, reason: 'the page follows the recitation');
      expect(find.byKey(const Key('mushafPage-3')), findsOneWidget);
      expect(duoText(tester, 2, 6), source(2, 6));

      await tester.tap(find.byKey(const Key('duoHideTafsir')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('splitView')), findsNothing);
      expect(app.prefs.getBool('audio.tafsir'), isFalse);
      expect(find.byKey(const Key('mushafPage-3')), findsOneWidget, reason: 'the page view opens on page 3');
      expect(find.byKey(const Key('miniPlayer')), findsOneWidget);

      await tester.tap(find.byKey(const Key('audioStop')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('splitView')), findsNothing);
    },
  );

  testWidgets('the choice is remembered: a saved "on" shows the halves as soon as recitation starts', (tester) async {
    final (app, _) = await openAndPlay(tester, 1, const AyahRef(1, 2), prefs: {'audio.tafsir': true});
    expect(app.services.settings.tafsirWithRecitation, isTrue);
    expect(find.byKey(const Key('splitView')), findsOneWidget);
    expect(duoText(tester, 1, 2), source(1, 2));
  });

  testWidgets('while the basmala plays before a surah the halves are shown; then ayah 1 is recited', (tester) async {
    final (app, audio) = await openAndPlay(
      tester,
      2,
      const AyahRef(2, 1),
      prefs: {'audio.tafsir': true},
      scope: PlayScope.surah,
    );
    expect(app.services.recitation.current!.isBasmala, isTrue);
    expect(find.byKey(const Key('splitView')), findsOneWidget);
    audio.finish();
    await tester.pumpAndSettle();
    expect(app.services.recitation.currentRef, const AyahRef(2, 1));
    expect(duoText(tester, 2, 1), source(2, 1));
  });

  testWidgets('also shown above the mini player on the home screen', (tester) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, audio: audio, prefs: {'audio.tafsir': true});
    await app.services.recitation.playFrom(const AyahRef(112, 1));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(panelText(tester), source(112, 1));
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('320 px wide ($locale): page and tafsir halves fit, the tafsir scrolls, nothing overflows', (
      tester,
    ) async {
      const size = Size(320, 568);
      await openAndPlay(tester, 48, const AyahRef(2, 282), prefs: {'audio.tafsir': true}, size: size, locale: locale);
      expect(tester.takeException(), isNull);
      expect(duoText(tester, 2, 282), source(2, 282));
      final panel = tester.getRect(find.byKey(const Key('duoTafsir')));
      expect(panel.height, greaterThan(size.height * 0.1), reason: 'a real half, not a strip');
      // Owner 2026-11-18: with the halves on a phone the player folds to one row (play / pause + the ayah).
      for (final k in ['duoTafsir', 'duoPage', 'miniPlayerStrip', 'miniStripPlay', 'playerHandle']) {
        final r = tester.getRect(find.byKey(Key(k)));
        expect(r.left, greaterThanOrEqualTo(-0.01), reason: k);
        expect(r.right, lessThanOrEqualTo(size.width + 0.01), reason: k);
        expect(r.bottom, lessThanOrEqualTo(size.height + 0.01), reason: k);
      }
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: find.byKey(const Key('tafsirList')), matching: find.byType(Scrollable)).first,
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }
}
