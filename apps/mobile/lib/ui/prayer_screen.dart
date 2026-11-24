import 'dart:async';

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/content.dart';
import '../data/location.dart';
import '../data/settings.dart';
import '../domain/adhan_schedule.dart';
import '../domain/gregorian_names.dart';
import '../domain/hijri.dart';
import '../domain/prayer.dart';
import '../domain/prayer_schedule.dart';
import '../theme/design_tokens.dart';
import 'city_picker_screen.dart';
import 'l10n_ext.dart';
import 'prayer_calendar_screen.dart';
import 'prayer_model.dart';
import 'qibla_screen.dart';
import 'locate.dart';
import 'settings_screen.dart' show AdhanSettingsCard, HijriOffsetCard;
import 'widgets.dart';
import 'adaptive.dart';
import 'r_icon.dart';
import 'shell_back.dart';

/// Prayer times. The tab is compact (date, the five times with their alert,
/// and "edit prayer times"); [settingsMode] is that edit screen: location,
/// calculation method, adjustments, alerts and the qibla.
class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key, this.settingsMode = false});
  final bool settingsMode;

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Timer? _ticker;

  /// Days from today shown in the times card (arrows; 0 = today).
  int _dayOffset = 0;
  bool _locating = false;
  String? _geoError;

  Future<void> _useLocation() async {
    final s = context.services;
    final l = context.l10n;
    setState(() {
      _locating = true;
      _geoError = null;
    });
    final r = await locateAndSave(s);
    if (!mounted) return;
    switch (r) {
      case LocationFound():
        setState(() => _locating = false);
      case LocationDenied():
        setState(() {
          _locating = false;
          _geoError = l.prayerGeoDenied;
        });
      case LocationUnavailable():
        setState(() {
          _locating = false;
          _geoError = l.prayerGeoUnavailable;
        });
    }
  }

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

  String _methodName(BuildContext context, PrayerMethod m) => context.isArabic ? m.nameAr : m.nameEn;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leading: shellBackButton(context),
        title: Text(widget.settingsMode ? l.prayerEditTimes : l.adhanTabTitle),
      ),
      body: ReadableWidth(
        child: ListenableBuilder(
          listenable: s.settings,
          builder: (context, _) {
            final pv = PrayerView.compute(s);
            final cfg = s.content.prayerConfig;
            final adjustments = s.settings.adjustments;
            final ar = context.isArabic;
            final h12 = s.settings.clock12;
            final shownDate = pv.date.add(Duration(days: _dayOffset));
            final today = _dayOffset == 0
                ? pv.today
                : PrayerInputs.resolve(
                    s.content,
                    s.settings,
                  ).day(PrayerSchedule(s.content.calculator), shownDate, adjustments);
            final next = _dayOffset == 0 ? pv.next : null;
            final hijri = hijriFor(shownDate, arabic: ar);
            final cityCard = <Widget>[
              SectionCard(
                children: [
                  ListTile(
                    key: const Key('cityTile'),
                    contentPadding: EdgeInsets.zero,
                    leading: const RIcon(RIcons.city),
                    title: Text(l.prayerCity),
                    subtitle: Text(pv.city.name(context.isArabic), key: const Key('cityName')),
                    trailing: const RIcon(RIcons.chevronForward),
                    onTap: () async {
                      final c = await Navigator.of(
                        context,
                      ).push<City>(MaterialPageRoute(builder: (_) => CityPickerScreen(selectedId: pv.city.id)));
                      if (c != null) await s.settings.setCity(c.id, c.method);
                    },
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      key: const Key('useLocation'),
                      onPressed: _locating ? null : _useLocation,
                      icon: _locating
                          ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const RIcon(RIcons.myLocation),
                      label: Text(_locating ? l.prayerLocating : l.prayerUseLocation),
                    ),
                  ),
                  if (_geoError != null)
                    Text(
                      _geoError!,
                      key: const Key('geoError'),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  const SizedBox(height: DesignTokens.spaceSm),
                  LabeledDropdown<String>(
                    dropdownKey: const Key('methodDropdown'),
                    label: l.prayerMethod,
                    value: pv.method,
                    items: {for (final m in cfg.methods.values) m.id: _methodName(context, m)},
                    onChanged: s.settings.setMethod,
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  LabeledDropdown<String>(
                    dropdownKey: const Key('asrDropdown'),
                    label: l.prayerAsrMethod,
                    value: pv.asr,
                    items: {'standard': l.prayerAsrStandard, 'hanafi': l.prayerAsrHanafi},
                    onChanged: s.settings.setAsr,
                  ),
                  const SizedBox(height: DesignTokens.spaceMd),
                  LabeledDropdown<bool>(
                    dropdownKey: const Key('clockDropdown'),
                    label: l.prayerClock,
                    value: h12,
                    items: {false: l.prayerClock24, true: l.prayerClock12},
                    onChanged: s.settings.setClock12,
                  ),
                ],
              ),
            ];
            final timesCard = <Widget>[
              SectionCard(
                title: l.prayerTitle,
                children: [
                  Row(
                    children: [
                      IconButton(
                        key: const Key('dayPrev'),
                        tooltip: l.prayerPrevDay,
                        icon: RIcon(ar ? RIcons.chevronForward : RIcons.chevron),
                        onPressed: () => setState(() => _dayOffset--),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            Text(
                              '${weekdayName(shownDate, arabic: ar)} ${context.num(shownDate.day)} '
                              '${gregorianMonthName(shownDate.month, arabic: ar)} ${context.num(shownDate.year)}',
                              key: const Key('dayLabel'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              l.homeHijriDate(context.num(hijri.day), hijri.monthName, context.num(hijri.year)),
                              key: const Key('dayHijri'),
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        key: const Key('dayNext'),
                        tooltip: l.prayerNextDay,
                        icon: RIcon(ar ? RIcons.chevron : RIcons.chevronForward),
                        onPressed: () => setState(() => _dayOffset++),
                      ),
                    ],
                  ),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: DesignTokens.spaceSm,
                    children: [
                      if (_dayOffset != 0)
                        TextButton(
                          key: const Key('dayToday'),
                          onPressed: () => setState(() => _dayOffset = 0),
                          child: Text(l.prayerBackToToday),
                        ),
                      TextButton.icon(
                        key: const Key('openCalendar'),
                        onPressed: () => Navigator.of(
                          context,
                        ).push(MaterialPageRoute<void>(builder: (_) => const PrayerCalendarScreen())),
                        icon: const RIcon(RIcons.calendar),
                        label: Text(l.prayerOpenCalendar),
                      ),
                    ],
                  ),
                  Text(l.prayerDate(context.numLtr(_date(shownDate))), key: const Key('prayerDate')),
                  Text(l.prayerTimezone(pv.city.tz), key: const Key('prayerTz')),
                  const SizedBox(height: DesignTokens.spaceSm),
                  if (today == null)
                    Text(l.prayerNoPrayerToday, key: const Key('polarMessage'))
                  else ...[
                    if (s.settings.iqamaPlan case final plan? when _dayOffset == 0)
                      if (PrayerSchedule.iqamaWait(s.clock().toUtc(), today, plan) case final wait?)
                        Container(
                          key: const Key('iqamaWait'),
                          margin: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
                          padding: const EdgeInsets.all(DesignTokens.spaceMd),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                          ),
                          child: Text(
                            l.iqamaWait(
                              context.prayerName(wait.key),
                              context.numLtr(PrayerSchedule.formatCountdown(wait.remaining)),
                            ),
                            key: const Key('iqamaCountdown'),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                    if (next != null)
                      Container(
                        key: const Key('nextPrayer'),
                        padding: const EdgeInsets.all(DesignTokens.spaceMd),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l.prayerNext(context.prayerName(next.key)),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              l.prayerIn(context.numLtr(PrayerSchedule.formatCountdown(next.remaining))),
                              key: const Key('countdown'),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: DesignTokens.spaceSm),
                    Container(
                      key: const Key('timesTint'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spaceMd,
                        vertical: DesignTokens.spaceSm,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                      ),
                      child: Column(
                        children: [
                          for (final k in prayerKeys)
                            _TimeRow(
                              name: context.prayerName(k),
                              time: context.num(today.clock(k, h12: h12, arabic: ar)),
                              isNext: next != null && next.key == k && next.at == today.day.utc[k],
                              rowKey: Key('time-$k'),
                              // Bell per obligatory prayer once adhan alerts are on.
                              bell: s.settings.adhanEnabled && obligatoryPrayers.contains(k)
                                  ? IconButton(
                                      key: Key('adhanBell-$k'),
                                      visualDensity: VisualDensity.compact,
                                      tooltip: s.settings.adhanFor(k)
                                          ? l.adhanBellOn(context.prayerName(k))
                                          : l.adhanBellOff(context.prayerName(k)),
                                      icon: RIcon(
                                        s.settings.adhanFor(k) ? RIcons.bell : RIcons.bellOff,
                                        color: s.settings.adhanFor(k) ? Theme.of(context).colorScheme.primary : null,
                                      ),
                                      onPressed: () => s.settings.setAdhanFor(k, !s.settings.adhanFor(k)),
                                    )
                                  // Keeps the times aligned on the sunrise row.
                                  : (s.settings.adhanEnabled ? const SizedBox(width: 40) : null),
                            ),
                        ],
                      ),
                    ),
                    if (today.day.highLatitudeAdjusted.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                        child: Text(
                          l.prayerHighLat(
                            today.day.highLatitudeAdjusted.map(context.prayerName).join(context.isArabic ? '، ' : ', '),
                          ),
                          key: const Key('highLatNote'),
                        ),
                      ),
                  ],
                ],
              ),
            ];
            final rest = <Widget>[
              if (s.settings.adhanEnabled) _AdhanExtrasCard(settings: s.settings),
              SectionCard(
                children: [
                  ExpansionTile(
                    key: const Key('adjustTile'),
                    tilePadding: EdgeInsets.zero,
                    title: Text(l.prayerAdjust),
                    children: [
                      for (final k in prayerKeys)
                        _AdjustRow(
                          prayerKey: k,
                          value: adjustments[k] ?? 0,
                          // Read the stored value at tap time so quick taps accumulate.
                          onStep: (d) => s.settings.setAdjustment(k, (s.settings.adjustments[k] ?? 0) + d),
                        ),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: TextButton.icon(
                          key: const Key('resetAdjust'),
                          onPressed: s.settings.resetAdjustments,
                          icon: const RIcon(RIcons.reset),
                          label: Text(l.prayerResetAdjust),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SectionCard(
                title: l.prayerQibla,
                children: [
                  Text(l.prayerQiblaDeg(context.num(pv.qibla.toStringAsFixed(1))), key: const Key('qiblaText')),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Center(child: QiblaCompass(bearing: pv.qibla)),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Text(l.prayerQiblaNote, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: DesignTokens.spaceSm),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: FilledButton.tonalIcon(
                      key: const Key('openLiveQibla'),
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const QiblaScreen())),
                      icon: const RIcon(RIcons.compass),
                      label: Text(l.qiblaTitle),
                    ),
                  ),
                ],
              ),
            ];
            if (widget.settingsMode) {
              return ListView(
                key: const Key('prayerSettingsList'),
                padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
                children: [
                  if (today != null) _TimesStrip(today: today, h12: h12),
                  ...cityCard,
                  AutoLocationCard(placeLabel: placeLabel(s, pv.city, arabic: ar)),
                  ...rest,
                  const HijriOffsetCard(),
                ],
              );
            }
            return ListView(
              key: const Key('prayerList'),
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
              children: [
                // Owner (2026-11-24): this tab is «الأذان» — the adhan alerts with all their parts come
                // first, then the prayer times.
                const AdhanSettingsCard(),
                if (s.settings.adhanEnabled) _AdhanExtrasCard(settings: s.settings),
                ...timesCard,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceXl, vertical: DesignTokens.spaceSm),
                  child: Text(
                    l.prayerCompactNote,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceLg, vertical: DesignTokens.spaceSm),
                  child: ListTile(
                    key: const Key('editPrayerTimes'),
                    leading: RIcon(RIcons.edit, color: Theme.of(context).colorScheme.primary),
                    title: Text(l.prayerEditTimes, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(placeLabel(s, pv.city, arabic: ar)),
                    trailing: const RIcon(RIcons.chevronForward),
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute<void>(builder: (_) => const PrayerScreen(settingsMode: true))),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Reminder before the adhan and the iqama alert (minutes per prayer).
class _AdhanExtrasCard extends StatelessWidget {
  const _AdhanExtrasCard({required this.settings});
  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SectionCard(
      key: const Key('adhanExtras'),
      children: [
        ExpansionTile(
          key: const Key('adhanExtrasTile'),
          tilePadding: EdgeInsets.zero,
          title: Text(l.adhanExtras),
          children: [
            LabeledDropdown<int>(
              dropdownKey: const Key('preAdhanDropdown'),
              label: l.adhanPre,
              value: settings.adhanPreMinutes,
              items: {for (final m in preAdhanChoices) m: m == 0 ? l.adhanPreOff : l.adhanPreMinutes(context.num(m))},
              onChanged: settings.setAdhanPreMinutes,
            ),
            SwitchListTile(
              key: const Key('iqamaSwitch'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.adhanIqama),
              value: settings.iqamaEnabled,
              onChanged: settings.setIqamaEnabled,
            ),
            if (settings.iqamaEnabled)
              for (final k in obligatoryPrayers)
                Row(
                  key: Key('iqama-$k'),
                  children: [
                    Expanded(child: Text(context.prayerName(k))),
                    IconButton(
                      key: Key('iqamaMinus-$k'),
                      tooltip: l.adhanIqamaDecrease(context.prayerName(k)),
                      icon: const RIcon(RIcons.minus),
                      onPressed: settings.iqamaMinutes(k) > minIqama
                          ? () => settings.setIqamaMinutes(k, settings.iqamaMinutes(k) - 1)
                          : null,
                    ),
                    SizedBox(
                      width: 120,
                      child: Text(
                        l.adhanIqamaMinutes(context.num(settings.iqamaMinutes(k))),
                        key: Key('iqamaValue-$k'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      key: Key('iqamaPlus-$k'),
                      tooltip: l.adhanIqamaIncrease(context.prayerName(k)),
                      icon: const RIcon(RIcons.plus),
                      onPressed: settings.iqamaMinutes(k) < maxIqama
                          ? () => settings.setIqamaMinutes(k, settings.iqamaMinutes(k) + 1)
                          : null,
                    ),
                  ],
                ),
            Padding(
              padding: const EdgeInsets.only(bottom: DesignTokens.spaceSm),
              child: Text(l.adhanExtrasNote, style: Theme.of(context).textTheme.bodySmall),
            ),
            const Divider(),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.adhanSoundPerPrayer, style: Theme.of(context).textTheme.titleSmall),
            ),
            for (final k in obligatoryPrayers)
              Padding(
                padding: const EdgeInsets.only(top: DesignTokens.spaceSm),
                child: LabeledDropdown<String>(
                  dropdownKey: Key('soundFor-$k'),
                  label: context.prayerName(k),
                  value: settings.hasOwnSound(k) ? settings.adhanSoundFor(k) : '',
                  items: {
                    '': l.adhanSoundGeneral,
                    'adhan': l.adhanSoundAdhan,
                    'tone': l.adhanSoundTone,
                    'silent': l.adhanSoundSilent,
                  },
                  onChanged: (v) => settings.setAdhanSoundFor(k, v.isEmpty ? null : v),
                ),
              ),
            const Divider(),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.alertOthers, style: Theme.of(context).textTheme.titleSmall),
            ),
            SwitchListTile(
              key: const Key('sunriseAlert'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.alertSunrise),
              value: settings.sunriseAlert,
              onChanged: settings.setSunriseAlert,
            ),
            SwitchListTile(
              key: const Key('lastThirdAlert'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.alertLastThird),
              value: settings.lastThirdAlert,
              onChanged: settings.setLastThirdAlert,
            ),
            SwitchListTile(
              key: const Key('fridayAlert'),
              contentPadding: EdgeInsets.zero,
              title: Text(l.alertFriday),
              subtitle: settings.fridayReminder == null
                  ? null
                  : Text(
                      context.num(
                        '${(settings.fridayReminder! ~/ 60).toString().padLeft(2, '0')}:'
                        '${(settings.fridayReminder! % 60).toString().padLeft(2, '0')}',
                      ),
                    ),
              value: settings.fridayReminder != null,
              onChanged: (on) async {
                final s = context.services;
                if (!on) {
                  await settings.setFridayReminder(null);
                } else {
                  final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 10, minute: 0));
                  if (t == null) return;
                  await settings.setFridayReminder(t.hour * 60 + t.minute);
                }
                await s.reminders.sync();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.name, required this.time, required this.isNext, required this.rowKey, this.bell});
  final String name;
  final String time;
  final bool isNext;
  final Key rowKey;
  final Widget? bell;

  @override
  Widget build(BuildContext context) {
    final style = isNext
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      key: rowKey,
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceXs),
      child: Row(
        children: [
          Expanded(child: Text(name, style: style)),
          Text(time, style: style, textDirection: TextDirection.ltr),
          ?bell,
        ],
      ),
    );
  }
}

class _AdjustRow extends StatelessWidget {
  const _AdjustRow({required this.prayerKey, required this.value, required this.onStep});
  final String prayerKey;
  final int value;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = context.prayerName(prayerKey);
    final shown = value > 0 ? '+$value' : '$value';
    return Row(
      key: Key('adjust-$prayerKey'),
      children: [
        Expanded(child: Text(name)),
        IconButton(
          key: Key('adjustMinus-$prayerKey'),
          tooltip: l.prayerDecrease(name),
          icon: const RIcon(RIcons.minus),
          onPressed: value > minAdjustment ? () => onStep(-1) : null,
        ),
        SizedBox(
          width: 72,
          child: Text(
            l.prayerMinutesValue(context.num(shown)),
            key: Key('adjustValue-$prayerKey'),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          key: Key('adjustPlus-$prayerKey'),
          tooltip: l.prayerIncrease(name),
          icon: const RIcon(RIcons.plus),
          onPressed: value < maxAdjustment ? () => onStep(1) : null,
        ),
      ],
    );
  }
}

/// Static compass diagram: north at the top, a needle at [bearing] degrees.
class QiblaCompass extends StatelessWidget {
  const QiblaCompass({super.key, required this.bearing, this.size = 180});
  final double bearing;
  final double size;

  /// The same emerald-and-gold dial as the live qibla screen, north-up.
  @override
  Widget build(BuildContext context) => SizedBox.square(
    key: const Key('qiblaCompass'),
    dimension: size,
    child: FittedBox(child: QiblaDial(qibla: bearing, heading: 0, live: false)),
  );
}

/// A labelled dropdown whose selection always reflects [value].
class LabeledDropdown<T> extends StatelessWidget {
  const LabeledDropdown({
    super.key,
    required this.dropdownKey,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final Key dropdownKey;
  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: label,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        key: dropdownKey,
        value: value,
        isExpanded: true,
        items: [
          for (final e in items.entries)
            DropdownMenuItem<T>(
              value: e.key,
              child: Text(e.value, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ),
  );
}

/// A strip of the day's five prayers (plus sunrise): icon, name and time.
class _TimesStrip extends StatelessWidget {
  const _TimesStrip({required this.today, required this.h12});
  final LocalPrayerDay today;
  final bool h12;

  static const _icons = {
    'fajr': RIcons.sunrise,
    'sunrise': RIcons.sunLow,
    'dhuhr': RIcons.sunHigh,
    'asr': RIcons.sun,
    'maghrib': RIcons.sunset,
    'isha': RIcons.moon,
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ar = context.isArabic;
    return Padding(
      key: const Key('timesStrip'),
      padding: const EdgeInsets.fromLTRB(DesignTokens.spaceLg, DesignTokens.spaceMd, DesignTokens.spaceLg, 0),
      child: Row(
        children: [
          for (final k in prayerKeys)
            Expanded(
              child: Container(
                key: Key('time-$k'),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.spaceSm),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Column(
                  children: [
                    RIcon(_icons[k]!, color: scheme.primary, size: 20),
                    const SizedBox(height: 2),
                    FittedBox(child: Text(context.prayerName(k), style: Theme.of(context).textTheme.labelSmall)),
                    FittedBox(
                      child: Text(
                        context.num(today.clock(k, h12: h12, arabic: ar)),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Location services: follow the phone's location automatically, with the
/// current place name.
class AutoLocationCard extends StatelessWidget {
  const AutoLocationCard({super.key, required this.placeLabel});
  final String placeLabel;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    return SectionCard(
      title: l.prayerLocationServices,
      children: [
        SwitchListTile(
          key: const Key('autoLocation'),
          contentPadding: EdgeInsets.zero,
          secondary: const RIcon(RIcons.location),
          title: Text(l.prayerAutoLocation),
          subtitle: Text(placeLabel),
          value: s.settings.autoLocation,
          onChanged: (v) async {
            await s.settings.setAutoLocation(v);
            if (v) {
              try {
                await locateAndSave(s, keepMethod: true);
              } catch (_) {}
            }
          },
        ),
        Text(l.prayerAutoLocationNote, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
