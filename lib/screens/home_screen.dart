import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'favorites_screen.dart';
import 'vocab_list_screen.dart';
import 'statistics_screen.dart';
import '../services/favorites_service.dart';
import '../services/quiz_state_service.dart';
import '../services/learning_stats_service.dart';
import '../services/quiz_settings_service.dart';

/// Home screen with main navigation buttons
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F8),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF2C3E50)),
            onPressed: () {
              _showSettingsDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Header with app title
              const SizedBox(height: 40),
              Text(
                'LexiLearn',
                style: GoogleFonts.lexend(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2C3E50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),
              
              // Main navigation buttons
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Flashcards button (primary)
                    _buildMainButton(
                      context: context,
                      icon: Icons.style,
                      title: 'Flashcards',
                      subtitle: 'Learn with interactive cards',
                      isPrimary: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FlashcardScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quiz button (secondary)
                    _buildMainButton(
                      context: context,
                      icon: Icons.quiz,
                      title: 'Quiz',
                      subtitle: 'Test your knowledge',
                      isPrimary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QuizScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Favorites button (secondary)
                    _buildMainButton(
                      context: context,
                      icon: Icons.favorite,
                      title: 'Favorites',
                      subtitle: 'Review saved words',
                      isPrimary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoritesScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Vocabulary List button (secondary)
                    _buildMainButton(
                      context: context,
                      icon: Icons.list_alt,
                      title: 'Vocabulary List',
                      subtitle: 'Browse all words with search',
                      isPrimary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const VocabListScreen(),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Statistics button (secondary)
                    _buildMainButton(
                      context: context,
                      icon: Icons.analytics,
                      title: 'Statistics',
                      subtitle: 'View your learning progress',
                      isPrimary: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StatisticsScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a main navigation button
  Widget _buildMainButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        color: isPrimary 
            ? const Color(0xFF1132D4) 
            : const Color(0xFFE0E0F8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isPrimary 
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF1132D4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary 
                        ? Colors.white 
                        : const Color(0xFF1132D4),
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.lexend(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isPrimary 
                                ? Colors.white 
                                : const Color(0xFF1132D4),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: Text(
                          subtitle,
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isPrimary 
                                ? Colors.white.withOpacity(0.8)
                                : const Color(0xFF1132D4).withOpacity(0.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: isPrimary 
                      ? Colors.white.withOpacity(0.7)
                      : const Color(0xFF1132D4).withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show settings dialog
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Settings',
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.quiz, color: Color(0xFF1132D4)),
                title: Text(
                  'Quiz Settings',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Set number of questions per quiz',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showQuizSettingsDialog(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.red),
                title: Text(
                  'Reset Statistics',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Clear all learning data and statistics',
                  style: GoogleFonts.lexend(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showResetConfirmation(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.lexend(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Show quiz settings dialog
  void _showQuizSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FutureBuilder<int>(
              future: QuizSettingsService.getQuestionCount(),
              builder: (context, snapshot) {
                int currentCount = snapshot.data ?? 5;
                
                return AlertDialog(
                  title: Text(
                    'Quiz Settings',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Number of Questions per Quiz',
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
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
                                    ? const Color(0xFF1132D4) 
                                    : const Color(0xFFF5F5F5),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected 
                                      ? const Color(0xFF1132D4) 
                                      : const Color(0xFFE0E0E0),
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
                                      : const Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Current setting: $currentCount questions',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Done',
                        style: GoogleFonts.lexend(
                          color: const Color(0xFF1132D4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Show reset confirmation dialog
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Reset Statistics',
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
              color: const Color(0xFF2C3E50),
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
          'All statistics have been reset successfully!',
          style: GoogleFonts.lexend(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
