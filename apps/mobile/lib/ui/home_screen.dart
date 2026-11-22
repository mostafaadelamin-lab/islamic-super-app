import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/recitation.dart';
import '../domain/audio_queue.dart';
import '../domain/gregorian_names.dart';
import '../domain/hijri.dart';
import '../domain/prayer_schedule.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'play_origin.dart';
import 'hajj_hub_screen.dart';
import 'kids_screen.dart';
import 'library_screen.dart';
import 'nasheeds_screen.dart';
import 'prayer_calendar_screen.dart';
import 'prayer_model.dart';
import 'qibla_screen.dart';
import 'radio_screen.dart';
import 'stories_screen.dart';
import 'locate.dart';
import 'tasbih_screen.dart';
import 'widgets.dart';
import 'r_icon.dart';
import 'rattil_logo.dart';

/// Hero colours of the chosen colour style (deep brand colour with white text and light gold
/// accents), kept for the banners that use them; contrast checked in theme_contrast_test.dart.
class HeroColors {
  HeroColors._();
  static Color get top => AppTheme.brand('heroTop');
  static Color get bottom => AppTheme.brand('heroBottom');
  static const text = Color(0xFFFFFFFF);
  static Color get accent => AppTheme.brand('heroAccent');
}

/// The five obligatory prayers shown as cards on the home screen.
const homePrayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

