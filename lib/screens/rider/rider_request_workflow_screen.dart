import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/api_models.dart';
import '../../providers/app_state.dart';
import '../../services/live_location_service.dart';
import '../../services/maps_launcher.dart';
import '../../theme/app_theme.dart';
import '../../theme/hexagon_clipper.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_states.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/request_map_view.dart';
import '../../widgets/status_chip.dart';
import 'rider_qr_scan_screen.dart';
import 'rider_weight_entry_screen.dart';

/// Rider collection workflow hub for an ACCEPTED request.
///
/// Steps: navigate to the Collector → scan & verify the Collector's
/// permanent QR → enter total weight (kg) and complete the collection.
class RiderRequestWorkflowScreen extends StatefulWidget {
  final CollectionRequest initialRequest;

  const RiderRequestWorkflowScreen({super.key, required this.initialRequest});

  @override
  State<RiderRequestWorkflowScreen> createState() =>
      _RiderRequestWorkflowScreenState();
}

class _RiderRequestWorkflowScreenState
    extends State<RiderRequestWorkflowScreen> {
  int _reloadTick = 0;
  bool _qrVerified = false;
  RequestStatus? _lastSeenStatus;
  Timer? _statusPoller;

  Future<CollectionRequest> _load() =>
      context.read<AppState>().api.rider.getRequest(widget.initialRequest.id);

  @override
  void initState() {
    super.initState();
    // Watch for the request leaving ACCEPTED (completed/cancelled by the
    // Collector) so live location sharing stops exactly at that moment.
    _statusPoller = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() => _reloadTick++);
    });
  }

  @override
  void dispose() {
    _statusPoller?.cancel();
    LiveLocationService.instance.stopSharing();
    super.dispose();
  }

  /// Starts sharing this rider's live position while the request is ACCEPTED
  /// and stops the moment it is completed or cancelled. Idempotent per
  /// [LiveLocationService], safe to call from every build.
  void _syncLocationSharing(CollectionRequest request) {
    if (request.status == RequestStatus.accepted) {
      LiveLocationService.instance.startSharing(requestId: request.id);
    } else if (_lastSeenStatus == RequestStatus.accepted) {
      LiveLocationService.instance.stopSharing();
    }
    _lastSeenStatus = request.status;
  }

  Future<void> _openQrScanner(CollectionRequest request) async {
    final verified = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => RiderQrScanScreen(request: request)),
    );
    if (!mounted) return;
    if (verified == true) {
      setState(() => _qrVerified = true);
    }
    // Refresh regardless: the request may have changed server-side while
    // the scanner was open (e.g. cancelled by the Collector).
    setState(() => _reloadTick++);
  }

  Future<void> _openWeightEntry(CollectionRequest request) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            RiderWeightEntryScreen(request: request, qrVerified: _qrVerified),
      ),
    );
    if (!mounted) return;
    // Refresh regardless so state reflects the server (e.g. the request
    // was cancelled while the weight screen was open).
    setState(() => _reloadTick++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Workflow'),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.primaryGreen,
            ),
            tooltip: 'Refresh',
            onPressed: () => setState(() => _reloadTick++),
          ),
        ],
      ),
      body: ValueListenableBuilder<String?>(
        valueListenable: LiveLocationService.instance.sharingError,
        builder: (context, sharingError, child) {
          return Column(
            children: [
              if (sharingError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          sharingError,
                          style: GoogleFonts.outfit(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9F1239),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: AsyncView<CollectionRequest>(
                  key: ValueKey(_reloadTick),
                  future: _load,
                  loadingMessage: 'Loading request…',
                  builder: (context, request) {
                    _syncLocationSharing(request);
                    if (request.status == RequestStatus.completed) {
                      return _buildCompletedView(request);
                    }
                    if (request.status == RequestStatus.cancelled) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Text(
                            'This request was cancelled by the Collector.\n\nPlease pick another job.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15),
                          ),
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _buildHeader(request),
                        const SizedBox(height: 16),
                        RequestMapView(
                          latitude: request.latitude,
                          longitude: request.longitude,
                          label: 'Collector location — drive here to start',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => _openInMaps(request),
                            icon: const Icon(
                              Icons.navigation_rounded,
                              size: 20,
                            ),
                            label: Text(
                              'Navigate to Collector',
                              style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCollectorCard(request),
                        const SizedBox(height: 20),
                        Text(
                          'How to complete this collection',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkBlack,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Step 1 — Navigate (always available)
                        _buildStep(
                          index: 1,
                          icon: Icons.navigation_rounded,
                          title: 'Go to the Collector location',
                          subtitle:
                              'Use the map above or "Navigate" to open turn-by-turn directions.',
                          done: true,
                        ),
                        const SizedBox(height: 8),

                        // Step 2 — Scan QR
                        _buildStep(
                          index: 2,
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Scan the Collector\'s QR',
                          subtitle: _qrVerified
                              ? 'QR verified against the Collector profile.'
                              : 'Scan their permanent QR card to verify identity.',
                          done: _qrVerified,
                          trailing: _qrVerified
                              ? null
                              : SizedBox(
                                  height: 40,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openQrScanner(request),
                                    icon: const Icon(
                                      Icons.qr_code_scanner_rounded,
                                      size: 17,
                                    ),
                                    label: Text(
                                      'Scan QR',
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 8),

                        // Step 3 — Weight + Complete
                        _buildStep(
                          index: 3,
                          icon: Icons.monitor_weight_rounded,
                          title: 'Enter total weight (kg)',
                          subtitle: 'Enter the total waste weight collected.',
                          done: request.status == RequestStatus.completed,
                          trailing: SizedBox(
                            height: 40,
                            child: ElevatedButton.icon(
                              onPressed: () => _openWeightEntry(request),
                              icon: const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 17,
                              ),
                              label: Text(
                                request.status == RequestStatus.completed
                                    ? 'Completed'
                                    : 'Enter Weight',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(CollectionRequest request) {
    return Row(
      children: [
        StatusChip(status: request.status),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            statusHint(request.status),
            style: GoogleFonts.outfit(fontSize: 13, color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _buildCollectorCard(CollectionRequest request) {
    final collector = request.collector;
    return LiquidGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(16),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              children: [
                ClipPath(
                  clipper: HexagonClipper(),
                  child: Container(
                    color: AppTheme.primaryGreen,
                    child: Center(
                      child: Text(
                        (collector?.fullName ?? 'C').isNotEmpty
                            ? (collector!.fullName)[0].toUpperCase()
                            : 'C',
                        style: GoogleFonts.outfit(
                          color: AppTheme.pureWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                CustomPaint(
                  size: const Size(44, 44),
                  painter: HexagonBorderPainter(
                    color: AppTheme.lightGreen,
                    strokeWidth: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collector?.fullName ?? 'Collector',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.darkBlack,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  collector?.mobile ?? '',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Requested ${formatDateTime(request.requestedAt)}',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_rounded, color: AppTheme.primaryGreen),
            tooltip: 'Call Collector',
            onPressed: collector?.mobile != null
                ? () => _call(collector!.mobile)
                : null,
          ),
        ],
      ),
    );
  }

  Future<void> _call(String mobile) async {
    final uri = Uri.parse('tel:$mobile');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Hands off to the device's native maps app for turn-by-turn navigation
  /// to the pickup coordinates. Shows an error message if no maps app can
  /// be launched.
  Future<void> _openInMaps(CollectionRequest request) async {
    final error = await MapsLauncher.openDirections(
      latitude: request.latitude,
      longitude: request.longitude,
    );
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildStep({
    required int index,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool done,
    Widget? trailing,
  }) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: BorderRadius.circular(14),
      fillOpacity: done ? 0.68 : 0.58,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: done ? AppTheme.primaryGreen : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: done
                ? const Icon(
                    Icons.check_rounded,
                    color: AppTheme.pureWhite,
                    size: 18,
                  )
                : Center(
                    child: Text(
                      '$index',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: AppTheme.darkBlack,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 11.5,
                    color: AppTheme.textMuted,
                  ),
                ),
                if (trailing != null) ...[const SizedBox(height: 10), trailing],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedView(CollectionRequest request) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppTheme.mintGreen,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryGreen, width: 3),
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 52,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Collection Completed!',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkBlack,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Completed ${formatDateTime(request.completedAt)}',
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to My Jobs'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
