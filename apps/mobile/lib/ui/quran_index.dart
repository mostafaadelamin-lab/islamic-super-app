import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/quran.dart';
import '../domain/text.dart';
import '../theme/app_theme.dart';
import 'l10n_ext.dart';
import 'page_reader_screen.dart';
import 'widgets.dart';

enum QuranIndexTab { surahs, quarters }

/// Opens the Quran index ("فهرس السور") as a bottom sheet and returns the Mushaf
/// page the user picked, or null if the sheet was dismissed. [currentPage] is
/// highlighted (the surah and the quarter that contain it).
Future<int?> showQuranIndexSheet(BuildContext context, {int? currentPage}) => showModalBottomSheet<int>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (sheetContext) => FractionallySizedBox(
    heightFactor: 0.94,
    child: QuranIndexView(currentPage: currentPage, onOpenPage: (p) => Navigator.of(sheetContext).pop(p)),
  ),
);

/// The Quran index: a Surahs / Quarters toggle, a search box and a list grouped
/// under juz headers, as in the printed Mushaf index. Rows show the page, ayah
/// count and Meccan/Medinan (surahs) or the opening words of the quarter, taken
/// unchanged from the canonical text (quarters).
class QuranIndexView extends StatefulWidget {
  const QuranIndexView({super.key, this.currentPage, this.onOpenPage, this.showTitle = true});

  /// Page to highlight; when null the last-read position is used.
  final int? currentPage;

  /// Called with the Mushaf page of the tapped row. Defaults to pushing the page reader.
  final ValueChanged<int>? onOpenPage;
  final bool showTitle;

  @override
  State<QuranIndexView> createState() => _QuranIndexViewState();
}

/// A row in the flattened index list: either a juz header or an entry.
sealed class _Row {
  const _Row();
}

class _JuzRow extends _Row {
  const _JuzRow(this.juz);
  final int juz;
}

class _SurahRow extends _Row {
  const _SurahRow(this.surah);
  final Surah surah;
}

class _QuarterRow extends _Row {
  const _QuarterRow(this.quarter);
  final HizbQuarter quarter;
}

List<_Row> _grouped<T>(Iterable<T> items, int Function(T) juzOf, _Row Function(T) row) {
  final out = <_Row>[];
  int? last;
  for (final x in items) {
    final j = juzOf(x);
    if (j != last) out.add(_JuzRow(j));
    last = j;
    out.add(row(x));
  }
  return out;
}

class _QuranIndexViewState extends State<QuranIndexView> {
  QuranIndexTab _tab = QuranIndexTab.surahs;
  final _search = TextEditingController();

  /// One controller per tab, created on first show so the list opens scrolled
  /// to the highlighted row.
  final _controllers = <QuranIndexTab, ScrollController>{};
  String _q = '';

