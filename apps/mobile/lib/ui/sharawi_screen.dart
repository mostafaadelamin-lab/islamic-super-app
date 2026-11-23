import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/lessons.dart';
import '../domain/sharawi.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'l10n_ext.dart';
import 'lessons_screen.dart' show LessonSeriesScreen, loadLessons;
import 'library_screen.dart' show PlayTile;
import 'r_icon.dart';
import 'stories_screen.dart' show NarrationBar;

const sharawiSeries = 'sharawi';

Future<SharawiTafsir> loadSharawi() async =>
    SharawiTafsir.parse(await rootBundle.loadString('assets/content/sharawi.v1.json'));

String _norm(String s) =>
    s.replaceAll(RegExp('[ًٌٍَُِّْـ]'), '').replaceAll(RegExp('[أإآٱ]'), 'ا').replaceAll('ى', 'ي').replaceAll('ة', 'ه');

extension on BuildContext {
  String sharawiSurahName(int n) {
    if (n == 0) return l10n.sharawiIntro;
    final s = services.content.quran.surahs[n - 1];
    return isArabic ? s.nameAr : s.nameEn;
  }

  String sharawiLessonTitle(SharawiLesson x) => l10n.sharawiLesson(this.num(x.index));

  String sharawiLessonSubtitle(SharawiLesson x) {
    final parts = <String>[
      if (x.hasRange)
        x.from == x.to ? l10n.sharawiAyah(this.num(x.from!)) : l10n.sharawiAyahs(this.num(x.from!), this.num(x.to!)),
      if ((x.seconds ?? 0) > 0) l10n.sharawiMinutes(this.num(((x.seconds!) / 60).round())),
    ];
    return parts.join(' · ');
  }
}

/// Episode for the shared audio player (streams, or plays the offline copy).
Episode sharawiEpisode(BuildContext context, SharawiLesson x) {
  final title =
      '${context.l10n.sharawiTitle} · ${context.sharawiSurahName(x.surah)} · ${context.sharawiLessonTitle(x)}';
  return Episode(
    id: 'sharawi-${x.id}',
    titleAr: title,
    titleEn: title,
    url: x.url,
    durationSec: x.seconds,
    status: ReviewStatus.approved,
  );
}

/// The three parts of the Sha'rawi section (owner 2026-11-23): Quran tafsir, the Prophet's life, prophets' stories.
enum SharawiPart { tafsir, seerah, anbiya }

/// "تفسير الشعراوي": the surahs the sheikh's recorded lessons cover, with search; and his seerah and
/// prophets' stories series (from the lesson-series list) as the section's other two parts.
class SharawiScreen extends StatefulWidget {
  const SharawiScreen({super.key, this.loader = loadSharawi, this.lessonsLoader = loadLessons, this.part});
  final Future<SharawiTafsir> Function() loader;
  final Future<LessonCatalog> Function() lessonsLoader;
  final SharawiPart? part;

  @override
  State<SharawiScreen> createState() => _SharawiScreenState();
}

class _SharawiScreenState extends State<SharawiScreen> {
  late final Future<SharawiTafsir> _future = widget.loader();
  Future<LessonCatalog>? _lessons;
  late SharawiPart _part = widget.part ?? SharawiPart.tafsir;
  String _query = '';

  static const _seriesOf = {SharawiPart.seerah: 'seerah-shaarawi', SharawiPart.anbiya: 'anbiya-shaarawi'};

  Widget _parts(BuildContext context) {
    final l = context.l10n;
    final labels = {
      SharawiPart.tafsir: l.sharawiPartTafsir,
      SharawiPart.seerah: l.sharawiPartSeerah,
      SharawiPart.anbiya: l.sharawiPartAnbiya,
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, 0),
      child: Row(
        children: [
          for (final p in SharawiPart.values)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceSm),
              child: ChoiceChip(
                key: Key('sharawiPart.${p.name}'),
                label: Text(labels[p]!),
                selected: _part == p,
                onSelected: (_) => setState(() => _part = p),
              ),
            ),
        ],
      ),
    );
  }

  Widget _series(BuildContext context) {
    final l = context.l10n;
    final future = _lessons ??= widget.lessonsLoader();
    return FutureBuilder<LessonCatalog>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text(l.sharawiLoadError));
        final c = snap.data;
        if (c == null) return const Center(child: CircularProgressIndicator());
        final s = c.sharawiById(_seriesOf[_part]!);
        if (s == null) return Center(child: Text(l.sharawiLoadError));
        return LessonSeriesScreen(key: Key('sharawiSeries.${s.id}'), series: s, embedded: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.sharawiSection)),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReadableWidth(child: _parts(context)),
          Expanded(child: _part == SharawiPart.tafsir ? _tafsir(context) : _series(context)),
        ],
      ),
    );
  }

  Widget _tafsir(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    return ReadableWidth(
      child: FutureBuilder<SharawiTafsir>(
        future: _future,
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text(l.sharawiLoadError));
          final all = snap.data;
          if (all == null) return const Center(child: CircularProgressIndicator());
          final q = _norm(_query.trim().toLowerCase());
          final surahs = [
            for (final s in all.surahs)
              if (q.isEmpty ||
                  _norm(context.sharawiSurahName(s.surah).toLowerCase()).contains(q) ||
                  '${s.surah}' == q ||
                  context.num(s.surah) == q)
                s,
          ];
          return ListView(
            key: const Key('sharawiList'),
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
                  l.sharawiNote(context.num(all.lessonCount)),
                  key: const Key('sharawiNote'),
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                child: TextField(
                  key: const Key('sharawiSearch'),
                  decoration: InputDecoration(
                    prefixIcon: const RIcon(RIcons.search),
                    hintText: l.sharawiSearch,
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              for (final s in surahs)
                Card(
                  key: Key('sharawiSurah.${s.surah}'),
                  margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
                  child: ListTile(
                    leading: s.surah == 0
                        ? const RIconBadge(RIcons.headphones)
                        : CircleAvatar(child: Text(context.num(s.surah))),
                    title: Text(context.sharawiSurahName(s.surah), style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(l.sharawiLessons(context.num(s.lessons.length))),
                    trailing: const RIcon(RIcons.chevronForward),
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => SharawiSurahScreen(surah: s))),
                  ),
                ),
              if (surahs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Text(l.sharawiNoMatch, key: const Key('sharawiEmpty')),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One surah's lessons: tap to listen (resumes where you stopped), download icon for offline.
class SharawiSurahScreen extends StatelessWidget {
  const SharawiSurahScreen({super.key, required this.surah});
  final SharawiSurah surah;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.sharawiSurahName(surah.surah))),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: context.services.narration,
          builder: (context, _) {
            // The surah's lessons in order: one lesson goes straight on to the next.
            final episodes = [for (final x in surah.lessons) sharawiEpisode(context, x)];
            return ListView.separated(
              key: const Key('sharawiLessons'),
              padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
              itemCount: surah.lessons.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final x = surah.lessons[i];
                final sub = context.sharawiLessonSubtitle(x);
                return PlayTile(
                  key: Key('sharawi-${x.id}'),
                  series: sharawiSeries,
                  offline: true,
                  title: context.sharawiLessonTitle(x),
                  subtitle: sub.isEmpty ? null : sub,
                  episode: episodes[i],
                  playlist: episodes,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
