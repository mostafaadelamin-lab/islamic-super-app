import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/tasbih.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'adaptive.dart';
import 'r_icon.dart';

/// Tasbih: a counter per dhikr (built-in or the user's own), big-button or
/// beads mode, nine colours, sound/vibration and a per-day history.
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.services.tasbih;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.tasbihTitle)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: t,
          builder: (context, _) {
            final b = t.book;
            final st = b.current;
            final color = Color(tasbihColors[b.color] ?? tasbihColors['emerald']!);
            final today = b.history[isoDay(DateTime.now())]?[b.phrase] ?? 0;
            final rows = b.historyRows().take(30).toList();
            return LayoutBuilder(
              builder: (context, c) {
                final dial = math.max(160.0, math.min(300.0, math.min(c.maxWidth - 64, c.maxHeight * 0.5)));
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        key: const Key('tasbihPhrase'),
                        initialValue: b.phrase,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l.tasbihPhrase),
                        items: [
                          for (final id in b.ids)
                            DropdownMenuItem(
                              value: id,
                              child: Text(b.textOf(id), overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) => v == null ? null : t.select(v),
                      ),
                      const SizedBox(height: DesignTokens.spaceMd),
                      Text(
                        b.textOf(b.phrase),
                        key: const Key('tasbihPhraseText'),
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: DesignTokens.spaceMd),
                      Center(
                        child: SegmentedButton<TasbihMode>(
                          key: const Key('tasbihMode'),
                          segments: [
                            ButtonSegment(value: TasbihMode.button, label: Text(l.tasbihModeButton)),
                            ButtonSegment(value: TasbihMode.beads, label: Text(l.tasbihModeBeads)),
                          ],
                          selected: {b.mode},
                          onSelectionChanged: (v) => t.setMode(v.first),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceMd),
                      Wrap(
                        spacing: DesignTokens.spaceSm,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final n in TasbihState.targets)
                            ChoiceChip(
                              key: Key('tasbihTarget-$n'),
                              label: Text(context.num(n)),
                              selected: st.target == n,
                              onSelected: (_) => t.setTarget(n),
                            ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spaceXl),
                      Center(
                        child: Semantics(
                          button: true,
                          label: l.tasbihCounter(context.num(st.count), context.num(st.target)),
                          hint: l.tasbihTap,
                          excludeSemantics: true,
                          child: SizedBox.square(
                            dimension: dial,
                            child: CustomPaint(
                              key: Key('tasbihDial-${b.mode.name}'),
                              painter: b.mode == TasbihMode.beads
                                  ? _BeadsPainter(st.count, st.target, color, scheme.surface)
                                  : _RingPainter(st.count / st.target, color, scheme.outline),
                              child: Padding(
                                padding: EdgeInsets.all(b.mode == TasbihMode.beads ? 34 : 14),
                                child: Material(
                                  color: scheme.secondaryContainer,
                                  shape: const CircleBorder(),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    key: const Key('tasbihButton'),
                                    onTap: _tap,
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          FittedBox(
                                            child: Text(
                                              context.num(st.count),
                                              key: const Key('tasbihCount'),
                                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                                color: scheme.onSecondaryContainer,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '/ ${context.num(st.target)}',
                                            style: TextStyle(color: scheme.onSecondaryContainer),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: DesignTokens.spaceMd),
                      Text(l.tasbihTap, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: DesignTokens.spaceLg),
                      Wrap(
                        spacing: DesignTokens.spaceXl,
                        alignment: WrapAlignment.center,
                        children: [
                          Text(l.tasbihRounds(context.num(st.rounds)), key: const Key('tasbihRounds')),
                          Text(l.tasbihTotal(context.num(st.total)), key: const Key('tasbihTotal')),
                          Text(l.tasbihToday(context.num(today)), key: const Key('tasbihToday')),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spaceLg),
                      Wrap(
                        spacing: DesignTokens.spaceMd,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            key: const Key('tasbihUndo'),
                            onPressed: st.count == 0 ? null : t.undo,
                            icon: const RIcon(RIcons.undo),
                            label: Text(l.tasbihUndo),
                          ),
                          OutlinedButton.icon(
                            key: const Key('tasbihReset'),
                            onPressed: t.reset,
                            icon: const RIcon(RIcons.reset),
                            label: Text(l.tasbihReset),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spaceXl),
                      Text(l.tasbihColor, style: Theme.of(context).textTheme.titleSmall),
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
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Color(e.value),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: b.color == e.key ? scheme.onSurface : scheme.outlineVariant,
                                      width: b.color == e.key ? 3 : 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
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
                      const Divider(),
                      Text(l.tasbihMine, style: Theme.of(context).textTheme.titleMedium),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('tasbihNew'),
                              controller: _draft,
                              maxLength: maxCustomText,
                              decoration: InputDecoration(hintText: l.tasbihNewDhikr, counterText: ''),
                              onChanged: (_) => setState(() {}),
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
                                    setState(() {});
                                  },
                            child: Text(l.tasbihAdd),
                          ),
                        ],
                      ),
                      for (final cd in b.custom)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(cd.text),
                          trailing: IconButton(
                            key: Key('tasbihRemove-${cd.id}'),
                            tooltip: l.tasbihRemove(cd.text),
                            icon: const RIcon(RIcons.trash),
                            onPressed: () => t.removeCustom(cd.id),
                          ),
                        ),
                      const Divider(),
                      Text(l.tasbihHistory, style: Theme.of(context).textTheme.titleMedium),
                      if (rows.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
                          child: Text(l.tasbihHistoryEmpty, key: const Key('tasbihHistoryEmpty')),
                        )
                      else ...[
                        for (final (day, id, n) in rows)
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(b.textOf(id)),
                            subtitle: Text(context.num(day)),
                            trailing: Text(context.num(n), style: Theme.of(context).textTheme.titleMedium),
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
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

/// A strand of up to 33 beads around the button; beads already counted are filled.
class _BeadsPainter extends CustomPainter {
  _BeadsPainter(this.count, this.target, this.color, this.empty);
  final int count;
  final int target;
  final Color color;
  final Color empty;

  static const strand = 33;

  @override
  void paint(Canvas canvas, Size size) {
    final n = math.min(target, strand);
    final on = count % n;
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 14;
    const bead = 9.0;
    for (var i = 0; i < n; i++) {
      final a = 2 * math.pi * i / n - math.pi / 2;
      final p = center + Offset(math.cos(a), math.sin(a)) * r;
      final radius = i == on ? bead + 3 : bead;
      canvas.drawCircle(p, radius, Paint()..color = i < on ? color : empty);
      canvas.drawCircle(
        p,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_BeadsPainter old) => old.count != count || old.target != target || old.color != color;
}
