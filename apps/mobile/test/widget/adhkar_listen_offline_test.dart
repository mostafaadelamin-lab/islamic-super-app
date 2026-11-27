import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/ui/adhkar_audio.dart';
import 'package:rattil/ui/adhkar_look.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/dhikr_audio.dart';
import 'package:rattil/ui/hisn_screen.dart';

import '../helpers.dart';
import 'dhikr_extras_test.dart' show FakeUrlAudio;

/// Owner 2026-11-27: listening plays inside the page, every dhikr recording can be kept for listening
/// without internet (one or all), and «إعدادات الأذكار» (background, tashkeel, text size).
class _Rec extends FakeUrlAudio {
  final sources = <String>[];
  @override
  Future<void> play(String url) {
    sources.add(url);
    return super.play(url);
  }
}

MockHttpClient mp3Client(List<Uri> asked) {
  final client = MockHttpClient();
  when(() => client.get(any())).thenAnswer((i) async {
    asked.add(i.positionalArguments.first as Uri);
    return http.Response.bytes([0x49, 0x44, 0x33, ...List.filled(20 * 1024, 0)], 200);
  });
  return client;
}

void main() {
  setUpAll(() async {
    registerFallbackValue(Uri());
    await loadContent();
  });

  test('hiding tashkeel is display only and keeps the Quran verses as they are', () {
    const t = 'أَعُوذُ بِاللَّهِ ﴿اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ﴾ رَضِيتُ';
    expect(dhikrShown(t, tashkeel: true), t);
    expect(dhikrShown(t, tashkeel: false), 'أعوذ بالله ﴿اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ﴾ رضيت');
  });

  testWidgets('one dhikr: ⬇ saves it, then it plays from the phone; delete removes the copy', (tester) async {
    final rec = _Rec();
    debugUrlAudioFactory = () => rec;
    addTearDown(() => debugUrlAudioFactory = null);
    final storage = Directory.systemTemp.createTempSync('rattil-clips');
    final asked = <Uri>[];
    final app = await pumpApp(tester, size: tallPhone, httpClient: mp3Client(asked), storage: storage);
    await app.services.settings.setAdhkarCards(false);
    await pushScreen(tester, HisnChapterScreen(chapter: app.services.content.adhkar.hisn[1]));
    await tester.pumpAndSettle();
    final save = find.byWidgetPredicate(
      (w) => w.key is ValueKey<String> && '${(w.key as ValueKey<String>).value}'.startsWith('dhikrSave-'),
    );
    final key = (tester.widget(save.first).key as ValueKey<String>).value;
    final id = key.substring('dhikrSave-'.length);
    await tester.tap(save.first);
    await tester.pumpAndSettle();
    expect(asked.single.path, endsWith('/$id.mp3'));
    expect(File('${storage.path}/dhikr/$id.mp3').existsSync(), isTrue);
    expect(find.byKey(Key('dhikrSaved-$id')), findsOneWidget);
    await tester.tap(find.byKey(const Key('dhikrListen')).first);
    await tester.pumpAndSettle();
    expect(rec.sources.single, '${storage.path}/dhikr/$id.mp3', reason: 'plays the saved file, no streaming');
    expect(find.byKey(const Key('dhikrPlayerBar')), findsOneWidget, reason: 'the player shows right there');
    await DhikrPlayer.instance.stop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('dhikrSaved-$id')));
    await tester.pumpAndSettle();
    expect(File('${storage.path}/dhikr/$id.mp3').existsSync(), isFalse);
    expect(find.byKey(Key('dhikrSave-$id')), findsOneWidget);
  });

  testWidgets('«حمّل الكل» saves every recording of the page, then offers delete', (tester) async {
    final storage = Directory.systemTemp.createTempSync('rattil-clips');
    final asked = <Uri>[];
    final app = await pumpApp(tester, size: tallPhone, httpClient: mp3Client(asked), storage: storage);
    await app.services.settings.setAdhkarCards(false);
    final chapter = app.services.content.adhkar.hisn[1];
    await pushScreen(tester, HisnChapterScreen(chapter: chapter));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dhikrOfflineAll')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dhikrOfflineDone')), findsOneWidget);
    expect(asked, isNotEmpty);
    expect(app.services.dhikrClips.savedCount(), asked.toSet().length);
    await tester.tap(find.byKey(const Key('dhikrOfflineDelete')));
    await tester.pumpAndSettle();
    expect(app.services.dhikrClips.savedCount(), 0);
    expect(find.byKey(const Key('dhikrOfflineAll')), findsOneWidget);
  });

  testWidgets('morning adhkar: «استمع للأذكار كاملة» plays inside the page', (tester) async {
    debugAssetAudioFactory = _Asset.new;
    addTearDown(() => debugAssetAudioFactory = null);
    final storage = Directory.systemTemp.createTempSync('rattil-a');
    Directory('${storage.path}/adhkar').createSync();
    File('${storage.path}/adhkar/adhkar_morning_alafasy.mp3').writeAsBytesSync(List.filled(300 * 1024, 0xFF));
    final app = await pumpApp(tester, size: tallPhone, storage: storage);
    await app.services.settings.setAdhkarCards(false);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    expect(find.byKey(const Key('alafasyCard-morning')), findsOneWidget);
    expect(find.byKey(const Key('dhikrOffline-adhkar-morning')), findsOneWidget);
    expect(find.byKey(const Key('adhkarAudioSheet')), findsNothing);
    await tester.tap(find.byKey(const Key('alafasyListen')));
    await tester.pump();
    expect(
      find.descendant(of: find.byType(AdhkarSessionScreen), matching: find.byKey(const Key('adhkarAudioSheet'))),
      findsOneWidget,
    );
    expect(find.byType(BottomSheet), findsNothing, reason: 'in the page, not a sheet');
    await tester.tap(find.byKey(const Key('adhkarAudioClose')));
    await tester.pump();
    expect(find.byKey(const Key('adhkarAudioSheet')), findsNothing);
  });

  testWidgets('«إعدادات الأذكار»: background, tashkeel and text size, kept', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    await app.services.settings.setAdhkarCards(false);
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    await tester.tap(find.byKey(const Key('adhkarSettings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adhkarSettingsSheet')), findsOneWidget);
    await tester.tap(find.byKey(const Key('adhkarBgPick-azure')));
    await tester.pumpAndSettle();
    expect(app.services.settings.adhkarBg, 'azure');
    expect(find.byKey(const Key('adhkarBg-azure')), findsOneWidget);
    await tester.tap(find.byKey(const Key('adhkarSettingsTashkeel')));
    await tester.pumpAndSettle();
    expect(app.services.settings.adhkarTashkeel, isFalse);
    await tester.drag(find.byKey(const Key('adhkarSettingsScale')), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(app.services.settings.adhkarScale, isNot(1.0));
    await tester.tap(find.byKey(const Key('adhkarSettingsClose')));
    await tester.pumpAndSettle();
    final first = app.services.adhkar.progress(AdhkarSession.morning).items.first;
    expect(find.text(dhikrShown(first.text, tashkeel: false)), findsOneWidget);
  });
}

class _Asset implements AssetAudio {
  final _pos = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  @override
  Future<Duration?> load(String asset) async => const Duration(minutes: 20);
  @override
  Future<void> play() async => _playing.add(true);
  @override
  Future<void> pause() async => _playing.add(false);
  @override
  Future<void> seek(Duration d) async => _pos.add(d);
  @override
  Future<void> dispose() async {}
  @override
  Stream<Duration> get position => _pos.stream;
  @override
  Stream<bool> get playing => _playing.stream;
}
