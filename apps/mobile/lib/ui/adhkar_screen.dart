import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/adhkar.dart';
import '../domain/nasheeds.dart';
import '../theme/design_tokens.dart';
import 'dhikr_audio.dart';
import 'dhikr_hadith.dart';
import 'dhikr_tools.dart';
import 'hisn_screen.dart';
import 'l10n_ext.dart';
import 'prayer_model.dart';
import 'adaptive.dart';
import 'r_icon.dart';
import 'review_notice.dart' show duaStyle;
import 'adhkar_audio.dart';

/// The Adhkar tab: a vertical list of the daily adhkar (morning, evening,
/// sleep, prayer…) and the duas, all from Hisn al-Muslim, then the whole book.
class AdhkarScreen extends StatelessWidget {
  const AdhkarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    void push(Widget w) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => w));
    Widget tile(String id, RIconData icon, String title, VoidCallback onTap) => Card(
      key: Key('adhkarHub.$id'),
      margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
      child: ListTile(
        leading: RIcon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const RIcon(RIcons.chevronForward),
        onTap: onTap,
      ),
    );
    Widget hisn(String id, RIconData icon, String title) =>
        tile(id, icon, title, () => push(HisnScreen(section: id, title: title)));
    Widget header(String text) => Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spaceLg,
        DesignTokens.spaceLg,
        DesignTokens.spaceLg,
        DesignTokens.spaceXs,
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l.navAdhkar)),
      body: ReadableWidth(
        child: ListView(
          key: const Key('adhkarHub'),
          padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
          children: [
            header(l.adhkarDaily),
            tile(
              'morning',
              RIcons.sunHigh,
              l.adhkarMorningTitle,
              () => push(const AdhkarSessionScreen(initial: AdhkarSession.morning)),
            ),
            tile(
              'evening',
              RIcons.moon,
              l.adhkarEveningTitle,
              () => push(const AdhkarSessionScreen(initial: AdhkarSession.evening)),
            ),
            hisn('sleep', RIcons.moon, l.hisnSectionSleep),
            hisn('prayer', RIcons.prayer, l.hisnSectionPrayer),
            hisn('remembrance', RIcons.beads, l.hisnSectionRemembrance),
            header(l.adhkarDuas),
            hisn('hardship', RIcons.dua, l.hisnSectionHardship),
            hisn('illness', RIcons.adhkar, l.hisnSectionIllness),
            hisn('travel', RIcons.location, l.hisnSectionTravel),
            hisn('home', RIcons.home, l.hisnSectionHome),
            hisn('food', RIcons.calendarCheck, l.hisnSectionFood),
            hisn('people', RIcons.dua, l.hisnSectionPeople),
            hisn('nature', RIcons.sunrise, l.hisnSectionNature),
            hisn('hajj', RIcons.kaaba, l.hisnSectionHajj),
            const SizedBox(height: DesignTokens.spaceSm),
            tile('hisn', RIcons.hisn, l.adhkarHisn, () => push(const HisnScreen())),
            header(l.adhkarListenHeader),
            for (final (a, icon, title) in [
              (AdhkarAudio.morning, RIcons.sunHigh, l.adhkarMorningTitle),
              (AdhkarAudio.evening, RIcons.moon, l.adhkarEveningTitle),
            ])
              Card(
                key: Key('adhkarAudio.${a.name}'),
                margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceXs),
                child: ListTile(
                  leading: RIcon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(l.adhkarAlafasy),
                  trailing: const RIcon(RIcons.playCircle),
                  onTap: () => openAdhkarAudio(context, a, title),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Morning or evening adhkar, one under the other, with a counter under every
/// item (persisted for the day).
class AdhkarSessionScreen extends StatefulWidget {
  const AdhkarSessionScreen({super.key, this.initial});
  final AdhkarSession? initial;

  @override
  State<AdhkarSessionScreen> createState() => AdhkarScreenState();
}

class AdhkarScreenState extends State<AdhkarSessionScreen> {
  AdhkarSession? _session;

  /// The dhikr shown in the one-per-page view.
  int _at = 0;
  AdhkarSession get session => _session!;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session ??= widget.initial ?? _defaultSession();
  }

  /// Morning from Fajr until Asr, evening otherwise.
  AdhkarSession _defaultSession() {
    final s = context.services;
    final pv = PrayerView.compute(s);
    final today = pv.today;
    if (today == null) return AdhkarSession.morning;
    final now = s.clock().toUtc();
    final fajr = today.day.utc['fajr']!;
    final asr = today.day.utc['asr']!;
    return !now.isBefore(fajr) && now.isBefore(asr) ? AdhkarSession.morning : AdhkarSession.evening;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    return StopDhikrAudioOnExit(
      child: Scaffold(
        bottomNavigationBar: const DhikrPlayerBar(),
        appBar: AppBar(
          title: Text(session == AdhkarSession.morning ? l.adhkarMorningTitle : l.adhkarEveningTitle),
          actions: [
            const AdhkarViewToggle(),
            IconButton(
              key: const Key('adhkarReminders'),
              tooltip: l.adhkarReminders,
              icon: const RIcon(RIcons.alarm),
              onPressed: () =>
                  showModalBottomSheet<void>(context: context, builder: (_) => const AdhkarRemindersSheet()),
            ),
            IconButton(
              key: const Key('adhkarReset'),
              tooltip: l.adhkarReset,
              icon: const RIcon(RIcons.reset),
              onPressed: () => s.adhkar.reset(session),
            ),
          ],
        ),
        body: ReadableWidth(
          child: ListenableBuilder(
            listenable: Listenable.merge([s.adhkar, s.settings]),
            builder: (context, _) {
              final p = s.adhkar.progress(session);
              final header = <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spaceLg,
                    DesignTokens.spaceSm,
                    DesignTokens.spaceLg,
                    0,
                  ),
                  child: SegmentedButton<AdhkarSession>(
                    key: const Key('adhkarSession'),
                    segments: [
                      ButtonSegment(
                        value: AdhkarSession.morning,
                        icon: const RIcon(RIcons.sunHigh),
                        label: Text(l.adhkarMorning),
                      ),
                      ButtonSegment(
                        value: AdhkarSession.evening,
                        icon: const RIcon(RIcons.moon),
                        label: Text(l.adhkarEvening),
                      ),
                    ],
                    selected: {session},
                    onSelectionChanged: (v) => setState(() {
                      _session = v.single;
                      _at = 0;
                    }),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    DesignTokens.spaceLg,
                    DesignTokens.spaceMd,
                    DesignTokens.spaceLg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session == AdhkarSession.morning ? l.adhkarMorningTitle : l.adhkarEveningTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      Text(
                        l.adhkarProgress(context.num(p.completedItems), context.num(p.items.length)),
                        key: const Key('adhkarProgress'),
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                        child: LinearProgressIndicator(value: p.fraction, minHeight: 6),
                      ),
                      const SizedBox(height: DesignTokens.spaceXs),
                      Text(l.adhkarTapToCount, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ];
              if (s.settings.adhkarCards) {
                // One dhikr per page (owner's choice, 2026-11-11): a bar with the overall progress on
                // top, the dhikr, "listen to this dhikr", and a big counter that moves on when complete.
                final n = p.items.length;
                final pct = (p.fraction * 100).round();
                return Column(
                  children: [
                    header.first,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DesignTokens.spaceLg,
                        DesignTokens.spaceMd,
                        DesignTokens.spaceLg,
                        0,
                      ),
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                            child: LinearProgressIndicator(
                              key: const Key('adhkarTopBar'),
                              value: p.fraction,
                              minHeight: 10,
                            ),
                          ),
                          const SizedBox(height: DesignTokens.spaceXs),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  l.adhkarItemOf(context.num(_at.clamp(0, n - 1) + 1), context.num(n)),
                                  key: const Key('adhkarItemOf'),
                                ),
                              ),
                              Text(l.adhkarPercentDone(context.num(pct)), key: const Key('adhkarProgress')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: CardPager(
                        resetKey: session,
                        count: n,
                        isDone: (i) => p.isDone(p.items[i]),
                        onIndex: (i) {
                          unawaited(DhikrPlayer.instance.stop());
                          setState(() => _at = i);
                        },
                        builder: (context, i) =>
                            _DhikrCard(dhikr: p.items[i], session: session, progress: p, big: true),
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                key: const Key('adhkarList'),
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                children: [
                  ...header,
                  for (final d in p.items) _DhikrCard(dhikr: d, session: session, progress: p),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DhikrCard extends StatelessWidget {
  const _DhikrCard({required this.dhikr, required this.session, required this.progress, this.big = false});
  final bool big;
  final Dhikr dhikr;
  final AdhkarSession session;
  final AdhkarProgress progress;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final scheme = Theme.of(context).colorScheme;
    final done = progress.isDone(dhikr);
    final remaining = progress.remaining(dhikr);
    return Card(
      key: Key('dhikr-${dhikr.index}'),
      margin: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
      color: done ? scheme.surfaceContainer : null,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: InkWell(
              key: Key('dhikrTap-${dhikr.index}'),
              onTap: done
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      s.adhkar.tap(session, dhikr);
                    },
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceLg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (big)
                      Padding(
                        padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                        child: Text(
                          l.adhkarRepeatTimes(context.num(dhikr.meta.count)),
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: scheme.primary),
                        ),
                      ),
                    Text(
                      dhikr.text,
                      textDirection: TextDirection.rtl,
                      style: duaStyle(context, size: big ? 24 : 18),
                    ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    DhikrAudioUrl(
                      pick: (m) => m.forDhikr(dhikr.index),
                      builder: (context, url) => Center(
                        child: DhikrListenButton(url: url, compact: !big),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceMd),
                    Center(
                      child: Container(
                        key: Key('dhikrCount-${dhikr.index}'),
                        width: big ? 170 : 96,
                        height: big ? 170 : 96,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? scheme.primary : scheme.primaryContainer,
                          border: Border.all(color: scheme.secondary.withValues(alpha: 0.6), width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.18),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: done
                            ? RIcon(RIcons.check, size: big ? 64 : 40, color: scheme.onPrimary)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.num('${dhikr.meta.count - remaining}'),
                                    style: TextStyle(
                                      fontSize: big ? 52 : 30,
                                      fontWeight: FontWeight.w700,
                                      color: scheme.onPrimaryContainer,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    '/ ${context.num('${dhikr.meta.count}')}',
                                    style: TextStyle(fontSize: big ? 18 : 14, color: scheme.onPrimaryContainer),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(
                      done ? l.adhkarDone : (big ? l.adhkarTapCounter : l.adhkarRemaining(context.num(remaining))),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Builder(
            builder: (context) {
              final source = l.adhkarShareSourceSession(
                session == AdhkarSession.morning ? l.adhkarMorning : l.adhkarEvening,
              );
              return Wrap(
                alignment: WrapAlignment.end,
                children: [
                  DhikrHadithButton(key: Key('dhikrHadith-${dhikr.index}'), pick: (m) => m.forDhikr(dhikr.index)),
                  CopyButton(text: dhikr.text, buttonKey: Key('dhikrCopy-${dhikr.index}')),
                  DhikrActions(
                    text: dhikr.text,
                    source: source,
                    where: '$source · ${context.num(progress.items.indexOf(dhikr) + 1)}',
                    keyPrefix: 'dhikr${dhikr.index}',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Copies [text] and confirms with a snackbar.
class CopyButton extends StatelessWidget {
  const CopyButton({super.key, required this.text, this.buttonKey});
  final String text;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return TextButton.icon(
      key: buttonKey,
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        await Clipboard.setData(ClipboardData(text: text));
        messenger.showSnackBar(SnackBar(content: Text(l.adhkarCopied)));
      },
      icon: const RIcon(RIcons.copy, size: 18),
      label: Text(l.adhkarCopy),
    );
  }
}

/// Daily morning / evening adhkar notifications (times are local to the prayer city).
class AdhkarRemindersSheet extends StatelessWidget {
  const AdhkarRemindersSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final settings = s.settings;
    return SafeArea(
      child: ListenableBuilder(
        listenable: settings,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.adhkarReminders, style: Theme.of(context).textTheme.titleMedium),
              for (final morning in [true, false])
                Builder(
                  builder: (context) {
                    final m = settings.adhkarReminder(morning);
                    return SwitchListTile(
                      key: Key(morning ? 'reminderMorning' : 'reminderEvening'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(morning ? l.adhkarReminderMorning : l.adhkarReminderEvening),
                      subtitle: m == null
                          ? null
                          : Text(
                              context.num(
                                '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}',
                              ),
                            ),
                      value: m != null,
                      onChanged: (on) async {
                        if (!on) {
                          await settings.setAdhkarReminder(morning, null);
                        } else {
                          final t = await showTimePicker(
                            context: context,
                            initialTime: morning
                                ? const TimeOfDay(hour: 6, minute: 30)
                                : const TimeOfDay(hour: 17, minute: 0),
                          );
                          if (t == null) return;
                          await settings.setAdhkarReminder(morning, t.hour * 60 + t.minute);
                        }
                        await s.reminders.sync();
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
