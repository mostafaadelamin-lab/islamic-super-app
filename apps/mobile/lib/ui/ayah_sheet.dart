import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/audio_queue.dart';
import '../domain/bookmark.dart';
import '../domain/quran.dart';
import '../domain/tafsir.dart';
import '../domain/text.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'ayah_image_screen.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';
import 'widgets.dart';
import 'r_icon.dart';

/// Opens the sheet for a tapped ayah: five simple buttons (listen, which opens the ways to listen:
/// the ayah, to the end of the page or surah, with tafsir; tafsir, which opens Tafsir al-Muyassar;
/// mark; copy; share as an image) under the ayah's name with previous / next ayah.
/// [readAsList] is kept for callers but no longer adds an action. [onAyahChanged] is told when the
/// reader moves to another ayah inside the sheet.
///
/// [overPage] (the Mushaf page, owner 2026-11-14): the page must stay in view, so the sheet is
/// smaller and does not dim the page; on a wide screen it opens as a panel beside the page.
Future<void> showAyahSheet(
  BuildContext context,
  AyahRef ref, {
  ValueChanged<AyahRef>? onAyahChanged,
  bool readAsList = true,
  bool overPage = false,
}) {
  Widget sheet({double heightFactor = 0.85}) =>
      AyahSheet(initial: ref, onAyahChanged: onAyahChanged, readAsList: readAsList, heightFactor: heightFactor);
  if (overPage && ayahSidePanel(MediaQuery.sizeOf(context))) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.transparent,
      pageBuilder: (context, _, _) => Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceSm),
          child: Material(
            key: const Key('ayahSidePanel'),
            elevation: 6,
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            clipBehavior: Clip.antiAlias,
            child: SizedBox(width: ayahPanelWidth, child: sheet(heightFactor: 0.92)),
          ),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    barrierColor: overPage ? Colors.transparent : null,
    builder: (_) => sheet(heightFactor: overPage ? 0.48 : 0.85),
  );
}

/// Width of the ayah panel beside the Mushaf page on wide screens.
const double ayahPanelWidth = 380;

/// A screen wide enough (tablet sideways, desktop) to show the ayah panel beside the page.
bool ayahSidePanel(Size size) => size.width >= 900 && size.width > size.height;

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
  const AyahSheet({
    super.key,
    required this.initial,
    this.onAyahChanged,
    this.readAsList = true,
    this.heightFactor = 0.85,
    this.onClose,
  });
  final AyahRef initial;

  /// In the reader's bottom strip (owner 2026-11-15): a close button in the title row.
  final VoidCallback? onClose;

  /// The most of the screen height the sheet may take.
  final double heightFactor;
  final ValueChanged<AyahRef>? onAyahChanged;
  final bool readAsList;

  @override
  State<AyahSheet> createState() => AyahSheetState();
}

class AyahSheetState extends State<AyahSheet> {
  late AyahRef _ref = widget.initial;
  Future<TafsirContent>? _tafsir;

  /// Simple menu (owner, 2026-11-15): the tafsir stays folded until its button is tapped.
  bool _showTafsir = false;

  /// The ayah the sheet is showing.
  AyahRef get ref => _ref;

  @override
  void didUpdateWidget(AyahSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Another ayah tapped on the page while the actions are open.
    if (widget.initial != oldWidget.initial && widget.initial != _ref) _ref = widget.initial;
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
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * widget.heightFactor),
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
                    icon: const RIcon(RIcons.chevron),
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
                    icon: const RIcon(RIcons.chevronForward),
                    onPressed: canNext ? () => _step(1) : null,
                  ),
                  if (widget.onClose != null)
                    IconButton(
                      key: const Key('ayahSheetClose'),
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      icon: const Icon(Icons.close),
                      onPressed: widget.onClose,
                    ),
                ],
              ),
            ),
            _Actions(
              ref: _ref,
              readAsList: widget.readAsList,
              tafsirOpen: _showTafsir,
              onClose: widget.onClose,
              onTafsir: () => setState(() {
                _showTafsir = !_showTafsir;
                // Loaded only when first opened.
                _tafsir ??= s.tafsir.load()..ignore(); // the card below shows a failure; nothing else waits on it
              }),
            ),
            if (_showTafsir)
              Flexible(
                child: FutureBuilder<TafsirContent>(
                  future: _tafsir,
                  initialData: s.tafsir.loaded,
                  builder: (context, snap) =>
                      _TafsirCard(text: snap.data?.text(_ref.surah, _ref.ayah), failed: snap.hasError),
                ),
              ),
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
              RIcon(RIcons.quran, size: 20, color: scheme.primary),
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

