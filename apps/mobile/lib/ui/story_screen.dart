import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/quran.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'audio_widgets.dart';
import 'ayah_sheet.dart';
import 'l10n_ext.dart';
import 'stories_screen.dart';
import 'widgets.dart';
import 'adaptive.dart';

/// One Quranic story: its verses only (Mushaf text), recited in order with the
/// chosen reciter; tapping an ayah opens its Tafsir al-Muyassar.
class StoryScreen extends StatelessWidget {
  const StoryScreen({super.key, required this.story});
  final QuranStory story;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final q = s.content.quran;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(story.title(context.isArabic)),
        actions: [
          IconButton(
            key: const Key('story.reciter'),
            tooltip: l.storiesReciter,
            icon: const Icon(Icons.record_voice_over_outlined),
            onPressed: () => showRecitationSheet(context),
          ),
          const SleepTimerButton(),
        ],
      ),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: s.recitation,
          builder: (context, _) {
            final cur = s.recitation.current;
            final playingRef = cur != null && !cur.isBasmala && story.contains(cur.ref) ? cur.ref : null;
            return ListView(
              key: const Key('story.verses'),
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
              children: [
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${story.category == 'prophets' ? l.storiesCatProphets : l.storiesCatOthers} · '
                        '${l.storiesAyahs(context.num(story.ayahCount))}',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: DesignTokens.spaceSm),
                      FilledButton.icon(
                        key: const Key('story.play'),
                        icon: const Icon(Icons.play_arrow),
                        label: Text(l.storiesListen),
                        onPressed: () => s.recitation.playRanges(story.ranges),
                      ),
                      const SizedBox(height: DesignTokens.spaceSm),
                      Text(l.storiesTafsirHint, style: theme.textTheme.bodySmall),
                      Text(l.storiesSource, key: const Key('story.source'), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                for (final r in story.ranges) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spaceLg,
                      DesignTokens.spaceSm,
                      DesignTokens.spaceLg,
                      0,
                    ),
                    child: Text(
                      l.storiesFrom(surahName(context, q.surah(r.surah)), context.num(r.from), context.num(r.to)),
                      style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary),
                    ),
                  ),
                  for (var a = r.from; a <= r.to; a++)
                    _Verse(ref: AyahRef(r.surah, a), playing: playingRef == AyahRef(r.surah, a)),
                ],
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: const MiniPlayer(),
    );
  }
}

class _Verse extends StatelessWidget {
  const _Verse({required this.ref, required this.playing});
  final AyahRef ref;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tile = InkWell(
      key: Key('verse-${ref.surah}-${ref.ayah}'),
      onTap: () => showAyahSheet(context, ref, readAsList: false),
      child: Container(
        color: playing ? scheme.secondaryContainer : null,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
        child: QuranText(context.services.content.quran.text(ref), ayahNumber: ref.ayah),
      ),
    );
    if (!playing) return tile;
    // Keep the ayah being recited in view.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Scrollable.ensureVisible(context, alignment: 0.3, duration: const Duration(milliseconds: 300));
      }
    });
    return Semantics(selected: true, child: tile);
  }
}
