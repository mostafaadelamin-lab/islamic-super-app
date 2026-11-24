import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../domain/lessons.dart';
import '../domain/stories.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'library_screen.dart' show OfflineButton;
import 'play_origin.dart';
import 'report_error_link.dart';
import 'r_icon.dart';
import 'sharawi_screen.dart' show SharawiPart, SharawiScreen;
import 'stories_screen.dart' show InlineNarrationPlayer, NarrationBar;

Future<LessonCatalog> loadLessons() async =>
    LessonCatalog.parse(await rootBundle.loadString('assets/content/lessons.v1.json'));

String _norm(String s) => s
    .replaceAll(RegExp('[ًٌٍَُِّْـ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .toLowerCase();

/// Cover colour per topic (deep tones that read well with the gold title).
const _topicColors = <String, Color>{
  'aqeedah': Color(0xFF1D3A64),
  'seerah': Color(0xFF16433A),
  'fiqh': Color(0xFF2E3D22),
  'hadith': Color(0xFF3B2A12),
  'hearts': Color(0xFF40243A),
  'stories': Color(0xFF25324F),
  'quran': Color(0xFF123B4A),
  'family': Color(0xFF1F4A3A),
  'akhlaq': Color(0xFF4A2A22),
  'adab': Color(0xFF2B2F52),
  'muamalat': Color(0xFF3A3A1A),
  'tahara': Color(0xFF14465A),
  'akhira': Color(0xFF2A1E36),
  'history': Color(0xFF3D2F1C),
  'fikr': Color(0xFF233F4F),
};

Color lessonTopicColor(String topic) => _topicColors[topic] ?? AppTheme.brand('heroTop');

extension LessonText on BuildContext {
  String lessonEpisodeTitle(LessonEpisode e) => l10n.lessonsLesson(this.num(e.index));

  String lessonDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = (seconds / 60).round().clamp(1, 1 << 30);
    if (m < 90) return l10n.lessonsMinutes(this.num(m));
    final h = seconds / 3600;
    return l10n.lessonsHours(this.num(h >= 10 ? h.round() : (h * 10).round() / 10));
  }
}

/// Episode for the shared audio player (streams, or plays the offline copy).
Episode lessonEpisode(BuildContext context, LessonSeries s, LessonEpisode e) {
  final ar = '${s.ar} · ${s.sheikh.ar.replaceFirst('الشيخ ', '')} · الدرس ${context.num(e.index)}';
  final en = '${s.en} · ${s.sheikh.en.replaceFirst('Sheikh ', '')} · lesson ${e.index}';
  return Episode(
    id: s.episodeId(e),
    titleAr: e.title == null ? ar : '$ar · ${e.title}',
    titleEn: en,
    url: e.url,
    durationSec: e.seconds > 0 ? e.seconds : null,
    status: ReviewStatus.approved,
    skips: e.skips,
    gainDb: s.gainDb,
    clarity: s.clarity,
  );
}

int _heard(BuildContext context, LessonSeries s) {
  final st = context.services.settings;
  var n = 0;
  for (final e in s.episodes) {
    if (st.episodeDone('${s.playerSeries}/${s.episodeId(e)}')) n++;
  }
  return n;
}

/// The lesson to continue in [s]: the last one played, else null.
LessonEpisode? _lastEpisode(BuildContext context, LessonSeries s) {
  final id = context.services.settings.lastEpisode(s.playerSeries);
  if (id == null) return null;
  for (final e in s.episodes) {
    if (s.episodeId(e) == id) return e;
  }
  return null;
}

/// «افهم دينك» (lesson series): all series as cards, filtered by topic, with a search box.
/// and topic, with search and a "continue" card for the last series listened to.
class LessonsScreen extends StatefulWidget {
  const LessonsScreen({super.key, this.loader = loadLessons});
  final Future<LessonCatalog> Function() loader;

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  late final Future<LessonCatalog> _future = widget.loader();
  String? _topic;
  String _query = '';

  void _open(LessonSeries s) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => s.isSharawiTafsir ? const SharawiScreen(part: SharawiPart.tafsir) : LessonSeriesScreen(series: s),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = context.isArabic;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.lessonsTitle)),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: ReadableWidth(
        child: FutureBuilder<LessonCatalog>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text(l.lessonsLoadError));
            final all = snap.data;
            if (all == null) return const Center(child: CircularProgressIndicator());
            final q = _norm(_query.trim());
            final list = [
              for (final s in all.filter(topic: _topic))
                if (q.isEmpty ||
                    _norm(s.ar).contains(q) ||
                    _norm(s.en).contains(q) ||
                    _norm(s.sheikh.ar).contains(q) ||
                    _norm(s.sheikh.en).contains(q) ||
                    _norm(s.topic.ar).contains(q))
                  s,
            ];
            Widget chip(String key, String label, bool on, VoidCallback tap) => Padding(
              padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceXs),
              // Owner (2026-11-24): the chosen topic is shaded more strongly.
              child: ChoiceChip(
                key: Key(key),
                label: Text(label, style: on ? const TextStyle(fontWeight: FontWeight.w700) : null),
                selected: on,
                selectedColor: theme.colorScheme.secondary.withValues(alpha: 0.5),
                side: on ? BorderSide(color: theme.colorScheme.secondary, width: 1.5) : null,
                onSelected: (_) => tap(),
              ),
            );
            return ListenableBuilder(
              listenable: context.services.settings,
              builder: (context, _) {
                final lastId = context.services.settings.lastLessonSeries;
                final last = lastId == null ? null : all.byId(lastId);
                final lastEp = last == null ? null : _lastEpisode(context, last);
                return ListView(
                  key: const Key('lessonsList'),
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spaceLg,
                        DesignTokens.spaceMd,
                        DesignTokens.spaceLg,
                        DesignTokens.spaceSm,
                      ),
                      child: Text(
                        l.lessonsNote(context.num(all.listed.length), context.num(all.lessonCount)),
                        key: const Key('lessonsNote'),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    // Owner (2026-11-24): every topic visible at once, no groups row.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                      child: Wrap(
                        runSpacing: DesignTokens.spaceXs,
                        children: [
                          chip(
                            'lessonsTopic.all',
                            l.lessonsAllTopics,
                            _topic == null,
                            () => setState(() => _topic = null),
                          ),
                          for (final t in all.topics)
                            if (all.filter(topic: t.id).isNotEmpty)
                              chip(
                                'lessonsTopic.${t.id}',
                                t.of(ar),
                                _topic == t.id,
                                () => setState(() => _topic = t.id),
                              ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spaceLg,
                        DesignTokens.spaceSm,
                        DesignTokens.spaceLg,
                        DesignTokens.spaceSm,
                      ),
                      child: TextField(
                        key: const Key('lessonsSearch'),
                        decoration: InputDecoration(
                          prefixIcon: const RIcon(RIcons.search),
                          hintText: l.lessonsSearch,
                          isDense: true,
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    if (last != null && lastEp != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DesignTokens.spaceLg,
                          vertical: DesignTokens.spaceXs,
                        ),
                        child: Material(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                          child: ListTile(
                            key: const Key('lessonsContinue'),
                            leading: const Icon(Icons.play_circle),
                            title: Text(l.lessonsContinue(last.title(ar), context.num(lastEp.index))),
                            subtitle: Text(last.sheikh.of(ar)),
                            trailing: IconButton(
                              key: const Key('lessonsContinueClose'),
                              tooltip: l.commonClose,
                              icon: const Icon(Icons.close),
                              onPressed: context.services.settings.clearLastLessonSeries,
                            ),
                            onTap: () => _open(last),
                          ),
                        ),
                      ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    LayoutBuilder(
                      builder: (context, box) {
                        final cols = box.maxWidth >= 720 ? 3 : 2;
                        const gap = DesignTokens.spaceSm;
                        final w = (box.maxWidth - 2 * DesignTokens.spaceMd - gap * (cols - 1)) / cols;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
                          child: Wrap(
                            spacing: gap,
                            runSpacing: gap,
                            children: [
                              for (final s in list)
                                SizedBox(
                                  width: w,
                                  child: _SeriesCard(series: s, heard: _heard(context, s), onTap: () => _open(s)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    if (list.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(DesignTokens.spaceLg),
                        child: Text(l.lessonsNoMatch, key: const Key('lessonsEmpty')),
                      ),
                    ReportErrorLink(page: l.lessonsTitle),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.series, required this.heard, required this.onTap});
  final LessonSeries series;
  final int heard;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = context.isArabic;
    final theme = Theme.of(context);
    final total = series.lessonTotal;
    final complete = heard >= total;
    return Card(
      key: Key('lessonsSeries.${series.id}'),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 84,
              color: lessonTopicColor(series.topic.id),
              padding: const EdgeInsets.all(DesignTokens.spaceSm),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    series.title(ar),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: const Color(0xFFF3E9D2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    series.sheikh.of(ar),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(color: AppTheme.brand('gold')),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spaceSm,
                DesignTokens.spaceXs,
                DesignTokens.spaceSm,
                DesignTokens.spaceSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    series.topic.of(ar),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                  Text(
                    [
                          l.lessonsCount(context.num(total)),
                          if (heard > 0) l.lessonsHeard(context.num(heard)),
                        ].join(' · ') +
                        (complete ? ' ✓' : ''),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: DesignTokens.spaceXs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 4,
                      value: total == 0 ? 0 : heard / total,
                      color: complete ? AppTheme.of(context, 'success') : AppTheme.of(context, 'accent'),
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One series: continue / download-all buttons, then every lesson in order with ✓ for those heard.
/// The player opens right under the lesson that plays (same player as the rest of the app).
class LessonSeriesScreen extends StatefulWidget {
  const LessonSeriesScreen({
    super.key,
    required this.series,
    this.embedded = false,
    this.heroOnly = false,
    this.onOpen,
    this.openLabel,
  });
  final LessonSeries series;

  /// Inside another screen (the Sha'rawi section's parts): the lessons only, no app bar of its own.
  final bool embedded;

  /// Only the series card (title, sheikh, topic · lessons · hours, start / download), as a section of
  /// «دروس الشيخ الشعراوي» (owner 2026-11-24); tapping it calls [onOpen].
  final bool heroOnly;
  final VoidCallback? onOpen;

  /// With [heroOnly]: the main button opens the part ([onOpen]) instead of playing, and there is no
  /// download button (the Quran tafsir, chosen by surah).
  final String? openLabel;

  @override
  State<LessonSeriesScreen> createState() => _LessonSeriesScreenState();
}

class _LessonSeriesScreenState extends State<LessonSeriesScreen> {
  Set<String> _saved = {};
  int _savedVersion = 0;
  bool _bulk = false;
  bool _stop = false;
  int _bulkDone = 0;

  LessonSeries get s => widget.series;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_savedVersion == 0) _refreshSaved();
  }

  Future<void> _refreshSaved() async {
    final d = context.services.downloads;
    final saved = <String>{};
    for (final e in s.episodes) {
      try {
        if (await d.offlineFile(s.playerSeries, s.episodeId(e)) != null) saved.add(s.episodeId(e));
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _saved = saved;
      _savedVersion++;
    });
  }

  Future<void> _downloadAll() async {
    final d = context.services.downloads;
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() {
      _bulk = true;
      _stop = false;
      _bulkDone = _saved.length;
    });
    var failed = false;
    for (final e in s.episodes) {
      if (_stop || !mounted) break;
      final id = s.episodeId(e);
      if (_saved.contains(id)) continue;
      try {
        await d.downloadFile(s.playerSeries, id, e.url);
        if (!mounted) return;
        setState(() {
          _saved = {..._saved, id};
          _bulkDone = _saved.length;
          _savedVersion++;
        });
      } catch (_) {
        failed = true;
        break;
      }
    }
    if (!mounted) return;
    setState(() => _bulk = false);
    if (failed) messenger.showSnackBar(SnackBar(content: Text(l.lessonsDownloadFailed)));
  }

  void _play(List<Episode> episodes, int i) {
    final n = context.services.narration;
    final e = episodes[i];
    final on = n.episode?.id == e.id && n.episode?.url == e.url;
    if (on && n.isPlaying) {
      n.pause();
    } else if (on && n.state == RecitationState.paused) {
      n.resume();
    } else {
      PlayOrigin.remember(context, s.playerSeries);
      n.playEpisode(s.playerSeries, e, playlist: episodes);
    }
  }

  /// The series card: title, sheikh, topic · lessons · hours, start / continue and download.
  Widget _hero(BuildContext context, List<Episode> episodes, int heard, LessonEpisode? last, bool allSaved) {
    final l = context.l10n;
    final ar = context.isArabic;
    final theme = Theme.of(context);
    final open = widget.openLabel;
    return Container(
      margin: const EdgeInsets.all(DesignTokens.spaceMd),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lessonTopicColor(s.topic.id), AppTheme.brand('heroDeep')],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.title(ar),
            style: theme.textTheme.titleLarge?.copyWith(color: const Color(0xFFF3E9D2), fontWeight: FontWeight.w600),
          ),
          Text(s.sheikh.of(ar), style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFFCDD8EA))),
          const SizedBox(height: DesignTokens.spaceXs),
          Text(
            [
              s.topic.of(ar),
              l.lessonsCount(context.num(s.lessonTotal)),
              if (s.seconds > 0) context.lessonDuration(s.seconds),
              if (heard > 0) l.lessonsHeard(context.num(heard)),
              if (_saved.isNotEmpty) l.lessonsSaved(context.num(_saved.length)),
            ].join(' · '),
            key: const Key('lessonsSeriesMeta'),
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.brand('gold')),
          ),
          const SizedBox(height: DesignTokens.spaceSm),
          Wrap(
            spacing: DesignTokens.spaceSm,
            runSpacing: DesignTokens.spaceXs,
            children: [
              FilledButton.icon(
                key: const Key('lessonsContinueBtn'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.brand('gold'),
                  foregroundColor: const Color(0xFF0A1830),
                ),
                icon: Icon(open != null ? Icons.menu_book : Icons.play_arrow),
                label: Text(open ?? (last == null ? l.lessonsStart : l.lessonsContinueBtn(context.num(last.index)))),
                onPressed: open != null ? widget.onOpen : () => _play(episodes, last == null ? 0 : last.index - 1),
              ),
              if (open == null && widget.heroOnly && widget.onOpen != null)
                OutlinedButton.icon(
                  key: Key('lessonsHeroOpen.${s.id}'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  icon: const Icon(Icons.format_list_bulleted),
                  label: Text(l.lessonsAllEpisodes),
                  onPressed: widget.onOpen,
                ),
              if (open != null)
                const SizedBox.shrink()
              else if (_bulk)
                OutlinedButton.icon(
                  key: const Key('lessonsDownloadStop'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  icon: const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  label: Text(
                    '${l.lessonsDownloading(context.num(_bulkDone), context.num(s.episodes.length))} · ${l.lessonsDownloadStop}',
                  ),
                  onPressed: () => setState(() => _stop = true),
                )
              else
                OutlinedButton.icon(
                  key: const Key('lessonsDownloadAll'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                  icon: Icon(allSaved ? Icons.download_done : Icons.download_for_offline_outlined),
                  label: Text(allSaved ? l.lessonsDownloadedAll : l.lessonsDownloadAll),
                  onPressed: allSaved ? null : _downloadAll,
                ),
            ],
          ),
          if (open == null && !widget.heroOnly) ...[
            const SizedBox(height: DesignTokens.spaceXs),
            Text(l.lessonsDoneHint, style: theme.textTheme.labelSmall?.copyWith(color: const Color(0xFFCDD8EA))),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = context.isArabic;
    final theme = Theme.of(context);
    final services = context.services;
    final body = ReadableWidth(
      child: ListenableBuilder(
        listenable: Listenable.merge([services.narration, services.settings]),
        builder: (context, _) {
          final episodes = [for (final e in s.episodes) lessonEpisode(context, s, e)];
          final heard = _heard(context, s);
          final last = _lastEpisode(context, s);
          final n = services.narration;
          final allSaved = _saved.length >= s.episodes.length;
          if (widget.heroOnly) {
            return GestureDetector(
              key: Key('lessonsHero.${s.id}'),
              onTap: widget.onOpen,
              child: _hero(context, episodes, heard, last, allSaved),
            );
          }
          return ListView.builder(
            key: const Key('lessonEpisodes'),
            padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
            itemCount: s.episodes.length + 1,
            itemBuilder: (context, i) {
              if (i == 0) return _hero(context, episodes, heard, last, allSaved);
              final idx = i - 1;
              final e = s.episodes[idx];
              final ep = episodes[idx];
              final key = '${s.playerSeries}/${ep.id}';
              final done = services.settings.episodeDone(key);
              final on = n.episode?.id == ep.id && n.episode?.url == ep.url;
              final playing = on && n.isPlaying;
              final scheme = theme.colorScheme;
              final sub = [
                if (e.title != null) e.title!,
                if (e.seconds > 0) context.lessonDuration(e.seconds),
                if (done) l.lessonsDone,
              ].join(' · ');
              final tile = ListTile(
                key: Key('lesson-${ep.id}'),
                selected: on,
                leading: playing
                    ? Icon(Icons.pause_circle, color: scheme.primary, size: 32)
                    : done
                    ? Icon(
                        Icons.check_circle,
                        key: Key('lessonDone-${ep.id}'),
                        color: AppTheme.of(context, 'success'),
                        size: 32,
                      )
                    : Icon(Icons.play_circle, color: scheme.primary, size: 32),
                title: Text(context.lessonEpisodeTitle(e)),
                subtitle: sub.isEmpty ? null : Text(sub),
                trailing: OfflineButton(
                  key: ValueKey('off-${ep.id}-$_savedVersion'),
                  series: s.playerSeries,
                  episode: ep,
                ),
                onTap: () => _play(episodes, idx),
                onLongPress: () => services.settings.setEpisodeDone(key, !done),
              );
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [tile, if (on && n.isActive) const InlineNarrationPlayer(), const Divider(height: 1)],
              );
            },
          );
        },
      ),
    );
    if (widget.embedded || widget.heroOnly) return body;
    return Scaffold(
      appBar: AppBar(title: Text(s.title(ar))),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: body,
    );
  }
}
