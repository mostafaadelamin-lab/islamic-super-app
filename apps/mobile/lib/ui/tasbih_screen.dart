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
            final dark = HSLColor.fromColor(color).withLightness(0.22).toColor();
            final theme = Theme.of(context);
            return LayoutBuilder(
              builder: (context, c) {
                final dial = math.max(180.0, math.min(280.0, math.min(c.maxWidth - 96, c.maxHeight * 0.45)));
                return ListView(
                  padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceSm, DesignTokens.spaceLg, DesignTokens.spaceXl),
                  children: [
                    // Dhikr picker: a row of pills.
                    SizedBox(
                      height: 44,
                      child: ListView(
                        key: const Key('tasbihPhrase'),
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (final id in b.ids)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: DesignTokens.spaceSm),
                              child: ChoiceChip(
                                key: Key('tasbihPick-$id'),
                                label: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 180),
                                  child: Text(b.textOf(id), overflow: TextOverflow.ellipsis),
                                ),
                                selected: b.phrase == id,
                                showCheckmark: false,
                                selectedColor: color.withValues(alpha: 0.18),
                                shape: const StadiumBorder(),
                                onSelected: (_) => t.select(id),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    // The counter: a gradient card with the ring and the big tap button.
                    Container(
                      key: const Key('tasbihHero'),
                      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceXl, DesignTokens.spaceLg, DesignTokens.spaceLg),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [color, dark],
                        ),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: Column(
                        children: [
                          Text(
                            b.textOf(b.phrase),
                            key: const Key('tasbihPhraseText'),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600, height: 1.5),
                          ),
                          const SizedBox(height: DesignTokens.spaceLg),
                          Semantics(
                            button: true,
                            label: l.tasbihCounter(context.num(st.count), context.num(st.target)),
                            hint: l.tasbihTap,
                            excludeSemantics: true,
                            child: SizedBox.square(
                              dimension: dial,
                              child: CustomPaint(
                                key: Key('tasbihDial-${b.mode.name}'),
                                painter: b.mode == TasbihMode.beads
                                    ? _BeadsPainter(st.count, st.target, Colors.white, Colors.white.withValues(alpha: 0.15))
                                    : _RingPainter(st.count / st.target, Colors.white, Colors.white.withValues(alpha: 0.2)),
                                child: Padding(
                                  padding: EdgeInsets.all(b.mode == TasbihMode.beads ? 36 : 20),
                                  child: Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    clipBehavior: Clip.antiAlias,
                                    child: InkWell(
                                      key: const Key('tasbihButton'),
                                      onTap: _tap,
                                      splashColor: color.withValues(alpha: 0.2),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            FittedBox(
                                              child: Text(
                                                context.num(st.count),
                                                key: const Key('tasbihCount'),
                                                style: theme.textTheme.displayLarge?.copyWith(color: dark, fontWeight: FontWeight.w700),
                                              ),
                                            ),
                                            Text(
                                              '/ ${context.num(st.target)}',
                                              style: theme.textTheme.titleMedium?.copyWith(color: color),
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
                          const SizedBox(height: DesignTokens.spaceMd),
                          Text(l.tasbihTap, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                          const SizedBox(height: DesignTokens.spaceMd),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _HeroAction(
                                key: const Key('tasbihUndo'),
                                icon: RIcons.undo,
                                label: l.tasbihUndo,
                                onTap: st.count == 0 ? null : t.undo,
                              ),
                              const SizedBox(width: DesignTokens.spaceXl),
                              _HeroAction(key: const Key('tasbihReset'), icon: RIcons.reset, label: l.tasbihReset, onTap: t.reset),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    Row(
                      children: [
                        _Stat(key: const Key('tasbihRounds'), text: l.tasbihRounds(context.num(st.rounds)), color: color),
                        const SizedBox(width: DesignTokens.spaceSm),
                        _Stat(key: const Key('tasbihTotal'), text: l.tasbihTotal(context.num(st.total)), color: color),
                        const SizedBox(width: DesignTokens.spaceSm),
                        _Stat(key: const Key('tasbihToday'), text: l.tasbihToday(context.num(today)), color: color),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    _Panel(
                      children: [
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
                                shape: const StadiumBorder(),
                                showCheckmark: false,
                                selectedColor: color.withValues(alpha: 0.18),
                                selected: st.target == n,
                                onSelected: (_) => t.setTarget(n),
                              ),
                          ],
                        ),
                        const SizedBox(height: DesignTokens.spaceMd),
                        Text(l.tasbihColor, style: theme.textTheme.titleSmall),
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
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: Color(e.value),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: b.color == e.key ? scheme.onSurface : Colors.transparent, width: 3),
                                    ),
                                    child: b.color == e.key ? const RIcon(RIcons.check, color: Colors.white, size: 18) : null,
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
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    _Panel(
                      children: [
                        Text(l.tasbihMine, style: theme.textTheme.titleMedium),
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
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    _Panel(
                      children: [
                        Text(l.tasbihHistory, style: theme.textTheme.titleMedium),
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
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// A round translucent button under the counter (undo, reset).
class _HeroAction extends StatelessWidget {
  const _HeroAction({super.key, required this.icon, required this.label, required this.onTap});
  final RIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = onTap == null ? Colors.white38 : Colors.white;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceSm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RIcon(icon, color: fg, size: 20),
              const SizedBox(width: DesignTokens.spaceXs),
              Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({super.key, required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd, horizontal: DesignTokens.spaceXs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(DesignTokens.spaceLg),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
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
