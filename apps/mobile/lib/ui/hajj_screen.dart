import 'package:flutter/material.dart';

import '../app_services.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'hajj_guide_view.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';

/// The Hajj & Umrah guide by part (owner 2026-11-16, every text from its source in hajj-guide.v2.json):
/// 'ihram' = the miqat of each country and the ihram; 'hajj' = the days of Hajj in full, the pillars,
/// the visit to Madinah, the official guide and the sources. Umrah and each kind of Hajj have their own
/// step-by-step screens (PilgrimageScreen).
class HajjScreen extends StatelessWidget {
  const HajjScreen({super.key, this.initialTab = 0, this.sections = allSections});

  /// Tab opened first.
  final int initialTab;
  final List<String> sections;

  static const allSections = ['hajj', 'ihram'];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String label(String k) => k == 'hajj' ? l.hajjHajj : l.hajjIhram;
    return DefaultTabController(
      length: sections.length,
      initialIndex: initialTab.clamp(0, sections.length - 1),
      child: Scaffold(
        appBar: AppBar(
          title: Text(sections.length == 1 ? label(sections.first) : l.hajjTitle),
          bottom: sections.length == 1
              ? null
              : TabBar(
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
                    ...(k == 'hajj' ? _hajj(context) : _ihram(context)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static List<Widget> _ihram(BuildContext context) => [
    for (final s in context.services.content.hajjGuide.ihram) GuideStepView(stepId: s, label: context.l10n.hajjIhram),
  ];

  static List<Widget> _hajj(BuildContext context) {
    final l = context.l10n;
    final g = context.services.content.hajjGuide;
    String num(int n) => context.isArabic ? _arabicNum(n) : '$n';
    return [
      for (final (i, s) in g.days.indexed)
        GuideStepView(key: Key('hajjStage-${i + 1}'), stepId: s, label: l.hajjStage(num(i + 1))),
      GuideStepView(key: const Key('hajjPillars'), stepId: g.pillars, label: l.hajjHajj),
      GuideStepView(stepId: g.madinah, label: l.hajjMadinah),
      const OfficialGuideCard(),
      const GuideSourcesCard(),
    ];
  }
}

/// "Step n of N" between Previous and Next.
class StepNav extends StatelessWidget {
  const StepNav({super.key, required this.index, required this.count, required this.onGo, required this.id});
  final int index;
  final int count;
  final ValueChanged<int> onGo;
  final String id;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String num(int n) => context.isArabic ? _arabicNum(n) : '$n';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceMd),
      child: Row(
        children: [
          OutlinedButton(
            key: Key('stepPrev-$id'),
            onPressed: index > 0 ? () => onGo(index - 1) : null,
            child: Text(l.hajjStepPrev),
          ),
          Expanded(
            child: Text(
              l.hajjStepOf(num(index + 1), num(count)),
              key: Key('stepCount-$id'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          FilledButton(
            key: Key('stepNext-$id'),
            onPressed: index < count - 1 ? () => onGo(index + 1) : null,
            child: Text(l.hajjStepNext),
          ),
        ],
      ),
    );
  }
}

String _arabicNum(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();
