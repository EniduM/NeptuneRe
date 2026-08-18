import 'package:geolocator/geolocator.dart';

/// Wraps geolocator with friendly error messages.
class LocationService {
  /// Requests location permission and returns the current position.
  /// Throws [LocationException] with a user-friendly message.
  static Future<Position> getCurrentPosition() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Location services are turned off. Please enable them in device settings.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException(
        'Location permission was denied. Grant location access to continue.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is permanently denied. Enable it in device settings.',
      );
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );
  }

  /// Position to map coordinates (lat, lng).
  static (double, double) toLatLng(Position position) =>
      (position.latitude, position.longitude);
}

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);

  @override
  String toString() => message;
}
