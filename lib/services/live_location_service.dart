import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'location_service.dart';

/// A single live-location update written by the Rider (or observed by the
/// Collector) in `liveLocations/{collectionRequestId}`.
class LiveLocationPoint {
  final double lat;
  final double lng;
  final DateTime? updatedAt;

  const LiveLocationPoint({
    required this.lat,
    required this.lng,
    this.updatedAt,
  });
}

/// The ONLY integration point with Firebase in this app.
///
/// Uses Firebase Realtime Database exclusively for live rider tracking:
/// Riders publish their position while a request is ACCEPTED, Collectors
/// subscribe to the same path to render the rider on the map. Location
/// publishing stops the moment a request leaves the ACCEPTED state.
///
/// Hazard: authentication here is TEMPORARY Firebase Anonymous Auth so the
/// feature is functional while the Neptune backend has no location-token
/// endpoint. The planned flow (once the backend mints tokens) is:
///   POST /rider/collection-requests/:id/location-token
///   POST /collector/collection-requests/:id/location-token
/// each returning a Firebase custom token scoped to that specific request.
/// Swap [signInAnonymously] for `FirebaseAuth.instance.signInWithCustomToken`
/// without touching any UI code.
class LiveLocationService {
  LiveLocationService._();

  static final LiveLocationService instance = LiveLocationService._();

  static const String _rootPath = 'liveLocations';

  bool _firebaseReady = false;
  bool _authAttempted = false;

  String? _sharingRequestId;
  StreamSubscription<Position>? _positionSub;

  /// Human-readable banner text when location sharing cannot start or
  /// stops mid-trip (permission denied / GPS off). Null when healthy.
  final ValueNotifier<String?> sharingError = ValueNotifier<String?>(null);

  bool get isSharing => _sharingRequestId != null;

  /// Idempotent: signing back into the same request is a no-op, so the
  /// workflow screen can call this from every build without churn.
  Future<DatabaseReference> _database() async {
    if (!_firebaseReady) {
      // TEMP: replace with backend-minted custom token once available.
      try {
        final auth = FirebaseAuth.instance;
        if (auth.currentUser == null && !_authAttempted) {
          _authAttempted = true;
          await auth.signInAnonymously();
        }
      } catch (e) {
        debugPrint('LiveLocationService: anonymous auth failed: $e');
      }
      _firebaseReady = true;
    }
    return FirebaseDatabase.instance.ref(_rootPath);
  }

  Future<void> _ensurePermission() async {
    var serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Location services are turned off. Turn them on to share your live location.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw LocationException(
        'Location permission was denied. Grant location access to share your live position.',
      );
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission is permanently denied. Enable it in device settings to share your position.',
      );
    }
  }

  /// Starts writing this device's live position to
  /// `liveLocations/{requestId}` every meaningful movement
  /// (Geolocator [getPositionStream] with a 10 m distance filter — no
  /// polling timer). Safe to call repeatedly.
  Future<void> startSharing({required String requestId}) async {
    if (_sharingRequestId == requestId) return;

    final DatabaseReference ref;
    try {
      ref = await _database();
    } catch (e) {
      debugPrint('LiveLocationService: database unavailable: $e');
      sharingError.value =
          'Live tracking is unavailable right now. Please try again.';
      return;
    }

    try {
      await _ensurePermission();
    } on LocationException catch (e) {
      sharingError.value = e.message;
      return;
    }

    await stopSharing();

    _sharingRequestId = requestId;
    sharingError.value = null;

    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen(
          (position) {
            ref
                .child(requestId)
                .set({
                  'lat': position.latitude,
                  'lng': position.longitude,
                  'updatedAt': ServerValue.timestamp,
                })
                .catchError((Object e) {
                  debugPrint('LiveLocationService: write failed: $e');
                });
          },
          onError: (Object e) {
            debugPrint('LiveLocationService: position stream error: $e');
            sharingError.value =
                'Live location was interrupted. Check GPS and restart the job if needed.';
            stopSharing();
          },
        );
  }

  /// Stops writing and removes the published position so Collectors see no
  /// stale point once the request leaves the ACCEPTED state.
  Future<void> stopSharing() async {
    _positionSub?.cancel();
    _positionSub = null;
    final requestId = _sharingRequestId;
    _sharingRequestId = null;
    if (requestId != null) {
      try {
        await (await _database()).child(requestId).remove();
      } catch (e) {
        // Rules or network may prevent cleanup; the data expires by
        // request lifecycle anyway.
        debugPrint('LiveLocationService: cleanup failed: $e');
      }
    }
  }

  /// Broad: emits [LiveLocationPoint] per update and `null` when the node
  /// disappears. The subscription is cancelled automatically when the
  /// listener cancels its stream subscription.
  Stream<LiveLocationPoint?> liveLocationStream(String requestId) {
    final controller = StreamController<LiveLocationPoint?>.broadcast();
    StreamSubscription<DatabaseEvent>? sub;

    _database()
        .then((ref) {
          final streamSub = ref.child(requestId).onValue.listen((event) {
            final data = event.snapshot.value;
            if (data is! Map) {
              controller.add(null);
              return;
            }
            final lat = (data['lat'] as num?)?.toDouble();
            final lng = (data['lng'] as num?)?.toDouble();
            final ts = (data['updatedAt'] as num?)?.toInt();
            if (lat == null || lng == null) {
              controller.add(null);
              return;
            }
            controller.add(
              LiveLocationPoint(
                lat: lat,
                lng: lng,
                updatedAt: ts != null
                    ? DateTime.fromMillisecondsSinceEpoch(ts)
                    : null,
              ),
            );
          });
          streamSub.onError((Object e) => controller.addError(e));
          sub = streamSub;
        })
        .catchError((Object e) => controller.addError(e));

    controller.onCancel = () => sub?.cancel();
    return controller.stream;
  }
}
