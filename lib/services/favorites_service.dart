import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary.dart';

/// Service class for managing favorite vocabulary words using SharedPreferences
class FavoritesService {
  static const String _favoritesKey = 'favorite_words';
  static const String _lastQuizScoreKey = 'last_quiz_score';
  static const String _isDarkModeKey = 'is_dark_mode';

  /// Add a word to favorites
  static Future<bool> addToFavorites(Vocabulary vocabulary) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      
      // Check if already in favorites
      if (favorites.any((fav) => fav.word == vocabulary.word)) {
        return false; // Already in favorites
      }
      
      favorites.add(vocabulary);
      final jsonList = favorites.map((v) => v.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      return await prefs.setString(_favoritesKey, jsonString);
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove a word from favorites
  static Future<bool> removeFromFavorites(String word) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavorites();
      
      favorites.removeWhere((fav) => fav.word == word);
      final jsonList = favorites.map((v) => v.toJson()).toList();
      final jsonString = json.encode(jsonList);
      
      return await prefs.setString(_favoritesKey, jsonString);
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  /// Get all favorite words
  static Future<List<Vocabulary>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_favoritesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }
      
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList
          .map((json) => Vocabulary.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting favorites: $e');
      return [];
    }
  }

  /// Check if a word is in favorites
  static Future<bool> isFavorite(String word) async {
    final favorites = await getFavorites();
    return favorites.any((fav) => fav.word == word);
  }

  /// Clear all favorites
  static Future<bool> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_favoritesKey);
    } catch (e) {
      print('Error clearing favorites: $e');
      return false;
    }
  }

  /// Save last quiz score
  static Future<bool> saveLastQuizScore(int score, int total) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoreData = {'score': score, 'total': total, 'timestamp': DateTime.now().millisecondsSinceEpoch};
      return await prefs.setString(_lastQuizScoreKey, json.encode(scoreData));
    } catch (e) {
      print('Error saving quiz score: $e');
      return false;
    }
  }

  /// Get last quiz score
  static Future<Map<String, dynamic>?> getLastQuizScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_lastQuizScoreKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('Error getting quiz score: $e');
      return null;
    }
  }

  /// Clear last quiz score
  static Future<bool> clearLastQuizScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.remove(_lastQuizScoreKey);
    } catch (e) {
      print('Error clearing last quiz score: $e');
      return false;
    }
  }

  /// Save dark mode preference
  static Future<bool> setDarkMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setBool(_isDarkModeKey, isDark);
    } catch (e) {
      print('Error saving dark mode preference: $e');
      return false;
    }
  }

  /// Get dark mode preference
  static Future<bool> getDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isDarkModeKey) ?? false;
    } catch (e) {
      print('Error getting dark mode preference: $e');
      return false;
    }
  }

  /// Clear all stored data
  static Future<bool> clearAllData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
      await prefs.remove(_lastQuizScoreKey);
      await prefs.remove(_isDarkModeKey);
      return true;
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }
}
