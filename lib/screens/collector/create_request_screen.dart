import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/hexagon_clipper.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/recycling_pin.dart';

/// Collector creates a collection request using the current GPS location.
///
/// The map below is centered on the device's REAL GPS position (fetched on
/// open). Only if GPS is genuinely unavailable does it fall back to a
/// Colombo, Sri Lanka default with a visible "location unavailable" banner.
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  /// Last-resort default center when GPS permission is denied or location
  /// cannot be fetched (Colombo, Sri Lanka) — never the tutorial default.
  static const LatLng _fallbackCenter = LatLng(6.9271, 79.8612);

  final MapController _mapController = MapController();

  double? _latitude;
  double? _longitude;
  String? _locationStatus;
  bool _isLocating = false;
  bool _isSubmitting = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    // Fetch GPS on open so the map centers on the device's actual location
    // instead of a placeholder default.
    WidgetsBinding.instance.addPostFrameCallback((_) => _captureLocation());
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    setState(() {
      _isLocating = true;
      _locationStatus = null;
    });
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationStatus = 'Location captured from GPS';
      });
      // Re-capture while the map is already shown: glide the camera to the
      // fresh coordinates. First capture mounts the map on the real point.
      final point = LatLng(position.latitude, position.longitude);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_mapReady) return;
        _mapController.move(point, 15.5);
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _locationStatus = e.message;
        _latitude = null;
        _longitude = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationStatus = 'Unable to read GPS location. Please try again.';
        _latitude = null;
        _longitude = null;
      });
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _submit() async {
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Capture your GPS location first'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      // Backend contract: POST /collector/collection-requests accepts only
      // { latitude, longitude }.
      final created = await appState.api.collector.createRequest(
        latitude: _latitude!,
        longitude: _longitude!,
      );
      if (!mounted) return;
      Navigator.pop(context, created);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Collection request created — awaiting a Rider.'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = _latitude != null && _longitude != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Create Collection Request')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LiquidGlassCard(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: ClipPath(
                        clipper: HexagonClipper(),
                        child: Container(
                          color: AppTheme.pureWhite,
                          child: const Center(
                            child: Icon(
                              Icons.my_location_rounded,
                              color: AppTheme.primaryGreen,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your current GPS position will be sent with the request so a Rider can find you.',
                        style: GoogleFonts.outfit(
                          color: AppTheme.pureWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // GPS capture
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isLocating ? null : _captureLocation,
                icon: _isLocating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.pureWhite,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.gps_fixed_rounded),
                label: Text(
                  _isLocating ? 'Locating…' : 'Use My Current Location',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location preview map — never shows a hardcoded default:
            // loading while GPS is fetched, the real position once known,
            // Colombo only as a visible last-resort fallback.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.94, end: 1).animate(animation),
                  child: child,
                ),
              ),
              child: hasLocation
                  ? _buildLiveMap(LatLng(_latitude!, _longitude!))
                  : _isLocating
                  ? const _MapLoadingPlaceholder()
                  : _buildFallbackMap(),
            ),

            // GPS status text
            const SizedBox(height: 12),
            Text(
              hasLocation
                  ? '${_locationStatus ?? 'Location captured'} — '
                        '${_latitude!.toStringAsFixed(7)}, '
                        '${_longitude!.toStringAsFixed(7)}'
                  : _locationStatus ?? 'Fetching your position…',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: hasLocation ? AppTheme.primaryGreen : Colors.redAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),

            // Submit
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppTheme.pureWhite,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'Submitting…' : 'Submit Collection Request',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMap(LatLng point) {
    return SizedBox(
      key: const ValueKey('live-map'),
      height: 260,
      child: LiquidGlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onMapReady: () => _mapReady = true,
              initialCenter: point,
              initialZoom: 15.5,
              minZoom: 3,
              maxZoom: 18,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.neptune.neptune_recyclers',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 48,
                    height: 48,
                    child: const RecyclingPin(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackMap() {
    return SizedBox(
      key: const ValueKey('fallback-map'),
      height: 260,
      child: LiquidGlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  onMapReady: () => _mapReady = true,
                  initialCenter: _fallbackCenter,
                  initialZoom: 12,
                  minZoom: 3,
                  maxZoom: 18,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.neptune.neptune_recyclers',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _fallbackCenter,
                        width: 48,
                        height: 48,
                        child: const RecyclingPin(),
                      ),
                    ],
                  ),
                ],
              ),
              Positioned(
                left: 0,
                right: 0,
                top: 12,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.location_off_rounded,
                          color: AppTheme.pureWhite,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Location unavailable — showing Colombo as a '
                            'default. Enable location and retry.',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.pureWhite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapLoadingPlaceholder extends StatelessWidget {
  const _MapLoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('map-loading'),
      height: 260,
      child: LiquidGlassCard(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fetching your location…',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
