import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configurations for light and dark modes
class AppThemes {
  // Color constants
  static const Color primaryBlue = Color(0xFF1132D4);
  static const Color primaryBlueDark = Color(0xFF0A1F8A);
  static const Color secondaryGray = Color(0xFF2C3E50);
  static const Color lightGray = Color(0xFFF6F6F8);
  static const Color darkGray = Color(0xFF121212);
  static const Color cardGray = Color(0xFF1E1E1E);
  static const Color surfaceGray = Color(0xFF2A2A2A);
  static const Color textLight = Color(0xFF2C3E50);
  static const Color textDark = Color(0xFFE1E1E1);
  static const Color textSecondaryLight = Color(0xFF2C3E50);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderDark = Color(0xFF404040);

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.light,
        primary: primaryBlue,
        secondary: secondaryGray,
        surface: Colors.white,
        background: lightGray,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textLight,
        onBackground: textLight,
      ),
      textTheme: GoogleFonts.lexendTextTheme(ThemeData.light().textTheme),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: lightGray,
        foregroundColor: textLight,
        titleTextStyle: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      scaffoldBackgroundColor: lightGray,
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        brightness: Brightness.dark,
        primary: primaryBlue,
        secondary: primaryBlueDark,
        surface: cardGray,
        background: darkGray,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
        onBackground: textDark,
        outline: borderDark,
      ),
      textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyLarge: GoogleFonts.lexend(color: textDark),
        bodyMedium: GoogleFonts.lexend(color: textDark),
        bodySmall: GoogleFonts.lexend(color: textSecondaryDark),
        titleLarge: GoogleFonts.lexend(color: textDark, fontWeight: FontWeight.bold),
        titleMedium: GoogleFonts.lexend(color: textDark, fontWeight: FontWeight.w600),
        titleSmall: GoogleFonts.lexend(color: textDark, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkGray,
        foregroundColor: textDark,
        titleTextStyle: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textDark,
        ),
        iconTheme: IconThemeData(color: textDark),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceGray,
        hintStyle: GoogleFonts.lexend(color: textSecondaryDark),
        labelStyle: GoogleFonts.lexend(color: textSecondaryDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderDark),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
      ),
      scaffoldBackgroundColor: darkGray,
      dividerTheme: DividerThemeData(
        color: borderDark,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceGray,
        selectedColor: primaryBlue,
        labelStyle: GoogleFonts.lexend(color: textDark),
        secondaryLabelStyle: GoogleFonts.lexend(color: Colors.white),
        brightness: Brightness.dark,
      ),
      listTileTheme: ListTileThemeData(
        textColor: textDark,
        iconColor: textDark,
        tileColor: cardGray,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Get theme colors based on brightness
  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkGray 
        : lightGray;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? cardGray 
        : Colors.white;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? surfaceGray 
        : Colors.white;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? textDark 
        : textLight;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? textSecondaryDark 
        : textSecondaryLight;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? borderDark 
        : borderLight;
  }

  static Color getPrimaryColor(BuildContext context) {
    return primaryBlue;
  }

  static Color getSelectionColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? primaryBlue.withOpacity(0.2)
        : primaryBlue.withOpacity(0.1);
  }
}
