import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../data/settings.dart';
import '../domain/audio_queue.dart';
import '../domain/quran.dart';
import '../domain/tafsir.dart';
import '../domain/text.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'mushaf_page.dart';
import 'review_notice.dart';
import 'widgets.dart';
import 'r_icon.dart';

/// المصحف / الآيات / التفسير.
enum ReaderTab { mushaf, ayat, tafsir }

/// Segmented control at the top of the Mushaf reader.
class ReaderTabs extends StatelessWidget {
  const ReaderTabs({super.key, required this.tab, required this.onChanged});
  final ReaderTab tab;
  final ValueChanged<ReaderTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final labels = {
      ReaderTab.mushaf: l.readerTabMushaf,
      ReaderTab.ayat: l.readerTabAyat,
      ReaderTab.tafsir: l.readerTabTafsir,
    };
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Color.alphaBlend(scheme.onSurface.withValues(alpha: 0.08), scheme.surface),
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final e in labels.entries)
            Semantics(
              selected: e.key == tab,
              button: true,
              child: InkWell(
                key: Key('readerTab-${e.key.name}'),
                borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                onTap: () => onChanged(e.key),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  constraints: const BoxConstraints(minWidth: 60, minHeight: 54),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm + 4),
                  decoration: BoxDecoration(
                    color: e.key == tab ? scheme.surface : Colors.transparent,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                    boxShadow: e.key == tab
                        ? const [BoxShadow(color: Color(0x22000000), blurRadius: 3, offset: Offset(0, 1))]
                        : null,
                  ),
                  child: Text(
                    e.value,
                    style: TextStyle(
                      fontWeight: e.key == tab ? FontWeight.w600 : FontWeight.w400,
                      color: e.key == tab ? scheme.primary : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The reader's recitation card: reciter (tap to choose), "Listen with
/// tafsir", previous / play-pause / next, repeat count and stop. While nothing
/// is queued, play starts the current page.
class ReaderPlayerCard extends StatelessWidget {
  const ReaderPlayerCard({super.key, required this.page});
  final int page;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final rec = s.recitation;
    final settings = s.settings;
    return ListenableBuilder(
      listenable: Listenable.merge([rec, settings]),
      builder: (context, _) {
        final l = context.l10n;
        final scheme = Theme.of(context).colorScheme;
        final active = rec.isActive;
        final error = rec.state == RecitationState.error;
        final withTafsir = settings.tafsirWithRecitation;
        final item = rec.current;
        String now;
        if (item == null) {
          now = l.mushafSlider(context.num(page));
        } else if (item.isBasmala) {
          now = '${l.audioBasmala} · ${surahName(context, s.content.quran.surah(item.ref.surah))}';
        } else {
          now = ayahLabel(context, item.ref);
        }
        void play() {
          if (!active) {
            unawaited(rec.playPage(page));
          } else if (rec.state == RecitationState.playing) {
            unawaited(rec.pause());
          } else {
            unawaited(rec.resume());
          }
        }

        final playIcon = !active || rec.state == RecitationState.paused
            ? RIcons.play
            : (error ? RIcons.refresh : RIcons.pause);
        final repeat = settings.repeat;
        // Short screens: one row (the reciter opens from the round button) so the page keeps its 15 lines.
        final compact = MediaQuery.sizeOf(context).height < 700;
        return Container(
          key: const Key('miniPlayer'),
          margin: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, 0, DesignTokens.spaceMd, DesignTokens.spaceXs),
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, DesignTokens.spaceXs, DesignTokens.spaceMd, 0),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: scheme.outline),
            boxShadow: const [BoxShadow(color: Color(0x24000000), blurRadius: 18, offset: Offset(0, 4))],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!compact)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primary,
                      child: RIcon(RIcons.reciter, size: 18, color: scheme.onPrimary),
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Flexible(
                      child: InkWell(
                        key: const Key('reciterButton'),
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => showReciterPicker(context),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  rec.reciter.name(context.isArabic),
                                  key: const Key('reciterName'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 4),
                              RIcon(RIcons.chevronDown, size: 18, color: scheme.primary),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spaceSm),
                    Expanded(
                      child: Text(
                        error ? l.audioOffline : now,
                        key: const Key('miniPlayerTitle'),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: error ? scheme.error : scheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              LayoutBuilder(
                builder: (context, c) {
                  // Very narrow phones: the controls keep their size and the row is scaled down to fit.
                  const minRow = 340.0;
                  final row = Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (compact)
                        IconButton(
                          key: const Key('reciterButton'),
                          tooltip: '${l.audioReciter}: ${rec.reciter.name(context.isArabic)}',
                          color: scheme.primary,
                          icon: const RIcon(RIcons.reciter),
                          onPressed: () => showReciterPicker(context),
                        ),
                      Flexible(
                        child: LayoutBuilder(
                          builder: (context, c) {
                            void toggle() {
                              unawaited(settings.setTafsirWithRecitation(!withTafsir));
                              // "Listen with tafsir" also starts listening when nothing plays yet.
                              if (!withTafsir && !active) unawaited(rec.playPage(page));
                            }

                            final style = TextButton.styleFrom(
                              backgroundColor: withTafsir ? scheme.primary : null,
                              foregroundColor: withTafsir ? scheme.onPrimary : scheme.primary,
                              minimumSize: const Size(48, 48),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            );
                            const icon = RIcon(RIcons.split, size: 20);
                            // Narrow phones: the icon alone (the label stays as its tooltip).
                            if (c.maxWidth < 100) {
                              return Tooltip(
                                message: l.readerListenWithTafsir,
                                child: TextButton(
                                  key: const Key('audioTafsirToggle'),
                                  style: style,
                                  onPressed: toggle,
                                  child: icon,
                                ),
                              );
                            }
                            return TextButton.icon(
                              key: const Key('audioTafsirToggle'),
                              style: style,
                              onPressed: toggle,
                              icon: icon,
                              label: Text(
                                l.readerListenWithTafsir,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12, height: 1.2),
                              ),
                            );
                          },
                        ),
                      ),
                      IconButton(
                        key: const Key('audioPrev'),
                        tooltip: l.audioPrevious,
                        icon: const RIcon(RIcons.prev),
                        color: scheme.primary,
                        onPressed: active ? rec.previous : null,
                      ),
                      IconButton.filled(
                        key: Key(active ? 'audioPlayPause' : 'playPage'),
                        tooltip: active
                            ? (rec.state == RecitationState.paused ? l.audioPlay : l.audioPause)
                            : l.mushafPlayPage,
                        iconSize: 30,
                        icon: RIcon(playIcon),
                        onPressed: play,
                      ),
                      IconButton(
                        key: const Key('audioNext'),
                        tooltip: l.audioNext,
                        icon: const RIcon(RIcons.next),
                        color: scheme.primary,
                        onPressed: active ? rec.next : null,
                      ),
                      Badge(
                        isLabelVisible: repeat > 1,
                        label: Text(context.num(repeat)),
                        backgroundColor: scheme.secondary,
                        child: IconButton(
                          key: const Key('audioRepeat'),
                          tooltip: l.readerRepeatN(context.num(repeat)),
                          icon: const RIcon(RIcons.repeat),
                          color: scheme.primary,
                          onPressed: () {
                            const choices = SettingsController.repeatChoices;
                            final i = choices.indexOf(repeat);
                            unawaited(settings.setRepeat(choices[(i + 1) % choices.length]));
                          },
                        ),
                      ),
                      if (active)
                        IconButton(
                          key: const Key('audioStop'),
                          tooltip: l.audioStop,
                          icon: const RIcon(RIcons.close, size: 20),
                          onPressed: rec.stop,
                        ),
                    ],
                  );
                  if (c.maxWidth >= minRow) return row;
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(width: minRow, child: row),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bottom sheet listing the reciters; the choice applies at once.
Future<void> showReciterPicker(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) {
    final s = context.services;
    final current = s.content.reciters.byFolder(s.settings.reciter).folder;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: ListView(
          key: const Key('reciterPicker'),
          shrinkWrap: true,
          children: [
            ListTile(title: Text(context.l10n.audioReciter, style: Theme.of(context).textTheme.titleMedium)),
            for (final r in s.content.reciters.reciters)
              ListTile(
                key: Key('reciter-${r.folder}'),
                leading: RIcon(r.folder == current ? RIcons.radioOn : RIcons.radioOff),
                title: Text(r.name(context.isArabic)),
                onTap: () {
                  unawaited(s.settings.setReciter(r.folder));
                  Navigator.of(context).pop();
                },
              ),
          ],
        ),
      ),
    );
  },
);

/// Quran text of an ayah followed by its numbered marker.
class AyahTextBlock extends StatelessWidget {
  const AyahTextBlock({super.key, required this.ref, required this.size, this.highlight});
  final AyahRef ref;
  final double size;
  final Color? highlight;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final ink = AppTheme.of(context, 'paperInk');
    final text = s.content.renderMap.forDisplay(s.content.quran.text(ref));
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(backgroundColor: highlight),
          ),
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: AyahMarker(
              number: ref.ayah,
              size: size * 1.15,
              color: Theme.of(context).colorScheme.primary,
              ink: ink,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.rtl,
      style: TextStyle(fontFamily: DesignTokens.fontQuran, fontSize: size, height: 2.0, color: ink),
    );
  }
}

