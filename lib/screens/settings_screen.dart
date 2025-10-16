import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/favorites_service.dart';
import '../services/quiz_state_service.dart';
import '../services/learning_stats_service.dart';
import '../services/quiz_settings_service.dart';
import '../services/theme_service.dart';
import '../utils/theme_notifier.dart';
import '../utils/app_themes.dart';

/// Settings screen with all app configuration options
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppThemes.getBackgroundColor(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppThemes.getTextColor(context),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppThemes.getTextColor(context),
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Quiz Settings Section
              _buildSectionHeader('Quiz Settings'),
              const SizedBox(height: 12),
              _buildQuizSettingsCard(context),
              
              const SizedBox(height: 24),
              
              // Theme Settings Section
              _buildSectionHeader('Appearance'),
              const SizedBox(height: 12),
              _buildThemeSettingsCard(context),
              
              const SizedBox(height: 24),
              
              // Data Management Section
              _buildSectionHeader('Data Management'),
              const SizedBox(height: 12),
              _buildDataManagementCard(context),
              
              const SizedBox(height: 24),
              
              // App Info Section
              _buildSectionHeader('App Information'),
              const SizedBox(height: 12),
              _buildAppInfoCard(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.lexend(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppThemes.getTextColor(context),
        letterSpacing: 0.5,
      ),
    );
  }

  /// Build quiz settings card
  Widget _buildQuizSettingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.quiz,
                color: AppThemes.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Quiz Configuration',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppThemes.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Number of Questions per Quiz',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppThemes.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<int>(
            future: QuizSettingsService.getQuestionCount(),
            builder: (context, snapshot) {
              int currentCount = snapshot.data ?? 5;
              
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: QuizSettingsService.getAvailableQuestionCounts().map((count) {
                  final isSelected = count == currentCount;
                  return GestureDetector(
                    onTap: () async {
                      await QuizSettingsService.setQuestionCount(count);
                      setState(() {
                        currentCount = count;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppThemes.getPrimaryColor(context)
                            : AppThemes.getCardColor(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected 
                              ? AppThemes.getPrimaryColor(context)
                              : AppThemes.getBorderColor(context),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$count',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Colors.white 
                              : AppThemes.getTextColor(context),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Choose how many questions you want in each quiz session',
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Build theme settings card
  Widget _buildThemeSettingsCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.palette,
                color: AppThemes.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Theme Settings',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppThemes.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<ThemeMode>(
            future: ThemeService.getThemeMode(),
            builder: (context, snapshot) {
              final currentTheme = snapshot.data ?? ThemeMode.system;
              
              return Column(
                children: [
                  _buildThemeOption(
                    context,
                    ThemeMode.light,
                    'Light',
                    'Use light theme',
                    Icons.light_mode,
                    currentTheme == ThemeMode.light,
                    () async {
                      await ThemeService.setThemeMode(ThemeMode.light);
                      ThemeNotifier().updateTheme(ThemeMode.light);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    context,
                    ThemeMode.dark,
                    'Dark',
                    'Use dark theme',
                    Icons.dark_mode,
                    currentTheme == ThemeMode.dark,
                    () async {
                      await ThemeService.setThemeMode(ThemeMode.dark);
                      ThemeNotifier().updateTheme(ThemeMode.dark);
                      setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  _buildThemeOption(
                    context,
                    ThemeMode.system,
                    'System',
                    'Follow system setting',
                    Icons.settings_suggest,
                    currentTheme == ThemeMode.system,
                    () async {
                      await ThemeService.setThemeMode(ThemeMode.system);
                      ThemeNotifier().updateTheme(ThemeMode.system);
                      setState(() {});
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build theme option widget
  Widget _buildThemeOption(
    BuildContext context,
    ThemeMode themeMode,
    String title,
    String subtitle,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isSelected ? AppThemes.getPrimaryColor(context) : AppThemes.getSecondaryTextColor(context),
        size: 20,
      ),
      title: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          color: isSelected ? AppThemes.getPrimaryColor(context) : AppThemes.getTextColor(context),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.lexend(
          fontSize: 14,
          color: AppThemes.getSecondaryTextColor(context),
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: AppThemes.getPrimaryColor(context), size: 20)
          : null,
      onTap: onTap,
    );
  }

  /// Build data management card
  Widget _buildDataManagementCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.storage,
                color: AppThemes.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Data Management',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppThemes.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.refresh, color: Colors.red, size: 20),
            title: Text(
              'Reset All Data',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            subtitle: Text(
              'Clear all learning data, statistics, and progress',
              style: GoogleFonts.lexend(
                fontSize: 14,
                color: AppThemes.getSecondaryTextColor(context),
              ),
            ),
            onTap: () => _showResetConfirmation(context),
          ),
        ],
      ),
    );
  }

  /// Build app info card
  Widget _buildAppInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppThemes.getPrimaryColor(context),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'App Information',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppThemes.getTextColor(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('App Name', 'LexiLearn'),
          _buildInfoRow('Version', '1.0.0'),
          _buildInfoRow('Developer', 'Mamun'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Made with ',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
              Icon(
                Icons.favorite,
                color: Colors.red,
                size: 16,
              ),
              Text(
                ' by Mamun',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build info row widget
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppThemes.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Show reset confirmation dialog
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reset All Data',
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            'This will permanently delete all your learning statistics, quiz history, progress, favorites, and last quiz scores. This action cannot be undone.\n\nAre you sure you want to continue?',
            style: GoogleFonts.lexend(
              fontSize: 14,
              color: AppThemes.getTextColor(context),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: GoogleFonts.lexend(
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetAllStatistics();
                _showSuccessMessage(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Reset',
                style: GoogleFonts.lexend(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Reset all statistics and learning data
  Future<void> _resetAllStatistics() async {
    // Reset all data
    await FavoritesService.clearFavorites();
    await QuizStateService.clearAllQuizData();
    await LearningStatsService.resetLearningData();
    await FavoritesService.clearLastQuizScore();
  }

  /// Show success message after reset
  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'All data has been reset successfully!',
          style: GoogleFonts.lexend(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

