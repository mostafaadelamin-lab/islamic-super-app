import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/gregorian_names.dart';
import '../domain/hijri.dart';
import '../domain/hijri_month.dart';
import '../domain/prayer_schedule.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'prayer_model.dart';
import 'share_capture.dart';

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
  bool _hijri = false;
  final _tableKey = GlobalKey();

  Future<void> _share(String title) async {
    final png = await capturePng(_tableKey);
    if (png == null || !mounted) return;
    await context.services.sharer.sharePng(png, fileName: 'prayer-calendar.png', text: title);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    final ar = context.isArabic;
    final inputs = PrayerInputs.resolve(s.content, s.settings);
    final today = PrayerSchedule.localDate(inputs.location, s.clock().toUtc());
    final first = DateTime.utc(today.year, today.month + _monthDelta);
    final schedule = PrayerSchedule(s.content.calculator);
    final hm = _hijri ? hijriMonthAround(today, _monthDelta) : null;
    final dates =
        hm?.days ??
        [for (var d = 1; d <= daysInMonth(first.year, first.month); d++) DateTime.utc(first.year, first.month, d)];
    final monthTitle = hm != null
        ? '${hijriMonthName(hm.month, arabic: ar)} ${context.num(hm.year)}'
        : '${gregorianMonthName(first.month, arabic: ar)} ${context.num(first.year)}';
    final theme = Theme.of(context);
    final h12 = s.settings.clock12;
    const cols = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    return Scaffold(
      appBar: AppBar(
        title: Text(l.prayerCalendarTitle),
        actions: [
          IconButton(
            key: const Key('calendar.share'),
            tooltip: l.prayerShareCalendar,
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _share('${l.prayerCalendarTitle} · $monthTitle · ${inputs.city.name(ar)}'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(DesignTokens.spaceMd, DesignTokens.spaceSm, DesignTokens.spaceMd, 0),
            child: SegmentedButton<bool>(
              key: const Key('calendar.kind'),
              segments: [
                ButtonSegment(value: false, label: Text(l.prayerGregorian)),
                ButtonSegment(value: true, label: Text(l.prayerHijri)),
              ],
              selected: {_hijri},
              onSelectionChanged: (v) => setState(() {
                _hijri = v.first;
                _monthDelta = 0;
              }),
            ),
          ),
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
                      Text(monthTitle, key: const Key('calendar.month'), style: theme.textTheme.titleMedium),
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
                child: RepaintBoundary(
                  key: _tableKey,
                  child: ColoredBox(
                    color: theme.colorScheme.surface,
                    child: DataTable(
                      key: const Key('calendar.table'),
                      columnSpacing: DesignTokens.spaceMd,
                      headingRowHeight: 40,
                      dataRowMinHeight: 36,
                      dataRowMaxHeight: 40,
                      columns: [
                        DataColumn(label: Text(l.prayerDayCol)),
                        DataColumn(label: Text(_hijri ? l.prayerGregorian : l.prayerHijriCol)),
                        for (final k in cols) DataColumn(label: Text(context.prayerName(k))),
                      ],
                      rows: [
                        for (final (i, date) in dates.indexed)
                          () {
                            final d = i + 1;
                            final day = inputs.day(schedule, date, s.settings.adjustments);
                            final h = hijriFor(date, arabic: ar);
                            final isToday = date == today;
                            return DataRow(
                              key: ValueKey('calendar.day-$d'),
                              selected: isToday,
                              color: isToday ? WidgetStatePropertyAll(theme.colorScheme.primaryContainer) : null,
                              cells: [
                                DataCell(Text('${weekdayName(date, arabic: ar)} ${context.num(_hijri ? h.day : d)}')),
                                DataCell(
                                  Text(
                                    _hijri
                                        ? '${context.num(date.day)} ${gregorianMonthName(date.month, arabic: ar)}'
                                        : '${context.num(h.day)} ${h.monthName}',
                                  ),
                                ),
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
            ),
          ),
        ],
      ),
    );
  }
}
