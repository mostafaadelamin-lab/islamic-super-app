import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/downloads.dart';
import 'package:rattil/data/recitation.dart';
import 'package:rattil/data/settings.dart';
import 'package:rattil/domain/audio_queue.dart';
import 'package:rattil/domain/quran.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers.dart';

void main() {
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('rattil-dl'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('downloads a surah with its basmala, plays it offline, lists and deletes it', () async {
    final content = await loadContent();
    final asked = <String>[];
    var fail = false;
    final client = MockClient((r) async {
      asked.add(r.url.path);
      if (fail) return http.Response('', 503);
      return http.Response.bytes(Uint8List.fromList(List.filled(100, 1)), 200);
    });
    final d = RecitationDownloads(content: content, httpClient: client, root: () async => tmp);
    const reciter = 'Alafasy_128kbps';
    expect(await d.isDownloaded(reciter, 112), isFalse);
    expect(await d.localFile(reciter, const AyahRef(112, 1)), isNull);
    await d.downloadSurah(reciter, 112);
    expect(asked.length, 5); // basmala 001001 + 4 ayahs
    expect(asked.first, endsWith('001001.mp3'));
    expect(await d.isDownloaded(reciter, 112), isTrue);
    expect(await d.localFile(reciter, const AyahRef(112, 4)), endsWith('112004.mp3'));
    expect(await d.localFile(reciter, const AyahRef(1, 1), forSurah: 112), endsWith('001001.mp3'));
    expect(await d.localFile(reciter, const AyahRef(1, 1)), isNull); // al-Fatiha itself is not downloaded
    expect(await d.list(), [(reciter: reciter, surah: 112, bytes: 400)]);
    expect(await d.totalBytes(), 500 + 2); // 5 files + "ok" marker

    // A failure keeps what was saved and leaves the surah not downloaded.
    fail = true;
    await expectLater(d.downloadSurah(reciter, 113), throwsA(isA<HttpException>()));
    expect(await d.isDownloaded(reciter, 113), isFalse);
    expect(d.progress, isEmpty);

    await d.deleteSurah(reciter, 112);
    expect(await d.isDownloaded(reciter, 112), isFalse);
    await d.deleteAll();
    expect(await d.totalBytes(), 0);
  });

  test('a podcast .m4a episode is saved as .m4a (the iOS player needs the right extension)', () async {
    final content = await loadContent();
    final client = MockClient((r) async => http.Response.bytes(Uint8List.fromList(List.filled(100, 1)), 200));
    final d = RecitationDownloads(content: content, httpClient: client, root: () async => tmp);
    await d.downloadFile('lessons-qudwa-amgad', 'e1', 'https://d3ctxlq1ktw2nl.cloudfront.net/staging/x/a.m4a');
    expect(await d.offlineFile('lessons-qudwa-amgad', 'e1'), endsWith('e1.m4a'));
    await d.downloadFile('lessons-qudwa-amgad', 'e2', 'https://feeds.soundcloud.com/stream/123-waiepodcast-x');
    expect(await d.offlineFile('lessons-qudwa-amgad', 'e2'), endsWith('e2.mp3'));
    await d.deleteFile('lessons-qudwa-amgad', 'e1');
    expect(await d.offlineFile('lessons-qudwa-amgad', 'e1'), isNull);
  });

  test('the player uses the downloaded file and the chosen speed', () async {
    final content = await loadContent();
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsController(await SharedPreferences.getInstance());
    await settings.setAudioSpeed(1.5);
    await settings.setAudioSpeed(3); // not offered: back to normal
    expect(settings.audioSpeed, 1.0);
    await settings.setAudioSpeed(1.25);
    final backend = FakeAudioBackend();
    final rec = RecitationController(
      content: content,
      settings: settings,
      backendFactory: () => backend,
      localFile: (reciter, item) async => item.ref.ayah == 2 ? '/data/rec/112002.mp3' : null,
    );
    await rec.playFrom(const AyahRef(112, 2), scope: PlayScope.ayah);
    expect(backend.loaded.single, 'file:///data/rec/112002.mp3');
    expect(backend.speed, 1.25);
    await rec.setSpeed(2.0);
    expect(backend.speed, 2.0);
    expect(settings.audioSpeed, 2.0);
    rec.dispose();
  });
}
