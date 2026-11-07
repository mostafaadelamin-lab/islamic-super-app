import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/hijri.dart';
import '../domain/prayer.dart';
import '../domain/prayer_schedule.dart';
import '../theme/design_tokens.dart';
import 'bookmarks_screen.dart';
import 'hajj_screen.dart';
import 'hisn_screen.dart';
import 'l10n_ext.dart';
import 'page_reader_screen.dart';
import 'prayer_model.dart';
import 'qibla_screen.dart';
import 'search_screen.dart';
import 'tasbih_screen.dart';
import 'widgets.dart';

/// Hero colours (deep emerald with white text and gold accents) — the same in
/// light and dark mode; contrast checked in theme_contrast_test.dart.
class HeroColors {
  HeroColors._();
  static const top = Color(0xFF0F5C4A);
  static const bottom = Color(0xFF0A3F33);
  static const text = Color(0xFFFFFFFF);
  static const accent = Color(0xFFF4EBD3);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onSelectTab});
  final ValueChanged<int> onSelectTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));

  void _openMushaf() {
    final s = context.services;
    final r = s.settings.lastRead;
    _push(PageReaderScreen(initialPage: r == null ? 1 : s.content.quran.pageOf(r)));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    return Scaffold(
      appBar: AppBar(title: Text(l.appName)),
      body: ListenableBuilder(
        listenable: s.settings,
        builder: (context, _) {
          final pv = PrayerView.compute(s);
          return ListView(
            key: const Key('homeList'),
            padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  DesignTokens.spaceLg,
                  DesignTokens.spaceXs,
                  DesignTokens.spaceLg,
                  DesignTokens.spaceSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeWelcome, style: Theme.of(context).textTheme.titleLarge),
                    Text(l.tagline, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              _NextPrayerHero(pv: pv, onTap: () => widget.onSelectTab(2)),
              if (pv.today != null) _TodayTimes(pv: pv),
              SectionCard(
                children: [
                  const ContinueReadingTile(),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      key: const Key('home.openMushaf'),
                      onPressed: _openMushaf,
                      icon: const Icon(Icons.menu_book),
                      label: Text(l.homeOpenMushaf),
                    ),
                  ),
                ],
              ),
              SectionCard(
                title: l.homeSections,
                children: [
                  _TileGrid(
                    tiles: [
                      _Tile('surahs', Icons.format_list_numbered, l.quranSurahs, () => widget.onSelectTab(1)),
                      _Tile('mushaf', Icons.chrome_reader_mode, l.quranPages, _openMushaf),
                      _Tile('search', Icons.search, l.quranSearch, () => _push(const SearchScreen())),
                      _Tile('adhkar', Icons.wb_twilight, l.navAdhkar, () => widget.onSelectTab(3)),
                      _Tile('hisn', Icons.menu_book_outlined, l.adhkarHisn, () => _push(const HisnScreen())),
                      _Tile('tasbih', Icons.touch_app_outlined, l.tasbihTitle, () => _push(const TasbihScreen())),
                      _Tile('qibla', Icons.explore_outlined, l.qiblaTitle, () => _push(const QiblaScreen())),
                      _Tile('hajj', Icons.mosque_outlined, l.hajjTitle, () => _push(const HajjScreen())),
                      _Tile(
                        'bookmarks',
                        Icons.bookmarks_outlined,
                        l.navBookmarks,
                        () => _push(const BookmarksScreen()),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _NextPrayerHero extends StatelessWidget {
  const _NextPrayerHero({required this.pv, required this.onTap});
  final PrayerView pv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final next = pv.next;
    final h = hijriFor(pv.date, arabic: context.isArabic);
    final greg =
        '${pv.date.year}-${pv.date.month.toString().padLeft(2, '0')}-${pv.date.day.toString().padLeft(2, '0')}';
    // Countdown recomputed from the clock on every tick of the parent's timer.
    final remaining = next?.at.difference(s.clock().toUtc());
    const t = TextStyle(color: HeroColors.text);
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [HeroColors.top, HeroColors.bottom],
            ),
          ),
          child: InkWell(
            key: const Key('home.nextPrayer'),
            onTap: onTap,
            child: Stack(
              children: [
                PositionedDirectional(
                  end: -18,
                  bottom: -24,
                  child: Icon(Icons.mosque, size: 140, color: HeroColors.text.withValues(alpha: 0.08)),
                ),
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: HeroColors.accent, size: 18),
                          const SizedBox(width: DesignTokens.spaceXs),
                          Expanded(
                            child: Text(
                              pv.city.name(context.isArabic),
                              key: const Key('home.city'),
                              style: theme.labelLarge?.copyWith(color: HeroColors.accent),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      Text(
                        l.homeHijriDate(context.num(h.day), h.monthName, context.num(h.year)),
                        key: const Key('home.hijri'),
                        style: theme.bodyMedium?.merge(t),
                      ),
                      Text(context.numLtr(greg), key: const Key('home.gregorian'), style: theme.bodySmall?.merge(t)),
                      const SizedBox(height: DesignTokens.spaceMd),
                      if (next == null)
                        Text(l.prayerNoPrayerToday, style: theme.titleMedium?.merge(t))
                      else ...[
                        Text(
                          l.prayerNext(context.prayerName(next.key)),
                          style: theme.titleLarge?.merge(t).copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          l.prayerIn(context.numLtr(PrayerSchedule.formatCountdown(remaining!))),
                          key: const Key('home.countdown'),
                          style: theme.headlineSmall?.merge(t).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayTimes extends StatelessWidget {
  const _TodayTimes({required this.pv});
  final PrayerView pv;

  @override
  Widget build(BuildContext context) {
    final today = pv.today!;
    final next = pv.next;
    final scheme = Theme.of(context).colorScheme;
    return SectionCard(
      title: context.l10n.homeTodayTimes,
      children: [
        Wrap(
          spacing: DesignTokens.spaceSm,
          runSpacing: DesignTokens.spaceSm,
          children: [
            for (final k in prayerKeys)
              () {
                final isNext = next != null && next.key == k && next.at == today.day.utc[k];
                return Container(
                  key: Key('home.time-$k'),
                  constraints: const BoxConstraints(minWidth: 84),
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: DesignTokens.spaceSm),
                  decoration: BoxDecoration(
                    color: isNext ? scheme.secondaryContainer : scheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    border: Border.all(color: isNext ? scheme.secondary : scheme.outline),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(context.prayerName(k), style: Theme.of(context).textTheme.labelMedium),
                      Text(
                        context.num(today.hhmm(k)),
                        textDirection: TextDirection.ltr,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }(),
          ],
        ),
      ],
    );
  }
}

class _Tile {
  const _Tile(this.id, this.icon, this.label, this.onTap);
  final String id;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.tiles});
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      const gap = DesignTokens.spaceSm;
      final w = ((c.maxWidth - 2 * gap) / 3).floorToDouble();
      final scheme = Theme.of(context).colorScheme;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final t in tiles)
            SizedBox(
              key: Key('home.tile-${t.id}'),
              width: w,
              child: Material(
                color: scheme.surfaceContainer,
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  onTap: t.onTap,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 84),
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spaceSm),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(DesignTokens.spaceSm),
                            decoration: BoxDecoration(color: scheme.secondaryContainer, shape: BoxShape.circle),
                            child: Icon(t.icon, color: scheme.primary),
                          ),
                          const SizedBox(height: DesignTokens.spaceXs),
                          Text(
                            t.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}
