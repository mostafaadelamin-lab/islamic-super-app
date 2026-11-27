import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/reels_feed.dart';
import '../domain/reels.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'reciters_screen.dart';
import 'reels_screen.dart';
import 'shell_back.dart';
import 'video_search_screen.dart';

/// The «فيديوهات» tab (owner 2026-11-27, mockup page 1): the Haramain live streams on top,
/// then group chips and a row per reciter group (pictures of the reciters and their newest
/// recitations). Any tap opens the full-screen player ([ReelsScreen]) on that tab or reciter.
class VideosHomeScreen extends StatefulWidget {
  const VideosHomeScreen({super.key, this.showThumbnails = true, this.playerBuilder, this.livePlayerBuilder});

  /// Off in tests (no network images).
  final bool showThumbnails;
  final ReelPlayerBuilder? playerBuilder;
  final LivePlayerBuilder? livePlayerBuilder;

  @override
  State<VideosHomeScreen> createState() => _VideosHomeScreenState();
}

/// Chips on the videos page.
const videosHomeTabs = [
  ReelsFeedController.tabAll,
  ReelsFeedController.tabHaramain,
  ReelsFeedController.tabGolden,
  ReelsFeedController.tabFamous,
  ReelsFeedController.tabSaved,
];

class _VideosHomeScreenState extends State<VideosHomeScreen> {
  String _tab = ReelsFeedController.tabAll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.services.reelsFeed.refresh();
    });
  }

  void _play({String tab = ReelsFeedController.tabAll, String? sourceId, String? startId}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReelsScreen(
          initialTab: tab,
          sourceId: sourceId,
          startId: startId,
          playerBuilder: widget.playerBuilder,
          livePlayerBuilder: widget.livePlayerBuilder,
          showPosters: widget.showThumbnails,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final feed = context.services.reelsFeed;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([context.services.settings, feed]),
      builder: (context, _) {
        final sections = switch (_tab) {
          ReelsFeedController.tabAll => const [
            ReelsFeedController.tabHaramain,
            ReelsFeedController.tabGolden,
            ReelsFeedController.tabFamous,
          ],
          _ => [_tab],
        };
        return Scaffold(
          appBar: AppBar(
            leading: shellBackButton(context),
            title: Text(l.reelsTitle),
            actions: [
              IconButton(
                key: const Key('videos.reciters'),
                tooltip: l.reelsReciters,
                icon: const RIcon(RIcons.reciter),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const RecitersScreen())),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, 0, DesignTokens.spaceMd, DesignTokens.spaceSm),
                child: Material(
                  color: scheme.surfaceContainerHighest,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    key: const Key('reels.searchBar'),
                    customBorder: const StadiumBorder(),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VideoSearchScreen())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 10),
                      child: Row(
                        children: [
                          RIcon(RIcons.search, color: scheme.onSurfaceVariant, size: 20),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Expanded(
                            child: Text(l.videosSearchHint, style: TextStyle(color: scheme.onSurfaceVariant)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: ReadableWidth(
            child: RefreshIndicator(
              onRefresh: () => feed.refresh(force: true, tab: _tab),
              child: ListView(
                key: const Key('videos.home'),
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                children: [
                  if (feed.live.isNotEmpty) ...[
                    _Header(title: l.reelsLiveTitle),
                    SizedBox(
                      height: 112 + MediaQuery.textScalerOf(context).scale(12) - 12,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
                        children: [
                          for (final c in feed.live)
                            _LiveCard(
                              live: c,
                              onTap: () => _play(tab: ReelsFeedController.tabLive, startId: c.id),
                            ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(
                    height: 36 + MediaQuery.textScalerOf(context).scale(16),
                    child: SingleChildScrollView(
                      key: const Key('videos.tabs'),
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
                      child: Row(
                        children: [
                          for (final t in videosHomeTabs)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: ChoiceChip(
                                key: Key('videos.tab.$t'),
                                showCheckmark: false,
                                selected: _tab == t,
                                label: Text(reelTabLabel(l, t)),
                                onSelected: (_) {
                                  setState(() => _tab = t);
                                  feed.refresh(tab: t);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (_tab == ReelsFeedController.tabSaved)
                    ..._saved(context, feed)
                  else
                    for (final g in sections) ..._section(context, feed, g),
                  if (feed.failed && feed.items.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(DesignTokens.spaceLg),
                      child: Column(
                        children: [
                          Text(l.reelsOffline, key: const Key('reels.empty'), textAlign: TextAlign.center),
                          const SizedBox(height: DesignTokens.spaceSm),
                          FilledButton.icon(
                            key: const Key('reels.retry'),
                            onPressed: () => feed.refresh(force: true, tab: _tab),
                            icon: const RIcon(RIcons.refresh),
                            label: Text(l.reelsRetry),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _section(BuildContext context, ReelsFeedController feed, String tab) {
    final l = context.l10n;
    final ar = context.isArabic;
    final reciters = feed.sourcesIn(tab);
    if (reciters.isEmpty) return const [];
    final reels = feed.itemsIn(tab);
    final single = _tab != ReelsFeedController.tabAll;
    final scale = MediaQuery.textScalerOf(context);
    return [
      _Header(
        key: Key('videos.section.$tab'),
        title: reelTabLabel(l, tab),
        action: reels.isEmpty ? null : l.reelsSeeAll,
        onAction: () => _play(tab: tab),
      ),
      SizedBox(
        height: 70 + scale.scale(11) * 2.6,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          children: [
            for (final s in reciters)
              _Avatar(
                key: Key('videos.reciter.${s.id}'),
                name: s.name(ar),
                onTap: () => _play(tab: tab, sourceId: s.id),
              ),
          ],
        ),
      ),
      if (reels.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
          child: Text(feed.loading ? l.reelsGroupLoading : l.reelsEmpty),
        )
      else if (single)
        _Grid(
          reels: reels,
          thumbs: widget.showThumbnails,
          onTap: (r) => _play(tab: tab, startId: r.id),
        )
      else
        SizedBox(
          height: 108 + scale.scale(12) * 2.7,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
            children: [
              for (final r in reels.take(12))
                _VideoCard(
                  reel: r,
                  thumbs: widget.showThumbnails,
                  onTap: () => _play(tab: tab, startId: r.id),
                ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _saved(BuildContext context, ReelsFeedController feed) {
    final l = context.l10n;
    final reels = feed.saved;
    if (reels.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Text(l.reelsSavedEmpty, key: const Key('videos.savedEmpty'), textAlign: TextAlign.center),
        ),
      ];
    }
    return [
      _Grid(
        reels: reels,
        thumbs: widget.showThumbnails,
        onTap: (r) => _play(tab: ReelsFeedController.tabSaved, startId: r.id),
      ),
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({super.key, required this.title, this.action, this.onAction});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceSm, 4),
    child: Row(
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
        if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
      ],
    ),
  );
}

/// The reciter's initial in a circle (YouTube profile pictures need the API, so none are shown).
class _Avatar extends StatelessWidget {
  const _Avatar({super.key, required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;

  static String initial(String name) {
    final words = name.replaceAll('الشيخ ', '').replaceAll('د. ', '').trim().split(' ');
    final w = words.isEmpty ? name : words.first;
    return w.isEmpty ? '؟' : w.characters.first;
  }

  @override
  Widget build(BuildContext context) {
    final short = name.replaceAll('الشيخ ', '').replaceAll('Sheikh ', '');
    return SizedBox(
      width: 74,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          children: [
            const SizedBox(height: 4),
            CircleAvatar(
              radius: 27,
              backgroundColor: AppTheme.brand('gold'),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.brand('goldSoft'),
                child: Text(
                  initial(name),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.brand('heroDeep')),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              short,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.reel, required this.thumbs});
  final Reel reel;
  final bool thumbs;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.brand('heroTop'), AppTheme.brand('heroDeep')],
          ),
        ),
      ),
      if (thumbs)
        Image.network(
          'https://i.ytimg.com/vi/${reel.ref}/mqdefault.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      const Center(child: RIcon(RIcons.playCircle, color: Colors.white, size: 32)),
    ],
  );
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.reel, required this.thumbs, required this.onTap});
  final Reel reel;
  final bool thumbs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ar = context.isArabic;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: SizedBox(
        width: 168,
        child: InkWell(
          key: Key('videos.card.${reel.id}'),
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  height: 94,
                  width: 168,
                  child: _Thumb(reel: reel, thumbs: thumbs),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                reel.title(ar),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({required this.reels, required this.thumbs, required this.onTap});
  final List<Reel> reels;
  final bool thumbs;
  final void Function(Reel) onTap;

  @override
  Widget build(BuildContext context) {
    final ar = context.isArabic;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      child: Wrap(
        spacing: DesignTokens.spaceSm,
        runSpacing: DesignTokens.spaceMd,
        children: [
          for (final r in reels)
            LayoutBuilder(
              builder: (context, _) {
                final w =
                    (MediaQuery.sizeOf(context).width.clamp(0, 720) - DesignTokens.spaceMd * 2 - DesignTokens.spaceSm) /
                    2;
                return SizedBox(
                  width: w,
                  child: InkWell(
                    key: Key('videos.card.${r.id}'),
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => onTap(r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: _Thumb(reel: r, thumbs: thumbs),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r.title(ar),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                        if (r.speaker(ar) != null)
                          Text(
                            r.speaker(ar)!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _LiveCard extends StatelessWidget {
  const _LiveCard({required this.live, required this.onTap});
  final LiveChannel live;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final place = live.place == 'makkah' ? l.reelsLiveMakkah : l.reelsLiveMadinah;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: Key('videos.live.${live.id}'),
          onTap: onTap,
          child: Ink(
            width: 190,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: live.place == 'makkah'
                    ? const [Color(0xFF2E4A3C), Color(0xFF122019)]
                    : const [Color(0xFF2B3550), Color(0xFF10141F)],
              ),
            ),
            child: Stack(
              children: [
                const PositionedDirectional(top: 8, start: 8, child: LiveBadge()),
                const Center(child: RIcon(RIcons.playCircle, color: Colors.white, size: 34)),
                PositionedDirectional(
                  bottom: 8,
                  start: 10,
                  end: 10,
                  child: Text(
                    place,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
