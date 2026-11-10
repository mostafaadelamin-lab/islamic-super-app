import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../app_services.dart';
import '../domain/reels.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'adaptive.dart';
import 'r_icon.dart';

typedef ReelPlayerBuilder = Widget Function(BuildContext context, Reel reel);

/// Vertical, swipeable reels feed (one full-screen video per page). Only the
/// reel in view gets a live player; the others show YouTube's poster image,
/// so at most one video loads or plays at a time.
class ReelsScreen extends StatefulWidget {
  const ReelsScreen({super.key, this.playerBuilder, this.showPosters = true});

  /// Replaced in tests (a WebView cannot run in widget tests).
  final ReelPlayerBuilder? playerBuilder;
  final bool showPosters;

  @override
  State<ReelsScreen> createState() => _ReelsScreenState();
}

class _ReelsScreenState extends State<ReelsScreen> {
  final _pages = PageController();
  int _current = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.services.reelsFeed.refresh();
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

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _open(Reel r) async {
    await launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final settings = context.services.settings;
    final feed = context.services.reelsFeed;
    return ListenableBuilder(
      listenable: Listenable.merge([settings, feed]),
      builder: (context, _) {
        final reviewer = settings.reelsReviewer;
        final reels = _feed(feed.items, context.services.content.reels.visible(reviewer: reviewer));
        if (_current >= reels.length && reels.isNotEmpty) _current = reels.length - 1;
        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: Text(l.reelsTitle),
            actions: [
              IconButton(
                key: const Key('reels.reviewer'),
                tooltip: '${l.reelsReviewerMode} — ${l.reelsReviewerHint}',
                isSelected: reviewer,
                icon: const RIcon(RIcons.checkCircle),
                selectedIcon: const RIcon(RIcons.checkCircle, color: Colors.amber),
                onPressed: () async {
                  await settings.setReelsReviewer(!reviewer);
                  if (_pages.hasClients) _pages.jumpToPage(0);
                  setState(() => _current = 0);
                },
              ),
            ],
          ),
          body: ReadableWidth(
            child: reels.isEmpty
                ? _Empty(
                    text: feed.loading
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
                          onPressed: () => feed.refresh(force: true),
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
                    onPageChanged: (i) => setState(() => _current = i),
                    itemBuilder: (context, i) => _ReelPage(
                      reel: reels[i],
                      index: i,
                      total: reels.length,
                      active: i == _current,
                      player: widget.playerBuilder ?? (context, r) => ReelPlayer(key: ValueKey(r.id), reel: r),
                      showPoster: widget.showPosters,
                      onOpen: () => _open(reels[i]),
                      onHide: reels[i].isAuto ? () => _hide(reels[i]) : null,
                    ),
                  ),
          ),
        );
      },
    );
  }
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
    this.onHide,
  });

  final Reel reel;
  final int index;
  final int total;
  final bool active;
  final ReelPlayerBuilder player;
  final bool showPoster;
  final VoidCallback onOpen;

  /// Hides the reel's channel (automatic reels only).
  final VoidCallback? onHide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = context.services.settings.isArabic;
    final speaker = reel.speaker(ar);
    final category = switch (reel.category) {
      'recitation' => l.reelsCatRecitation,
      'lesson' => l.reelsCatLesson,
      _ => l.reelsCatAdmonition,
    };
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
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0F5C4A), Color(0xFF06140F)],
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
                    Text(
                      reel.title(ar),
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                    if (speaker != null) Text(speaker, style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Wrap(
                      spacing: DesignTokens.spaceXs,
                      runSpacing: DesignTokens.spaceXs,
                      children: [
                        _Chip(category),
                        _Chip(reel.isInstagram ? l.reelsPlatformInstagram : l.reelsPlatformYoutube),
                        if (reel.reviewer != null) _Chip(l.reelsReviewedBy(reel.reviewer!), green: true),
                        if (reel.isAuto) _Chip(l.reelsTrusted, green: true),
                        _Chip(context.numLtr('${index + 1} / $total')),
                      ],
                    ),
                    Wrap(
                      spacing: DesignTokens.spaceMd,
                      children: [
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

class _Chip extends StatelessWidget {
  const _Chip(this.text, {this.green = false});
  final String text;
  final bool green;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: 2),
    decoration: BoxDecoration(
      color: green ? const Color(0x8C2EA06E) : const Color(0x2EFFFFFF),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
  );
}

final _igEmbedPath = RegExp(r'^/(reel|p|tv)/[A-Za-z0-9_-]{5,40}/embed(/captioned)?/?$');

/// Only the official embed pages may load inside the feed; anything else
/// (watch pages, profiles, other sites) is handed to the app or browser.
bool reelNavigationAllowedInFeed(Uri u) =>
    u.scheme == 'about' ||
    (u.scheme == 'https' && u.host == 'www.youtube-nocookie.com' && (u.path == '/' || u.path.startsWith('/embed/'))) ||
    (u.scheme == 'https' && u.host == 'www.instagram.com' && _igEmbedPath.hasMatch(u.path));

/// The platform's official embed in a WebView. YouTube autoplays muted and
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
