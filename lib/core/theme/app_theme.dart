import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens sourced from assets/DESIGN (1).md — the "Nudge" sensory-safe,
/// neuro-inclusive design system. No red anywhere; amber replaces error/danger.
///
/// These static constants are the light-mode values, kept for call sites that
/// have no BuildContext available (e.g. const decorative widgets). Anything
/// inside a widget's build method should prefer `context.colors.*` instead,
/// which resolves to [AppColors.light] or [AppColors.dark] via the current
/// theme so it actually responds to dark mode.
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
      extensions: const [AppColors.light],
    );
  }

  static ThemeData get darkTheme {
    const colors = AppColors.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: colors.surface,
        onSurface: colors.text,
      ),
      scaffoldBackgroundColor: colors.background,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: colors.surface,
        margin: const EdgeInsets.only(bottom: 12),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: colors.background,
        foregroundColor: colors.text,
      ).copyWith(titleTextStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 22, color: colors.text)),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ),
      textTheme: _textTheme(colors.text, colors.textVariant),
      extensions: const [AppColors.dark],
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

/// Theme-aware token set. Register on [ThemeData.extensions] and read via
/// `Theme.of(context).extension<AppColors>()!` — or, more conveniently,
/// `context.colors` (see [AppColorsX] below).
class AppColors extends ThemeExtension<AppColors> {
  final Color primary;
  final Color primaryContainer;
  final Color primaryFixed;
  final Color success;
  final Color successContainer;
  final Color onSuccessContainer;
  final Color warning;
  final Color warningContainer;
  final Color onWarningContainer;
  final Color background;
  final Color surface;
  final Color surfaceContainerLow;
  final Color surfaceContainer;
  final Color text;
  final Color textVariant;
  final Color outline;
  final Color outlineVariant;
  final Color divider;
  final Color iconBubble; // recurring light-tint circle behind feature icons
  final Color completedCard;
  final Color selectedGoal;
  final Color mascotPurple;
  final Color inactiveGray;
  final Color shadow;

  const AppColors({
    required this.primary,
    required this.primaryContainer,
    required this.primaryFixed,
    required this.success,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.background,
    required this.surface,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.text,
    required this.textVariant,
    required this.outline,
    required this.outlineVariant,
    required this.divider,
    required this.iconBubble,
    required this.completedCard,
    required this.selectedGoal,
    required this.mascotPurple,
    required this.inactiveGray,
    required this.shadow,
  });

