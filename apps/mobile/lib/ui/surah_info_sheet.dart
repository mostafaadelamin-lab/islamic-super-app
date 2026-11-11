import 'dart:convert';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'widgets.dart' show surahName;

/// One surah card (owner, 2026-11-11): where it was revealed, its order of revelation, a short
/// introduction and the reasons for revelation, verbatim from a published source (see
/// tools/surah_info.py; docs/CONTENT_SOURCES.md).
class SurahInfo {
  SurahInfo(this.n, this.type, this.order, this.intro, this.purposes, this.asbab, this.wahidi);
  factory SurahInfo.fromJson(Map<String, dynamic> j) => SurahInfo(
    j['n'] as int,
    j['type'] as String? ?? '',
    j['order'] as String? ?? '',
    j['intro'] as String? ?? '',
    j['purposes'] as String? ?? '',
    j['asbab'] as String? ?? '',
    [
      for (final w in (j['wahidi'] as List<dynamic>? ?? const []))
        ((w as Map<String, dynamic>)['ayah'] as int, w['text'] as String),
    ],
  );
  final int n;
  final String type;
  final String order;
  final String intro;
  final String purposes;
  final String asbab;
  final List<(int, String)> wahidi;

  static const asset = 'assets/content/surah-info.v1.json';
  static List<SurahInfo>? _all;
  static Future<SurahInfo?> load(BuildContext context, int n) async {
    try {
      _all ??= [
        for (final x
            in (jsonDecode(await DefaultAssetBundle.of(context).loadString(asset)) as Map<String, dynamic>)['surahs']
                as List<dynamic>)
          SurahInfo.fromJson(x as Map<String, dynamic>),
      ];
      return _all!.firstWhere((s) => s.n == n);
    } catch (_) {
      return null;
    }
  }
}

Future<void> showSurahInfo(BuildContext context, int surah) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.75,
    maxChildSize: 0.95,
    builder: (context, scroll) => SurahInfoView(surah: surah, controller: scroll),
  ),
);

class SurahInfoView extends StatelessWidget {
  const SurahInfoView({super.key, required this.surah, this.controller});
  final int surah;
  final ScrollController? controller;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services.content.quran.surah(surah);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return FutureBuilder<SurahInfo?>(
      future: SurahInfo.load(context, surah),
      builder: (context, snap) {
        final info = snap.data;
        Widget para(String t) => Padding(
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
          child: Text(t, textDirection: TextDirection.rtl, style: theme.textTheme.bodyLarge?.copyWith(height: 1.8)),
        );
        Widget chip(String label, String value) => Container(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceSm),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
          ),
          child: Text(
            '$label: $value',
            style: TextStyle(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
          ),
        );
        return ListView(
          key: const Key('surahInfo'),
          controller: controller,
          padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, 0, DesignTokens.spaceLg, DesignTokens.spaceXl),
          children: [
            Text(
              l.quranSurahTitle(surahName(context, s)),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: DesignTokens.spaceSm,
              runSpacing: DesignTokens.spaceSm,
              children: [
                chip(l.surahInfoPlace, s.isMeccan ? l.quranMeccan : l.quranMedinan),
                if (info != null && info.order.isNotEmpty) chip(l.surahInfoOrder, context.num(info.order)),
                chip(l.surahInfoAyahs, context.num(s.ayahCount)),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            if (snap.connectionState != ConnectionState.done)
              const Center(child: CircularProgressIndicator())
            else if (info == null)
              Text(l.surahInfoMissing)
            else ...[
              if (info.intro.isNotEmpty) ...[
                Text(l.surahInfoAbout, style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary)),
                const SizedBox(height: DesignTokens.spaceXs),
                for (final p in info.intro.split('\n')) para(p),
              ],
              const SizedBox(height: DesignTokens.spaceSm),
              ExpansionTile(
                key: const Key('surahAsbab'),
                tilePadding: EdgeInsets.zero,
                leading: RIcon(RIcons.openBook, color: scheme.primary),
                title: Text(l.surahInfoAsbab, style: theme.textTheme.titleMedium?.copyWith(color: scheme.primary)),
                childrenPadding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (info.asbab.isNotEmpty)
                    for (final p in info.asbab.split('\n')) para(p)
                  else if (info.wahidi.isNotEmpty) ...[
                    Text(l.surahInfoWahidi, style: theme.textTheme.bodySmall),
                    const SizedBox(height: DesignTokens.spaceXs),
                    for (final (ayah, text) in info.wahidi) ...[
                      Text(
                        l.quranAyahN(context.num(ayah)),
                        style: theme.textTheme.labelLarge?.copyWith(color: scheme.secondary),
                      ),
                      for (final p in text.split('\n')) para(p),
                    ],
                  ] else
                    Text(l.surahInfoNoAsbab),
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}
