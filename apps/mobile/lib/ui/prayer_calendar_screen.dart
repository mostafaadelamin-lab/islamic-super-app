import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/gregorian_names.dart';
import '../domain/hijri.dart';
import '../domain/prayer_schedule.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'prayer_model.dart';

/// Days in Gregorian [month] (1-12) of [year].
int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

/// Monthly prayer timetable for the selected place: one row per day with the
/// Hijri date and the six times; today is highlighted; arrows change month.
class PrayerCalendarScreen extends StatefulWidget {
  const PrayerCalendarScreen({super.key});

  @override
  State<PrayerCalendarScreen> createState() => _PrayerCalendarScreenState();
}

class _PrayerCalendarScreenState extends State<PrayerCalendarScreen> {
  int _monthDelta = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final ar = context.isArabic;
    final inputs = PrayerInputs.resolve(s.content, s.settings);
    final today = PrayerSchedule.localDate(inputs.location, s.clock().toUtc());
    final first = DateTime.utc(today.year, today.month + _monthDelta);
    final schedule = PrayerSchedule(s.content.calculator);
    final n = daysInMonth(first.year, first.month);
    final theme = Theme.of(context);
    final h12 = s.settings.clock12;
    const cols = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    return Scaffold(
      appBar: AppBar(title: Text(l.prayerCalendarTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spaceSm),
            child: Row(
              children: [
                IconButton(
                  key: const Key('calendar.prev'),
                  tooltip: l.prayerPrevMonth,
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() => _monthDelta--),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '${gregorianMonthName(first.month, arabic: ar)} ${context.num(first.year)}',
                        key: const Key('calendar.month'),
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(inputs.city.name(ar), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  key: const Key('calendar.next'),
                  tooltip: l.prayerNextMonth,
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() => _monthDelta++),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              key: const Key('calendar.scroll'),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  key: const Key('calendar.table'),
                  columnSpacing: DesignTokens.spaceMd,
                  headingRowHeight: 40,
                  dataRowMinHeight: 36,
                  dataRowMaxHeight: 40,
                  columns: [
                    DataColumn(label: Text(l.prayerDayCol)),
                    DataColumn(label: Text(l.prayerHijriCol)),
                    for (final k in cols) DataColumn(label: Text(context.prayerName(k))),
                  ],
                  rows: [
                    for (var d = 1; d <= n; d++)
                      () {
                        final date = DateTime.utc(first.year, first.month, d);
                        final day = inputs.day(schedule, date, s.settings.adjustments);
                        final h = hijriFor(date, arabic: ar);
                        final isToday = date == today;
                        return DataRow(
                          key: ValueKey('calendar.day-$d'),
                          selected: isToday,
                          color: isToday ? WidgetStatePropertyAll(theme.colorScheme.primaryContainer) : null,
                          cells: [
                            DataCell(Text('${weekdayName(date, arabic: ar)} ${context.num(d)}')),
                            DataCell(Text('${context.num(h.day)} ${h.monthName}')),
                            for (final k in cols)
                              DataCell(
                                Text(
                                  day == null ? '—' : context.num(day.clock(k, h12: h12, arabic: ar)),
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                          ],
                        );
                      }(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
