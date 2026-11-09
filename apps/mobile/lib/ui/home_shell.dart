import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/shortcuts.dart';
import '../domain/tasbih.dart';

import 'adhkar_screen.dart';
import 'audio_widgets.dart';
import 'help_screen.dart';
import 'home_screen.dart';
import 'l10n_ext.dart';
import 'more_screen.dart';
import 'prayer_screen.dart';
import 'surah_list_screen.dart';
import 'tasbih_screen.dart';

/// Bottom navigation: Home, Quran, Prayer, Adhkar, More. The recitation mini
/// player sits above the bar while audio is active.
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
  void initState() {
    super.initState();
    shortcutRequests.addListener(_onShortcut);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onShortcut();
      if (mounted) maybeShowSharePrompt(context, isoDay(context.services.clock()));
    });
  }

  @override
  void dispose() {
    shortcutRequests.removeListener(_onShortcut);
    super.dispose();
  }

  /// Opens the section of a home-screen shortcut.
  void _onShortcut() {
    final type = shortcutRequests.value;
    if (type == null || !mounted) return;
    shortcutRequests.value = null;
    switch (type) {
      case 'quran':
        select(1);
      case 'prayer':
        select(2);
      case 'adhkar':
        select(3);
      case 'tasbih':
        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const TasbihScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final body = switch (_index) {
      0 => HomeScreen(onSelectTab: select),
      1 => const SurahListScreen(),
      2 => const PrayerScreen(),
      3 => const AdhkarScreen(),
      _ => const MoreScreen(),
    };
    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          NavigationBar(
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
                icon: const Icon(Icons.wb_twilight_outlined),
                selectedIcon: const Icon(Icons.wb_twilight),
                label: l.navAdhkar,
              ),
              NavigationDestination(
                icon: const Icon(Icons.grid_view_outlined),
                selectedIcon: const Icon(Icons.grid_view),
                label: l.navMore,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
