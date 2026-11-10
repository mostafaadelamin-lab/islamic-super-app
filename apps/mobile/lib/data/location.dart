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

/// The device position. Coarse accuracy is enough for prayer times; nearby
/// mosques ask for a [precise] fix.
abstract class LocationProvider {
  Future<LocationResult> current({bool precise = false});
}

class GeolocatorLocation implements LocationProvider {
  const GeolocatorLocation();

  @override
  Future<LocationResult> current({bool precise = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return const LocationUnavailable();
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return const LocationDenied();
      }
      try {
        final p = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: precise ? LocationAccuracy.high : LocationAccuracy.low,
            timeLimit: const Duration(seconds: 20),
          ),
        );
        return LocationFound(p.latitude, p.longitude);
      } catch (_) {
        // No fresh fix in time (indoors, GPS warming up): the last known one is
        // still far better than the city centre.
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) return LocationFound(last.latitude, last.longitude);
        return const LocationUnavailable();
      }
    } catch (_) {
      return const LocationUnavailable();
    }
  }
}
