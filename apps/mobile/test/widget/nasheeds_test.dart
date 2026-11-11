import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/nasheeds.dart';
import 'package:rattil/ui/adhkar_audio.dart';
import 'package:rattil/ui/adhkar_screen.dart';
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

  test('every nasheed and adhkar recording is a well-formed, unique YouTube id', () {
    final ids = [
      for (final m in munshidin) ...[for (final i in m.items) i.videoId],
      ...adhkarAudioVideo.values,
    ];
    expect(ids, everyElement(matches(MediaItem.idPattern)));
    expect(ids.toSet().length, ids.length);
    expect({for (final m in munshidin) m.id}.length, munshidin.length);
    for (final m in munshidin) {
      expect(m.channelId, matches(RegExp(r'^UC[A-Za-z0-9_-]{22}$')), reason: m.id);
      expect(m.items, isNotEmpty, reason: m.id);
    }
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

  testWidgets('nasheeds: Egypt then the Arab world; a nasheed opens its player', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const NasheedsScreen());
    expect(find.text('أناشيد'), findsOneWidget);
    expect(find.byKey(const Key('nasheedsNote')), findsOneWidget);
    expect(find.byKey(const Key('munshid.mohamed-tarek')), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('munshid.muqit')), 200,
        scrollable: find.descendant(of: find.byKey(const Key('nasheedsList')), matching: find.byType(Scrollable)));
    expect(find.byKey(const Key('munshid.muqit')), findsOneWidget);
    await tester.tap(find.byKey(const Key('munshid.muqit')));
    await tester.pumpAndSettle();
    expect(find.text('محمد المقيط'), findsOneWidget);
    await tester.tap(find.byKey(const Key('nasheed-mjmxu6zYaBM')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('ytSheet')), findsOneWidget);
    expect(find.byKey(const Key('fakeEmbed-mjmxu6zYaBM')), findsOneWidget);
    await expectAccessible(tester);
  });

  testWidgets('adhkar: Alafasy recordings from the hub and the morning list', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const AdhkarScreen());
    await tester.scrollUntilVisible(find.byKey(const Key('adhkarAudio.sleep')), 200,
        scrollable: find.descendant(of: find.byKey(const Key('adhkarHub')), matching: find.byType(Scrollable)));
    await tester.tap(find.byKey(const Key('adhkarAudio.sleep')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('fakeEmbed-5HmvokzY3Jg')), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    await pushScreen(tester, const AdhkarSessionScreen(initial: AdhkarSession.morning));
    await tester.tap(find.byKey(const Key('adhkarListen')));
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
