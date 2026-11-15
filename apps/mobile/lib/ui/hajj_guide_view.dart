import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/hajj_guide.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'adhkar_screen.dart' show CopyButton;
import 'hajj_scene_view.dart';
import 'l10n_ext.dart';
import 'mushaf_page.dart' show AyahMarker;
import 'review_notice.dart' show duaStyle;

/// The Hajj & Umrah guide's steps (owner 2026-11-16): each step's picture, the official guide's words for
/// it, then every sunnah, dhikr and ayah of it in full, each with its reference. Only lays out the texts of
/// hajj-guide.v2.json; nothing religious is written here.

String _arabicNum(int n) => n.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join();

/// Text with ayahs in it: plain words in the UI font, ayahs in the Complex's text and font with their marks.
class GuideSegsText extends StatelessWidget {
  const GuideSegsText(this.segs, {super.key, this.style});
  final List<GuideSeg> segs;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.9);
    return Text.rich(
      TextSpan(children: [for (final s in segs) ...quranAwareSpans(context, s, base)]),
      textDirection: TextDirection.rtl,
      style: base,
    );
  }
}

/// The spans of one run of a text.
List<InlineSpan> quranAwareSpans(BuildContext context, GuideSeg s, TextStyle? base) {
  switch (s) {
    case TextSeg(:final text):
      return [TextSpan(text: text)];
    case final QuranSeg q:
      final c = context.services.content;
      final scheme = Theme.of(context).colorScheme;
      final ink = AppTheme.of(context, 'paperInk');
      final size = (base?.fontSize ?? 16) + 4;
      final quran = TextStyle(fontFamily: DesignTokens.fontQuran, fontSize: size, height: 2.0, color: ink);
      final name = c.quran.surah(q.surah).nameAr;
      final ref = q.from == q.to ? _arabicNum(q.from) : '${_arabicNum(q.from)}–${_arabicNum(q.to)}';
      return [
        TextSpan(
          text: '﴿',
          style: TextStyle(color: scheme.primary),
        ),
        if (q.part case final part?)
          TextSpan(text: c.renderMap.forDisplay(part), style: quran)
        else
          for (final (i, t) in q.texts.indexed) ...[
            TextSpan(text: c.renderMap.forDisplay(t), style: quran),
            const TextSpan(text: ' '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: AyahMarker(number: q.from + i, size: size * 1.1, color: scheme.primary, ink: ink),
            ),
            if (i < q.texts.length - 1) const TextSpan(text: ' '),
          ],
        TextSpan(
          text: '﴾',
          style: TextStyle(color: scheme.primary),
        ),
        TextSpan(
          text: ' [$name: $ref] ',
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
        ),
      ];
  }
}

class _Source extends StatelessWidget {
  const _Source(this.src);
  final String src;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
      child: Text(
        '${context.l10n.hajjRef}: $src',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _Notes extends StatelessWidget {
  const _Notes(this.notes);
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final n in notes)
          Text(n, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class GuideItemView extends StatelessWidget {
  const GuideItemView({super.key, required this.item});
  final GuideItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final it = item;
    final shaded = BoxDecoration(
      color: scheme.secondaryContainer,
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
    );
    Widget hadithBox(Widget child) => Container(
      padding: const EdgeInsetsDirectional.only(start: DesignTokens.spaceMd),
      decoration: BoxDecoration(
        border: BorderDirectional(start: BorderSide(color: scheme.secondary, width: 3)),
      ),
      child: child,
    );
    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.9);
    final Widget child = switch (it.kind) {
      GuideItemKind.text => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GuideSegsText(it.segs, key: const Key('guideText')),
          _Source(it.src),
          _Notes(it.notes),
        ],
      ),
      GuideItemKind.hadith => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          hadithBox(GuideSegsText(it.segs, key: const Key('guideHadith'))),
          _Source(it.src),
          _Notes(it.notes),
        ],
      ),
      GuideItemKind.say => Container(
        key: const Key('guideSay'),
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        decoration: shaded,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GuideSegsText(it.segs, style: duaStyle(context, size: 19).copyWith(color: scheme.onSecondaryContainer)),
            Row(
              children: [
                if (it.times case final n?)
                  Container(
                    key: const Key('guideSayTimes'),
                    padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: 2),
                    decoration: BoxDecoration(color: scheme.primary, borderRadius: BorderRadius.circular(20)),
                    child: Text(
                      context.l10n.hajjTimes(context.isArabic ? _arabicNum(n) : '$n'),
                      style: theme.textTheme.labelMedium?.copyWith(color: scheme.onPrimary),
                    ),
                  ),
                const Spacer(),
                CopyButton(
                  text: [
                    for (final s in it.segs)
                      if (s is TextSeg) s.text,
                  ].join(),
                ),
              ],
            ),
            _Source(it.src),
            _Notes(it.notes),
          ],
        ),
      ),
      GuideItemKind.quran => Container(
        key: Key(it.say ? 'guideSay' : 'guideQuran'),
        padding: it.say ? const EdgeInsets.all(DesignTokens.spaceMd) : EdgeInsets.zero,
        decoration: it.say ? shaded : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (it.citeText case final cite?) ...[
              hadithBox(Text(cite, style: body)),
              if (it.citeSrc case final s?) _Source(s),
              const SizedBox(height: DesignTokens.spaceSm),
            ],
            GuideSegsText([it.quran!], key: const Key('guideQuranText'), style: body),
          ],
        ),
      ),
      GuideItemKind.table => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Table(
            key: const Key('guideTable'),
            border: TableBorder.all(color: scheme.outlineVariant),
            columnWidths: const {0: IntrinsicColumnWidth(), 1: IntrinsicColumnWidth()},
            children: [
              TableRow(
                decoration: BoxDecoration(color: scheme.surfaceContainer),
                children: [for (final h in it.head) _cell(context, h, bold: true)],
              ),
              for (final r in it.rows) TableRow(children: [for (final c in r) _cell(context, c)]),
            ],
          ),
          _Source(it.src),
        ],
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
      child: child,
    );
  }

  static Widget _cell(BuildContext context, String s, {bool bold = false}) => Padding(
    padding: const EdgeInsets.all(DesignTokens.spaceXs),
    child: Text(s, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
  );
}

