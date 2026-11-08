import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'story_screen.dart';
import 'widgets.dart';

/// Quranic stories: the narrated series (audio only, Sheikh Nabil al-Awadi's
/// "Stories of the Prophets"), then each story's verses from the Mushaf.
class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final cat = s.content.stories;
    return Scaffold(
      appBar: AppBar(title: Text(l.storiesTitle)),
      body: ListView(
        key: const Key('stories.list'),
        padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
            child: Text(l.storiesIntro, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (final se in cat.series) SeriesCard(series: se),
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceLg, 0),
            child: Text(l.storiesVersesTitle, style: Theme.of(context).textTheme.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
            child: Text(l.storiesVersesIntro, style: Theme.of(context).textTheme.bodySmall),
          ),
          for (final c in QuranStory.categories)
            if (cat.inCategory(c).isNotEmpty)
              SectionCard(
                key: Key('stories.cat.$c'),
                title: c == 'prophets' ? l.storiesCatProphets : l.storiesCatOthers,
                children: [for (final st in cat.inCategory(c)) _StoryTile(story: st)],
              ),
        ],
      ),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
    );
  }
}

class _StoryTile extends StatelessWidget {
  const _StoryTile({required this.story});
  final QuranStory story;

  @override
  Widget build(BuildContext context) {
    final q = context.services.content.quran;
    final surahs = <String>[];
    for (final r in story.ranges) {
      final n = surahName(context, q.surah(r.surah));
      if (!surahs.contains(n)) surahs.add(n);
    }
    return ListTile(
      key: Key('story-${story.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(story.title(context.isArabic)),
      subtitle: Text(
        '${surahs.join(context.isArabic ? '، ' : ', ')} · ${context.l10n.storiesAyahs(context.num(story.ayahCount))}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => StoryScreen(story: story))),
    );
  }
}

/// One narrated series: its episodes (approved ones; reviewers also see
/// pending ones), the reviewer-mode switch and the source/licence line.
class SeriesCard extends StatelessWidget {
  const SeriesCard({super.key, required this.series});
  final StorySeries series;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final ar = context.isArabic;
    return ListenableBuilder(
      listenable: Listenable.merge([s.settings, s.narration]),
      builder: (context, _) {
        final reviewer = s.settings.reelsReviewer;
        final eps = series.visible(reviewer: reviewer);
        final theme = Theme.of(context);
        return SectionCard(
          key: Key('series-${series.id}'),
          title: '${series.title(ar)} — ${series.narrator(ar)}',
          children: [
            if (eps.isEmpty)
              Text(
                l.storiesSeriesHidden(series.title(ar), series.narrator(ar)),
                key: const Key('series.hidden'),
                style: theme.textTheme.bodyMedium,
              )
            else ...[
              Text(
                '${l.storiesEpisodes(context.num(eps.length))} · ${l.storiesOnlineOnly}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              for (final e in eps) _EpisodeTile(seriesId: series.id, episode: e),
            ],
            const SizedBox(height: DesignTokens.spaceSm),
            Text(l.storiesSeriesSource(series.source, series.licence), style: theme.textTheme.bodySmall),
            SwitchListTile(
              key: const Key('stories.reviewer'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.storiesReviewerMode, style: theme.textTheme.bodyMedium),
              value: reviewer,
              onChanged: (v) => s.settings.setReelsReviewer(v),
            ),
          ],
        );
      },
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.seriesId, required this.episode});
  final String seriesId;
  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final on = s.narration.episode?.id == episode.id;
    final playing = on && s.narration.isPlaying;
    final m = episode.minutes;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      key: Key('episode-${episode.id}'),
      contentPadding: EdgeInsets.zero,
      selected: on,
      leading: Icon(playing ? Icons.pause_circle : Icons.play_circle, color: scheme.primary, size: 32),
      title: Text(episode.title(context.isArabic)),
      subtitle: Text(
        [
          if (m != null) l.storiesMinutes(context.num(m)),
          if (episode.isPending) '⚠ ${l.storiesEpisodePending}',
          if (episode.reviewer != null) l.storiesReviewedBy(episode.reviewer!),
        ].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        if (playing) {
          s.narration.pause();
        } else if (on && s.narration.state == RecitationState.paused) {
          s.narration.resume();
        } else {
          s.narration.playEpisode(seriesId, episode);
        }
      },
    );
  }
}

