import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SahulatTheme {
  // ═══════════════════════════════════════════════════════════════════════════
  // Brand colors from DESIGN.md (Sahulat Oasis)
  // ═══════════════════════════════════════════════════════════════════════════
  // Flip7 Design System Colors
  static const Color primaryColor = Color(0xFF2BA8A2); // Primary Teal
  static const Color primaryGlow = Color(0xFF14B8A6); // Primary Light (keep)
  static const Color secondaryColor = Color(0xFFEF6C4A); // Coral
  static const Color accentGold = Color(0xFFFFD23F); // Gold CTA
  static const Color accentCoral = Color(0xFFD45233); // Dark Coral
  static const Color backgroundDark = Color(0xFF090D16); // Dark Background
  static const Color surfaceDark = Color(0xFF111827); // Dark Surface

  // ═══════════════════════════════════════════════════════════════════════════
  // Light Mode Colors — warm cream palette, high-contrast readable text
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color lightBg = Color(0xFFFAF8F5); // Warm parchment base
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF5F1EC); // Subtle warm tint for panels
  static const Color lightBorder = Color(0xFFDDD9D4); // Slightly stronger border
  static const Color lightTextPrimary = Color(0xFF1A1614); // Near-black, warm undertone
  static const Color lightTextSecondary = Color(0xFF5C554E); // Readable warm gray
  static const Color lightTextTertiary = Color(0xFF8A8279); // Muted but visible

  // ═══════════════════════════════════════════════════════════════════════════
  // Dark Mode Colors — deep slate navy, luminous accents
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color darkBg = Color(0xFF0B0F1A); // Deep navy slate
  static const Color darkSurface = Color(0xFF131A2B); // Elevated card surface
  static const Color darkSurfaceVariant = Color(0xFF1A2236); // Panels, sheets
  static const Color darkBorder = Color(0xFF243044); // Visible but subtle
  static const Color darkTextPrimary = Color(0xFFF1F3F8); // Soft white with blue tint
  static const Color darkTextSecondary = Color(0xFFA0AAB8); // Muted but readable
  static const Color darkTextTertiary = Color(0xFF6B7689); // Subtle labels

  // ═══════════════════════════════════════════════════════════════════════════
  // Semantic Colors — consistent across themes
  // ═══════════════════════════════════════════════════════════════════════════
  static const Color successColor = Color(0xFF10B981); // Mint
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Crimson

  // ═══════════════════════════════════════════════════════════════════════════
  // Light Theme
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        surfaceContainerHighest: lightSurfaceVariant,
        error: errorColor,
        outlineVariant: lightBorder,
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
        onSurfaceVariant: lightTextSecondary,
        brightness: Brightness.light,
      ),
      textTheme: _buildTextTheme(isLight: true),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface.withValues(alpha: 0.92),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: lightTextPrimary, size: 22),
        titleTextStyle: GoogleFonts.outfit(
          color: lightTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: lightTextTertiary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurfaceVariant,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: primaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        shape: StadiumBorder(side: BorderSide(color: primaryColor.withValues(alpha: 0.2), width: 1)),
        side: BorderSide(color: primaryColor.withValues(alpha: 0.2), width: 1),
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
        space: 24,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor;
          return lightTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryColor.withValues(alpha: 0.3);
          return lightBorder;
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: lightSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalBarrierColor: Color(0x66000000),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightTextPrimary,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: lightSurface,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      iconTheme: const IconThemeData(color: lightTextSecondary, size: 22),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: lightBorder,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Dark Theme
  // ═══════════════════════════════════════════════════════════════════════════
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        surfaceContainerHighest: darkSurfaceVariant,
        error: errorColor,
        outlineVariant: darkBorder,
        onPrimary: Colors.white,
        onSurface: darkTextPrimary,
        onSurfaceVariant: darkTextSecondary,
        brightness: Brightness.dark,
      ),
      textTheme: _buildTextTheme(isLight: false),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: darkTextPrimary, size: 22),
        titleTextStyle: GoogleFonts.outfit(
          color: darkTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGlow,
          side: BorderSide(color: primaryGlow.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: darkTextTertiary,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: primaryGlow, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVariant,
        labelStyle: GoogleFonts.plusJakartaSans(
          color: primaryGlow,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        shape: StadiumBorder(side: BorderSide(color: primaryGlow.withValues(alpha: 0.2), width: 1)),
        side: BorderSide(color: primaryGlow.withValues(alpha: 0.2), width: 1),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 24,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGlow;
          return darkTextTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primaryGlow.withValues(alpha: 0.3);
          return darkBorder;
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: darkSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        modalBarrierColor: Color(0x99000000),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkTextPrimary,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: darkBg,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        elevation: 4,
      ),
      iconTheme: const IconThemeData(color: darkTextSecondary, size: 22),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryGlow,
        linearTrackColor: darkBorder,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Shared Text Theme Builder
  // ═══════════════════════════════════════════════════════════════════════════
  static TextTheme _buildTextTheme({required bool isLight}) {
    final primary = isLight ? lightTextPrimary : darkTextPrimary;
    final secondary = isLight ? lightTextSecondary : darkTextSecondary;

    final base = isLight
        ? GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme)
        : GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme);

    return base.copyWith(
      // Display — hero sections, splash
      displayLarge: GoogleFonts.outfit(
        color: primary, fontWeight: FontWeight.w800,
        fontSize: 34, letterSpacing: -1.2, height: 1.15,
      ),
      displayMedium: GoogleFonts.outfit(
        color: primary, fontWeight: FontWeight.w700,
        fontSize: 28, letterSpacing: -0.8, height: 1.2,
      ),
      displaySmall: GoogleFonts.outfit(
        color: primary, fontWeight: FontWeight.w700,
        fontSize: 24, letterSpacing: -0.5, height: 1.25,
      ),
      // Headlines — screen titles
      headlineLarge: GoogleFonts.outfit(
        color: primary, fontWeight: FontWeight.w700,
        fontSize: 22, letterSpacing: -0.3, height: 1.3,
      ),
      headlineMedium: GoogleFonts.outfit(
        color: primary, fontWeight: FontWeight.w700,
        fontSize: 20, letterSpacing: -0.2, height: 1.3,
      ),
      headlineSmall: GoogleFonts.outfit(
        color: primary, fontWeight: FontWeight.w600,
        fontSize: 18, height: 1.35,
      ),
      // Titles — card headers, section labels
      titleLarge: GoogleFonts.outfit(
        color: primary, fontWeight: FontWeight.w600,
        fontSize: 17, height: 1.35,
      ),
      titleMedium: GoogleFonts.outfit(
        color: primary, fontWeight: FontWeight.w600,
        fontSize: 15, height: 1.4,
      ),
      titleSmall: GoogleFonts.outfit(
        color: primary, fontWeight: FontWeight.w500,
        fontSize: 14, height: 1.4,
      ),
      // Body — main content, chat messages
      bodyLarge: GoogleFonts.plusJakartaSans(
        color: primary, fontSize: 16, fontWeight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        color: secondary, fontSize: 14, fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        color: secondary, fontSize: 12.5, fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      // Labels — badges, status chips, buttons
      labelLarge: GoogleFonts.plusJakartaSans(
        color: primary, fontSize: 14,
        fontWeight: FontWeight.w600, letterSpacing: 0.3,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        color: secondary, fontSize: 12,
        fontWeight: FontWeight.w600, letterSpacing: 0.4,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        color: secondary, fontSize: 11,
        fontWeight: FontWeight.w700, letterSpacing: 0.5,
      ),
    );
  }
}
