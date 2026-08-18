import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Hands off to the device's native maps app for real turn-by-turn
/// navigation to a coordinate. Prefers Google Maps, falls back to the
/// platform's safe default, and reports failure instead of failing
/// silently.
///
/// Returns `null` on success or a user-facing error message on failure.
class MapsLauncher {
  /// Opens turn-by-turn directions to [latitude]/[longitude] in the
  /// device's native maps app (or a new browser tab on web).
  static Future<String?> openDirections({
    required double latitude,
    required double longitude,
  }) async {
    final destination = '$latitude,$longitude';

    if (kIsWeb) {
      // Browsers have no custom URI schemes (geo:, google.navigation:,
      // comgooglemaps://). Open the universal Google Maps directions page
      // in a new tab.
      final webUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$destination',
      );
      final launched = await launchUrl(webUrl, webOnlyWindowName: '_blank');
      if (!launched) {
        return 'Could not open Google Maps in a new tab. Please try again.';
      }
      return null;
    }

    Uri? uri;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Force Google Maps turn-by-turn navigation when installed.
        final navigation = Uri.parse('google.navigation:q=$destination&mode=d');
        if (await canLaunchUrl(navigation)) {
          uri = navigation;
        } else {
          // No Google Maps: let the OS pick the default maps app.
          final geo = Uri.parse('geo:0,0?q=$destination');
          if (!await canLaunchUrl(geo)) {
            return 'No maps application is available for navigation.';
          }
          uri = geo;
        }
      case TargetPlatform.iOS:
        // Google Maps deep link only when that app is installed...
        final googleMaps = Uri.parse(
          'comgooglemaps://?daddr=$destination&directionsmode=driving',
        );
        if (await canLaunchUrl(googleMaps)) {
          uri = googleMaps;
        } else {
          // ...otherwise Apple Maps is the universal fallback.
          uri = Uri.parse('http://maps.apple.com/?daddr=$destination&dirflg=d');
        }
      default:
        // Desktop / anything else: browser directions page.
        uri = Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$destination',
        );
    }

    if (!await canLaunchUrl(uri)) {
      return 'No maps application is available on this device.';
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      return 'Could not open the maps app. Please try again.';
    }
    return null;
  }
}
