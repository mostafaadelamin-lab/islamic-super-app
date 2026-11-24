import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/car_browser.dart' show nasheedEpisode;
import '../data/recitation.dart';
import '../domain/nasheeds.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'lock_player.dart';
import 'library_screen.dart' show PlayTile;
import 'r_icon.dart';
import 'stories_screen.dart' show NarrationBar;

export '../data/car_browser.dart' show nasheedEpisode;

Future<List<Munshid>> loadNasheeds() async =>
    Munshid.parse(await rootBundle.loadString('assets/content/nasheeds.v2.json'));

String _norm(String s) =>
    s.replaceAll(RegExp('[ًٌٍَُِّْـ]'), '').replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه');

/// A nasheed in a list: its play tile and, while it is the one playing, the player right under it
/// (owner 2026-11-14: not in a bar away from the list).
class NasheedTile extends StatelessWidget {
  const NasheedTile({super.key, required this.nasheed, required this.playlist, this.subtitle});
  final Nasheed nasheed;
  final List<Episode>? playlist;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final n = context.services.narration;
    final e = nasheedEpisode(nasheed);
    final on = n.seriesId == 'nasheeds' && n.episode?.id == e.id && n.isActive;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayTile(
          key: Key('nasheed-${nasheed.id}'),
          series: 'nasheeds',
          remember: false,
          inline: false,
          offline: true,
          title: nasheed.title,
          subtitle: subtitle,
          episode: e,
          playlist: playlist,
        ),
        if (on) const NasheedInlinePlayer(),
      ],
    );
  }
}

/// Seek bar, previous / play-pause / next, sleep timer and stop for the nasheed playing.
class NasheedInlinePlayer extends StatelessWidget {
  const NasheedInlinePlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final n = context.services.narration;
    final l = context.l10n;
    final e = n.episode;
    return LockPlayerCard(
      key: const Key('nasheedInlinePlayer'),
      id: 'nasheed',
      title: e?.title(context.isArabic),
      position: n.position,
      total: n.duration,
      playing: n.isPlaying && n.state != RecitationState.loading,
      loading: n.state == RecitationState.loading,
      error: n.state == RecitationState.error ? l.storiesEpisodeError : null,
      showSkip: true,
      onPrevious: n.hasPrevious ? n.previous : null,
      onNext: n.hasNext ? n.next : null,
      sleepTimer: true,
      onToggle: () => n.isPlaying ? n.pause() : n.resume(),
      onSeek: (d) => n.seekBy(d - n.position),
      onClose: n.stop,
    );
  }
}

/// The app's narration bar, except while the nasheed playing is listed on this screen
/// (its player is then under it).
class _BottomPlayers extends StatelessWidget {
  const _BottomPlayers({required this.listed});
  final bool Function(String episodeId) listed;

  @override
  Widget build(BuildContext context) {
    final n = context.services.narration;
    return ListenableBuilder(
      listenable: n,
      builder: (context, _) {
        final e = n.episode;
        final inline = n.seriesId == 'nasheeds' && e != null && listed(e.id);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [if (!inline) const NarrationBar(), const MiniPlayer()],
        );
      },
    );
  }
}

/// Every munshid with his nasheeds count; search finds nasheeds by title too.
class NasheedsScreen extends StatefulWidget {
  const NasheedsScreen({super.key, this.loader = loadNasheeds});
  final Future<List<Munshid>> Function() loader;

  @override
  State<NasheedsScreen> createState() => _NasheedsScreenState();
}

class _NasheedsScreenState extends State<NasheedsScreen> {
  late final Future<List<Munshid>> _future = widget.loader();
  String _query = '';
  Set<String> _listed = const {};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.nasheedsTitle)),
      bottomNavigationBar: _BottomPlayers(listed: (id) => _listed.contains(id)),
      body: ReadableWidth(
        child: FutureBuilder<List<Munshid>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text(l.nasheedsLoadError));
            final all = snap.data;
            if (all == null) return const Center(child: CircularProgressIndicator());
            final q = _norm(_query.trim());
            final singers = [
              for (final m in all)
                if (q.isEmpty || _norm(m.name).contains(q)) m,
            ];
            final hits = q.isEmpty
                ? const <(Munshid, Nasheed)>[]
                : [
                    for (final m in all)
                      for (final n in m.items)
                        if (_norm(n.title).contains(q)) (m, n),
                  ];
            _listed = {for (final (_, n) in hits) nasheedEpisode(n).id};
            return ListenableBuilder(
              listenable: context.services.narration,
              builder: (context, _) => ListView(
                key: const Key('nasheedsList'),
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spaceLg,
                      DesignTokens.spaceMd,
                      DesignTokens.spaceLg,
                      DesignTokens.spaceSm,
                    ),
                    child: Text(l.nasheedsNote, key: const Key('nasheedsNote'), style: theme.textTheme.bodyMedium),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                    child: TextField(
                      key: const Key('nasheedsSearch'),
                      decoration: InputDecoration(
                        prefixIcon: const RIcon(RIcons.search),
                        hintText: l.nasheedsSearch,
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  for (final m in singers)
                    Card(
                      key: Key('munshid.${m.id}'),
                      margin: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceLg,
                        vertical: DesignTokens.spaceXs,
                      ),
                      child: ListTile(
                        leading: const RIconBadge(RIcons.headphones),
                        title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(l.nasheedsCount(context.num(m.items.length))),
                        trailing: const RIcon(RIcons.chevronForward),
                        onTap: () => Navigator.of(
                          context,
                        ).push(MaterialPageRoute<void>(builder: (_) => MunshidScreen(munshid: m))),
                      ),
                    ),
                  for (final (m, n) in hits) NasheedTile(nasheed: n, playlist: null, subtitle: m.name),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One munshid's nasheeds: tap to play, download icon for offline.
class MunshidScreen extends StatelessWidget {
  const MunshidScreen({super.key, required this.munshid});
  final Munshid munshid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(munshid.name)),
      bottomNavigationBar: _BottomPlayers(listed: (id) => munshid.items.any((n) => nasheedEpisode(n).id == id)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: context.services.narration,
          builder: (context, _) {
            final episodes = [for (final n in munshid.items) nasheedEpisode(n)];
            return ListView.separated(
              key: const Key('munshidList'),
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
              itemCount: munshid.items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                return NasheedTile(nasheed: munshid.items[i], playlist: episodes);
              },
            );
          },
        ),
      ),
    );
  }
}
