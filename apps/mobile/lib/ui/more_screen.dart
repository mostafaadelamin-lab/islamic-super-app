import 'package:flutter/material.dart';

import 'about_screen.dart';
import 'bookmarks_screen.dart';
import 'hajj_screen.dart';
import 'hisn_screen.dart';
import 'l10n_ext.dart';
import 'qibla_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'tasbih_screen.dart';
import 'widgets.dart';

/// "More" tab: the remaining sections and the settings.
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    Widget tile(String id, IconData icon, String title, Widget Function() screen) => ListTile(
      key: Key('more.$id'),
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen())),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.moreTitle)),
      body: ListView(
        key: const Key('moreList'),
        children: [
          SectionCard(
            children: [
              tile('bookmarks', Icons.bookmarks_outlined, l.navBookmarks, () => const BookmarksScreen()),
              tile('search', Icons.search, l.quranSearch, () => const SearchScreen()),
            ],
          ),
          SectionCard(
            children: [
              tile('hisn', Icons.menu_book_outlined, l.adhkarHisn, () => const HisnScreen()),
              tile('tasbih', Icons.touch_app_outlined, l.tasbihTitle, () => const TasbihScreen()),
              tile('qibla', Icons.explore_outlined, l.qiblaTitle, () => const QiblaScreen()),
              tile('hajj', Icons.mosque_outlined, l.hajjTitle, () => const HajjScreen()),
            ],
          ),
          SectionCard(
            children: [
              tile('settings', Icons.settings_outlined, l.navSettings, () => const SettingsScreen()),
              tile('about', Icons.info_outline, l.settingsAbout, () => const AboutScreen()),
            ],
          ),
        ],
      ),
    );
  }
}
