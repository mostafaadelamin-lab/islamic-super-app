import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_services.dart';
import '../domain/video_search.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'reels_screen.dart' show ChannelSearchSheet;
import 'youtube_player.dart';

/// Search Islamic videos (recitations, lessons, admonitions). The viewer's past
/// searches are kept on the device and shown under the box; tap one to search again.
class VideoSearchScreen extends StatefulWidget {
  const VideoSearchScreen({super.key, this.initialQuery});
  final String? initialQuery;

  @override
  State<VideoSearchScreen> createState() => _VideoSearchScreenState();
}

class _VideoSearchScreenState extends State<VideoSearchScreen> {
  final _q = TextEditingController();
  Future<List<VideoHit>?>? _results;
  String? _query;

  @override
  void initState() {
    super.initState();
    final q = widget.initialQuery;
    if (q != null) WidgetsBinding.instance.addPostFrameCallback((_) => _run(q));
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  void _run(String raw) {
    final q = raw.trim();
    if (q.isEmpty) return;
    final feed = context.services.reelsFeed;
    _q.text = q;
    FocusScope.of(context).unfocus();
    feed.rememberSearch(q);
    setState(() {
      _query = q;
      _results = feed.searchVideos(q);
    });
  }

  void _play(VideoHit h) => showYouTubeSheet(context, videoId: h.ref, title: h.title, subtitle: h.channel ?? '');

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final feed = context.services.reelsFeed;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('videos.searchField'),
          controller: _q,
          autofocus: widget.initialQuery == null,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(hintText: l.videosSearchHint, border: InputBorder.none),
          onSubmitted: _run,
        ),
        actions: [
          IconButton(
            key: const Key('videos.go'),
            tooltip: l.videosSearch,
            icon: const RIcon(RIcons.search),
            onPressed: () => _run(_q.text),
          ),
          IconButton(
            key: const Key('videos.channels'),
            tooltip: l.reelsSearch,
            icon: const RIcon(RIcons.plus),
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              showDragHandle: true,
              builder: (_) => const ChannelSearchSheet(),
            ),
          ),
        ],
      ),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: feed,
          builder: (context, _) {
            final history = feed.searchHistory;
            return ListView(
              key: const Key('videos.list'),
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
              children: [
                if (history.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spaceLg,
                      DesignTokens.spaceMd,
                      DesignTokens.spaceSm,
                      0,
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text(l.videosHistory, style: theme.textTheme.titleSmall)),
                        TextButton(
                          key: const Key('videos.clearHistory'),
                          onPressed: feed.clearSearchHistory,
                          child: Text(l.videosClearHistory),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                    child: Wrap(
                      spacing: DesignTokens.spaceXs,
                      runSpacing: DesignTokens.spaceXs,
                      children: [
                        for (final h in history)
                          InputChip(
                            key: Key('videos.history.$h'),
                            label: Text(h),
                            onPressed: () => _run(h),
                            onDeleted: () => feed.forgetSearch(h),
                            deleteButtonTooltipMessage: l.videosRemoveHistory(h),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: DesignTokens.spaceXl),
                ],
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                  child: Text(l.videosSearchNote, style: theme.textTheme.bodySmall),
                ),
                if (_results != null)
                  FutureBuilder<List<VideoHit>?>(
                    key: ValueKey(_query),
                    future: _results,
                    builder: (context, snap) {
                      if (snap.connectionState != ConnectionState.done) {
                        return const Padding(
                          padding: EdgeInsets.all(DesignTokens.spaceXl),
                          child: Center(child: CircularProgressIndicator(key: Key('videos.loading'))),
                        );
                      }
                      final list = snap.data;
                      if (list == null || list.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(DesignTokens.spaceLg),
                          child: Text(
                            list == null ? l.videosSearchFailed : l.videosNoResults,
                            key: const Key('videos.none'),
                            textAlign: TextAlign.center,
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final h in list)
                            ListTile(
                              key: Key('videos.hit.${h.ref}'),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: SizedBox(
                                  width: 112,
                                  height: 63,
                                  child: Image.network(
                                    h.thumbUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => const ColoredBox(
                                      color: Colors.black12,
                                      child: Center(child: RIcon(RIcons.playCircle)),
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(h.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: Text(
                                [?h.channel, ?h.duration, if (h.trusted) l.reelsTrusted].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => _play(h),
                              onLongPress: () => launchUrl(Uri.parse(h.watchUrl), mode: LaunchMode.externalApplication),
                            ),
                        ],
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
