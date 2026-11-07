import 'package:sensors_plus/sensors_plus.dart';

import '../domain/qibla.dart';

/// Accelerometer + magnetometer streams for the live qibla compass. The app
/// uses sensors_plus; tests pass fixed streams.
abstract class CompassSensors {
  Stream<Vec3> get accelerometer;
  Stream<Vec3> get magnetometer;
}

class DeviceCompassSensors implements CompassSensors {
  const DeviceCompassSensors();

  @override
  Stream<Vec3> get accelerometer =>
      accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).map((e) => Vec3(e.x, e.y, e.z));

  @override
  Stream<Vec3> get magnetometer =>
      magnetometerEventStream(samplingPeriod: SensorInterval.uiInterval).map((e) => Vec3(e.x, e.y, e.z));
}
