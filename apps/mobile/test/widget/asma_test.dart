import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/ui/asma_screen.dart';
import 'package:rattil/ui/dhikr_audio.dart';

import '../helpers.dart';

class _FakeAudio implements UrlAudio {
  final playingC = StreamController<bool>.broadcast();
  final urls = <String>[];
  @override
  Future<void> play(String url) async {
    urls.add(url);
    playingC.add(true);
  }

  @override
  Future<void> pause() async => playingC.add(false);
  @override
  Future<void> resume() async => playingC.add(true);
  @override
  Future<void> seek(Duration d) async {}
  @override
  Future<void> stop() async => playingC.add(false);
  @override
  Stream<bool> get playing => playingC.stream;
  @override
  Stream<bool> get completed => const Stream.empty();
  @override
  Stream<Duration> get position => const Stream.empty();
  @override
  Stream<Duration?> get duration => const Stream.empty();
}

void main() {
  setUpAll(loadContent);

  test('91 of the 99 names have a recorded lesson by Sheikh al-Nabulsi; every link is https', () {
    final j = jsonDecode(File('assets/content/asma-audio.v1.json').readAsStringSync()) as Map<String, dynamic>;
    final names = j['names'] as Map<String, dynamic>;
    expect(names.length, 91);
    for (final v in names.values) {
      expect((v as List<dynamic>).length, inInclusiveRange(1, 2));
      for (final u in v) {
        expect(u as String, startsWith('https://'));
      }
    }
  });

  testWidgets('the lesson buttons play the sheikh\'s recording with a player bar; no phone voice', (tester) async {
    final fake = _FakeAudio();
    debugUrlAudioFactory = () => fake;
    addTearDown(() => debugUrlAudioFactory = null);
    await pumpApp(tester, size: tallPhone);
    await pushScreen(
      tester,
      AsmaScreen(
        loader: () async => const [
          AsmaEntry(name: 'الرحمن', text: 'شرح', page: 1),
          AsmaEntry(name: 'المحيط', text: 'شرح', page: 2),
        ],
        lessons: () async => const {
          0: ['https://example.org/a.mp3', 'https://example.org/b.mp3'],
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('asmaListen-0')), findsOneWidget);
    expect(find.byKey(const Key('asmaListen-0-2')), findsOneWidget);
    expect(find.byKey(const Key('asmaListen-1')), findsNothing, reason: 'no lesson for this name');
    await tester.tap(find.byKey(const Key('asmaListen-0-2')));
    await tester.pumpAndSettle();
    expect(fake.urls, ['https://example.org/b.mp3']);
    expect(find.byKey(const Key('dhikrPlayerBar')), findsOneWidget);
    // Owner 2026-11-22: the player sits inside this name's card (not a page or a bar of its own),
    // with the time and a seek bar like the lock screen.
    expect(
      find.descendant(of: find.byKey(const Key('asma-0')), matching: find.byKey(const Key('dhikrPlayerBar'))),
      findsOneWidget,
    );
    expect(find.descendant(of: find.byKey(const Key('asma-1')), matching: find.byKey(const Key('dhikrPlayerBar'))), findsNothing);
    expect(find.byKey(const Key('dhikrPlayerSlider')), findsOneWidget);
    expect(find.byKey(const Key('dhikrPlayerBack30')), findsOneWidget);
    expect(find.byKey(const Key('dhikrPlayerFwd30')), findsOneWidget);
    expect(find.textContaining('الرحمن'), findsWidgets);
    await tester.tap(find.byKey(const Key('dhikrPlayerStop')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dhikrPlayerBar')), findsNothing);
  });
}
