import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/favorites_service.dart';
import '../services/quiz_state_service.dart';
import '../services/learning_stats_service.dart';
import '../services/vocab_loader.dart';

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
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Statistics',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Section
                  _buildSectionHeader('Overview'),
                  _buildOverviewCards(),
                  
                  const SizedBox(height: 24),
                  
                  // Quiz Statistics
                  _buildSectionHeader('Quiz Performance'),
                  _buildQuizStatsCards(),
                  
                  const SizedBox(height: 24),
                  
                  // Learning Progress
                  _buildSectionHeader('Learning Progress'),
                  _buildLearningProgressCards(),
                  
                  const SizedBox(height: 24),
                  
                  // Vocabulary Progress
                  _buildSectionHeader('Vocabulary Progress'),
                  _buildVocabularyProgressCards(),
                  
                  const SizedBox(height: 24),
                  
                  // Recent Activity
                  _buildSectionHeader('Recent Activity'),
                  _buildRecentActivityCard(),
                ],
              ),
            ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2C3E50),
        ),
      ),
    );
  }

  /// Build overview cards
  Widget _buildOverviewCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Words',
                _totalVocabulary.toString(),
                Icons.book,
                const Color(0xFF1132D4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Favorites',
                _favorites.length.toString(),
                Icons.favorite,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Quiz Sessions',
                _quizStats['totalQuizzes']?.toString() ?? '0',
                Icons.quiz,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Words Studied',
                _learningStats['totalWordsStudied']?.toString() ?? '0',
                Icons.school,
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build quiz statistics cards
  Widget _buildQuizStatsCards() {
    final totalQuestions = _quizStats['totalQuestions'] ?? 0;
    final correctAnswers = _quizStats['correctAnswers'] ?? 0;
    final wrongAnswers = _quizStats['wrongAnswers'] ?? 0;
    final accuracy = totalQuestions > 0 ? (correctAnswers / totalQuestions * 100).round() : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Questions',
                totalQuestions.toString(),
                Icons.help_outline,
                const Color(0xFF1132D4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Correct Answers',
                correctAnswers.toString(),
                Icons.check_circle,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Wrong Answers',
                wrongAnswers.toString(),
                Icons.cancel,
                Colors.red,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Accuracy',
                '$accuracy%',
                Icons.trending_up,
                accuracy >= 80 ? Colors.green : accuracy >= 60 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build learning progress cards
  Widget _buildLearningProgressCards() {
    final knownWords = _learningStats['knownWords'] ?? 0;
    final unknownWords = _learningStats['unknownWords'] ?? 0;
    final reviewWords = _learningStats['wordsForReview'] ?? 0;
    final totalStudied = knownWords + unknownWords;
    final progressPercentage = _totalVocabulary > 0 ? (totalStudied / _totalVocabulary * 100).round() : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Known Words',
                knownWords.toString(),
                Icons.check_circle_outline,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Unknown Words',
                unknownWords.toString(),
                Icons.help_outline,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Review Words',
                reviewWords.toString(),
                Icons.refresh,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Progress',
                '$progressPercentage%',
                Icons.trending_up,
                progressPercentage >= 80 ? Colors.green : progressPercentage >= 50 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Build vocabulary progress cards
  Widget _buildVocabularyProgressCards() {
    final studiedWords = _learningStats['totalWordsStudied'] ?? 0;
    final remainingWords = _totalVocabulary - studiedWords;
    final completionRate = _totalVocabulary > 0 ? (studiedWords / _totalVocabulary * 100).round() : 0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Studied Words',
                studiedWords.toString(),
                Icons.school,
                const Color(0xFF1132D4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Remaining Words',
                remainingWords.toString(),
                Icons.pending,
                Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildProgressCard(completionRate),
      ],
    );
  }

  /// Build progress card with circular progress
  Widget _buildProgressCard(int percentage) {
    final studiedWords = _learningStats['totalWordsStudied'] ?? 0;
    final knownWords = _learningStats['knownWords'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Overall Progress',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$studiedWords of $_totalVocabulary words studied',
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage >= 80 ? Colors.green : percentage >= 50 ? Colors.orange : Colors.red,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percentage%',
                    style: GoogleFonts.lexend(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  Text(
                    '$knownWords known',
                    style: GoogleFonts.lexend(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build recent activity card
  Widget _buildRecentActivityCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            Icons.quiz,
            'Last Quiz',
            '${_quizStats['lastQuizScore'] ?? 0}/${_quizStats['lastQuizTotal'] ?? 0} correct',
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            Icons.school,
            'Words Studied Today',
            '${_learningStats['wordsStudiedToday'] ?? 0} words',
            Colors.green,
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            Icons.favorite,
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
          width: 40,
          height: 40,
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
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build individual stat card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
