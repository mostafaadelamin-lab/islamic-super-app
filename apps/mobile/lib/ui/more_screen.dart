import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'asma_screen.dart';
import 'radio_screen.dart';
import 'nasheeds_screen.dart';
import 'hadith_screen.dart';
import 'hajj_hub_screen.dart';
import 'khatma_screen.dart';
import 'worship_screen.dart';
import 'help_screen.dart';
import 'l10n_ext.dart';
import 'mosques_screen.dart';
import 'qibla_screen.dart';
import 'library_screen.dart';
import 'stories_screen.dart';
import 'settings_screen.dart';
import 'sharawi_screen.dart';
import 'widgets.dart';
import 'zakat_screen.dart';
import 'adaptive.dart';
import 'r_icon.dart';

/// "More" tab: the remaining sections and the settings.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget tile(String id, RIconData icon, String title, Widget Function() screen) => ListTile(
      key: Key('more.$id'),
      leading: RIconBadge(icon),
      title: Text(title),
      trailing: const RIcon(RIcons.chevronForward),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen())),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.moreTitle)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('moreList'),
          children: [
            SectionCard(
              children: [
                tile('khatma', RIcons.khatma, l.khatmaTitle, () => const KhatmaScreen()),
                tile('tracker', RIcons.calendarCheck, l.worshipTitle, () => const WorshipScreen()),
                tile('hadith', RIcons.openBook, l.hadithTitle, () => const HadithScreen()),
                tile('asma', RIcons.star, l.asmaTitle, () => const AsmaScreen()),
                tile('radio', RIcons.radio, l.radiosTitle, () => const RadioScreen()),
                tile('nasheeds', RIcons.headphones, l.nasheedsTitle, () => const NasheedsScreen()),
                tile('library', RIcons.reciter, l.libraryTitle, () => const LibraryScreen()),
                tile('stories', RIcons.headphones, l.storiesTitle, () => const StoriesScreen()),
                tile('sharawi', RIcons.book, l.sharawiTitle, () => const SharawiScreen()),
                tile('qibla', RIcons.compass, l.qiblaTitle, () => const QiblaScreen()),
                tile('mosques', RIcons.location, l.mosquesTitle, () => const MosquesScreen()),
                tile('zakat', RIcons.zakat, l.zakatTitle, () => const ZakatScreen()),
                tile('hajj', RIcons.kaaba, l.hajjTitle, () => const HajjHubScreen()),
              ],
            ),
            SectionCard(
              children: [
                tile('settings', RIcons.settings, l.navSettings, () => const SettingsScreen()),
                tile('help', RIcons.help, l.helpTitle, () => const HelpScreen()),
                tile('about', RIcons.info, l.settingsAbout, () => const AboutScreen()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
