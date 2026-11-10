import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/domain/adhan_voices.dart';
import 'package:rattil/ui/muezzin_screen.dart';

import '../helpers.dart';

/// A fake MP3: "ID3" header and enough bytes to pass the size check.
Uint8List _mp3() => Uint8List.fromList([0x49, 0x44, 0x33, ...List.filled(30 * 1024, 0)]);

void main() {
  setUpAll(loadContent);

  test('voice ids and download address', () {
    expect(isAdhanVoiceId('haram'), isTrue);
    expect(isAdhanVoiceId('iw426698'), isTrue);
    expect(isAdhanVoiceId('iw'), isFalse);
    expect(isAdhanVoiceId('../x'), isFalse);
    expect(remoteAdhanId('iw122646'), 122646);
    expect(adhanDownloadUri(5).toString(), 'https://audio.islamweb.net/audio/downloadmp3.php?audioid=5');
    expect(bundledAdhanVoice(defaultFajrVoice)!.fajr, isTrue);
    expect(bundledAdhanVoice(defaultAdhanVoice)!.fajr, isFalse);
  });

  testWidgets('defaults: Makkah Haram adhan, and its own Fajr adhan', (tester) async {
    final app = await pumpApp(tester, size: tallPhone, locale: 'en');
    final s = app.services.settings;
    expect(s.adhanVoice, 'haram');
    expect(s.adhanFajrVoice, 'haram_fajr');
    expect(s.adhanVoiceFor('fajr'), 'haram_fajr');
    expect(s.adhanVoiceFor('maghrib'), 'haram');
    expect(app.services.adhan.nativeVoiceFor('fajr'), 'adhan_haram_fajr');
    expect(app.services.adhan.nativeVoiceFor('isha'), 'adhan_haram');
    await expectLater(s.setAdhanVoice('nope'), throwsA(anything));
    expect(s.adhanVoice, 'haram');
  });

  testWidgets('Fajr list shows only Fajr adhans; tapping one downloads it (retrying) and chooses it', (tester) async {
    final urls = <String>[];
    final client = MockClient((req) async {
      urls.add(req.url.toString());
      // The server often fails the first time.
      if (urls.length == 1) return http.Response('busy', 502);
      return http.Response.bytes(_mp3(), 200);
    });
    final storage = Directory.systemTemp.createTempSync('rattil-muezzin');
    final app = await pumpApp(tester, size: tallPhone, locale: 'en', httpClient: client, storage: storage);
    // Load the catalogue outside fake async first (the screen reads it).
    await tester.runAsync(app.services.adhanVoices.catalog);
    await pushScreen(tester, const MuezzinScreen(fajr: true));
    expect(find.byKey(const Key('muezzin-haram_fajr')), findsOneWidget);
    expect(find.byKey(const Key('muezzin-haram')), findsNothing);
    // 404627: a Fajr adhan by Abdul Basit Abdul Samad in the collection.
    await tester.enterText(find.byKey(const Key('muezzinSearch')), 'عبد الباسط');
    await tester.pumpAndSettle();
    final tile = find.byKey(const Key('muezzin-iw404627'));
    expect(tile, findsOneWidget);
    expect(find.textContaining('Tap to download'), findsWidgets);
    await tester.runAsync(() async {
      await tester.tap(tile);
      for (var i = 0; i < 50 && app.services.settings.adhanFajrVoice != 'iw404627'; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pumpAndSettle();
    expect(urls, hasLength(2));
    expect(urls.last, endsWith('audioid=404627'));
    expect(app.services.settings.adhanFajrVoice, 'iw404627');
    expect(app.services.adhanVoices.isReady('iw404627'), isTrue);
    final path = app.services.adhan.nativeVoiceFor('fajr');
    expect(path, endsWith('/adhan/iw404627.mp3'));
    expect(File(path).existsSync(), isTrue);
    // The other prayers keep their own muezzin.
    expect(app.services.adhan.nativeVoiceFor('dhuhr'), 'adhan_haram');
    storage.deleteSync(recursive: true);
  });

  testWidgets('a failed download keeps the old choice and says so', timeout: const Timeout(Duration(minutes: 2)), (
    tester,
  ) async {
    final client = MockClient((req) async => http.Response('<html>error</html>', 502));
    final storage = Directory.systemTemp.createTempSync('rattil-muezzin');
    final app = await pumpApp(tester, size: tallPhone, locale: 'en', httpClient: client, storage: storage);
    final files = app.services.adhanVoices;
    await tester.runAsync(files.catalog);
    await pushScreen(tester, const MuezzinScreen(fajr: false));
    expect(find.byKey(const Key('muezzin-haram')), findsOneWidget);
    expect(find.byKey(const Key('muezzin-haram_fajr')), findsNothing);
    await tester.enterText(find.byKey(const Key('muezzinSearch')), 'رمضان سعد');
    await tester.pumpAndSettle();
    final tile = find.byKey(const Key('muezzin-iw426698'));
    expect(tile, findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(tile);
      for (var i = 0; i < 100 && (files.isDownloading('iw426698') || !files.hasFailed('iw426698')); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    });
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(app.services.settings.adhanVoice, 'haram');
    expect(find.text('Could not download the adhan. Check the internet and try again.'), findsOneWidget);
    // A voice that is not on the phone falls back to the bundled default.
    expect(files.nativeVoice('iw426698', fajr: false), 'adhan_haram');
    storage.deleteSync(recursive: true);
  });
}
