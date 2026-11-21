import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../app_services.dart';
import '../data/audio_focus.dart';
import '../domain/kids.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'library_screen.dart' show OfflineButton;
import 'play_origin.dart';
import 'r_icon.dart';
import 'kids_learn_screen.dart';
import 'kids_mushaf_screen.dart';
import 'ruqyah_screen.dart';
import 'stories_screen.dart' show NarrationBar;
import 'widgets.dart';
import 'youtube_player.dart';

/// "الأطفال" (owner, 2026-11-20): stories of the prophets (video, listen, offline),
/// the teaching Mushaf, religious and educational stories, and ruqyah for children.
class KidsScreen extends StatelessWidget {
  const KidsScreen({super.key, this.loader = loadKids});
  final Future<KidsContent> Function() loader;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    Widget tile(String id, RIconData icon, String title, String sub, VoidCallback onTap) => Card(
      key: Key('kids.$id'),
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
        leading: RIconBadge(icon, size: 48),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
        subtitle: Text(sub),
        trailing: const RIcon(RIcons.chevronForward),
        onTap: onTap,
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.kidsTitle)),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: ReadableWidth(
        child: FutureBuilder<KidsContent>(
          future: loader(),
          builder: (context, snap) {
            final k = snap.data;
            if (k == null) return const Center(child: CircularProgressIndicator());
            final prophets = k.byId('kids-prophets');
            final prophetsNew = k.byId('kids-prophets-new');
            final prophets3d = k.byId('kids-prophets-3d');
            final rasoul = k.byId('kids-rasoul');
            final ramadan = k.byId('kids-ramadan');
            return ListView(
              key: const Key('kidsHub'),
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
              children: [
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Text(l.kidsNote, style: Theme.of(context).textTheme.bodyMedium),
                ),
                if (prophets != null)
                  tile('prophets', RIcons.video, l.kidsProphets, l.kidsProphetsSub, () {
                    final choices = [
                      if (prophetsNew != null) (prophetsNew, l.kidsProphetsNew, l.kidsProphetsNewSub),
                      if (prophets3d != null) (prophets3d, l.kidsProphets3d, l.kidsProphets3dSub),
                      (prophets, l.kidsProphetsClassic, l.kidsProphetsSub),
                    ];
                    push(KidsSeriesScreen(series: choices.first.$1, title: l.kidsProphets, choices: choices));
                  }),
                tile(
                  'teacher',
                  RIcons.quran,
                  l.kidsTeacher,
                  l.kidsTeacherSub,
                  () => push(TeacherMushafScreen(content: k)),
                ),
                tile(
                  'stories',
                  RIcons.book,
                  l.kidsStories,
                  l.kidsStoriesSub,
                  () => push(
                    KidsStoriesScreen(
                      parts: [
                        if (rasoul != null) (rasoul, l.kidsRasoul, l.kidsRasoulSub),
                        if (ramadan != null) (ramadan, l.kidsRamadan, l.kidsRamadanSub),
                      ],
                    ),
                  ),
                ),
                tile(
                  'books',
                  RIcons.openBook,
                  l.kidsLearnBooks,
                  l.kidsLearnBooksSub,
                  () => push(const KidsBooksScreen()),
                ),
                tile(
                  'hadith',
                  RIcons.star,
                  l.kidsLearnHadith,
                  l.kidsLearnHadithSub,
                  () => push(const KidsHadithScreen()),
                ),
                tile(
                  'cards',
                  RIcons.adhkar,
                  l.kidsLearnCards,
                  l.kidsLearnCardsSub,
                  () => push(const KidsCardsScreen()),
                ),
                tile(
                  'wudu',
                  RIcons.prayer,
                  l.kidsLearnWudu,
                  l.kidsLearnWuduSub,
                  () => push(const KidsStepsScreen(salah: false)),
                ),
                tile(
                  'salah',
                  RIcons.prayer,
                  l.kidsLearnSalah,
                  l.kidsLearnSalahSub,
                  () => push(const KidsStepsScreen(salah: true)),
                ),
                tile(
                  'ruqyah',
                  RIcons.shield,
                  l.ruqyahKidsTitle,
                  l.kidsRuqyahSub,
                  () => push(RuqyahScreen(kids: true, loader: loader)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// "قصص دينية وتعليمية": one card per series.
class KidsStoriesScreen extends StatelessWidget {
  const KidsStoriesScreen({super.key, required this.parts, this.title});
  final List<(KidsSeries, String, String)> parts;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(title ?? l.kidsStories)),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: ReadableWidth(
        child: ListView(
          key: const Key('kidsStories'),
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
          children: [
            for (final (s, name, sub) in parts)
              Card(
                key: Key('kidsStories.${s.id}'),
                margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
                child: ListTile(
                  leading: const RIconBadge(RIcons.video),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$sub · ${context.num(s.episodes.length)}'),
                  trailing: const RIcon(RIcons.chevronForward),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => KidsSeriesScreen(series: s, title: name),
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

Episode kidsEpisode(KidsEpisode e) => Episode(
  id: e.id,
  titleAr: e.title,
  titleEn: e.title,
  url: e.url,
  durationSec: e.seconds,
  status: ReviewStatus.approved,
);

/// The episodes of one video series: watch, listen (the sound only, in the background
/// player), or download for offline (the saved file serves both).
class KidsSeriesScreen extends StatefulWidget {
  const KidsSeriesScreen({super.key, required this.series, required this.title, this.choices});
  final KidsSeries series;
  final String title;

  /// Several series of one kind (the prophets' stories, owner 2026-11-21): a drop-down list picks one.
  final List<(KidsSeries, String, String)>? choices;

  @override
  State<KidsSeriesScreen> createState() => _KidsSeriesScreenState();
}

class _KidsSeriesScreenState extends State<KidsSeriesScreen> {
  late KidsSeries series = widget.series;

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final choices = widget.choices;
    final s = context.services;
    final l = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: s.narration,
          builder: (context, _) {
            final online = series.episodes.isNotEmpty && series.episodes.first.youtube != null;
            final playlist = [for (final e in series.episodes) kidsEpisode(e)];
            return ListView.builder(
              key: Key('kidsSeries.${series.id}'),
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
              itemCount: series.episodes.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  final note = Text(online ? l.kidsYtNote : l.kidsOfflineNote, style: theme.textTheme.bodyMedium);
                  if (choices == null) return Padding(padding: const EdgeInsets.all(DesignTokens.spaceLg), child: note);
                  final picked = choices.firstWhere((c) => c.$1.id == series.id);
                  return Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<String>(
                          key: const Key('kidsSeries.pick'),
                          initialValue: series.id,
                          isExpanded: true,
                          decoration: InputDecoration(labelText: l.kidsProphetsPick),
                          items: [
                            for (final (c, name, _) in choices)
                              DropdownMenuItem(
                                value: c.id,
                                child: Text(name, overflow: TextOverflow.ellipsis),
                              ),
                          ],
                          onChanged: (id) => setState(() => series = choices.firstWhere((c) => c.$1.id == id).$1),
                        ),
                        const SizedBox(height: DesignTokens.spaceSm),
                        Text(picked.$3, style: theme.textTheme.bodySmall),
                        const SizedBox(height: DesignTokens.spaceSm),
                        note,
                      ],
                    ),
                  );
                }
                final e = series.episodes[i - 1];
                final yt = e.youtube;
                if (yt != null) {
                  return Card(
                    key: Key('kidsEpisode.${e.id}'),
                    margin: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceLg,
                      vertical: DesignTokens.spaceXs,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(context.num(i))),
                      title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: e.minutes == null ? null : Text(l.kidsMinutes(context.num(e.minutes!))),
                      trailing: FilledButton.tonalIcon(
                        key: Key('kidsWatch.${e.id}'),
                        icon: const RIcon(RIcons.play, size: 18),
                        label: Text(l.kidsWatch),
                        onPressed: () => showYouTubeSheet(context, videoId: yt, title: e.title, subtitle: title),
                      ),
                    ),
                  );
                }
                final ep = playlist[i - 1];
                final listening = s.narration.episode?.id == ep.id && s.narration.isPlaying;
                final meta = [
                  if (e.minutes != null) l.kidsMinutes(context.num(e.minutes!)),
                  if (e.megabytes != null) l.kidsSize(context.num(e.megabytes!)),
                ].join(' · ');
                return Card(
                  key: Key('kidsEpisode.${e.id}'),
                  margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DesignTokens.spaceMd,
                      DesignTokens.spaceSm,
                      DesignTokens.spaceSm,
                      DesignTokens.spaceSm,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(child: Text(context.num(i))),
                        const SizedBox(width: DesignTokens.spaceMd),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                              if (meta.isNotEmpty) Text(meta, style: theme.textTheme.bodySmall),
                              const SizedBox(height: DesignTokens.spaceXs),
                              Wrap(
                                spacing: DesignTokens.spaceSm,
                                children: [
                                  FilledButton.tonalIcon(
                                    key: Key('kidsWatch.${e.id}'),
                                    icon: const RIcon(RIcons.play, size: 18),
                                    label: Text(l.kidsWatch),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) => KidsVideoScreen(series: series, episode: e),
                                      ),
                                    ),
                                  ),
                                  OutlinedButton.icon(
                                    key: Key('kidsListen.${e.id}'),
                                    icon: RIcon(listening ? RIcons.pause : RIcons.headphones, size: 18),
                                    label: Text(l.kidsListen),
                                    onPressed: () {
                                      final n = s.narration;
                                      if (listening) {
                                        n.pause();
                                      } else {
                                        PlayOrigin.remember(context, series.id);
                                        n.playEpisode(series.id, ep, playlist: playlist);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        OfflineButton(series: series.id, episode: ep),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Plays one episode's video: the saved copy when there is one, else streamed.
class KidsVideoScreen extends StatefulWidget {
  const KidsVideoScreen({super.key, required this.series, required this.episode});
  final KidsSeries series;
  final KidsEpisode episode;

  @override
  State<KidsVideoScreen> createState() => _KidsVideoScreenState();
}

class _KidsVideoScreenState extends State<KidsVideoScreen> {
  VideoPlayerController? _c;
  bool _failed = false;
  bool _offline = false;

  @override
  void initState() {
    super.initState();
    // One sound at a time: the recitation, adhkar or the listening player pause.
    AudioFocus.claim(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  Future<void> _open() async {
    final s = context.services;
    if (s.narration.isPlaying) await s.narration.pause();
    String? local;
    try {
      local = await s.downloads.offlineFile(widget.series.id, widget.episode.id);
    } catch (_) {}
    final c = local != null
        ? VideoPlayerController.file(File(local))
        : VideoPlayerController.networkUrl(Uri.parse(widget.episode.url));
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _c = c;
        _offline = local != null;
      });
      await c.play();
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    unawaited(_c?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = _c;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.episode.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: Center(
          child: _failed
              ? Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceXl),
                  child: Text(
                    l.kidsVideoError,
                    key: const Key('kidsVideoError'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                )
              : c == null
              ? const CircularProgressIndicator(color: Colors.white)
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: c.value.aspectRatio,
                      child: GestureDetector(
                        onTap: () => setState(() => c.value.isPlaying ? c.pause() : c.play()),
                        child: VideoPlayer(c),
                      ),
                    ),
                    _VideoControls(controller: c),
                    if (_offline)
                      Padding(
                        padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                        child: Text(l.kidsOfflinePlaying, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _VideoControls extends StatelessWidget {
  const _VideoControls({required this.controller});
  final VideoPlayerController controller;

  String _t(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<VideoPlayerValue>(
    valueListenable: controller,
    builder: (context, v, _) {
      final total = v.duration.inMilliseconds.toDouble();
      final pos = v.position.inMilliseconds.clamp(0, total.toInt()).toDouble();
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          child: Row(
            children: [
              IconButton(
                key: const Key('kidsVideoPlay'),
                color: Colors.white,
                iconSize: 36,
                icon: Icon(v.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                onPressed: () => v.isPlaying ? controller.pause() : controller.play(),
              ),
              Text(_t(v.position), style: const TextStyle(color: Colors.white70)),
              Expanded(
                child: Slider(
                  value: total > 0 ? pos : 0,
                  max: total > 0 ? total : 1,
                  onChanged: total > 0 ? (x) => controller.seekTo(Duration(milliseconds: x.round())) : null,
                ),
              ),
              Text(_t(v.duration), style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    },
  );
}

/// "المصحف المعلّم للأطفال": Juz 'Amma and al-Fatiha. Each surah opens the interactive kids' Mushaf
/// ([KidsMushafScreen], owner 2026-11-20), with the stars earned so far.
class TeacherMushafScreen extends StatefulWidget {
  const TeacherMushafScreen({super.key, required this.content});
  final KidsContent content;

  @override
  State<TeacherMushafScreen> createState() => _TeacherMushafScreenState();
}

class _TeacherMushafScreenState extends State<TeacherMushafScreen> {
  Map<String, int> _stars = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final st = await readTeacherStars();
    if (mounted) setState(() => _stars = st);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final q = s.content.quran;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.kidsTeacher)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('teacherList'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Text(l.kidsTeacherNote, style: theme.textTheme.bodyMedium),
            ),
            for (final n in widget.content.teacherSurahs)
              Card(
                key: Key('teacher.$n'),
                margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
                child: ListTile(
                  leading: CircleAvatar(child: Text(context.num(n))),
                  title: Text(
                    'سورة ${q.surah(n).nameAr}',
                    style: const TextStyle(fontFamily: DesignTokens.fontQuran, fontSize: 20),
                  ),
                  subtitle: Text(
                    [
                      l.storiesAyahs(context.num(q.surah(n).ayahCount)),
                      if ((_stars['$n'] ?? 0) > 0) '⭐ ${context.num(_stars['$n']!)}',
                    ].join(' · '),
                  ),
                  trailing: const RIcon(RIcons.openBook, size: 28),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => KidsMushafScreen(surah: n, reciters: widget.content.teacherReciters),
                      ),
                    );
                    await _load();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Small helper for the home screen and More list.
Widget kidsEntryTile(BuildContext context) => SectionCard(
  children: [
    ListTile(
      key: const Key('more.kids'),
      contentPadding: EdgeInsets.zero,
      leading: const RIconBadge(RIcons.kids),
      title: Text(context.l10n.kidsTitle),
      trailing: const RIcon(RIcons.chevronForward),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const KidsScreen())),
    ),
  ],
);
