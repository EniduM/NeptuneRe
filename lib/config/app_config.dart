/// Application configuration.
///
/// The backend base URL is resolved at build time via:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
///
/// When no override is provided, the temporary Cloudflare tunnel to the
/// Neptune backend is used:
/// - https://chef-dried-lawyers-committees.trycloudflare.com
///   (temporary — ask the backend owner for a new link when it expires)
class AppConfig {
  static const String _definedBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get apiBaseUrl {
    if (_definedBaseUrl.isNotEmpty) return _definedBaseUrl;
    return 'https://chef-dried-lawyers-committees.trycloudflare.com';
  }

  /// Access token TTL is 15 minutes server-side; refresh the session by
  /// logging in again when a 401 is received.
  static const Duration tokenValidity = Duration(minutes: 15);
}
