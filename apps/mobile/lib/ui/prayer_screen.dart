import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../data/content.dart';
import '../domain/prayer.dart';
import '../domain/prayer_schedule.dart';
import '../theme/design_tokens.dart';
import 'city_picker_screen.dart';
import 'l10n_ext.dart';
import 'prayer_model.dart';
import 'widgets.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
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

  String _methodName(BuildContext context, PrayerMethod m) => context.isArabic ? m.nameAr : m.nameEn;

  @override
  Widget build(BuildContext context) {
    final s = context.services;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l.prayerTitle)),
      body: ListenableBuilder(
        listenable: s.settings,
        builder: (context, _) {
          final pv = PrayerView.compute(s);
          final cfg = s.content.prayerConfig;
          final adjustments = s.settings.adjustments;
          final today = pv.today;
          final next = pv.next;
          return ListView(
            key: const Key('prayerList'),
            padding: const EdgeInsets.only(bottom: DesignTokens.spaceXl),
            children: [
              SectionCard(
                children: [
                  ListTile(
                    key: const Key('cityTile'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.location_city),
                    title: Text(l.prayerCity),
                    subtitle: Text(pv.city.name(context.isArabic), key: const Key('cityName')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final c = await Navigator.of(
                        context,
                      ).push<City>(MaterialPageRoute(builder: (_) => CityPickerScreen(selectedId: pv.city.id)));
                      if (c != null) await s.settings.setCity(c.id, c.method);
                    },
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
                ],
              ),
              SectionCard(
                title: l.prayerTitle,
                children: [
                  Text(l.prayerDate(context.numLtr(_date(pv.date))), key: const Key('prayerDate')),
                  Text(l.prayerTimezone(pv.city.tz), key: const Key('prayerTz')),
                  const SizedBox(height: DesignTokens.spaceSm),
                  if (today == null)
                    Text(l.prayerNoPrayerToday, key: const Key('polarMessage'))
                  else ...[
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
                    for (final k in prayerKeys)
                      _TimeRow(
                        name: context.prayerName(k),
                        time: context.num(today.hhmm(k)),
                        isNext: next != null && next.key == k && next.at == today.day.utc[k],
                        rowKey: Key('time-$k'),
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
                          icon: const Icon(Icons.restart_alt),
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
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.name, required this.time, required this.isNext, required this.rowKey});
  final String name;
  final String time;
  final bool isNext;
  final Key rowKey;

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
          icon: const Icon(Icons.remove),
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
          icon: const Icon(Icons.add),
          onPressed: value < maxAdjustment ? () => onStep(1) : null,
        ),
      ],
    );
  }
}

/// Static compass diagram: north at the top, a needle at [bearing] degrees.
class QiblaCompass extends StatelessWidget {
  const QiblaCompass({super.key, required this.bearing, this.size = 160});
  final double bearing;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      key: const Key('qiblaCompass'),
      label: context.l10n.prayerCompassLabel(context.num(bearing.toStringAsFixed(1))),
      image: true,
      container: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: CompassPainter(
              bearing: bearing,
              ring: scheme.outline,
              needle: scheme.primary,
              text: scheme.onSurface,
              north: context.l10n.prayerNorth,
              textDirection: Directionality.of(context),
            ),
          ),
        ),
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  CompassPainter({
    required this.bearing,
    required this.ring,
    required this.needle,
    required this.text,
    required this.north,
    required this.textDirection,
  });

  final double bearing;
  final Color ring;
  final Color needle;
  final Color text;
  final String north;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = ring,
    );
    for (var i = 0; i < 360; i += 30) {
      final a = i * math.pi / 180;
      final p1 = c + Offset(math.sin(a), -math.cos(a)) * (r - 8);
      final p2 = c + Offset(math.sin(a), -math.cos(a)) * r;
      canvas.drawLine(
        p1,
        p2,
        Paint()
          ..strokeWidth = 2
          ..color = ring,
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: north,
        style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      textDirection: textDirection,
    )..layout();
    tp.paint(canvas, c + Offset(-tp.width / 2, -r + 10));
    final a = bearing * math.pi / 180;
    final dir = Offset(math.sin(a), -math.cos(a));
    final tip = c + dir * (r - 14);
    final paint = Paint()
      ..color = needle
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, tip, paint);
    final perp = Offset(-dir.dy, dir.dx);
    final head = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((tip - dir * 14 + perp * 7).dx, (tip - dir * 14 + perp * 7).dy)
      ..lineTo((tip - dir * 14 - perp * 7).dx, (tip - dir * 14 - perp * 7).dy)
      ..close();
    canvas.drawPath(head, Paint()..color = needle);
    canvas.drawCircle(c, 5, Paint()..color = needle);
  }

  @override
  bool shouldRepaint(CompassPainter old) =>
      old.bearing != bearing || old.needle != needle || old.ring != ring || old.north != north;
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