  static const light = AppColors(
    primary: Color(0xFF7862E8),
    primaryContainer: Color(0xFF8C79F2),
    primaryFixed: Color(0xFFEFEAFB),
    success: Color(0xFF0EA358),
    successContainer: Color(0xFF83F5C6),
    onSuccessContainer: Color(0xFF007151),
    warning: Color(0xFF825100),
    warningContainer: Color(0xFFFFDDB8),
    onWarningContainer: Color(0xFF2A1700),
    background: Color(0xFFF9F9F8),
    surface: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF3F4F3),
    surfaceContainer: Color(0xFFEEEEED),
    text: Color(0xFF1A1C1C),
    textVariant: Color(0xFF474552),
    outline: Color(0xFF787583),
    outlineVariant: Color(0xFFC8C4D4),
    divider: Color(0xFFF0F0F0),
    iconBubble: Color(0xFFF4F1FC),
    completedCard: Color(0xFFF6F5FC),
    selectedGoal: Color(0xFFF4F1FC),
    mascotPurple: Color(0xFFB0A4F6),
    inactiveGray: Color(0xFF9E9EA7),
    shadow: Color(0xFF000000),
  );

  static const dark = AppColors(
    primary: Color(0xFF9C90F0),
    primaryContainer: Color(0xFF473C8C),
    primaryFixed: Color(0xFF2A2547),
    success: Color(0xFF4CD787),
    successContainer: Color(0xFF184A34),
    onSuccessContainer: Color(0xFF83F5C6),
    warning: Color(0xFFFFB74D),
    warningContainer: Color(0xFF4A3419),
    onWarningContainer: Color(0xFFFFDDB8),
    background: Color(0xFF12121A),
    surface: Color(0xFF1E1E2E),
    surfaceContainerLow: Color(0xFF23233A),
    surfaceContainer: Color(0xFF282840),
    text: Color(0xFFE0E0E0),
    textVariant: Color(0xFFB8B5C4),
    outline: Color(0xFF8B889C),
    outlineVariant: Color(0xFF3A3850),
    divider: Color(0xFF2A2A3D),
    iconBubble: Color(0xFF2A2547),
    completedCard: Color(0xFF23233A),
    selectedGoal: Color(0xFF2A2547),
    mascotPurple: Color(0xFFB0A4F6),
    inactiveGray: Color(0xFF6E6E7A),
    shadow: Color(0xFF000000),
  );

  /// Ambient depth shadow — subtler on dark surfaces where a black drop
  /// shadow barely reads against an already-dark background.
  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: shadow.withValues(alpha: this == dark ? 0.18 : 0.04),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  @override
  AppColors copyWith({
    Color? primary,
    Color? primaryContainer,
    Color? primaryFixed,
    Color? success,
    Color? successContainer,
    Color? onSuccessContainer,
    Color? warning,
    Color? warningContainer,
    Color? onWarningContainer,
    Color? background,
    Color? surface,
    Color? surfaceContainerLow,
    Color? surfaceContainer,
    Color? text,
    Color? textVariant,
    Color? outline,
    Color? outlineVariant,
    Color? divider,
    Color? iconBubble,
    Color? completedCard,
    Color? selectedGoal,
    Color? mascotPurple,
    Color? inactiveGray,
    Color? shadow,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      primaryFixed: primaryFixed ?? this.primaryFixed,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      onWarningContainer: onWarningContainer ?? this.onWarningContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      surfaceContainer: surfaceContainer ?? this.surfaceContainer,
      text: text ?? this.text,
      textVariant: textVariant ?? this.textVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      divider: divider ?? this.divider,
      iconBubble: iconBubble ?? this.iconBubble,
      completedCard: completedCard ?? this.completedCard,
      selectedGoal: selectedGoal ?? this.selectedGoal,
      mascotPurple: mascotPurple ?? this.mascotPurple,
      inactiveGray: inactiveGray ?? this.inactiveGray,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      primary: c(primary, other.primary),
      primaryContainer: c(primaryContainer, other.primaryContainer),
      primaryFixed: c(primaryFixed, other.primaryFixed),
      success: c(success, other.success),
      successContainer: c(successContainer, other.successContainer),
      onSuccessContainer: c(onSuccessContainer, other.onSuccessContainer),
      warning: c(warning, other.warning),
      warningContainer: c(warningContainer, other.warningContainer),
      onWarningContainer: c(onWarningContainer, other.onWarningContainer),
      background: c(background, other.background),
      surface: c(surface, other.surface),
      surfaceContainerLow: c(surfaceContainerLow, other.surfaceContainerLow),
      surfaceContainer: c(surfaceContainer, other.surfaceContainer),
      text: c(text, other.text),
      textVariant: c(textVariant, other.textVariant),
      outline: c(outline, other.outline),
      outlineVariant: c(outlineVariant, other.outlineVariant),
      divider: c(divider, other.divider),
      iconBubble: c(iconBubble, other.iconBubble),
      completedCard: c(completedCard, other.completedCard),
      selectedGoal: c(selectedGoal, other.selectedGoal),
      mascotPurple: c(mascotPurple, other.mascotPurple),
      inactiveGray: c(inactiveGray, other.inactiveGray),
      shadow: c(shadow, other.shadow),
    );
  }
}

/// Terse, theme-aware color access from any BuildContext:
/// `context.colors.textColor` instead of
/// `Theme.of(context).extension<AppColors>()!.textColor`.
extension AppColorsX on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;

  /// For one-off decorative tints that don't warrant their own token —
  /// `context.isDarkTheme ? darkLiteral : lightLiteral`. Prefer `context.colors.*`
  /// for anything structural (text, surface, outline, etc). Named `isDarkTheme`
  /// (not `isDarkMode`) to avoid colliding with a same-named extension in a
  /// third-party dependency.
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;
}
