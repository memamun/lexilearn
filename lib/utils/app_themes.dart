import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme configurations for light and dark modes
/// Based on color theory principles for optimal contrast and accessibility
class AppThemes {
  // Primary Color Palette (Blue-based)
  static const Color primary500 = Color(0xFF3B82F6); // Blue 500 - Main brand color
  static const Color primary600 = Color(0xFF2563EB); // Blue 600 - Hover states
  static const Color primary700 = Color(0xFF1D4ED8); // Blue 700 - Active states
  static const Color primary800 = Color(0xFF1E40AF); // Blue 800 - Dark mode primary
  static const Color primary900 = Color(0xFF1E3A8A); // Blue 900 - Darkest primary
  
  // Primary Light Variants
  static const Color primary50 = Color(0xFFEFF6FF);  // Blue 50 - Lightest
  static const Color primary100 = Color(0xFFDBEAFE); // Blue 100 - Very light
  static const Color primary200 = Color(0xFFBFDBFE); // Blue 200 - Light
  static const Color primary300 = Color(0xFF93C5FD); // Blue 300 - Medium light
  static const Color primary400 = Color(0xFF60A5FA); // Blue 400 - Medium
  
  // Semantic Colors (Performance-based)
  static const Color success500 = Color(0xFF10B981); // Emerald 500 - Success/Excellent
  static const Color success100 = Color(0xFFD1FAE5); // Emerald 100 - Success light
  static const Color success900 = Color(0xFF064E3B); // Emerald 900 - Success dark
  
  static const Color warning500 = Color(0xFFF59E0B); // Amber 500 - Warning/Good
  static const Color warning100 = Color(0xFFFEF3C7); // Amber 100 - Warning light
  static const Color warning900 = Color(0xFF78350F); // Amber 900 - Warning dark
  
  static const Color error500 = Color(0xFFEF4444);   // Red 500 - Error/Needs improvement
  static const Color error100 = Color(0xFFFEE2E2);   // Red 100 - Error light
  static const Color error900 = Color(0xFF7F1D1D);   // Red 900 - Error dark
  
  // Neutral Colors (Grayscale)
  static const Color neutral50 = Color(0xFFFAFAFA);   // Lightest gray
  static const Color neutral100 = Color(0xFFF5F5F5);  // Very light gray
  static const Color neutral200 = Color(0xFFE5E5E5);  // Light gray
  static const Color neutral300 = Color(0xFFD4D4D4);  // Medium light gray
  static const Color neutral400 = Color(0xFFA3A3A3);  // Medium gray
  static const Color neutral500 = Color(0xFF737373);  // Base gray
  static const Color neutral600 = Color(0xFF525252);  // Medium dark gray
  static const Color neutral700 = Color(0xFF404040);  // Dark gray
  static const Color neutral800 = Color(0xFF262626);  // Very dark gray
  static const Color neutral900 = Color(0xFF171717);  // Darkest gray
  
  // Legacy color mappings for backward compatibility
  static const Color primaryBlue = primary500;
  static const Color primaryBlueDark = primary800;
  static const Color secondaryGray = neutral600;
  static const Color lightGray = neutral50;
  static const Color darkGray = neutral900;
  static const Color cardGray = neutral800;
  static const Color surfaceGray = neutral700;
  static const Color textLight = neutral800;
  static const Color textDark = neutral100;
  static const Color textSecondaryLight = neutral600;
  static const Color textSecondaryDark = neutral400;
  static const Color borderLight = neutral200;
  static const Color borderDark = neutral600;

  /// Light theme configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary500,
        brightness: Brightness.light,
        primary: primary500,
        primaryContainer: primary100,
        secondary: neutral600,
        secondaryContainer: neutral100,
        surface: neutral50,
        surfaceContainer: neutral100,
        background: neutral50,
        error: error500,
        errorContainer: error100,
        onPrimary: Colors.white,
        onPrimaryContainer: primary900,
        onSecondary: Colors.white,
        onSecondaryContainer: neutral800,
        onSurface: neutral800,
        onBackground: neutral800,
        onError: Colors.white,
        onErrorContainer: error900,
        outline: neutral300,
        outlineVariant: neutral200,
        shadow: neutral900.withOpacity(0.1),
        scrim: neutral900.withOpacity(0.5),
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
        seedColor: primary500,
        brightness: Brightness.dark,
        primary: primary400,
        primaryContainer: primary900,
        secondary: neutral400,
        secondaryContainer: neutral800,
        surface: neutral900,
        surfaceContainer: neutral800,
        background: neutral900,
        error: error500,
        errorContainer: error900,
        onPrimary: neutral900,
        onPrimaryContainer: primary100,
        onSecondary: neutral900,
        onSecondaryContainer: neutral200,
        onSurface: neutral100,
        onBackground: neutral100,
        onError: neutral900,
        onErrorContainer: error100,
        outline: neutral600,
        outlineVariant: neutral700,
        shadow: Colors.black.withOpacity(0.3),
        scrim: Colors.black.withOpacity(0.7),
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
        ? neutral900 
        : neutral50;
  }

  static Color getCardColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? neutral800 
        : Colors.white;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? neutral700 
        : neutral100;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? neutral100 
        : neutral800;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? neutral400 
        : neutral600;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? neutral600 
        : neutral200;
  }

  static Color getPrimaryColor(BuildContext context) {
    return primary500;
  }

  static Color getSelectionColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? primary500.withOpacity(0.2)
        : primary500.withOpacity(0.1);
  }

  /// Semantic color methods for performance-based UI
  static Color getSuccessColor(BuildContext context) {
    return success500;
  }

  static Color getSuccessLightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? success500.withOpacity(0.2)
        : success100;
  }

  static Color getSuccessDarkColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? success500
        : success900;
  }

  static Color getWarningColor(BuildContext context) {
    return warning500;
  }

  static Color getWarningLightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? warning500.withOpacity(0.2)
        : warning100;
  }

  static Color getWarningDarkColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? warning500
        : warning900;
  }

  static Color getErrorColor(BuildContext context) {
    return error500;
  }

  static Color getErrorLightColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? error500.withOpacity(0.2)
        : error100;
  }

  static Color getErrorDarkColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? error500
        : error900;
  }

  /// Get performance-based colors
  static Color getPerformanceColor(BuildContext context, int percentage) {
    if (percentage >= 80) {
      return getSuccessColor(context);
    } else if (percentage >= 60) {
      return getWarningColor(context);
    } else {
      return getErrorColor(context);
    }
  }

  static Color getPerformanceLightColor(BuildContext context, int percentage) {
    if (percentage >= 80) {
      return getSuccessLightColor(context);
    } else if (percentage >= 60) {
      return getWarningLightColor(context);
    } else {
      return getErrorLightColor(context);
    }
  }

  static Color getPerformanceDarkColor(BuildContext context, int percentage) {
    if (percentage >= 80) {
      return getSuccessDarkColor(context);
    } else if (percentage >= 60) {
      return getWarningDarkColor(context);
    } else {
      return getErrorDarkColor(context);
    }
  }
}
