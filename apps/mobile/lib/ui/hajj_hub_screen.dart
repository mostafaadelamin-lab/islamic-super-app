import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../domain/haram_crowd.dart';
import '../domain/stories.dart';
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'audio_widgets.dart';
import 'hajj_screen.dart';
import 'hisn_screen.dart';
import 'l10n_ext.dart';
import 'library_screen.dart' show PlayTile;
import 'pilgrimage_screen.dart';
import 'r_icon.dart';
import 'radio_screen.dart' show haramainRadios;
import 'stories_screen.dart' show NarrationBar;
import 'widgets.dart';

/// The Hajj & Umrah section (owner, 2026-11-14: its own entry): crowd levels from the official
/// source (a link, never numbers of our own), live sound from the Two Holy Mosques, and the guide.
class HajjHubScreen extends StatelessWidget {
  const HajjHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = context.isArabic;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    Widget tile(String id, RIconData icon, String title, Widget Function() screen) => ListTile(
      key: Key('hajjHub.$id'),
      leading: RIconBadge(icon),
      title: Text(title),
      trailing: const RIcon(RIcons.chevronForward),
      onTap: () => push(screen()),
    );
    Future<void> open(Uri u) => launchUrl(u, mode: LaunchMode.externalApplication);
    return Scaffold(
      appBar: AppBar(title: Text(l.hajjTitle)),
      bottomNavigationBar: const Column(mainAxisSize: MainAxisSize.min, children: [NarrationBar(), MiniPlayer()]),
      body: ReadableWidth(
        child: ListView(
          key: const Key('hajjHubList'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            SectionCard(
              children: [
                // One screen per kind, step by step (owner 2026-11-15).
                for (final k in PilgrimageKind.values)
                  ListTile(
                    key: Key('hajjHub.${k.name}'),
                    leading: RIconBadge(k == PilgrimageKind.umrah ? RIcons.kaaba : RIcons.flag),
                    title: Text(pilgrimageTitle(context, k)),
                    subtitle: Text(k == PilgrimageKind.umrah ? l.hajjHubUmrahSub : l.hajjKindSub),
                    trailing: const RIcon(RIcons.chevronForward),
                    onTap: () => push(PilgrimageScreen(kind: k)),
                  ),
                // Types, the stages by day, pillars and Madinah, in full (dropped by mistake 2026-11-15).
                tile('hajj', RIcons.flag, l.hajjHubHajj, () => const HajjScreen(sections: ['hajj'])),
                tile('ihram', RIcons.info, l.hajjHubIhram, () => const HajjScreen(sections: ['ihram'])),
                tile('duas', RIcons.dua, l.hajjHubDuas, () => HisnScreen(section: 'hajj', title: l.hajjHubDuas)),
              ],
            ),
            if (HaramCrowdLinks.visible)
              SectionCard(
                title: l.hajjCrowdTitle,
                children: [
                  Text(l.hajjCrowdBody, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: DesignTokens.spaceMd),
                  FilledButton.icon(
                    key: const Key('hajjHub.crowdOfficial'),
                    onPressed: () => open(HaramCrowdLinks.official),
                    icon: const RIcon(RIcons.external),
                    label: Text(l.hajjCrowdOfficial),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  OutlinedButton.icon(
                    key: const Key('hajjHub.crowdNusuk'),
                    onPressed: () => open(HaramCrowdLinks.nusuk),
                    icon: const RIcon(RIcons.external),
                    label: Text(l.hajjCrowdNusuk),
                  ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Text(l.hajjCrowdNote, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ],
              ),
            SectionCard(
              title: l.hajjLiveTitle,
              children: [
                for (final r in haramainRadios)
                  PlayTile(
                    key: Key('hajjHub.${r.id}'),
                    series: 'radio',
                    remember: false,
                    title: ar ? r.nameAr : r.nameEn,
                    subtitle: l.libraryLive,
                    leading: CircleAvatar(
                      backgroundColor: scheme.primaryContainer,
                      child: RIcon(RIcons.radio, color: scheme.primary),
                    ),
                    episode: Episode(
                      id: r.id,
                      titleAr: r.nameAr,
                      titleEn: r.nameEn,
                      url: r.url,
                      status: ReviewStatus.approved,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
