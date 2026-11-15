import 'package:flutter/material.dart';

import 'l10n_ext.dart';
import 'widgets.dart';
import 'adaptive.dart';
import 'rattil_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const appVersion = '1.0.0';

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
            // No "content sources" card (owner, 2026-11-15): kept in docs/CONTENT_SOURCES.md.
          ],
        ),
      ),
    );
  }
}
