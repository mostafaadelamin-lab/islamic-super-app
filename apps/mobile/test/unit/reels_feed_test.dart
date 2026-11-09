import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/reels_feed.dart';
import 'package:rattil/domain/reels.dart';
import 'package:shared_preferences/shared_preferences.dart';

const yasser = ReelSource(
  id: 'yt-UCYuUcfXvsHapABTcPRWCEoQ',
  channelId: 'UCYuUcfXvsHapABTcPRWCEoQ',
  nameAr: 'الشيخ ياسر الدوسري',
  nameEn: 'Sheikh Yasser Al-Dosari',
  category: 'recitation',
);
const other = ReelSource(
  id: 'yt-UCaaaaaaaaaaaaaaaaaaaaaa',
  channelId: 'UCaaaaaaaaaaaaaaaaaaaaaa',
  nameAr: 'قناة مواعظ',
  nameEn: 'Admonitions',
  category: 'admonition',
);

String feed(List<(String, String, String)> entries) =>
    '<feed xmlns:yt="http://www.youtube.com/xml/schemas/2015" xmlns="http://www.w3.org/2005/Atom">'
    '${entries.map((e) => '<entry><yt:videoId>${e.$1}</yt:videoId><title>${e.$2}</title><link rel="alternate" href="https://www.youtube.com/shorts/${e.$1}"/><published>${e.$3}</published></entry>').join()}'
    '</feed>';

