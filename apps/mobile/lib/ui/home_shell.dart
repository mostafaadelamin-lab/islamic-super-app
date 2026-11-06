import 'package:flutter/material.dart';

import 'bookmarks_screen.dart';
import 'home_screen.dart';
import 'l10n_ext.dart';
import 'prayer_screen.dart';
import 'settings_screen.dart';
import 'surah_list_screen.dart';

/// Bottom navigation: Home, Quran, Prayer, Bookmarks, Settings.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _index = 0;
  int get index => _index;

  void select(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final body = switch (_index) {
      0 => HomeScreen(onSelectTab: select),
      1 => const SurahListScreen(),
      2 => const PrayerScreen(),
      3 => const BookmarksScreen(),
      _ => const SettingsScreen(),
    };
    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book),
            label: l.navQuran,
          ),
          NavigationDestination(
            icon: const Icon(Icons.schedule_outlined),
            selectedIcon: const Icon(Icons.schedule),
            label: l.navPrayer,
          ),
          NavigationDestination(
            icon: const Icon(Icons.bookmarks_outlined),
            selectedIcon: const Icon(Icons.bookmarks),
            label: l.navBookmarks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }
}
