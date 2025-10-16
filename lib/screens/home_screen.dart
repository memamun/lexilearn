import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'flashcard_screen.dart';
import 'quiz_screen.dart';
import 'vocab_list_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import '../services/quiz_state_service.dart';
import '../services/learning_stats_service.dart';
import '../utils/app_themes.dart';
import '../services/vocab_loader.dart';

/// Home screen with main navigation buttons
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppThemes.getBackgroundColor(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Icon(
              Icons.psychology_outlined,
              color: AppThemes.getTextColor(context),
              size: 24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LexiLearn',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppThemes.getTextColor(context),
                    letterSpacing: 0.2,
                    height: 1.0,
                  ),
                ),
                Text(
                  'Lets learn new words today',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppThemes.getSecondaryTextColor(context),
                    letterSpacing: 0.1,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: AppThemes.getTextColor(context),
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.person_outline,
              color: AppThemes.getTextColor(context),
              size: 22,
            ),
            onPressed: () {
              // Add profile functionality
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            children: [
              // Word of the Day Section
              _buildWordOfTheDaySection(context),
              const SizedBox(height: 20),
              
              // Daily Goal Section
              _buildDailyGoalSection(context),
              const SizedBox(height: 20),
              
              // Main navigation grid
              _buildNavigationGrid(context),
              
              const SizedBox(height: 20),
              
              // Progress Snapshot Section
              // _buildProgressSnapshot(context),
              //       const SizedBox(height: 16),
              
              // Made with love footer
              _buildMadeWithLoveFooter(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
      decoration: BoxDecoration(
          color: AppThemes.getCardColor(context),
        boxShadow: [
          BoxShadow(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
            blurRadius: 8,
              offset: const Offset(0, -2),
          ),
        ],
      ),
        child: BottomNavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppThemes.getPrimaryColor(context),
          unselectedItemColor: AppThemes.getSecondaryTextColor(context),
          selectedLabelStyle: GoogleFonts.lexend(
            fontSize: 12,
                            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          currentIndex: 0, // Home is selected
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_outlined),
              activeIcon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              activeIcon: Icon(Icons.favorite),
              label: 'Favorites',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          onTap: (index) {
            // Handle navigation
            switch (index) {
              case 0:
                // Already on home
                break;
              case 1:
                // Navigate to discover (could be vocab list)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VocabListScreen()),
                );
                break;
              case 2:
                // Navigate to search (could be vocab list with search)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VocabListScreen()),
                );
                break;
              case 3:
                // Navigate to favorites
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VocabListScreen()),
                );
                break;
              case 4:
                // Navigate to profile (could be statistics)
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                );
                break;
            }
          },
        ),
      ),
    );
  }






  /// Build daily goal section
  Widget _buildDailyGoalSection(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getQuickStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final wordsStudiedToday = stats['wordsStudiedToday'] ?? 0;
        final dailyGoal = 20;
        final progress = (wordsStudiedToday / dailyGoal).clamp(0.0, 1.0);
        
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
              Text(
                'DAILY GOAL',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppThemes.getTextColor(context),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '$wordsStudiedToday/$dailyGoal',
                    style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppThemes.getTextColor(context),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        color: Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '5 Streak',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppThemes.getBorderColor(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppThemes.getPrimaryColor(context),
                          AppThemes.getPrimaryColor(context).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lets learn new words today',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }





  /// Build responsive navigation grid
  Widget _buildNavigationGrid(BuildContext context) {
    return Column(
      children: [
        // Flashcards - Primary large card (full width)
        _buildLargeCard(
          context: context,
          icon: Icons.style,
          title: 'Flashcards',
          subtitle: 'New Words Learned',
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue, Colors.purple],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FlashcardScreen()),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Three smaller cards in a row with flexible height
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(
                child: _buildSmallCard(
                  context: context,
                  icon: Icons.quiz,
                  title: 'Quiz',
                  subtitle: 'Test yourself',
                  color: Colors.green,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const QuizScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallCard(
                  context: context,
                  icon: Icons.library_books,
                  title: 'Vocablist',
                  subtitle: 'Browse words',
                  color: Colors.orange,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const VocabListScreen()),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSmallCard(
                  context: context,
                  icon: Icons.analytics,
                  title: 'Statistics',
                  subtitle: 'Progress',
                  color: Colors.purple,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build large card (full width)
  Widget _buildLargeCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.lexend(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: GoogleFonts.lexend(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withOpacity(0.9),
                          letterSpacing: 0.2,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build small card
  Widget _buildSmallCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon at the top center
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                // Title
                Text(
                  title,
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Subtitle
                Text(
                  subtitle,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.85),
                    letterSpacing: 0.1,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  /// Get quick stats data
  Future<Map<String, dynamic>> _getQuickStats() async {
    try {
      final learningStats = await LearningStatsService.getLearningStatistics();
      final lastQuizScore = await QuizStateService.getLastQuizScore();
      final vocabCount = await VocabLoader.getVocabularyCount();
      
      return {
        'wordsStudiedToday': learningStats['wordsStudiedToday'] ?? 0,
        'totalWords': vocabCount,
        'lastQuizScore': lastQuizScore?['percentage'] ?? 0,
      };
    } catch (e) {
      return {
        'wordsStudiedToday': 0,
        'totalWords': 0,
        'lastQuizScore': 0,
      };
    }
  }

  /// Build word of the day section
  Widget _buildWordOfTheDaySection(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getWordOfTheDay(),
      builder: (context, snapshot) {
        final wordData = snapshot.data ?? {};
        final word = wordData['word'] ?? 'Serendipity';
        final meaning = wordData['meaning'] ?? 'The occurrence of events by chance in a happy way';
        final pronunciation = wordData['pronunciation'] ?? '/ˌserənˈdipədē/';
        
        return SizedBox(
          width: double.infinity,
          child: Container(
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
                    Icons.auto_awesome,
                    color: AppThemes.getPrimaryColor(context),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'WORD OF THE DAY',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppThemes.getTextColor(context),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                word,
                style: GoogleFonts.lexend(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppThemes.getTextColor(context),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pronunciation,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppThemes.getSecondaryTextColor(context),
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                meaning,
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppThemes.getTextColor(context),
                  letterSpacing: 0.1,
                  height: 1.3,
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  /// Get word of the day data
  Future<Map<String, dynamic>> _getWordOfTheDay() async {
    try {
      // For now, return a static word. In a real app, this would fetch from an API
      // or use a predefined list with date-based selection
      final words = [
        {
          'word': 'Serendipity',
          'pronunciation': '/ˌserənˈdipədē/',
          'meaning': 'The occurrence of events by chance in a happy way',
        },
        {
          'word': 'Ephemeral',
          'pronunciation': '/əˈfem(ə)rəl/',
          'meaning': 'Lasting for a very short time',
        },
        {
          'word': 'Ubiquitous',
          'pronunciation': '/yo͞oˈbikwədəs/',
          'meaning': 'Present, appearing, or found everywhere',
        },
        {
          'word': 'Mellifluous',
          'pronunciation': '/məˈliflo͞oəs/',
          'meaning': 'Sweet or musical; pleasant to hear',
        },
        {
          'word': 'Petrichor',
          'pronunciation': '/ˈpetrəˌkôr/',
          'meaning': 'The pleasant smell of earth after rain',
        },
      ];
      
      // Use date to select a consistent word for the day
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final selectedWord = words[dayOfYear % words.length];
      
      return selectedWord;
    } catch (e) {
      return {
        'word': 'Serendipity',
        'pronunciation': '/ˌserənˈdipədē/',
        'meaning': 'The occurrence of events by chance in a happy way',
      };
    }
  }

  /// Build made with love footer
  Widget _buildMadeWithLoveFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
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
    );
  }
}