/// Simple ayah menu (owner, 2026-11-15): one row of five buttons (listen, tafsir, mark, copy,
/// share); the ways to listen open under it only when "listen" is tapped.
class _Actions extends StatefulWidget {
  const _Actions({
    required this.ref,
    required this.readAsList,
    required this.tafsirOpen,
    required this.onTafsir,
    this.onClose,
  });
  final AyahRef ref;

  /// Set when the actions sit in the reader's bottom strip: there is no sheet to pop, and the
  /// buttons look like the bar under them.
  final VoidCallback? onClose;
  final bool readAsList;
  final bool tafsirOpen;
  final VoidCallback onTafsir;

  @override
  State<_Actions> createState() => _ActionsState();
}

class _ActionsState extends State<_Actions> {
  bool _listen = false;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final ref = widget.ref;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: s.bookmarks,
      builder: (context, _) {
        final marked = s.bookmarks.isBookmarked(ref);
        final inline = widget.onClose != null;
        // In the strip the sheet stays; as a sheet it closes after an action.
        void closeSheet(NavigatorState nav) {
          if (!inline) nav.pop();
        }

        Widget action(String key, RIconData icon, String label, VoidCallback onPressed, {bool on = false}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Material(
              color: on
                  ? (inline ? AppTheme.of(context, 'accentSoft') : scheme.secondaryContainer)
                  : (inline ? Colors.transparent : scheme.surfaceContainerLow),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                side: inline ? BorderSide.none : BorderSide(color: on ? scheme.primary : scheme.outlineVariant),
              ),
              child: InkWell(
                key: Key(key),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                onTap: onPressed,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RIcon(icon, size: 22, color: scheme.primary),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: inline
                            ? TextStyle(fontSize: 12, color: scheme.primary)
                            : Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        Widget way(String key, String label, VoidCallback onPressed) => OutlinedButton(
          key: Key(key),
          style: OutlinedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 38),
          ),
          onPressed: onPressed,
          child: Text(label),
        );
        void play(AyahRef from, PlayScope scope, {bool tafsir = false}) {
          if (inline) {
            widget.onClose!();
          } else {
            Navigator.of(context).pop();
          }
          s.settings.setTafsirWithRecitation(tafsir);
          s.recitation.playFrom(from, scope: scope);
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, 0, DesignTokens.spaceMd, DesignTokens.spaceSm),
          child: Column(
            key: const Key('ayahActions'),
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  action(
                    'ayahListen',
                    RIcons.playCircle,
                    l.ayahListen,
                    () => setState(() => _listen = !_listen),
                    on: _listen,
                  ),
                  action('ayahTafsir', RIcons.openBook, l.ayahTafsir, widget.onTafsir, on: widget.tafsirOpen),
                  action('ayahBookmark', RIcons.bookmark, marked ? l.ayahUnmarkShort : l.ayahMarkShort, () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    if (marked) {
                      await s.bookmarks.remove(Bookmark.idFor(ref.surah, ref.ayah));
                    } else {
                      await s.bookmarks.add(ref);
                    }
                    closeSheet(nav);
                    messenger.showSnackBar(
                      SnackBar(content: Text(marked ? l.quranBookmarkRemoved : l.quranBookmarked)),
                    );
                  }, on: marked),
                  action('ayahCopy', RIcons.copy, l.ayahCopyShort, () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final nav = Navigator.of(context);
                    final q = s.content.quran;
                    // The canonical stored text (no display glyph map) and its reference.
                    await Clipboard.setData(
                      ClipboardData(text: '${q.text(ref)} ﴿${q.surah(ref.surah).nameAr}: ${toArabicIndic(ref.ayah)}﴾'),
                    );
                    closeSheet(nav);
                    messenger.showSnackBar(SnackBar(content: Text(l.mushafCopied)));
                  }),
                  action('ayahShareImage', RIcons.share, l.ayahShare, () {
                    final nav = Navigator.of(context);
                    closeSheet(nav);
                    nav.push(MaterialPageRoute<void>(builder: (_) => AyahImageScreen(ayah: ref)));
                  }),
                ],
              ),
              if (_listen)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                  child: Wrap(
                    key: const Key('ayahListenWays'),
                    spacing: DesignTokens.spaceXs,
                    runSpacing: DesignTokens.spaceXs,
                    alignment: WrapAlignment.center,
                    children: [
                      way('ayahPlayOne', l.ayahOnlyThis, () => play(ref, PlayScope.ayah)),
                      way('ayahPlayPage', l.ayahToPageEnd, () => play(ref, PlayScope.page)),
                      way('ayahPlaySurah', l.ayahToSurahEnd, () => play(ref, PlayScope.surah)),
                      way('ayahPlayTafsir', l.ayahWithTafsir, () => play(ref, PlayScope.surah, tafsir: true)),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
