// ============================================================
// app_theme.dart
// Central design token registry for the CityBuilder UI.
//
// All colors, typography, shadows, radii, and spacing values
// are defined here so every widget references a single source
// of truth. Changing a token here updates the whole app.
// ============================================================

import 'package:flutter/material.dart';

// ── Color Palette ─────────────────────────────────────────────

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color background   = Color(0xFF0F172A); // Dark navy
  static const Color surface      = Color(0xFF1E293B); // Dark gray panel
  static const Color surfaceLight = Color(0xFF263348); // Slightly lighter panel
  static const Color border       = Color(0xFF334155); // Subtle border

  // Resource accent colors
  static const Color credits    = Color(0xFFF59E0B); // Amber / gold
  static const Color food       = Color(0xFF22C55E); // Soft green
  static const Color power      = Color(0xFFEAB308); // Yellow
  static const Color population = Color(0xFF3B82F6); // Blue

  // Terrain colors (desaturated, no neon)
  static const Color grass     = Color(0xFF4A7C59); // Muted green
  static const Color grassDark = Color(0xFF3D6B4A); // Slightly darker grass
  static const Color water     = Color(0xFF2E6B8A); // Muted blue
  static const Color waterDark = Color(0xFF245A76); // Darker water
  static const Color mountain  = Color(0xFF64748B); // Neutral gray
  static const Color mountainDark = Color(0xFF4E5F70);

  // Building tile overlays
  static const Color house       = Color(0xFF6366F1); // Indigo
  static const Color farm        = Color(0xFF16A34A); // Green
  static const Color powerPlant  = Color(0xFFCA8A04); // Amber
  static const Color market      = Color(0xFFEC4899); // Pink
  static const Color barracks    = Color(0xFFEF4444); // Red
  static const Color researchLab = Color(0xFF8B5CF6); // Purple

  // UI states
  static const Color selected  = Color(0xFF38BDF8); // Sky blue highlight
  static const Color warning   = Color(0xFFF97316); // Orange
  static const Color danger    = Color(0xFFEF4444); // Red
  static const Color success   = Color(0xFF22C55E); // Green
  static const Color disabled  = Color(0xFF475569); // Muted gray

  // Map background
  static const Color mapBackground = Color(0xFF1A2535);

  // Text
  static const Color textPrimary   = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted     = Color(0xFF64748B);
}

// ── Typography ─────────────────────────────────────────────────

class AppText {
  AppText._();

  // Use system sans-serif which maps to Inter/Roboto/SF Pro
  // depending on platform — clean and modern everywhere.
  static const String fontFamily = 'Roboto';

  static const TextStyle displayLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle resourceNumber = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.3,
  );

  static const TextStyle resourceLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelBold = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    letterSpacing: 0.2,
  );

  // Aliases used in game_screen.dart and other widgets
  static const TextStyle heading = headingMedium;
  static const TextStyle body    = bodyMedium;
}

// ── Shadows ────────────────────────────────────────────────────

class AppShadows {
  AppShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0x44000000),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];
}

// ── Border Radii ───────────────────────────────────────────────

class AppRadius {
  AppRadius._();

  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double lg   = 16.0;
  static const double xl   = 20.0;
  static const double full = 999.0;

  static const BorderRadius cardRadius =
      BorderRadius.all(Radius.circular(md));
  static const BorderRadius tileRadius =
      BorderRadius.all(Radius.circular(xs));
  static const BorderRadius pillRadius =
      BorderRadius.all(Radius.circular(full));
}

// ── Spacing ────────────────────────────────────────────────────

class AppSpacing {
  AppSpacing._();

  static const double xs  = 4.0;
  static const double sm  = 8.0;
  static const double md  = 12.0;
  static const double lg  = 16.0;
  static const double xl  = 24.0;
  static const double xxl = 32.0;
}

// ── MaterialApp ThemeData ──────────────────────────────────────

/// Convenience class so main.dart can call AppTheme.theme
class AppTheme {
  AppTheme._();
  static ThemeData get theme => buildAppTheme();
}

ThemeData buildAppTheme() {
  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary:   AppColors.selected,
      secondary: AppColors.credits,
      surface:   AppColors.surface,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      elevation: 0,
      titleTextStyle: AppText.headingMedium,
      iconTheme: IconThemeData(color: AppColors.textSecondary),
    ),
    cardTheme: CardTheme(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: AppColors.surfaceLight,
      textStyle: AppText.bodyMedium,
    ),
  );
}
