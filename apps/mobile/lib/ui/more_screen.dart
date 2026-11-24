import 'package:flutter/material.dart';

import 'asma_screen.dart';
import 'radio_screen.dart';
import 'hadith_screen.dart';
import 'hajj_hub_screen.dart';
import 'khatma_screen.dart';
import 'worship_screen.dart';
import 'l10n_ext.dart';
import 'mosques_screen.dart';
import 'lessons_screen.dart';
import 'settings_screen.dart';
import 'sharawi_screen.dart';
import 'tafsir_library_screen.dart';
import 'widgets.dart';
import 'zakat_screen.dart';
import 'adaptive.dart';
import 'r_icon.dart';
import 'shell_back.dart';

/// "More" tab: the remaining sections and the settings.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget tile(String id, RIconData icon, String title, Widget Function() screen, {String? sub}) => ListTile(
      key: Key('more.$id'),
      leading: RIconBadge(icon),
      title: Text(title),
      subtitle: sub == null ? null : Text(sub),
      trailing: const RIcon(RIcons.chevronForward),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen())),
    );
    return Scaffold(
      appBar: AppBar(leading: shellBackButton(context), title: Text(l.moreTitle)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('moreList'),
          children: [
            // Owner's order (2026-11-24). Home items (tasbih, qibla, kids, library, nasheeds) are not repeated;
            // help and about now live inside the settings.
            SectionCard(
              children: [
                tile('tafsir', RIcons.quran, l.tafsirLibTitle, () => const TafsirLibraryScreen()),
                tile('hadith', RIcons.openBook, l.hadithTitle, () => const HadithScreen()),
                tile('sharawi', RIcons.book, l.sharawiSection, () => const SharawiScreen(), sub: l.moreSharawiSub),
                tile('mosques', RIcons.location, l.mosquesTitle, () => const MosquesScreen()),
                tile('zakat', RIcons.zakat, l.zakatTitle, () => const ZakatScreen()),
                tile('asma', RIcons.star, l.moreAsma, () => const AsmaScreen()),
                tile('khatma', RIcons.khatma, l.khatmaTitle, () => const KhatmaScreen()),
                tile('tracker', RIcons.calendarCheck, l.worshipTitle, () => const WorshipScreen()),
                tile('radio', RIcons.radio, l.radiosTitle, () => const RadioScreen()),
                tile('hajj', RIcons.kaaba, l.hajjTitle, () => const HajjHubScreen(), sub: l.moreHajjSub),
                tile('lessons', RIcons.headphones, l.lessonsTitle, () => const LessonsScreen(), sub: l.moreLessonsSub),
              ],
            ),
            SectionCard(children: [tile('settings', RIcons.settings, l.navSettings, () => const SettingsScreen())]),
          ],
        ),
      ),
    );
  }
}
