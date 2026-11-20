import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/kids.dart';
import '../domain/quran.dart';
import '../domain/stories.dart';
import '../domain/text.dart';
import '../theme/app_theme.dart';
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
                RuqyahDua() => _Dua(key: Key('ruqyah.item.$i'), dua: item, index: i),
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
            // One flowing Mushaf paragraph, ayah after ayah (owner 2026-11-20: not one ayah per row).
            _FlowingVerses(range: range, playingRef: playingRef),
          ],
        ),
      ),
    );
  }
}

/// The ayat of [range] as one justified paragraph; the recited ayah is tinted, a tap opens the ayah sheet.
class _FlowingVerses extends StatefulWidget {
  const _FlowingVerses({required this.range, required this.playingRef});
  final StoryRange range;
  final AyahRef? playingRef;

  @override
  State<_FlowingVerses> createState() => _FlowingVersesState();
}

class _FlowingVersesState extends State<_FlowingVerses> {
  final _taps = <int, TapGestureRecognizer>{};

  TapGestureRecognizer _tap(AyahRef ref) => _taps.putIfAbsent(
    ref.ayah,
    () => TapGestureRecognizer()..onTap = () => showAyahSheet(context, ref, readAsList: false),
  );

  @override
  void dispose() {
    for (final r in _taps.values) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final scheme = Theme.of(context).colorScheme;
    final q = s.content.quran;
    final r = widget.range;
    final playing = widget.playingRef;
    if (playing != null && playing.surah == r.surah && playing.ayah >= r.from && playing.ayah <= r.to) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Scrollable.ensureVisible(context, alignment: 0.3, duration: const Duration(milliseconds: 300));
      });
    }
    return ListenableBuilder(
      listenable: s.settings,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
        child: Text.rich(
          key: Key('ruqyahFlow-${r.surah}-${r.from}'),
          TextSpan(
            children: [
              for (var a = r.from; a <= r.to; a++)
                TextSpan(
                  text: '${s.content.renderMap.forDisplay(q.text(AyahRef(r.surah, a)))}\u00A0${ayahMarker(a)} ',
                  recognizer: _tap(AyahRef(r.surah, a)),
                  style: playing == AyahRef(r.surah, a) ? TextStyle(backgroundColor: scheme.secondaryContainer) : null,
                ),
            ],
          ),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.justify,
          style: AppTheme.quran(context, s.settings.quranFontSize),
        ),
      ),
    );
  }
}

/// A dua of the ruqyah. One said more than once gets the adhkar counter (owner 2026-11-20): tap the card
/// or the circle for each time; it turns into a tick when done.
class _Dua extends StatefulWidget {
  const _Dua({super.key, required this.dua, required this.index});
  final RuqyahDua dua;
  final int index;

  @override
  State<_Dua> createState() => _DuaState();
}

class _DuaState extends State<_Dua> {
  int _n = 0;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dua = widget.dua;
    final audio = dua.audio;
    final counted = dua.repeat > 1;
    final done = counted && _n >= dua.repeat;
    void count() {
      if (!counted || done) return;
      HapticFeedback.selectionClick();
      setState(() => _n++);
    }

    final body = Padding(
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.ruqyahDua, style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary)),
          const SizedBox(height: DesignTokens.spaceSm),
          Text(dua.text, textDirection: TextDirection.rtl, style: duaStyle(context, size: 20)),
          const SizedBox(height: DesignTokens.spaceSm),
          Wrap(
            spacing: DesignTokens.spaceMd,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (dua.source.isNotEmpty) Text(dua.source, style: theme.textTheme.bodySmall),
              if (counted)
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
          if (counted) ...[
            const SizedBox(height: DesignTokens.spaceMd),
            Center(
              child: Container(
                key: Key('ruqyah.count.${widget.index}'),
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? scheme.primary : scheme.primaryContainer,
                  border: Border.all(color: scheme.secondary.withValues(alpha: 0.6), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: scheme.primary.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: done
                    ? RIcon(RIcons.check, size: 40, color: scheme.onPrimary)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.num('$_n'),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: scheme.onPrimaryContainer,
                              height: 1.1,
                            ),
                          ),
                          Text(
                            '/ ${context.num('${dua.repeat}')}',
                            style: TextStyle(fontSize: 14, color: scheme.onPrimaryContainer),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceXs),
            Text(
              done ? l.adhkarDone : l.adhkarRemaining(context.num(dua.repeat - _n)),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            if (_n > 0)
              Center(
                child: TextButton.icon(
                  icon: const RIcon(RIcons.reset, size: 18),
                  label: Text(l.adhkarReset),
                  onPressed: () => setState(() => _n = 0),
                ),
              ),
          ],
        ],
      ),
    );
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      color: done ? scheme.surfaceContainer : null,
      clipBehavior: Clip.antiAlias,
      child: counted ? InkWell(onTap: done ? null : count, child: body) : body,
    );
  }
}
