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
  });

  testWidgets('on: shows the playing ayah\'s tafsir, follows it ayah by ayah and across a page turn; off hides it', (
    tester,
  ) async {
    final (app, audio) = await openAndPlay(tester, 2, const AyahRef(2, 4));
    await tester.tap(find.byKey(const Key('audioTafsirToggle')));
    await tester.pumpAndSettle();
    expect(app.prefs.getBool('audio.tafsir'), isTrue);
    expect(find.byKey(const Key('recitationTafsir')), findsOneWidget);
    expect(find.text('التفسير مع التلاوة · البقرة : ٤'), findsOneWidget);
    expect(panelText(tester), source(2, 4));

    audio.finish();
    await tester.pumpAndSettle();
    expect(app.services.recitation.currentRef, const AyahRef(2, 5));
    expect(panelText(tester), source(2, 5));
    expect(page(tester), 2);

    audio.finish(); // 2:6 is on page 3
    await tester.pumpAndSettle();
    expect(app.services.recitation.currentRef, const AyahRef(2, 6));
    expect(page(tester), 3, reason: 'the Mushaf turned the page');
    expect(panelText(tester), source(2, 6));
    expect(find.text('التفسير مع التلاوة · البقرة : ٦'), findsOneWidget);

    await tester.tap(find.byKey(const Key('audioTafsirToggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recitationTafsir')), findsNothing);
    expect(app.prefs.getBool('audio.tafsir'), isFalse);
    expect(find.byKey(const Key('miniPlayer')), findsOneWidget);

    await tester.tap(find.byKey(const Key('audioStop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('recitationTafsir')), findsNothing);
  });

  testWidgets('the choice is remembered: a saved "on" shows the panel as soon as recitation starts', (tester) async {
    final (app, _) = await openAndPlay(tester, 1, const AyahRef(1, 2), prefs: {'audio.tafsir': true});
    expect(app.services.settings.tafsirWithRecitation, isTrue);
    expect(panelText(tester), source(1, 2));
  });

  testWidgets(
    'while the basmala plays before a surah, the panel shows that surah\'s first ayah (the one highlighted)',
    (tester) async {
      final (app, _) = await openAndPlay(
        tester,
        2,
        const AyahRef(2, 1),
        prefs: {'audio.tafsir': true},
        scope: PlayScope.surah,
      );
      expect(app.services.recitation.current!.isBasmala, isTrue);
      expect(panelText(tester), source(2, 1));
    },
  );

  testWidgets('also shown above the mini player on the home screen', (tester) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, audio: audio, prefs: {'audio.tafsir': true});
    await app.services.recitation.playFrom(const AyahRef(112, 1));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(panelText(tester), source(112, 1));
  });

  for (final locale in ['ar', 'en']) {
    testWidgets('320 px wide ($locale): the longest entry scrolls in the panel, nothing overflows', (tester) async {
      const size = Size(320, 568);
      await openAndPlay(tester, 48, const AyahRef(2, 282), prefs: {'audio.tafsir': true}, size: size, locale: locale);
      expect(tester.takeException(), isNull);
      expect(panelText(tester), source(2, 282));
      if (locale == 'en') expect(find.text('This tafsir is available in Arabic only.'), findsOneWidget);
      final panel = tester.getRect(find.byKey(const Key('recitationTafsir')));
      expect(panel.height, lessThanOrEqualTo(size.height * 0.3), reason: 'docked, leaves room for the page');
      for (final k in ['recitationTafsir', 'miniPlayer', 'audioTafsirToggle', 'audioStop', 'audioPlayPause']) {
        final r = tester.getRect(find.byKey(Key(k)));
        expect(r.left, greaterThanOrEqualTo(-0.01), reason: k);
        expect(r.right, lessThanOrEqualTo(size.width + 0.01), reason: k);
        expect(r.bottom, lessThanOrEqualTo(size.height + 0.01), reason: k);
      }
      final scroll = tester.state<ScrollableState>(
        find.descendant(of: find.byKey(const Key('recitationTafsir')), matching: find.byType(Scrollable)),
      );
      expect(scroll.position.maxScrollExtent, greaterThan(0));
      await tester.drag(find.byKey(const Key('recitationTafsir')), const Offset(0, -80));
      await tester.pumpAndSettle();
      expect(scroll.position.pixels, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }
}
