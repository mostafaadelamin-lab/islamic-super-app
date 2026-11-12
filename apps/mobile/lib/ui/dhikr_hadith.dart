import 'dart:convert';

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';

/// The hadith a dhikr comes from, its virtue and where it is reported, quoted
/// verbatim from published sources (built by tools/adhkar_hadith.py; sources in
/// docs/CONTENT_SOURCES.md, not shown in the app).
class DhikrHadith {
  const DhikrHadith({this.hadith, this.fadl, this.source});
  final String? hadith;
  final String? fadl;
  final String? source;

  static DhikrHadith _of(Object? j) {
    final m = j as Map<String, dynamic>;
    return DhikrHadith(hadith: m['hadith'] as String?, fadl: m['fadl'] as String?, source: m['source'] as String?);
  }
}

class DhikrHadithMap {
  DhikrHadithMap(this._adhkar, this._hisn);
  final Map<String, dynamic> _adhkar;
  final Map<String, dynamic> _hisn;

  static const asset = 'assets/content/adhkar-hadith.v1.json';
  static Future<DhikrHadithMap?>? _loading;

  static Future<DhikrHadithMap?> load(AssetBundle bundle) => _loading ??= bundle
      .loadString(asset)
      .then<DhikrHadithMap?>((raw) {
        return DhikrHadithMap.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      })
      .catchError((Object _) => null);

  /// Tests set the map directly (asset loading does not finish inside a widget test).
  @visibleForTesting
  static set debugMap(DhikrHadithMap? m) => _loading = m == null ? null : Future.value(m);

  factory DhikrHadithMap.fromJson(Map<String, dynamic> j) =>
      DhikrHadithMap(j['adhkar'] as Map<String, dynamic>, j['hisn'] as Map<String, dynamic>);

  DhikrHadith? forDhikr(int index) => _adhkar['$index'] == null ? null : DhikrHadith._of(_adhkar['$index']);
  DhikrHadith? forHisn(int chapter, int item) =>
      _hisn['$chapter:$item'] == null ? null : DhikrHadith._of(_hisn['$chapter:$item']);
}

/// "The hadith" icon under a dhikr; hidden when no source hadith is linked.
class DhikrHadithButton extends StatelessWidget {
  const DhikrHadithButton({super.key, required this.pick});
  final DhikrHadith? Function(DhikrHadithMap m) pick;

  @override
  Widget build(BuildContext context) => FutureBuilder<DhikrHadithMap?>(
    future: DhikrHadithMap.load(DefaultAssetBundle.of(context)),
    builder: (context, snap) {
      final m = snap.data;
      final h = m == null ? null : pick(m);
      if (h == null) return const SizedBox.shrink();
      final l = context.l10n;
      return TextButton.icon(
        icon: const RIcon(RIcons.book, size: 20),
        label: Text(l.dhikrHadith),
        onPressed: () => showDhikrHadith(context, h),
      );
    },
  );
}

Future<void> showDhikrHadith(BuildContext context, DhikrHadith h) {
  final l = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final body = theme.textTheme.bodyLarge?.copyWith(height: 1.9);
      Widget section(String title, String text) => Padding(
        padding: const EdgeInsets.only(bottom: DesignTokens.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary)),
            const SizedBox(height: DesignTokens.spaceXs),
            Text(text, style: body, textDirection: TextDirection.rtl),
          ],
        ),
      );
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          key: const Key('dhikrHadithSheet'),
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceXl),
          children: [
            if (h.hadith != null) section(l.dhikrHadithText, h.hadith!),
            if (h.fadl != null) section(l.dhikrHadithFadl, h.fadl!),
            if (h.source != null) section(l.dhikrHadithSource, h.source!),
          ],
        ),
      );
    },
  );
}
