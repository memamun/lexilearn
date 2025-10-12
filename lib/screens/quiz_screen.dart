import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vocabulary.dart';
import '../services/vocab_loader.dart';
import '../services/favorites_service.dart';
import '../services/quiz_state_service.dart';
import '../services/quiz_settings_service.dart';
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
                backgroundColor: const Color(0xFF1132D4),
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
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: _showLeaveWarning,
        ),
        title: Text(
          'Quiz',
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
          : _vocabularyList.isEmpty
              ? Center(
                  child: Text(
                    'No vocabulary found',
                    style: GoogleFonts.lexend(
                      fontSize: 18,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                )
              : _showResults
                  ? _buildResultsScreen()
                  : _buildQuizScreen(),
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

    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of $_totalQuestions',
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF2C3E50).withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE0E0F8),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1132D4)),
                minHeight: 8,
              ),
            ],
          ),
        ),

        // Question
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
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
                  child: Text(
                    'What is the Bengali meaning of "${_currentQuestion!.word}"?',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Answer options
                Expanded(
                  child: ListView.builder(
                    itemCount: answerOptions.length,
                    itemBuilder: (context, index) {
                      final option = answerOptions[index];
                      final isSelected = _userAnswers[_currentQuestionIndex] == option;

                      Color? backgroundColor;
                      Color? borderColor;
                      Color? textColor;

                      backgroundColor = isSelected 
                          ? const Color(0xFFE0E0F8) 
                          : Colors.white;
                      borderColor = isSelected 
                          ? const Color(0xFF1132D4) 
                          : const Color(0xFFE0E0E0);
                      textColor = const Color(0xFF2C3E50);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectAnswer(option),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: backgroundColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: borderColor, width: 2),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: borderColor, width: 2),
                                      color: isSelected ? borderColor : Colors.transparent,
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check,
                                            size: 12,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      option,
                                      style: GoogleFonts.lexend(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Navigation buttons
                Row(
                  children: [
                    // Previous button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _currentQuestionIndex > 0 
                              ? const Color(0xFF6C757D) 
                              : Colors.grey[300],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Previous',
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
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
                          backgroundColor: const Color(0xFF1132D4),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _currentQuestionIndex < _totalQuestions - 1 ? 'Next' : 'Finish',
                          style: GoogleFonts.lexend(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
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
    String message;
    Color messageColor;

    if (percentage >= 80) {
      message = 'Excellent! You\'re doing great!';
      messageColor = Colors.green;
    } else if (percentage >= 60) {
      message = 'Good job! Keep practicing!';
      messageColor = Colors.orange;
    } else {
      message = 'Keep studying! You\'ll improve!';
      messageColor = Colors.red;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Score circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1132D4).withOpacity(0.1),
                border: Border.all(color: const Color(0xFF1132D4), width: 4),
              ),
              child: Center(
                child: Text(
                  '$score/${_quizWords.length}',
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1132D4),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Score text
            Text(
              'Quiz Complete!',
              style: GoogleFonts.lexend(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'You got $score out of ${_quizWords.length} correct!',
              style: GoogleFonts.lexend(
                fontSize: 18,
                color: const Color(0xFF2C3E50).withOpacity(0.7),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '($percentage%)',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: messageColor,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              message,
              style: GoogleFonts.lexend(
                fontSize: 16,
                color: messageColor,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Study More button
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
                icon: const Icon(Icons.school),
                label: const Text('Study More'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Review button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C757D),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Review Quiz',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Restart button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _restartQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1132D4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Take Another Quiz',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
