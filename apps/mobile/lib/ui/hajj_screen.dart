import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/hajj.dart';
import '../domain/hajj_flows.dart';
import '../theme/design_tokens.dart';
import 'adhkar_screen.dart';
import 'hajj_art.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';
import 'steps_flow.dart';
import 'tawaf_plan.dart';
import 'adaptive.dart';

/// Hajj & Umrah guide (Arabic text from the prototype, pending review).
class HajjScreen extends StatelessWidget {
  const HajjScreen({super.key, this.initialTab = 0});

  /// Tab opened first (0 Umrah, 1 Hajj, 2 Ihram), from the Hajj & Umrah section.
  final int initialTab;

  static const sections = ['umrah', 'hajj', 'ihram'];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final guide = context.services.content.hajj;
    String label(String k) => switch (k) {
      'umrah' => l.hajjUmrah,
      'hajj' => l.hajjHajj,
      _ => l.hajjIhram,
    };
    return DefaultTabController(
      length: sections.length,
      initialIndex: initialTab.clamp(0, sections.length - 1),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.hajjTitle),
          bottom: TabBar(
            tabs: [for (final k in sections) Tab(key: Key('hajjTab-$k'), text: label(k))],
          ),
        ),
        body: ReadableWidth(
          child: TabBarView(
            children: [
              for (final k in sections)
                ListView(
                  key: Key('hajjList-$k'),
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                  children: [
                    if (!context.isArabic) ReviewNotice(l.adhkarArabicOnly),
                    for (final (i, b) in (guide.sections[k] ?? const <HajjBlock>[]).indexed) ...[
                      // Numbered steps graphic before the first numbered step (owner, 2026-11-14).
                      if (b.label != null && i == _firstLabelled(guide.sections[k]!))
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            DesignTokens.spaceLg,
                            DesignTokens.spaceMd,
                            DesignTokens.spaceLg,
                            0,
                          ),
                          child: k == 'hajj'
                              ? HajjTypeFlow(guide: guide)
                              : StepsFlow(
                                  key: Key('stepsFlow-$k'),
                                  titles: [
                                    for (final x in guide.sections[k]!)
                                      if (x.label != null) x.title ?? '',
                                  ],
                                  arabic: context.isArabic,
                                  label: k == 'umrah' ? l.hajjUmrah : l.hajjHajj,
                                ),
                        ),
                      _Block(block: b),
                    ],
                    if (k == 'hajj' && !guide.official.isEmpty) OfficialGuideCard(guide: guide.official),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

int _firstLabelled(List<HajjBlock> blocks) => blocks.indexWhere((b) => b.label != null);

class _Block extends StatelessWidget {
  const _Block({required this.block});
  final HajjBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final b = block;
    final body = Directionality(
      textDirection: TextDirection.rtl,
      child: b.kind == 'intro'
          ? Padding(
              padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
              child: Text(b.text ?? '', style: theme.textTheme.bodyLarge),
            )
          : Card(
              margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (hajjSceneFor(b.title) case final scene?)
                    Stack(
                      children: [
                        if (scene == HajjScene.tawaf)
                          // Tawaf map from above: start at the Black Stone, anti-clockwise (owner).
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              DesignTokens.spaceSm,
                              DesignTokens.spaceXl + DesignTokens.spaceSm,
                              DesignTokens.spaceSm,
                              0,
                            ),
                            child: TawafPlan(arabic: context.isArabic),
                          )
                        else
                          HajjArt(key: Key('hajjArt-${scene.name}'), scene: scene),
                        if (b.label != null)
                          PositionedDirectional(
                            top: DesignTokens.spaceSm,
                            start: DesignTokens.spaceSm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 4),
                              decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(20)),
                              child: Text(
                                b.label!,
                                style: theme.textTheme.labelLarge?.copyWith(color: scheme.onPrimary),
                              ),
                            ),
                          ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.all(DesignTokens.spaceLg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (b.label != null && hajjSceneFor(b.title) == null)
                          Text(b.label!, style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
                        if (b.title != null) Text(b.title!, style: theme.textTheme.titleMedium),
                        for (final d in b.defs)
                          Padding(
                            padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${d.term}: ',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  TextSpan(text: d.detail),
                                ],
                              ),
                            ),
                          ),
                        for (final item in b.items)
                          Padding(
                            padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Icon(Icons.circle, size: 7, color: scheme.secondary),
                                ),
                                const SizedBox(width: DesignTokens.spaceSm),
                                Expanded(child: Text(item, style: const TextStyle(height: 1.7))),
                              ],
                            ),
                          ),
                        for (final p in b.paragraphs)
                          Padding(
                            padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                            child: Text(p, style: theme.textTheme.bodyMedium),
                          ),
                        if (b.dua != null) ...[
                          const SizedBox(height: DesignTokens.spaceMd),
                          Container(
                            padding: const EdgeInsets.all(DesignTokens.spaceMd),
                            decoration: BoxDecoration(
                              color: scheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                            ),
                            child: Text(b.dua!, style: duaStyle(context).copyWith(color: scheme.onSecondaryContainer)),
                          ),
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: CopyButton(text: b.dua!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
    return body;
  }
}

