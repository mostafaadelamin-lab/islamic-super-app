import 'package:flutter/material.dart';

import '../app_services.dart';
import 'l10n_ext.dart';
import 'widgets.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final v = context.services.content.versions;
    return Scaffold(
      appBar: AppBar(title: Text(l.settingsAbout)),
      body: ListView(
        key: const Key('aboutList'),
        children: [
          SectionCard(
            title: l.appName,
            children: [
              Text(l.settingsFree, key: const Key('freeStatement'), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(l.aboutOpenSource),
              const SizedBox(height: 8),
              Text(l.aboutVersion(context.num(appVersion))),
              Text('Quran ${v['quran']} · Pages ${v['pages']}', textDirection: TextDirection.ltr),
            ],
          ),
          SectionCard(
            title: l.settingsSources,
            children: [
              for (final t in [
                l.aboutQuranText,
                l.aboutTranslation,
                l.aboutPages,
                l.aboutFonts,
                l.aboutPrayerAlgo,
                l.aboutTzdb,
              ])
                Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Text(t)),
            ],
          ),
        ],
      ),
    );
  }
}
