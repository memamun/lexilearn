import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vocabulary.dart';
import '../services/vocab_loader.dart';
import '../services/favorites_service.dart';
import '../services/quiz_state_service.dart';
import '../services/quiz_settings_service.dart';
import '../utils/app_themes.dart';
import 'answer_sheet_screen.dart';
import 'flashcard_screen.dart';

/// Quiz screen for testing vocabulary knowledge
class QuizScreen extends StatefulWidget {
  final List<Vocabulary>? vocabularySet;
  final bool isFromFlashcard;
  
  const QuizScreen({super.key, this.vocabularySet, this.isFromFlashcard = false});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Vocabulary> _vocabularyList = [];
  List<Vocabulary> _quizWords = [];
  int _currentQuestionIndex = 0;
  int _totalQuestions = 5;
  bool _isLoading = true;
  bool _showResults = false;
  
  // Store user answers for each question
  Map<int, String?> _userAnswers = {};
  
  // Store correct answers for review
  Map<int, String> _correctAnswers = {};
  
  // Store answer options for each question to prevent them from changing
  Map<int, List<String>> _questionOptions = {};

  @override
  void initState() {
    super.initState();
    _loadQuizSettings();
  }

  /// Load quiz settings and then create quiz
  Future<void> _loadQuizSettings() async {
    try {
      int questionCount;
      
      if (widget.isFromFlashcard) {
        // Always use 20 questions when coming from flashcard screen
        questionCount = 20;
      } else {
        // Use user's setting for other cases
        questionCount = await QuizSettingsService.getQuestionCount();
      }
      
      setState(() {
        _totalQuestions = questionCount;
      });
      await _loadQuiz();
    } catch (e) {
      await _loadQuiz(); // Fallback to default
    }
  }

  /// Load vocabulary and create quiz
  Future<void> _loadQuiz() async {
    try {
      List<Vocabulary> vocabList;
      
      if (widget.vocabularySet != null && widget.vocabularySet!.isNotEmpty) {
        // Use provided vocabulary set
        vocabList = widget.vocabularySet!;
      } else {
        // Load all vocabulary
        vocabList = await VocabLoader.loadVocabulary();
      }
      
      setState(() {
        _vocabularyList = vocabList;
        _isLoading = false;
      });
      await _createQuiz();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load vocabulary');
    }
  }

  /// Create a new quiz with robust question selection
  Future<void> _createQuiz() async {
    if (_vocabularyList.isEmpty) return;

    try {
      List<Vocabulary> availableQuestions;
      
      if (widget.vocabularySet != null && widget.vocabularySet!.isNotEmpty) {
        // Use the provided vocabulary set directly but limit to appropriate count
        availableQuestions = List<Vocabulary>.from(_vocabularyList);
        // Remove any potential duplicates by using word as unique identifier
        final uniqueQuestions = <String, Vocabulary>{};
        for (final vocab in availableQuestions) {
          uniqueQuestions[vocab.word] = vocab;
        }
        availableQuestions = uniqueQuestions.values.toList();
        availableQuestions.shuffle();
        // Limit to appropriate question count (20 for flashcard, user setting for others)
        if (availableQuestions.length > _totalQuestions) {
          availableQuestions = availableQuestions.take(_totalQuestions).toList();
        }
      } else {
        // Get available questions using robust state management with settings
        availableQuestions = await QuizStateService.getAvailableQuestions(
          _vocabularyList,
          _totalQuestions,
        );
      }
      
      if (availableQuestions.isEmpty) {
        _showErrorSnackBar('No questions available. Please try again later.');
        return;
      }
      
      _userAnswers.clear();
      _correctAnswers.clear();
      _questionOptions.clear();
      
      setState(() {
        _quizWords = availableQuestions;
        // Keep the user's preferred question count, don't override it
        _currentQuestionIndex = 0;
        _showResults = false;
      });
      
      // Store correct answers and generate options for each question
      for (int i = 0; i < _quizWords.length; i++) {
        _correctAnswers[i] = _quizWords[i].bengaliMeaning;
        _questionOptions[i] = _generateOptionsForQuestion(i);
      }
      
      // Clear last session to prepare for new quiz
      await QuizStateService.clearLastQuizSession();
      
    } catch (e) {
      _showErrorSnackBar('Failed to create quiz. Please try again.');
      print('Error creating quiz: $e');
    }
  }

  /// Get current question
  Vocabulary? get _currentQuestion {
    if (_quizWords.isEmpty || _currentQuestionIndex >= _quizWords.length) {
      return null;
    }
    return _quizWords[_currentQuestionIndex];
  }

