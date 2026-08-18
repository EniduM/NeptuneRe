import 'package:flutter/foundation.dart' show kIsWeb;

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
  static const String _definedBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Neptune backend base URL.
  ///
  /// Defaults to the deployed backend. When developing against a local
  /// NestJS server, pass --dart-define=API_BASE_URL=... explicitly:
  ///   - Android emulator:  --dart-define=API_BASE_URL=http://10.0.2.2:3000
  ///   - iOS simulator:     --dart-define=API_BASE_URL=http://localhost:3000
  ///   - Physical device:   --dart-define=API_BASE_URL=http://`<LAN-IP>`:3000
  /// (An emulator's localhost is the emulator itself; 10.0.2.2 maps to the
  /// host machine.)
  ///
  /// On the web the app calls the SAME-ORIGIN `/api` prefix, which Vercel
  /// rewrites (web/vercel.json) to the backend. Same-origin means browsers
  /// never run CORS checks against the backend, so the PWA works regardless
  /// of the backend's CORS allowlist.
  static String get apiBaseUrl {
    if (_definedBaseUrl.isNotEmpty) {
      return _definedBaseUrl;
    }

    if (kIsWeb) {
      return 'https://web-two-ebon-72.vercel.app/api';
    }

    return 'https://neptune-backend-kappa.vercel.app';
  }

  /// Access token validity on the backend.
  static const Duration tokenValidity = Duration(minutes: 15);
}
