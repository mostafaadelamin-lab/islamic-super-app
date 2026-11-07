import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../data/settings.dart';
import '../domain/quran.dart';
import '../domain/tafsir.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';
import 'widgets.dart';

/// Mini player shown while a recitation is active: what is playing, previous /
/// play-pause / next / stop, and a clear message when the audio cannot load.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final rec = context.services.recitation;
    final settings = context.services.settings;
    return ListenableBuilder(
      listenable: Listenable.merge([rec, settings]),
      builder: (context, _) {
        if (!rec.isActive) return const SizedBox.shrink();
        final withTafsir = settings.tafsirWithRecitation;
        final l = context.l10n;
        final scheme = Theme.of(context).colorScheme;
        final item = rec.current!;
        final title = item.isBasmala
            ? '${l.audioBasmala} · ${surahName(context, context.services.content.quran.surah(item.ref.surah))}'
            : ayahLabel(context, item.ref);
        final error = rec.state == RecitationState.error;
        final player = Material(
          key: const Key('miniPlayer'),
          color: scheme.surfaceContainer,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outline)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: DesignTokens.spaceXs),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('audioTafsirToggle'),
                    tooltip: l.audioTafsirToggle,
                    isSelected: withTafsir,
                    icon: Icon(Icons.menu_book_outlined, color: scheme.primary),
                    selectedIcon: Icon(Icons.menu_book, color: scheme.onPrimary),
                    style: IconButton.styleFrom(backgroundColor: withTafsir ? scheme.primary : null),
                    onPressed: () => settings.setTafsirWithRecitation(!withTafsir),
                  ),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          error ? l.audioOffline : title,
                          key: const Key('miniPlayerTitle'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: error ? scheme.error : null,
                          ),
                        ),
                        if (!error)
                          Text(
                            rec.state == RecitationState.loading ? l.audioLoading : rec.reciter.name(context.isArabic),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                  if (!error)
                    IconButton(
                      key: const Key('audioPrev'),
                      tooltip: l.audioPrevious,
                      icon: const Icon(Icons.skip_previous),
                      onPressed: rec.previous,
                    ),
                  IconButton.filledTonal(
                    key: const Key('audioPlayPause'),
                    tooltip: error ? l.commonRetry : (rec.state == RecitationState.paused ? l.audioPlay : l.audioPause),
                    icon: Icon(
                      error ? Icons.refresh : (rec.state == RecitationState.paused ? Icons.play_arrow : Icons.pause),
                    ),
                    onPressed: rec.state == RecitationState.playing ? rec.pause : rec.resume,
                  ),
                  if (!error)
                    IconButton(
                      key: const Key('audioNext'),
                      tooltip: l.audioNext,
                      icon: const Icon(Icons.skip_next),
                      onPressed: rec.next,
                    ),
                  IconButton(
                    key: const Key('audioStop'),
                    tooltip: l.audioStop,
                    icon: const Icon(Icons.close),
                    onPressed: rec.stop,
                  ),
                ],
              ),
            ),
          ),
        );
        if (!withTafsir || rec.current == null) return player;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RecitationTafsirPanel(ref: rec.current!.ref),
            player,
          ],
        );
      },
    );
  }
}

/// Docked above the mini player while "Tafsir with recitation" is on: the
/// Tafsir al-Muyassar of the ayah being recited, exactly as stored. It follows
/// the recitation ayah by ayah (and so across page turns).
class RecitationTafsirPanel extends StatefulWidget {
  const RecitationTafsirPanel({super.key, required this.ref});
  final AyahRef ref;

  @override
  State<RecitationTafsirPanel> createState() => _RecitationTafsirPanelState();
}

class _RecitationTafsirPanelState extends State<RecitationTafsirPanel> {
  Future<TafsirContent>? _tafsir;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tafsir ??= context.services.tafsir.load();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final r = widget.ref;
    final maxH = (MediaQuery.sizeOf(context).height * 0.22).clamp(96.0, 220.0);
    return Material(
      key: const Key('recitationTafsir'),
      color: scheme.surfaceContainerLow,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, DesignTokens.spaceSm, DesignTokens.spaceMd, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${l.audioTafsirToggle} · ${ayahLabel(context, r)}',
              key: const Key('recitationTafsirTitle'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
            ),
            if (!context.isArabic)
              Text(
                l.tafsirArabicOnly,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxH),
              child: FutureBuilder<TafsirContent>(
                future: _tafsir,
                initialData: context.services.tafsir.loaded,
                builder: (context, snap) {
                  final text = snap.data?.text(r.surah, r.ayah);
                  if (text == null) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
                      child: Text(
                        snap.hasError ? l.tafsirError : l.tafsirLoading,
                        key: const Key('recitationTafsirStatus'),
                        style: theme.textTheme.bodySmall?.copyWith(color: snap.hasError ? scheme.error : null),
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    // A new scroll position for every ayah: each entry starts at its top.
                    key: ValueKey('recitationTafsirScroll-${r.surah}-${r.ayah}'),
                    padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                    child: Text(
                      text,
                      key: const Key('recitationTafsirText'),
                      textDirection: TextDirection.rtl,
                      style: duaStyle(context, size: 15),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Reciter and repeat-count choices (also used in Settings).
class RecitationSettings extends StatelessWidget {
  const RecitationSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: s.settings,
      builder: (context, _) {
        final current = s.content.reciters.byFolder(s.settings.reciter);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InputDecorator(
              decoration: InputDecoration(
                labelText: l.audioReciter,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  key: const Key('reciterDropdown'),
                  value: current.folder,
                  isExpanded: true,
                  items: [
                    for (final r in s.content.reciters.reciters)
                      DropdownMenuItem(
                        value: r.folder,
                        child: Text(r.name(context.isArabic), overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) s.settings.setReciter(v);
                  },
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(l.audioRepeat, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: DesignTokens.spaceXs),
            Wrap(
              spacing: DesignTokens.spaceSm,
              children: [
                for (final n in SettingsController.repeatChoices)
                  ChoiceChip(
                    key: Key('repeat-$n'),
                    label: Text(l.audioRepeatN(context.num(n))),
                    selected: s.settings.repeat == n,
                    onSelected: (_) => s.settings.setRepeat(n),
                  ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(l.audioStreamNote, style: Theme.of(context).textTheme.bodySmall),
          ],
        );
      },
    );
  }
}

Future<void> showRecitationSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(context.l10n.audioTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: DesignTokens.spaceMd),
          const RecitationSettings(),
        ],
      ),
    ),
  ),
);