/// One part of a step, with its picture when it has one (and that picture is not already shown above).
class GuideSubView extends StatelessWidget {
  const GuideSubView({super.key, required this.id, this.shownScene});
  final String id;
  final String? shownScene;

  @override
  Widget build(BuildContext context) {
    final sub = context.services.content.hajjGuide.subs[id];
    if (sub == null) return const SizedBox.shrink();
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    String tag(String t) => switch (t) {
      'men' => l.hajjTagMen,
      'women' => l.hajjTagWomen,
      _ => l.hajjTagFirst,
    };
    return Container(
      key: Key('guideSub-$id'),
      margin: const EdgeInsets.only(top: DesignTokens.spaceLg),
      padding: const EdgeInsets.only(top: DesignTokens.spaceMd),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(sub.title, style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary)),
          if (sub.tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
              child: Wrap(
                spacing: DesignTokens.spaceXs,
                children: [
                  for (final t in sub.tags)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceSm, vertical: 2),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(tag(t), style: theme.textTheme.labelMedium),
                    ),
                ],
              ),
            ),
          if (sub.scene case final s? when s != shownScene) HajjSceneView(id: s),
          for (final it in sub.items) GuideItemView(item: it),
        ],
      ),
    );
  }
}

/// A whole step: picture, the official guide's words (when named), then each part in full.
class GuideStepView extends StatelessWidget {
  const GuideStepView({super.key, required this.stepId, this.label, this.title, this.dalil, this.kind = 'umrah'});
  final String stepId;
  final String? label;
  final String? title;
  final String? dalil;
  final String kind;

  @override
  Widget build(BuildContext context) {
    final g = context.services.content.hajjGuide;
    final step = g.steps[stepId];
    if (step == null) return const SizedBox.shrink();
    final l = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final official = g.official(dalil, kind);
    return Card(
      key: Key('guideStep-$stepId'),
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (label case final s?) Text(s, style: theme.textTheme.labelLarge?.copyWith(color: scheme.primary)),
              Text(title ?? step.title, key: const Key('hajjStepTitle'), style: theme.textTheme.titleLarge),
              if (step.scene case final s?) HajjSceneView(id: s),
              if (official != null)
                Container(
                  key: const Key('guideOfficial'),
                  margin: const EdgeInsets.only(top: DesignTokens.spaceSm),
                  padding: const EdgeInsets.all(DesignTokens.spaceMd),
                  decoration: BoxDecoration(
                    border: Border.all(color: scheme.outlineVariant),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(l.hajjOfficialGuide, style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary)),
                      GuideSegsText(official, key: const Key('hajjStepText')),
                      _Source(g.officialTitle),
                    ],
                  ),
                ),
              for (final k in step.subs) GuideSubView(id: k, shownScene: step.scene),
            ],
          ),
        ),
      ),
    );
  }
}

/// The official guide in full, its ayahs in the KFGQPC text.
class OfficialGuideCard extends StatelessWidget {
  const OfficialGuideCard({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.services.content.hajjGuide;
    final l = context.l10n;
    final theme = Theme.of(context);
    Widget heading(String s) => Padding(
      padding: const EdgeInsets.only(top: DesignTokens.spaceMd, bottom: DesignTokens.spaceSm),
      child: Text(s, style: theme.textTheme.titleMedium),
    );
    Widget numbered(int i, List<GuideSeg> segs) => Padding(
      padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            margin: const EdgeInsetsDirectional.only(top: 4, end: DesignTokens.spaceSm),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer, shape: BoxShape.circle),
            child: Text(
              _arabicNum(i + 1),
              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: GuideSegsText(segs)),
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
              for (final t in g.officialTypes)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                  child: GuideSegsText([TextSeg('${t.name}: '), ...t.segs]),
                ),
              GuideSegsText(g.officialTypesNote),
              heading(l.hajjGuideUmrah),
              for (final (i, p) in g.officialUmrah.indexed) numbered(i, p),
              heading(l.hajjGuideHajj),
              for (final (i, p) in g.officialHajj.indexed) numbered(i, p),
              _Source(g.officialTitle),
            ],
          ),
        ),
      ),
    );
  }
}

/// The sources the guide quotes, and the typing errors of the digital copy that were corrected.
class GuideSourcesCard extends StatelessWidget {
  const GuideSourcesCard({super.key});

  @override
  Widget build(BuildContext context) {
    final g = context.services.content.hajjGuide;
    final l = context.l10n;
    final theme = Theme.of(context);
    return Card(
      key: const Key('guideSources'),
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.hajjSources, style: theme.textTheme.titleMedium),
              for (final s in g.sources)
                Padding(
                  padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
                  child: Text(
                    [s.title, ?s.author, ?s.publisher, ?s.edition].join(' — '),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(l.hajjGuideCorrections, style: theme.textTheme.bodySmall),
                children: [
                  for (final c in g.corrections)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(c, style: theme.textTheme.bodySmall),
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
