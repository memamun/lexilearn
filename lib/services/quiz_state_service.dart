import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary.dart';

/// Service for managing quiz state and question tracking
/// All data is stored locally using SharedPreferences
class QuizStateService {
  // SharedPreferences keys for local storage
  static const String _quizHistoryKey = 'quiz_history';
  static const String _wrongAnswersKey = 'wrong_answers';
  static const String _lastQuizSessionKey = 'last_quiz_session';
  static const String _quizStatsKey = 'quiz_stats';
  
  /// Get quiz history (questions used in previous sessions)
  static Future<List<String>> getQuizHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyString = prefs.getString(_quizHistoryKey);
    if (historyString == null) return [];
    
    try {
      final List<dynamic> historyList = json.decode(historyString);
      return historyList.cast<String>();
    } catch (e) {
      return [];
    }
  }
  
  /// Add questions to quiz history
  static Future<void> addToQuizHistory(List<String> questionWords) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentHistory = await getQuizHistory();
    
    // Add new questions to history
    currentHistory.addAll(questionWords);
    
    // Keep only last 50 questions to prevent infinite growth
    if (currentHistory.length > 50) {
      currentHistory.removeRange(0, currentHistory.length - 50);
    }
    
    await prefs.setString(_quizHistoryKey, json.encode(currentHistory));
  }
  
  /// Get wrong answers from previous sessions
  static Future<List<String>> getWrongAnswers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? wrongAnswersString = prefs.getString(_wrongAnswersKey);
    if (wrongAnswersString == null) return [];
    
    try {
      final List<dynamic> wrongAnswersList = json.decode(wrongAnswersString);
      return wrongAnswersList.cast<String>();
    } catch (e) {
      return [];
    }
  }
  
  /// Add wrong answers to tracking
  static Future<void> addWrongAnswers(List<String> wrongAnswerWords) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentWrongAnswers = await getWrongAnswers();
    
    // Add new wrong answers
    currentWrongAnswers.addAll(wrongAnswerWords);
    
    // Remove duplicates
    currentWrongAnswers.toSet().toList();
    
    // Keep only last 30 wrong answers
    if (currentWrongAnswers.length > 30) {
      currentWrongAnswers.removeRange(0, currentWrongAnswers.length - 30);
    }
    
    await prefs.setString(_wrongAnswersKey, json.encode(currentWrongAnswers));
  }
  
  /// Get last quiz session questions
  static Future<List<String>> getLastQuizSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionString = prefs.getString(_lastQuizSessionKey);
    if (sessionString == null) return [];
    
    try {
      final List<dynamic> sessionList = json.decode(sessionString);
      return sessionList.cast<String>();
    } catch (e) {
      return [];
    }
  }
  
  /// Save current quiz session questions
  static Future<void> saveCurrentQuizSession(List<String> questionWords) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastQuizSessionKey, json.encode(questionWords));
  }
  
  /// Clear last quiz session (called when starting new quiz)
  static Future<void> clearLastQuizSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastQuizSessionKey);
  }
  
  /// Get available questions for new quiz
  static Future<List<Vocabulary>> getAvailableQuestions(
    List<Vocabulary> allVocabulary,
    int totalQuestions,
  ) async {
    final List<String> lastSession = await getLastQuizSession();
    final List<String> wrongAnswers = await getWrongAnswers();
    
    // Filter out questions from last session
    List<Vocabulary> availableQuestions = allVocabulary
        .where((vocab) => !lastSession.contains(vocab.word))
        .toList();
    
    // If we don't have enough questions, include wrong answers from previous sessions
    if (availableQuestions.length < totalQuestions) {
      final List<Vocabulary> wrongAnswerQuestions = allVocabulary
          .where((vocab) => wrongAnswers.contains(vocab.word))
          .toList();
      
      // Add wrong answer questions that weren't in last session
      for (final wrongQuestion in wrongAnswerQuestions) {
        if (!lastSession.contains(wrongQuestion.word) && 
            !availableQuestions.any((q) => q.word == wrongQuestion.word)) {
          availableQuestions.add(wrongQuestion);
        }
      }
    }
    
    // If still not enough, include all questions (fallback)
    if (availableQuestions.length < totalQuestions) {
      availableQuestions = List<Vocabulary>.from(allVocabulary);
    }
    
    // Shuffle and limit to requested number of questions
    availableQuestions.shuffle();
    if (availableQuestions.length > totalQuestions) {
      availableQuestions = availableQuestions.take(totalQuestions).toList();
    }
    
    return availableQuestions;
  }
  
  /// Save quiz results and update state
  static Future<void> saveQuizResults({
    required List<Vocabulary> quizQuestions,
    required Map<int, String?> userAnswers,
    required Map<int, String> correctAnswers,
  }) async {
    // Save current session to history
    final List<String> questionWords = quizQuestions.map((q) => q.word).toList();
    await addToQuizHistory(questionWords);
    
    // Find wrong answers
    final List<String> wrongAnswerWords = [];
    for (int i = 0; i < quizQuestions.length; i++) {
      final userAnswer = userAnswers[i];
      final correctAnswer = correctAnswers[i];
      
      if (userAnswer != null && userAnswer != correctAnswer) {
        wrongAnswerWords.add(quizQuestions[i].word);
      }
    }
    
    // Add wrong answers to tracking
    if (wrongAnswerWords.isNotEmpty) {
      await addWrongAnswers(wrongAnswerWords);
    }
    
    // Save current session for next quiz
    await saveCurrentQuizSession(questionWords);
  }
  
  /// Clear all quiz data (for testing or reset)
  static Future<void> clearAllQuizData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quizHistoryKey);
    await prefs.remove(_wrongAnswersKey);
    await prefs.remove(_lastQuizSessionKey);
    await prefs.remove(_quizStatsKey);
  }
  
  /// Get quiz statistics
  static Future<Map<String, dynamic>> getQuizStatistics() async {
    final List<String> history = await getQuizHistory();
    final List<String> wrongAnswers = await getWrongAnswers();
    final List<String> lastSession = await getLastQuizSession();
    final Map<String, dynamic>? stats = await _getQuizStats();
    
    return {
      'totalQuizzes': stats?['totalQuizzes'] ?? 0,
      'totalQuestions': stats?['totalQuestions'] ?? 0,
      'correctAnswers': stats?['correctAnswers'] ?? 0,
      'wrongAnswers': stats?['wrongAnswers'] ?? 0,
      'percentage': stats?['percentage'] ?? 0.0,
      'totalQuestionsUsed': history.length,
      'wrongAnswersTracked': wrongAnswers.length,
      'lastSessionQuestions': lastSession.length,
      'storageKeys': [
        _quizHistoryKey,
        _wrongAnswersKey,
        _lastQuizSessionKey,
        _quizStatsKey,
      ],
    };
  }
  
  /// Save detailed quiz statistics
  static Future<void> saveQuizStats({
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
    required double percentage,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic>? existingStats = await _getQuizStats();
    
    // Get existing totals or start with 0
    final int existingTotalQuizzes = existingStats?['totalQuizzes'] ?? 0;
    final int existingTotalQuestions = existingStats?['totalQuestions'] ?? 0;
    final int existingCorrectAnswers = existingStats?['correctAnswers'] ?? 0;
    final int existingWrongAnswers = existingStats?['wrongAnswers'] ?? 0;
    
    // Calculate new totals
    final int newTotalQuizzes = existingTotalQuizzes + 1;
    final int newTotalQuestions = existingTotalQuestions + totalQuestions;
    final int newCorrectAnswers = existingCorrectAnswers + correctAnswers;
    final int newWrongAnswers = existingWrongAnswers + wrongAnswers;
    final double newOverallPercentage = newTotalQuestions > 0 ? (newCorrectAnswers / newTotalQuestions * 100) : 0.0;
    
    final Map<String, dynamic> stats = {
      'totalQuizzes': newTotalQuizzes,
      'totalQuestions': newTotalQuestions,
      'correctAnswers': newCorrectAnswers,
      'wrongAnswers': newWrongAnswers,
      'percentage': newOverallPercentage,
      'lastQuizScore': correctAnswers,
      'lastQuizTotal': totalQuestions,
      'lastQuizPercentage': percentage,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    
    await prefs.setString(_quizStatsKey, json.encode(stats));
  }
  
  
  /// Get last quiz score
  static Future<Map<String, dynamic>?> getLastQuizScore() async {
    final Map<String, dynamic>? stats = await _getQuizStats();
    if (stats == null) return null;
    
    return {
      'score': stats['lastQuizScore'] ?? 0,
      'total': stats['lastQuizTotal'] ?? 0,
      'percentage': stats['lastQuizPercentage'] ?? 0.0,
    };
  }
  
  /// Get all stored data (for debugging)
  static Future<Map<String, dynamic>> getAllStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    
    return {
      'quizHistory': await getQuizHistory(),
      'wrongAnswers': await getWrongAnswers(),
      'lastSession': await getLastQuizSession(),
      'quizStats': await _getQuizStats(),
      'allKeys': prefs.getKeys().toList(),
    };
  }
  
  /// Get quiz stats
  static Future<Map<String, dynamic>?> _getQuizStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? statsString = prefs.getString(_quizStatsKey);
    if (statsString == null) return null;
    
    try {
      return json.decode(statsString);
    } catch (e) {
      return null;
    }
  }
  
  /// Validate stored data integrity
  static Future<bool> validateStoredData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if all required keys exist
      final requiredKeys = [_quizHistoryKey, _wrongAnswersKey, _lastQuizSessionKey];
      for (final key in requiredKeys) {
        if (!prefs.containsKey(key)) {
          return false;
        }
      }
      
      // Validate JSON data
      await getQuizHistory();
      await getWrongAnswers();
      await getLastQuizSession();
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Repair corrupted data
  static Future<void> repairStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear potentially corrupted data
    await prefs.remove(_quizHistoryKey);
    await prefs.remove(_wrongAnswersKey);
    await prefs.remove(_lastQuizSessionKey);
    await prefs.remove(_quizStatsKey);
    
    // Initialize with empty data
    await prefs.setString(_quizHistoryKey, json.encode([]));
    await prefs.setString(_wrongAnswersKey, json.encode([]));
    await prefs.setString(_lastQuizSessionKey, json.encode([]));
  }
}
