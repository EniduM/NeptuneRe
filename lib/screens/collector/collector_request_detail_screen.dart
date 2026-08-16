import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../models/api_models.dart';
import '../../providers/app_state.dart';
import '../../services/api_client.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/async_states.dart';
import '../../widgets/liquid_glass.dart';
import '../../widgets/request_map_view.dart';
import '../../widgets/status_chip.dart';

/// Collector: track a single request with live status polling,
/// timeline and cancellation (PENDING only).
class CollectorRequestDetailScreen extends StatefulWidget {
  final String requestId;

  const CollectorRequestDetailScreen({super.key, required this.requestId});

  @override
  State<CollectorRequestDetailScreen> createState() =>
      _CollectorRequestDetailScreenState();
}

class _CollectorRequestDetailScreenState
    extends State<CollectorRequestDetailScreen> {
  Timer? _poller;
  int _reloadTick = 0;

  Future<CollectionRequest> _load() =>
      context.read<AppState>().api.collector.getRequest(widget.requestId);

  @override
  void initState() {
    super.initState();
    _poller = Timer.periodic(
      const Duration(seconds: 20),
      (_) {
        if (mounted) setState(() => _reloadTick++);
      },
    );
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }

  Future<void> _cancelRequest(CollectionRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel Request',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This request is still waiting for a Rider. Cancel it?',
          style: GoogleFonts.outfit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<AppState>().api.collector.cancelRequest(request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request cancelled.'),
          backgroundColor: AppTheme.primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _reloadTick++);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _reloadTick++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Request'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppTheme.primaryGreen),
            tooltip: 'Refresh',
            onPressed: () => setState(() => _reloadTick++),
          ),
        ],
      ),
      body: AsyncView<CollectionRequest>(
        key: ValueKey(_reloadTick),
        future: _load,
        loadingMessage: 'Loading request…',
        builder: (context, request) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildHeader(request),
              const SizedBox(height: 16),
              RequestMapView(
                latitude: request.latitude,
                longitude: request.longitude,
                label: 'Collection location',
              ),
              const SizedBox(height: 20),
              _buildTimeline(request),
              const SizedBox(height: 16),
              _buildDetails(request),
              if (request.status == RequestStatus.pending) ...[
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                    ),
                    onPressed: () => _cancelRequest(request),
                    icon: const Icon(Icons.cancel_rounded),
                    label: const Text('Cancel Request'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
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
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeline(CollectionRequest request) {
    final requested = _timelineItem(
      Icons.add_location_alt_rounded,
      'Requested',
      formatDateTime(request.requestedAt),
      true,
    );
    final accepted = _timelineItem(
      Icons.directions_car_filled_rounded,
      'Accepted',
      formatDateTime(request.acceptedAt),
      request.acceptedAt != null,
    );
    final completed = _timelineItem(
      Icons.check_circle_rounded,
      'Completed',
      formatDateTime(request.completedAt),
      request.completedAt != null,
    );
    final cancelled = request.cancelledAt != null
        ? _timelineItem(
            Icons.cancel_rounded,
            'Cancelled',
            formatDateTime(request.cancelledAt),
            true,
            error: true,
          )
        : null;

    final steps = [
      requested,
      accepted,
      if (request.status != RequestStatus.cancelled) completed,
      ?cancelled,
    ];

    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Timeline',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlack,
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++) ...[
            steps[i],
            if (i < steps.length - 1)
              Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Container(
                  width: 2,
                  height: 18,
                  color: const Color(0xFFE5E7EB),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _timelineItem(
    IconData icon,
    String title,
    String time,
    bool active, {
    bool error = false,
  }) {
    final color = error
        ? Colors.redAccent
        : (active ? AppTheme.primaryGreen : AppTheme.textMuted);
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: error
                ? const Color(0xFFFEE2E2)
                : (active ? AppTheme.mintGreen : const Color(0xFFF3F4F6)),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: active || error ? AppTheme.darkBlack : AppTheme.textMuted,
          ),
        ),
        const Spacer(),
        Text(
          time,
          style: GoogleFonts.outfit(
            fontSize: 11.5,
            color: AppTheme.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildDetails(CollectionRequest request) {
    final rider = request.rider;
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Request Details',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkBlack,
            ),
          ),
          const SizedBox(height: 10),
          _detailRow('Request ID', request.id.substring(0, 8).toUpperCase()),
          _detailRow('Status', statusLabel(request.status)),
          _detailRow('Requested', formatDateTime(request.requestedAt)),
          if (rider != null) ...[
            const Divider(height: 20),
            Text(
              'Assigned Rider',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 6),
            _detailRow('Name', rider.fullName),
            _detailRow('Mobile', rider.mobile),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                color: AppTheme.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}