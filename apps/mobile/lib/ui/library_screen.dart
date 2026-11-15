import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/mp3quran.dart';
import '../data/recitation.dart';
import '../domain/mp3quran.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'play_origin.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'stories_screen.dart';
import 'widgets.dart';

const _bottomPlayers = Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]);

/// mp3quran.net reciters (every riwaya), streamed or saved for offline listening.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  Future<Mp3Library>? _future;
  String _query = '';
  int? _rewaya;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<Mp3Library> _load({bool refresh = false}) =>
      context.services.mp3quran.load(Mp3QuranClient.apiLanguage(context.isArabic), refresh: refresh);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.libraryTitle)),
      bottomNavigationBar: _bottomPlayers,
      body: ReadableWidth(
        child: FutureBuilder<Mp3Library>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceXl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l.libraryLoadError, key: const Key('libraryError'), textAlign: TextAlign.center),
                      const SizedBox(height: DesignTokens.spaceMd),
                      FilledButton(
                        key: const Key('libraryRetry'),
                        onPressed: () => setState(() => _future = _load(refresh: true)),
                        child: Text(l.libraryRetry),
                      ),
                    ],
                  ),
                ),
              );
            }
            final lib = snap.data;
            if (lib == null) return const Center(child: CircularProgressIndicator());
            return _reciters(context, lib);
          },
        ),
      ),
    );
  }

  Widget _search(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
    child: TextField(
      key: const Key('librarySearch'),
      decoration: InputDecoration(labelText: context.l10n.librarySearch, prefixIcon: const Icon(Icons.search)),
      onChanged: (v) => setState(() => _query = v),
    ),
  );

  Widget _source(BuildContext context) => Padding(
    padding: const EdgeInsets.all(DesignTokens.spaceLg),
    child: Text(
      context.l10n.librarySource,
      key: const Key('librarySource'),
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );

  Widget _reciters(BuildContext context, Mp3Library lib) {
    final l = context.l10n;
    final norm = context.services.content.normalizer.normalize;
    final list = lib.filterReciters(_query, _rewaya, norm);
    return ListView(
      key: const Key('libraryReciters'),
      children: [
        _search(context),
        if (lib.riwayat.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
            child: DropdownButtonFormField<int?>(
              key: const Key('libraryRewaya'),
              initialValue: _rewaya,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.libraryRewaya),
              items: [
                DropdownMenuItem<int?>(value: null, child: Text(l.libraryAllRiwayat)),
                for (final w in lib.riwayat)
                  DropdownMenuItem<int?>(
                    value: w.id,
                    child: Text(w.name, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _rewaya = v),
            ),
          ),
        if (list.isEmpty) Padding(padding: const EdgeInsets.all(DesignTokens.spaceXl), child: Text(l.libraryEmpty)),
        for (final r in list)
          ListTile(
            key: Key('reciter-${r.id}'),
            leading: const Icon(Icons.record_voice_over_outlined),
            title: Text(r.name),
            subtitle: Text(
              [
                for (final m in r.moshafs)
                  if (_rewaya == null || m.rewayaId == _rewaya) m.name,
              ].join(' · '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReciterScreen(reciter: r, rewaya: _rewaya),
              ),
            ),
          ),
        _source(context),
      ],
    );
  }
}

/// One reciter: choose a recording (riwaya), then a surah to play.
class ReciterScreen extends StatefulWidget {
  const ReciterScreen({super.key, required this.reciter, this.rewaya});
  final Mp3Reciter reciter;
  final int? rewaya;

  @override
  State<ReciterScreen> createState() => _ReciterScreenState();
}

class _ReciterScreenState extends State<ReciterScreen> {
  late Mp3Moshaf _moshaf = widget.reciter.moshafs.firstWhere(
    (m) => m.rewayaId == widget.rewaya,
    orElse: () => widget.reciter.moshafs.first,
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final r = widget.reciter;
    final episodes = [
      for (final n in _moshaf.surahs)
        Episode(
          id: 's$n',
          titleAr: l.librarySurahTitle(r.name, s.content.quran.surah(n).nameAr),
          titleEn: l.librarySurahTitle(r.name, s.content.quran.surah(n).translit),
          url: _moshaf.url(n),
          status: ReviewStatus.approved,
        ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(r.name)),
      bottomNavigationBar: _bottomPlayers,
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: s.narration,
          builder: (context, _) => ListView(
            key: const Key('reciterSurahs'),
            children: [
              if (r.moshafs.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spaceLg,
                    DesignTokens.spaceSm,
                    DesignTokens.spaceLg,
                    0,
                  ),
                  child: DropdownButtonFormField<int>(
                    key: const Key('reciterMoshaf'),
                    initialValue: _moshaf.id,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: l.libraryRewaya),
                    items: [
                      for (final m in r.moshafs)
                        DropdownMenuItem(
                          value: m.id,
                          child: Text(m.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (id) => setState(() => _moshaf = r.moshafs.firstWhere((m) => m.id == id)),
                  ),
                )
              else
                ListTile(title: Text(_moshaf.name)),
              ListTile(dense: true, title: Text(l.librarySurahCount(context.num(_moshaf.surahs.length)))),
              // The whole moshaf, in order: a surah goes straight on to the next one.
              for (final (i, n) in _moshaf.surahs.indexed)
                PlayTile(
                  key: Key('surah-$n'),
                  offline: true,
                  series: 'mp3quran-${_moshaf.id}',
                  episode: episodes[i],
                  playlist: episodes,
                  title: '${context.num(n)}. ${surahName(context, s.content.quran.surah(n))}',
                ),
              Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Text(l.librarySource, style: Theme.of(context).textTheme.bodySmall),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Play / pause row for one stream through the narration player (one voice at a
/// time). With [offline], a button saves the file on the phone (or deletes the
/// saved copy); a saved copy plays without internet.
class PlayTile extends StatelessWidget {
  const PlayTile({
    super.key,
    required this.series,
    required this.episode,
    this.title,
    this.subtitle,
    this.remember = true,
    this.offline = false,
    this.leading,
    this.onPlay,
    this.playlist,
    this.inline = true,
  });
  final VoidCallback? onPlay;

  /// Show the player's buttons right under this row while it plays.
  final bool inline;

  /// The list this item belongs to: when it ends the next one plays.
  final List<Episode>? playlist;
  final String series;
  final Episode episode;
  final String? title;
  final String? subtitle;
  final bool remember;
  final bool offline;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final n = s.narration;
    final on = n.episode?.id == episode.id && n.episode?.url == episode.url;
    final playing = on && n.isPlaying;
    final scheme = Theme.of(context).colorScheme;
    final tile = ListTile(
      selected: on,
      leading: leading ?? Icon(playing ? Icons.pause_circle : Icons.play_circle, color: scheme.primary),
      title: Text(title ?? episode.title(context.isArabic)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: offline
          ? OfflineButton(series: series, episode: episode)
          : (leading != null ? Icon(playing ? Icons.pause_circle : Icons.play_circle, color: scheme.primary) : null),
      onTap: () {
        if (playing) {
          n.pause();
        } else if (on && n.state == RecitationState.paused) {
          n.resume();
        } else {
          onPlay?.call();
          PlayOrigin.remember(context, series);
          n.playEpisode(series, episode, remember: remember, playlist: playlist);
        }
      },
    );
    if (!inline || !on || !n.isActive) return tile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [tile, const InlineNarrationPlayer()],
    );
  }
}

/// Download for offline listening / saved (tap to delete) / progress.
class OfflineButton extends StatefulWidget {
  const OfflineButton({super.key, required this.series, required this.episode});
  final String series;
  final Episode episode;

  @override
  State<OfflineButton> createState() => OfflineButtonState();
}

class OfflineButtonState extends State<OfflineButton> {
  Future<String?>? _saved;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _saved ??= _check();
  }

  Future<String?> _check() async {
    try {
      return await context.services.downloads.offlineFile(widget.series, widget.episode.id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = context.services.downloads;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: d,
      builder: (context, _) {
        if (d.isFileDownloading(widget.series, widget.episode.id)) {
          final p = d.fileProgress['${widget.series}/${widget.episode.id}'] ?? 0;
          return SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5, value: p > 0 ? p : null),
          );
        }
        return FutureBuilder<String?>(
          future: _saved,
          builder: (context, snap) {
            final saved = snap.data != null;
            return IconButton(
              key: Key('offline-${widget.episode.id}'),
              tooltip: saved ? l.offlineSavedDelete : l.offlineDownload,
              icon: Icon(
                saved ? Icons.download_done : Icons.download_for_offline_outlined,
                color: saved ? Theme.of(context).colorScheme.primary : null,
              ),
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                if (saved) {
                  await d.deleteFile(widget.series, widget.episode.id);
                } else {
                  try {
                    await d.downloadFile(widget.series, widget.episode.id, widget.episode.url);
                    messenger.showSnackBar(SnackBar(content: Text(l.offlineDone)));
                  } catch (_) {
                    messenger.showSnackBar(SnackBar(content: Text(l.offlineFailed)));
                  }
                }
                if (mounted) setState(() => _saved = _check());
              },
            );
          },
        );
      },
    );
  }
}
