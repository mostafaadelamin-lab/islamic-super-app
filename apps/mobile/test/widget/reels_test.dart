import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/domain/reels.dart';
import 'package:rattil/ui/reels_screen.dart';
import 'package:rattil/ui/video_search_screen.dart';

import '../helpers.dart';

AppContent withReels(AppContent c, List<Map<String, dynamic>> items) => AppContent(
  quran: c.quran,
  mushaf: c.mushaf,
  reciters: c.reciters,
  adhkar: c.adhkar,
  hajj: c.hajj,
  stepDuas: c.stepDuas,
  integrity: c.integrity,
  prayerConfig: c.prayerConfig,
  cities: c.cities,
  renderMap: c.renderMap,
  normalizer: c.normalizer,
  versions: c.versions,
  reels: ReelCatalog.fromJson({'schema': 'reels.v1', 'items': items}),
);

Map<String, dynamic> reel(String ref, String status, String category, String title, {String platform = 'youtube'}) => {
  'platform': platform,
  'ref': ref,
  'title': {'ar': title, 'en': title},
  'speaker': null,
  'category': category,
  'status': status,
  'reviewer': status == 'approved' ? 'الشيخ فلان' : null,
};

/// Stands in for the WebView player and records which reel it was asked to play.
Widget fakePlayer(BuildContext context, Reel r) =>
    ColoredBox(key: Key('player.${r.ref}'), color: Colors.teal, child: const SizedBox.expand());