  /// Generate answer options for a specific question
  List<String> _generateOptionsForQuestion(int questionIndex) {
    if (questionIndex >= _quizWords.length) return [];
    
    final correctAnswer = _quizWords[questionIndex].bengaliMeaning;
    
    // Get all unique Bengali meanings from the vocabulary list
    final allMeanings = _vocabularyList
        .where((v) => v.word != _quizWords[questionIndex].word)
        .map((v) => v.bengaliMeaning)
        .toSet() // Remove duplicates
        .toList();
    
    // Ensure we have enough wrong answers
    if (allMeanings.length < 3) {
      // If not enough unique meanings, add some generic options
      final genericOptions = ['অজানা', 'অনিশ্চিত', 'অনুপস্থিত'];
      allMeanings.addAll(genericOptions);
    }
    
    // Get 3 random wrong answers (ensure they're different from correct answer)
    allMeanings.shuffle();
    final wrongAnswers = allMeanings
        .where((meaning) => meaning != correctAnswer)
        .take(3)
        .toList();
    
    // If we still don't have 3 unique wrong answers, add some generic ones
    while (wrongAnswers.length < 3) {
      final genericOptions = ['অজানা', 'অনিশ্চিত', 'অনুপস্থিত', 'অন্যান্য'];
      for (final option in genericOptions) {
        if (!wrongAnswers.contains(option) && option != correctAnswer) {
          wrongAnswers.add(option);
          if (wrongAnswers.length >= 3) break;
        }
      }
    }
    
    // Combine correct and wrong answers
    final options = [correctAnswer, ...wrongAnswers.take(3)];
    options.shuffle();
    
    return options;
  }

  /// Get answer options for current question
  List<String> get _answerOptions {
    if (_currentQuestion == null) return [];
    return _questionOptions[_currentQuestionIndex] ?? [];
  }

  /// Select an answer for current question
  void _selectAnswer(String answer) {
    HapticFeedback.lightImpact(); // Add haptic feedback for selection
    setState(() {
      _userAnswers[_currentQuestionIndex] = answer;
    });
  }

  /// Move to next question
  void _nextQuestion() {
    if (_currentQuestionIndex < _totalQuestions - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _checkAndSubmitQuiz();
    }
  }

  /// Check if all questions are answered and submit accordingly
  void _checkAndSubmitQuiz() {
    int answeredQuestions = 0;
    for (int i = 0; i < _quizWords.length; i++) {
      if (_userAnswers[i] != null) {
        answeredQuestions++;
      }
    }

    if (answeredQuestions < _quizWords.length) {
      _showIncompleteWarning();
    } else {
      _submitQuizDirectly();
    }
  }

