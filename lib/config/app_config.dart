/// Application configuration.
///
/// The backend is currently running on the development PC.
/// The physical phone and the backend PC must be connected
/// to the same Wi-Fi/network.
///
/// Backend:
///   http://192.168.1.2:3000
///
/// You can override this at build time with:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.2:3000
class AppConfig {
  /// Optional build-time API URL override.
  ///
  /// Example:
  /// flutter run --dart-define=API_BASE_URL=http://192.168.1.2:3000
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  /// Neptune backend base URL.
  static String get apiBaseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl;
    }

    return 'https://subscription-organic-quilt-roger.trycloudflare.com';
  }

  /// Access token validity on the backend.
  static const Duration tokenValidity = Duration(minutes: 15);
}