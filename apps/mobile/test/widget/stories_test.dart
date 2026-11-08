import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rattil/data/content.dart';
import 'package:rattil/domain/quran.dart';
import 'package:rattil/domain/stories.dart';
import 'package:rattil/ui/stories_screen.dart';
import 'package:rattil/ui/story_screen.dart';

import '../helpers.dart';

/// The shipped content with the first [n] episodes of the series approved.
AppContent withApproved(AppContent c, int n) {
  final se = c.stories.series.single;
  final eps = [
    for (var i = 0; i < se.episodes.length; i++)
      i < n
          ? Episode(
              id: se.episodes[i].id,
              titleAr: se.episodes[i].titleAr,
              titleEn: se.episodes[i].titleEn,
              url: se.episodes[i].url,
              durationSec: se.episodes[i].durationSec,
              story: se.episodes[i].story,
              status: ReviewStatus.approved,
              reviewer: 'الشيخ س',
            )
          : se.episodes[i],
  ];
  return AppContent(
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
    reels: c.reels,
    stories: StoryCatalog(c.stories.stories, [
      StorySeries(
        id: se.id,
        titleAr: se.titleAr,
        titleEn: se.titleEn,
        narratorAr: se.narratorAr,
        narratorEn: se.narratorEn,
        source: se.source,
        licence: se.licence,
        episodes: eps,
      ),
    ]),
  );
}

void main() {
  late AppContent base;
  setUpAll(() async => base = await loadContent());

  testWidgets('unreviewed episodes are hidden; reviewer mode lists all 19 with a warning', (tester) async {
    final app = await pumpApp(tester, size: tallPhone);
    await pushScreen(tester, const StoriesScreen());
    expect(find.byKey(const Key('series.hidden')), findsOneWidget);
    expect(find.textContaining('نبيل العوضي'), findsWidgets);
    expect(find.byKey(const Key('episode-adam')), findsNothing);
    await tester.tap(find.byKey(const Key('stories.reviewer')));
    await tester.pumpAndSettle();
    expect(app.prefs.getBool('reelsReviewer'), isTrue);
    expect(find.byKey(const Key('episode-adam')), findsOneWidget);
    expect(find.textContaining('لم تتم مراجعة هذه الحلقة'), findsWidgets);
  });

  testWidgets('plays an approved episode, resumes where it stopped, and stops the recitation', (tester) async {
    final narration = FakeNarrationBackend();
    final audio = FakeAudioBackend();
    final app = await pumpApp(
      tester,
      size: tallPhone,
      content: withApproved(base, 2),
      narration: narration,
      audio: audio,
      prefs: {'storyPos.awadi-prophets/adam': 600},
    );
    await app.services.recitation.playSurah(105);
    await pushScreen(tester, const StoriesScreen());
    expect(find.byKey(const Key('episode-idris-nuh')), findsOneWidget);
    expect(find.byKey(const Key('episode-hud')), findsNothing, reason: 'still pending');
    expect(find.text('راجعها: الشيخ س'), findsNothing); // shown inside the subtitle line
    await tester.tap(find.byKey(const Key('episode-adam')));
    await tester.pumpAndSettle();
    expect(narration.loaded.single, contains('archive.org/download/prophets_stories_Nabel-ElAwadde/'));
    expect(narration.calls, containsAllInOrder(['load', 'seek:600', 'play']));
    expect(app.services.recitation.isActive, isFalse, reason: 'one voice at a time');
    expect(find.byKey(const Key('narrationBar')), findsOneWidget);
    expect(find.byKey(const Key('narrationPending')), findsNothing);

    narration.emit(const Duration(minutes: 12));
    await tester.pump();
    await tester.tap(find.byKey(const Key('narrationToggle')));
    await tester.pumpAndSettle();
    expect(narration.calls.last, 'pause');
    expect(app.prefs.getInt('storyPos.awadi-prophets/adam'), 720);

    await tester.tap(find.byKey(const Key('narrationReadVerses')));
    await tester.pumpAndSettle();
    expect(find.byType(StoryScreen), findsOneWidget);
    expect(find.byKey(const Key('verse-2-30')), findsOneWidget);
  });

  testWidgets('a failed episode shows an error and can be retried', (tester) async {
    final narration = FakeNarrationBackend()..failNext = true;
    await pumpApp(tester, size: tallPhone, content: withApproved(base, 1), narration: narration);
    await pushScreen(tester, const StoriesScreen());
    await tester.tap(find.byKey(const Key('episode-adam')));
    await tester.pumpAndSettle();
    expect(find.textContaining('تعذّر تشغيل الحلقة'), findsOneWidget);
    await tester.tap(find.byKey(const Key('narrationToggle')));
    await tester.pumpAndSettle();
    expect(narration.loaded, hasLength(1));
  });

  testWidgets('sleep timer stops the narrator', (tester) async {
    final narration = FakeNarrationBackend();
    final app = await pumpApp(tester, size: tallPhone, content: withApproved(base, 1), narration: narration);
    await pushScreen(tester, const StoriesScreen());
    await tester.tap(find.byKey(const Key('episode-adam')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sleepTimer')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('sleep-15')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('sleepLeft')), findsOneWidget);
    expect(app.services.sleepTimer.isOn, isTrue);
    app.services.sleepTimer.set(null); // cancelling works…
    await tester.pump(const Duration(minutes: 20));
    expect(app.services.narration.isPlaying, isTrue);
    app.services.sleepTimer.set(15); // …and a new timer fires once
    await tester.pump(const Duration(minutes: 14));
    expect(app.services.narration.isPlaying, isTrue);
    await tester.pump(const Duration(minutes: 1));
    await tester.pumpAndSettle();
    expect(app.services.narration.isPlaying, isFalse);
    expect(narration.calls.last, 'pause');
  });

  testWidgets('a story shows only its verses and recites them in order, highlighting the current ayah', (tester) async {
    final audio = FakeAudioBackend();
    final app = await pumpApp(tester, size: tallPhone, audio: audio);
    final ayyub = app.services.content.stories.byId('ayyub')!;
    await pushScreen(tester, StoryScreen(story: ayyub));
    expect(find.byKey(const Key('story.source')), findsOneWidget);
    expect(find.byKey(const Key('verse-21-83')), findsOneWidget);
    await tester.tap(find.byKey(const Key('story.play')));
    await tester.pumpAndSettle();
    final rec = app.services.recitation;
    expect(rec.currentRef, const AyahRef(21, 83));
    expect(audio.loaded.single, endsWith('/021083.mp3'));
    audio.finish();
    await tester.pumpAndSettle();
    audio.finish();
    await tester.pumpAndSettle();
    expect(rec.currentRef, const AyahRef(38, 41));
    expect(audio.loaded.last, endsWith('/038041.mp3'));
  });

  testWidgets('verse stories are listed by category and reachable from More', (tester) async {
    await pumpApp(tester, size: tallPhone);
    await goToTab(tester, 4);
    await tester.tap(find.byKey(const Key('more.stories')));
    await tester.pumpAndSettle();
    expect(find.byType(StoriesScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('story-yusuf')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('story-yusuf')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('verse-12-4')), findsOneWidget);
  });
}