  /// Show warning for incomplete answers
  void _showIncompleteWarning() {
    int unanswered = _quizWords.length - _userAnswers.values.where((answer) => answer != null).length;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Incomplete Quiz',
            style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'You have $unanswered unanswered question(s). Are you sure you want to submit now?',
            style: GoogleFonts.lexend(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Continue Quiz',
                style: GoogleFonts.lexend(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitQuizDirectly();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.getPrimaryColor(context),
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Submit Anyway',
                style: GoogleFonts.lexend(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Submit quiz directly to results
  Future<void> _submitQuizDirectly() async {
    int score = 0;
    for (int i = 0; i < _quizWords.length; i++) {
      if (_userAnswers[i] == _correctAnswers[i]) {
        score++;
      }
    }
    
    final wrongAnswers = _quizWords.length - score;
    final percentage = (score / _quizWords.length) * 100;
    
    // Save quiz results using robust state management
    await QuizStateService.saveQuizResults(
      quizQuestions: _quizWords,
      userAnswers: _userAnswers,
      correctAnswers: _correctAnswers,
    );
    
    // Save detailed statistics
    await QuizStateService.saveQuizStats(
      totalQuestions: _quizWords.length,
      correctAnswers: score,
      wrongAnswers: wrongAnswers,
      percentage: percentage,
    );
    
    setState(() {
      _showResults = true;
    });
    
    _saveScore(score);
  }

  /// Move to previous question
  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }


  /// Save quiz score
  Future<void> _saveScore(int score) async {
    await FavoritesService.saveLastQuizScore(score, _quizWords.length);
  }

  /// Show warning dialog when leaving quiz
  void _showLeaveWarning() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Leave Quiz?',
            style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Your progress will be lost if you leave now. Are you sure?',
            style: GoogleFonts.lexend(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Stay',
                style: GoogleFonts.lexend(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Leave',
                style: GoogleFonts.lexend(),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Restart quiz
  Future<void> _restartQuiz() async {
    await _createQuiz();
  }

  /// Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showResults) {
          Navigator.pop(context);
          return false;
        } else {
          _showLeaveWarning();
          return false;
        }
      },
      child: Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppThemes.getBackgroundColor(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: AppThemes.getTextColor(context),
                size: 20,
              ),
              onPressed: _showLeaveWarning,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Quiz',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppThemes.getTextColor(context),
                      letterSpacing: 0.2,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    'Test your vocabulary knowledge',
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
            ),
          ],
        ),
        actions: [
          if (!_showResults)
            IconButton(
              icon: Icon(
                Icons.refresh_outlined,
                color: AppThemes.getTextColor(context),
                size: 22,
              ),
              onPressed: () {
                _restartQuiz();
              },
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppThemes.getPrimaryColor(context)),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Preparing your quiz...',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppThemes.getSecondaryTextColor(context),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              )
            : _vocabularyList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: AppThemes.getSecondaryTextColor(context).withOpacity(0.3),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No vocabulary found',
                          style: GoogleFonts.lexend(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppThemes.getTextColor(context),
                            letterSpacing: 0.2,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please try refreshing the app',
                          style: GoogleFonts.lexend(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: AppThemes.getSecondaryTextColor(context),
                            letterSpacing: 0.1,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                : _showResults
                    ? _buildResultsScreen()
                    : _buildQuizScreen(),
      ),
      ),
    );
  }

  /// Build the quiz screen
  Widget _buildQuizScreen() {
    if (_currentQuestion == null) {
      return const Center(child: Text('No questions available'));
    }

    final progress = (_currentQuestionIndex + 1) / _totalQuestions;
    final answerOptions = _answerOptions;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppThemes.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentQuestionIndex + 1} of $_totalQuestions',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppThemes.getTextColor(context),
                        letterSpacing: 0.1,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: GoogleFonts.lexend(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : AppThemes.getPrimaryColor(context),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(AppThemes.getPrimaryColor(context)),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Question
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppThemes.getCardColor(context),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What is the Bengali meaning of:',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppThemes.getSecondaryTextColor(context),
                    letterSpacing: 0.1,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _currentQuestion!.word,
                  style: GoogleFonts.lexend(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppThemes.getTextColor(context),
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Answer options
          ...answerOptions.map((option) {
            final isSelected = _userAnswers[_currentQuestionIndex] == option;

            Color? backgroundColor;
            Color? borderColor;
            Color? textColor;

            backgroundColor = isSelected 
                ? AppThemes.getPrimaryColor(context)
                : AppThemes.getCardColor(context);
            borderColor = isSelected 
                ? AppThemes.getPrimaryColor(context)
                : Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.2)
                    : AppThemes.getBorderColor(context);
            textColor = isSelected 
                ? Colors.white
                : AppThemes.getTextColor(context);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _selectAnswer(option),
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 2),
                      boxShadow: [
                        if (isSelected) ...[
                          BoxShadow(
                            color: AppThemes.getPrimaryColor(context).withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                          BoxShadow(
                            color: AppThemes.getPrimaryColor(context).withOpacity(0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ] else ...[
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.3)
                                : Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected 
                                  ? Theme.of(context).brightness == Brightness.dark
                                      ? Colors.orange
                                      : Colors.green
                                  : Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.6)
                                      : AppThemes.getPrimaryColor(context).withOpacity(0.5), 
                              width: isSelected ? 3 : 2,
                            ),
                            color: isSelected 
                                ? Theme.of(context).brightness == Brightness.dark
                                    ? Colors.orange
                                    : Colors.green
                                : Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.1)
                                    : Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                    ? Colors.green.withOpacity(0.4)
                                    : Theme.of(context).brightness == Brightness.dark
                                        ? Colors.black.withOpacity(0.3)
                                        : AppThemes.getPrimaryColor(context).withOpacity(0.1),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.white,
                                )
                              : Icon(
                                  Icons.radio_button_unchecked,
                                  size: 16,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.7)
                                      : AppThemes.getPrimaryColor(context).withOpacity(0.6),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: isSelected ? 20 : 18,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: textColor,
                              letterSpacing: isSelected ? 0.2 : 0.1,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),

          const SizedBox(height: 32),

          // Navigation buttons
          Row(
            children: [
              // Previous button
              Expanded(
                child: ElevatedButton(
                  onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _currentQuestionIndex > 0 
                        ? AppThemes.getSecondaryTextColor(context) 
                        : AppThemes.getSecondaryTextColor(context).withOpacity(0.3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: _currentQuestionIndex > 0 
                        ? AppThemes.getSecondaryTextColor(context).withOpacity(0.3)
                        : Colors.transparent,
                  ),
                  child: Text(
                    'Previous',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Next button
              Expanded(
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemes.getPrimaryColor(context),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: AppThemes.getPrimaryColor(context).withOpacity(0.3),
                  ),
                  child: Text(
                    _currentQuestionIndex < _totalQuestions - 1 ? 'Next' : 'Finish',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }


  /// Build results screen
  Widget _buildResultsScreen() {
    // Calculate score from user answers
    int score = 0;
    for (int i = 0; i < _quizWords.length; i++) {
      if (_userAnswers[i] == _correctAnswers[i]) {
        score++;
      }
    }
    
    final percentage = (score / _quizWords.length * 100).round();
    final isExcellent = percentage >= 80;
    final isGood = percentage >= 60;
    
    String message;
    String subtitle;
    Color accentColor;
    Color accentLight;
    Color accentDark;

    if (isExcellent) {
      message = 'Outstanding!';
      subtitle = 'You\'ve mastered this quiz!';
      accentColor = AppThemes.getSuccessColor(context);
      accentLight = AppThemes.getSuccessLightColor(context);
      accentDark = AppThemes.getSuccessDarkColor(context);
    } else if (isGood) {
      message = 'Well Done!';
      subtitle = 'Great progress, keep it up!';
      accentColor = AppThemes.getWarningColor(context);
      accentLight = AppThemes.getWarningLightColor(context);
      accentDark = AppThemes.getWarningDarkColor(context);
    } else {
      message = 'Keep Learning!';
      subtitle = 'Practice makes perfect!';
      accentColor = AppThemes.getPrimaryColor(context);
      accentLight = AppThemes.getSelectionColor(context);
      accentDark = AppThemes.getPrimaryColor(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        children: [
          // Hero section with modern card design
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        AppThemes.getCardColor(context),
                        AppThemes.getSurfaceColor(context),
                      ]
                    : [
                        AppThemes.getCardColor(context),
                        AppThemes.getSurfaceColor(context),
                      ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: AppThemes.getBorderColor(context).withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.4)
                      : accentColor.withOpacity(0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.2)
                      : AppThemes.getTextColor(context).withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                // Modern score display with glassmorphism
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: Theme.of(context).brightness == Brightness.dark
                              ? [
                                  accentColor.withOpacity(0.2),
                                  accentColor.withOpacity(0.08),
                                  Colors.transparent,
                                ]
                              : [
                                  accentLight.withOpacity(0.6),
                                  accentColor.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                          stops: const [0.0, 0.7, 1.0],
                        ),
                        border: Border.all(
                          color: accentColor.withOpacity(0.3),
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: accentColor.withOpacity(0.15),
                            blurRadius: 40,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.black.withOpacity(0.3)
                                : accentColor.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Animated progress ring
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: value * (score / _quizWords.length),
                              strokeWidth: 8,
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? accentColor.withOpacity(0.15)
                                  : accentLight.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                            ),
                          ),
                          // Score content
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: score.toDouble()),
                                duration: const Duration(milliseconds: 2000),
                                curve: Curves.easeOutCubic,
                                builder: (context, animatedScore, child) {
                                  return Text(
                                    '${animatedScore.round()}',
                                    style: GoogleFonts.lexend(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white
                                          : accentDark,
                                      letterSpacing: -1.5,
                                      height: 1.0,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'out of ${_quizWords.length}',
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white.withOpacity(0.7)
                                      : accentDark.withOpacity(0.6),
                                  letterSpacing: 0.2,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Modern title with better typography
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: Column(
                          children: [
                            Text(
                              message,
                              style: GoogleFonts.lexend(
                                fontSize: 42,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : accentDark,
                                letterSpacing: -1.0,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitle,
                              style: GoogleFonts.lexend(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white.withOpacity(0.8)
                                    : accentDark.withOpacity(0.7),
                                letterSpacing: 0.1,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Modern percentage badge
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 1800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: Theme.of(context).brightness == Brightness.dark
                                ? [
                                    accentColor.withOpacity(0.2),
                                    accentColor.withOpacity(0.1),
                                  ]
                                : [
                                    accentLight.withOpacity(0.8),
                                    accentColor.withOpacity(0.1),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: accentColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accentColor.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.black.withOpacity(0.3)
                                  : accentColor.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: percentage.toDouble()),
                          duration: const Duration(milliseconds: 2500),
                          curve: Curves.easeOutCubic,
                          builder: (context, animatedPercentage, child) {
                            return Text(
                              '${animatedPercentage.round()}%',
                              style: GoogleFonts.lexend(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : accentDark,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Modern action buttons with better spacing
                Column(
                  children: [
                    // Primary action button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FlashcardScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.school_rounded, size: 24),
                        label: const Text('Continue Learning'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          shadowColor: accentColor.withOpacity(0.4),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Secondary action button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AnswerSheetScreen(
                                quizWords: _quizWords,
                                userAnswers: _userAnswers,
                                correctAnswers: _correctAnswers,
                                questionOptions: _questionOptions,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.quiz_rounded, size: 24),
                        label: const Text('Review Answers'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : accentDark,
                          side: BorderSide(
                            color: accentColor.withOpacity(0.4),
                            width: 1.5,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

}
