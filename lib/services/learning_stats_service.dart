import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing learning statistics and spaced repetition
class LearningStatsService {
  static const String _knownWordsKey = 'known_words';
  static const String _unknownWordsKey = 'unknown_words';
  static const String _learningHistoryKey = 'learning_history';
  static const String _spacedRepetitionKey = 'spaced_repetition';
  static const String _sessionStatsKey = 'session_stats';
  static const String _dailyStatsKey = 'daily_stats';

  /// Mark a word as known
  static Future<void> markAsKnown(String word) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Add to known words
    List<String> knownWords = prefs.getStringList(_knownWordsKey) ?? [];
    if (!knownWords.contains(word)) {
      knownWords.add(word);
      await prefs.setStringList(_knownWordsKey, knownWords);
    }
    
    // Remove from unknown words if present
    List<String> unknownWords = prefs.getStringList(_unknownWordsKey) ?? [];
    unknownWords.remove(word);
    await prefs.setStringList(_unknownWordsKey, unknownWords);
    
    // Update spaced repetition data
    await _updateSpacedRepetition(word, true);
    
    // Record learning event
    await _recordLearningEvent(word, 'known');
    
    // Record word studied today
    await recordWordStudiedToday(word);
  }

  /// Mark a word as unknown
  static Future<void> markAsUnknown(String word) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Add to unknown words
    List<String> unknownWords = prefs.getStringList(_unknownWordsKey) ?? [];
    if (!unknownWords.contains(word)) {
      unknownWords.add(word);
      await prefs.setStringList(_unknownWordsKey, unknownWords);
    }
    
    // Remove from known words if present
    List<String> knownWords = prefs.getStringList(_knownWordsKey) ?? [];
    knownWords.remove(word);
    await prefs.setStringList(_knownWordsKey, knownWords);
    
    // Update spaced repetition data
    await _updateSpacedRepetition(word, false);
    
    // Record learning event
    await _recordLearningEvent(word, 'unknown');
    
    // Record word studied today
    await recordWordStudiedToday(word);
  }

  /// Mark a word as known (without daily tracking - for flashcard sessions)
  static Future<void> markAsKnownWithoutDailyTracking(String word) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Add to known words
    List<String> knownWords = prefs.getStringList(_knownWordsKey) ?? [];
    if (!knownWords.contains(word)) {
      knownWords.add(word);
      await prefs.setStringList(_knownWordsKey, knownWords);
    }
    
    // Remove from unknown words if present
    List<String> unknownWords = prefs.getStringList(_unknownWordsKey) ?? [];
    unknownWords.remove(word);
    await prefs.setStringList(_unknownWordsKey, unknownWords);
    
    // Update spaced repetition data
    await _updateSpacedRepetition(word, true);
    
    // Record learning event
    await _recordLearningEvent(word, 'known');
    
    // Note: No daily tracking here - will be handled by session completion
  }

  /// Mark a word as unknown (without daily tracking - for flashcard sessions)
  static Future<void> markAsUnknownWithoutDailyTracking(String word) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Add to unknown words
    List<String> unknownWords = prefs.getStringList(_unknownWordsKey) ?? [];
    if (!unknownWords.contains(word)) {
      unknownWords.add(word);
      await prefs.setStringList(_unknownWordsKey, unknownWords);
    }
    
    // Remove from known words if present
    List<String> knownWords = prefs.getStringList(_knownWordsKey) ?? [];
    knownWords.remove(word);
    await prefs.setStringList(_knownWordsKey, knownWords);
    
    // Update spaced repetition data
    await _updateSpacedRepetition(word, false);
    
    // Record learning event
    await _recordLearningEvent(word, 'unknown');
    
    // Note: No daily tracking here - will be handled by session completion
  }

  /// Check if a word is known
  static Future<bool> isKnown(String word) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> knownWords = prefs.getStringList(_knownWordsKey) ?? [];
    return knownWords.contains(word);
  }

  /// Check if a word is unknown
  static Future<bool> isUnknown(String word) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> unknownWords = prefs.getStringList(_unknownWordsKey) ?? [];
    return unknownWords.contains(word);
  }

  /// Get words that need review (spaced repetition)
  static Future<List<String>> getWordsForReview() async {
    final prefs = await SharedPreferences.getInstance();
    final String? spacedRepetitionData = prefs.getString(_spacedRepetitionKey);
    
    if (spacedRepetitionData == null) return [];
    
    try {
      final Map<String, dynamic> data = json.decode(spacedRepetitionData);
      final List<String> reviewWords = [];
      final DateTime now = DateTime.now();
      
      for (String word in data.keys) {
        final Map<String, dynamic> wordData = data[word];
        final DateTime nextReview = DateTime.parse(wordData['nextReview']);
        
        if (now.isAfter(nextReview)) {
          reviewWords.add(word);
        }
      }
      
      return reviewWords;
    } catch (e) {
      return [];
    }
  }

  /// Get words for spaced repetition (prioritize unknown words)
  static Future<List<String>> getWordsForSpacedRepetition(int count) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> unknownWords = prefs.getStringList(_unknownWordsKey) ?? [];
    List<String> reviewWords = await getWordsForReview();
    
    // Combine unknown words and words due for review
    Set<String> priorityWords = {...unknownWords, ...reviewWords};
    List<String> result = priorityWords.toList();
    
    // Shuffle and limit to requested count
    result.shuffle();
    return result.take(count).toList();
  }

  /// Update spaced repetition data for a word
  static Future<void> _updateSpacedRepetition(String word, bool isKnown) async {
    final prefs = await SharedPreferences.getInstance();
    final String? spacedRepetitionData = prefs.getString(_spacedRepetitionKey);
    
    Map<String, dynamic> data = {};
    if (spacedRepetitionData != null) {
      try {
        data = json.decode(spacedRepetitionData);
      } catch (e) {
        data = {};
      }
    }
    
    final DateTime now = DateTime.now();
    final Map<String, dynamic> wordData = data[word] ?? {
      'interval': 1,
      'repetitions': 0,
      'nextReview': now.add(const Duration(days: 1)).toIso8601String(),
    };
    
    if (isKnown) {
      // Increase interval and repetitions for known words
      wordData['repetitions'] = (wordData['repetitions'] ?? 0) + 1;
      wordData['interval'] = _calculateNextInterval(wordData['interval'] ?? 1);
      wordData['nextReview'] = now.add(Duration(days: wordData['interval'])).toIso8601String();
    } else {
      // Reset interval for unknown words
      wordData['interval'] = 1;
      wordData['repetitions'] = 0;
      wordData['nextReview'] = now.add(const Duration(hours: 1)).toIso8601String();
    }
    
    data[word] = wordData;
    await prefs.setString(_spacedRepetitionKey, json.encode(data));
  }

  /// Calculate next interval for spaced repetition
  static int _calculateNextInterval(int currentInterval) {
    if (currentInterval == 1) return 2;
    if (currentInterval == 2) return 4;
    if (currentInterval == 4) return 8;
    if (currentInterval == 8) return 16;
    return (currentInterval * 1.5).round();
  }

  /// Record a learning event
  static Future<void> _recordLearningEvent(String word, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyData = prefs.getString(_learningHistoryKey);
    
    List<Map<String, dynamic>> history = [];
    if (historyData != null) {
      try {
        final List<dynamic> historyList = json.decode(historyData);
        history = historyList.cast<Map<String, dynamic>>();
      } catch (e) {
        history = [];
      }
    }
    
    history.add({
      'word': word,
      'status': status,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Keep only last 1000 events
    if (history.length > 1000) {
      history = history.sublist(history.length - 1000);
    }
    
    await prefs.setString(_learningHistoryKey, json.encode(history));
  }

  /// Get learning statistics
  static Future<Map<String, dynamic>> getLearningStats() async {
    final prefs = await SharedPreferences.getInstance();
    
    final List<String> knownWords = prefs.getStringList(_knownWordsKey) ?? [];
    final List<String> unknownWords = prefs.getStringList(_unknownWordsKey) ?? [];
    final String? historyData = prefs.getString(_learningHistoryKey);
    
    int totalSessions = 0;
    int knownCount = 0;
    int unknownCount = 0;
    
    if (historyData != null) {
      try {
        final List<dynamic> history = json.decode(historyData);
        totalSessions = history.length;
        
        // Count recent known/unknown events (last 7 days)
        final DateTime weekAgo = DateTime.now().subtract(const Duration(days: 7));
        for (final event in history) {
          final DateTime timestamp = DateTime.parse(event['timestamp']);
          if (timestamp.isAfter(weekAgo)) {
            if (event['status'] == 'known') {
              knownCount++;
            } else if (event['status'] == 'unknown') {
              unknownCount++;
            }
          }
        }
      } catch (e) {
        // Handle error silently
      }
    }
    
    return {
      'totalKnownWords': knownWords.length,
      'totalUnknownWords': unknownWords.length,
      'totalSessions': totalSessions,
      'recentKnownCount': knownCount,
      'recentUnknownCount': unknownCount,
      'learningProgress': knownWords.length / (knownWords.length + unknownWords.length),
    };
  }

  /// Get session statistics
  static Future<Map<String, dynamic>> getSessionStats() async {
    final prefs = await SharedPreferences.getInstance();
    final String? sessionData = prefs.getString(_sessionStatsKey);
    
    if (sessionData == null) {
      return {
        'currentSessionKnown': 0,
        'currentSessionUnknown': 0,
        'currentSessionTotal': 0,
        'lastSessionDate': null,
      };
    }
    
    try {
      return json.decode(sessionData);
    } catch (e) {
      return {
        'currentSessionKnown': 0,
        'currentSessionUnknown': 0,
        'currentSessionTotal': 0,
        'lastSessionDate': null,
      };
    }
  }

  /// Update session statistics
  static Future<void> updateSessionStats(int known, int unknown) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> stats = {
      'currentSessionKnown': known,
      'currentSessionUnknown': unknown,
      'currentSessionTotal': known + unknown,
      'lastSessionDate': DateTime.now().toIso8601String(),
    };
    
    await prefs.setString(_sessionStatsKey, json.encode(stats));
  }

  /// Reset all learning data
  static Future<void> resetLearningData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_knownWordsKey);
    await prefs.remove(_unknownWordsKey);
    await prefs.remove(_learningHistoryKey);
    await prefs.remove(_spacedRepetitionKey);
    await prefs.remove(_sessionStatsKey);
    await prefs.remove(_dailyStatsKey);
  }

  /// Get words by category for review
  static Future<Map<String, List<String>>> getWordsByCategory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> knownWords = prefs.getStringList(_knownWordsKey) ?? [];
    final List<String> unknownWords = prefs.getStringList(_unknownWordsKey) ?? [];
    final List<String> reviewWords = await getWordsForReview();
    
    return {
      'known': knownWords,
      'unknown': unknownWords,
      'forReview': reviewWords,
    };
  }

  /// Get learning statistics
  static Future<Map<String, dynamic>> getLearningStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> knownWords = prefs.getStringList(_knownWordsKey) ?? [];
    final List<String> unknownWords = prefs.getStringList(_unknownWordsKey) ?? [];
    final wordsForReview = await getWordsForSpacedRepetition(100);
    final wordsStudiedToday = await getWordsStudiedToday();
    
    return {
      'knownWords': knownWords.length,
      'unknownWords': unknownWords.length,
      'wordsForReview': wordsForReview.length,
      'totalWordsStudied': knownWords.length + unknownWords.length,
      'wordsStudiedToday': wordsStudiedToday,
    };
  }

  /// Get words studied today
  static Future<int> getWordsStudiedToday() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dailyStatsString = prefs.getString(_dailyStatsKey);
      
      if (dailyStatsString == null) return 0;
      
      final Map<String, dynamic> dailyStats = json.decode(dailyStatsString);
      final String today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      
      return dailyStats[today] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Record a word as studied today
  static Future<void> recordWordStudiedToday(String word) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dailyStatsString = prefs.getString(_dailyStatsKey);
      
      Map<String, dynamic> dailyStats = {};
      if (dailyStatsString != null) {
        dailyStats = json.decode(dailyStatsString);
      }
      
      final String today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final int currentCount = dailyStats[today] ?? 0;
      dailyStats[today] = currentCount + 1;
      
      await prefs.setString(_dailyStatsKey, json.encode(dailyStats));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Record completed flashcard session for daily tracking
  static Future<void> recordFlashcardSessionCompleted(int wordsCount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dailyStatsString = prefs.getString(_dailyStatsKey);
      
      Map<String, dynamic> dailyStats = {};
      if (dailyStatsString != null) {
        dailyStats = json.decode(dailyStatsString);
      }
      
      final String today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
      final int currentCount = dailyStats[today] ?? 0;
      dailyStats[today] = currentCount + wordsCount;
      
      await prefs.setString(_dailyStatsKey, json.encode(dailyStats));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Clean old daily stats (keep only last 30 days)
  static Future<void> cleanOldDailyStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? dailyStatsString = prefs.getString(_dailyStatsKey);
      
      if (dailyStatsString == null) return;
      
      final Map<String, dynamic> dailyStats = json.decode(dailyStatsString);
      final DateTime thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      // Remove entries older than 30 days
      dailyStats.removeWhere((key, value) {
        try {
          final DateTime date = DateTime.parse(key);
          return date.isBefore(thirtyDaysAgo);
        } catch (e) {
          return true; // Remove invalid dates
        }
      });
      
      await prefs.setString(_dailyStatsKey, json.encode(dailyStats));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get the study date for a word (when it was first marked as known)
  static Future<DateTime?> getStudyDate(String word) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyData = prefs.getString(_learningHistoryKey);
      
      if (historyData == null) return null;
      
      final List<dynamic> historyList = json.decode(historyData);
      final List<Map<String, dynamic>> history = historyList.cast<Map<String, dynamic>>();
      
      // Find the first time this word was marked as 'known'
      for (final event in history) {
        if (event['word'] == word && event['status'] == 'known') {
          return DateTime.parse(event['timestamp']);
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }
}