/// Steps 1, 2, 3… for the chosen Hajj type (tamattu' by default); a tap shows the official
/// guide's own words for that step (owner, 2026-11-14).
class HajjTypeFlow extends StatefulWidget {
  const HajjTypeFlow({super.key, required this.guide});
  final HajjGuide guide;

  @override
  State<HajjTypeFlow> createState() => _HajjTypeFlowState();
}

class _HajjTypeFlowState extends State<HajjTypeFlow> {
  HajjType _type = HajjType.tamattu;

  String _name(HajjType t) => switch (t) {
    HajjType.tamattu => context.l10n.hajjTamattu,
    HajjType.qiran => context.l10n.hajjQiran,
    HajjType.ifrad => context.l10n.hajjIfrad,
  };

  /// The explanation of a step: a paragraph of the official guide, the types of Hajj, or the
  /// app guide's farewell tawaf.
  String _explain(FlowStep step) {
    final o = widget.guide.official;
    if (step.ref == 'types') return [for (final (n, t) in o.types) '$n: $t'].join('\n\n');
    if (step.ref == 'farewell') {
      for (final b in widget.guide.sections['hajj'] ?? const <HajjBlock>[]) {
        if ((b.title ?? '').contains('الوداع')) return [...b.paragraphs, ...b.items].join('\n');
      }
      return '';
    }
    return o.paragraph(step.ref) ?? '';
  }

  void _show(int i, List<FlowStep> steps) {
    final step = steps[i];
    final theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        builder: (ctx, scroll) => Directionality(
          textDirection: TextDirection.rtl,
          child: ListView(
            key: const Key('hajjStepSheet'),
            controller: scroll,
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceXl),
            children: [
              Text('${context.isArabic ? _arabicNum(i + 1) : i + 1}. ${step.title}', style: theme.textTheme.titleLarge),
              const SizedBox(height: DesignTokens.spaceMd),
              Text(_explain(step), style: theme.textTheme.bodyLarge?.copyWith(height: 1.9)),
              const SizedBox(height: DesignTokens.spaceMd),
              Text('${context.l10n.hajjGuideSource}: ${widget.guide.official.title}', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final steps = hajjFlows[_type]!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l.hajjStepsInOrder, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: DesignTokens.spaceSm),
        SegmentedButton<HajjType>(
          key: const Key('hajjTypes'),
          showSelectedIcon: false,
          segments: [
            for (final t in HajjType.values)
              ButtonSegment(
                value: t,
                label: Text(_name(t), key: Key('hajjType-${t.name}')),
              ),
          ],
          selected: {_type},
          onSelectionChanged: (v) => setState(() => _type = v.first),
        ),
        const SizedBox(height: DesignTokens.spaceSm),
        StepsFlow(
          key: Key('stepsFlow-hajj-${_type.name}'),
          titles: [for (final s in steps) s.title],
          arabic: context.isArabic,
          label: '${l.hajjStepsInOrder}: ${_name(_type)}',
          onStep: (i) => _show(i, steps),
        ),
        Padding(
          padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
          child: Text(l.hajjTapStep, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

/// The official guide's text in full: types of Hajj, then Umrah and Hajj paragraph by paragraph.
class OfficialGuideCard extends StatelessWidget {
  const OfficialGuideCard({super.key, required this.guide});
  final OfficialHajjGuide guide;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.9);
    Widget heading(String s) => Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spaceMd, bottom: DesignTokens.spaceSm),
      child: Text(s, style: theme.textTheme.titleMedium),
    );
    Widget numbered(int i, String text) => Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsets.only(top: 4, left: DesignTokens.spaceSm),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainer, shape: BoxShape.circle),
            child: Text(
              context.isArabic ? _arabicNum(i + 1) : '${i + 1}',
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(text, style: body)),
        ],
      ),
    );
    return Card(
      key: const Key('officialHajjGuide'),
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.hajjOfficialGuide, style: theme.textTheme.titleLarge),
              heading(l.hajjGuideTypes),
              for (final (n, t) in guide.types)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$n: ',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(text: t),
                      ],
                    ),
                    style: body,
                  ),
                ),
              Text(guide.typesNote, style: body),
              heading(l.hajjGuideUmrah),
              for (final (i, p) in guide.umrah.indexed) numbered(i, p),
              heading(l.hajjGuideHajj),
              for (final (i, p) in guide.hajj.indexed) numbered(i, p),
              const SizedBox(height: DesignTokens.spaceSm),
              Text('${l.hajjGuideSource}: ${guide.title} — ${guide.publisher}', style: theme.textTheme.bodySmall),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l.hajjGuideCorrections, style: theme.textTheme.bodySmall),
                children: [
                  for (final c in guide.corrections)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('• $c', style: theme.textTheme.bodySmall),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _arabicNum(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();
