import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/prayer_schedule.dart';
import 'l10n_ext.dart';
import 'page_reader_screen.dart';
import 'prayer_model.dart';
import 'search_screen.dart';
import 'widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onSelectTab});
  final ValueChanged<int> onSelectTab;

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
          final next = pv.next;
          return ListView(
            children: [
              SectionCard(title: l.homeWelcome, children: [Text(l.tagline)]),
              SectionCard(children: const [ContinueReadingTile()]),
              SectionCard(
                title: l.homeNextPrayer,
                children: [
                  ListTile(
                    key: const Key('home.nextPrayer'),
                    leading: const Icon(Icons.schedule),
                    title: Text(next == null ? l.prayerNoPrayerToday : l.prayerNext(context.prayerName(next.key))),
                    subtitle: Text(
                      next == null
                          ? pv.city.name(context.isArabic)
                          : '${pv.city.name(context.isArabic)} · ${context.numLtr(_hhmm(pv, next))} · ${l.prayerIn(context.numLtr(PrayerSchedule.formatCountdown(next.remaining)))}',
                    ),
                    onTap: () => onSelectTab(2),
                  ),
                ],
              ),
              SectionCard(
                title: l.homeQuickLinks,
                children: [
                  ListTile(leading: const Icon(Icons.list), title: Text(l.quranSurahs), onTap: () => onSelectTab(1)),
                  ListTile(
                    leading: const Icon(Icons.chrome_reader_mode),
                    title: Text(l.quranPages),
                    onTap: () {
                      final r = s.settings.lastRead;
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PageReaderScreen(initialPage: r == null ? 1 : s.content.quran.pageOf(r)),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(l.quranSearch),
                    onTap: () =>
                        Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bookmarks),
                    title: Text(l.navBookmarks),
                    onTap: () => onSelectTab(3),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _hhmm(PrayerView pv, NextPrayer n) {
    final d = (pv.today!.day.utc[n.key] == n.at) ? pv.today! : pv.tomorrow!;
    return d.hhmm(n.key);
  }
}