  @override
  void dispose() {
    _search.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Surah> _surahs(BuildContext context) {
    final s = context.services;
    final all = s.content.quran.surahs;
    final q = _q.trim();
    if (q.isEmpty) return all;
    final num = int.tryParse(toAsciiDigits(q));
    final norm = s.content.normalizer.normalize(q);
    final lower = q.toLowerCase();
    return [
      for (final su in all)
        if ((num != null && su.n == num) ||
            (norm.isNotEmpty && s.content.normalizer.normalize(su.nameAr).contains(norm)) ||
            su.translit.toLowerCase().contains(lower) ||
            su.nameEn.toLowerCase().contains(lower))
          su,
    ];
  }

  List<HizbQuarter> _quarters(BuildContext context) {
    final s = context.services;
    final quran = s.content.quran;
    final q = _q.trim();
    if (q.isEmpty) return quran.quarters;
    final num = int.tryParse(toAsciiDigits(q));
    if (num != null) {
      return [
        for (final x in quran.quarters)
          if (x.hizb == num || x.page == num) x,
      ];
    }
    final surahs = {for (final su in _surahs(context)) su.n};
    final norm = s.content.normalizer.normalize(q);
    return [
      for (final x in quran.quarters)
        if (surahs.contains(x.start.surah) ||
            (norm.length > 1 && s.content.normalizer.normalize(quran.text(x.start)).contains(norm)))
          x,
    ];
  }

  ScrollController _controllerFor(List<_Row> rows, double Function(_Row) extent, int? surah_, int? quarter_) =>
      _controllers.putIfAbsent(_tab, () {
        var offset = 0.0;
        var found = false;
        for (final r in rows) {
          final hit = switch (r) {
            _SurahRow(:final surah) => surah.n == surah_,
            _QuarterRow(:final quarter) => quarter.n == quarter_,
            _JuzRow() => false,
          };
          if (hit) {
            found = true;
            break;
          }
          offset += extent(r);
        }
        return ScrollController(initialScrollOffset: found ? math.max(0, offset - 2 * _headerExtent) : 0);
      });

  static const _headerExtent = 62.0;

  void _open(BuildContext context, int page) {
    final cb = widget.onOpenPage;
    if (cb != null) {
      cb(page);
    } else {
      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PageReaderScreen(initialPage: page)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final quran = s.content.quran;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: s.settings,
      builder: (context, _) {
        final last = s.settings.lastRead;
        final page = widget.currentPage ?? (last == null ? null : quran.pageOf(last));
        final at = widget.currentPage == null ? last : null;
        int? currentSurah;
        int? currentQuarter;
        if (at != null) {
          currentSurah = at.surah;
          for (final x in quran.quarters) {
            if (x.start.compareTo(at) <= 0) currentQuarter = x.n;
          }
        } else if (page != null) {
          for (final su in quran.surahs) {
            if (quran.pageOf(AyahRef(su.n, 1)) <= page) currentSurah = su.n;
          }
          for (final x in quran.quarters) {
            if (x.page <= page) currentQuarter = x.n;
          }
        }
        final rows = _tab == QuranIndexTab.surahs
            ? _grouped<Surah>(_surahs(context), (su) => quran.juzOf(AyahRef(su.n, 1)), _SurahRow.new)
            : _grouped<HizbQuarter>(_quarters(context), (x) => x.juz, _QuarterRow.new);
        // Fixed row heights (scaled with the text size) let the list open at the highlighted row.
        final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
        double extent(_Row r) => r is _JuzRow ? _headerExtent * math.max(1, scale) : 84 * math.max(1, scale);
        return Material(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              if (widget.showTitle)
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 10),
                  child: Text(
                    l.quranIndex,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              SegmentedButton<QuranIndexTab>(
                key: const Key('quranIndexTabs'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: QuranIndexTab.surahs,
                    label: Text(l.quranTabSurahs, key: const Key('tabSurahs')),
                  ),
                  ButtonSegment(
                    value: QuranIndexTab.quarters,
                    label: Text(l.quranTabQuarters, key: const Key('tabQuarters')),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (v) => setState(() => _tab = v.first),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: Border.symmetric(horizontal: BorderSide(color: Theme.of(context).dividerColor)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('surahFilter'),
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: l.quranIndexSearch,
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: scheme.surface,
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (v) => setState(() => _q = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      key: const Key('clearSearch'),
                      tooltip: l.quranClearSearch,
                      onPressed: _q.isEmpty
                          ? null
                          : () => setState(() {
                              _search.clear();
                              _q = '';
                            }),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: rows.isEmpty
                    ? Center(child: Text(l.quranNoResults))
                    : ListView.builder(
                        key: Key(_tab == QuranIndexTab.surahs ? 'surahList' : 'quarterList'),
                        controller: _controllerFor(rows, extent, currentSurah, currentQuarter),
                        itemExtentBuilder: (i, _) => i < rows.length ? extent(rows[i]) : null,
                        itemCount: rows.length,
                        itemBuilder: (context, i) => switch (rows[i]) {
                          _JuzRow(:final juz) => _JuzHeader(juz),
                          _SurahRow(:final surah) => _SurahTile(
                            surah,
                            current: surah.n == currentSurah,
                            onOpen: (p) => _open(context, p),
                          ),
                          _QuarterRow(:final quarter) => _QuarterTile(
                            quarter,
                            current: quarter.n == currentQuarter,
                            onOpen: (p) => _open(context, p),
                          ),
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

String juzTitle(BuildContext context, int juz) {
  final ordinals = context.l10n.quranJuzOrdinals.split('|');
  return context.l10n.quranJuzTitle(juz <= ordinals.length ? ordinals[juz - 1] : '$juz');
}

class _JuzHeader extends StatelessWidget {
  const _JuzHeader(this.juz);
  final int juz;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Semantics(
        header: true,
        child: Container(
          key: Key('juzHeader-$juz'),
          color: scheme.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Text(
            juzTitle(context, juz),
            style: AppTheme.quran(context, 19).copyWith(color: scheme.onPrimary, height: 1.5),
          ),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.current,
    required this.onTap,
    this.semanticsLabel,
    this.trailing,
    super.key,
  });
  final Widget badge;
  final Widget title;
  final String subtitle;
  final bool current;
  final VoidCallback onTap;
  final String? semanticsLabel;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: current
          ? Color.lerp(theme.colorScheme.surface, theme.colorScheme.primary, 0.14)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: double.infinity,
          padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 8, 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Semantics(
            label: semanticsLabel,
            selected: current,
            child: Row(
              children: [
                badge,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      title,
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile(this.s, {required this.current, required this.onOpen});
  final Surah s;
  final bool current;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final quran = context.services.content.quran;
    final page = quran.pageOf(AyahRef(s.n, 1));
    final kind = s.isMeccan ? l.quranMeccan : l.quranMedinan;
    final name = surahName(context, s);
    return _Entry(
      key: Key('surah-${s.n}'),
      badge: StarBadge(label: context.num(s.n)),
      title: Text(
        context.isArabic ? l.quranSurahTitle(name) : '$name — ${s.nameEn}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.isArabic
            ? AppTheme.quran(context, 20).copyWith(height: 1.6)
            : Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: l.quranSurahLine(context.num(page), context.num(s.ayahCount), kind),
      current: current,
      onTap: () => onOpen(page),
      trailing: IconButton(
        key: Key('surahText-${s.n}'),
        tooltip: '${l.quranListView}: $name',
        icon: const Icon(Icons.format_list_bulleted),
        color: Theme.of(context).hintColor,
        onPressed: () => openSurah(context, s.n),
      ),
    );
  }
}

class _QuarterTile extends StatelessWidget {
  const _QuarterTile(this.x, {required this.current, required this.onOpen});
  final HizbQuarter x;
  final bool current;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final quran = context.services.content.quran;
    final s = quran.surah(x.start.surah);
    // Opening words: the canonical ayah text, minus the leading rub' al-hizb sign
    // (the quarter is shown in the badge). QuranText applies the display map.
    final text = quran.text(x.start).replaceFirst(RegExp('^۞\\s*'), '');
    final badge = x.quarter == 0 ? context.num(x.hizb) : '${context.num(x.quarter)}/${context.num(4)}';
    final where = l.quranQuarterLine(
      l.quranSurahTitle(surahName(context, s)),
      context.num(x.start.ayah),
      context.num(x.page),
    );
    return _Entry(
      key: Key('quarter-${x.n}'),
      badge: StarBadge(label: badge, small: x.quarter != 0),
      title: ExcludeSemantics(child: QuranText(text, size: 20, maxLines: 1)),
      subtitle: where,
      semanticsLabel: x.quarter == 0
          ? l.quranHizbN(context.num(x.hizb))
          : l.quranQuarterOfHizb(context.num(x.quarter), context.num(x.hizb)),
      current: current,
      onTap: () => onOpen(x.page),
    );
  }
}

/// Eight-pointed star badge with a number in the middle (as in the printed index).
class StarBadge extends StatelessWidget {
  const StarBadge({super.key, required this.label, this.small = false});
  final String label;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 46,
      height: 46,
      child: CustomPaint(
        painter: _StarPainter(
          fill: Color.lerp(scheme.surface, scheme.primary, 0.25)!,
          stroke: scheme.primary,
          inner: scheme.surface,
        ),
        child: Center(
          child: Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: small ? 11.5 : 14, color: scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  _StarPainter({required this.fill, required this.stroke, required this.inner});
  final Color fill;
  final Color stroke;
  final Color inner;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final half = size.width * 0.31;
    final square = Rect.fromCenter(center: c, width: half * 2, height: half * 2);
    final fillPaint = Paint()..color = fill;
    final strokePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final angle in [0.0, math.pi / 4]) {
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..rotate(angle)
        ..translate(-c.dx, -c.dy)
        ..drawRect(square, fillPaint)
        ..drawRect(square, strokePaint)
        ..restore();
    }
    canvas
      ..drawCircle(c, size.width * 0.28, Paint()..color = inner)
      ..drawCircle(c, size.width * 0.28, strokePaint);
  }

  @override
  bool shouldRepaint(_StarPainter old) => old.fill != fill || old.stroke != stroke || old.inner != inner;
}
