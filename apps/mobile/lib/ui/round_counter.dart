import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/hajj_rounds.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';

/// Where the counts live (kept when the app is closed, like the website's "rattil.rounds").
const roundsPrefsKey = 'hajj.rounds';

/// Counter of tawaf/sa'i rounds or jamarat pebbles under a guide step, like the website's RoundCounter:
/// seven dots that light up, "I finished a round", undo and reset.
class RoundCounter extends StatefulWidget {
  const RoundCounter({super.key, required this.tool});
  final RoundTool tool;

  @override
  State<RoundCounter> createState() => _RoundCounterState();
}

class _RoundCounterState extends State<RoundCounter> {
  Map<RoundTool, int> _read() {
    final raw = context.services.settings.rawJson(roundsPrefsKey);
    if (raw == null) return sanitizeRounds(null);
    try {
      return sanitizeRounds(jsonDecode(raw));
    } on FormatException {
      return sanitizeRounds(null);
    }
  }

  /// Reads the latest counts first, so two counters on one step never undo each other.
  Future<void> _change(int? delta) async {
    final now = _read();
    final next = delta == null ? {...now, widget.tool: 0} : addRound(now, widget.tool, delta);
    await context.services.settings.setRawJson(roundsPrefsKey, jsonEncode(roundsToJson(next)));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final n = _read()[widget.tool] ?? 0;
    final done = n >= roundsTarget;
    String num(int v) => context.num(v);
    final title = switch (widget.tool) {
      RoundTool.tawaf => l.hajjCounterTawaf,
      RoundTool.sai => l.hajjCounterSai,
      RoundTool.jamarat => l.hajjCounterJamarat,
    };
    return Card(
      key: Key('rounds-${widget.tool.name}'),
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < roundsTarget; i++)
                    Container(
                      key: Key('roundDot-${widget.tool.name}-$i'),
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < n ? scheme.primary : Colors.transparent,
                        border: Border.all(color: i < n ? scheme.primary : scheme.outline, width: 2),
                      ),
                      child: Text(
                        num(i + 1),
                        style: theme.textTheme.labelSmall?.copyWith(color: i < n ? scheme.onPrimary : scheme.outline),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceSm),
            Semantics(
              liveRegion: true,
              child: Text(
                done ? l.hajjCounterDone : l.hajjCounterProgress(num(n), num(roundsTarget)),
                key: Key('rounds-${widget.tool.name}-status'),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: done ? scheme.primary : scheme.onSurfaceVariant,
                  fontWeight: done ? FontWeight.w700 : null,
                ),
              ),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: DesignTokens.spaceSm,
              runSpacing: DesignTokens.spaceSm,
              children: [
                FilledButton(
                  key: Key('rounds-${widget.tool.name}-add'),
                  onPressed: done ? null : () => _change(1),
                  child: Text(l.hajjCounterAdd),
                ),
                OutlinedButton(
                  key: Key('rounds-${widget.tool.name}-undo'),
                  onPressed: n == 0 ? null : () => _change(-1),
                  child: Text(l.hajjCounterUndo),
                ),
                OutlinedButton(
                  key: Key('rounds-${widget.tool.name}-reset'),
                  onPressed: n == 0 ? null : () => _change(null),
                  child: Text(l.hajjCounterReset),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
