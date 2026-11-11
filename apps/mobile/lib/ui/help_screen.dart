import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_services.dart';
import '../domain/app_links.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'widgets.dart';
import 'adaptive.dart';
import 'contact_screen.dart';
import 'r_icon.dart';

/// The text shared by "Share Rattil": a short line and the website or store link when set.
String shareAppText(AppLocalizations l, AppLinks links) =>
    [l.helpShareText, ?(links.website ?? links.playStore)].join('\n');

/// Help & contact: FAQ, contact address, share and rate the app.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final links = s.content.links;
    final faq = [
      (l.helpQ1, l.helpA1),
      (l.helpQ2, l.helpA2),
      (l.helpQ3, l.helpA3),
      (l.helpQ4, l.helpA4),
      (l.helpQ5, l.helpA5),
      (l.helpQ6, l.helpA6),
      (l.helpQ7, l.helpA7),
    ];
    final store = links.playStore ?? links.appStore;
    return Scaffold(
      appBar: AppBar(title: Text(l.helpTitle)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('helpList'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            SectionCard(
              children: [
                ListTile(title: Text(l.helpFaq, style: Theme.of(context).textTheme.titleMedium)),
                for (var i = 0; i < faq.length; i++)
                  ExpansionTile(
                    key: Key('faq-${i + 1}'),
                    title: Text(faq[i].$1),
                    childrenPadding: const EdgeInsets.fromLTRB(
                      DesignTokens.spaceLg,
                      0,
                      DesignTokens.spaceLg,
                      DesignTokens.spaceMd,
                    ),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(faq[i].$2)],
                  ),
              ],
            ),
            SectionCard(
              children: [
                ListTile(title: Text(l.helpContact, style: Theme.of(context).textTheme.titleMedium)),
                ListTile(
                  key: const Key('helpContactForm'),
                  leading: const RIcon(RIcons.mail),
                  title: Text(l.contactSend),
                  trailing: const RIcon(RIcons.chevronForward),
                  onTap: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ContactScreen())),
                ),
              ],
            ),
            SectionCard(
              children: [
                ListTile(
                  title: Text(l.helpSpread, style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text(l.helpSpreadBody),
                ),
                ListTile(
                  key: const Key('helpShareApp'),
                  leading: const RIcon(RIcons.share),
                  title: Text(l.helpShareApp),
                  onTap: () => s.sharer.shareText(shareAppText(l, links)),
                ),
                if (store != null)
                  ListTile(
                    key: const Key('helpRate'),
                    leading: const RIcon(RIcons.star),
                    title: Text(l.helpRate),
                    onTap: () => launchUrl(Uri.parse(store), mode: LaunchMode.externalApplication),
                  )
                else
                  ListTile(key: const Key('helpRatePending'), subtitle: Text(l.helpRatePending)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One-time suggestion to share the app, shown after it has been used on a few different days.
Future<void> maybeShowSharePrompt(BuildContext context, String today) async {
  final s = context.services;
  final r = sharePromptVisit(s.settings.sharePromptDays, s.settings.sharePromptDone, today);
  await s.settings.setSharePrompt(days: r.days);
  if (!r.show || !context.mounted) return;
  final l = context.l10n;
  final share = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('sharePrompt'),
      title: Text(l.helpPromptTitle),
      content: Text(l.helpPromptBody),
      actions: [
        TextButton(
          key: const Key('sharePromptLater'),
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l.helpNotNow),
        ),
        FilledButton(
          key: const Key('sharePromptShare'),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l.helpShareApp),
        ),
      ],
    ),
  );
  await s.settings.setSharePrompt(done: true);
  if (share == true) await s.sharer.shareText(shareAppText(l, s.content.links));
}
