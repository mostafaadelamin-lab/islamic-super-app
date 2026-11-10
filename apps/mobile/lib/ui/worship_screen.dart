import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/gregorian_names.dart';
import '../domain/worship.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'adaptive.dart';
import 'r_icon.dart';

/// Worship tracker: monthly calendar, the chosen day's five prayers, fasting
/// and a note, weekly / monthly totals and the streak.
class WorshipScreen extends StatefulWidget {
  const WorshipScreen({super.key});

  @override
  State<WorshipScreen> createState() => _WorshipScreenState();
}

class _WorshipScreenState extends State<WorshipScreen> {
  int _monthDelta = 0;
  DateTime? _picked;
  final _note = TextEditingController();
  String? _noteFor;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final ar = context.isArabic;
    final w = context.services.worship;
    final scheme = Theme.of(context).colorScheme;
    final t = w.today;
    final today = DateTime.utc(t.year, t.month, t.day);
    final selected = _picked ?? today;
    final first = DateTime.utc(today.year, today.month + _monthDelta);
    final days = DateTime.utc(first.year, first.month + 1, 0).day;
    // Saturday-first weeks (DateTime.weekday: Monday = 1 … Sunday = 7).
    final lead = (first.weekday + 1) % 7;
    return Scaffold(
      appBar: AppBar(title: Text(l.worshipTitle)),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: w,
          builder: (context, _) {
            final log = w.log;
            final day = log.dayOf(selected);
            final key = worshipDay(selected);
            if (_noteFor != key) {
              _noteFor = key;
              _note.text = day.note;
            }
            final week = log.week(today);
            final month = log.month(first.year, first.month, today);
            return ListView(
              padding: const EdgeInsets.all(DesignTokens.spaceLg),
              children: [
                Text(
                  l.worshipStreak(context.num(log.streak(today))),
                  key: const Key('worship.streak'),
                  style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: DesignTokens.spaceMd),
                Row(
                  children: [
                    IconButton(
                      key: const Key('worship.prev'),
                      onPressed: () => setState(() => _monthDelta--),
                      icon: const RIcon(RIcons.chevron),
                      tooltip: l.prayerPrevMonth,
                    ),
                    Expanded(
                      child: Text(
                        '${gregorianMonthName(first.month, arabic: ar)} ${context.num(first.year)}',
                        key: const Key('worship.month'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    IconButton(
                      key: const Key('worship.next'),
                      onPressed: _monthDelta >= 0 ? null : () => setState(() => _monthDelta++),
                      icon: const RIcon(RIcons.chevronForward),
                      tooltip: l.prayerNextMonth,
                    ),
                  ],
                ),
                GridView.count(
                  key: const Key('worship.grid'),
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 0.85,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Center(
                        child: Text(
                          _short(weekdayName(DateTime.utc(2026, 1, 3 + i), arabic: ar), ar),
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                    for (var d = 1; d <= days; d++)
                      () {
                        final date = DateTime.utc(first.year, first.month, d);
                        final rec = log.dayOf(date);
                        final future = date.isAfter(today);
                        final isSel = date == selected;
                        return InkWell(
                          key: Key('worship.day-${worshipDay(date)}'),
                          onTap: future ? null : () => setState(() => _picked = date),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: rec.full ? scheme.primaryContainer : null,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSel
                                    ? scheme.primary
                                    : date == today
                                    ? scheme.tertiary
                                    : scheme.outlineVariant,
                                width: isSel ? 2 : 1,
                              ),
                            ),
                            child: Opacity(
                              opacity: future ? 0.4 : 1,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(context.num(d), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  Text(
                                    '${rec.prayed > 0 ? context.num('${rec.prayed}/5') : ''}${rec.fasting ? ' ◐' : ''}',
                                    style: Theme.of(context).textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }(),
                  ],
                ),
                const SizedBox(height: DesignTokens.spaceLg),
                Text(
                  selected == today
                      ? l.worshipToday
                      : '${weekdayName(selected, arabic: ar)} ${context.num(selected.day)} ${gregorianMonthName(selected.month, arabic: ar)}',
                  key: const Key('worship.dayTitle'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                for (final p in worshipPrayers)
                  CheckboxListTile(
                    key: Key('worship.$p'),
                    contentPadding: EdgeInsets.zero,
                    title: Text(context.prayerName(p)),
                    value: day.prayers.contains(p),
                    onChanged: (_) => w.togglePrayer(selected, p),
                  ),
                SwitchListTile(
                  key: const Key('worship.fasting'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.worshipFasting),
                  value: day.fasting,
                  onChanged: (v) => w.setFasting(selected, v),
                ),
                TextField(
                  key: const Key('worship.note'),
                  controller: _note,
                  maxLength: maxWorshipNote,
                  maxLines: 2,
                  decoration: InputDecoration(labelText: l.worshipNote),
                  onChanged: (v) => w.setNote(selected, v),
                ),
                const SizedBox(height: DesignTokens.spaceLg),
                _StatsCard(key: const Key('worship.week'), title: l.worshipWeek, s: week),
                _StatsCard(key: const Key('worship.monthStats'), title: l.worshipMonth, s: month),
                const SizedBox(height: DesignTokens.spaceSm),
                Text(l.worshipPrivate, style: Theme.of(context).textTheme.bodySmall),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Short weekday label for the calendar header ("Sat", "السبت" → "سبت").
String _short(String name, bool ar) => ar ? name.replaceFirst('ال', '') : name.substring(0, 3);

class _StatsCard extends StatelessWidget {
  const _StatsCard({super.key, required this.title, required this.s});
  final String title;
  final WorshipStats s;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final pct = s.possible == 0 ? 0 : (s.prayed * 100 / s.possible).round();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: DesignTokens.spaceXs),
            Text('${l.worshipPrayedOf(context.num(s.prayed), context.num(s.possible))} (${context.num(pct)}%)'),
            const SizedBox(height: DesignTokens.spaceXs),
            LinearProgressIndicator(value: s.possible == 0 ? 0 : s.prayed / s.possible),
            const SizedBox(height: DesignTokens.spaceXs),
            Text(
              '${l.worshipFullDays(context.num(s.fullDays))} · ${l.worshipFasted(context.num(s.fasted))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
