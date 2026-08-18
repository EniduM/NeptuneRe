import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/api_models.dart';
import '../theme/app_theme.dart';
import '../theme/hexagon_clipper.dart';
import '../utils/formatters.dart';
import 'liquid_glass.dart';
import 'status_chip.dart';

/// Reusable collection-request card used across Collector and Rider flows.
class RequestCard extends StatelessWidget {
  final CollectionRequest request;
  final VoidCallback? onTap;
  final Widget? trailing;

  const RequestCard({
    super.key,
    required this.request,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final collector = request.collector;
    final rider = request.rider;

    return LiquidGlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: BorderRadius.circular(18),
      fillOpacity: 0.60,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: ClipPath(
                        clipper: HexagonClipper(),
                        child: Container(
                          color: AppTheme.primaryGreen,
                          child: Center(
                            child: Text(
                              (collector?.fullName ?? 'C')
                                  .isNotEmpty
                                  ? (collector?.fullName ?? 'C')[0]
                                      .toUpperCase()
                                  : 'C',
                              style: GoogleFonts.outfit(
                                color: AppTheme.pureWhite,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
                            collector?.fullName ?? 'Collector',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.darkBlack,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (collector?.mobile != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              collector!.mobile,
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    StatusChip(status: request.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${request.latitude.toStringAsFixed(5)}, ${request.longitude.toStringAsFixed(5)}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      formatTime(request.requestedAt),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (trailing != null) ...[
                  const SizedBox(height: 6),
                  trailing!,
                ],
                if (rider != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.mintGreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.directions_car_filled_rounded,
                          size: 14,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Rider: ${rider.fullName} (${rider.mobile})',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}