import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../app_services.dart';
import '../data/location.dart';
import '../data/sensors.dart';
import '../domain/declination.dart';
import '../domain/mosques.dart' show distanceM;
import '../domain/qibla.dart';
import '../theme/design_tokens.dart';
import 'l10n_ext.dart';
import 'locate.dart';
import 'prayer_model.dart';
import 'adaptive.dart';
import 'prayer_screen.dart' show QiblaCompass;
import 'r_icon.dart';

/// Live qibla compass. Uses the phone's own compass heading (iOS
/// CLLocationManager / Android rotation-vector sensor) and falls back to the
/// raw accelerometer + magnetometer (sensors_plus); the static north-up diagram
/// is shown when there is no usable sensor. Headings are from magnetic north,
/// so the local magnetic declination (WMM2025) is added to get true north,
/// which is what the qibla bearing is measured from.
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
  StreamSubscription<double>? _sys;
  StreamSubscription<CompassQuality>? _quality;

  /// The platform says the magnetometer is uncalibrated, or its error is large.
  bool needsCalibration = false;
  double? accuracyDeg;
  bool _started = false;

  /// Degrees east of true north of magnetic north at the selected city.
  double? declination;
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
    if (_started) return;
    _started = true;
    final services = context.services;
    final city = PrayerView.compute(services).city;
    declination = services.content.magneticModel?.declination(city.lat, city.lng, decimalYear(DateTime.now()));
    final sys = services.sensors.systemHeading;
    if (sys != null) {
      try {
        _sys = sys.listen(_onHeading, onError: (Object _) => _startRawSensors(), cancelOnError: true);
        _quality = services.sensors.quality?.listen(_onQuality, onError: (Object _) {});
      } catch (_) {
        _startRawSensors();
      }
    } else {
      _startRawSensors();
    }
    _timeout = Timer(QiblaScreen.timeout, () {
      if (mounted) setState(() => _timedOut = true);
    });
  }

  void _onQuality(CompassQuality q) {
    if (!mounted) return;
    setState(() {
      if (q.calibration != null) needsCalibration = q.calibration! <= 1;
      if (q.accuracyDeg != null) {
        accuracyDeg = q.accuracyDeg;
        if (q.accuracyDeg! > 25) needsCalibration = true;
        if (q.accuracyDeg! <= 10 && q.calibration == null) needsCalibration = false;
      }
    });
  }

  /// Raw accelerometer + magnetometer, used when the platform compass is missing.
  void _startRawSensors() {
    _sys?.cancel();
    _sys = null;
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
  }

  bool _locating = false;

  /// Re-reads the phone's position so the qibla bearing is for where the user is now.
  Future<void> _relocate() async {
    final s = context.services;
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l10n;
    setState(() => _locating = true);
    try {
      final r = await locateAndSave(s, keepMethod: true);
      if (r is! LocationFound) throw StateError('no fix');
      final city = PrayerView.compute(s).city;
      declination = s.content.magneticModel?.declination(city.lat, city.lng, decimalYear(DateTime.now()));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.qiblaLocateFailed)));
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _onMagnetic(Vec3 m) {
    final g = _gravity;
    if (g == null) return;
    final h = headingFromSensors(g, m);
    if (h == null) return;
    _onHeading(h);
  }

  /// [magnetic]: degrees from magnetic north; stored as degrees from true north.
  void _onHeading(double magnetic) {
    if (!mounted || magnetic.isNaN) return;
    final qibla = PrayerView.compute(context.services).qibla;
    final was = _heading != null && facesQibla(qibla, _heading!);
    setState(() => _heading = _filter.add(normalizeDegrees(magnetic + (declination ?? 0))));
    // A light tap in the hand when the phone comes round to the qibla.
    if (!was && facesQibla(qibla, _heading!)) HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _acc?.cancel();
    _mag?.cancel();
    _sys?.cancel();
    _quality?.cancel();
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
    final live = m == CompassMode.live;
    final facing = live && facesQibla(qibla, _heading!);
    final km = distanceM(pv.city.lat, pv.city.lng, kaabaLat, kaabaLng) / 1000;
    final dial = switch (m) {
      CompassMode.live => QiblaDial(key: const Key('qiblaMode-live'), qibla: qibla, heading: _heading!, live: true),
      CompassMode.waiting => const SizedBox.square(
        key: Key('qiblaMode-waiting'),
        dimension: 280,
        child: Center(child: CircularProgressIndicator(color: QiblaColors.gold)),
      ),
      _ => KeyedSubtree(
        key: const Key('qiblaMode-static'),
        child: QiblaCompass(bearing: qibla, size: 280),
      ),
    };
    final status = switch (m) {
      CompassMode.live => _direction(context, qibla, _heading!),
      CompassMode.waiting => l.qiblaWaiting,
      _ => l.qiblaStatic,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.qiblaTitle)),
      body: ReadableWidth(
        child: ListView(
          padding: const EdgeInsets.all(DesignTokens.spaceLg),
          children: [
            // The hero card keeps the Mushaf brown and gold in light and dark mode.
            Container(
              padding: const EdgeInsets.fromLTRB(
                DesignTokens.spaceLg,
                DesignTokens.spaceLg,
                DesignTokens.spaceLg,
                DesignTokens.spaceXl,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [QiblaColors.brand, QiblaColors.brandDeep],
                ),
                boxShadow: [
                  BoxShadow(
                    color: QiblaColors.brandDeep.withValues(alpha: 0.22),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const RIcon(RIcons.location, color: QiblaColors.goldSoft, size: 20),
                      const SizedBox(width: DesignTokens.spaceXs),
                      Expanded(
                        child: Text(
                          pv.city.name(context.isArabic),
                          style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spaceMd, vertical: 6),
                        decoration: BoxDecoration(
                          color: QiblaColors.gold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                          border: Border.all(color: QiblaColors.gold.withValues(alpha: 0.6)),
                        ),
                        child: Text(
                          context.numLtr('${qibla.toStringAsFixed(0)}°'),
                          style: theme.textTheme.labelLarge?.copyWith(color: QiblaColors.goldSoft),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: DesignTokens.spaceLg),
                  Center(child: dial),
                  const SizedBox(height: DesignTokens.spaceLg),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spaceLg,
                      vertical: DesignTokens.spaceMd,
                    ),
                    decoration: BoxDecoration(
                      color: facing ? QiblaColors.gold : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusPill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (facing) ...[
                          const RIcon(RIcons.checkCircle, color: QiblaColors.brandDeep, size: 22),
                          const SizedBox(width: DesignTokens.spaceSm),
                        ],
                        Flexible(
                          child: Text(
                            status,
                            key: live ? const Key('qiblaTurn') : null,
                            textAlign: TextAlign.center,
                            style: (live ? theme.textTheme.titleMedium : theme.textTheme.bodyMedium)?.copyWith(
                              color: facing ? QiblaColors.brandDeep : Colors.white,
                              fontWeight: live ? FontWeight.w700 : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: DesignTokens.spaceLg),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: RIcons.compass,
                    label: l.qiblaDirection,
                    value: l.prayerQiblaDeg(context.num(qibla.toStringAsFixed(1))),
                    valueKey: const Key('qiblaBearing'),
                  ),
                ),
                const SizedBox(width: DesignTokens.spaceMd),
                Expanded(
                  child: _InfoTile(
                    icon: RIcons.kaaba,
                    label: l.qiblaDistance,
                    value: l.mosquesKm(context.num(km.round())),
                    valueKey: const Key('qiblaDistance'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DesignTokens.spaceMd),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                key: const Key('qiblaPlace'),
                leading: RIcon(RIcons.location, color: theme.colorScheme.primary),
                title: Text(placeLabel(s, pv.city, arabic: context.isArabic)),
                subtitle: Text(l.qiblaPlaceNote),
                trailing: _locating
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        key: const Key('qiblaRelocate'),
                        tooltip: l.prayerUseLocation,
                        icon: const RIcon(RIcons.myLocation),
                        onPressed: _relocate,
                      ),
              ),
            ),
            if (live && needsCalibration) ...[
              const SizedBox(height: DesignTokens.spaceMd),
              Card(
                key: const Key('qiblaCalibrate'),
                margin: EdgeInsets.zero,
                color: theme.colorScheme.errorContainer,
                child: ListTile(
                  leading: RIcon(RIcons.refresh, color: theme.colorScheme.onErrorContainer),
                  title: Text(
                    l.qiblaCalibrateTitle,
                    style: TextStyle(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(l.qiblaCalibrateBody, style: TextStyle(color: theme.colorScheme.onErrorContainer)),
                ),
              ),
            ],
            const SizedBox(height: DesignTokens.spaceSm),
            OutlinedButton.icon(
              key: const Key('qiblaMapCheck'),
              icon: const RIcon(RIcons.external),
              label: Text(l.qiblaMapCheck),
              onPressed: () =>
                  launchUrl(Uri.parse('https://qiblafinder.withgoogle.com/'), mode: LaunchMode.externalApplication),
            ),
            if (live) ...[
              const SizedBox(height: DesignTokens.spaceMd),
              Text(
                l.qiblaHeading(context.num(_heading!.round())),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              if (accuracyDeg != null)
                Text(
                  l.qiblaAccuracy(context.num(accuracyDeg!.round())),
                  key: const Key('qiblaAccuracy'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              if (declination != null)
                Text(
                  l.qiblaDeclination(context.num('${declination! >= 0 ? '+' : ''}${declination!.toStringAsFixed(1)}')),
                  key: const Key('qiblaDeclination'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: DesignTokens.spaceMd),
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.spaceLg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          RIcon(RIcons.bulb, size: 20, color: theme.colorScheme.secondary),
                          const SizedBox(width: DesignTokens.spaceSm),
                          Text(l.qiblaTipsTitle, style: theme.textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: DesignTokens.spaceSm),
                      Text(l.qiblaLiveNote, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
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

/// The Kaaba, Makkah (for the distance shown under the dial).
const kaabaLat = 21.4225;
const kaabaLng = 39.8262;

/// Rattil brand colours for the qibla card (same in light and dark mode).
abstract final class QiblaColors {
  static const brand = Color(0xFF8A5A2B);
  static const brandDeep = Color(0xFF4A2E14);
  static const gold = Color(0xFFD4AF5A);
  static const goldSoft = Color(0xFFF1DFAE);
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value, required this.valueKey});
  final RIconData icon;
  final String label;
  final String value;
  final Key valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(DesignTokens.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RIcon(icon, size: 22, color: theme.colorScheme.secondary),
            const SizedBox(height: DesignTokens.spaceSm),
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 2),
            Text(
              value,
              key: valueKey,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Emerald-and-gold compass. The card turns with the earth (north follows
/// [heading]); the gold line and the Kaaba mark show the qibla; the gold
/// triangle at the top is where the phone points. With [live] false the card
/// is drawn north-up (no compass reading).
class QiblaDial extends StatelessWidget {
  const QiblaDial({super.key, required this.qibla, required this.heading, required this.live, this.size = 280});
  final double qibla;
  final double heading;
  final bool live;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final facing = live && facesQibla(qibla, heading);
    return Semantics(
      label: l.prayerCompassLabel(context.num(qibla.toStringAsFixed(1))),
      image: true,
      container: true,
      child: ExcludeSemantics(
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: QiblaDialPainter(
              heading: heading,
              qibla: qibla,
              facing: facing,
              showPointer: live,
              labels: [l.prayerNorth, l.qiblaEast, l.qiblaSouth, l.qiblaWest],
              textDirection: Directionality.of(context),
            ),
          ),
        ),
      ),
    );
  }
}

class QiblaDialPainter extends CustomPainter {
  QiblaDialPainter({
    required this.heading,
    required this.qibla,
    required this.facing,
    required this.showPointer,
    required this.labels,
    required this.textDirection,
  });

  final double heading;
  final double qibla;
  final bool facing;
  final bool showPointer;

  /// N, E, S, W in the app language.
  final List<String> labels;
  final TextDirection textDirection;

  static Offset _at(Offset c, double deg, double radius) {
    final a = deg * math.pi / 180;
    return c + Offset(math.sin(a), -math.cos(a)) * radius;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const gold = QiblaColors.gold;
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 16;

    // Glow when the phone faces the qibla.
    if (facing) {
      canvas.drawCircle(
        c,
        r + 4,
        Paint()
          ..color = gold.withValues(alpha: 0.55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    // Face.
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF9A6A36), Color(0xFF6B4420), Color(0xFF3F2711)],
          stops: [0, 0.7, 1],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = gold,
    );
    canvas.drawCircle(
      c,
      r - 30,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = gold.withValues(alpha: 0.35),
    );

    // Ticks every 5°, turning with the earth.
    for (var i = 0; i < 360; i += 5) {
      final deg = i - heading;
      final major = i % 30 == 0;
      final len = i % 90 == 0 ? 14.0 : (major ? 10.0 : 5.0);
      canvas.drawLine(
        _at(c, deg, r - 4 - len),
        _at(c, deg, r - 4),
        Paint()
          ..strokeWidth = major ? 2 : 1
          ..strokeCap = StrokeCap.round
          ..color = (major ? gold : Colors.white).withValues(alpha: major ? 0.95 : 0.4),
      );
    }

    // N E S W.
    for (var k = 0; k < 4; k++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[k],
          style: TextStyle(
            fontFamily: DesignTokens.fontUi,
            color: k == 0 ? gold : Colors.white.withValues(alpha: 0.85),
            fontSize: k == 0 ? 18 : 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: textDirection,
      )..layout();
      tp.paint(canvas, _at(c, k * 90 - heading, r - 44) - Offset(tp.width / 2, tp.height / 2));
    }

    // Eight-pointed star in the middle (two squares), turning with the card.
    final star = r * 0.3;
    for (final base in [0.0, 45.0]) {
      final path = Path();
      for (var k = 0; k < 4; k++) {
        final p = _at(c, base + k * 90 - heading, star);
        k == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = gold.withValues(alpha: 0.4),
      );
    }

    // Qibla line and the Kaaba mark on the ring.
    final qa = qibla - heading;
    final tip = _at(c, qa, r - 30);
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..shader = LinearGradient(colors: [gold.withValues(alpha: 0.15), gold]).createShader(Rect.fromPoints(c, tip))
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    final kaaba = _at(c, qa, r - 14);
    canvas.save();
    canvas.translate(kaaba.dx, kaaba.dy);
    canvas.rotate(qa * math.pi / 180);
    final body = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: 22, height: 22),
      const Radius.circular(3),
    );
    canvas.drawRRect(body.shift(const Offset(0, 1.5)), Paint()..color = Colors.black.withValues(alpha: 0.35));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF151515));
    canvas.drawRect(const Rect.fromLTWH(-11, -5, 22, 4), Paint()..color = gold);
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = gold,
    );
    canvas.restore();

    // Hub.
    canvas.drawCircle(c, 8, Paint()..color = gold);
    canvas.drawCircle(c, 3.5, Paint()..color = QiblaColors.brandDeep);

    // Where the top of the phone points.
    if (showPointer) {
      final top = c.dy - r - 14;
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, top + 14)
          ..lineTo(c.dx - 9, top)
          ..lineTo(c.dx + 9, top)
          ..close(),
        Paint()..color = facing ? gold : Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(QiblaDialPainter old) =>
      old.heading != heading || old.qibla != qibla || old.facing != facing || old.showPointer != showPointer;
}