/// Player for the narrated episode: title, progress, ±30 s, play/pause, stop,
/// sleep timer, and a link to the story's verses.
class NarrationBar extends StatelessWidget {
  const NarrationBar({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final n = s.narration;
    return ListenableBuilder(
      listenable: n,
      builder: (context, _) {
        final e = n.episode;
        if (!n.isActive || e == null) return const SizedBox.shrink();
        final l = context.l10n;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final error = n.state == RecitationState.error;
        final total = n.duration ?? (e.durationSec == null ? null : Duration(seconds: e.durationSec!));
        final story = s.content.stories.byId(e.story);
        String fmt(Duration d) => context.numLtr('${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}');
        return Material(
          key: const Key('narrationBar'),
          color: scheme.surfaceContainer,
          child: SafeArea(
            top: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outline)),
              ),
              padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, DesignTokens.spaceSm, DesignTokens.spaceMd, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    error ? l.storiesEpisodeError : '${l.storiesNowPlaying}: ${e.title(context.isArabic)}',
                    key: const Key('narrationTitle'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: error ? scheme.error : null,
                    ),
                  ),
                  if (e.isPending)
                    Text(
                      l.storiesEpisodePending,
                      key: const Key('narrationPending'),
                      maxLines: 2,
                      style: theme.textTheme.bodySmall?.copyWith(color: scheme.error),
                    ),
                  if (total != null && total.inSeconds > 0)
                    Row(
                      children: [
                        Text(fmt(n.position), style: theme.textTheme.bodySmall),
                        Expanded(
                          child: Slider(
                            key: const Key('narrationSlider'),
                            value: n.position.inSeconds.clamp(0, total.inSeconds).toDouble(),
                            max: total.inSeconds.toDouble(),
                            onChanged: (v) => n.seekBy(Duration(seconds: v.round()) - n.position),
                          ),
                        ),
                        Text(fmt(total), style: theme.textTheme.bodySmall),
                      ],
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: l.storiesRewind,
                        icon: const Icon(Icons.replay_30),
                        onPressed: () => n.seekBy(const Duration(seconds: -30)),
                      ),
                      IconButton.filled(
                        key: const Key('narrationToggle'),
                        tooltip: n.isPlaying ? l.storiesPause : l.storiesPlay,
                        icon: Icon(n.isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () => n.isPlaying ? n.pause() : n.resume(),
                      ),
                      IconButton(
                        tooltip: l.storiesForward,
                        icon: const Icon(Icons.forward_30),
                        onPressed: () => n.seekBy(const Duration(seconds: 30)),
                      ),
                      IconButton(
                        key: const Key('narrationStop'),
                        tooltip: l.storiesStop,
                        icon: const Icon(Icons.stop),
                        onPressed: n.stop,
                      ),
                      const SleepTimerButton(),
                    ],
                  ),
                  if (story != null)
                    TextButton.icon(
                      key: const Key('narrationReadVerses'),
                      icon: const Icon(Icons.menu_book_outlined),
                      label: Text(l.storiesReadVerses),
                      onPressed: () => Navigator.of(
                        context,
                      ).push(MaterialPageRoute<void>(builder: (_) => StoryScreen(story: story))),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Bedtime icon: pick "stop after 15/30/45/60 minutes" or turn it off; shows the minutes left.
class SleepTimerButton extends StatelessWidget {
  const SleepTimerButton({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.services.sleepTimer;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: t,
      builder: (context, _) {
        final left = t.minutesLeft;
        return PopupMenuButton<int>(
          key: const Key('sleepTimer'),
          tooltip: left == null ? l.storiesSleep : l.storiesSleepLeft(context.num(left)),
          initialValue: 0,
          onSelected: (m) => t.set(m == 0 ? null : m),
          itemBuilder: (context) => [
            PopupMenuItem(key: const Key('sleep-0'), value: 0, child: Text(l.storiesSleepOff)),
            for (final m in SleepTimerController.choices)
              PopupMenuItem(key: Key('sleep-$m'), value: m, child: Text(l.storiesSleepMin(context.num(m)))),
          ],
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceSm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  left == null ? Icons.bedtime_outlined : Icons.bedtime,
                  color: Theme.of(context).colorScheme.primary,
                ),
                if (left != null) Text(' ${context.num(left)}', key: const Key('sleepLeft')),
              ],
            ),
          ),
        );
      },
    );
  }
}
