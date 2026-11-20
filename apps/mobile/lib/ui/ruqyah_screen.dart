import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/kids.dart';
import '../domain/quran.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'ayah_sheet.dart';
import 'dhikr_audio.dart';
import 'l10n_ext.dart';
import 'library_screen.dart' show PlayTile;
import 'r_icon.dart';
import 'review_notice.dart' show duaStyle;
import 'stories_screen.dart' show NarrationBar;
import 'widgets.dart';

Future<KidsContent> loadKids() async => KidsContent.parse(await rootBundle.loadString('assets/content/kids.v1.json'));

/// "الرقية الشرعية" (adhkar) and "الرقية الشرعية للأطفال" (adhkar + kids): the Quran
/// passages in the Mushaf text, recited with the chosen reciter, and the duas of the
/// Sunnah (with their recording where there is one). Owner, 2026-11-20.
class RuqyahScreen extends StatelessWidget {
  const RuqyahScreen({super.key, this.kids = false, this.loader = loadKids});
  final bool kids;
  final Future<KidsContent> Function() loader;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return StopDhikrAudioOnExit(
      child: Scaffold(
        appBar: AppBar(title: Text(kids ? l.ruqyahKidsTitle : l.ruqyahTitle)),
        bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
        body: ReadableWidth(
          child: FutureBuilder<KidsContent>(
            future: loader(),
            builder: (context, snap) {
              final k = snap.data;
              if (k == null) return const Center(child: CircularProgressIndicator());
              return _RuqyahList(ruqyah: kids ? k.ruqyahKids : k.ruqyah, kids: kids);
            },
          ),
        ),
      ),
    );
  }
}

class _RuqyahList extends StatelessWidget {
  const _RuqyahList({required this.ruqyah, required this.kids});
  final Ruqyah ruqyah;
  final bool kids;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final q = s.content.quran;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([s.recitation, s.narration]),
      builder: (context, _) {
        final cur = s.recitation.current;
        final playingRef = cur != null && !cur.isBasmala && ruqyah.contains(cur.ref) ? cur.ref : null;
        final full = ruqyah.full;
        return ListView(
          key: Key(kids ? 'ruqyahKids' : 'ruqyah'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            Padding(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(kids ? l.ruqyahKidsNote : l.ruqyahNote, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: DesignTokens.spaceMd),
                  FilledButton.icon(
                    key: const Key('ruqyah.play'),
                    icon: const RIcon(RIcons.play),
                    label: Text(l.ruqyahListenQuran),
                    onPressed: () => s.recitation.playRanges(ruqyah.quranRanges),
                  ),
                ],
              ),
            ),
            if (full != null)
              Card(
                margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
                child: PlayTile(
                  key: const Key('ruqyah.full'),
                  series: 'ruqyah',
                  offline: true,
                  title: l.ruqyahFull,
                  subtitle: l.ruqyahFullSub(context.num(full.minutes ?? 0)),
                  episode: Episode(
                    id: full.id,
                    titleAr: l.ruqyahFull,
                    titleEn: l.ruqyahFull,
                    url: full.url,
                    durationSec: full.seconds,
                    status: ReviewStatus.approved,
                  ),
                ),
              ),
            for (final (i, item) in ruqyah.items.indexed)
              switch (item) {
                RuqyahQuran(:final range) => _QuranPassage(
                  key: Key('ruqyah.item.$i'),
                  range: range,
                  playingRef: playingRef,
                  title: range.from == range.to
                      ? l.ruqyahAyah(surahName(context, q.surah(range.surah)), context.num(range.from))
                      : l.ruqyahFrom(
                          surahName(context, q.surah(range.surah)),
                          context.num(range.from),
                          context.num(range.to),
                        ),
                ),
                RuqyahDua() => _Dua(key: Key('ruqyah.item.$i'), dua: item),
              },
          ],
        );
      },
    );
  }
}

class _QuranPassage extends StatelessWidget {
  const _QuranPassage({super.key, required this.range, required this.playingRef, required this.title});
  final StoryRange range;
  final AyahRef? playingRef;
  final String title;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final theme = Theme.of(context);
    final q = s.content.quran;
    final whole = range.from == 1 && range.to == q.surah(range.surah).ayahCount;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: DesignTokens.spaceLg),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
                ),
                IconButton(
                  key: Key('ruqyah.listen-${range.surah}-${range.from}'),
                  tooltip: context.l10n.kidsListen,
                  icon: const RIcon(RIcons.headphones),
                  onPressed: () => s.recitation.playRanges([range]),
                ),
              ],
            ),
            // A whole surah other than al-Fatiha (whose first ayah is the basmala) starts with the basmala.
            if (whole && range.surah != 1 && range.surah != 9)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                child: QuranText(q.text(const AyahRef(1, 1)), textAlign: TextAlign.center),
              ),
            for (var a = range.from; a <= range.to; a++)
              _Verse(ref: AyahRef(range.surah, a), playing: playingRef == AyahRef(range.surah, a)),
          ],
        ),
      ),
    );
  }
}

class _Verse extends StatelessWidget {
  const _Verse({required this.ref, required this.playing});
  final AyahRef ref;
  final bool playing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tile = InkWell(
      key: Key('ruqyahVerse-${ref.surah}-${ref.ayah}'),
      onTap: () => showAyahSheet(context, ref, readAsList: false),
      child: Container(
        color: playing ? scheme.secondaryContainer : null,
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
        child: QuranText(context.services.content.quran.text(ref), ayahNumber: ref.ayah),
      ),
    );
    if (!playing) return tile;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Scrollable.ensureVisible(context, alignment: 0.3, duration: const Duration(milliseconds: 300));
      }
    });
    return Semantics(selected: true, child: tile);
  }
}

class _Dua extends StatelessWidget {
  const _Dua({super.key, required this.dua});
  final RuqyahDua dua;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final audio = dua.audio;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.ruqyahDua, style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(dua.text, textDirection: TextDirection.rtl, style: duaStyle(context, size: 20)),
            const SizedBox(height: DesignTokens.spaceSm),
            Wrap(
              spacing: DesignTokens.spaceMd,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (dua.source.isNotEmpty) Text(dua.source, style: theme.textTheme.bodySmall),
                if (dua.repeat > 1)
                  Text(
                    l.ruqyahRepeat(context.num(dua.repeat)),
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            if (audio != null) ...[
              const SizedBox(height: DesignTokens.spaceSm),
              DhikrListenButton(url: audio, compact: true),
            ],
          ],
        ),
      ),
    );
  }
}
