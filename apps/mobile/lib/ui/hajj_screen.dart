import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/hajj.dart';
import '../theme/design_tokens.dart';
import 'adhkar_screen.dart';
import 'l10n_ext.dart';
import 'review_notice.dart';

/// Hajj & Umrah guide (Arabic text from the prototype, pending review).
class HajjScreen extends StatelessWidget {
  const HajjScreen({super.key});

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
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.hajjTitle),
          bottom: TabBar(
            tabs: [for (final k in sections) Tab(key: Key('hajjTab-$k'), text: label(k))],
          ),
        ),
        body: TabBarView(
          children: [
            for (final k in sections)
              ListView(
                key: Key('hajjList-$k'),
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                children: [
                  ReviewNotice(l.hajjReviewNotice, key: const Key('hajjNotice')),
                  if (!context.isArabic) ReviewNotice(l.adhkarArabicOnly),
                  for (final b in guide.sections[k] ?? const <HajjBlock>[]) _Block(block: b),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

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
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (b.label != null)
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
            ),
    );
    return body;
  }
}
