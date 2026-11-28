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

/// The «فيديوهات» tab (owner 2026-11-28, layout option 2): a row of circles (the Haramain live
/// streams, then the reciters), the group chips, then a three-column grid of tall video tiles.
/// Any tap opens the full-screen player ([ReelsScreen]) on that tab, reciter or video.
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
              preferredSize: const Size.fromHeight(60),
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
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
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
              child: CustomScrollView(
                key: const Key('videos.home'),
                slivers: [
                  SliverToBoxAdapter(child: _stories(context, feed)),
                  SliverToBoxAdapter(child: _chips(context, feed)),
                  ..._grid(context, feed),
                  if (feed.failed && feed.items.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
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
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: DesignTokens.spaceXl)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Owner 2026-11-28 (layout option 2): circles on top, first the two Haramain live streams (red ring),
  /// then the reciters of the chosen tab, each with a frame of their newest recitation.
  Widget _stories(BuildContext context, ReelsFeedController feed) {
    final l = context.l10n;
    final ar = context.isArabic;
    final tab = _tab == ReelsFeedController.tabSaved ? ReelsFeedController.tabAll : _tab;
    final reciters = feed.sourcesIn(tab);
    final scale = MediaQuery.textScalerOf(context);
    return SizedBox(
      height: 84 + scale.scale(11) * 2.8,
      child: ListView(
        key: const Key('videos.stories'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: 6),
        children: [
          for (final c in feed.live)
            _Circle(
              key: Key('videos.live.${c.id}'),
              label: c.place == 'makkah' ? l.videosLiveMakkahShort : l.videosLiveMadinahShort,
              sub: l.reelsLiveBadge,
              live: true,
              colors: c.place == 'makkah'
                  ? const [Color(0xFF2E4A3C), Color(0xFF122019)]
                  : const [Color(0xFF2B3550), Color(0xFF10141F)],
              onTap: () => _play(tab: ReelsFeedController.tabLive, startId: c.id),
            ),
          for (final s in reciters)
            _Circle(
              key: Key('videos.reciter.${s.id}'),
              label: shortReciterName(s.name(ar)),
              image: widget.showThumbnails ? _newestThumb(feed, s.id) : null,
              onTap: () => _play(tab: tab, sourceId: s.id),
            ),
        ],
      ),
    );
  }

  static String? _newestThumb(ReelsFeedController feed, String sourceId) {
    final items = feed.itemsOf(sourceId);
    return items.isEmpty ? null : 'https://i.ytimg.com/vi/${items.first.ref}/default.jpg';
  }

  Widget _chips(BuildContext context, ReelsFeedController feed) {
    final l = context.l10n;
    return SizedBox(
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
    );
  }

  /// Three columns of tall tiles (the video's frame and the reciter's name), newest first, mixed across
  /// reciters; a tap opens the full-screen player on that video in the same tab.
  List<Widget> _grid(BuildContext context, ReelsFeedController feed) {
    final l = context.l10n;
    final saved = _tab == ReelsFeedController.tabSaved;
    final reels = saved ? feed.saved : feed.itemsIn(_tab);
    if (reels.isEmpty) {
      final text = saved ? l.reelsSavedEmpty : (feed.loading ? l.reelsGroupLoading : l.reelsEmpty);
      if (!saved && feed.failed) return const [];
      return [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: Text(text, key: Key(saved ? 'videos.savedEmpty' : 'videos.gridEmpty'), textAlign: TextAlign.center),
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        key: Key('videos.section.$_tab'),
        padding: const EdgeInsets.fromLTRB(3, DesignTokens.spaceSm, 3, 0),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            childAspectRatio: 9 / 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, i) => _Tile(
              reel: reels[i],
              thumbs: widget.showThumbnails,
              onTap: () => _play(tab: _tab, startId: reels[i].id),
            ),
            childCount: reels.length,
          ),
        ),
      ),
    ];
  }
}

/// "الشيخ عبد الرحمن السديس" -> "عبد الرحمن السديس" (titles dropped so the circle label fits).
String shortReciterName(String name) => name.replaceFirst(RegExp(r'^(الشيخ|القارئ|د\.|Sheikh|Dr\.)\s+'), '').trim();

class _Thumb extends StatelessWidget {
  const _Thumb({required this.reel, required this.thumbs, this.quality = 'mqdefault'});
  final Reel reel;
  final bool thumbs;
  final String quality;

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
          'https://i.ytimg.com/vi/${reel.ref}/$quality.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
    ],
  );
}

/// One circle of the top row: a Haramain live stream (red ring, "مباشر" under it) or a reciter
/// (gold ring, a frame of their newest recitation, or their initial while it loads).
class _Circle extends StatelessWidget {
  const _Circle({
    super.key,
    required this.label,
    required this.onTap,
    this.sub,
    this.image,
    this.live = false,
    this.colors,
  });

  final String label;
  final String? sub;
  final String? image;
  final bool live;
  final List<Color>? colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ring = live ? const Color(0xFFE53935) : AppTheme.brand('gold');
    final initial = label.isEmpty ? '؟' : label.characters.first;
    return SizedBox(
      width: 78,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 66,
              height: 66,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: ring, width: 2.5),
              ),
              child: ClipOval(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                          colors: colors ?? [AppTheme.brand('goldSoft'), AppTheme.brand('gold')],
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        live ? label : initial,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: live ? 13 : 20,
                          fontWeight: FontWeight.bold,
                          color: live ? Colors.white : AppTheme.brand('heroDeep'),
                        ),
                      ),
                    ),
                    if (image != null)
                      Image.network(image!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox.shrink()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            if (live)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(color: Color(0xFFD32F2F), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    sub ?? '',
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                ],
              )
            else
              Text(
                label,
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

/// A tall tile of the grid: the video's frame (cropped to 9:16) and the reciter's short name.
class _Tile extends StatelessWidget {
  const _Tile({required this.reel, required this.thumbs, required this.onTap});
  final Reel reel;
  final bool thumbs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ar = context.isArabic;
    final who = reel.speaker(ar);
    return Semantics(
      button: true,
      label: [reel.title(ar), ?who].join('، '),
      excludeSemantics: true,
      child: InkWell(
        key: Key('videos.card.${reel.id}'),
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Thumb(reel: reel, thumbs: thumbs, quality: 'hqdefault'),
            const PositionedDirectional(top: 6, end: 6, child: RIcon(RIcons.playCircle, color: Colors.white, size: 20)),
            if (who != null)
              PositionedDirectional(
                start: 0,
                end: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0xCC000000)],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(6, 18, 6, 6),
                    child: Text(
                      shortReciterName(who),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
