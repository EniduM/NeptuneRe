import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/api_models.dart';
import '../../services/live_location_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/recycling_pin.dart';

/// Collector: full-screen live view of the Rider approaching the pick-up
/// point, once the request is ACCEPTED. The Rider's marker glides between
/// consecutive live-location updates (Firebase Realtime Database) instead
/// of snapping, and the camera fits both markers on the first update only
/// (no fighting the user's manual pan/zoom afterwards).
class CollectorRiderTrackScreen extends StatefulWidget {
  final CollectionRequest request;

  const CollectorRiderTrackScreen({super.key, required this.request});

  @override
  State<CollectorRiderTrackScreen> createState() =>
      _CollectorRiderTrackScreenState();
}

class _CollectorRiderTrackScreenState extends State<CollectorRiderTrackScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _glide;
  StreamSubscription<LiveLocationPoint?>? _subscription;

  LatLng? _from;
  LatLng? _to;
  LatLng? _marker;
  LiveLocationPoint? _latest;
  double _bearing = 0;
  bool _waiting = true;
  bool _paused = false;
  bool _mapReady = false;
  double _distanceKm = 0;

  LatLng get _pickup =>
      LatLng(widget.request.latitude, widget.request.longitude);

  @override
  void initState() {
    super.initState();
    _glide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(_tick);
    _subscription = LiveLocationService.instance
        .liveLocationStream(widget.request.id)
        .listen(
          _onUpdate,
          onError: (_) {
            if (mounted) setState(() => _paused = true);
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _glide.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _tick() {
    if (_from == null || _to == null || !mounted) return;
    final t = Curves.easeInOut.transform(_glide.value);
    setState(() {
      _marker = LatLng(
        _from!.latitude + (_to!.latitude - _from!.latitude) * t,
        _from!.longitude + (_to!.longitude - _from!.longitude) * t,
      );
    });
  }

  double _bearingBetween(LatLng a, LatLng b) {
    final dy = (b.latitude - a.latitude) * 111320;
    final dx =
        (b.longitude - a.longitude) *
        111320 *
        math.cos(a.latitude * math.pi / 180);
    return (math.atan2(dx, dy) * 180 / math.pi + 360) % 360;
  }

  void _fitBothMarkers() {
    final rider = _marker;
    if (rider == null || !_mapReady) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_mapReady) return;
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_pickup, rider]),
          padding: const EdgeInsets.all(70),
          maxZoom: 17,
        ),
      );
    });
  }

  void _onUpdate(LiveLocationPoint? point) {
    if (!mounted) return;
    if (point == null) {
      // Node removed (request left ACCEPTED) — freeze the last known marker.
      if (_waiting) return;
      setState(() => _paused = true);
      return;
    }

    final target = LatLng(point.lat, point.lng);
    if (_waiting) {
      setState(() {
        _waiting = false;
        _marker = target;
        _from = target;
        _to = target;
        _distanceKm =
            Geolocator.distanceBetween(
              point.lat,
              point.lng,
              widget.request.latitude,
              widget.request.longitude,
            ) /
            1000;
      });
      return _fitBothMarkers(); // Auto-fit on the FIRST update only.
    }

    final previous = _latest;
    if (previous != null) {
      _bearing = _bearingBetween(LatLng(previous.lat, previous.lng), target);
    }
    setState(() {
      _paused = false;
      _from = _marker ?? target;
      _to = target;
      _latest = point;
      _distanceKm =
          Geolocator.distanceBetween(
            point.lat,
            point.lng,
            widget.request.latitude,
            widget.request.longitude,
          ) /
          1000;
    });
    _glide.forward(from: 0);
  }

  Future<void> _callRider(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rider = widget.request.rider;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Track Rider'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              onMapReady: () => _mapReady = true,
              initialCenter: _pickup,
              initialZoom: 14,
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
                  _collectorPin(_pickup),
                  if (!_waiting && _marker != null) _riderMarker(_marker!),
                ],
              ),
            ],
          ),
          if (_waiting) const _WaitingOverlay(),
          _buildBottomSheet(rider),
        ],
      ),
    );
  }

  // --- Markers ------------------------------------------------------------

  Marker _collectorPin(LatLng point) {
    return Marker(
      point: point,
      width: 48,
      height: 48,
      child: const RecyclingPin(),
    );
  }

  Marker _riderMarker(LatLng point) {
    return Marker(
      point: point,
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _PulseRing(),
          Transform.rotate(
            angle: _bearing * math.pi / 180,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.pureWhite, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.darkBlack.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: AppTheme.pureWhite,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Bottom sheet -------------------------------------------------------

  Widget _buildBottomSheet(RiderDetails? rider) {
    final name = rider?.fullName.trim().isNotEmpty == true
        ? rider!.fullName
        : widget.request.riderId ?? 'Rider';
    final mobile = rider?.mobile ?? '';
    return DraggableScrollableSheet(
      initialChildSize: 0.30,
      minChildSize: 0.22,
      maxChildSize: 0.62,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.darkBlack.withValues(alpha: 0.10),
                blurRadius: 18,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.textMuted.withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Rider on the way',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.darkBlack,
                        ),
                      ),
                    ),
                    if (_paused)
                      Text(
                        'paused',
                        style: GoogleFonts.outfit(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: AppTheme.mintGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              name.characters.first.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkBlack,
                                ),
                              ),
                              if (mobile.isNotEmpty)
                                Text(
                                  mobile,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (mobile.isNotEmpty)
                          IconButton.filled(
                            tooltip: 'Call Rider',
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: AppTheme.pureWhite,
                            ),
                            onPressed: () => _callRider(mobile),
                            icon: const Icon(Icons.call_rounded, size: 20),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Flexible(
                          fit: FlexFit.loose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.mintGreen,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _distanceKm < 1
                                      ? '${(_distanceKm * 1000).round()} m'
                                      : '${_distanceKm.toStringAsFixed(1)} km',
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.primaryGreen,
                                  ),
                                ),
                                Text(
                                  'Approximate distance away',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10.5,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: mobile.isNotEmpty
                                ? () => _callRider(mobile)
                                : null,
                            icon: const Icon(Icons.call_rounded, size: 18),
                            label: Text(
                              'Call Rider',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Centered "live" indicator under the Rider marker: an expanding, fading
/// ring looped on a slow cycle — subtle, not flashy.
class _PulseRing extends StatefulWidget {
  const _PulseRing();

  @override
  State<_PulseRing> createState() => _PulseRingState();
}

class _PulseRingState extends State<_PulseRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _radius;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _radius = Tween<double>(
      begin: 24,
      end: 36,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacity = Tween<double>(
      begin: 0.28,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: _radius.value * 2,
          height: _radius.value * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.lightGreen.withValues(alpha: _opacity.value),
          ),
        );
      },
    );
  }
}

/// Clean pre-data state: never a blank map.
class _WaitingOverlay extends StatelessWidget {
  const _WaitingOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 40),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: AppTheme.darkBlack.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Waiting for rider's location…",
              style: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlack,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Live tracking starts once the rider begins their trip.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 11.5,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
