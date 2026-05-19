import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SahulatTheme {
  // Brand colors from DESIGN.md (Sahulat Oasis)
  static const Color primaryColor = Color(0xFF0D9488); // Forest Emerald
  static const Color primaryGlow = Color(0xFF14B8A6);
  static const Color secondaryColor = Color(0xFFC2410C); // Clay Terracotta
  
  // Light Mode Colors
  static const Color lightBg = Color(0xFFFFFBF5); // Warm cream base
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE7E5E4);
  static const Color lightTextPrimary = Color(0xFF1C1917);
  static const Color lightTextSecondary = Color(0xFF57534E);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF090D16); // Slate dark navy
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkBorder = Color(0xFF1F2937);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // Semantic Colors
  static const Color successColor = Color(0xFF10B981); // Mint
  static const Color warningColor = Color(0xFFF59E0B); // Amber
  static const Color errorColor = Color(0xFFEF4444); // Crimson

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: lightSurface,
        error: errorColor,
        outlineVariant: lightBorder,
        onPrimary: Colors.white,
        onSurface: lightTextPrimary,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.bold, letterSpacing: -1.5),
        displayMedium: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displaySmall: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: lightTextPrimary, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.plusJakartaSans(color: lightTextPrimary),
        bodyMedium: GoogleFonts.plusJakartaSans(color: lightTextSecondary),
        labelSmall: GoogleFonts.plusJakartaSans(color: lightTextSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightSurface.withValues(alpha: 0.8),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: lightTextPrimary),
        titleTextStyle: GoogleFonts.outfit(color: lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        hintStyle: GoogleFonts.plusJakartaSans(color: lightTextSecondary.withValues(alpha: 0.5)),
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
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        labelStyle: GoogleFonts.plusJakartaSans(color: primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        shape: const StadiumBorder(side: BorderSide(color: lightBorder, width: 1)),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: darkSurface,
        error: errorColor,
        outlineVariant: darkBorder,
        onPrimary: Colors.white,
        onSurface: darkTextPrimary,
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.bold, letterSpacing: -1.5),
        displayMedium: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.bold, letterSpacing: -0.5),
        displaySmall: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.w600),
        titleMedium: GoogleFonts.outfit(color: darkTextPrimary, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.plusJakartaSans(color: darkTextPrimary),
        bodyMedium: GoogleFonts.plusJakartaSans(color: darkTextSecondary),
        labelSmall: GoogleFonts.plusJakartaSans(color: darkTextSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: darkTextPrimary),
        titleTextStyle: GoogleFonts.outfit(color: darkTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        hintStyle: GoogleFonts.plusJakartaSans(color: darkTextSecondary.withValues(alpha: 0.5)),
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
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        labelStyle: GoogleFonts.plusJakartaSans(color: primaryGlow, fontSize: 12, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
        shape: const StadiumBorder(side: BorderSide(color: darkBorder, width: 1)),
      ),
    );
  }
}

