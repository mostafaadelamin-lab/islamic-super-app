import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/mp3quran.dart';
import '../data/recitation.dart';
import '../domain/mp3quran.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'stories_screen.dart';
import 'widgets.dart';

const _bottomPlayers = Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]);

/// mp3quran.net reciters (every riwaya) and Quran radios, streamed.
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.libraryTitle),
          bottom: TabBar(
            tabs: [
              Tab(key: const Key('libraryTabReciters'), text: l.libraryReciters),
              Tab(key: const Key('libraryTabRadios'), text: l.libraryRadios),
            ],
          ),
        ),
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
              return TabBarView(children: [_reciters(context, lib), _radios(context, lib)]);
            },
          ),
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

  Widget _radios(BuildContext context, Mp3Library lib) {
    final l = context.l10n;
    final s = context.services;
    final list = lib.filterRadios(_query, s.content.normalizer.normalize);
    return ListenableBuilder(
      listenable: s.narration,
      builder: (context, _) => ListView(
        key: const Key('libraryRadios'),
        children: [
          _search(context),
          if (list.isEmpty) Padding(padding: const EdgeInsets.all(DesignTokens.spaceXl), child: Text(l.libraryEmpty)),
          for (final r in list)
            _PlayTile(
              key: Key('radio-${r.id}'),
              series: 'radio',
              episode: Episode(
                id: 'radio-${r.id}',
                titleAr: r.name,
                titleEn: r.name,
                url: r.url,
                status: ReviewStatus.approved,
              ),
              subtitle: l.libraryLive,
              remember: false,
            ),
          _source(context),
        ],
      ),
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
              for (final n in _moshaf.surahs)
                Builder(
                  builder: (context) {
                    final surah = s.content.quran.surah(n);
                    final ar = l.librarySurahTitle(r.name, surah.nameAr);
                    return _PlayTile(
                      key: Key('surah-$n'),
                      series: 'mp3quran-${_moshaf.id}',
                      episode: Episode(
                        id: 's$n',
                        titleAr: ar,
                        titleEn: l.librarySurahTitle(r.name, surah.translit),
                        url: _moshaf.url(n),
                        status: ReviewStatus.approved,
                      ),
                      title: '${context.num(n)}. ${surahName(context, surah)}',
                    );
                  },
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

/// Play / pause row for one stream through the narration player (one voice at a time).
class _PlayTile extends StatelessWidget {
  const _PlayTile({
    super.key,
    required this.series,
    required this.episode,
    this.title,
    this.subtitle,
    this.remember = true,
  });
  final String series;
  final Episode episode;
  final String? title;
  final String? subtitle;
  final bool remember;

  @override
  Widget build(BuildContext context) {
    final n = context.services.narration;
    final on = n.episode?.id == episode.id && n.episode?.url == episode.url;
    final playing = on && n.isPlaying;
    return ListTile(
      selected: on,
      leading: Icon(playing ? Icons.pause_circle : Icons.play_circle, color: Theme.of(context).colorScheme.primary),
      title: Text(title ?? episode.title(context.isArabic)),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onTap: () {
        if (playing) {
          n.pause();
        } else if (on && n.state == RecitationState.paused) {
          n.resume();
        } else {
          n.playEpisode(series, episode, remember: remember);
        }
      },
    );
  }
}
