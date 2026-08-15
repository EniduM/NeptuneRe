import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../theme/hexagon_clipper.dart';

class HexagonAvatar extends StatelessWidget {
  final String text;
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final Widget? child;

  const HexagonAvatar({
    super.key,
    this.text = '',
    this.size = 48,
    this.backgroundColor = AppTheme.primaryGreen,
    this.textColor = AppTheme.pureWhite,
    this.child,
  });

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
              color: backgroundColor,
              child: Center(
                child: child ??
                    Text(
                      text.isNotEmpty ? text[0].toUpperCase() : '?',
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: size * 0.42,
                      ),
                    ),
              ),
            ),
          ),
          CustomPaint(
            size: Size(size, size),
            painter: HexagonBorderPainter(
              color: AppTheme.lightGreen,
              strokeWidth: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
