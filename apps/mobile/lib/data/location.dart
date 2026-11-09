import 'package:geolocator/geolocator.dart';

/// Result of asking the device for its position.
sealed class LocationResult {
  const LocationResult();
}

class LocationFound extends LocationResult {
  const LocationFound(this.lat, this.lng);
  final double lat;
  final double lng;
}

class LocationDenied extends LocationResult {
  const LocationDenied();
}

class LocationUnavailable extends LocationResult {
  const LocationUnavailable();
}

/// The device position for "use my location" (coarse accuracy is enough for prayer times).
abstract class LocationProvider {
  Future<LocationResult> current();
}

class GeolocatorLocation implements LocationProvider {
  const GeolocatorLocation();

  @override
  Future<LocationResult> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return const LocationUnavailable();
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return const LocationDenied();
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 20)),
      );
      return LocationFound(p.latitude, p.longitude);
    } catch (_) {
      return const LocationUnavailable();
    }
  }
}
