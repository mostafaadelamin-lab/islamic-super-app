import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../data/settings.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'widgets.dart';

/// Mini player shown while a recitation is active: what is playing, previous /
/// play-pause / next / stop, and a clear message when the audio cannot load.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final rec = context.services.recitation;
    return ListenableBuilder(
      listenable: rec,
      builder: (context, _) {
        if (!rec.isActive) return const SizedBox.shrink();
        final l = context.l10n;
        final scheme = Theme.of(context).colorScheme;
        final item = rec.current!;
        final title = item.isBasmala
            ? '${l.audioBasmala} · ${surahName(context, context.services.content.quran.surah(item.ref.surah))}'
            : ayahLabel(context, item.ref);
        final error = rec.state == RecitationState.error;
        return Material(
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
                  Icon(error ? Icons.wifi_off : Icons.graphic_eq, color: error ? scheme.error : scheme.primary),
                  const SizedBox(width: DesignTokens.spaceSm),
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
      },
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
