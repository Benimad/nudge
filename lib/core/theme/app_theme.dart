import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens sourced from assets/DESIGN (1).md — the "Nudge" sensory-safe,
/// neuro-inclusive design system. No red anywhere; amber replaces error/danger.
class AppTheme {
  // Primary — Soft Purple
  static const Color primaryColor = Color(0xFF7862E8); // Updated to match mockup primary button/text
  static const Color primaryContainerColor = Color(0xFF8C79F2);
  static const Color primaryFixedColor = Color(0xFFEFEAFB); // light purple tint (10%-ish), chips/avatars/selected states

  // Secondary — Mint Green (success / completion)
  static const Color successColor = Color(0xFF0EA358); // solid fill + white text/icon (buttons, snackbars)
  static const Color successContainerColor = Color(0xFF83F5C6); // mint fill for completed habit indicators
  static const Color onSuccessContainerColor = Color(0xFF007151); // icon/text on top of mint fill

  // Tertiary — Amber (replaces all error/danger red)
  static const Color warningColor = Color(0xFF825100); // solid fill + white text/icon (badges, icons)
  static const Color warningContainerColor = Color(0xFFFFDDB8); // light amber bg for "gentle" alerts/snackbars
  static const Color onWarningContainerColor = Color(0xFF2A1700); // text on light amber bg

  // Surfaces
  static const Color backgroundColor = Color(0xFFF9F9F8); // warm off-white
  static const Color cardColor = Color(0xFFFFFFFF); // surface-container-lowest
  static const Color surfaceContainerLowColor = Color(0xFFF3F4F3); // subtle tonal layer
  static const Color surfaceContainerColor = Color(0xFFEEEEED);

  // Text & outlines
  static const Color textColor = Color(0xFF1A1C1C); // on-surface
  static const Color textVariantColor = Color(0xFF474552); // on-surface-variant (muted/secondary text)
  static const Color outlineColor = Color(0xFF787583);
  static const Color outlineVariantColor = Color(0xFFC8C4D4);

  /// Ambient depth shadow per DESIGN.md: y:4, blur:20, opacity:0.04, color:#000
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: successColor,
        tertiary: warningColor,
        surface: cardColor,
        onSurface: textColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: backgroundColor,
      textTheme: _textTheme(textColor, textVariantColor),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: cardColor,
        margin: const EdgeInsets.only(bottom: 12),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        titleTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 22, color: textColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    const darkSurface = Color(0xFF1E1E2E);
    const darkBackground = Color(0xFF12121A);
    const darkOnSurface = Color(0xFFE0E0E0);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: darkSurface,
        onSurface: darkOnSurface,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: darkSurface,
        margin: const EdgeInsets.only(bottom: 12),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: darkBackground,
        foregroundColor: darkOnSurface,
      ).copyWith(titleTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 22, color: darkOnSurface)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ),
      textTheme: _textTheme(darkOnSurface, const Color(0xFFB8B5C4)),
    );
  }

  /// Inter type scale, restricted to weights 400 (Regular) and 500 (Medium)
  /// per DESIGN.md: headline-lg 22, headline-md 20, body-lg 16, body-md 14, label-lg 14, label-sm 12.
  static TextTheme _textTheme(Color onSurface, Color onSurfaceVariant) {
    return GoogleFonts.interTextTheme().copyWith(
      displayLarge: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 22, color: onSurface, height: 28 / 22),
      displayMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 22, color: onSurface, height: 28 / 22),
      displaySmall: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 20, color: onSurface, height: 26 / 20),
      headlineMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 22, color: onSurface, height: 28 / 22),
      headlineSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 20, color: onSurface, height: 26 / 20),
      titleLarge: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 22, color: onSurface, height: 28 / 22),
      titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16, color: onSurface),
      bodyLarge: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 16, color: onSurface, height: 24 / 16),
      bodyMedium: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: onSurface, height: 20 / 14),
      bodySmall: GoogleFonts.inter(fontWeight: FontWeight.w400, fontSize: 14, color: onSurfaceVariant, height: 20 / 14),
      labelLarge: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14, color: onSurface, height: 20 / 14),
      labelSmall: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 12, color: onSurfaceVariant, height: 16 / 12),
    );
  }

  static const List<Color> habitColors = [
    primaryColor,
    successColor,
    warningColor,
    Color(0xFF68B0AB), // Teal
    primaryContainerColor,
    Color(0xFFF4A261), // Warm orange
    onSuccessContainerColor,
    Color(0xFFD88373), // Dusty rose
  ];

  // Mockup-exact accents
  static const Color checkGreen = Color(0xFF0EA358); // progress bar, completed check circles, % label
  static const Color completedCardColor = Color(0xFFF6F5FC); // very light lavender tint on completed habit cards
  static const Color selectedGoalColor = Color(0xFFF4F1FC); // lavender tint on selected goal cards
  static const Color mascotPurple = Color(0xFFB0A4F6); // brain mascot circle background
  static const Color inactiveGray = Color(0xFF9E9EA7); // unselected nav items / pending circles

  // Premium UI additions
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryColor, primaryContainerColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient textGradient = LinearGradient(
    colors: [primaryColor, primaryContainerColor],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