void main() {
  final fixture = File('test/fixtures/youtube-feed.xml').readAsStringSync();

  group('ReelSource', () {
    test('parses the published sources bundle and rejects bad channels', () {
      final list = ReelSource.listFromJson({
        'schema': 'reel-sources.v1',
        'sources': [
          {
            'platform': 'youtube',
            'channelId': 'UCYuUcfXvsHapABTcPRWCEoQ',
            'name': {'ar': 'ياسر'},
            'category': 'recitation',
          },
          {
            'platform': 'youtube',
            'channelId': '@handle',
            'name': {'ar': 'x'},
            'category': 'recitation',
          },
          {
            'platform': 'instagram',
            'channelId': 'UCYuUcfXvsHapABTcPRWCEoQ',
            'name': {'ar': 'x'},
            'category': 'lesson',
          },
          {
            'platform': 'youtube',
            'channelId': 'UCaaaaaaaaaaaaaaaaaaaaaa',
            'name': {'ar': 'x'},
            'category': 'music',
          },
        ],
      });
      expect(list.map((s) => s.id), ['yt-UCYuUcfXvsHapABTcPRWCEoQ']);
      expect(list.single.nameEn, 'ياسر');
      expect(ReelSource.listFromJson({'schema': 'other'}), isEmpty);
    });

    test('feed URLs: Shorts playlist (UUSH) and channel fallback', () {
      expect(
        yasser.shortsFeed.toString(),
        'https://www.youtube.com/feeds/videos.xml?playlist_id=UUSHYuUcfXvsHapABTcPRWCEoQ',
      );
      expect(
        yasser.channelFeed.toString(),
        'https://www.youtube.com/feeds/videos.xml?channel_id=UCYuUcfXvsHapABTcPRWCEoQ',
      );
    });

    test('parses an Atom feed into automatic reels of the channel category', () {
      final all = yasser.parseFeed(fixture);
      expect(all.map((r) => r.ref), ['AAAAAAAAAA1', 'BBBBBBBBBB2', 'CCCCCCCCCC3']);
      final r = all.first;
      expect(r.status, ReelStatus.auto);
      expect(r.isAuto, isTrue);
      expect(r.category, 'recitation');
      expect(r.speakerAr, 'الشيخ ياسر الدوسري');
      expect(r.sourceId, yasser.id);
      expect(r.published, DateTime.utc(2026, 11, 8, 10));
      expect(all.last.titleAr, 'تلاوة من سورة يس & الرحمن');
      expect(yasser.parseFeed(fixture, shortsOnly: true).map((r) => r.ref), ['AAAAAAAAAA1', 'CCCCCCCCCC3']);
      expect(yasser.parseFeed('<not xml'), isEmpty);
    });

    test('automatic reels are not curated: catalogue visibility ignores them', () {
      expect(const ReelCatalog([]).visible(reviewer: true), isEmpty);
    });
  });

  test('mixReels alternates channels, newest first, without duplicates', () {
    final a = yasser.parseFeed(fixture); // A(8th) B(9th) C(7th)
    final b = other.parseFeed(
      feed([('DDDDDDDDDD4', 'موعظة', '2026-11-01T00:00:00Z'), ('EEEEEEEEEE5', 'نصيحة', '2026-11-02T00:00:00Z')]),
    );
    expect(mixReels([a, b, a]).map((r) => r.ref), [
      'BBBBBBBBBB2',
      'EEEEEEEEEE5',
      'AAAAAAAAAA1',
      'DDDDDDDDDD4',
      'CCCCCCCCCC3',
    ]);
  });

  group('ReelsFeedController', () {
    late SharedPreferences prefs;
    var now = DateTime.utc(2026, 11, 9, 12);
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      now = DateTime.utc(2026, 11, 9, 12);
    });

    ReelsFeedController make(http.Client c, {List<ReelSource> sources = const [yasser]}) =>
        ReelsFeedController(sources: sources, httpClient: c, prefs: prefs, clock: () => now);

    test('fetches the Shorts feed, caches it and reuses the cache for 3 hours', () async {
      final calls = <Uri>[];
      final c = make(
        MockClient((req) async {
          calls.add(req.url);
          return http.Response.bytes(utf8.encode(fixture), 200);
        }),
      );
      await c.refresh();
      expect(calls.single.queryParameters['playlist_id'], 'UUSHYuUcfXvsHapABTcPRWCEoQ');
      expect(c.items.map((r) => r.ref), ['BBBBBBBBBB2', 'AAAAAAAAAA1', 'CCCCCCCCCC3']);
      expect(c.failed, isFalse);

      now = now.add(const Duration(hours: 2));
      await make(MockClient((_) async => throw StateError('no network expected'))).refresh();
      expect(calls, hasLength(1));

      // A new controller (app restart) reads the cache with no network.
      final offline = make(MockClient((_) async => throw const SocketException('offline')));
      expect(offline.items, hasLength(3));
      now = now.add(const Duration(hours: 2));
      await offline.refresh();
      expect(offline.items, hasLength(3), reason: 'a failed refresh keeps the cached reels');
      expect(offline.failed, isFalse);
    });

    test('falls back to the channel feed, keeping Shorts only', () async {
      final c = make(
        MockClient((req) async {
          if (req.url.queryParameters.containsKey('playlist_id')) return http.Response('not found', 404);
          return http.Response.bytes(utf8.encode(fixture), 200);
        }),
      );
      await c.refresh();
      expect(c.items.map((r) => r.ref), ['AAAAAAAAAA1', 'CCCCCCCCCC3']);
    });

    test('reports failure when nothing is reachable and nothing is cached', () async {
      final c = make(MockClient((_) async => throw const SocketException('offline')));
      await c.refresh();
      expect(c.failed, isTrue);
      expect(c.items, isEmpty);
    });

    test('hiding a channel removes its reels; unhide brings them back', () async {
      final c = make(
        MockClient((req) async {
          final isYasser = req.url.toString().contains('YuUcfXvsHapABTcPRWCEoQ');
          return http.Response.bytes(
            utf8.encode(isYasser ? fixture : feed([('DDDDDDDDDD4', 'موعظة', '2026-11-01T00:00:00Z')])),
            200,
          );
        }),
        sources: const [yasser, other],
      );
      await c.refresh();
      expect(c.items, hasLength(4));
      await c.hide(yasser.id);
      expect(c.items.map((r) => r.ref), ['DDDDDDDDDD4']);
      expect(prefs.getStringList(ReelsFeedController.hiddenKey), [yasser.id]);
      expect(make(MockClient((_) async => http.Response('', 500))).hidden, {yasser.id});
      await c.unhide(yasser.id);
      expect(c.items, hasLength(4));
    });
  });
}
