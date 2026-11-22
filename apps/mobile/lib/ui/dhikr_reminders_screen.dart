import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../domain/dhikr_reminders.dart';
import '../domain/prayer_schedule.dart' show formatClock;
import '../theme/design_tokens.dart';
import 'adaptive.dart';
import 'l10n_ext.dart';
import 'r_icon.dart';
import 'review_notice.dart' show duaStyle;
import 'widgets.dart';

/// «تنبيهات الأذكار» (owner 2026-11-20): the user picks short adhkar and how often they
/// come between two times of the day. Each one shows on the screen and, when the phone is
/// not on silent, is said aloud by Sheikh Mishary Alafasy (the notification sound is the clip).
class DhikrRemindersScreen extends StatefulWidget {
  const DhikrRemindersScreen({super.key});

  @override
  State<DhikrRemindersScreen> createState() => _DhikrRemindersScreenState();
}

class _DhikrRemindersScreenState extends State<DhikrRemindersScreen> {
  AppServices? _services;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _services ??= context.services;
  }

  @override
  void dispose() {
    final p = _services?.dhikrPreview;
    if (p != null && p.playing) p.toggle(p.voice!);
    super.dispose();
  }

  Future<void> _resync() async {
    final s = context.services;
    await s.reminders.sync();
    // iOS shares 64 pending notifications between the adhan and the reminders: re-plan the adhan too.
    await s.adhan.sync(force: true);
  }

  Future<void> _turnOn(bool on) async {
    final s = context.services;
    if (on) await s.adhan.backend.requestPermission();
    await s.settings.setDhikrRemindersOn(on);
    await _resync();
  }

  Future<void> _customEvery() async {
    final l = context.l10n;
    final s = context.services;
    final ctrl = TextEditingController(text: '${s.settings.dhikrRemindersEvery}');
    final v = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.dhikrRemCustomTitle),
        content: TextField(
          key: const Key('dhikrRemCustomField'),
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.dhikrRemCancel)),
          FilledButton(
            key: const Key('dhikrRemCustomOk'),
            onPressed: () => Navigator.pop(ctx, int.tryParse(ctrl.text)),
            child: Text(l.dhikrRemOk),
          ),
        ],
      ),
    );
    if (v == null) return;
    await s.settings.setDhikrRemindersEvery(v);
    await _resync();
  }

  Future<void> _pickTime(bool from) async {
    final s = context.services;
    final m = from ? s.settings.dhikrRemindersFrom : s.settings.dhikrRemindersTo;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60),
    );
    if (t == null) return;
    final v = t.hour * 60 + t.minute;
    await s.settings.setDhikrRemindersWindow(from: from ? v : null, to: from ? null : v);
    await _resync();
  }

  String _everyLabel(int m) {
    final l = context.l10n;
    if (m == 60) return l.dhikrRemHour;
    if (m == 120) return l.dhikrRemTwoHours;
    if (m % 60 == 0) return l.dhikrRemHours(context.num(m ~/ 60));
    return l.dhikrRemMinutes(context.num(m));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final settings = s.settings;
    final ios = defaultTargetPlatform == TargetPlatform.iOS;
    return Scaffold(
      appBar: AppBar(title: Text(l.dhikrRemTitle)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: Listenable.merge([settings, s.dhikrPreview]),
          builder: (context, _) {
            final on = settings.dhikrRemindersOn;
            final every = settings.dhikrRemindersEvery;
            final ids = settings.dhikrReminderIds;
            final plan = planDhikrSlots(
              from: settings.dhikrRemindersFrom,
              to: settings.dhikrRemindersTo,
              every: every,
              max: ios ? dhikrReminderMaxFor(iosCap: 60, adhanNeed: s.adhan.iosNeed) : dhikrReminderMaxAndroid,
            );
            String time(int m) => context.num(
              formatClock(DateTime(2000, 1, 1, m ~/ 60, m % 60), h12: settings.clock12, arabic: context.isArabic),
            );
            final custom = !dhikrReminderIntervals.contains(every);
            return ListView(
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
              children: [
                SectionCard(
                  children: [
                    SwitchListTile(
                      key: const Key('dhikrRemOn'),
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.dhikrRemEnable, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(l.dhikrRemEnableHint),
                      value: on,
                      onChanged: _turnOn,
                    ),
                    if (on && ids.isNotEmpty)
                      Text(
                        l.dhikrRemSummary(context.num(plan.slots.length)),
                        key: const Key('dhikrRemSummary'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                SectionCard(
                  title: l.dhikrRemEvery,
                  children: [
                    Wrap(
                      spacing: DesignTokens.spaceSm,
                      runSpacing: DesignTokens.spaceSm,
                      children: [
                        for (final m in dhikrReminderIntervals)
                          ChoiceChip(
                            key: Key('dhikrRemEvery-$m'),
                            label: Text(_everyLabel(m)),
                            selected: every == m,
                            onSelected: (_) async {
                              await settings.setDhikrRemindersEvery(m);
                              await _resync();
                            },
                          ),
                        ChoiceChip(
                          key: const Key('dhikrRemEveryCustom'),
                          label: Text(custom ? _everyLabel(every) : l.dhikrRemCustom),
                          selected: custom,
                          onSelected: (_) => _customEvery(),
                        ),
                      ],
                    ),
                    if (on && plan.slots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                        child: Text(
                          l.dhikrRemIosFull,
                          key: const Key('dhikrRemIosFull'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    else if (plan.every != every)
                      Padding(
                        padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                        child: Text(
                          l.dhikrRemIosCap(context.num(plan.every)),
                          key: const Key('dhikrRemCapNote'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
                SectionCard(
                  children: [
                    Row(
                      children: [
                        Text(l.dhikrRemFrom, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: DesignTokens.spaceSm),
                        OutlinedButton(
                          key: const Key('dhikrRemFrom'),
                          onPressed: () => _pickTime(true),
                          child: Text(time(settings.dhikrRemindersFrom)),
                        ),
                        const Spacer(),
                        Text(l.dhikrRemTo, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(width: DesignTokens.spaceSm),
                        OutlinedButton(
                          key: const Key('dhikrRemTo'),
                          onPressed: () => _pickTime(false),
                          child: Text(time(settings.dhikrRemindersTo)),
                        ),
                      ],
                    ),
                    const SizedBox(height: DesignTokens.spaceXs),
                    Text(l.dhikrRemWindowHint, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
                SectionCard(
                  title: '${l.dhikrRemPick} ${l.dhikrRemPickHint}',
                  children: [
                    if (ids.isEmpty)
                      Text(l.dhikrRemPickOne, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    for (final d in dhikrReminderItems)
                      CheckboxListTile(
                        key: Key('dhikrRem-${d.id}'),
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: ids.contains(d.id),
                        onChanged: (_) async {
                          await settings.toggleDhikrReminder(d.id);
                          await _resync();
                        },
                        title: Text(s.content.adhkar.items[d.index].text, style: duaStyle(context, size: 16)),
                        secondary: IconButton(
                          key: Key('dhikrRemListen-${d.id}'),
                          tooltip: l.dhikrRemListen,
                          icon: RIcon(s.dhikrPreview.voice == d.id ? RIcons.stop : RIcons.play),
                          onPressed: () => s.dhikrPreview.toggle(d.id),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