void main() {
  late AppContent base;
  setUpAll(() async => base = await loadContent());

  testWidgets('no placeholder reels and no reviewer switch; the search bar opens video search', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const ReelsScreen(playerBuilder: fakePlayer, showPosters: false));
    // Owner 2026-11-13: the two "pending review" samples are gone; videos come from the trusted channels.
    expect(app.services.content.reels.items.where((r) => r.isPending), isEmpty);
    expect(find.byKey(const Key('reels.empty')), findsOneWidget);
    expect(find.byKey(const Key('reels.reviewer')), findsNothing);
    await tester.tap(find.byKey(const Key('reels.searchBar')));
    await tester.pumpAndSettle();
    expect(find.byType(VideoSearchScreen), findsOneWidget);
  });

  testWidgets('one live player at a time; swiping up plays the next reel', (tester) async {
    final content = withReels(base, [
      reel('hTtlD-u4_HI', 'approved', 'recitation', 'تلاوة خاشعة أولى'),
      reel('26dRG7OeL6Q', 'approved', 'lesson', 'درس مختصر'),
      reel('dQw4w9WgXcQ', 'pending', 'lesson', 'غير مراجع'),
    ]);
    await pumpApp(tester, size: tallPhone, content: content);
    await pushScreen(tester, const ReelsScreen(playerBuilder: fakePlayer, showPosters: false));
    expect(find.byKey(const Key('player.hTtlD-u4_HI')), findsOneWidget);
    expect(find.text('تلاوة قرآنية'), findsNothing); // labels removed (owner)
    expect(find.text('راجعه: الشيخ فلان'), findsNothing); // labels removed (owner)
    expect(find.text('غير مراجع'), findsNothing, reason: 'pending reels are hidden from normal users');

    await tester.fling(find.byKey(const Key('reels.feed')), const Offset(0, -600), 2000);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('player.26dRG7OeL6Q')), findsOneWidget);
    expect(find.byKey(const Key('player.hTtlD-u4_HI')), findsNothing);
    expect(find.text('درس ديني'), findsNothing);
  });

  testWidgets('Instagram admonition reel: no labels, Instagram button, poster placeholder off-screen', (tester) async {
    final content = withReels(base, [
      reel('C1a2B3c4D5e', 'approved', 'admonition', 'موعظة قصيرة', platform: 'instagram'),
      reel('hTtlD-u4_HI', 'approved', 'recitation', 'تلاوة'),
    ]);
    await pumpApp(tester, size: tallPhone, content: content);
    await pushScreen(tester, const ReelsScreen(playerBuilder: fakePlayer, showPosters: false));
    expect(find.byKey(const Key('player.C1a2B3c4D5e')), findsOneWidget);
    expect(find.text('نصائح ومواعظ'), findsNothing);
    expect(find.text('إنستجرام'), findsNothing);
    expect(find.text('افتح على إنستجرام'), findsOneWidget);
    await tester.fling(find.byKey(const Key('reels.feed')), const Offset(0, -600), 2000);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('player.hTtlD-u4_HI')), findsOneWidget);
    expect(find.text('افتح على يوتيوب'), findsOneWidget);
  });

  group('automatic reels from trusted channels', () {
    // Newest first: BBBBBBBBBB2 (9 Nov) leads the feed.
    final fixture = File('test/fixtures/youtube-feed.xml').readAsStringSync();
    // Only the first shipped channel (Sheikh Yasser Al-Dosari) answers; the others are unreachable.
    http.Response yasserOnly(http.BaseRequest req) => req.url.toString().contains('YuUcfXvsHapABTcPRWCEoQ')
        ? http.Response.bytes(utf8.encode(fixture), 200)
        : http.Response('', 404);

    testWidgets('pulls the newest Shorts of the trusted channel and plays them with no review banner', (tester) async {
      final calls = <Uri>[];
      final app = await pumpApp(
        tester,
        size: tallPhone,
        httpClient: MockClient((req) async {
          calls.add(req.url);
          return yasserOnly(req);
        }),
      );
      expect(app.services.content.reelSources, isNotEmpty, reason: 'the shipped list has the owner-approved channel');
      await pushScreen(tester, const ReelsScreen(playerBuilder: fakePlayer, showPosters: false));
      await tester.pumpAndSettle();
      expect(calls.first.host, 'www.youtube.com');
      expect(find.byKey(const Key('reels.feed')), findsOneWidget);
      expect(find.byKey(const Key('player.BBBBBBBBBB2')), findsOneWidget);
      expect(find.text('بث مباشر صلاة التراويح'), findsOneWidget);
      expect(find.text('قناة موثوقة'), findsNothing);
      expect(find.textContaining('لم تتم مراجعة'), findsNothing);
      expect(find.byKey(const Key('reel.hide.yt-BBBBBBBBBB2')), findsOneWidget);
    });

    testWidgets('hiding the channel empties its reels, with undo', (tester) async {
      final app = await pumpApp(tester, size: tallPhone, httpClient: MockClient((req) async => yasserOnly(req)));
      await pushScreen(tester, const ReelsScreen(playerBuilder: fakePlayer, showPosters: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('reel.hide.yt-BBBBBBBBBB2')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reels.feed')), findsNothing);
      expect(find.textContaining('تم إخفاء'), findsOneWidget);
      expect(app.services.reelsFeed.hidden, hasLength(1));
      expect(find.byKey(const Key('reels.showHidden')), findsOneWidget);
      await tester.tap(find.text('تراجع'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reels.feed')), findsOneWidget);
      expect(app.services.reelsFeed.hidden, isEmpty);
    });

    testWidgets('offline with nothing cached: message and retry', (tester) async {
      var online = false;
      await pumpApp(
        tester,
        size: tallPhone,
        httpClient: MockClient((req) async {
          if (!online) throw const SocketException('offline');
          return yasserOnly(req);
        }),
      );
      await pushScreen(tester, const ReelsScreen(playerBuilder: fakePlayer, showPosters: false));
      await tester.pumpAndSettle();
      expect(find.textContaining('تعذّر الوصول إلى يوتيوب'), findsOneWidget);
      online = true;
      await tester.tap(find.byKey(const Key('reels.retry')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('player.BBBBBBBBBB2')), findsOneWidget);
    });
  });
}