/// Home screen after the owner's mockup (2026-11-09): place (no settings icon since 2026-11-15), mosque
/// art with the next prayer, its time and a live countdown; the day card
/// (weekday, Gregorian + Hijri dates, prayer calendar, the five prayers,
/// sunrise and sunset); big tiles; Quran radio; "main sections".
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

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: s.settings,
          builder: (context, _) {
            final pv = PrayerView.compute(s);
            return ListView(
              key: const Key('homeList'),
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spaceLg,
                DesignTokens.spaceSm,
                DesignTokens.spaceLg,
                DesignTokens.spaceXl,
              ),
              children: [
                // Logo in the chosen colour style and the app name (as in the style designs, owner 2026-11-15).
                Padding(
                  key: const Key('home.brand'),
                  padding: const EdgeInsets.only(bottom: DesignTokens.spaceMd),
                  child: Row(
                    children: [
                      const RattilLogo(size: 44),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.homeWelcome, style: Theme.of(context).textTheme.bodySmall),
                            Text(
                              l.appName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _Hero(pv: pv, onTap: () => widget.onSelectTab(2)),
                const SizedBox(height: DesignTokens.spaceMd),
                _DayCard(
                  pv: pv,
                  onCalendar: () =>
                      Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PrayerCalendarScreen())),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: _BigTile('quran', RIcons.quran, l.homeBigQuran, () => widget.onSelectTab(1))),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(child: _BigTile('adhkar', RIcons.dua, l.homeBigAdhkar, () => widget.onSelectTab(3))),
                      const SizedBox(width: DesignTokens.spaceSm),
                      Expanded(child: _BigTile('prayer', RIcons.clock, l.homeBigPrayer, () => widget.onSelectTab(2))),
                      const SizedBox(width: DesignTokens.spaceSm),
                      // Hajj & Umrah next to the prayer times (owner, 2026-11-17).
                      Expanded(
                        child: _BigTile('hajj', RIcons.kaaba, l.homeBigHajj, () => _push(const HajjHubScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                _WideRow(
                  a: _WideTile('tasbih', RIcons.beads, l.homeBigTasbih, () => _push(const TasbihScreen())),
                  b: _WideTile('qibla', RIcons.compass, l.homeBigQibla, () => _push(const QiblaScreen())),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                // Kids section in place of the short videos, which the Videos tab already opens (owner, 2026-11-20).
                _WideRow(
                  a: _WideTile('kids', RIcons.kids, l.kidsTitle, () => _push(const KidsScreen())),
                  b: _WideTile('stories', RIcons.headphones, l.homeBigStories, () => _push(const StoriesScreen())),
                ),
                const SizedBox(height: DesignTokens.spaceSm),
                // Recitations library under the videos, nasheeds under the stories (owner, 2026-11-17).
                _WideRow(
                  a: _WideTile('library', RIcons.reciter, l.homeBigLibrary, () => _push(const LibraryScreen())),
                  b: _WideTile('nasheeds', RIcons.playlist, l.homeBigNasheeds, () => _push(const NasheedsScreen())),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                const QuranRadioCard(),
                const SizedBox(height: DesignTokens.spaceMd),
                _Panel(
                  child: InkWell(
                    key: const Key('home.mainSections'),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    onTap: () => widget.onSelectTab(5),
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spaceLg),
                      child: Row(
                        children: [
                          RIcon(RIcons.more, color: Theme.of(context).colorScheme.primary),
                          Expanded(
                            child: Text(
                              l.homeMainSections,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          RIcon(RIcons.chevronForward, color: Theme.of(context).colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// White rounded card with a hairline border, like the mockup's panels.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.padding = EdgeInsets.zero});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      elevation: 1,
      shadowColor: Colors.black26,
      child: Padding(padding: padding, child: child),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.pv, required this.onTap});
  final PrayerView pv;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final theme = Theme.of(context).textTheme;
    final primary = Theme.of(context).colorScheme.primary;
    final now = s.clock().toUtc();
    // Shortly after an adhan the hero shows that prayer with the time elapsed
    // since it; otherwise the next prayer with the time left.
    final recent = pv.today == null ? null : PrayerSchedule.recent(now, pv.today!);
    // Between the adhan and the iqama (owner 2026-11-22): that prayer, counting down to its iqama.
    final wait = pv.today == null ? null : PrayerSchedule.iqamaWait(now, pv.today!, s.settings.iqamaPlan);
    final next = wait == null ? recent ?? pv.next : NextPrayer(wait.key, pv.today!.day.utc[wait.key]!, Duration.zero);
    final remaining = recent?.remaining ?? next?.at.difference(now);
    final city = placeLabel(s, pv.city, arabic: context.isArabic);
    final nextTime = next == null ? null : PrayerSchedule.localDate(pv.location, next.at.toUtc());
    final nextDay = next == null || nextTime == pv.date ? pv.today : pv.tomorrow;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RIcon(RIcons.location, color: primary),
            const SizedBox(width: DesignTokens.spaceXs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.homeTimingFor, style: theme.bodySmall),
                  Text(
                    city,
                    key: const Key('home.city'),
                    style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        InkWell(
          key: const Key('home.nextPrayer'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (next == null)
                      Text(l.prayerNoPrayerToday, style: theme.titleMedium)
                    else ...[
                      Text(
                        l.homePrayerOf(context.prayerName(next.key)),
                        key: const Key('home.nextName'),
                        style: theme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerStart,
                        child: Builder(
                          builder: (context) {
                            // 12 h (the default since 2026-11-20): the AM/PM mark small beside the big time,
                            // on its reading side (left of the time in Arabic, right of it in English).
                            final full = context.num(
                              nextDay?.clock(next.key, h12: s.settings.clock12, arabic: context.isArabic) ?? '',
                            );
                            final cut = full.indexOf(' ');
                            final time = cut < 0 ? full : full.substring(0, cut);
                            final mark = cut < 0 ? null : full.substring(cut + 1);
                            final small = TextSpan(text: mark, style: const TextStyle(fontSize: 28));
                            return Text.rich(
                              TextSpan(
                                children: [
                                  if (mark != null && context.isArabic) ...[small, const TextSpan(text: ' ')],
                                  TextSpan(text: time),
                                  if (mark != null && !context.isArabic) ...[const TextSpan(text: ' '), small],
                                ],
                              ),
                              key: const Key('home.nextTime'),
                              semanticsLabel: full,
                              textDirection: TextDirection.ltr,
                              style: theme.displayLarge?.copyWith(
                                color: primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 72,
                                height: 1.1,
                              ),
                            );
                          },
                        ),
                      ),
                      Text(
                        wait != null
                            ? l.iqamaLeft(context.numLtr(PrayerSchedule.formatCountdown(wait.remaining)))
                            : recent != null
                            ? l.homeElapsed(context.numLtr(PrayerSchedule.formatCountdown(remaining!)))
                            : l.homeLeft(context.numLtr(PrayerSchedule.formatCountdown(remaining!))),
                        key: const Key('home.countdown'),
                        style: theme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(
                width: 130,
                height: 106,
                child: CustomPaint(painter: MosquePainter(primary.withValues(alpha: 0.85))),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.pv, required this.onCalendar});
  final PrayerView pv;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = context.isArabic;
    final theme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final s = context.services;
    final next = pv.next;
    // After Isha the next prayer is tomorrow's Fajr: show tomorrow's day.
    final tomorrow = next != null && pv.today != null && next.at.toUtc() != pv.today!.day.utc[next.key]?.toUtc();
    final day = tomorrow ? pv.tomorrow : pv.today;
    final date = tomorrow ? pv.date.add(const Duration(days: 1)) : pv.date;
    final h = hijriFor(date, arabic: ar);
    final greg = '${context.num(date.day)} ${gregorianMonthName(date.month, arabic: ar)} ${context.num(date.year)}';
    final h12 = s.settings.clock12;
    String hhmm(String k) => context.num(day!.clock(k, h12: h12, arabic: ar));
    String sunset() {
      final adj = s.settings.adjustments['maghrib'] ?? 0;
      final t = day!.local('maghrib').subtract(Duration(minutes: adj));
      return context.num(formatClock(t, h12: h12, arabic: ar));
    }

    return _Panel(
      padding: const EdgeInsets.all(DesignTokens.spaceMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: DesignTokens.spaceSm,
            runSpacing: DesignTokens.spaceSm,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: DesignTokens.spaceSm,
                children: [
                  Text(
                    weekdayName(date, arabic: ar),
                    key: const Key('home.weekday'),
                    style: theme.titleLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w700),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greg, key: const Key('home.gregorian'), style: theme.labelLarge),
                      Text(
                        l.homeHijriDate(context.num(h.day), h.monthName, context.num(h.year)),
                        key: const Key('home.hijri'),
                        style: theme.labelLarge?.copyWith(color: scheme.primary),
                      ),
                    ],
                  ),
                ],
              ),
              OutlinedButton.icon(
                key: const Key('home.calendar'),
                onPressed: onCalendar,
                icon: const RIcon(RIcons.calendar, size: 20),
                label: Text(l.homeCalendar),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
              ),
            ],
          ),
          if (tomorrow)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceXs),
              child: Text(l.homeTomorrowTimes, key: const Key('home.tomorrow'), style: theme.bodySmall),
            ),
          if (day == null)
            Padding(
              padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
              child: Text(l.prayerNoPrayerToday),
            )
          else ...[
            const SizedBox(height: DesignTokens.spaceMd),
            Row(
              children: [
                for (final (i, k) in homePrayers.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _PrayerCell(
                      k: k,
                      time: hhmm(k),
                      isNext: next != null && next.key == k && next.at.toUtc() == day.day.utc[k]?.toUtc(),
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: DesignTokens.spaceXl),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: DesignTokens.spaceLg,
              runSpacing: DesignTokens.spaceXs,
              children: [
                _SunItem(
                  key: const Key('home.time-sunrise'),
                  icon: RIcons.sunset,
                  label: l.homeSunrise,
                  time: hhmm('sunrise'),
                ),
                _SunItem(key: const Key('home.sunset'), icon: RIcons.sunHigh, label: l.homeSunset, time: sunset()),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PrayerCell extends StatelessWidget {
  const _PrayerCell({required this.k, required this.time, required this.isNext});
  final String k;
  final String time;
  final bool isNext;

  static const _icons = {
    'fajr': RIcons.moon,
    'dhuhr': RIcons.sunHigh,
    'asr': RIcons.sunLow,
    'maghrib': RIcons.sunset,
    'isha': RIcons.moon,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return Container(
      key: Key('home.time-$k'),
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
      decoration: BoxDecoration(
        color: isNext ? scheme.secondaryContainer : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(color: isNext ? scheme.secondary : scheme.outlineVariant),
      ),
      child: Column(
        children: [
          RIcon(_icons[k]!, size: 22, color: scheme.primary),
          const SizedBox(height: 2),
          FittedBox(child: Text(context.prayerName(k), style: theme.labelMedium)),
          FittedBox(
            child: Text(
              time,
              textDirection: TextDirection.ltr,
              style: theme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _SunItem extends StatelessWidget {
  const _SunItem({super.key, required this.icon, required this.label, required this.time});
  final RIconData icon;
  final String label;
  final String time;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      RIcon(icon, size: 18, color: Theme.of(context).colorScheme.secondary),
      const SizedBox(width: 6),
      Text('$label  '),
      Text(
        time,
        textDirection: TextDirection.ltr,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ],
  );
}

class _BigTile extends StatelessWidget {
  const _BigTile(this.id, this.icon, this.label, this.onTap);
  final String id;
  final RIconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _Panel(
    child: InkWell(
      key: Key('home.tile-$id'),
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 112),
        child: Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceSm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RIcon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _WideTile {
  const _WideTile(this.id, this.icon, this.label, this.onTap);
  final String id;
  final RIconData icon;
  final String label;
  final VoidCallback onTap;
}

class _WideRow extends StatelessWidget {
  const _WideRow({required this.a, this.b});
  final _WideTile a;

  /// Second tile; without it [a] takes the whole row.
  final _WideTile? b;

  Widget _tile(BuildContext context, _WideTile t) => _Panel(
    child: InkWell(
      key: Key('home.tile-${t.id}'),
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      onTap: t.onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 68),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd),
          child: Row(
            children: [
              RIcon(t.icon, size: 30, color: Theme.of(context).colorScheme.secondary),
              Expanded(
                child: Text(
                  t.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: _tile(context, a)),
      if (b case final b?) ...[const SizedBox(width: DesignTokens.spaceSm), Expanded(child: _tile(context, b))],
    ],
  );
}

/// Quran radio: the whole Mushaf recited continuously by the chosen reciter
/// (streamed per ayah), from a random surah, with a play duration that stops it
/// through the app's sleep timer.
class QuranRadioCard extends StatefulWidget {
  const QuranRadioCard({super.key, this.random});

  /// Injected in tests to fix the first surah.
  final Random? random;

  /// Play-duration steps, in minutes: 0 = unlimited, then the sleep-timer choices.
  static const durations = [0, ...SleepTimerController.choices];

  @override
  State<QuranRadioCard> createState() => _QuranRadioCardState();
}

class _QuranRadioCardState extends State<QuranRadioCard> {
  int _chosen = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final rec = s.recitation;
    final theme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: Listenable.merge([rec, s.sleepTimer, s.settings, s.narration]),
      builder: (context, _) {
        final isRadio = rec.isActive && rec.scope == PlayScope.radio;
        final playing = isRadio && rec.isPlaying;
        final minutes = _chosen;
        final step = QuranRadioCard.durations.indexOf(minutes);
        final cur = isRadio ? rec.current : null;
        // Live station chosen for the card (Cairo Quran radio unless the user picked another).
        final station = s.settings.radioStation;
        final live = station == 'mushaf' ? null : homeStation(s.settings, context.isArabic);
        final n = s.narration;
        final liveOn = live != null && n.episode?.id == live.id;
        final livePlaying = liveOn && n.isPlaying;

        void setDuration(int delta) {
          final i = ((step < 0 ? 0 : step) + delta).clamp(0, QuranRadioCard.durations.length - 1);
          final m = QuranRadioCard.durations[i];
          setState(() => _chosen = m);
          if (isRadio || livePlaying) s.sleepTimer.set(m == 0 ? null : m);
        }

        Future<void> onPlay() async {
          if (live != null) {
            if (livePlaying) {
              await n.pause();
            } else if (liveOn && n.state == RecitationState.paused) {
              await n.resume();
            } else {
              s.sleepTimer.set(_chosen == 0 ? null : _chosen);
              PlayOrigin.remember(context, 'radio');
              await n.playEpisode('radio', live, remember: false);
            }
            return;
          }
          if (isRadio) {
            if (playing) {
              await rec.pause();
            } else {
              await rec.resume();
            }
            return;
          }
          final from = (widget.random ?? Random()).nextInt(s.content.quran.surahs.length) + 1;
          s.sleepTimer.set(_chosen == 0 ? null : _chosen);
          await rec.playRadio(from);
        }

        final reciter = s.content.reciters.byFolder(s.settings.reciter);
        return _Panel(
          padding: const EdgeInsets.all(DesignTokens.spaceMd),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.radioTitle, style: theme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        // The player sits in the same row as the station (owner, 2026-11-17): play, or while the
                        // live radio plays, pause, the sleep timer and ✕ to close it.
                        Row(
                          children: [
                            Expanded(
                              child: _Box(
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    key: const Key('radio.station'),
                                    value: station,
                                    isExpanded: true,
                                    icon: const RIcon(RIcons.chevronDown),
                                    items: [
                                      for (final r in featuredRadios)
                                        DropdownMenuItem(
                                          value: r.id,
                                          child: Text(
                                            context.isArabic ? r.nameAr : r.nameEn,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      if (!featuredRadios.any((r) => r.id == station) && station != 'mushaf')
                                        DropdownMenuItem(
                                          value: station,
                                          child: Text(
                                            s.settings.radioStationName ?? station,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      DropdownMenuItem(
                                        value: 'mushaf',
                                        child: Text(
                                          l.radioMushaf,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                    onChanged: (v) async {
                                      if (v == null || v == station) return;
                                      if (livePlaying) await n.stop();
                                      if (isRadio) await rec.stop();
                                      await s.settings.setRadioStation(v);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: DesignTokens.spaceXs),
                            if (liveOn && n.isActive) ...[
                              const InlinePlayerMarker(),
                              IconButton(
                                key: const Key('inlineStop'),
                                tooltip: l.storiesStop,
                                icon: const RIcon(RIcons.close),
                                onPressed: n.stop,
                              ),
                              const SleepTimerButton(),
                            ],
                            IconButton.filled(
                              key: const Key('radio.play'),
                              tooltip: (playing || livePlaying) ? l.radioPause : l.radioListen,
                              onPressed: onPlay,
                              iconSize: 28,
                              icon: RIcon((playing || livePlaying) ? RIcons.pause : RIcons.play),
                            ),
                          ],
                        ),
                        if (station == 'mushaf') ...[
                          const SizedBox(height: 6),
                          _Box(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                key: const Key('radio.reciter'),
                                value: reciter.folder,
                                isExpanded: true,
                                icon: const RIcon(RIcons.chevronDown),
                                items: [
                                  for (final r in s.content.reciters.reciters)
                                    DropdownMenuItem(
                                      value: r.folder,
                                      child: Text(
                                        r.name(context.isArabic),
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) s.settings.setReciter(v);
                                },
                              ),
                            ),
                          ),
                        ],
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            key: const Key('radio.all'),
                            onPressed: () => Navigator.of(
                              context,
                            ).push(MaterialPageRoute<void>(builder: (_) => const RadioScreen())),
                            child: Text(l.radioAll),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Row(
                children: [
                  Text(l.radioDuration, style: theme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(width: DesignTokens.spaceSm),
                  Expanded(
                    child: _Box(
                      child: Row(
                        children: [
                          IconButton(
                            key: const Key('radio.longer'),
                            tooltip: l.radioLonger,
                            color: scheme.primary,
                            onPressed: step == QuranRadioCard.durations.length - 1 ? null : () => setDuration(1),
                            icon: const RIcon(RIcons.plus),
                          ),
                          Expanded(
                            child: Text(
                              minutes == 0 ? l.radioUnlimited : l.radioMin(context.num(minutes)),
                              key: const Key('radio.duration'),
                              textAlign: TextAlign.center,
                              style: theme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          IconButton(
                            key: const Key('radio.shorter'),
                            tooltip: l.radioShorter,
                            color: scheme.primary,
                            onPressed: step <= 0 ? null : () => setDuration(-1),
                            icon: const RIcon(RIcons.minus),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DesignTokens.spaceSm),
              Text(
                live != null
                    ? (livePlaying ? l.libraryLive : l.radioLiveNote)
                    : cur == null
                    ? l.radioNote
                    : l.radioNowPlaying(surahName(context, s.content.quran.surah(cur.ref.surah))),
                key: const Key('radio.status'),
                textAlign: TextAlign.center,
                style: theme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 52),
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: BoxDecoration(
      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
    ),
    child: child,
  );
}

/// Line drawing of a mosque (dome, two minarets with crescents), in a 160×130
/// box scaled to the canvas — the same drawing as the website's.
class MosquePainter extends CustomPainter {
  MosquePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 160, size.height / 130);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    void poly(List<double> xy) {
      final path = Path()..moveTo(xy[0], xy[1]);
      for (var i = 2; i < xy.length; i += 2) {
        path.lineTo(xy[i], xy[i + 1]);
      }
      canvas.drawPath(path, p);
    }

    void crescent(double cx, double cy, double r) {
      final outer = Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
      final inner = Path()..addOval(Rect.fromCircle(center: Offset(cx + r * 0.45, cy - r * 0.2), radius: r * 0.8));
      canvas.drawPath(Path.combine(PathOperation.difference, outer, inner), fill);
    }

    // tall minaret
    poly([22, 128, 22, 52, 30, 42, 38, 52, 38, 128]);
    poly([20, 66, 40, 66]);
    poly([20, 92, 40, 92]);
    poly([26, 66, 30, 72, 34, 66]);
    poly([26, 92, 30, 98, 34, 92]);
    poly([30, 42, 30, 30]);
    crescent(30, 22, 5.5);
    // dome on its drum
    poly([58, 128, 58, 88, 128, 88, 128, 128]);
    canvas.drawPath(
      Path()
        ..moveTo(62, 88)
        ..cubicTo(62, 70, 76, 62, 93, 54)
        ..cubicTo(110, 62, 124, 70, 124, 88),
      p,
    );
    poly([93, 54, 93, 44]);
    crescent(93, 36, 5.5);
    // door and windows
    canvas.drawPath(
      Path()
        ..moveTo(84, 128)
        ..lineTo(84, 112)
        ..arcToPoint(const Offset(102, 112), radius: const Radius.circular(9))
        ..lineTo(102, 128),
      p,
    );
    for (final x in [68.0, 110.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(x, 108)
          ..lineTo(x, 102)
          ..arcToPoint(Offset(x + 8, 102), radius: const Radius.circular(4))
          ..lineTo(x + 8, 108)
          ..close(),
        p,
      );
    }
    // small minaret
    poly([138, 128, 138, 78, 144, 70, 150, 78, 150, 128]);
    poly([136, 92, 152, 92]);
    poly([144, 70, 144, 62]);
    crescent(144, 55, 4.5);
    poly([6, 128, 156, 128]);
  }

  @override
  bool shouldRepaint(MosquePainter old) => old.color != color;
}
