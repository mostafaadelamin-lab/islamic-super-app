import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rattil/data/reels_feed.dart';
import 'package:rattil/domain/reels.dart';
import 'package:rattil/domain/video_search.dart';
import 'package:shared_preferences/shared_preferences.dart';

const ch = 'UCYuUcfXvsHapABTcPRWCEoQ';
const other = 'UCaaaaaaaaaaaaaaaaaaaaaa';
const yasser = ReelSource(
  id: 'yt-$ch',
  channelId: ch,
  nameAr: 'الشيخ ياسر الدوسري',
  nameEn: 'Sheikh Yasser Al-Dosari',
  category: 'recitation',
);

String results(List<(String, String, String, String)> rows) =>
    'var ytInitialData = {"contents":[${rows.map((r) => '{"videoRenderer":{"videoId":"${r.$1}","thumbnail":{},"title":{"runs":[{"text":"${r.$2}"}]},"ownerText":{"runs":[{"text":"${r.$3}","navigationEndpoint":{"browseEndpoint":{"browseId":"${r.$4}"}}}]},"lengthText":{"simpleText":"12:34"}}}').join(',')}]};';

void main() {
  group('Islamic filter (same rules as the website)', () {
    test('Islamic titles, blocked words, and Arabic prefixes', () {
      expect(looksIslamic('سورة البقرة كاملة بصوت ياسر الدوسري'), isTrue);
      expect(looksIslamic('بالقرآن نحيا'), isTrue);
      expect(looksIslamic('Beautiful Quran recitation'), isTrue);
      expect(looksIslamic('مدرسة المشاغبين'), isFalse);
      expect(isBlockedVideoText('اغنية جديدة'), isTrue);
      expect(isBlockedVideoText('Islamic song remix'), isTrue);
      expect(isBlockedVideoText('موعظة مؤثرة'), isFalse);
    });

    test('recitation only: trusted reciters pass, others need a recitation title, never lessons', () {
      const trusted = {ch};
      expect(allowedVideo(const VideoHit(ref: 'a', title: 'vlog', channelId: ch), trusted), isTrue);
      expect(allowedVideo(const VideoHit(ref: 'a', title: 'تلاوة سورة الكهف', channelId: other), trusted), isTrue);
      expect(allowedVideo(const VideoHit(ref: 'a', title: 'تفسير سورة الكهف', channelId: other), trusted), isFalse);
      expect(allowedVideo(const VideoHit(ref: 'a', title: 'درس عن الصبر', channelId: ch), trusted), isFalse);
      expect(allowedVideo(const VideoHit(ref: 'a', title: 'my day vlog', channelId: other), trusted), isFalse);
      expect(allowedVideo(const VideoHit(ref: 'a', title: 'اغنية عن الله', channelId: ch), trusted), isFalse);
      expect(
        allowedVideo(
          const VideoHit(ref: 'a', title: 'تلاوة سورة يس', channel: 'الشيخ محمد حسان', channelId: other),
          trusted,
        ),
        isFalse,
        reason: 'an excluded sheikh',
      );
    });

    test('feed titles: surah names that look like other words still pass', () {
      expect(allowedFeedTitle('سورة القصص كاملة'), isTrue);
      expect(allowedFeedTitle('سورة الشرح'), isTrue);
      expect(allowedFeedTitle('صلاة العشاء من المسجد الحرام'), isTrue);
      expect(allowedFeedTitle('آيات ﴿وَلَسَوْفَ يُعْطِيكَ رَبُّكَ﴾'), isTrue);
      expect(allowedFeedTitle('خطبة الجمعة من المسجد النبوي'), isFalse);
      expect(allowedFeedTitle('نشيد جميل'), isFalse);
      expect(allowedFeedTitle('لقاء مع القارئ'), isFalse);
      expect(allowedChannel('تلاوات خاشعة'), isTrue);
      expect(allowedChannel('دروس ومواعظ'), isFalse);
    });

    test('parses the results page', () {
      final hits = parseVideoSearch(results([('abcdefghijk', r'درس م', 'قناة', ch)]));
      expect(hits.single.ref, 'abcdefghijk');
      expect(hits.single.title, 'درس م');
      expect(hits.single.channelId, ch);
      expect(hits.single.duration, '12:34');
    });
  });

  group('ReelsFeedController search', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });
    ReelsFeedController make(http.Client c) =>
        ReelsFeedController(sources: const [yasser], httpClient: c, prefs: prefs);

    test('keeps a search history on the device: newest first, no duplicates, at most 20', () async {
      final f = make(MockClient((_) async => http.Response('', 404)));
      for (var i = 0; i < 25; i++) {
        await f.rememberSearch('q$i');
      }
      expect(f.searchHistory, hasLength(20));
      expect(f.searchHistory.first, 'q24');
      await f.rememberSearch(' Q24 ');
      expect(f.searchHistory.first, 'Q24');
      expect(f.searchHistory.where((q) => q.toLowerCase() == 'q24'), hasLength(1));
      await f.forgetSearch('Q24');
      expect(f.searchHistory.first, 'q23');
      await f.clearSearchHistory();
      expect(f.searchHistory, isEmpty);
    });

    test('drops non-Islamic results, trusted channels first; refuses blocked queries; null when offline', () async {
      final calls = <Uri>[];
      final f = make(
        MockClient((req) async {
          calls.add(req.url);
          return http.Response(
            results([
              ('aaaaaaaaaaa', 'تلاوة خاشعة', 'قناة عامة', other),
              ('bbbbbbbbbbb', 'مقلب مضحك', 'ترفيه', other),
              ('ccccccccccc', 'Short clip', 'الدوسري', ch),
            ]),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }),
      );
      final hits = await f.searchVideos('تلاوة');
      expect(hits!.map((h) => h.ref), ['ccccccccccc', 'aaaaaaaaaaa']);
      expect(hits.first.trusted, isTrue);
      expect(calls.single.path, '/results');
      expect(await f.searchVideos('اغاني'), isEmpty);
      expect(calls, hasLength(1));
      final offline = make(MockClient((_) async => throw Exception('offline')));
      expect(await offline.searchVideos('درس'), isNull);
    });
  });

  test('feeds fail (404/500): the channel Videos page fills the feed', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const lockup =
        '{"lockupViewModel":{"contentImage":{"thumbnailViewModel":{"image":{"sources":[{"url":"https://i.ytimg.com/vi/abcdefghijk/hq720.jpg"}]}}},'
        '"metadata":{"lockupMetadataViewModel":{"title":{"content":"سورة الكهف كاملة"}}}}}';
    final f = ReelsFeedController(
      sources: const [yasser],
      prefs: prefs,
      httpClient: MockClient(
        (req) async => req.url.path.endsWith('/videos')
            ? http.Response.bytes(utf8.encode('x $lockup y'), 200)
            : http.Response('', req.url.path.contains('feeds') ? 404 : 500),
      ),
    );
    await f.refresh();
    expect(f.items.single.ref, 'abcdefghijk');
    expect(f.items.single.titleAr, 'سورة الكهف كاملة');
  });
}
