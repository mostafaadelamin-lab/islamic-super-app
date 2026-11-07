import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/data/recitation.dart';
import 'package:rattil/domain/mushaf_layout.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/mushaf_page.dart';
import 'package:rattil/ui/page_reader_screen.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);

  PageReaderScreenState reader(WidgetTester tester) =>
      tester.state<PageReaderScreenState>(find.byType(PageReaderScreen));

  Future<TestApp> open(
    WidgetTester tester,
    int page, {
    Size size = const Size(390, 844),
    FakeAudioBackend? audio,
    String locale = 'ar',
  }) async {
    final app = await pumpApp(tester, size: size, audio: audio, locale: locale);
    await pushScreen(tester, PageReaderScreen(initialPage: page));
    return app;
  }

  List<Text> lineTexts(WidgetTester tester, int page, int line) => tester
      .widgetList<Text>(find.descendant(of: find.byKey(Key('mushafLine-$page-$line')), matching: find.byType(Text)))
      .toList();

  testWidgets('page 3: 15 lines, each drawn only from canonical words with the display map applied', (tester) async {
    final app = await open(tester, 3);
    final c = app.services.content;
    final layout = c.mushaf.page(3);
    expect(layout.lines, hasLength(15));
    for (var i = 0; i < 15; i++) {
      final words = lineWords(c.quran, layout.lines[i]);
      final texts = lineTexts(tester, 3, i).map((t) => t.data).toList();
      // Words in reading order, each followed by its ayah marker digits when the ayah ends there.
      final expected = <String?>[];
      for (final w in words) {
        expected.add(c.renderMap.forDisplay(w.text));
        if (w.endsAyah) expected.add(_indic(w.ref.ayah));
      }
      expect(texts, expected, reason: 'line $i');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('display glyph map is applied to the drawn string only (stored text untouched)', (tester) async {
    final app = await pumpApp(tester, size: const Size(390, 844));
    final c = app.services.content;
    // Find the first page whose words contain a code point the render map changes.
    final keys = c.renderMap.map.keys.toList();
    late int page;
    late MushafWord word;
    outer:
    for (final p in c.mushaf.pages) {
      for (final l in p.lines.where((l) => l.kind == MushafLineKind.text)) {
        for (final w in lineWords(c.quran, l)) {
          if (keys.any(w.text.contains)) {
            page = p.page;
            word = w;
            break outer;
          }
        }
      }
    }
    final before = c.quran.text(word.ref);
    await pushScreen(tester, PageReaderScreen(initialPage: page));
    final shown = c.renderMap.forDisplay(word.text);
    expect(shown, isNot(word.text));
    expect(find.text(shown), findsWidgets);
    expect(find.text(word.text), findsNothing, reason: 'the unmapped form is never drawn');
    expect(c.quran.text(word.ref), before, reason: 'stored text unchanged');
  });

  for (final size in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets('all 604 pages build at ${size.width.toInt()}x${size.height.toInt()} without overflow; 15 lines fit', (
      tester,
    ) async {
      await open(tester, 1, size: size);
      for (var p = 1; p <= 604; p++) {
        reader(tester).jumpTo(p);
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'page $p');
        final pageFinder = find.byKey(Key('mushafPage-$p'));
        expect(pageFinder, findsOneWidget, reason: 'page $p');
        final scroll = tester.state<ScrollableState>(
          find.descendant(of: pageFinder, matching: find.byType(Scrollable)),
        );
        expect(scroll.position.maxScrollExtent, 0, reason: 'page $p fits the screen without scrolling');
        final lines = find.descendant(
          of: pageFinder,
          matching: find.byWidgetPredicate(
            (w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('mushafLine-$p-'),
          ),
        );
        expect(lines, findsNWidgets(p <= 2 ? 8 : 15), reason: 'page $p');
        // Every justified line spans the frame: its first and last child touch the edges.
        if (p == 3 || p == 300 || p == 604) {
          final layout = tester.state<NavigatorState>(find.byType(Navigator).first).context.services.content.mushaf;
          final li = layout.page(p).lines.indexWhere((l) => l.kind == MushafLineKind.text);
          final frame = tester.getRect(find.byKey(Key('mushafLine-$p-$li')));
          final texts = find.descendant(of: find.byKey(Key('mushafLine-$p-$li')), matching: find.byType(Text));
          final rects = [for (final e in texts.evaluate()) tester.getRect(find.byWidget(e.widget))];
          final minX = rects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
          final maxX = rects.map((r) => r.right).reduce((a, b) => a > b ? a : b);
          expect(maxX - minX, greaterThan(frame.width * 0.9), reason: 'page $p line $li justified edge to edge');
        }
      }
    });
  }

  testWidgets('pages 1 and 2 are centred 8-line pages with a surah band', (tester) async {
    await open(tester, 2);
    expect(find.byKey(const Key('surahBanner-2')), findsOneWidget);
    expect(find.byKey(const Key('basmala-2')), findsOneWidget);
    expect(find.text('سورة البقرة'), findsOneWidget);
    expect(find.byType(AyahMarker), findsNWidgets(5));
  });

  testWidgets('a drag turns the page like a book (the leaf rotates about the spine)', (tester) async {
    await open(tester, 10);
    final g = await tester.startGesture(tester.getCenter(find.byKey(const Key('mushafPageView'))));
    for (var i = 0; i < 6; i++) {
      await g.moveBy(const Offset(25, 0));
      await tester.pump();
    }
    final transforms = tester.widgetList<Transform>(
      find.descendant(of: find.byKey(const Key('mushafPageView')), matching: find.byType(Transform)),
    );
    expect(transforms.any((t) => t.transform.entry(3, 2) != 0), isTrue, reason: 'perspective rotation in use');
    await g.moveBy(const Offset(250, 0));
    await g.up();
    await tester.pumpAndSettle();
    expect(reader(tester).page, 11);
  });

  testWidgets('page slider jumps to a page', (tester) async {
    await open(tester, 1);
    tester.widget<Slider>(find.byKey(const Key('pageSlider'))).onChangeEnd!(300);
    await tester.pumpAndSettle();
    expect(reader(tester).page, 300);
    expect(find.text('صفحة ٣٠٠'), findsOneWidget);
  });

  testWidgets('tapping the margin hides and shows the controls', (tester) async {
    await open(tester, 5);
    expect(find.byKey(const Key('mushafControls')), findsOneWidget);
    await tester.tapAt(tester.getTopLeft(find.byKey(const Key('mushafPage-5'))) + const Offset(3, 3));
    await tester.pumpAndSettle();
    expect(reader(tester).controlsVisible, isFalse);
    expect(find.byKey(const Key('mushafControls')), findsNothing);
    await tester.tapAt(tester.getTopLeft(find.byKey(const Key('mushafPage-5'))) + const Offset(3, 3));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mushafControls')), findsOneWidget);
  });

  testWidgets('tap an ayah: highlight + actions; bookmark and copy the canonical text', (tester) async {
    final app = await open(tester, 3);
    String? clip;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') clip = (call.arguments as Map<Object?, Object?>)['text'] as String?;
      return null;
    });
    await tester.tap(find.byKey(const Key('pageAyah-2-10')));
    await tester.pumpAndSettle();
    expect(reader(tester).selected, const AyahRef(2, 10));
    expect(find.byKey(const Key('ayahSheet')), findsOneWidget);
    expect(find.text('البقرة : ١٠'), findsOneWidget);
    expect(app.services.settings.lastRead, const AyahRef(2, 10));
    // The selected ayah's words are highlighted.
    expect(
      find.ancestor(of: find.byKey(const Key('pageAyah-2-10')), matching: find.byType(DecoratedBox)),
      findsWidgets,
    );
    await tester.tap(find.byKey(const Key('ayahBookmark')));
    await tester.pumpAndSettle();
    expect(app.services.bookmarks.isBookmarked(const AyahRef(2, 10)), isTrue);

    await tester.tap(find.byKey(const Key('pageAyah-2-11')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahCopy')));
    await tester.pumpAndSettle();
    final stored = app.services.content.quran.text(const AyahRef(2, 11));
    expect(clip, startsWith(stored), reason: 'canonical stored text, not the display form');
    expect(clip, endsWith('﴿البقرة: ١١﴾'));
  });

  testWidgets('play from an ayah: the playing ayah is highlighted and pages turn automatically', (tester) async {
    final audio = FakeAudioBackend();
    final app = await open(tester, 2, audio: audio);
    await tester.tap(find.byKey(const Key('pageAyah-2-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahPlay')));
    await tester.pumpAndSettle();
    expect(audio.loaded.last, 'https://everyayah.com/data/Alafasy_128kbps/002005.mp3');
    expect(find.byKey(const Key('miniPlayer')), findsOneWidget);
    expect(app.services.recitation.currentRef, const AyahRef(2, 5));
    audio.finish();
    await tester.pumpAndSettle();
    expect(app.services.recitation.currentRef, const AyahRef(2, 6));
    expect(reader(tester).page, 3, reason: 'turned to the page of 2:6');
    expect(
      find.ancestor(of: find.byKey(const Key('pageAyah-2-6')), matching: find.byType(DecoratedBox)),
      findsWidgets,
      reason: 'playing ayah highlighted',
    );
    await tester.tap(find.byKey(const Key('audioStop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('miniPlayer')), findsNothing);
  });

  testWidgets('offline: the mini player says so and offers a retry', (tester) async {
    final audio = FakeAudioBackend()..failNext = true;
    final app = await open(tester, 1, audio: audio, locale: 'en');
    await tester.tap(find.byKey(const Key('playPage')));
    await tester.pumpAndSettle();
    expect(app.services.recitation.state, RecitationState.error);
    expect(find.text("Couldn't load the recitation. Check your internet connection and try again."), findsOneWidget);
    await tester.tap(find.byKey(const Key('audioPlayPause')));
    await tester.pumpAndSettle();
    expect(app.services.recitation.state, RecitationState.playing);
    expect(audio.loaded.last, endsWith('/001001.mp3'));
  });

  testWidgets('recitation settings sheet: reciter and repeat are saved', (tester) async {
    final app = await open(tester, 1, locale: 'en');
    await tester.tap(find.byKey(const Key('recitationSettings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('repeat-3')));
    await tester.pumpAndSettle();
    expect(app.prefs.getInt('audio.repeat'), 3);
    await tester.tap(find.byKey(const Key('reciterDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Maher Al-Muaiqly').last);
    await tester.pumpAndSettle();
    expect(app.prefs.getString('audio.reciter'), 'Maher_AlMuaiqly_64kbps');
    expect(app.services.recitation.reciter.nameEn, 'Maher Al-Muaiqly');
  });

  testWidgets('the last page is remembered and reopened from home', (tester) async {
    final app = await open(tester, 1, size: tallPhone);
    reader(tester).jumpTo(77);
    await tester.pumpAndSettle();
    await goBack(tester);
    expect(app.services.content.quran.pageOf(app.services.settings.lastRead!), 77);
    await tester.tap(find.byKey(const Key('home.openMushaf')));
    await tester.pumpAndSettle();
    expect(reader(tester).page, 77);
  });

  testWidgets('surah list and search open the right Mushaf page', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    await goToTab(tester, 1);
    await tester.tap(find.byKey(const Key('surahMushaf-18')));
    await tester.pumpAndSettle();
    expect(reader(tester).page, app.services.content.quran.pageOf(const AyahRef(18, 1)));
    expect(reader(tester).page, 293);
    await goBack(tester);
    await tester.tap(find.byTooltip('البحث في القرآن'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('searchField')), 'كرسيه');
    await tester.tap(find.byKey(const Key('searchButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('hitMushaf-2-255')));
    await tester.pumpAndSettle();
    expect(reader(tester).page, 42);
    expect(reader(tester).selected, const AyahRef(2, 255));
  });
}

String _indic(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();
