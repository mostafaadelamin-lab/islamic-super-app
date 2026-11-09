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
  Stream<Vec3> get accelerometer;
  Stream<Vec3> get magnetometer;
}

class DeviceCompassSensors implements CompassSensors {
  const DeviceCompassSensors();

  /// Native side: MainActivity.kt (Android) and AppDelegate.swift (iOS).
  static const channel = EventChannel('org.rattil.app/heading');

  @override
  Stream<double>? get systemHeading => channel.receiveBroadcastStream().map((e) => (e as num).toDouble());

  @override
  Stream<Vec3> get accelerometer =>
      accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).map((e) => Vec3(e.x, e.y, e.z));

  @override
  Stream<Vec3> get magnetometer =>
      magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).map((e) => Vec3(e.x, e.y, e.z));
}
