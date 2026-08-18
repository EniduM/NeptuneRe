import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/hexagon_clipper.dart';

/// Hexagonal recycling pin used for map markers across the app
/// (collector pick-up points).
class RecyclingPin extends StatelessWidget {
  final double size;

  const RecyclingPin({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          ClipPath(
            clipper: HexagonClipper(),
            child: Container(
              color: AppTheme.primaryGreen,
              child: const Center(
                child: Icon(
                  Icons.recycling_rounded,
                  color: AppTheme.pureWhite,
                  size: 22,
                ),
              ),
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: HexagonBorderPainter(
              color: AppTheme.lightGreen,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );
  }
}
