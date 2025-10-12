import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/vocabulary.dart';
import '../utils/error_handler.dart';

/// Service class for loading vocabulary data from local JSON assets
class VocabLoader {
  static List<Vocabulary>? _vocabularyList;
  static bool _isLoaded = false;

  /// Load vocabulary data from assets/vocab.json
  /// Returns a list of Vocabulary objects with enhanced error handling
  static Future<List<Vocabulary>> loadVocabulary() async {
    if (_isLoaded && _vocabularyList != null) {
      return _vocabularyList!;
    }

    try {
      // Load JSON data from assets
      final String jsonString = await rootBundle.loadString('assets/vocab.json');
      
      // Parse JSON data
      final List<dynamic> jsonList = json.decode(jsonString);
      
      // Validate JSON structure
      if (jsonList.isEmpty) {
        throw Exception('Vocabulary data is empty');
      }
      
      // Convert to Vocabulary objects with validation
      _vocabularyList = jsonList.map((json) {
        try {
          return Vocabulary.fromJson(json as Map<String, dynamic>);
        } catch (e) {
          throw Exception('Invalid vocabulary item format: $e');
        }
      }).toList();
      
      // Validate loaded data - filter out invalid entries instead of throwing
      _vocabularyList = _vocabularyList!.where((vocab) {
        return vocab.word.isNotEmpty && 
               vocab.bengaliMeaning.isNotEmpty && 
               vocab.englishDefinition.isNotEmpty;
      }).toList();
      
      if (_vocabularyList!.isEmpty) {
        throw Exception('No valid vocabulary data found');
      }
      
      _isLoaded = true;
      return _vocabularyList!;
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Invalid JSON format in vocabulary file');
      } else if (e is PlatformException) {
        throw Exception('Failed to read vocabulary file from assets');
      }
      rethrow;
    }
  }

  /// Get a random vocabulary word
  static Future<Vocabulary?> getRandomVocabulary() async {
    final vocabList = await loadVocabulary();
    if (vocabList.isEmpty) return null;
    
    final random = DateTime.now().millisecondsSinceEpoch % vocabList.length;
    return vocabList[random];
  }

  /// Get multiple random vocabulary words for quiz options
  static Future<List<Vocabulary>> getRandomVocabularyList(int count) async {
    final vocabList = await loadVocabulary();
    if (vocabList.isEmpty) return [];
    
    // Shuffle the list and take the requested count
    final shuffledList = List<Vocabulary>.from(vocabList);
    shuffledList.shuffle();
    
    return shuffledList.take(count).toList();
  }

  /// Search vocabulary by word
  static Future<Vocabulary?> searchVocabulary(String word) async {
    final vocabList = await loadVocabulary();
    
    try {
      return vocabList.firstWhere(
        (vocab) => vocab.word.toLowerCase() == word.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get vocabulary by index
  static Future<Vocabulary?> getVocabularyByIndex(int index) async {
    final vocabList = await loadVocabulary();
    
    if (index >= 0 && index < vocabList.length) {
      return vocabList[index];
    }
    return null;
  }

  /// Get total vocabulary count
  static Future<int> getVocabularyCount() async {
    final vocabList = await loadVocabulary();
    return vocabList.length;
  }

  /// Clear cached data (useful for testing or memory management)
  static void clearCache() {
    _vocabularyList = null;
    _isLoaded = false;
  }

  /// Validate vocabulary data integrity
  static Future<bool> validateVocabularyData() async {
    try {
      final vocabulary = await loadVocabulary();
      
      // Check for required fields
      for (final item in vocabulary) {
        if (item.word.isEmpty || 
            item.bengaliMeaning.isEmpty || 
            item.englishDefinition.isEmpty) {
          return false;
        }
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get vocabulary statistics
  static Future<Map<String, int>> getVocabularyStats() async {
    try {
      final vocabulary = await loadVocabulary();
      return {
        'totalWords': vocabulary.length,
        'uniqueWords': vocabulary.map((v) => v.word).toSet().length,
      };
    } catch (e) {
      return {
        'totalWords': 0,
        'uniqueWords': 0,
      };
    }
  }
}
