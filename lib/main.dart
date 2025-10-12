import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_screen.dart';
import 'utils/error_handler.dart';
import 'utils/app_themes.dart';
import 'utils/theme_notifier.dart';
import 'services/theme_service.dart';

/// LexiLearn - A vocabulary learning app with flashcards and quizzes
void main() {
  // Initialize error handling
  ErrorHandler.initialize();
  
  runApp(const LexiLearnApp());
}

class LexiLearnApp extends StatefulWidget {
  const LexiLearnApp({super.key});

  @override
  State<LexiLearnApp> createState() => _LexiLearnAppState();
}

class _LexiLearnAppState extends State<LexiLearnApp> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
    _themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      _themeMode = _themeNotifier.themeMode;
    });
  }

  Future<void> _loadThemeMode() async {
    final themeMode = await ThemeService.getThemeMode();
    if (mounted) {
      _themeNotifier.updateTheme(themeMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      child: MaterialApp(
        title: 'LexiLearn',
        debugShowCheckedModeBanner: false,
        theme: AppThemes.lightTheme,
        darkTheme: AppThemes.darkTheme,
        themeMode: _themeMode,
        home: const HomeScreen(),
      ),
    );
  }
}