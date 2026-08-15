/// Application configuration.
///
/// The backend base URL is resolved at build time via:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
///
/// - Local device (iOS simulator / macOS): use http://localhost:3000
/// - Android emulator: use http://10.0.2.2:3000
/// - Physical device: use the machine LAN IP (e.g. http://192.168.1.10:3000)
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// Access token TTL is 15 minutes server-side; refresh the session by
  /// logging in again when a 401 is received.
  static const Duration tokenValidity = Duration(minutes: 15);
}
