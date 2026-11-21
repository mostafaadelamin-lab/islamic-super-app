import 'package:flutter/material.dart';

import 'l10n_ext.dart';
import 'widgets.dart';
import 'adaptive.dart';
import 'rattil_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// The store version; test/unit/app_version_test.dart keeps it equal to pubspec.yaml.
  static const appVersion = '1.2.16';

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
            // No sources or credits in the app (owner, 2026-11-15 and 2026-11-20: given on request only);
            // they are kept in docs/CONTENT_SOURCES.md and apps/mobile/assets/audio/ADHAN_AUDIO.md.
          ],
        ),
      ),
    );
  }
}
