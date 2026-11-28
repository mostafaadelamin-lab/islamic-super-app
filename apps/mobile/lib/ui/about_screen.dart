import 'package:flutter/material.dart';

import 'r_icon.dart';
import '../theme/rattil_icons.dart';

import 'l10n_ext.dart';
import 'widgets.dart';
import 'adaptive.dart';
import 'in_app_doc_screen.dart';
import 'rattil_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// The store version; test/unit/app_version_test.dart keeps it equal to pubspec.yaml.
  static const appVersion = '1.2.28';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAbout)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('aboutList'),
          children: [
            SectionCard(
              title: l.appName,
              children: [
                const Align(alignment: AlignmentDirectional.centerStart, child: RattilLogo(size: 64)),
                const SizedBox(height: 12),
                Text(l.settingsFree, key: const Key('freeStatement'), style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(l.aboutOpenSource),
                const SizedBox(height: 8),
                Text(l.aboutVersion(context.num(appVersion))),
              ],
            ),
            // Owner 2026-11-26/27: the sources and proof page, opened inside the app (bundled, works offline).
            SectionCard(
              title: l.aboutProofTitle,
              children: [
                ListTile(
                  key: const Key('aboutProof'),
                  contentPadding: EdgeInsets.zero,
                  leading: const RIcon(RIcons.shield),
                  title: Text(l.aboutProofOpen),
                  subtitle: Text(l.aboutProofBody),
                  trailing: const RIcon(RIcons.chevronForward),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => InAppDocScreen(title: l.aboutProofTitle, asset: InAppDocScreen.sourcesAsset, anchor: 'proof'),
                    ),
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
