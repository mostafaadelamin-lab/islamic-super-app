import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'library_screen.dart' show OfflineButton;
import 'widgets.dart';
import 'youtube_player.dart';
import 'adaptive.dart';
import 'r_icon.dart';
import 'play_origin.dart';

/// Prophets' stories: the narrated series (audio only, Sheikh Nabil al-Awadi's
/// "Stories of the Prophets"), every episode shown (owner: no review step).
class StoriesScreen extends StatelessWidget {
  const StoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final cat = s.content.stories;
    return Scaffold(
      appBar: AppBar(title: Text(l.storiesTitle)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('stories.list'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
              child: Text(l.storiesIntro, style: Theme.of(context).textTheme.bodyMedium),
            ),
            for (final se in cat.series) SeriesCard(series: se),
          ],
        ),
      ),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
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
        final eps = series.episodes;
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
              Text(l.storiesEpisodes(context.num(eps.length)), style: theme.textTheme.bodySmall),
              Text(l.storiesHowTo, key: const Key('stories.howTo'), style: theme.textTheme.bodySmall),
              const SizedBox(height: DesignTokens.spaceSm),
              for (final e in eps) _EpisodeTile(seriesId: series.id, episode: e),
            ],
          ],
        );
      },
    );
  }
}

/// The same series on video (Sheikh Nabil Al-Awadi's lessons channel, playlist
/// PLx0cDxpWtpY_65w9G0_SEA5TF3jhq_QaF; some videos cover two or more prophets).
const storyVideos = <String, String>{
  'adam': 'VQtyczrmgDU',
  'idris-nuh': 'U1b6uIe9LmM',
  'hud': 'ck6vaENGENg',
  'salih': 'ck6vaENGENg',
  'ibrahim': 'G5sO3nBi-gM',
  'lut': 'xKc6_kZYq9I',
  'shuayb': 'xKc6_kZYq9I',
  'yusuf': 'eLC6K7YyIIU',
  'ayyub': 'S-hwVKViokc',
  'yunus': 'S-hwVKViokc',
  'musa': 'wvtWBHguRh0',
  'khidr': 'lqzbfy26gC4',
  'yusha': '2lyl2XOMhqs',
  'dawud': '2lyl2XOMhqs',
  'sulayman-uzair': '2lyl2XOMhqs',
  'zakariya-yahya': '2lyl2XOMhqs',
  'maryam': '4cxCcYlJXbY',
  'isa': '4cxCcYlJXbY',
  'muhammad': 'd5vq2Ly9LBw',
};

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
      leading: RIcon(playing ? RIcons.pauseCircle : RIcons.playCircle, color: scheme.primary, size: 32),
      title: Text(episode.title(context.isArabic)),
      subtitle: Text(
        [if (m != null) l.storiesMinutes(context.num(m))].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (storyVideos[episode.id] != null)
            IconButton(
              key: Key('episodeVideo-${episode.id}'),
              tooltip: l.storiesWatchVideo,
              icon: RIcon(RIcons.reels, color: scheme.primary),
              onPressed: () {
                if (s.narration.isPlaying) s.narration.pause();
                showYouTubeSheet(
                  context,
                  videoId: storyVideos[episode.id]!,
                  title: episode.title(context.isArabic),
                  subtitle: l.storiesVideoBy,
                );
              },
            ),
          OfflineButton(series: seriesId, episode: episode),
        ],
      ),
      onTap: () {
        if (playing) {
          s.narration.pause();
        } else if (on && s.narration.state == RecitationState.paused) {
          s.narration.resume();
        } else {
          PlayOrigin.remember(context, seriesId);
          s.narration.playEpisode(seriesId, episode);
        }
      },
    );
  }
}

/// Player for the narrated episode: title, progress, ±30 s, play/pause, stop,
/// sleep timer.
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
                  _OpenOrigin(
                    canOpen: PlayOrigin.canReturn(context, n.seriesId),
                    child: Text(
                      error ? l.storiesEpisodeError : '${l.storiesNowPlaying}: ${e.title(context.isArabic)}',
                      key: const Key('narrationTitle'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: error ? scheme.error : null,
                      ),
                    ),
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
                        icon: RIcon(n.isPlaying ? RIcons.pause : RIcons.play),
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
                        icon: const RIcon(RIcons.stop),
                        onPressed: n.stop,
                      ),
                      const SleepTimerButton(),
                    ],
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

/// The player's title; when the item was started on another screen, tapping it (or the
/// arrow beside it) goes back to that screen.
class _OpenOrigin extends StatelessWidget {
  const _OpenOrigin({required this.canOpen, required this.child});
  final bool canOpen;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!canOpen) return child;
    final l = context.l10n;
    return Semantics(
      button: true,
      label: l.playerOpen,
      child: InkWell(
        key: const Key('narrationOpen'),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        onTap: () => PlayOrigin.open(context),
        child: Row(
          children: [
            Expanded(child: child),
            Tooltip(
              message: l.playerOpen,
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceXs),
                child: RIcon(RIcons.chevronForward, color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
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
                RIcon(RIcons.moon, color: Theme.of(context).colorScheme.primary),
                if (left != null) Text(' ${context.num(left)}', key: const Key('sleepLeft')),
              ],
            ),
          ),
        );
      },
    );
  }
}
