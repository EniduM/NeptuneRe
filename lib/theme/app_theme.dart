import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Palette
  static const Color primaryGreen = Color(0xFF2E7D32); // Neptune Green
  static const Color lightGreen = Color(0xFF81C784); // Soft Light Green
  static const Color mintGreen = Color(0xFFE8F5E9); // Background Green Accent
  static const Color darkBlack = Color(0xFF111827); // Rich Dark Slate / Black
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFF9FAFB);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.outfitTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: pureWhite,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: lightGreen,
        surface: pureWhite,
        onPrimary: pureWhite,
        onSecondary: darkBlack,
        onSurface: darkBlack,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: pureWhite,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.outfit(
          color: darkBlack,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: const IconThemeData(color: darkBlack),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: pureWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGreen,
          side: const BorderSide(color: primaryGreen, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF3F4F6),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryGreen, width: 2),
        ),
        hintStyle: GoogleFonts.outfit(color: textMuted, fontSize: 14),
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: GoogleFonts.outfit(
          color: darkBlack,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: GoogleFonts.outfit(
          color: darkBlack,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: GoogleFonts.outfit(
          color: darkBlack,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.outfit(
          color: textMuted,
          fontSize: 14,
        ),
      ),
    );
  }
}
