import 'package:flutter/material.dart';

/// Global theme notifier for updating theme across the app
class ThemeNotifier extends ChangeNotifier {
  static final ThemeNotifier _instance = ThemeNotifier._internal();
  factory ThemeNotifier() => _instance;
  ThemeNotifier._internal();

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void updateTheme(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }
}
