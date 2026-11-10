import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/adhkar.dart';
import 'package:rattil/domain/nasheeds.dart';
import 'package:rattil/ui/adhkar_screen.dart';
import 'package:rattil/ui/nasheeds_screen.dart';
import 'package:rattil/ui/youtube_player.dart';

import '../helpers.dart';

void main() {
  setUpAll(loadContent);
  setUp(() => debugYouTubeEmbedBuilder = (_, id) => ColoredBox(key: Key('fakeEmbed-$id'), color: Colors.black));
  tearDown(() => debugYouTubeEmbedBuilder = null);

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
    expect(find.byKey(const Key('fakeEmbed-V2Brp_esIVI')), findsOneWidget);
  });
}
