import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/nasheeds.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'library_screen.dart' show PlayTile;
import 'r_icon.dart';
import 'stories_screen.dart' show NarrationBar;

Future<List<Munshid>> loadNasheeds() async =>
    Munshid.parse(await rootBundle.loadString('assets/content/nasheeds.v2.json'));

String _norm(String s) =>
    s.replaceAll(RegExp('[ًٌٍَُِّْـ]'), '').replaceAll(RegExp('[أإآ]'), 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه');

/// Episode for the shared audio player (streams, or plays the offline copy).
Episode nasheedEpisode(Nasheed n) =>
    Episode(id: 'nasheed-${n.id}', titleAr: n.title, titleEn: n.title, url: n.url, status: ReviewStatus.approved);

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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.nasheedsTitle)),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
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
                  for (final (m, n) in hits)
                    PlayTile(
                      key: Key('nasheed-${n.id}'),
                      series: 'nasheeds',
                      remember: false,
                      offline: true,
                      title: n.title,
                      subtitle: m.name,
                      episode: nasheedEpisode(n),
                    ),
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
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
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
                final n = munshid.items[i];
                return PlayTile(
                  key: Key('nasheed-${n.id}'),
                  series: 'nasheeds',
                  remember: false,
                  offline: true,
                  title: n.title,
                  episode: episodes[i],
                  playlist: episodes,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
