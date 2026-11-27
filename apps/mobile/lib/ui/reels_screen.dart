import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../app_services.dart';
import '../data/reels_feed.dart';
import '../domain/reels.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'adaptive.dart';
import 'r_icon.dart';
import 'video_search_screen.dart';
import 'shell_back.dart';

typedef ReelPlayerBuilder = Widget Function(BuildContext context, Reel reel);
typedef LivePlayerBuilder = Widget Function(BuildContext context, LiveChannel live);

/// The tabs across the top of the full-screen player (owner 2026-11-27):
/// «الكل · أئمة الحرمين · الجيل الذهبي المصري · بث مباشر من الحرمين».
const reelPlayerTabs = [
  ReelsFeedController.tabAll,
  ReelsFeedController.tabHaramain,
  ReelsFeedController.tabGolden,
  ReelsFeedController.tabLive,
];

/// The label of a videos tab.
String reelTabLabel(AppLocalizations l, String tab) => switch (tab) {
  ReelsFeedController.tabHaramain => l.reelsGroupHaramain,
  ReelsFeedController.tabGolden => l.reelsGroupGolden,
  ReelsFeedController.tabFamous => l.reelsGroupFamous,
  ReelsFeedController.tabLive => l.reelsLiveTitle,
  ReelsFeedController.tabSaved => l.reelsSaved,
  _ => l.reelsGroupAll,
};

/// The label of a reciter group (the tag on a recitation and the reciters list).
String reelGroupLabel(AppLocalizations l, String? group) => switch (group) {
  'golden' => l.reelsGroupGolden,
  'makkah' => l.reelsGroupMakkah,
  'madinah' => l.reelsGroupMadinah,
  'famous' => l.reelsGroupFamous,
  _ => l.reelsGroupAll,
};

