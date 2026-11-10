import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../app_services.dart';
import '../domain/nasheeds.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// Replaced in widget tests, where a WebView cannot run.
@visibleForTesting
Widget Function(BuildContext context, String videoId)? debugYouTubeEmbedBuilder;

const _origin = 'https://www.youtube-nocookie.com';

/// The official YouTube embed for one video (privacy-enhanced domain).
Uri youTubeEmbedUri(String videoId) => Uri.https('www.youtube-nocookie.com', '/embed/$videoId', {
  'autoplay': '1',
  'playsinline': '1',
  'rel': '0',
  'modestbranding': '1',
  'origin': _origin,
});

String _html(String videoId) =>
    '<!doctype html><html><head><meta charset="utf-8">'
    '<meta name="viewport" content="width=device-width,initial-scale=1">'
    '<style>html,body{margin:0;height:100%;background:#000;overflow:hidden}'
    'iframe{position:fixed;inset:0;width:100%;height:100%;border:0}</style></head><body>'
    '<iframe src="${youTubeEmbedUri(videoId)}" allow="autoplay; encrypted-media; picture-in-picture; fullscreen" '
    'allowfullscreen referrerpolicy="strict-origin-when-cross-origin"></iframe></body></html>';

/// Only the embed itself loads in place; any other link opens in YouTube or the browser.
bool youTubeEmbedNavigationAllowed(Uri u) =>
    u.scheme == 'about' ||
    (u.scheme == 'https' && u.host == 'www.youtube-nocookie.com' && (u.path == '/' || u.path.startsWith('/embed/')));

class YouTubeEmbed extends StatefulWidget {
  const YouTubeEmbed({super.key, required this.videoId});
  final String videoId;

  @override
  State<YouTubeEmbed> createState() => _YouTubeEmbedState();
}

class _YouTubeEmbedState extends State<YouTubeEmbed> {
  WebViewController? _c;

  @override
  void initState() {
    super.initState();
    if (debugYouTubeEmbedBuilder != null) return;
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
            if (u != null && youTubeEmbedNavigationAllowed(u)) return NavigationDecision.navigate;
            if (u != null && u.scheme == 'https') launchUrl(u, mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          },
        ),
      );
    final p = c.platform;
    if (p is AndroidWebViewController) p.setMediaPlaybackRequiresUserGesture(false);
    c.loadHtmlString(_html(widget.videoId), baseUrl: _origin);
    _c = c;
  }

  @override
  Widget build(BuildContext context) {
    final test = debugYouTubeEmbedBuilder;
    if (test != null) return test(context, widget.videoId);
    return WebViewWidget(controller: _c!);
  }
}

/// A bottom sheet with the video's player (kept visible, as YouTube requires),
/// its title and who it is by. Any Quran recitation that is playing pauses.
Future<void> showYouTubeSheet(
  BuildContext context, {
  required String videoId,
  required String title,
  required String subtitle,
}) {
  assert(MediaItem.idPattern.hasMatch(videoId));
  final s = context.services;
  if (s.recitation.isPlaying) s.recitation.pause();
  if (s.narration.isPlaying) s.narration.pause();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        key: const Key('ytSheet'),
        padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            Text(subtitle, style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            const SizedBox(height: DesignTokens.spaceMd),
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: AspectRatio(aspectRatio: 16 / 9, child: YouTubeEmbed(key: Key('yt-$videoId'), videoId: videoId)),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Row(
              children: [
                const RIcon(RIcons.info, size: 16),
                const SizedBox(width: DesignTokens.spaceXs),
                Expanded(child: Text(ctx.l10n.ytOfficialNote, style: Theme.of(ctx).textTheme.bodySmall)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
