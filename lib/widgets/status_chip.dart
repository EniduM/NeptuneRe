import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// Colored status pill matching the Neptune green/white palette.
class StatusChip extends StatelessWidget {
  final RequestStatus status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      RequestStatus.pending => (
          const Color(0xFFFFF3E0),
          const Color(0xFFEF6C00),
        ),
      RequestStatus.accepted => (
          const Color(0xFFE3F2FD),
          const Color(0xFF1565C0),
        ),
      RequestStatus.completed => (
          AppTheme.mintGreen,
          AppTheme.primaryGreen,
        ),
      RequestStatus.cancelled => (
          const Color(0xFFF3F4F6),
          AppTheme.textMuted,
        ),
    };
    final icon = switch (status) {
      RequestStatus.pending => Icons.hourglass_top_rounded,
      RequestStatus.accepted => Icons.directions_car_filled_rounded,
      RequestStatus.completed => Icons.check_circle_rounded,
      RequestStatus.cancelled => Icons.cancel_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 4),
          Text(
            statusLabel(status),
            style: GoogleFonts.outfit(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}