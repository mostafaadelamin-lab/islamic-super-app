import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'lock_player.dart';
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
    final tile = ListTile(
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
    // The player sits right under the episode playing (owner 2026-11-22).
    if (!on || !s.narration.isActive) return tile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [tile, const InlineNarrationPlayer()],
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
      listenable: Listenable.merge([n, InlinePlayers.shown]),
      builder: (context, _) {
        final e = n.episode;
        if (!n.isActive || e == null) return const SizedBox.shrink();
        // Its buttons are already under the item playing on this screen.
        if (InlinePlayers.on(ModalRoute.of(context))) return const SizedBox.shrink();
        final l = context.l10n;
        final error = n.state == RecitationState.error;
        final canOpen = PlayOrigin.canReturn(context, n.seriesId);
        return LockPlayerCard(
          key: const Key('narrationBar'),
          id: 'narration',
          docked: true,
          titleKey: const Key('narrationTitle'),
          title: error ? l.storiesEpisodeError : e.title(context.isArabic),
          subtitle: canOpen ? l.playerOpen : null,
          onTitleTap: canOpen ? () => PlayOrigin.open(context) : null,
          position: n.position,
          total: n.duration ?? (e.durationSec == null ? null : Duration(seconds: e.durationSec!)),
          playing: n.isPlaying && n.state != RecitationState.loading,
          loading: n.state == RecitationState.loading,
          live: n.isLive,
          showSkip: n.hasNext || n.hasPrevious,
          onPrevious: n.hasPrevious ? n.previous : null,
          onNext: n.hasNext ? n.next : null,
          sleepTimer: true,
          onToggle: () => n.isPlaying ? n.pause() : n.resume(),
          onSeek: (d) => n.seekBy(d - n.position),
          onClose: n.stop,
        );
      },
    );
  }
}

/// Screens where the narration's buttons are shown under the item playing
/// (owner 2026-11-15: in the recitation library and the radios, the player
/// belongs with the surah / station playing, not in a bar away from it).
/// The bottom [NarrationBar] steps aside there; it comes back when that row
/// scrolls far out of view or the user leaves the screen.
class InlinePlayers {
  InlinePlayers._();
  static final _routes = <Route<dynamic>, int>{};

  /// Changes whenever an inline player appears or goes away.
  static final shown = ValueNotifier<int>(0);

  static bool on(Route<dynamic>? r) => r != null && (_routes[r] ?? 0) > 0;

  static void _changed() {
    // Not while the tree is being built or torn down.
    WidgetsBinding.instance.addPostFrameCallback((_) => shown.value++);
    WidgetsBinding.instance.scheduleFrame();
  }

  static void add(Route<dynamic> r) {
    _routes[r] = (_routes[r] ?? 0) + 1;
    _changed();
  }

  static void remove(Route<dynamic> r) {
    final c = (_routes[r] ?? 1) - 1;
    if (c <= 0) {
      _routes.remove(r);
    } else {
      _routes[r] = c;
    }
    _changed();
  }
}

/// The narration's seek bar, previous / play-pause / next, sleep timer and stop,
/// shown right under the item playing (recitation library, radios, al-Sha'rawi).
/// Marks the current screen as showing its own player (so the bottom narration bar stays hidden),
/// for screens that draw the controls themselves, such as the radio row on the home screen.
class InlinePlayerMarker extends StatefulWidget {
  const InlinePlayerMarker({super.key});

  @override
  State<InlinePlayerMarker> createState() => _InlinePlayerMarkerState();
}

class _InlinePlayerMarkerState extends State<InlinePlayerMarker> {
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = ModalRoute.of(context);
    if (r == _route) return;
    if (_route != null) InlinePlayers.remove(_route!);
    _route = r;
    if (r != null) InlinePlayers.add(r);
  }

  @override
  void dispose() {
    if (_route != null) InlinePlayers.remove(_route!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class InlineNarrationPlayer extends StatefulWidget {
  const InlineNarrationPlayer({super.key});

  @override
  State<InlineNarrationPlayer> createState() => _InlineNarrationPlayerState();
}

class _InlineNarrationPlayerState extends State<InlineNarrationPlayer> {
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = ModalRoute.of(context);
    if (r == _route) return;
    if (_route != null) InlinePlayers.remove(_route!);
    _route = r;
    if (r != null) InlinePlayers.add(r);
  }

  @override
  void dispose() {
    if (_route != null) InlinePlayers.remove(_route!);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = context.services.narration;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: n,
      builder: (context, _) {
        final e = n.episode;
        final skip = n.hasNext || n.hasPrevious;
        return LockPlayerCard(
          key: const Key('inlinePlayer'),
          id: 'inline',
          title: e?.title(context.isArabic),
          position: n.position,
          total: n.duration,
          playing: n.isPlaying && n.state != RecitationState.loading,
          loading: n.state == RecitationState.loading,
          error: n.state == RecitationState.error ? l.storiesEpisodeError : null,
          live: n.isLive,
          showSkip: skip,
          onPrevious: n.hasPrevious ? n.previous : null,
          onNext: n.hasNext ? n.next : null,
          sleepTimer: true,
          onToggle: () => n.isPlaying ? n.pause() : n.resume(),
          onSeek: (d) => n.seekBy(d - n.position),
          onClose: n.stop,
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
