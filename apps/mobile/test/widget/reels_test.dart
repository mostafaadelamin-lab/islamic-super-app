import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/domain/reels.dart';
import 'package:rattil/ui/reels_screen.dart';

import '../helpers.dart';

AppContent withReels(AppContent c, List<Map<String, dynamic>> items) => AppContent(
  quran: c.quran,
  mushaf: c.mushaf,
  reciters: c.reciters,
  adhkar: c.adhkar,
  hajj: c.hajj,
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

  testWidgets('empty state when nothing is approved; reviewer mode reveals pending reels', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const ReelsScreen(playerBuilder: fakePlayer, showPosters: false));
    // The shipped catalogue has pending samples only.
    expect(app.services.content.reels.items, isNotEmpty);
    expect(find.byKey(const Key('reels.empty')), findsOneWidget);
    await tester.tap(find.byKey(const Key('reels.reviewer')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reels.feed')), findsOneWidget);
    expect(find.textContaining('لم تتم مراجعة هذا المقطع'), findsOneWidget);
    expect(app.prefs.getBool('reelsReviewer'), isTrue);
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
    expect(find.text('تلاوة قرآنية'), findsOneWidget); // category chip
    expect(find.text('راجعه: الشيخ فلان'), findsOneWidget);
    expect(find.text('غير مراجع'), findsNothing, reason: 'pending reels are hidden from normal users');

    await tester.fling(find.byKey(const Key('reels.feed')), const Offset(0, -600), 2000);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('player.26dRG7OeL6Q')), findsOneWidget);
    expect(find.byKey(const Key('player.hTtlD-u4_HI')), findsNothing);
    expect(find.text('درس ديني'), findsOneWidget);
    expect(find.text('\u2066٢ / ٢\u2069'), findsOneWidget);
  });

  testWidgets('Instagram admonition reel: Instagram chip and button, poster placeholder off-screen', (tester) async {
    final content = withReels(base, [
      reel('C1a2B3c4D5e', 'approved', 'admonition', 'موعظة قصيرة', platform: 'instagram'),
      reel('hTtlD-u4_HI', 'approved', 'recitation', 'تلاوة'),
    ]);
    await pumpApp(tester, size: tallPhone, content: content);
    await pushScreen(tester, const ReelsScreen(playerBuilder: fakePlayer, showPosters: false));
    expect(find.byKey(const Key('player.C1a2B3c4D5e')), findsOneWidget);
    expect(find.text('نصائح ومواعظ'), findsOneWidget);
    expect(find.text('إنستجرام'), findsOneWidget);
    expect(find.text('افتح على إنستجرام'), findsOneWidget);
    await tester.fling(find.byKey(const Key('reels.feed')), const Offset(0, -600), 2000);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('player.hTtlD-u4_HI')), findsOneWidget);
    expect(find.text('افتح على يوتيوب'), findsOneWidget);
  });
}