/// Vertical, swipeable full-screen recitations (one video per page). Only the
/// recitation in view gets a live player; the others show YouTube's poster image,
/// so at most one video loads or plays at a time. Swiping stays inside the tab
/// (or the reciter) it was opened from.
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({
    super.key,
    this.playerBuilder,
    this.livePlayerBuilder,
    this.showPosters = true,
    this.initialTab = ReelsFeedController.tabAll,
    this.sourceId,
    this.startId,
  });

  /// Replaced in tests (a WebView cannot run in widget tests).
  final ReelPlayerBuilder? playerBuilder;
  final LivePlayerBuilder? livePlayerBuilder;
  final bool showPosters;

  /// The tab to open on (see [reelPlayerTabs]; famous/saved are also accepted from the videos page).
  final String initialTab;

  /// Only this reciter's recitations (opened from a reciter's picture).
  final String? sourceId;

  /// The recitation (or live stream) to start on.
  final String? startId;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  late PageController _pages;
  int _current = 0;
  late String _tab = widget.initialTab;
  late String? _sourceId = widget.sourceId;

  /// When the reel on screen started showing (for the viewer's interest).
  DateTime _shownAt = DateTime.now();
  Reel? _shown;

  void _noteWatch(Reel? next) {
    final prev = _shown;
    final secs = DateTime.now().difference(_shownAt).inSeconds;
    if (prev != null && prev.isAuto) context.services.reelsFeed.recordWatch(prev.sourceId, secs.clamp(0, 120));
    _shown = next;
    _shownAt = DateTime.now();
  }

  @override
  void initState() {
    super.initState();
    _pages = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final start = widget.startId;
      if (start != null) {
        final ids = _tab == ReelsFeedController.tabLive
            ? [for (final c in context.services.reelsFeed.live) c.id]
            : [for (final r in _reels()) r.id];
        final i = ids.indexOf(start);
        if (i > 0 && _pages.hasClients) {
          _pages.jumpToPage(i);
          setState(() => _current = i);
        }
      }
      context.services.reelsFeed.refresh(tab: _tab);
    });
  }

  /// Trusted-channel reels first (mixed across channels), then the curated list.
  static List<Reel> _feed(List<Reel> auto, List<Reel> curated) {
    final seen = <String>{};
    return [
      for (final r in [...auto, ...curated])
        if (seen.add(r.id)) r,
    ];
  }

  List<Reel> _reels() {
    final feed = context.services.reelsFeed;
    if (_sourceId != null) return feed.itemsOf(_sourceId!);
    if (_tab == ReelsFeedController.tabAll) {
      return _feed(feed.items, context.services.content.reels.visible(reviewer: false));
    }
    return feed.itemsIn(_tab);
  }

  void _selectTab(String tab) {
    if (tab == _tab && _sourceId == null) return;
    setState(() {
      _tab = tab;
      _sourceId = null;
      _current = 0;
      _shown = null;
    });
    if (_pages.hasClients) _pages.jumpToPage(0);
    context.services.reelsFeed.refresh(tab: tab);
  }

  Future<void> _hide(Reel r) async {
    final feed = context.services.reelsFeed;
    final src = feed.source(r.sourceId);
    if (src == null) return;
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final name = src.name(context.services.settings.isArabic);
    await feed.hide(src.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l.reelsHidden(name)),
          action: SnackBarAction(label: l.reelsUndo, onPressed: () => feed.unhide(src.id)),
        ),
      );
  }

  Future<void> _save(Reel r) async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final now = await context.services.reelsFeed.toggleSave(r);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(duration: const Duration(seconds: 2), content: Text(now ? l.reelsUnsave : l.reelsSave)));
  }

  Future<void> _share(Reel r) async {
    final ar = context.services.settings.isArabic;
    final who = r.speaker(ar);
    await context.services.sharer.shareText([r.title(ar), ?who, r.url].join('\n'));
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _open(Reel r) async {
    await launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication);
  }

  Widget _tabs(BuildContext context) {
    final l = context.l10n;
    return SizedBox(
      height: 36 + MediaQuery.textScalerOf(context).scale(16),
      child: SingleChildScrollView(
        key: const Key('reels.tabs'),
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
        child: Row(
          children: [
            for (final t in reelPlayerTabs)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: ChoiceChip(
                  key: Key('reels.tab.$t'),
                  showCheckmark: false,
                  selected: _sourceId == null && _tab == t,
                  onSelected: (_) => _selectTab(t),
                  avatar: t == ReelsFeedController.tabLive
                      ? const Icon(Icons.circle, size: 10, color: Color(0xFFFF5A5A))
                      : null,
                  label: Text(reelTabLabel(l, t)),
                  labelStyle: TextStyle(
                    color: _sourceId == null && _tab == t ? const Color(0xFF2B1D12) : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: const Color(0xFFE0B25A),
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.services.settings;
    final feed = context.services.reelsFeed;
    return ListenableBuilder(
      listenable: Listenable.merge([settings, feed]),
      builder: (context, _) {
        final live = _tab == ReelsFeedController.tabLive && _sourceId == null;
        final reels = live ? const <Reel>[] : _reels();
        final count = live ? feed.live.length : reels.length;
        if (_current >= count && count > 0) _current = count - 1;
        final reciter = _sourceId == null ? null : feed.source(_sourceId);
        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            leading: shellBackButton(context),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: Text(reciter?.name(settings.isArabic) ?? l.reelsTitle, style: const TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                key: const Key('reels.search'),
                tooltip: l.videosSearch,
                icon: const RIcon(RIcons.search),
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const VideoSearchScreen())),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(36 + MediaQuery.textScalerOf(context).scale(16)),
              child: _tabs(context),
            ),
          ),
          body: ReadableWidth(
            child: live
                ? (feed.live.isEmpty
                      ? _Empty(text: l.reelsEmpty, note: l.reelsNote)
                      : PageView.builder(
                          key: const Key('reels.live'),
                          controller: _pages,
                          scrollDirection: Axis.vertical,
                          itemCount: feed.live.length,
                          onPageChanged: (i) => setState(() => _current = i),
                          itemBuilder: (context, i) => _LivePage(
                            live: feed.live[i],
                            active: i == _current,
                            player:
                                widget.livePlayerBuilder ?? (context, c) => LivePlayer(key: ValueKey(c.id), live: c),
                          ),
                        ))
                : reels.isEmpty
                ? _Empty(
                    text: _tab == ReelsFeedController.tabSaved
                        ? l.reelsSavedEmpty
                        : feed.loading
                        ? l.reelsLoading
                        : feed.failed
                        ? l.reelsOffline
                        : l.reelsEmpty,
                    note: l.reelsNote,
                    loading: feed.loading,
                    actions: [
                      if (!feed.loading && feed.failed)
                        FilledButton.icon(
                          key: const Key('reels.retry'),
                          onPressed: () => feed.refresh(force: true, tab: _tab),
                          icon: const RIcon(RIcons.refresh),
                          label: Text(l.reelsRetry),
                        ),
                      if (!feed.loading && feed.hidden.isNotEmpty)
                        TextButton(
                          key: const Key('reels.showHidden'),
                          style: TextButton.styleFrom(foregroundColor: Colors.white),
                          onPressed: () async {
                            for (final id in feed.hidden) {
                              await feed.unhide(id);
                            }
                          },
                          child: Text(l.reelsShowHidden),
                        ),
                    ],
                  )
                : PageView.builder(
                    key: const Key('reels.feed'),
                    controller: _pages,
                    scrollDirection: Axis.vertical,
                    itemCount: reels.length,
                    onPageChanged: (i) {
                      _noteWatch(reels[i]);
                      setState(() => _current = i);
                    },
                    itemBuilder: (context, i) => _ReelPage(
                      reel: reels[i],
                      index: i,
                      total: reels.length,
                      active: i == _current,
                      player: widget.playerBuilder ?? (context, r) => ReelPlayer(key: ValueKey(r.id), reel: r),
                      showPoster: widget.showPosters,
                      saved: feed.isSaved(reels[i]),
                      onOpen: () => _open(reels[i]),
                      onSave: () => _save(reels[i]),
                      onShare: () => _share(reels[i]),
                      onHide: reels[i].isAuto && feed.source(reels[i].sourceId) != null ? () => _hide(reels[i]) : null,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// One Haramain live stream, full screen.
class _LivePage extends StatelessWidget {
  const _LivePage({required this.live, required this.active, required this.player});
  final LiveChannel live;
  final bool active;
  final LivePlayerBuilder player;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = context.services.settings.isArabic;
    return Stack(
      key: Key('live.${live.id}'),
      fit: StackFit.expand,
      children: [
        if (active)
          player(context, live)
        else
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppTheme.brand('heroTop'), AppTheme.brand('heroDeep')],
              ),
            ),
            child: const Center(child: RIcon(RIcons.playCircle, color: Colors.white70, size: 64)),
          ),
        Positioned(
          left: DesignTokens.spaceMd,
          right: DesignTokens.spaceMd,
          bottom: DesignTokens.spaceLg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const _LiveBadge(),
              const SizedBox(height: DesignTokens.spaceXs),
              Text(
                live.name(ar),
                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
              ),
              TextButton.icon(
                key: Key('live.open.${live.id}'),
                style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
                onPressed: () => launchUrl(live.watchUri, mode: LaunchMode.externalApplication),
                icon: const RIcon(RIcons.external, size: 18),
                label: Text(l.reelsOpenYoutube),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The red «● مباشر» badge.
class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(color: const Color(0xFFC62828), borderRadius: BorderRadius.circular(8)),
    child: Text(
      '● ${context.l10n.reelsLiveBadge}',
      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
    ),
  );
}

/// The same red badge for other screens (the videos page's live cards).
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) => const _LiveBadge();
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text, required this.note, this.loading = false, this.actions = const []});
  final String text;
  final String note;
  final bool loading;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (loading)
            const CircularProgressIndicator(key: Key('reels.loading'), color: Colors.white70)
          else
            const RIcon(RIcons.reels, color: Colors.white70, size: 56),
          const SizedBox(height: DesignTokens.spaceMd),
          Text(
            text,
            key: const Key('reels.empty'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Text(
            note,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
          if (actions.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spaceMd),
            Wrap(spacing: DesignTokens.spaceSm, alignment: WrapAlignment.center, children: actions),
          ],
        ],
      ),
    ),
  );
}

class _ReelPage extends StatelessWidget {
  const _ReelPage({
    required this.reel,
    required this.index,
    required this.total,
    required this.active,
    required this.player,
    required this.showPoster,
    required this.onOpen,
    this.saved = false,
    this.onSave,
    this.onShare,
    this.onHide,
  });

  final Reel reel;
  final int index;
  final int total;
  final bool active;
  final ReelPlayerBuilder player;
  final bool showPoster;
  final VoidCallback onOpen;
  final bool saved;
  final VoidCallback? onSave;
  final VoidCallback? onShare;

  /// Hides the reel's channel (automatic reels only).
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = context.services.settings.isArabic;
    final speaker = reel.speaker(ar);
    final top = MediaQuery.paddingOf(context).top + kToolbarHeight;
    return Semantics(
      container: true,
      label: l.reelsPosition(context.num(index + 1), context.num(total)),
      child: Stack(
        key: Key('reel.${reel.id}'),
        fit: StackFit.expand,
        children: [
          if (active)
            player(context, reel)
          else if (showPoster && reel.posterUrl != null)
            Image.network(
              reel.posterUrl!,
              fit: BoxFit.cover,
              opacity: const AlwaysStoppedAnimation(0.6),
              errorBuilder: (_, _, _) => const ColoredBox(color: Colors.black),
            )
          else
            DecoratedBox(
              key: Key('reel.poster.${reel.id}'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.brand('heroTop'), AppTheme.brand('heroDeep')],
                ),
              ),
              child: const Center(child: RIcon(RIcons.playCircle, color: Colors.white70, size: 64)),
            ),
          if (reel.isPending)
            Positioned(
              top: top + DesignTokens.spaceSm,
              left: DesignTokens.spaceSm,
              right: DesignTokens.spaceSm,
              child: Container(
                key: Key('reel.pending.${reel.id}'),
                padding: const EdgeInsets.all(DesignTokens.spaceSm),
                decoration: BoxDecoration(color: const Color(0xFFB3261E), borderRadius: BorderRadius.circular(8)),
                child: Text(l.reelsPending, style: const TextStyle(color: Colors.white)),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD9000000)],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spaceMd,
                  DesignTokens.spaceXl,
                  DesignTokens.spaceMd,
                  DesignTokens.spaceSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (reel.group != null)
                      Container(
                        key: Key('reel.group.${reel.id}'),
                        margin: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0B25A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          reel.group == 'makkah' || reel.group == 'madinah'
                              ? l.reelsGroupHaramain
                              : reelGroupLabel(l, reel.group),
                          style: const TextStyle(color: Color(0xFF2B1D12), fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    Text(
                      reel.title(ar),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    if (speaker != null) Text(speaker, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Wrap(
                      spacing: DesignTokens.spaceMd,
                      children: [
                        if (onSave != null)
                          TextButton.icon(
                            key: Key('reel.save.${reel.id}'),
                            style: TextButton.styleFrom(
                              foregroundColor: saved ? const Color(0xFFE0B25A) : Colors.white,
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: onSave,
                            icon: RIcon(saved ? RIcons.bookmarks : RIcons.bookmark, size: 18),
                            label: Text(saved ? l.reelsUnsave : l.reelsSave),
                          ),
                        if (onShare != null)
                          TextButton.icon(
                            key: Key('reel.share.${reel.id}'),
                            style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
                            onPressed: onShare,
                            icon: const RIcon(RIcons.share, size: 18),
                            label: Text(l.reelsShare),
                          ),
                        TextButton.icon(
                          key: Key('reel.open.${reel.id}'),
                          style: TextButton.styleFrom(foregroundColor: Colors.white, padding: EdgeInsets.zero),
                          onPressed: onOpen,
                          icon: const RIcon(RIcons.external, size: 18),
                          label: Text(reel.isInstagram ? l.reelsOpenInstagram : l.reelsOpenYoutube),
                        ),
                        if (onHide != null)
                          TextButton.icon(
                            key: Key('reel.hide.${reel.id}'),
                            style: TextButton.styleFrom(foregroundColor: Colors.white70, padding: EdgeInsets.zero),
                            onPressed: onHide,
                            icon: const RIcon(RIcons.eyeOff, size: 18),
                            label: Text(l.reelsHide),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _igEmbedPath = RegExp(r'^/(reel|p|tv)/[A-Za-z0-9_-]{5,40}/embed(/captioned)?/?$');

/// Only the official embed pages may load inside the feed; anything else
/// (watch pages, profiles, other sites) is handed to the app or browser.
bool reelNavigationAllowedInFeed(Uri u) =>
    u.scheme == 'about' ||
    (u.scheme == 'https' && u.host == 'www.youtube-nocookie.com' && (u.path == '/' || u.path.startsWith('/embed/'))) ||
    (u.scheme == 'https' && u.host == 'www.instagram.com' && _igEmbedPath.hasMatch(u.path));

/// The platform's official embed in a WebView. YouTube autoplays with sound and
/// inline (its own controls unmute); Instagram's embed shows its play button.
/// Navigation away from the embed (logos, "view on Instagram", related links)
/// opens in the YouTube/Instagram app or browser instead of inside the feed.
class ReelPlayer extends StatefulWidget {
  const ReelPlayer({super.key, required this.reel});
  final Reel reel;

  @override
  State<ReelPlayer> createState() => _ReelPlayerState();
}

class _ReelPlayerState extends State<ReelPlayer> {
  late final WebViewController _c;

  @override
  void initState() {
    super.initState();
    final PlatformWebViewControllerCreationParams params = defaultTargetPlatform == TargetPlatform.iOS
        ? WebKitWebViewControllerCreationParams(
            allowsInlineMediaPlayback: true,
            mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
          )
        : const PlatformWebViewControllerCreationParams();
    _c = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (req) {
            final u = Uri.tryParse(req.url);
            if (u != null && reelNavigationAllowedInFeed(u)) return NavigationDecision.navigate;
            if (u != null && u.scheme == 'https') launchUrl(u, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      );
    final p = _c.platform;
    if (p is AndroidWebViewController) p.setMediaPlaybackRequiresUserGesture(false);
    if (widget.reel.isInstagram) {
      _c.loadRequest(widget.reel.instagramEmbedUri);
    } else {
      _c.loadHtmlString(widget.reel.embedHtml(), baseUrl: ReelCatalog.embedOrigin);
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _c);
}

/// A Haramain live stream in a WebView (YouTube's privacy-enhanced live embed).
class LivePlayer extends StatefulWidget {
  const LivePlayer({super.key, required this.live});
  final LiveChannel live;

  @override
  State<LivePlayer> createState() => _LivePlayerState();
}

class _LivePlayerState extends State<LivePlayer> {
  late final WebViewController _c;

  @override
  void initState() {
    super.initState();
    _c = _embedController()..loadHtmlString(widget.live.embedHtml(), baseUrl: ReelCatalog.embedOrigin);
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(controller: _c);
}

/// A WebView controller that plays inline without a tap and sends any link
/// away from the embed to the YouTube/Instagram app or browser.
WebViewController _embedController() {
  final PlatformWebViewControllerCreationParams params = defaultTargetPlatform == TargetPlatform.iOS
      ? WebKitWebViewControllerCreationParams(
          allowsInlineMediaPlayback: true,
          mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
        )
      : const PlatformWebViewControllerCreationParams();
  final c = WebViewController.fromPlatformCreationParams(params)
    ..setJavaScriptMode(JavaScriptMode.unrestricted)
    ..setBackgroundColor(Colors.black)
    ..setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (req) {
          final u = Uri.tryParse(req.url);
          if (u != null && reelNavigationAllowedInFeed(u)) return NavigationDecision.navigate;
          if (u != null && u.scheme == 'https') launchUrl(u, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
      ),
    );
  final p = c.platform;
  if (p is AndroidWebViewController) p.setMediaPlaybackRequiresUserGesture(false);
  return c;
}

/// Find a channel on YouTube and add it to the feed; also lists the channels the app suggests.
class ChannelSearchSheet extends StatefulWidget {
  const ChannelSearchSheet({super.key});

  @override
  State<ChannelSearchSheet> createState() => _ChannelSearchSheetState();
}

class _ChannelSearchSheetState extends State<ChannelSearchSheet> {
  final _q = TextEditingController();
  Future<List<({String id, String title, String? subs})>>? _results;

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final feed = context.services.reelsFeed;
    final ar = context.isArabic;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: ListenableBuilder(
          listenable: feed,
          builder: (context, _) {
            final have = {for (final s in feed.sources) s.channelId};
            final mine = feed.userSources;
            final suggestions = [
              for (final s in feed.suggestionPool)
                if (!have.contains(s.channelId)) s,
            ];
            Widget addButton(String id, String name) => have.contains(id)
                ? const RIcon(RIcons.checkCircle)
                : IconButton(
                    key: Key('reels.add.$id'),
                    tooltip: l.reelsAddChannel,
                    icon: const RIcon(RIcons.plus),
                    onPressed: () => feed.addUserSource(id, name),
                  );
            return ListView(
              padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceXl),
              children: [
                TextField(
                  key: const Key('reels.searchField'),
                  controller: _q,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: l.reelsSearchHint,
                    prefixIcon: const RIcon(RIcons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (v) => setState(() => _results = feed.searchChannels(v)),
                ),
                if (_results != null)
                  FutureBuilder(
                    future: _results,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(DesignTokens.spaceLg),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final list = snap.data ?? const [];
                      if (list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(DesignTokens.spaceLg),
                          child: Text(l.reelsSearchNone),
                        );
                      }
                      return Column(
                        children: [
                          for (final r in list)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(r.title),
                              subtitle: r.subs == null ? null : Text(r.subs!),
                              trailing: addButton(r.id, r.title),
                            ),
                        ],
                      );
                    },
                  ),
                if (mine.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spaceLg),
                  Text(l.reelsMyChannels, style: Theme.of(context).textTheme.titleMedium),
                  for (final s in mine)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.name(ar)),
                      trailing: IconButton(
                        tooltip: l.reelsRemoveChannel,
                        icon: const RIcon(RIcons.trash),
                        onPressed: () => feed.removeUserSource(s.id),
                      ),
                    ),
                ],
                if (suggestions.isNotEmpty) ...[
                  const SizedBox(height: DesignTokens.spaceLg),
                  Text(l.reelsSuggested, style: Theme.of(context).textTheme.titleMedium),
                  Text(l.reelsSuggestedHint, style: Theme.of(context).textTheme.bodySmall),
                  for (final s in suggestions)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(s.name(ar)),
                      trailing: addButton(s.channelId!, s.name(ar)),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
