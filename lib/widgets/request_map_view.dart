import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_theme.dart';
import 'liquid_glass.dart';
import 'recycling_pin.dart';

/// Interactive map showing a single collection location, with a button to
/// open the location in the system maps app for navigation.
class RequestMapView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? label;

  const RequestMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.label,
  });

  Future<void> _openInMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return LiquidGlassCard(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(22),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
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
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.neptune.recyclers',
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
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton.small(
                      heroTag: 'openMapsToggle',
                      backgroundColor: Colors.white.withValues(alpha: 0.85),
                      foregroundColor: AppTheme.primaryGreen,
                      onPressed: _openInMaps,
                      tooltip: 'Open in Maps',
                      child: const Icon(Icons.navigation_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.place_rounded,
                size: 16,
                color: AppTheme.primaryGreen,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label ??
                      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
                  style: GoogleFonts.outfit(
                    fontSize: 12.5,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _openInMaps,
                icon: const Icon(Icons.directions_rounded, size: 16),
                label: const Text('Navigate'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryGreen,
                  textStyle: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
