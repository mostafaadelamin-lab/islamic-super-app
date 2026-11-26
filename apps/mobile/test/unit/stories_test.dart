import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/stories.dart';

import '../helpers.dart';

Map<String, dynamic> ep(Map<String, dynamic> over) => {
  'id': 'yusuf',
  'title': {'ar': 'قصة يوسف', 'en': 'Joseph'},
  'url': 'https://archive.org/download/x/a.mp3',
  'durationSec': 4459,
  'story': 'yusuf',
  'status': 'pending',
  'reviewer': null,
  ...over,
};

void main() {
  late List<int> counts;
  setUpAll(() async {
    final c = await loadContent();
    counts = [for (final s in c.quran.surahs) s.ayahCount];
  });

  test('the shipped bundle: verse stories and Sheikh al-Sha\'rawi\'s 44 episodes (replaced al-Awadi, owner 2026-11-26), all pending', () async {
    final c = await loadContent();
    final cat = c.stories;
    final raw = jsonDecode(File('assets/content/stories.v1.json').readAsStringSync()) as Map<String, dynamic>;
    expect(cat.stories, hasLength((raw['items'] as List).length));
    expect(cat.stories.length, greaterThanOrEqualTo(20));
    expect(cat.series, hasLength(1));
    final se = cat.series.single;
    expect(se.narratorAr, contains('الشعراوي'));
    expect(se.episodes, hasLength(44));
    expect(se.episodes.every((e) => e.isPending), isTrue);
    expect(se.visible(reviewer: false), isEmpty);
    expect(se.visible(reviewer: true), hasLength(44));
    for (final e in se.episodes) {
      if (e.story != null) expect(cat.byId(e.story), isNotNull, reason: e.id);
    }
  });

  test('drops stories whose verses do not exist, and malformed ones', () {
    Map<String, dynamic> st(Object segs, {String id = 'a', String status = 'pending'}) => {
      'id': id,
      'category': 'prophets',
      'title': {'ar': 'قصة', 'en': 'Story'},
      'segments': segs,
      'status': status,
    };
    final cat = StoryCatalog.fromJson({
      'schema': 'stories.v1',
      'items': [
        st([
          [12, 4, 101],
        ]),
        st([
          [12, 4, 112],
        ], id: 'b'), // Yusuf has 111 ayahs
        st([
          [12, 9, 3],
        ], id: 'c'),
        st([
          [115, 1, 1],
        ], id: 'd'),
        st([], id: 'e'),
        st(
          [
            [1, 1, 2],
          ],
          id: 'f',
          status: 'rejected',
        ),
        st([
          [1, 1, 2],
        ], id: 'Bad Id'),
      ],
    }, counts);
    expect(cat.stories.map((s) => s.id), ['a']);
    expect(cat.stories.single.ayahCount, 98);
    expect(cat.stories.single.contains(const AyahRef(12, 50)), isTrue);
    expect(cat.stories.single.contains(const AyahRef(12, 102)), isFalse);
    expect(StoryCatalog.fromJson({'schema': 'x'}, counts).stories, isEmpty);
  });

  test('episodes: https audio only; approved for everyone, pending for reviewers', () {
    final se = StorySeries.tryParse({
      'id': 's',
      'title': {'ar': 'قصص الأنبياء'},
      'narrator': {'ar': 'الشيخ'},
      'licence': 'non-commercial',
      'episodes': [
        ep({}),
        ep({'id': 'adam', 'status': 'approved', 'reviewer': 'الشيخ س'}),
        ep({'id': 'h', 'url': 'http://a.org/x.mp3'}),
        ep({'id': 'j', 'url': 'javascript:alert(1)//x.mp3'}),
        ep({'id': 'p', 'url': 'https://a.org/page.html'}),
        ep({'id': 'r', 'status': 'rejected'}),
      ],
    })!;
    expect(se.episodes.map((e) => e.id), ['yusuf', 'adam']);
    expect(se.visible(reviewer: false).map((e) => e.id), ['adam']);
    expect(se.visible(reviewer: true).map((e) => e.id), ['yusuf', 'adam']);
    expect(se.episodes.first.minutes, 74);
    expect(se.episodes.last.reviewer, 'الشيخ س');
    expect(StorySeries.tryParse({...ep({}), 'licence': ' '}), isNull);
  });
}
