import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/hadith.dart' show loadGzipAsset;
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// A simplified explanation of a hadith, quoted from a published hadith
/// encyclopedia (source in docs/CONTENT_SOURCES.md; never written by us).
class HadithExplanation {
  const HadithExplanation({
    required this.title,
    required this.explanation,
    this.grade,
    this.attribution,
    this.hints = const [],
  });
  final String title;
  final String explanation;
  final String? grade;
  final String? attribution;
  final List<String> hints;
}

/// Explanations keyed by "book:number" (built by tools/hadith_explained.py).
class HadithExplanations {
  HadithExplanations(this._entries, this._map);
  final Map<String, dynamic> _entries;
  final Map<String, dynamic> _map;

  static const asset = 'assets/hadith/explained.v1.json.gz';
  static Future<HadithExplanations>? _loading;

  static Future<HadithExplanations> load() => _loading ??= loadGzipAsset(rootBundle, asset).then(parse);

  /// Tests: use [e] instead of reading the asset.
  @visibleForTesting
  static void debugUse(HadithExplanations e) => _loading = SynchronousFuture(e);

  static HadithExplanations parse(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return HadithExplanations(j['entries'] as Map<String, dynamic>, j['map'] as Map<String, dynamic>);
  }

  int get length => _map.length;

  /// Numbers of the hadiths of [book] that have an explanation, in order.
  List<int> numbers(String book) {
    final prefix = '$book:';
    return _map.keys
        .where((k) => k.startsWith(prefix))
        .map((k) => int.tryParse(k.substring(prefix.length)))
        .whereType<int>()
        .toList()
      ..sort();
  }

  HadithExplanation? of(String book, int n) {
    final id = _map['$book:$n'] as String?;
    final e = id == null ? null : _entries[id] as Map<String, dynamic>?;
    if (e == null) return null;
    return HadithExplanation(
      title: e['title'] as String,
      explanation: e['explanation'] as String,
      grade: e['grade'] as String?,
      attribution: e['attribution'] as String?,
      hints: [for (final h in (e['hints'] as List? ?? const [])) h as String],
    );
  }
}

/// "Simplified explanation" button for one hadith; hidden when there is none.
class HadithExplainButton extends StatelessWidget {
  const HadithExplainButton({super.key, required this.book, required this.n});
  final String book;
  final int n;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HadithExplanations>(
      future: HadithExplanations.load(),
      builder: (context, snap) {
        final e = snap.data?.of(book, n);
        if (e == null) return const SizedBox.shrink();
        return TextButton.icon(
          key: Key('hadithExplain-$n'),
          icon: const RIcon(RIcons.book, size: 20),
          label: Text(context.l10n.hadithExplain),
          onPressed: () => showHadithExplanation(context, e),
        );
      },
    );
  }
}

/// «الشرح المبسّط» shown under a hadith (owner 2026-11-15: visible, not
/// hidden behind a button): the start of the explanation, and the whole text
/// with the grade and benefits on «اقرأ الشرح كاملًا». Hidden when there is none.
class HadithExplainSection extends StatelessWidget {
  const HadithExplainSection({super.key, required this.book, required this.n});
  final String book;
  final int n;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HadithExplanations>(
      future: HadithExplanations.load(),
      builder: (context, snap) {
        final e = snap.data?.of(book, n);
        if (e == null) return const SizedBox.shrink();
        final l = context.l10n;
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        return Container(
          key: Key('hadithExplain-$n'),
          margin: const EdgeInsets.only(top: DesignTokens.spaceMd),
          padding: const EdgeInsetsDirectional.fromSTEB(
            DesignTokens.spaceMd,
            DesignTokens.spaceSm,
            DesignTokens.spaceMd,
            0,
          ),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: BorderDirectional(start: BorderSide(color: scheme.primary, width: 3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  RIcon(RIcons.book, size: 18, color: scheme.primary),
                  const SizedBox(width: DesignTokens.spaceXs),
                  Text(
                    l.hadithExplain,
                    style: theme.textTheme.titleSmall?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceXs),
              Text(
                e.explanation.trim(),
                key: Key('hadithExplainText-$n'),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textDirection: TextDirection.rtl,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.8),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  key: Key('hadithExplainMore-$n'),
                  onPressed: () => showHadithExplanation(context, e),
                  child: Text(l.hadithExplainMore),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Future<void> showHadithExplanation(BuildContext context, HadithExplanation e) {
  final l = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final body = theme.textTheme.bodyLarge?.copyWith(height: 1.9);
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          key: const Key('hadithExplainSheet'),
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceXl),
          children: [
            Text(l.hadithExplain, style: theme.textTheme.titleLarge?.copyWith(color: scheme.primary)),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(e.title, style: theme.textTheme.titleMedium),
            if (e.grade != null || e.attribution != null)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
                child: Text(
                  [if (e.attribution != null) e.attribution!, if (e.grade != null) l.hadithGrade(e.grade!)].join(' · '),
                  style: theme.textTheme.labelMedium?.copyWith(color: scheme.secondary),
                ),
              ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(e.explanation, style: body),
            if (e.hints.isNotEmpty) ...[
              const SizedBox(height: DesignTokens.spaceLg),
              Text(l.hadithBenefits, style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary)),
              const SizedBox(height: DesignTokens.spaceSm),
              for (final h in e.hints)
                Padding(
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                  child: Text('• $h', style: body),
                ),
            ],
            const SizedBox(height: DesignTokens.spaceMd),
            Text(l.hadithExplainSource, style: theme.textTheme.bodySmall),
          ],
        ),
      );
    },
  );
}
