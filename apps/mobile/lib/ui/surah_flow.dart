import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/audio_queue.dart';
import '../domain/quran.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'mushaf_page.dart';
import 'quran_index.dart' show juzTitle;
import 'r_icon.dart';

/// "السورة كاملة" (owner 2026-11-17): the whole surah as one flowing text on the Mushaf paper, so it reads
/// without turning pages. The text is the canonical KFGQPC text of every ayah (only the display glyph map is
/// applied, as on the Mushaf page), each ayah closed by its number marker. The size follows the reader's
/// A+ / A− buttons. It opens at the ayahs of [page]; a tap on an ayah calls [onAyahTap].
class SurahFlow extends StatefulWidget {
  const SurahFlow({
    super.key,
    required this.surah,
    required this.page,
    required this.onAyahTap,
    required this.onSurah,
    this.selected,
    this.playing,
  });

  final int surah;

  /// The Mushaf page the reader was on: the view starts at its first ayah of [surah].
  final int page;
  final AyahRef? selected;
  final AyahRef? playing;
  final ValueChanged<AyahRef> onAyahTap;

  /// Opens another surah (the buttons at the end).
  final ValueChanged<int> onSurah;

  @override
  State<SurahFlow> createState() => _SurahFlowState();
}

class _SurahFlowState extends State<SurahFlow> {
  final _center = UniqueKey();

  /// Fixed when the view opens, so a later page change (an ayah picked in the sheet) never shifts the text.
  late final int _startPage = widget.page;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final q = s.content.quran;
    final sura = q.surah(widget.surah);
    final size = s.settings.quranFontSize;
    final paper = AppTheme.of(context, 'paper');
    final frame = AppTheme.of(context, 'frame');

    // The surah split by Mushaf page, so the view can open at the reader's page.
    final chunks = <(int, List<AyahRef>)>[];
    for (var a = 1; a <= sura.ayahCount; a++) {
      final r = AyahRef(sura.n, a);
      final p = q.pageOf(r);
      if (chunks.isEmpty || chunks.last.$1 != p) chunks.add((p, []));
      chunks.last.$2.add(r);
    }
    var start = chunks.indexWhere((c) => c.$1 >= _startPage);
    if (start < 0) start = chunks.length - 1;

