import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/favorites_service.dart';
import '../services/quiz_state_service.dart';
import '../services/learning_stats_service.dart';
import '../services/vocab_loader.dart';
import '../utils/app_themes.dart';

/// Statistics screen showing learning progress and data
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _quizStats = {};
  Map<String, dynamic> _learningStats = {};
  List<dynamic> _favorites = [];
  int _totalVocabulary = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// Load all statistics data
  Future<void> _loadStatistics() async {
    try {
      final quizStats = await QuizStateService.getQuizStatistics();
      final learningStats = await LearningStatsService.getLearningStatistics();
      final favorites = await FavoritesService.getFavorites();
      final lastQuizScore = await QuizStateService.getLastQuizScore();
      final totalVocab = await VocabLoader.getVocabularyCount();
      
      // Enhance quiz stats with last quiz score
      final enhancedQuizStats = Map<String, dynamic>.from(quizStats);
      enhancedQuizStats['lastQuizScore'] = lastQuizScore?['score'] ?? 0;
      enhancedQuizStats['lastQuizTotal'] = lastQuizScore?['total'] ?? 0;

      setState(() {
        _quizStats = enhancedQuizStats;
        _learningStats = learningStats;
        _favorites = favorites;
        _totalVocabulary = totalVocab;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }


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
            Icons.arrow_back_ios_rounded,
            color: AppThemes.getTextColor(context),
            size: 20,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: AppThemes.getTextColor(context),
              size: 24,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
          'Statistics',
          style: GoogleFonts.lexend(
            fontSize: 20,
                    fontWeight: FontWeight.w700,
            color: AppThemes.getTextColor(context),
                    letterSpacing: -0.2,
                    height: 1.0,
                  ),
                ),
                Text(
                  'Your learning progress',
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
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppThemes.getPrimaryColor(context)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                children: [
                  // Hero section with overall progress
                  _buildHeroSection(context),
                  
                  const SizedBox(height: 24),
                  
                  // Quick stats grid
                  _buildQuickStatsGrid(context),
                  
                  const SizedBox(height: 24),
                  
                  // Detailed statistics
                  _buildDetailedStats(context),
                  
                  const SizedBox(height: 24),
                  
                  // Recent activity
                  _buildRecentActivity(context),
                ],
              ),
            ),
    );
  }

  /// Build hero section with overall progress
  Widget _buildHeroSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final studiedWords = _learningStats['totalWordsStudied'] ?? 0;
    final knownWords = _learningStats['knownWords'] ?? 0;
    final progressPercentage = _totalVocabulary > 0 ? (studiedWords / _totalVocabulary * 100).round() : 0;
    final accuracy = _quizStats['totalQuestions'] > 0 
        ? ((_quizStats['correctAnswers'] ?? 0) / (_quizStats['totalQuestions'] ?? 1) * 100).round() 
        : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppThemes.getCardColor(context),
                  AppThemes.getSurfaceColor(context),
                ]
              : [
                  AppThemes.getCardColor(context),
                  AppThemes.getSurfaceColor(context),
                ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppThemes.getBorderColor(context).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : AppThemes.getPrimaryColor(context).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Progress circle
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppThemes.getPrimaryColor(context).withOpacity(0.2),
                      AppThemes.getPrimaryColor(context).withOpacity(0.05),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  border: Border.all(
                    color: AppThemes.getPrimaryColor(context).withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: value * (progressPercentage / 100),
                        strokeWidth: 6,
                        backgroundColor: AppThemes.getBorderColor(context).withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(AppThemes.getPrimaryColor(context)),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$progressPercentage%',
                          style: GoogleFonts.lexend(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AppThemes.getTextColor(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Progress',
                          style: GoogleFonts.lexend(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppThemes.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeroStat('Words Studied', studiedWords.toString(), Icons.school),
              _buildHeroStat('Known Words', knownWords.toString(), Icons.check_circle),
              _buildHeroStat('Accuracy', '$accuracy%', Icons.trending_up),
            ],
          ),
        ],
      ),
    );
  }

  /// Build hero stat item
  Widget _buildHeroStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppThemes.getPrimaryColor(context),
          size: 20,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppThemes.getTextColor(context),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppThemes.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

  /// Build quick stats grid
  Widget _buildQuickStatsGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                'Total Words',
                _totalVocabulary.toString(),
                Icons.book_outlined,
                AppThemes.getPrimaryColor(context),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernStatCard(
                'Favorites',
                _favorites.length.toString(),
                Icons.favorite_outline,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildModernStatCard(
                'Quiz Sessions',
                _quizStats['totalQuizzes']?.toString() ?? '0',
                Icons.quiz_outlined,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernStatCard(
                'Words Studied',
                _learningStats['totalWordsStudied']?.toString() ?? '0',
                Icons.school_outlined,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build modern stat card
  Widget _buildModernStatCard(String title, String value, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
      children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
        ),
        const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppThemes.getTextColor(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppThemes.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
            ),
          ],
        ),
    );
  }

  /// Build detailed statistics
  Widget _buildDetailedStats(BuildContext context) {
    final totalQuestions = _quizStats['totalQuestions'] ?? 0;
    final correctAnswers = _quizStats['correctAnswers'] ?? 0;
    final wrongAnswers = _quizStats['wrongAnswers'] ?? 0;
    final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions * 100).round() : 0;
    final knownWords = _learningStats['knownWords'] ?? 0;
    final unknownWords = _learningStats['unknownWords'] ?? 0;
    final reviewWords = _learningStats['wordsForReview'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            ),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text(
            'Detailed Statistics',
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppThemes.getTextColor(context),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 24),
          
          // Quiz performance
          _buildDetailSection(
            'Quiz Performance',
            Icons.quiz_outlined,
            AppThemes.getPrimaryColor(context),
            [
              _buildDetailItem('Total Questions', totalQuestions.toString()),
              _buildDetailItem('Correct Answers', correctAnswers.toString()),
              _buildDetailItem('Wrong Answers', wrongAnswers.toString()),
              _buildDetailItem('Accuracy', '$accuracy%', 
                  accuracy >= 80 ? Colors.green : accuracy >= 60 ? Colors.orange : Colors.red),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Learning progress
          _buildDetailSection(
            'Learning Progress',
            Icons.school_outlined,
            Colors.green,
            [
              _buildDetailItem('Known Words', knownWords.toString()),
              _buildDetailItem('Unknown Words', unknownWords.toString()),
              _buildDetailItem('Review Words', reviewWords.toString()),
              _buildDetailItem('Total Studied', (knownWords + unknownWords).toString()),
          ],
        ),
      ],
      ),
    );
  }

  /// Build detail section
  Widget _buildDetailSection(String title, IconData icon, Color color, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppThemes.getTextColor(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...items,
      ],
    );
  }

  /// Build detail item
  Widget _buildDetailItem(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              color: valueColor ?? AppThemes.getTextColor(context),
            ),
          ),
        ],
      ),
    );
  }

  /// Build recent activity
  Widget _buildRecentActivity(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.lexend(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppThemes.getTextColor(context),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          
          _buildActivityItem(
            Icons.quiz_outlined,
            'Last Quiz Score',
            '${_quizStats['lastQuizScore'] ?? 0}/${_quizStats['lastQuizTotal'] ?? 0} correct',
            AppThemes.getPrimaryColor(context),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            Icons.school_outlined,
            'Words Studied Today',
            '${_learningStats['wordsStudiedToday'] ?? 0} words',
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            Icons.favorite_outline,
            'Favorite Words',
            '${_favorites.length} words marked',
            Colors.red,
          ),
        ],
      ),
    );
  }

  /// Build activity item
  Widget _buildActivityItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppThemes.getTextColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
