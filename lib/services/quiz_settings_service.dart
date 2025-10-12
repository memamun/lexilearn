import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing quiz settings
class QuizSettingsService {
  static const String _questionCountKey = 'quiz_question_count';
  static const int _defaultQuestionCount = 5;

  /// Get the current quiz question count setting
  static Future<int> getQuestionCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_questionCountKey) ?? _defaultQuestionCount;
    } catch (e) {
      return _defaultQuestionCount;
    }
  }

  /// Set the quiz question count
  static Future<void> setQuestionCount(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_questionCountKey, count);
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get available question count options
  static List<int> getAvailableQuestionCounts() {
    return [3, 5, 10, 15, 20, 25, 30];
  }

  /// Reset quiz settings to default
  static Future<void> resetToDefault() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_questionCountKey);
    } catch (e) {
      // Handle error silently
    }
  }
}
