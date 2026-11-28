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
  nameAr: 'الشيخ محمود خليل الحصري',
  nameEn: 'Sheikh Al-Husary',
  category: 'recitation',
  group: 'golden',
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
            'platform': 'youtube',
            'handle': 'إسلاميات123',
            'name': {'ar': 'إسلاميات'},
            'category': 'recitation',
            'group': 'famous',
          },
          {
            'platform': 'youtube',
            'channelId': 'UCbbbbbbbbbbbbbbbbbbbbbb',
            'name': {'ar': 'دروس'},
            'category': 'lesson',
          },
          {
            'platform': 'youtube',
            'handle': 'xyz',
            'channelId': 'UCaaaaaaaaaaaaaaaaaaaaaa',
            'name': {'ar': 'x'},
            'category': 'lesson',
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
      expect(list.map((s) => s.id), ['yt-UCYuUcfXvsHapABTcPRWCEoQ', 'yt-@إسلاميات123']);
      expect(list.first.nameEn, 'ياسر');
      expect(list.first.group, isNull);
      expect(list.last.group, 'famous');
      expect(list.last.channelPage.toString(), startsWith('https://www.youtube.com/@'));
      expect(ReelSource.listFromJson({'schema': 'other'}), isEmpty);
    });

    test('feed URLs: Shorts playlist (UUSH) and channel fallback', () {
      expect(
        ReelSource.shortsFeed('UCYuUcfXvsHapABTcPRWCEoQ').toString(),
        'https://www.youtube.com/feeds/videos.xml?playlist_id=UUSHYuUcfXvsHapABTcPRWCEoQ',
      );
      expect(
        ReelSource.channelFeed('UCYuUcfXvsHapABTcPRWCEoQ').toString(),
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
      feed([
        ('DDDDDDDDDD4', 'سورة الملك', '2026-11-01T00:00:00Z'),
        ('EEEEEEEEEE5', 'سورة القصص', '2026-11-02T00:00:00Z'),
      ]),
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
            utf8.encode(isYasser ? fixture : feed([('DDDDDDDDDD4', 'تلاوة سورة الملك', '2026-11-01T00:00:00Z')])),
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

  group('recitation only, tabs, saved, live (owner 2026-11-27)', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    const sudais = ReelSource(
      id: 'yt-UCw9Ua8fLBPCetGwLmccbvtw',
      channelId: 'UCw9Ua8fLBPCetGwLmccbvtw',
      nameAr: 'الشيخ عبد الرحمن السديس',
      nameEn: 'Sheikh Al-Sudais',
      category: 'recitation',
      group: 'makkah',
    );

    ReelsFeedController make() => ReelsFeedController(
      sources: const [other, sudais],
      httpClient: MockClient((req) async {
        final golden = req.url.toString().contains('aaaaaaaa');
        return http.Response.bytes(
          utf8.encode(
            golden
                ? feed([
                    ('DDDDDDDDDD4', 'تلاوة سورة القصص', '2026-11-01T00:00:00Z'),
                    ('FFFFFFFFFF6', 'درس في الصبر', '2026-11-03T00:00:00Z'),
                    ('GGGGGGGGGG7', 'لقاء مع الشيخ', '2026-11-04T00:00:00Z'),
                  ])
                : feed([
                    ('HHHHHHHHHH8', 'صلاة العشاء من المسجد الحرام', '2026-11-05T00:00:00Z'),
                    ('IIIIIIIIII9', 'خطبة الجمعة', '2026-11-06T00:00:00Z'),
                  ]),
          ),
          200,
        );
      }),
      prefs: prefs,
      live: [
        LiveChannel.tryParse({
          'channelId': 'UCos52azQNBgW63_9uDJoPDA',
          'place': 'makkah',
          'name': {'ar': 'بث مباشر من المسجد الحرام'},
        })!,
      ],
    );

    test('lessons, sermons and interviews never enter the feed', () async {
      final c = make();
      await c.refresh();
      expect(c.items.map((r) => r.ref).toSet(), {'DDDDDDDDDD4', 'HHHHHHHHHH8'});
    });

    test('tabs: Haramain = Makkah + Madinah imams, golden generation, all', () async {
      final c = make();
      await c.refresh();
      expect(c.itemsIn(ReelsFeedController.tabHaramain).map((r) => r.ref), ['HHHHHHHHHH8']);
      expect(c.itemsIn(ReelsFeedController.tabGolden).map((r) => r.ref), ['DDDDDDDDDD4']);
      expect(c.itemsIn(ReelsFeedController.tabGolden).single.group, 'golden');
      expect(c.sourcesIn(ReelsFeedController.tabHaramain).map((s) => s.id), [sudais.id]);
      expect(c.itemsOf(sudais.id).map((r) => r.ref), ['HHHHHHHHHH8']);
      expect(c.itemsIn(ReelsFeedController.tabAll), hasLength(2));
    });

    test('save and unsave a recitation; saved ones survive a restart', () async {
      final c = make();
      await c.refresh();
      final r = c.itemsIn(ReelsFeedController.tabGolden).single;
      expect(await c.toggleSave(r), isTrue);
      expect(c.isSaved(r), isTrue);
      final again = make();
      expect(again.saved.single.ref, r.ref);
      expect(again.saved.single.speakerAr, 'الشيخ محمود خليل الحصري');
      expect(again.itemsIn(ReelsFeedController.tabSaved).single.ref, r.ref);
      expect(await again.toggleSave(r), isFalse);
      expect(again.saved, isEmpty);
    });

    test('live streams: a known 24/7 video id is embedded directly (Makkah showed "unavailable")', () {
      final l = LiveChannel.tryParse({
        'channelId': 'UCos52azQNBgW63_9uDJoPDA',
        'videoId': 'IsJTAdC3-Jw',
        'place': 'makkah',
        'name': {'ar': 'مكة'},
      })!;
      expect(l.embedUri().path, '/embed/IsJTAdC3-Jw');
      expect(l.embedUri().queryParameters.containsKey('channel'), isFalse);
      expect(l.watchUri.toString(), 'https://www.youtube.com/watch?v=IsJTAdC3-Jw');
      final bad = LiveChannel.tryParse({
        'channelId': 'UCos52azQNBgW63_9uDJoPDA',
        'videoId': 'x"><script>',
        'place': 'makkah',
        'name': {'ar': 'مكة'},
      })!;
      expect(bad.videoId, isNull);
      expect(bad.embedUri().path, '/embed/live_stream');
    });

    test('live streams: the Haramain channels through the live_stream embed', () {
      final c = make();
      final live = c.live.single;
      expect(live.id, 'live-makkah');
      expect(live.embedUri().path, '/embed/live_stream');
      expect(live.embedUri().queryParameters['channel'], 'UCos52azQNBgW63_9uDJoPDA');
      expect(
        LiveChannel.tryParse({
          'channelId': 'bad',
          'place': 'makkah',
          'name': {'ar': 'x'},
        }),
        isNull,
      );
      expect(
        LiveChannel.listFromJson({
          'schema': 'reel-sources.v1',
          'live': [
            {
              'channelId': 'UCROKYPep-UuODNwyipe6JMw',
              'place': 'madinah',
              'name': {'ar': 'المدينة'},
            },
            {
              'channelId': 'UCROKYPep-UuODNwyipe6JMw',
              'place': 'cairo',
              'name': {'ar': 'x'},
            },
          ],
        }).map((l) => l.id),
        ['live-madinah'],
      );
    });

    test('the bundled sources: recitation only, every one in a group, two live streams', () {
      final j = jsonDecode(File('assets/content/reel-sources.v1.json').readAsStringSync()) as Map<String, dynamic>;
      final list = ReelSource.listFromJson(j);
      expect(list.length, (j['sources'] as List).length);
      expect(list.every((s) => s.category == 'recitation' && s.group != null), isTrue);
      expect(LiveChannel.listFromJson(j).map((l) => l.place), ['makkah', 'madinah']);
    });
  });

  test('channel id read from a channel page', () {
    expect(
      ReelSource.channelIdFromPage(
        '<html><link rel="canonical" href="https://www.youtube.com/channel/UCch6Y4YgssEzMa4Q5zw4xjw"></html>',
      ),
      'UCch6Y4YgssEzMa4Q5zw4xjw',
    );
    expect(ReelSource.channelIdFromPage('{"externalId":"UCch6Y4YgssEzMa4Q5zw4xjw"}'), 'UCch6Y4YgssEzMa4Q5zw4xjw');
    expect(ReelSource.channelIdFromPage('<html>nothing</html>'), isNull);
  });

  test('a source given by @handle: looks the id up once, then uses the feeds', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const samir = ReelSource(
      id: 'yt-@samirmoustafa',
      handle: 'samirmoustafa',
      nameAr: 'الشيخ سمير مصطفى',
      nameEn: 'Sheikh Samir Mostafa',
      category: 'recitation',
    );
    final calls = <Uri>[];
    ReelsFeedController make() => ReelsFeedController(
      sources: const [samir],
      httpClient: MockClient((req) async {
        calls.add(req.url);
        if (req.url.path == '/@samirmoustafa') {
          return http.Response(
            '<link rel="canonical" href="https://www.youtube.com/channel/UCch6Y4YgssEzMa4Q5zw4xjw">',
            200,
          );
        }
        expect(req.url.queryParameters['playlist_id'], 'UUSHch6Y4YgssEzMa4Q5zw4xjw');
        return http.Response.bytes(utf8.encode(fixture), 200);
      }),
      prefs: prefs,
    );
    await make().refresh();
    expect(calls.map((u) => u.path), ['/@samirmoustafa', '/feeds/videos.xml']);
    expect(prefs.getString(ReelsFeedController.handleKey('samirmoustafa')), 'UCch6Y4YgssEzMa4Q5zw4xjw');
    calls.clear();
    await make().refresh(force: true);
    expect(calls.map((u) => u.path), ['/feeds/videos.xml'], reason: 'the id is remembered');
  });
}
