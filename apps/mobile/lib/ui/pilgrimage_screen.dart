import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/hajj.dart';
import '../domain/hajj_flows.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'dua_text.dart';
import 'hajj_screen.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';

/// Umrah and the three kinds of Hajj, each on its own screen.
enum PilgrimageKind { umrah, tamattu, qiran, ifrad }

String pilgrimageTitle(BuildContext context, PilgrimageKind k) {
  final l = context.l10n;
  return switch (k) {
    PilgrimageKind.umrah => l.hajjUmrah,
    PilgrimageKind.tamattu => l.hajjKindTamattu,
    PilgrimageKind.qiran => l.hajjKindQiran,
    PilgrimageKind.ifrad => l.hajjKindIfrad,
  };
}

/// One kind of pilgrimage on its own screen (owner 2026-11-15): the numbered steps pinned at the top and
/// only the chosen step under them, with Previous / Next, so a pilgrim never loses their place.
class PilgrimageScreen extends StatefulWidget {
  const PilgrimageScreen({super.key, required this.kind});
  final PilgrimageKind kind;

  @override
  State<PilgrimageScreen> createState() => _PilgrimageScreenState();
}

class _PilgrimageScreenState extends State<PilgrimageScreen> {
  int _active = 0;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final guide = context.services.content.hajj;
    final kind = widget.kind;
    final umrah = [
      for (final b in guide.sections['umrah'] ?? const <HajjBlock>[])
        if (b.label != null) b,
    ];
    final flow = switch (kind) {
      PilgrimageKind.umrah => const <FlowStep>[],
      PilgrimageKind.tamattu => hajjFlows[HajjType.tamattu]!,
      PilgrimageKind.qiran => hajjFlows[HajjType.qiran]!,
      PilgrimageKind.ifrad => hajjFlows[HajjType.ifrad]!,
    };
    final titles = kind == PilgrimageKind.umrah
        ? [for (final b in umrah) b.title ?? '']
        : [for (final s in flow) s.title];
    final count = titles.length;
    final i = _active.clamp(0, count - 1);
    void go(int n) {
      setState(() => _active = n.clamp(0, count - 1));
      if (_scroll.hasClients) _scroll.jumpTo(0);
    }

    final Widget step;
    if (kind == PilgrimageKind.umrah) {
      step = HajjBlockCard(block: umrah[i]);
    } else {
      final s = flow[i];
      step = Card(
        key: const Key('hajjStepCard'),
        margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(s.title, key: const Key('hajjStepTitle'), style: theme.textTheme.titleLarge),
                const SizedBox(height: DesignTokens.spaceMd),
                DuaText(
                  explainHajjStep(guide, s),
                  textKey: const Key('hajjStepText'),
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.9),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                Text('${l.hajjGuideSource}: ${guide.official.title}', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(pilgrimageTitle(context, kind))),
      body: ReadableWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StepStrip(key: Key('stepStrip-${kind.name}'), titles: titles, active: i, onStep: go, id: kind.name),
            Expanded(
              child: ListView(
                key: Key('pilgrimage-${kind.name}'),
                controller: _scroll,
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                children: [
                  if (!context.isArabic) ReviewNotice(l.adhkarArabicOnly),
                  KeyedSubtree(key: Key('stepCard-${kind.name}-${i + 1}'), child: step),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg),
                    child: StepNav(index: i, count: count, onGo: go, id: kind.name),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The pinned steps: numbered circles joined by a dotted line, the chosen one filled, its short name under
/// it. Scrolls sideways when there are many steps and keeps the chosen one in view.
class StepStrip extends StatefulWidget {
  const StepStrip({super.key, required this.titles, required this.active, required this.onStep, required this.id});
  final List<String> titles;
  final int active;
  final ValueChanged<int> onStep;
  final String id;

  @override
  State<StepStrip> createState() => _StepStripState();
}

class _StepStripState extends State<StepStrip> {
  static const _w = 84.0;
  final _scroll = ScrollController();

  @override
  void didUpdateWidget(StepStrip old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) WidgetsBinding.instance.addPostFrameCallback((_) => _reveal());
  }

  void _reveal() {
    if (!_scroll.hasClients) return;
    final p = _scroll.position;
    final target = (widget.active * _w - (p.viewportDimension - _w) / 2).clamp(0.0, p.maxScrollExtent);
    _scroll.animateTo(target, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ar = context.isArabic;
    String num(int n) => ar ? n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join() : '$n';
    return Material(
      color: theme.scaffoldBackgroundColor,
      elevation: 1,
      child: SizedBox(
        height: 92,
        child: ListView.builder(
          controller: _scroll,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: DesignTokens.spaceSm),
          itemCount: widget.titles.length,
          itemBuilder: (context, i) {
            final on = i == widget.active;
            final done = i < widget.active;
            return SizedBox(
              width: _w,
              child: Stack(
                children: [
                  if (i < widget.titles.length - 1)
                    PositionedDirectional(
                      top: 20,
                      start: _w / 2 + 22,
                      end: -_w / 2 + 22,
                      child: _Dots(color: scheme.secondary),
                    ),
                  Semantics(
                    button: true,
                    selected: on,
                    label: '${num(i + 1)}. ${widget.titles[i]}',
                    child: InkWell(
                      key: Key('stepStrip-${widget.id}-${i + 1}'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => widget.onStep(i),
                      child: ExcludeSemantics(
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: on
                                    ? scheme.primary
                                    : done
                                    ? Color.alphaBlend(scheme.primary.withValues(alpha: 0.18), scheme.surface)
                                    : scheme.secondaryContainer,
                                border: Border.all(color: scheme.primary, width: 2),
                              ),
                              child: Text(
                                num(i + 1),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: on ? scheme.onPrimary : scheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.titles[i].split('·').last.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: on ? scheme.onSurface : scheme.onSurfaceVariant,
                                fontWeight: on ? FontWeight.w600 : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final n = (c.maxWidth / 6).floor().clamp(0, 100);
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [for (var k = 0; k < n; k++) Container(width: 2, height: 2, color: color)],
      );
    },
  );
}
