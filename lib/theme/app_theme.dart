import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// RoadSense PW (Bangladesh Public Works) Theme Definition
/// Provides a clean, modern municipal light theme matching official specifications
/// along with backward-compatible aliases for existing screens.
class AppTheme {
  // ---------------------------------------------------------
  // RoadSense PW Municipal Color Palette (Light Theme)
  // ---------------------------------------------------------
  static const Color primaryTeal = Color(0xFF09495C);
  static const Color primaryDark = Color(0xFF063340);
  static const Color scanGreen = Color(0xFF16A34A);
  static const Color lightGreenBg = Color(0xFFDCFCE7);
  static const Color urgentRed = Color(0xFFDC2626);
  static const Color urgentRedBg = Color(0xFFFEE2E2);
  static const Color scheduledAmber = Color(0xFFB45309);
  static const Color scheduledAmberBg = Color(0xFFFEF3C7);
  static const Color lightBlueBg = Color(0xFFEEF5FD);
  static const Color lightBlueAccent = Color(0xFFE0EDFF);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color scaffoldBackground = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color cardBackground = Colors.white;

  // Auxiliary UI Colors
  static const Color municipalBlue = Color(0xFF0C4A60);
  static const Color surfaceMuted = Color(0xFFF1F5F9);
  static const Color badgeGreenText = Color(0xFF15803D);
  static const Color badgeRedText = Color(0xFFB91C1C);
  static const Color badgeAmberText = Color(0xFF92400E);
  static const Color badgeBlueText = Color(0xFF1D4ED8);

  // ---------------------------------------------------------
  // Backward-Compatible Aliases
  // ---------------------------------------------------------
  static const Color background = scaffoldBackground;
  static const Color cardBg = cardBackground;
  static const Color cardBgLight = lightBlueBg;
  static const Color primaryPurple = primaryTeal;
  static const Color accentPink = urgentRed;
  static const Color sensorGreen = scanGreen;
  static const Color alertRed = urgentRed;
  static const Color infoBlue = primaryTeal;
  static const Color warningYellow = scheduledAmber;
  static const Color divider = borderColor;

  // Backward-compatible Gradients & Icon Backgrounds
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, municipalBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient heroBg = LinearGradient(
    colors: [primaryDark, primaryTeal],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cameraBg = LinearGradient(
    colors: [Color(0xFF0A1628), Color(0xFF0D2040)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Color purpleIconBg = Color(0x1F09495C);
  static const Color greenIconBg = Color(0x1F16A34A);
  static const Color blueIconBg = Color(0x1F09495C);

  // ---------------------------------------------------------
  // Typography (Google Fonts Inter)
  // ---------------------------------------------------------
  static TextStyle get titleLarge => GoogleFonts.inter(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.3,
      );

  static TextStyle get titleMedium => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: -0.2,
      );

  static TextStyle get titleSmall => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: textPrimary,
        height: 1.4,
      );

  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.35,
      );

  static TextStyle get bodySmall => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: textSecondary,
      );

  static TextStyle get badgeText => GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      );

  // ---------------------------------------------------------
  // Main Light ThemeData (Official RoadSense PW)
  // ---------------------------------------------------------
  static ThemeData get lightTheme {
    final base = ThemeData.light();
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryTeal,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: const ColorScheme.light(
        primary: primaryTeal,
        onPrimary: Colors.white,
        primaryContainer: lightBlueAccent,
        onPrimaryContainer: primaryDark,
        secondary: scanGreen,
        onSecondary: Colors.white,
        secondaryContainer: lightGreenBg,
        onSecondaryContainer: badgeGreenText,
        error: urgentRed,
        onError: Colors.white,
        errorContainer: urgentRedBg,
        onErrorContainer: badgeRedText,
        surface: cardBackground,
        onSurface: textPrimary,
        outline: borderColor,
        outlineVariant: borderColor,
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        headlineMedium: GoogleFonts.inter(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderColor,
        thickness: 1,
        space: 1,
      ),
    );
  }

  /// Preserved darkTheme for backward compatibility if invoked
  static ThemeData get darkTheme => lightTheme;

  // ---------------------------------------------------------
  // Helper BoxDecorations
  // ---------------------------------------------------------
  static BoxDecoration cardDecoration({
    Color backgroundColor = cardBackground,
    BorderRadius? borderRadius,
    Color border = borderColor,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(color: border, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  static BoxDecoration badgeDecoration({
    required Color background,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: background,
      borderRadius: borderRadius ?? BorderRadius.circular(6),
    );
  }
}
