import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/location.dart';
import '../data/shortcuts.dart';
import '../domain/tasbih.dart';

import 'adaptive.dart';
import 'adhkar_screen.dart';
import 'audio_widgets.dart';
import 'help_screen.dart';
import 'stories_screen.dart' show NarrationBar;
import 'home_screen.dart';
import 'locate.dart';
import 'l10n_ext.dart';
import 'more_screen.dart';
import 'parent_gate.dart';
import 'prayer_screen.dart';
import 'reels_screen.dart';
import 'surah_list_screen.dart';
import 'tasbih_screen.dart';
import 'r_icon.dart';

/// Bottom navigation (a side rail on tablets): Home, Quran, Prayer, Adhkar, Videos, More.
/// The recitation mini player sits above the bar while audio is active.
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
      if (!mounted) return;
      maybeShowSharePrompt(context, isoDay(context.services.clock()));
      // Prayer times and the place name follow the phone's position (the
      // "automatic location" setting, on by default) unless a city was picked.
      final s = context.services;
      if (s.settings.autoLocation && (s.settings.cityNeverChosen || s.settings.cityId == 'gps')) {
        unawaited(locateAndSave(s, keepMethod: true).catchError((Object _) => const LocationUnavailable()));
      } else {
        // A place name that failed earlier (no network) or was saved by older rules.
        unawaited(refreshPlaceName(s).catchError((Object _) {}));
      }
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
      case 'reels':
        select(4);
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
      // Parent lock: children use the app (Google Play Families policy, owner 2026-11-20).
      4 => const ParentGate(child: ReelsScreen()),
      _ => const MoreScreen(),
    };
    final items = [
      (RIcons.home, RIcons.home, l.navHome),
      (RIcons.quran, RIcons.quran, l.navQuran),
      (RIcons.prayer, RIcons.prayer, l.navPrayer),
      (RIcons.dua, RIcons.dua, l.navAdhkar),
      (RIcons.reels, RIcons.reels, l.navVideos),
      (RIcons.more, RIcons.more, l.navMore),
    ];
    if (Adaptive.isWide(context)) {
      // Tablets and landscape: a side rail, the tab centred at a comfortable width,
      // and the mini player under the content.
      final extended = Adaptive.isExpanded(context);
      return Scaffold(
        body: SafeArea(
          child: Row(
            children: [
              NavigationRail(
                key: const Key('navRail'),
                selectedIndex: _index,
                onDestinationSelected: select,
                extended: extended,
                labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                destinations: [
                  for (final (icon, selected, label) in items)
                    NavigationRailDestination(icon: RIcon(icon), selectedIcon: RIcon(selected), label: Text(label)),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ReadableWidth(maxWidth: Adaptive.tabWidth, child: body),
                    ),
                    const NarrationBar(),
                    const MiniPlayer(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Scaffold(
      body: body,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Owner (2026-11-11): a story keeps playing after leaving its page, so its player
          // (play/pause/stop) stays on the main screens too.
          const NarrationBar(),
          const MiniPlayer(),
          NavigationBar(
            key: const Key('navBar'),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: _index,
            onDestinationSelected: select,
            destinations: [
              for (final (icon, selected, label) in items)
                NavigationDestination(icon: RIcon(icon), selectedIcon: RIcon(selected), label: label),
            ],
          ),
        ],
      ),
    );
  }
}