/// "الآيات" and "التفسير": the ayahs of [page] one by one (with the tafsir
/// box under each when [withTafsir]). Tapping an ayah calls [onAyahTap]; the
/// recited ayah is highlighted and kept in view.
class PageAyahList extends StatefulWidget {
  const PageAyahList({super.key, required this.page, required this.withTafsir, required this.onAyahTap, this.selected});
  final int page;
  final bool withTafsir;
  final ValueChanged<AyahRef> onAyahTap;
  final AyahRef? selected;

  @override
  State<PageAyahList> createState() => _PageAyahListState();
}

class _PageAyahListState extends State<PageAyahList> {
  final _keys = <AyahRef, GlobalKey>{};
  Future<TafsirContent>? _tafsir;
  AyahRef? _followed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tafsir ??= context.services.tafsir.load();
  }

  void _follow(AyahRef? playing) {
    if (playing == null || playing == _followed) return;
    _followed = playing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[playing]?.currentContext;
      if (ctx != null && ctx.mounted) {
        unawaited(Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), alignment: 0.1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final q = s.content.quran;
    final refs = q.ayahsOnPage(widget.page);
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([s.recitation, s.settings]),
      builder: (context, _) {
        final playing = s.recitation.currentRef;
        _follow(playing);
        final size = s.settings.quranFontSize;
        return FutureBuilder<TafsirContent>(
          future: _tafsir,
          initialData: s.tafsir.loaded,
          builder: (context, snap) => ListView.builder(
            key: Key(widget.withTafsir ? 'tafsirList' : 'ayatList'),
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, 0, DesignTokens.spaceMd, DesignTokens.spaceLg),
            itemCount: refs.length,
            itemBuilder: (context, i) {
              final r = refs[i];
              final isPlaying = r == playing;
              final isSelected = r == widget.selected;
              final tafsir = snap.data?.text(r.surah, r.ayah);
              return Container(
                key: _keys.putIfAbsent(r, GlobalKey.new),
                margin: const EdgeInsets.only(top: DesignTokens.spaceSm),
                decoration: BoxDecoration(
                  color: isPlaying ? scheme.secondaryContainer : null,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: isSelected ? scheme.primary : Colors.transparent, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (r.ayah == 1) ...[
                      SizedBox(
                        height: size * 1.9,
                        child: SurahBand(surah: r.surah, font: size, height: size * 1.9),
                      ),
                      if (basmalaBeforeSurah(r.surah))
                        Text(
                          s.content.renderMap.forDisplay(q.text(const AyahRef(1, 1))),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: TextStyle(fontFamily: DesignTokens.fontQuran, fontSize: size * 0.9, height: 2),
                        ),
                    ],
                    InkWell(
                      key: Key('listAyah-${r.surah}-${r.ayah}'),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      onTap: () => widget.onAyahTap(r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXs),
                        child: AyahTextBlock(ref: r, size: size),
                      ),
                    ),
                    if (widget.withTafsir)
                      Container(
                        key: Key('listTafsir-${r.surah}-${r.ayah}'),
                        margin: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                        padding: const EdgeInsets.all(DesignTokens.spaceMd),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                        ),
                        child: Text(
                          tafsir ?? (snap.hasError ? context.l10n.tafsirError : context.l10n.tafsirLoading),
                          textDirection: TextDirection.rtl,
                          style: duaStyle(context, size: (size * 0.66).clamp(14, 26)),
                        ),
                      )
                    else
                      Divider(color: scheme.outlineVariant),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// "Listen with tafsir": the screen in two halves — the ayah being recited
/// (highlighted) and its Tafsir al-Muyassar under it. Follows the recitation.
class SplitRecitationView extends StatefulWidget {
  const SplitRecitationView({super.key});

  @override
  State<SplitRecitationView> createState() => _SplitRecitationViewState();
}

class _SplitRecitationViewState extends State<SplitRecitationView> {
  Future<TafsirContent>? _tafsir;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tafsir ??= context.services.tafsir.load();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListenableBuilder(
      listenable: s.recitation,
      builder: (context, _) {
        final item = s.recitation.current;
        final basmala = item?.isBasmala ?? false;
        final ref = item == null || basmala ? null : item.ref;
        final size = s.settings.quranFontSize + 4;
        final hl = AppTheme.of(context, 'accentSoft');
        final label = ref != null ? ayahLabel(context, ref) : (basmala ? l.readerBasmalaNow : '');
        return Padding(
          key: const Key('splitView'),
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, 0, DesignTokens.spaceMd, DesignTokens.spaceSm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  key: const Key('splitAyah'),
                  decoration: BoxDecoration(
                    color: AppTheme.of(context, 'paper'),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(color: scheme.primary, width: 2),
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spaceMd,
                    DesignTokens.spaceXs,
                    DesignTokens.spaceMd,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Text(l.readerSplitTitle, style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Expanded(
                            child: Text(
                              label,
                              key: const Key('splitAyahLabel'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          TextButton(
                            key: const Key('splitShowPage'),
                            onPressed: () => s.settings.setTafsirWithRecitation(false),
                            child: Text(l.readerShowPage),
                          ),
                        ],
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          key: ValueKey('splitAyahScroll-$ref'),
                          child: Center(
                            child: ref != null
                                ? AyahTextBlock(key: const Key('splitAyahText'), ref: ref, size: size, highlight: hl)
                                : (basmala
                                      ? Text(
                                          s.content.renderMap.forDisplay(s.content.quran.text(const AyahRef(1, 1))),
                                          textDirection: TextDirection.rtl,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontFamily: DesignTokens.fontQuran,
                                            fontSize: size,
                                            height: 2,
                                            backgroundColor: hl,
                                            color: AppTheme.of(context, 'paperInk'),
                                          ),
                                        )
                                      : const SizedBox.shrink()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Expanded(
                child: Container(
                  key: const Key('recitationTafsir'),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                  padding: const EdgeInsets.all(DesignTokens.spaceMd),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l.tafsirTitle,
                        key: const Key('recitationTafsirTitle'),
                        style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
                      ),
                      Text(l.tafsirSource, style: theme.textTheme.bodySmall),
                      if (!context.isArabic)
                        Text(
                          l.tafsirArabicOnly,
                          style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      Expanded(
                        child: FutureBuilder<TafsirContent>(
                          future: _tafsir,
                          initialData: s.tafsir.loaded,
                          builder: (context, snap) {
                            if (ref == null) return const SizedBox.shrink();
                            final text = snap.data?.text(ref.surah, ref.ayah);
                            if (text == null) {
                              return Text(
                                snap.hasError ? l.tafsirError : l.tafsirLoading,
                                key: const Key('recitationTafsirStatus'),
                              );
                            }
                            return SingleChildScrollView(
                              key: ValueKey('recitationTafsirScroll-${ref.surah}-${ref.ayah}'),
                              child: Text(
                                text,
                                key: const Key('recitationTafsirText'),
                                textDirection: TextDirection.rtl,
                                style: duaStyle(context, size: 17),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// "الختمة": progress of the current khatma and where to continue.
Future<void> showKhatmaSheet(BuildContext context, {required ValueChanged<int> onGo}) => showModalBottomSheet<void>(
  context: context,
  builder: (sheetContext) {
    final s = sheetContext.services;
    return SafeArea(
      child: ListenableBuilder(
        listenable: s.settings,
        builder: (context, _) {
          final l = context.l10n;
          final theme = Theme.of(context);
          final k = s.settings.khatma;
          final children = <Widget>[Text(l.readerKhatmaTitle, style: theme.textTheme.titleLarge)];
          if (k == null) {
            children.addAll([
              const SizedBox(height: DesignTokens.spaceSm),
              Text(l.readerKhatmaNone),
              const SizedBox(height: DesignTokens.spaceMd),
              FilledButton(
                key: const Key('khatmaStart'),
                onPressed: () async {
                  await s.settings.startKhatma(DateTime.now());
                  if (context.mounted) Navigator.of(context).pop();
                  onGo(1);
                },
                child: Text(l.readerKhatmaStart),
              ),
            ]);
          } else {
            final next = k.next;
            final date = MaterialLocalizations.of(context).formatMediumDate(k.startedAt);
            children.addAll([
              const SizedBox(height: DesignTokens.spaceMd),
              LinearProgressIndicator(
                value: k.done / k.pageCount,
                minHeight: 10,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                l.readerKhatmaProgress(context.num(k.done), context.num(k.percent)),
                key: const Key('khatmaProgress'),
              ),
              Text(
                '${next == null ? l.readerKhatmaDone : l.readerKhatmaLeft(context.num(k.left))} · ${l.readerKhatmaSince(date)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: DesignTokens.spaceMd),
              Wrap(
                spacing: DesignTokens.spaceSm,
                children: [
                  if (next != null)
                    FilledButton(
                      key: const Key('khatmaContinue'),
                      onPressed: () {
                        Navigator.of(context).pop();
                        onGo(next);
                      },
                      child: Text(l.readerKhatmaContinue(context.num(next))),
                    ),
                  OutlinedButton(
                    key: const Key('khatmaReset'),
                    onPressed: s.settings.clearKhatma,
                    child: Text(l.readerKhatmaReset),
                  ),
                ],
              ),
            ]);
          }
          return Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceLg),
            child: Column(
              key: const Key('khatmaSheet'),
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
        },
      ),
    );
  },
);

/// Help sheet: how to use the reader, and go to a page by number.
Future<void> showReaderHelp(BuildContext context, {required int pageCount, required ValueChanged<int> onGo}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          child: _HelpBody(pageCount: pageCount, onGo: onGo),
        ),
      ),
    );

class _HelpBody extends StatefulWidget {
  const _HelpBody({required this.pageCount, required this.onGo});
  final int pageCount;
  final ValueChanged<int> onGo;

  @override
  State<_HelpBody> createState() => _HelpBodyState();
}

class _HelpBodyState extends State<_HelpBody> {
  final _input = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _go() {
    final p = parsePageNumber(_input.text, max: widget.pageCount);
    if (p == null) {
      setState(() => _error = context.l10n.quranPageInvalid);
      return;
    }
    Navigator.of(context).pop();
    widget.onGo(p);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SingleChildScrollView(
      key: const Key('readerHelpSheet'),
      padding: const EdgeInsets.all(DesignTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.readerHelpTitle, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: DesignTokens.spaceSm),
          for (final h in [l.readerHelp1, l.readerHelp2, l.readerHelp3])
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXs),
              child: Text('• $h'),
            ),
          const SizedBox(height: DesignTokens.spaceMd),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  key: const Key('goToPageField'),
                  controller: _input,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _go(),
                  decoration: InputDecoration(
                    labelText: l.quranGoToPage,
                    hintText: l.quranPageNumberHint,
                    errorText: _error,
                    errorMaxLines: 3,
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              FilledButton(key: const Key('goToPageButton'), onPressed: _go, child: Text(l.quranGo)),
            ],
          ),
        ],
      ),
    );
  }
}
