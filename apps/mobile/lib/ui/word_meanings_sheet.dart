import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/word_meanings.dart';
import '../domain/quran.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'widgets.dart';

/// «معاني الكلمات» (owner 2026-11-17): the difficult words of a Mushaf page ([page] set, [refs] = its
/// ayahs) or of one ayah, with their meanings from «السراج في بيان غريب القرآن», shown verbatim.
/// A centred panel like the khatma panel. [onSelect] (page view): tapping an ayah's name selects it.
Future<void> showWordMeaningsSheet(
  BuildContext context, {
  required List<AyahRef> refs,
  int? page,
  ValueChanged<AyahRef>? onSelect,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => Dialog(
    insetPadding: const EdgeInsets.all(DesignTokens.spaceMd),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: WordMeaningsPanel(
        refs: refs,
        page: page,
        onSelect: onSelect == null
            ? null
            : (r) {
                Navigator.of(dialogContext).pop();
                onSelect(r);
              },
      ),
    ),
  ),
);

class WordMeaningsPanel extends StatefulWidget {
  const WordMeaningsPanel({super.key, required this.refs, this.page, this.onSelect});
  final List<AyahRef> refs;
  final int? page;
  final ValueChanged<AyahRef>? onSelect;

  @override
  State<WordMeaningsPanel> createState() => _WordMeaningsPanelState();
}

class _WordMeaningsPanelState extends State<WordMeaningsPanel> {
  late Future<WordMeaningsContent> _future = context.services.wordMeanings.load();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final one = widget.refs.length == 1 ? widget.refs.first : null;
    final title = one != null
        ? l.meaningsOfAyah(ayahLabel(context, one))
        : l.meaningsOfPage(context.num(widget.page ?? 0));
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          DesignTokens.spaceMd,
          DesignTokens.spaceSm,
          DesignTokens.spaceMd,
          DesignTokens.spaceMd,
        ),
        child: Column(
          key: const Key('wordMeanings'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                RIcon(RIcons.meanings, color: scheme.primary),
                const SizedBox(width: DesignTokens.spaceXs),
                Expanded(
                  child: Text(
                    title,
                    key: const Key('wordMeaningsTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  key: const Key('wordMeaningsClose'),
                  tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            Flexible(
              child: FutureBuilder<WordMeaningsContent>(
                future: _future,
                initialData: context.services.wordMeanings.loaded,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(l.meaningsError, key: const Key('wordMeaningsError')),
                        TextButton(
                          onPressed: () => setState(() => _future = context.services.wordMeanings.load()),
                          child: Text(l.commonRetry),
                        ),
                      ],
                    );
                  }
                  final c = snap.data;
                  if (c == null) {
                    return Padding(
                      padding: const EdgeInsets.all(DesignTokens.spaceMd),
                      child: Text(l.meaningsLoading, key: const Key('wordMeaningsLoading')),
                    );
                  }
                  final items = [
                    for (final r in widget.refs)
                      if (c.words(r.surah, r.ayah).isNotEmpty) (ref: r, words: c.words(r.surah, r.ayah)),
                  ];
                  if (items.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
                      child: Text(
                        one != null ? l.meaningsNoneAyah : l.meaningsNonePage,
                        key: const Key('wordMeaningsNone'),
                        style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return ListView(
                    key: const Key('wordMeaningsList'),
                    shrinkWrap: true,
                    children: [
                      for (final it in items) ...[
                        if (one == null)
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: Padding(
                              padding: const EdgeInsets.only(top: DesignTokens.spaceSm, bottom: 4),
                              child: Material(
                                color: scheme.primary.withValues(alpha: 0.1),
                                shape: const StadiumBorder(),
                                child: InkWell(
                                  key: Key('wordMeaningsAyah-${it.ref.surah}:${it.ref.ayah}'),
                                  customBorder: const StadiumBorder(),
                                  onTap: widget.onSelect == null ? null : () => widget.onSelect!(it.ref),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    child: Text(
                                      ayahLabel(context, it.ref),
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: scheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        for (final w in it.words)
                          Container(
                            margin: const EdgeInsets.only(top: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Color.alphaBlend(const Color(0x1AC8A24A), scheme.surface),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: scheme.outlineVariant),
                            ),
                            child: Text.rich(
                              key: const Key('wordMeaningItem'),
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${w.word}: ',
                                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700),
                                  ),
                                  TextSpan(text: w.meaning),
                                ],
                              ),
                              style: theme.textTheme.bodyLarge?.copyWith(height: 1.8),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(
              l.meaningsSource,
              key: const Key('wordMeaningsSource'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