    Widget chunk(int i) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      child: _Chunk(
        key: ValueKey('surahFlow-${sura.n}-${chunks[i].$1}'),
        refs: chunks[i].$2,
        size: size,
        selected: widget.selected,
        playing: widget.playing,
        onTap: widget.onAyahTap,
      ),
    );

    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: size * 1.9,
          child: SurahBand(surah: sura.n, font: size, height: size * 1.9),
        ),
        if (basmalaBeforeSurah(sura.n))
          Text(
            s.content.renderMap.forDisplay(q.text(const AyahRef(1, 1))),
            key: Key('surahFlowBasmala-${sura.n}'),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: DesignTokens.fontQuran,
              fontSize: size * 0.9,
              height: 2,
              color: AppTheme.of(context, 'paperInk'),
            ),
          ),
      ],
    );

    return Container(
      key: Key('surahFlow-${sura.n}'),
      margin: const EdgeInsets.all(DesignTokens.spaceSm),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: frame, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomScrollView(
        key: const Key('surahFlowScroll'),
        center: _center,
        slivers: [
          // Opening at the first page: the title (and the juz picker) start the list, in view.
          SliverList.builder(
            itemCount: start == 0 ? 0 : start + 1,
            itemBuilder: (_, k) => k == start
                ? Padding(padding: const EdgeInsets.all(DesignTokens.spaceSm), child: head)
                : chunk(start - 1 - k),
          ),
          SliverList.builder(
            key: _center,
            itemCount: chunks.length - start + 1 + (start == 0 ? 1 : 0),
            itemBuilder: (_, i) {
              if (start == 0 && i == 0) {
                return Padding(padding: const EdgeInsets.all(DesignTokens.spaceSm), child: head);
              }
              final k = start == 0 ? i - 1 : i;
              return k == chunks.length - start ? _surahButtons(context, sura.n) : chunk(start + k);
            },
          ),
        ],
      ),
    );
  }

  Widget _surahButtons(BuildContext context, int n) {
    final l = context.l10n;
    return Padding(
      key: const Key('surahFlowButtons'),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('surahFlowPrev'),
              onPressed: n <= 1 ? null : () => widget.onSurah(n - 1),
              icon: const RIcon(RIcons.chevron),
              label: Text(l.readerPrevSurah, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: FilledButton.icon(
              key: const Key('surahFlowNext'),
              onPressed: n >= 114 ? null : () => widget.onSurah(n + 1),
              icon: const RIcon(RIcons.chevronForward),
              label: Text(l.readerNextSurah, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ayahs of one Mushaf page of the surah, flowing as one justified paragraph.
class _Chunk extends StatefulWidget {
  const _Chunk({super.key, required this.refs, required this.size, required this.onTap, this.selected, this.playing});
  final List<AyahRef> refs;
  final double size;
  final AyahRef? selected;
  final AyahRef? playing;
  final ValueChanged<AyahRef> onTap;

  @override
  State<_Chunk> createState() => _ChunkState();
}

class _ChunkState extends State<_Chunk> {
  final _taps = <AyahRef, TapGestureRecognizer>{};

  TapGestureRecognizer _tap(AyahRef r) =>
      _taps.putIfAbsent(r, () => TapGestureRecognizer()..onTap = () => widget.onTap(r));

  @override
  void didUpdateWidget(_Chunk old) {
    super.didUpdateWidget(old);
    for (final r in _taps.keys) {
      _taps[r]!.onTap = () => widget.onTap(r);
    }
  }

  @override
  void dispose() {
    for (final t in _taps.values) {
      t.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final ink = AppTheme.of(context, 'paperInk');
    final dark = Theme.of(context).brightness == Brightness.dark;
    final size = widget.size;
    // The same clear colours as the Mushaf page (never red).
    Color? highlight(AyahRef r) => r == widget.playing
        ? (dark ? const Color(0xFF2F6B5A) : const Color(0xFFB9E2CF)).withValues(alpha: MushafPageView.highlightAlpha)
        : r == widget.selected
        ? (dark ? const Color(0xFF8A6A1E) : const Color(0xFFF3C969)).withValues(alpha: MushafPageView.highlightAlpha)
        : null;
    return Text.rich(
      TextSpan(
        children: [
          for (final r in widget.refs) ...[
            TextSpan(
              text: s.content.renderMap.forDisplay(s.content.quran.text(r)),
              recognizer: _tap(r),
              style: TextStyle(backgroundColor: highlight(r)),
            ),
            const TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                key: Key('surahFlowAyah-${r.surah}-${r.ayah}'),
                onTap: () => widget.onTap(r),
                child: AyahMarker(
                  number: r.ayah,
                  size: size * 1.15,
                  color: Theme.of(context).colorScheme.primary,
                  ink: ink,
                ),
              ),
            ),
            const TextSpan(text: ' '),
          ],
        ],
      ),
      textAlign: TextAlign.justify,
      textDirection: TextDirection.rtl,
      style: TextStyle(fontFamily: DesignTokens.fontQuran, fontSize: size, height: 2.1, color: ink),
    );
  }
}

/// «الجزء كاملاً» (owner 2026-11-20): one juz as one flowing text on the Mushaf paper, surah after surah (a surah
/// band before every ayah 1), with a juz picker on top and the previous / next juz at the end. The same canonical
/// KFGQPC text as the whole-surah view. It opens at the ayahs of [page]; a tap on an ayah calls [onAyahTap].
class JuzFlow extends StatefulWidget {
  const JuzFlow({
    super.key,
    required this.juz,
    required this.page,
    required this.onAyahTap,
    required this.onJuz,
    this.selected,
    this.playing,
  });

  final int juz;
  final int page;
  final AyahRef? selected;
  final AyahRef? playing;
  final ValueChanged<AyahRef> onAyahTap;

  /// Opens another juz (the picker, or the buttons at the end).
  final ValueChanged<int> onJuz;

  @override
  State<JuzFlow> createState() => _JuzFlowState();
}

class _JuzFlowState extends State<JuzFlow> {
  final _center = UniqueKey();
  late final int _startPage = widget.page;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final q = s.content.quran;
    final size = s.settings.quranFontSize;
    final paper = AppTheme.of(context, 'paper');
    final frame = AppTheme.of(context, 'frame');
    final refs = q.juzRefs(widget.juz);

    // Split by Mushaf page and by surah, so a surah band can sit before its first ayah.
    final chunks = <(int, List<AyahRef>)>[];
    for (final r in refs) {
      final p = q.pageOf(r);
      if (chunks.isEmpty || chunks.last.$1 != p || r.ayah == 1) chunks.add((p, []));
      chunks.last.$2.add(r);
    }
    var start = chunks.indexWhere((c) => c.$1 >= _startPage);
    if (start < 0) start = chunks.length - 1;

    Widget band(int surah) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: size * 1.9,
            child: SurahBand(surah: surah, font: size, height: size * 1.9),
          ),
          if (basmalaBeforeSurah(surah))
            Text(
              s.content.renderMap.forDisplay(q.text(const AyahRef(1, 1))),
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: DesignTokens.fontQuran,
                fontSize: size * 0.9,
                height: 2,
                color: AppTheme.of(context, 'paperInk'),
              ),
            ),
        ],
      ),
    );

    Widget chunk(int i) {
      final c = chunks[i];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (c.$2.first.ayah == 1) band(c.$2.first.surah),
            _Chunk(
              key: ValueKey('juzFlow-${widget.juz}-${c.$1}-${c.$2.first.surah}'),
              refs: c.$2,
              size: size,
              selected: widget.selected,
              playing: widget.playing,
              onTap: widget.onAyahTap,
            ),
          ],
        ),
      );
    }

    final first = refs.first;
    final head = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: _juzPicker(context)),
        if (first.ayah != 1)
          Padding(
            padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
            child: Text(
              context.l10n.quranSurahTitle(q.surah(first.surah).nameAr),
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
      ],
    );

    return Container(
      key: Key('juzFlow-${widget.juz}'),
      margin: const EdgeInsets.all(DesignTokens.spaceSm),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: frame, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: CustomScrollView(
        key: const Key('juzFlowScroll'),
        center: _center,
        slivers: [
          // Opening at the first page: the title (and the juz picker) start the list, in view.
          SliverList.builder(
            itemCount: start == 0 ? 0 : start + 1,
            itemBuilder: (_, k) => k == start
                ? Padding(padding: const EdgeInsets.all(DesignTokens.spaceSm), child: head)
                : chunk(start - 1 - k),
          ),
          SliverList.builder(
            key: _center,
            itemCount: chunks.length - start + 1 + (start == 0 ? 1 : 0),
            itemBuilder: (_, i) {
              if (start == 0 && i == 0) {
                return Padding(padding: const EdgeInsets.all(DesignTokens.spaceSm), child: head);
              }
              final k = start == 0 ? i - 1 : i;
              return k == chunks.length - start ? _juzButtons(context) : chunk(start + k);
            },
          ),
        ],
      ),
    );
  }

  Widget _juzPicker(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final count = context.services.content.quran.juz.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
        border: Border.all(color: AppTheme.of(context, 'frame')),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          key: const Key('juzPick'),
          value: widget.juz,
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
          menuMaxHeight: 420,
          // The app font (a bare TextStyle would fall back to a font without Arabic).
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
          items: [
            for (var j = 1; j <= count; j++)
              DropdownMenuItem(value: j, key: Key('juzPick-$j'), child: Text(juzTitle(context, j))),
          ],
          onChanged: (j) {
            if (j != null && j != widget.juz) widget.onJuz(j);
          },
        ),
      ),
    );
  }

  Widget _juzButtons(BuildContext context) {
    final l = context.l10n;
    final n = widget.juz;
    final count = context.services.content.quran.juz.length;
    return Padding(
      key: const Key('juzFlowButtons'),
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              key: const Key('juzFlowPrev'),
              onPressed: n <= 1 ? null : () => widget.onJuz(n - 1),
              icon: const RIcon(RIcons.chevron),
              label: Text(l.readerPrevJuz, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
          const SizedBox(width: DesignTokens.spaceSm),
          Expanded(
            child: FilledButton.icon(
              key: const Key('juzFlowNext'),
              onPressed: n >= count ? null : () => widget.onJuz(n + 1),
              icon: const RIcon(RIcons.chevronForward),
              label: Text(l.readerNextJuz, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ),
    );
  }
}
