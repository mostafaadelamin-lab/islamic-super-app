import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/tasbih.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'adaptive.dart';
import 'misbaha.dart';
import 'r_icon.dart';

/// Tasbih: a counter per dhikr (built-in or the user's own), big beads in the middle (several bead styles and
/// colours, all drawn by the app) or a big button, the count beside them, the dhikr and its virtue (Hisn
/// al-Muslim) on top; change dhikr, history and the look in sheets (owner, 2026-11-17).
class TasbihScreen extends StatefulWidget {
  const TasbihScreen({super.key});

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  final _draft = TextEditingController();

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  Future<void> _tap() async {
    final t = context.services.tasbih;
    final book = t.book;
    final round = await t.tap();
    if (book.sound) await SystemSound.play(SystemSoundType.click);
    if (!book.vibrate) return;
    if (round) {
      await HapticFeedback.heavyImpact();
    } else {
      await HapticFeedback.selectionClick();
    }
  }

  Future<void> _confirmClear() async {
    final l = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l.tasbihClearConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.tasbihCancel)),
          TextButton(
            key: const Key('tasbihClearOk'),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.tasbihClear),
          ),
        ],
      ),
    );
    if (ok == true && mounted) await context.services.tasbih.clearHistory();
  }

  /// The virtue of a built-in dhikr, quoted as printed in Hisn al-Muslim («فضل التسبيح والتحميد،
  /// والتهليل، والتكبير»); none for the others (owner rule: religious text only from a published source).
  static const _virtueItem = {'tasbih': 4, 'tahmid': 7, 'takbir': 3, 'tahlil': 10};
  static const _virtueChapter = 'فضل التسبيح والتحميد ، والتهليل ، والتكبير';

  String? _virtue(String id) {
    final k = _virtueItem[id];
    if (k == null) return null;
    for (final ch in context.services.content.adhkar.hisn) {
      if (ch.title == _virtueChapter && k < ch.items.length) return ch.items[k];
    }
    return null;
  }

  String _styleName(BeadStyle v) {
    final l = context.l10n;
    return switch (v) {
      BeadStyle.glossy => l.tasbihStyleGlossy,
      BeadStyle.marble => l.tasbihStyleMarble,
      BeadStyle.wood => l.tasbihStyleWood,
      BeadStyle.pearl => l.tasbihStylePearl,
      BeadStyle.crystal => l.tasbihStyleCrystal,
    };
  }

  Future<void> _sheet(Key key, Widget Function(BuildContext context) body) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => ListenableBuilder(
      listenable: context.services.tasbih,
      builder: (ctx, _) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.85),
          child: SingleChildScrollView(
            key: key,
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceLg),
            child: body(ctx),
          ),
        ),
      ),
    ),
  );

  /// Bead style, colour, counter shape, sound and vibration.
  Future<void> _lookSheet() => _sheet(const Key('tasbihLookSheet'), (ctx) {
    final l = context.l10n;
    final t = context.services.tasbih;
    final b = t.book;
    final theme = Theme.of(ctx);
    final scheme = theme.colorScheme;
    final color = Color(tasbihColors[b.color] ?? tasbihColors['emerald']!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.tasbihStyle, style: theme.textTheme.titleMedium),
        const SizedBox(height: DesignTokens.spaceSm),
        Wrap(
          spacing: DesignTokens.spaceSm,
          runSpacing: DesignTokens.spaceSm,
          children: [
            for (final v in BeadStyle.values)
              ChoiceChip(
                key: Key('tasbihStyle-${v.name}'),
                avatar: BeadSwatch(color: color, style: v, size: 26),
                label: Text(_styleName(v)),
                selected: b.style == v,
                showCheckmark: false,
                onSelected: (_) => t.setStyle(v),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        Text(l.tasbihColor, style: theme.textTheme.titleMedium),
        const SizedBox(height: DesignTokens.spaceSm),
        Wrap(
          spacing: DesignTokens.spaceSm,
          runSpacing: DesignTokens.spaceSm,
          children: [
            for (final e in tasbihColors.entries)
              Semantics(
                selected: b.color == e.key,
                button: true,
                label: e.key,
                child: InkWell(
                  key: Key('tasbihColor-${e.key}'),
                  customBorder: const CircleBorder(),
                  onTap: () => t.setColor(e.key),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: b.color == e.key ? scheme.onSurface : Colors.transparent, width: 2.5),
                    ),
                    child: BeadSwatch(color: Color(e.value), style: b.style, size: 38),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: DesignTokens.spaceMd),
        Center(
          child: SegmentedButton<TasbihMode>(
            key: const Key('tasbihMode'),
            segments: [
              ButtonSegment(value: TasbihMode.beads, label: Text(l.tasbihModeBeads)),
              ButtonSegment(value: TasbihMode.button, label: Text(l.tasbihModeButton)),
            ],
            selected: {b.mode},
            onSelectionChanged: (v) => t.setMode(v.first),
          ),
        ),
        SwitchListTile(
          key: const Key('tasbihSound'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.tasbihSound),
          value: b.sound,
          onChanged: t.setSound,
        ),
        SwitchListTile(
          key: const Key('tasbihVibrate'),
          contentPadding: EdgeInsets.zero,
          title: Text(l.tasbihVibrate),
          value: b.vibrate,
          onChanged: t.setVibrate,
        ),
      ],
    );
  });

  /// The list of adhkar with their counts, the target, and the user's own adhkar.
  Future<void> _dhikrSheet() => _sheet(const Key('tasbihDhikrSheet'), (ctx) {
    final l = context.l10n;
    final t = context.services.tasbih;
    final b = t.book;
    final theme = Theme.of(ctx);
    final scheme = theme.colorScheme;
    final color = Color(tasbihColors[b.color] ?? tasbihColors['emerald']!);
    return StatefulBuilder(
      builder: (ctx, setLocal) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.tasbihPickDhikr, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
          const SizedBox(height: DesignTokens.spaceSm),
          for (final id in b.ids)
            Material(
              color: b.phrase == id ? color.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              child: ListTile(
                key: Key('tasbihPick-$id'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.radiusMd)),
                title: Text(b.textOf(id), style: theme.textTheme.titleMedium),
                subtitle: (b.counters[id]?.count ?? 0) > 0
                    ? Text(l.tasbihCounter(context.num(b.counters[id]!.count), context.num(b.counters[id]!.target)))
                    : null,
                trailing: id.startsWith('c')
                    ? IconButton(
                        key: Key('tasbihRemove-$id'),
                        tooltip: l.tasbihRemove(b.textOf(id)),
                        icon: const RIcon(RIcons.trash),
                        onPressed: () => t.removeCustom(id),
                      )
                    : Text(
                        l.tasbihTimes(context.num(b.counters[id]?.target ?? 33)),
                        style: theme.textTheme.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                onTap: () {
                  t.select(id);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          const Divider(height: DesignTokens.spaceLg),
          Text(l.tasbihTarget, style: theme.textTheme.titleSmall),
          const SizedBox(height: DesignTokens.spaceXs),
          Wrap(
            spacing: DesignTokens.spaceSm,
            children: [
              for (final n in TasbihState.targets)
                ChoiceChip(
                  key: Key('tasbihTarget-$n'),
                  label: Text(context.num(n)),
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                  selectedColor: color.withValues(alpha: 0.18),
                  selected: t.state.target == n,
                  onSelected: (_) => t.setTarget(n),
                ),
            ],
          ),
          const SizedBox(height: DesignTokens.spaceMd),
          Text(l.tasbihMine, style: theme.textTheme.titleSmall),
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('tasbihNew'),
                  controller: _draft,
                  maxLength: maxCustomText,
                  decoration: InputDecoration(hintText: l.tasbihNewDhikr, counterText: ''),
                  onChanged: (_) => setLocal(() {}),
                ),
              ),
              const SizedBox(width: DesignTokens.spaceSm),
              FilledButton(
                key: const Key('tasbihAdd'),
                onPressed: _draft.text.trim().isEmpty || b.custom.length >= maxCustomAdhkar
                    ? null
                    : () async {
                        await t.addCustom(_draft.text);
                        _draft.clear();
                        setLocal(() {});
                      },
                child: Text(l.tasbihAdd),
              ),
            ],
          ),
        ],
      ),
    );
  });

  /// Taps per day and dhikr, with "clear".
  Future<void> _historySheet() => _sheet(const Key('tasbihHistorySheet'), (ctx) {
    final l = context.l10n;
    final b = context.services.tasbih.book;
    final theme = Theme.of(ctx);
    final rows = b.historyRows().take(60).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.tasbihHistoryOpen, textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceLg),
            child: Text(l.tasbihHistoryEmpty, key: const Key('tasbihHistoryEmpty'), textAlign: TextAlign.center),
          )
        else ...[
          for (final (day, id, n) in rows)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(b.textOf(id)),
              subtitle: Text(context.num(day)),
              trailing: Text(context.num(n), style: theme.textTheme.titleMedium),
            ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              key: const Key('tasbihClearHistory'),
              onPressed: _confirmClear,
              icon: const RIcon(RIcons.trash),
              label: Text(l.tasbihClearHistory),
            ),
          ),
        ],
      ],
    );
  });

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.services.tasbih;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tasbihTitle),
        actions: [
          IconButton(
            key: const Key('tasbihLook'),
            tooltip: l.tasbihChangeLook,
            icon: const RIcon(RIcons.palette),
            onPressed: _lookSheet,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: t,
        builder: (context, _) {
          final b = t.book;
          final st = b.current;
          final color = Color(tasbihColors[b.color] ?? tasbihColors['emerald']!);
          final deep = HSLColor.fromColor(color).withLightness(0.24).toColor();
          final today = b.history[isoDay(DateTime.now())]?[b.phrase] ?? 0;
          final theme = Theme.of(context);
          final scheme = theme.colorScheme;
          final virtue = _virtue(b.phrase);
          final counter = Semantics(
            button: true,
            label: l.tasbihCounter(context.num(st.count), context.num(st.target)),
            hint: l.tasbihTap,
            excludeSemantics: true,
            child: b.mode == TasbihMode.beads
                ? KeyedSubtree(
                    key: const Key('tasbihButton'),
                    child: RealMisbaha(count: st.count, target: st.target, onCount: _tap, bead: color, style: b.style),
                  )
                : Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: CustomPaint(
                        key: const Key('tasbihDial-button'),
                        painter: _RingPainter(st.count / st.target, color, color.withValues(alpha: 0.18)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Material(
                            color: color,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            elevation: 4,
                            child: InkWell(
                              key: const Key('tasbihButton'),
                              onTap: _tap,
                              child: Center(
                                child: Text(
                                  l.tasbihTap,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          );
          return DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.10), scheme.surface, color.withValues(alpha: 0.08)],
              ),
            ),
            child: ReadableWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spaceLg,
                  DesignTokens.spaceSm,
                  DesignTokens.spaceLg,
                  DesignTokens.spaceMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      b.textOf(b.phrase),
                      key: const Key('tasbihPhraseText'),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.5),
                    ),
                    if (virtue != null) ...[
                      const SizedBox(height: DesignTokens.spaceSm),
                      Container(
                        key: const Key('tasbihVirtue'),
                        padding: const EdgeInsets.all(DesignTokens.spaceMd),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10)],
                        ),
                        child: Column(
                          children: [
                            Text(
                              virtue,
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.rtl,
                              style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                            ),
                            Text(
                              l.tasbihVirtueSource,
                              style: theme.textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: DesignTokens.spaceSm),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: counter),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Expanded(
                            flex: 3,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(l.tasbihCount, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
                                FittedBox(
                                  child: Text(
                                    context.num(st.count),
                                    key: const Key('tasbihCount'),
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: color,
                                    ),
                                  ),
                                ),
                                Text(
                                  l.tasbihOfTarget(context.num(st.target)),
                                  style: theme.textTheme.titleSmall?.copyWith(color: deep),
                                ),
                                const SizedBox(height: DesignTokens.spaceMd),
                                _RoundAction(
                                  key: const Key('tasbihUndo'),
                                  icon: RIcons.undo,
                                  label: l.tasbihUndo,
                                  onTap: st.count == 0 ? null : t.undo,
                                ),
                                const SizedBox(height: DesignTokens.spaceSm),
                                _RoundAction(
                                  key: const Key('tasbihReset'),
                                  icon: RIcons.reset,
                                  label: l.tasbihReset,
                                  onTap: t.reset,
                                ),
                                const SizedBox(height: DesignTokens.spaceSm),
                                InkWell(
                                  key: const Key('tasbihLookSmall'),
                                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                                  onTap: _lookSheet,
                                  child: Column(
                                    children: [
                                      BeadSwatch(color: color, style: b.style, size: 34),
                                      Text(l.tasbihChangeLook, style: theme.textTheme.labelMedium),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Row(
                      children: [
                        _Stat(
                          key: const Key('tasbihRounds'),
                          text: l.tasbihRounds(context.num(st.rounds)),
                          color: color,
                        ),
                        const SizedBox(width: DesignTokens.spaceSm),
                        _Stat(key: const Key('tasbihTotal'), text: l.tasbihTotal(context.num(st.total)), color: color),
                        const SizedBox(width: DesignTokens.spaceSm),
                        _Stat(key: const Key('tasbihToday'), text: l.tasbihToday(context.num(today)), color: color),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BigAction(
                          key: const Key('tasbihChangeDhikr'),
                          icon: RIcons.beads,
                          label: l.tasbihChangeDhikr,
                          color: color,
                          onTap: _dhikrSheet,
                        ),
                        _BigAction(
                          key: const Key('tasbihHistoryOpen'),
                          icon: RIcons.calendarCheck,
                          label: l.tasbihHistoryOpen,
                          color: color,
                          onTap: _historySheet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A small round button with its label under it (undo, reset).
class _RoundAction extends StatelessWidget {
  const _RoundAction({super.key, required this.icon, required this.label, required this.onTap});
  final RIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle),
              child: RIcon(icon, size: 20, color: onTap == null ? scheme.outline : scheme.onSurface),
            ),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

/// A big round button with its label under it (change dhikr, history).
class _BigAction extends StatelessWidget {
  const _BigAction({super.key, required this.icon, required this.label, required this.color, required this.onTap});
  final RIconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceXs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.10), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: RIcon(icon, color: color, size: 28),
            ),
            const SizedBox(height: DesignTokens.spaceXs),
            Text(label, style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd, horizontal: DesignTokens.spaceXs),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.fraction, this.color, this.track);
  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(5);
    canvas.drawArc(
      rect,
      0,
      2 * math.pi,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..color = track,
    );
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0, 1),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.fraction != fraction || old.color != color;
}
