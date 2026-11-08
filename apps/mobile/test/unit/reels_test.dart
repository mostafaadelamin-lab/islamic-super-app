import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/reels.dart';

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
        item({'platform': 'instagram'}),
        item({'category': 'music'}),
        item({'status': 'rejected'}),
        item({
          'title': {'ar': ' ', 'en': 'x'},
        }),
        item({
          'ref': '26dRG7OeL6Q',
          'category': 'lesson',
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

  test('official privacy-enhanced YouTube embed, autoplaying muted and inline', () {
    final r = ReelCatalog.fromJson({
      'schema': 'reels.v1',
      'items': [item({})],
    }).items.single;
    final u = r.embedUri();
    expect(u.host, 'www.youtube-nocookie.com');
    expect(u.path, '/embed/hTtlD-u4_HI');
    expect(u.queryParameters, containsPair('autoplay', '1'));
    expect(u.queryParameters, containsPair('mute', '1'));
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
}
