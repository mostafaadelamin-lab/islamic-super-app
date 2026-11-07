import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/tasbih.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';

/// Tasbih counter: one big button, a progress ring, target choice; the count
/// is saved after every tap.
class TasbihScreen extends StatelessWidget {
  const TasbihScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final t = context.services.tasbih;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.tasbihTitle)),
      body: ListenableBuilder(
        listenable: t,
        builder: (context, _) {
          final st = t.state;
          return LayoutBuilder(
            builder: (context, c) {
              final dial = math.max(160.0, math.min(300.0, math.min(c.maxWidth - 64, c.maxHeight * 0.5)));
              return SingleChildScrollView(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Column(
                  children: [
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
                    Semantics(
                      button: true,
                      label: l.tasbihCounter(context.num(st.count), context.num(st.target)),
                      hint: l.tasbihTap,
                      excludeSemantics: true,
                      child: SizedBox.square(
                        dimension: dial,
                        child: CustomPaint(
                          painter: _RingPainter(st.count / st.target, scheme.primary, scheme.outline),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Material(
                              color: scheme.secondaryContainer,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: const Key('tasbihButton'),
                                onTap: () async {
                                  final round = await t.tap();
                                  if (round) {
                                    await HapticFeedback.heavyImpact();
                                  } else {
                                    await HapticFeedback.selectionClick();
                                  }
                                },
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
                    const SizedBox(height: DesignTokens.spaceMd),
                    Text(l.tasbihTap, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: DesignTokens.spaceLg),
                    Wrap(
                      spacing: DesignTokens.spaceXl,
                      alignment: WrapAlignment.center,
                      children: [
                        Text(l.tasbihRounds(context.num(st.rounds)), key: const Key('tasbihRounds')),
                        Text(l.tasbihTotal(context.num(st.total)), key: const Key('tasbihTotal')),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceLg),
                    OutlinedButton.icon(
                      key: const Key('tasbihReset'),
                      onPressed: t.reset,
                      icon: const Icon(Icons.restart_alt),
                      label: Text(l.tasbihReset),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
