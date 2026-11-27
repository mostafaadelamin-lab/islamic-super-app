import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/reels.dart';
import 'package:rattil/ui/reels_screen.dart';

import '../helpers.dart';

Map<String, dynamic> item(Map<String, dynamic> over) => {
  'id': 'yt-hTtlD-u4_HI',
  'platform': 'youtube',
  'ref': 'hTtlD-u4_HI',
  'url': 'https://www.youtube.com/watch?v=hTtlD-u4_HI',
  'title': {'ar': 'تلاوة', 'en': 'Recitation'},
  'speaker': null,
  'category': 'recitation',
  'source': null,
  'status': 'approved',
  'reviewer': 'Reviewer',
  'reviewedAt': '2026-11-09',
  ...over,
};

void main() {
  test('parses well-formed YouTube reels and drops everything else', () {
    final cat = ReelCatalog.fromJson({
      'schema': 'reels.v1',
      'items': [
        item({}),
        item({'ref': 'short'}),
        item({'platform': 'tiktok'}),
        item({'platform': 'instagram', 'ref': 'a/b'}),
        item({'category': 'music'}),
        item({'category': 'lesson'}), // owner 2026-11-27: recitation only
        item({'category': 'admonition'}),
        item({'status': 'rejected'}),
        item({
          'title': {'ar': ' ', 'en': 'x'},
        }),
        item({
          'ref': '26dRG7OeL6Q',
          'category': 'recitation',
          'status': 'pending',
          'reviewer': 'ignored',
          'title': {'ar': 'درس', 'en': ''},
        }),
        'junk',
      ],
    });
    expect(cat.items.map((r) => r.id), ['yt-hTtlD-u4_HI', 'yt-26dRG7OeL6Q']);
    final pending = cat.items[1];
    expect(pending.isPending, isTrue);
    expect(pending.reviewer, isNull, reason: 'only approved reels carry a reviewer');
    expect(pending.titleEn, 'درس', reason: 'falls back to Arabic');
    expect(
      ReelCatalog.fromJson({
        'schema': 'other',
        'items': [item({})],
      }).items,
      isEmpty,
    );
  });

  test('normal users see approved reels only; reviewers also see pending ones', () {
    final cat = ReelCatalog.fromJson({
      'schema': 'reels.v1',
      'items': [
        item({}),
        item({'ref': '26dRG7OeL6Q', 'status': 'pending'}),
      ],
    });
    expect(cat.visible(reviewer: false).map((r) => r.ref), ['hTtlD-u4_HI']);
    expect(cat.visible(reviewer: true).map((r) => r.ref), ['hTtlD-u4_HI', '26dRG7OeL6Q']);
  });

  test('official privacy-enhanced YouTube embed, autoplaying with sound and inline', () {
    final r = ReelCatalog.fromJson({
      'schema': 'reels.v1',
      'items': [item({})],
    }).items.single;
    final u = r.embedUri();
    expect(u.host, 'www.youtube-nocookie.com');
    expect(u.path, '/embed/hTtlD-u4_HI');
    expect(u.queryParameters, containsPair('autoplay', '1'));
    expect(u.queryParameters, containsPair('mute', '0'));
    expect(u.queryParameters, containsPair('playsinline', '1'));
    expect(u.queryParameters, containsPair('origin', ReelCatalog.embedOrigin));
    expect(r.embedHtml(), contains('src="$u"'));
    expect(r.posterUrl, 'https://i.ytimg.com/vi/hTtlD-u4_HI/hqdefault.jpg');
  });

  test('bundled asset is the built catalogue', () {
    final bundled = jsonDecode(File('assets/content/reels.v1.json').readAsStringSync());
    expect(bundled, readRepoJson('content/reels/dist/reels.v1.json'));
    final cat = ReelCatalog.fromJson(bundled as Map<String, dynamic>);
    expect(cat.items.length, (bundled['items'] as List).length, reason: 'every shipped reel is valid');
  });

  test('Instagram reels: official embed page, recitation category, no poster', () {
    final r = ReelCatalog.fromJson({
      'schema': 'reels.v1',
      'items': [
        item({'platform': 'instagram', 'ref': 'C1a2B3c4D5e', 'category': 'recitation'}),
      ],
    }).items.single;
    expect(r.id, 'ig-C1a2B3c4D5e');
    expect(r.isInstagram, isTrue);
    expect(r.url, 'https://www.instagram.com/reel/C1a2B3c4D5e/');
    expect(r.instagramEmbedUri.toString(), 'https://www.instagram.com/reel/C1a2B3c4D5e/embed/');
    expect(r.posterUrl, isNull);
    expect(r.category, 'recitation');
  });

  test('only official embed pages may load inside the feed', () {
    bool ok(String s) => reelNavigationAllowedInFeed(Uri.parse(s));
    expect(ok('https://www.youtube-nocookie.com/embed/hTtlD-u4_HI?autoplay=1'), isTrue);
    expect(ok('https://www.instagram.com/reel/C1a2B3c4D5e/embed/'), isTrue);
    expect(ok('https://www.instagram.com/p/C1a2B3c4D5e/embed/captioned/'), isTrue);
    expect(ok('about:blank'), isTrue);
    expect(ok('https://www.youtube.com/watch?v=hTtlD-u4_HI'), isFalse);
    expect(ok('https://www.instagram.com/someuser/'), isFalse);
    expect(ok('https://www.instagram.com/reel/C1a2B3c4D5e/'), isFalse);
    expect(ok('http://www.instagram.com/reel/C1a2B3c4D5e/embed/'), isFalse);
    expect(ok('https://evil.example/embed/'), isFalse);
  });
}
