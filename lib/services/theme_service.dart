import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing app theme (light/dark mode)
class ThemeService {
  static const String _themeKey = 'app_theme';
  static const String _lightTheme = 'light';
  static const String _darkTheme = 'dark';
  static const String _systemTheme = 'system';

  /// Get current theme mode
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeString = prefs.getString(_themeKey) ?? _systemTheme;
    
    switch (themeString) {
      case _lightTheme:
        return ThemeMode.light;
      case _darkTheme:
        return ThemeMode.dark;
      case _systemTheme:
      default:
        return ThemeMode.system;
    }
  }

  /// Set theme mode
  static Future<void> setThemeMode(ThemeMode themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeString;
    
    switch (themeMode) {
      case ThemeMode.light:
        themeString = _lightTheme;
        break;
      case ThemeMode.dark:
        themeString = _darkTheme;
        break;
      case ThemeMode.system:
      default:
        themeString = _systemTheme;
        break;
    }
    
    await prefs.setString(_themeKey, themeString);
  }

  /// Get theme string for display
  static Future<String> getThemeString() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? _systemTheme;
  }

  /// Reset theme to system default
  static Future<void> resetTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey);
  }
}
