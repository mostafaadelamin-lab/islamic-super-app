import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../domain/qibla.dart';

/// Compass sources for the live qibla compass. The preferred one is the
/// operating system's own heading (iOS CLLocationManager, Android rotation-
/// vector sensor), which is calibrated and fused with the gyroscope; the raw
/// accelerometer + magnetometer pair (sensors_plus) is the fallback. All of
/// them report degrees from MAGNETIC north; the screen adds the declination.
/// Tests pass fixed streams.
abstract class CompassSensors {
  /// Heading from the platform compass, or null when there is none.
  Stream<double>? get systemHeading;

  /// How trustworthy the platform compass is right now, or null when unknown.
  Stream<CompassQuality>? get quality => null;
  Stream<Vec3> get accelerometer;
  Stream<Vec3> get magnetometer;
}

class DeviceCompassSensors implements CompassSensors {
  const DeviceCompassSensors();

  /// Native side: MainActivity.kt (Android) and AppDelegate.swift (iOS).
  static const channel = EventChannel('org.rattil.app/heading');

  /// One platform subscription shared by the heading and its quality.
  static final Stream<dynamic> _events = channel.receiveBroadcastStream();

  @override
  Stream<double>? get systemHeading => _events.where((e) => e is num).map((e) => (e as num).toDouble());

  @override
  Stream<CompassQuality>? get quality =>
      _events.where((e) => e is Map).map((e) => CompassQuality.fromPlatform(e as Map<dynamic, dynamic>));

  @override
  Stream<Vec3> get accelerometer =>
      accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).map((e) => Vec3(e.x, e.y, e.z));

  @override
  Stream<Vec3> get magnetometer =>
      magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).map((e) => Vec3(e.x, e.y, e.z));
}

/// A platform report on the compass: [calibration] is Android's sensor status
/// (0 unreliable, 1 low, 2 medium, 3 high); [accuracyDeg] the estimated error.
class CompassQuality {
  const CompassQuality({this.calibration, this.accuracyDeg});
  final int? calibration;
  final double? accuracyDeg;

  factory CompassQuality.fromPlatform(Map<dynamic, dynamic> e) =>
      CompassQuality(calibration: (e['cal'] as num?)?.toInt(), accuracyDeg: (e['acc'] as num?)?.toDouble());
}
