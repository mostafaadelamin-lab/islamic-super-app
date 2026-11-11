import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/nasheeds.dart';
import 'package:rattil/ui/adhkar_audio.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/library_screen.dart' show OfflineButton;
import 'package:rattil/ui/nasheeds_screen.dart';
import 'package:rattil/ui/youtube_player.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  setUp(() => debugYouTubeEmbedBuilder = (_, id) => ColoredBox(key: Key('fakeEmbed-$id'), color: Colors.black));
  setUp(() => debugAssetAudioFactory = _FakeAudio.new);
  tearDown(() {
    debugYouTubeEmbedBuilder = null;
    debugAssetAudioFactory = null;
    _FakeAudio.loaded.clear();
  });

  test('nasheeds list: unique ids, https audio, no empty munshid; adhkar videos well-formed', () {
    final all = Munshid.parse(File('assets/content/nasheeds.v2.json').readAsStringSync());
    expect(all.length, greaterThan(20));
    final ids = [for (final m in all) ...[for (final n in m.items) n.id]];
    expect(ids.toSet().length, ids.length);
    for (final m in all) {
      expect(m.items, isNotEmpty, reason: m.name);
      for (final n in m.items) {
        expect(n.url, startsWith('https://'), reason: n.title);
      }
    }
    expect(adhkarAudioVideo.values, everyElement(matches(MediaItem.idPattern)));
    expect(adhkarAudioVideo.keys.toSet(), AdhkarAudio.values.toSet());
  });

  test('the embed is the privacy-enhanced player and other links leave it', () {
    final u = youTubeEmbedUri('V2Brp_esIVI');
    expect(u.host, 'www.youtube-nocookie.com');
    expect(u.path, '/embed/V2Brp_esIVI');
    expect(youTubeEmbedNavigationAllowed(u), isTrue);
    expect(youTubeEmbedNavigationAllowed(Uri.parse('https://www.youtube.com/watch?v=V2Brp_esIVI')), isFalse);
    expect(youTubeEmbedNavigationAllowed(Uri.parse('http://www.youtube-nocookie.com/embed/x')), isFalse);
  });

  testWidgets('nasheeds: munshidin list, search by title, a munshid opens with download buttons', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const NasheedsScreen());
    await tester.pumpAndSettle();
    expect(find.text('أناشيد'), findsOneWidget);
    expect(find.byKey(const Key('nasheedsNote')), findsOneWidget);
    expect(find.byKey(const Key('munshid.2')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('nasheedsSearch')), 'رحمن يا رحمن');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nasheed-347')), findsOneWidget);
    await tester.enterText(find.byKey(const Key('nasheedsSearch')), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('munshid.2')));
    await tester.pumpAndSettle();
    expect(find.text('مشاري العفاسي'), findsWidgets);
    expect(find.byKey(const Key('nasheed-347')), findsOneWidget);
    expect(find.byType(OfflineButton), findsWidgets);
    await expectAccessible(tester);
  });

  testWidgets('adhkar: only morning and evening recordings, played offline', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const AdhkarScreen());
    await tester.scrollUntilVisible(find.byKey(const Key('adhkarAudio.morning')), 200,
        scrollable: find.descendant(of: find.byKey(const Key('adhkarHub')), matching: find.byType(Scrollable)));
    expect(find.byKey(const Key('adhkarAudio.sleep')), findsNothing);
    await tester.tap(find.byKey(const Key('adhkarAudio.morning')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('adhkarAudioSheet')), findsOneWidget, reason: 'morning plays offline');
    expect(_FakeAudio.loaded, ['assets/audio/adhkar_morning_alafasy.mp3']);
    expect(find.text('18:41'), findsOneWidget);
    await tester.tap(find.byKey(const Key('adhkarAudioPlay')));
    await tester.pump();
    expect(_FakeAudio.last!.isPlaying, isFalse);
  });
}

class _FakeAudio implements AssetAudio {
  _FakeAudio() {
    last = this;
  }
  static final loaded = <String>[];
  static _FakeAudio? last;
  bool isPlaying = false;
  final _pos = StreamController<Duration>.broadcast();
  final _playing = StreamController<bool>.broadcast();
  @override
  Future<Duration?> load(String asset) async {
    loaded.add(asset);
    return const Duration(minutes: 18, seconds: 41);
  }
  @override
  Future<void> play() async => _playing.add(isPlaying = true);
  @override
  Future<void> pause() async => _playing.add(isPlaying = false);
  @override
  Future<void> seek(Duration d) async => _pos.add(d);
  @override
  Future<void> dispose() async {}
  @override
  Stream<Duration> get position => _pos.stream;
  @override
  Stream<bool> get playing => _playing.stream;
}
