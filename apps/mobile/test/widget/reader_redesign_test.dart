import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/app_services.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/ui/page_reader_screen.dart';
import 'package:rattil/ui/reader_widgets.dart';

import '../helpers.dart';

/// The redesigned Mushaf reader: tabs (Mushaf / verses / tafsir), tap an ayah
/// to listen or "listen with tafsir", the bottom bar (khatma) and the font
/// size button of the lists.
void main() {
  late Map<String, dynamic> stored;
  setUpAll(() async {
    await loadContent();
    stored = readRepoJson('content/tafsir/dist/muyassar.v1.json');
  });
  String source(int s, int a) => ((stored['surahs'] as List<dynamic>)[s - 1] as List<dynamic>)[a - 1] as String;
  PageReaderScreenState reader(WidgetTester t) => t.state<PageReaderScreenState>(find.byType(PageReaderScreen));

  Future<(TestApp, FakeAudioBackend)> open(WidgetTester tester, int page, {String locale = 'ar'}) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, audio: audio, locale: locale, size: const Size(390, 844));
    await pushScreen(tester, PageReaderScreen(initialPage: page));
    return (app, audio);
  }

  testWidgets('layout: tabs on top; player card, page slider and the four bottom-bar buttons', (tester) async {
    await open(tester, 1);
    for (final k in ['readerTab-mushaf', 'readerTab-ayat', 'readerTab-tafsir', 'readerBack', 'readerHelp']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    for (final k in ['miniPlayer', 'reciterButton', 'playPage', 'audioRepeat', 'audioTafsirToggle', 'pageSlider']) {
      expect(find.byKey(Key(k)), findsOneWidget, reason: k);
    }
    expect(find.text('الفهرس'), findsOneWidget);
    expect(find.text('إشارات مرجعية'), findsOneWidget);
    expect(find.text('الختمة'), findsOneWidget);
    expect(find.text('البحث'), findsOneWidget);
    expect(find.text('مشاري راشد العفاسي'), findsOneWidget, reason: 'the default reciter on the card');
    expect(tester.takeException(), isNull);
  });

  testWidgets('verses tab lists the page\'s ayahs; tafsir tab adds the stored tafsir under each', (tester) async {
    await open(tester, 3);
    await tester.tap(find.byKey(const Key('readerTab-ayat')));
    await tester.pumpAndSettle();
    expect(reader(tester).tab, ReaderTab.ayat);
    expect(find.byKey(const Key('ayatList')), findsOneWidget);
    expect(find.byKey(const Key('listAyah-2-6')), findsOneWidget);
    expect(find.byKey(const Key('listTafsir-2-6')), findsNothing);

    await tester.tap(find.byKey(const Key('readerTab-tafsir')));
    await tester.pumpAndSettle();
    final box = find.byKey(const Key('listTafsir-2-6'));
    expect(box, findsOneWidget);
    expect(find.descendant(of: box, matching: find.text(source(2, 6))), findsOneWidget);
    // A+ enlarges the list font by 2 (up to 40)
    expect(find.byKey(const Key('readerHelp')), findsNothing);
    final app = tester.state<PageReaderScreenState>(find.byType(PageReaderScreen)).context.services;
    final before = app.settings.quranFontSize;
    await tester.tap(find.byKey(const Key('readerFontUp')));
    await tester.pumpAndSettle();
    expect(app.settings.quranFontSize, (before + 2).clamp(18, 40));

    // tapping an ayah in the list opens its sheet with its tafsir
    await tester.tap(find.byKey(const Key('listAyah-2-6')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ayahSheet')), findsOneWidget);
    expect(find.text('البقرة : ٦'), findsOneWidget);

    // back to the Mushaf tab on the same page
    Navigator.of(tester.element(find.byKey(const Key('ayahSheet')))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('readerTab-mushaf')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('mushafPage-3')), findsOneWidget);
  });

  testWidgets('tap an ayah: "listen to this ayah" plays it alone; "listen with tafsir" splits the screen', (
    tester,
  ) async {
    final (app, audio) = await open(tester, 3);
    await tester.tap(find.byKey(const Key('pageAyah-2-7')));
    await tester.pumpAndSettle();
    // Simple menu (owner 2026-11-15): tafsir and the ways to listen open from their buttons.
    expect(find.byKey(const Key('ayahPlayOne')), findsNothing);
    await tester.tap(find.byKey(const Key('ayahTafsir')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tafsirText')), findsOneWidget, reason: 'the sheet shows its tafsir');
    await tester.tap(find.byKey(const Key('ayahListen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahPlayOne')));
    await tester.pumpAndSettle();
    expect(audio.loaded.last, endsWith('/002007.mp3'));
    expect(app.services.recitation.queue.length, 1);
    audio.finish();
    await tester.pumpAndSettle();
    expect(app.services.recitation.isActive, isFalse, reason: 'only that ayah');

    await tester.tap(find.byKey(const Key('pageAyah-2-7')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahListen')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ayahPlayTafsir')));
    await tester.pumpAndSettle();
    expect(app.services.settings.tafsirWithRecitation, isTrue);
    expect(find.byKey(const Key('splitView')), findsOneWidget);
    expect(tester.widget<Text>(find.byKey(const Key('recitationTafsirText'))).data, source(2, 7));
    audio.finish();
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('recitationTafsirText'))).data, source(2, 8));
  });

  testWidgets('"listen with tafsir" on the player starts the page when nothing plays', (tester) async {
    final (app, audio) = await open(tester, 2);
    await tester.tap(find.byKey(const Key('audioTafsirToggle')));
    await tester.pumpAndSettle();
    expect(app.services.recitation.isActive, isTrue);
    expect(find.byKey(const Key('splitView')), findsOneWidget);
    expect(audio.loaded.first, endsWith('/001001.mp3'), reason: 'basmala before al-Baqarah');
  });

  testWidgets('khatma: start, pages count after staying open, continue from the first unread page', (tester) async {
    final (app, _) = await open(tester, 5);
    await tester.tap(find.byKey(const Key('barKhatma')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('khatmaStart')));
    await tester.pumpAndSettle();
    expect(reader(tester).page, 1);
    await tester.pump(const Duration(seconds: 5));
    reader(tester).jumpTo(2);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1)); // too short: page 2 is not read yet
    reader(tester).jumpTo(3);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    expect(app.services.settings.khatma!.read, {1, 3});
    await tester.tap(find.byKey(const Key('barKhatma')));
    await tester.pumpAndSettle();
    expect(find.text('قرأت ٢ من ٦٠٤ صفحة (٠٪)'), findsOneWidget);
    await tester.tap(find.byKey(const Key('khatmaContinue')));
    await tester.pumpAndSettle();
    expect(reader(tester).page, 2);
    expect(app.services.settings.khatma!.next, 2);
  });

  testWidgets('320 px: tabs, player card and bars fit without overflow', (tester) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, audio: audio, size: const Size(320, 568));
    await pushScreen(tester, const PageReaderScreen(initialPage: 50));
    await app.services.recitation.playFrom(const AyahRef(3, 1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final t in ['readerTab-ayat', 'readerTab-tafsir']) {
      await tester.tap(find.byKey(Key(t)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: t);
    }
  });
}
