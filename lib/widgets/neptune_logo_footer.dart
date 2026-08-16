import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/hexagon_clipper.dart';

class NeptuneLogoFooter extends StatelessWidget {
  final bool compact;

  const NeptuneLogoFooter({
    super.key,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: compact ? 8 : 12,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.8),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hexagonal Logo Emblem Space
            SizedBox(
              width: compact ? 28 : 34,
              height: compact ? 28 : 34,
              child: Stack(
                children: [
                  ClipPath(
                    clipper: HexagonClipper(),
                    child: Container(
                      color: AppTheme.primaryGreen,
                      child: Center(
                        child: Icon(
                          Icons.recycling_rounded,
                          color: AppTheme.pureWhite,
                          size: compact ? 16 : 20,
                        ),
                      ),
                    ),
                  ),
                  CustomPaint(
                    size: Size(compact ? 28 : 34, compact ? 28 : 34),
                    painter: HexagonBorderPainter(
                      color: AppTheme.lightGreen,
                      strokeWidth: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'NEPTUNE',
                        style: GoogleFonts.outfit(
                          color: AppTheme.darkBlack,
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'RECYCLERS',
                        style: GoogleFonts.outfit(
                          color: AppTheme.primaryGreen,
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Powering Kandy Smart Waste System',
                    style: GoogleFonts.outfit(
                      color: AppTheme.textMuted,
                      fontSize: compact ? 9 : 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
