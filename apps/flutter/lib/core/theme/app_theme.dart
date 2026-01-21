import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

class AppColors {
  // --- Neutral (Backgrounds & Surfaces) ---
  static const Color bg0 = Color(0xFF0B1220); // App Background
  static const Color bg1 = Color(0xFF0D172A); // Gradient Top / AppBar
  static const Color surface1 = Color(0xFF111C2F); // Card Base
  static const Color surface2 = Color(0xFF14213A); // Elevated / Inputs
  static const Color surface3 = Color(0xFF182744); // Modals / BottomSheets

  // --- Borders ---
  static const Color borderSoft = Color.fromRGBO(255, 255, 255, 0.08);
  static const Color borderFocus = Color.fromRGBO(59, 130, 246, 0.55);
  static const Color divider = Color.fromRGBO(255, 255, 255, 0.06);

  // --- Text (Strict Typography Refresh v1) ---
  static const Color textPrimary = Color(0xFFE6EDF7);
  static const Color textSecondary = Color(0xB8E6EDF7); // 72% opacity
  static const Color textTertiary = Color(0x85E6EDF7); // 52% opacity
  static const Color textDisabled = Color(0x52E6EDF7); // 32% opacity (approx)

  // --- Accents ---
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryPressed = Color(0xFF2563EB);
  static const Color primarySoft = Color.fromRGBO(59, 130, 246, 0.18);

  // --- Semantics ---
  static const Color success = Color(0xFF22C55E);
  static const Color successSoft = Color.fromRGBO(34, 197, 94, 0.18);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningSoft = Color.fromRGBO(245, 158, 11, 0.18);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSoft = Color.fromRGBO(239, 68, 68, 0.16);

  static const Color info = Color(0xFF38BDF8);
  static const Color infoSoft = Color.fromRGBO(56, 189, 248, 0.16);

  // --- Legacy Mappings ---
  static const Color background = bg0;
  static const Color surface = surface1;
  static const Color text = textPrimary;
  static const Color muted = textTertiary;
  static const Color secondary = warning;
}

class AppTheme {
  /// The new "Desquadra Dark Calm" theme.
  static ThemeData darkCalm() {
    final baseTextTheme = GoogleFonts.manropeTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg0,

      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.primary,
        surface: AppColors.surface1,
        background: AppColors.bg0,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.danger,
        onError: Colors.white,
      ),

      // Text Theme (Strict Hierarchy)
      // Display/Headline are used for MoneyText mostly
      textTheme: baseTextTheme.copyWith(
        // MoneyXL (24sp)
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // MoneyL (22sp)
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Title (18sp) / MoneyM (18sp)
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Subtitle (14sp)
        titleSmall: baseTextTheme.titleSmall?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w400, // Regular per requirements
          color: AppColors.textPrimary,
        ),
        // Body (14-15sp)
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          fontSize: 14,
          height: 1.4,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        // Label (12sp)
        labelMedium: baseTextTheme.labelMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary, // Strict rule
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          fontSize: 12,
          color: AppColors.textTertiary, // Hints
        ),
      ),

      // Component Themes
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),

      cardTheme: CardThemeData(
        color: AppColors.surface1,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        margin: EdgeInsets.zero,
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface3,
        modalBackgroundColor: AppColors.surface3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      iconTheme: const IconThemeData(color: AppColors.textPrimary),

      // Inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface2,
        labelStyle: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontFamily: GoogleFonts.manrope().fontFamily,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: AppColors.textTertiary,
          fontSize: 14,
          fontFamily: GoogleFonts.manrope().fontFamily,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.borderFocus,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
      ),

      // Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          elevation: 0,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface1,
          side: const BorderSide(color: AppColors.borderSoft),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.manrope(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      useMaterial3: true,
    );
  }

  // --- LEGACY ---
  @Deprecated("Use darkCalm() instead")
  static ThemeData light() {
    return darkCalm(); // Redirect for safety
  }
}
