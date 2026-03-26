import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Primary colors
  static const Color primary = Color(0xFF974400);
  static const Color primaryContainer = Color(0xFFBB5808);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFFFFBFF);
  static const Color primaryFixed = Color(0xFFFFDBC9);
  static const Color primaryFixedDim = Color(0xFFFFB68D);
  static const Color onPrimaryFixed = Color(0xFF321200);
  static const Color onPrimaryFixedVariant = Color(0xFF763400);

  // Secondary colors
  static const Color secondary = Color(0xFF855233);
  static const Color secondaryContainer = Color(0xFFFEBA95);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF79482A);
  static const Color secondaryFixed = Color(0xFFFFDBC9);
  static const Color secondaryFixedDim = Color(0xFFFBB892);
  static const Color onSecondaryFixed = Color(0xFF321200);
  static const Color onSecondaryFixedVariant = Color(0xFF693B1E);

  // Tertiary colors
  static const Color tertiary = Color(0xFF006290);
  static const Color tertiaryContainer = Color(0xFF007BB5);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFCFCFF);
  static const Color tertiaryFixed = Color(0xFFCAE6FF);
  static const Color tertiaryFixedDim = Color(0xFF8DCDFF);
  static const Color onTertiaryFixed = Color(0xFF001E30);
  static const Color onTertiaryFixedVariant = Color(0xFF004B70);

  // Error colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Surface colors
  static const Color surface = Color(0xFFFDF9EE);
  static const Color surfaceBright = Color(0xFFFDF9EE);
  static const Color surfaceDim = Color(0xFFDDDACF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF7F3E8);
  static const Color surfaceContainer = Color(0xFFF1EEE3);
  static const Color surfaceContainerHigh = Color(0xFFECE8DD);
  static const Color surfaceContainerHighest = Color(0xFFE6E2D8);
  static const Color surfaceVariant = Color(0xFFE6E2D8);
  static const Color surfaceTint = Color(0xFF9A4600);

  // On Surface colors
  static const Color onSurface = Color(0xFF1C1C15);
  static const Color onSurfaceVariant = Color(0xFF564338);
  static const Color onBackground = Color(0xFF1C1C15);
  static const Color background = Color(0xFFFDF9EE);

  // Outline colors
  static const Color outline = Color(0xFF8A7266);
  static const Color outlineVariant = Color(0xFFDDC1B3);

  // Inverse colors
  static const Color inverseSurface = Color(0xFF31312A);
  static const Color inverseOnSurface = Color(0xFFF4F1E6);
  static const Color inversePrimary = Color(0xFFFFB68D);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: onSecondary,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        onTertiary: onTertiary,
        tertiaryContainer: tertiaryContainer,
        onTertiaryContainer: onTertiaryContainer,
        error: error,
        onError: onError,
        errorContainer: errorContainer,
        onErrorContainer: onErrorContainer,
        surface: surface,
        onSurface: onSurface,
        surfaceContainerHighest: surfaceContainerHighest,
        surfaceContainerHigh: surfaceContainerHigh,
        surfaceContainer: surfaceContainer,
        surfaceContainerLow: surfaceContainerLow,
        surfaceContainerLowest: surfaceContainerLowest,
        outline: outline,
        outlineVariant: outlineVariant,
        inverseSurface: inverseSurface,
        onInverseSurface: inverseOnSurface,
        inversePrimary: inversePrimary,
        surfaceTint: surfaceTint,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.interTextTheme().copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w800,
          color: onSurface,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          color: onSurface,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        bodyLarge: GoogleFonts.inter(color: onSurface),
        bodyMedium: GoogleFonts.inter(color: onSurface),
        bodySmall: GoogleFonts.inter(color: onSurfaceVariant),
        labelLarge: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        labelMedium: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: onSurfaceVariant,
        ),
        labelSmall: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          color: onSurfaceVariant,
          letterSpacing: 1.5,
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 0,
        color: surfaceContainerLowest,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
