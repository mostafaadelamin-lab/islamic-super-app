import 'package:flutter/material.dart';

import '../domain/nasheeds.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'youtube_player.dart';

bool _ar(BuildContext context) => Localizations.localeOf(context).languageCode == 'ar';

/// Nasheeds without music from the munshidin's official channels, Egypt first.
class NasheedsScreen extends StatelessWidget {
  const NasheedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final theme = Theme.of(context);
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceLg, DesignTokens.spaceXs),
      child: Text(text, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
    );
    Widget card(Munshid m) => Card(
      key: Key('munshid.${m.id}'),
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      child: ListTile(
        leading: const RIconBadge(RIcons.headphones),
        title: Text(_ar(context) ? m.nameAr : m.nameEn, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(l.nasheedsCount('${m.items.length}')),
        trailing: const RIcon(RIcons.chevronForward),
        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => MunshidScreen(munshid: m))),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.nasheedsTitle)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('nasheedsList'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
              child: Text(l.nasheedsNote, key: const Key('nasheedsNote'), style: theme.textTheme.bodyMedium),
            ),
            header(l.nasheedsEgypt),
            for (final m in munshidin)
              if (m.region == MunshidRegion.egypt) card(m),
            header(l.nasheedsArab),
            for (final m in munshidin)
              if (m.region == MunshidRegion.arab) card(m),
          ],
        ),
      ),
    );
  }
}

class MunshidScreen extends StatelessWidget {
  const MunshidScreen({super.key, required this.munshid});
  final Munshid munshid;

  @override
  Widget build(BuildContext context) {
    final name = _ar(context) ? munshid.nameAr : munshid.nameEn;
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: ReadableWidth(
        child: ListView.separated(
          key: const Key('munshidList'),
          padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
          itemCount: munshid.items.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final item = munshid.items[i];
            return ListTile(
              key: Key('nasheed-${item.videoId}'),
              leading: RIcon(RIcons.playCircle, color: Theme.of(context).colorScheme.primary, size: 30),
              title: Text(item.titleAr),
              onTap: () => showYouTubeSheet(context, videoId: item.videoId, title: item.titleAr, subtitle: name),
            );
          },
        ),
      ),
    );
  }
}
