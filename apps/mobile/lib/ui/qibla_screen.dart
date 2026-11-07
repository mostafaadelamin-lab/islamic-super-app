import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_services.dart';
import '../domain/qibla.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'prayer_model.dart';
import 'prayer_screen.dart';

/// Live qibla compass (accelerometer + magnetometer via sensors_plus), with
/// the static north-up diagram as a fallback when there is no usable sensor.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  static const timeout = Duration(seconds: 3);

  @override
  State<QiblaScreen> createState() => QiblaScreenState();
}

class QiblaScreenState extends State<QiblaScreen> {
  final _filter = HeadingFilter();
  StreamSubscription<Vec3>? _acc;
  StreamSubscription<Vec3>? _mag;
  Timer? _timeout;
  Vec3? _gravity;
  double? _heading;
  bool _error = false;
  bool _timedOut = false;

  CompassMode get mode => compassMode(hasHeading: _heading != null, sensorError: _error, timedOut: _timedOut);
  double? get heading => _heading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_acc != null) return;
    final sensors = context.services.sensors;
    void fail(Object _) {
      if (mounted && _heading == null) setState(() => _error = true);
    }

    try {
      _acc = sensors.accelerometer.listen((v) => _gravity = v, onError: fail, cancelOnError: true);
      _mag = sensors.magnetometer.listen(_onMagnetic, onError: fail, cancelOnError: true);
    } catch (e) {
      _error = true;
    }
    _timeout = Timer(QiblaScreen.timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  void _onMagnetic(Vec3 m) {
    final g = _gravity;
    if (g == null) return;
    final h = headingFromSensors(g, m);
    if (h == null) return;
    setState(() => _heading = _filter.add(h));
  }

  @override
  void dispose() {
    _acc?.cancel();
    _mag?.cancel();
    _timeout?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = context.services;
    final pv = PrayerView.compute(s);
    final qibla = pv.qibla;
    final m = mode;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.qiblaTitle)),
      body: ListView(
        padding: const EdgeInsets.all(DesignTokens.spaceLg),
        children: [
          Text(pv.city.name(context.isArabic), style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          Text(
            l.prayerQiblaDeg(context.num(qibla.toStringAsFixed(1))),
            key: const Key('qiblaBearing'),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spaceLg),
          if (m == CompassMode.live) ...[
            Center(
              child: _LiveDial(key: const Key('qiblaMode-live'), qibla: qibla, heading: _heading!),
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(
              _direction(context, qibla, _heading!),
              key: const Key('qiblaTurn'),
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            Text(
              l.qiblaHeading(context.num(_heading!.round())),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Text(l.qiblaLiveNote, style: theme.textTheme.bodySmall),
          ] else ...[
            Center(
              child: m == CompassMode.waiting
                  ? Column(
                      key: const Key('qiblaMode-waiting'),
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: DesignTokens.spaceSm),
                        Text(l.qiblaWaiting),
                      ],
                    )
                  : Column(
                      key: const Key('qiblaMode-static'),
                      children: [
                        QiblaCompass(bearing: qibla, size: 220),
                        const SizedBox(height: DesignTokens.spaceMd),
                        Text(l.qiblaStatic, textAlign: TextAlign.center),
                      ],
                    ),
            ),
          ],
        ],
      ),
    );
  }

  static String _direction(BuildContext context, double qibla, double heading) {
    final l = context.l10n;
    if (facesQibla(qibla, heading)) return l.qiblaFacing;
    final t = turnAngle(qibla, heading);
    final deg = context.num(t.abs().round());
    return t > 0 ? l.qiblaTurnRight(deg) : l.qiblaTurnLeft(deg);
  }
}

/// Compass card rotated so that north follows the earth; the gold needle
/// points to the qibla relative to where the phone's top is pointing.
class _LiveDial extends StatelessWidget {
  const _LiveDial({super.key, required this.qibla, required this.heading});
  final double qibla;
  final double heading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final facing = facesQibla(qibla, heading);
    return Semantics(
      label: context.l10n.prayerCompassLabel(context.num(qibla.toStringAsFixed(1))),
      image: true,
      child: SizedBox.square(
        dimension: 260,
        child: CustomPaint(
          painter: _DialPainter(
            heading: heading,
            qibla: qibla,
            ring: scheme.outline,
            text: scheme.onSurface,
            needle: facing ? scheme.primary : scheme.secondary,
            north: context.l10n.prayerNorth,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.heading,
    required this.qibla,
    required this.ring,
    required this.text,
    required this.needle,
    required this.north,
    required this.textDirection,
  });

  final double heading;
  final double qibla;
  final Color ring;
  final Color text;
  final Color needle;
  final String north;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 6;
    final rot = -heading * math.pi / 180;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ring,
    );
    for (var i = 0; i < 360; i += 15) {
      final a = rot + i * math.pi / 180;
      final len = i % 90 == 0 ? 16.0 : (i % 45 == 0 ? 11.0 : 6.0);
      canvas.drawLine(
        c + Offset(math.sin(a), -math.cos(a)) * (r - len),
        c + Offset(math.sin(a), -math.cos(a)) * r,
        Paint()
          ..strokeWidth = i % 90 == 0 ? 3 : 1.5
          ..color = ring,
      );
    }
    final tp = TextPainter(
      text: TextSpan(
        text: north,
        style: TextStyle(color: text, fontSize: 16, fontWeight: FontWeight.w700),
      ),
      textDirection: textDirection,
    )..layout();
    final np = c + Offset(math.sin(rot), -math.cos(rot)) * (r - 30);
    tp.paint(canvas, np - Offset(tp.width / 2, tp.height / 2));
    // Fixed marker for the top of the phone.
    canvas.drawLine(
      c + Offset(0, -r - 4),
      c + Offset(0, -r + 10),
      Paint()
        ..color = text
        ..strokeWidth = 3,
    );
    // Qibla needle.
    final qa = (qibla - heading) * math.pi / 180;
    final dir = Offset(math.sin(qa), -math.cos(qa));
    final tip = c + dir * (r - 22);
    final p = Paint()
      ..color = needle
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, tip, p);
    canvas.drawCircle(tip, 11, Paint()..color = needle);
    canvas.drawRect(Rect.fromCenter(center: tip, width: 9, height: 9), Paint()..color = const Color(0xFF111111));
    canvas.drawCircle(c, 7, Paint()..color = needle);
  }

  @override
  bool shouldRepaint(_DialPainter old) => old.heading != heading || old.qibla != qibla || old.needle != needle;
}
