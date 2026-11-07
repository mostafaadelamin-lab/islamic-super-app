import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/audio_queue.dart';
import '../domain/bookmark.dart';
import '../domain/quran.dart';
import '../domain/tafsir.dart';
import '../domain/text.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';
import 'widgets.dart';

/// Opens the sheet for a tapped ayah: its Tafsir al-Muyassar (with previous /
/// next ayah) and the actions listen, listen to the surah, bookmark, copy and,
/// when [readAsList] is true, read as a list. [onAyahChanged] is told when the
/// reader moves to another ayah inside the sheet.
Future<void> showAyahSheet(
  BuildContext context,
  AyahRef ref, {
  ValueChanged<AyahRef>? onAyahChanged,
  bool readAsList = true,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => AyahSheet(initial: ref, onAyahChanged: onAyahChanged, readAsList: readAsList),
);

/// The ayah before / after [r] across surah boundaries, or null at 1:1 / 114:6.
AyahRef? stepAyah(QuranContent q, AyahRef r, int delta) {
  if (delta > 0) {
    if (r.ayah < q.surah(r.surah).ayahCount) return AyahRef(r.surah, r.ayah + 1);
    return r.surah < 114 ? AyahRef(r.surah + 1, 1) : null;
  }
  if (r.ayah > 1) return AyahRef(r.surah, r.ayah - 1);
  return r.surah > 1 ? AyahRef(r.surah - 1, q.surah(r.surah - 1).ayahCount) : null;
}

class AyahSheet extends StatefulWidget {
  const AyahSheet({super.key, required this.initial, this.onAyahChanged, this.readAsList = true});
  final AyahRef initial;
  final ValueChanged<AyahRef>? onAyahChanged;
  final bool readAsList;

  @override
  State<AyahSheet> createState() => AyahSheetState();
}

class AyahSheetState extends State<AyahSheet> {
  late AyahRef _ref = widget.initial;
  Future<TafsirContent>? _tafsir;

  /// The ayah the sheet is showing.
  AyahRef get ref => _ref;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _tafsir ??= context.services.tafsir.load();
  }

  void _step(int delta) {
    final next = stepAyah(context.services.content.quran, _ref, delta);
    if (next == null) return;
    setState(() => _ref = next);
    widget.onAyahChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final q = s.content.quran;
    final canPrev = stepAyah(q, _ref, -1) != null;
    final canNext = stepAyah(q, _ref, 1) != null;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: Column(
          key: const Key('ayahSheet'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('tafsirPrev'),
                    tooltip: l.tafsirPrev,
                    icon: const Icon(Icons.navigate_before),
                    onPressed: canPrev ? () => _step(-1) : null,
                  ),
                  Expanded(
                    child: Text(
                      ayahLabel(context, _ref),
                      key: const Key('ayahSheetTitle'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    key: const Key('tafsirNext'),
                    tooltip: l.tafsirNext,
                    icon: const Icon(Icons.navigate_next),
                    onPressed: canNext ? () => _step(1) : null,
                  ),
                ],
              ),
            ),
            Flexible(
              child: FutureBuilder<TafsirContent>(
                future: _tafsir,
                initialData: s.tafsir.loaded,
                builder: (context, snap) =>
                    _TafsirCard(text: snap.data?.text(_ref.surah, _ref.ayah), failed: snap.hasError),
              ),
            ),
            _Actions(ref: _ref, readAsList: widget.readAsList),
          ],
        ),
      ),
    );
  }
}

class _TafsirCard extends StatelessWidget {
  const _TafsirCard({required this.text, required this.failed});
  final String? text;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final Widget body;
    if (text != null) {
      body = Flexible(
        child: SingleChildScrollView(
          key: const Key('tafsirScroll'),
          child: Text(
            text!,
            key: const Key('tafsirText'),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.start,
            style: duaStyle(context, size: 17),
          ),
        ),
      );
    } else if (failed) {
      body = Text(
        l.tafsirError,
        key: const Key('tafsirError'),
        style: TextStyle(color: scheme.error),
      );
    } else {
      body = Row(
        key: const Key('tafsirLoading'),
        children: [
          const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(child: Text(l.tafsirLoading)),
        ],
      );
    }
    return Container(
      key: const Key('tafsirCard'),
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_outlined, size: 20, color: scheme.primary),
              const SizedBox(width: DesignTokens.spaceSm),
              Expanded(
                child: Text(
                  l.tafsirTitle,
                  key: const Key('tafsirTitle'),
                  style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Text(
            l.tafsirSource,
            key: const Key('tafsirSource'),
            style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (!context.isArabic)
            Text(
              l.tafsirArabicOnly,
              key: const Key('tafsirArabicOnly'),
              style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: DesignTokens.spaceSm),
          body,
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({required this.ref, required this.readAsList});
  final AyahRef ref;
  final bool readAsList;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    return ListenableBuilder(
      listenable: s.bookmarks,
      builder: (context, _) {
        final marked = s.bookmarks.isBookmarked(ref);
        Widget action(String key, IconData icon, String label, VoidCallback onPressed) =>
            ActionChip(key: Key(key), avatar: Icon(icon, size: 18), label: Text(label), onPressed: onPressed);
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            DesignTokens.spaceLg,
            DesignTokens.spaceXs,
            DesignTokens.spaceLg,
            DesignTokens.spaceSm,
          ),
          child: Wrap(
            spacing: DesignTokens.spaceSm,
            children: [
              action('ayahPlay', Icons.play_arrow, l.mushafPlayFromHere, () {
                Navigator.of(context).pop();
                s.recitation.playFrom(ref);
              }),
              action('ayahPlaySurah', Icons.queue_music, l.mushafPlaySurah, () {
                Navigator.of(context).pop();
                s.recitation.playFrom(AyahRef(ref.surah, 1), scope: PlayScope.surah);
              }),
              action(
                'ayahBookmark',
                marked ? Icons.bookmark : Icons.bookmark_border,
                marked ? l.quranRemoveBookmark : l.quranBookmark,
                () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final nav = Navigator.of(context);
                  if (marked) {
                    await s.bookmarks.remove(Bookmark.idFor(ref.surah, ref.ayah));
                  } else {
                    await s.bookmarks.add(ref);
                  }
                  nav.pop();
                  messenger.showSnackBar(SnackBar(content: Text(marked ? l.quranBookmarkRemoved : l.quranBookmarked)));
                },
              ),
              action('ayahCopy', Icons.copy, l.mushafCopy, () async {
                final messenger = ScaffoldMessenger.of(context);
                final nav = Navigator.of(context);
                final q = s.content.quran;
                // The canonical stored text (no display glyph map) and its reference.
                await Clipboard.setData(
                  ClipboardData(text: '${q.text(ref)} ﴿${q.surah(ref.surah).nameAr}: ${toArabicIndic(ref.ayah)}﴾'),
                );
                nav.pop();
                messenger.showSnackBar(SnackBar(content: Text(l.mushafCopied)));
              }),
              if (readAsList)
                action('ayahReadList', Icons.view_agenda_outlined, l.mushafReadAsList, () {
                  Navigator.of(context).pop();
                  openSurah(context, ref.surah, ayah: ref.ayah);
                }),
            ],
          ),
        );
      },
    );
  }
}
