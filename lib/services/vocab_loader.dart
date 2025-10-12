import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/vocabulary.dart';

/// Service class for loading vocabulary data from local JSON assets
class VocabLoader {
  static List<Vocabulary>? _vocabularyList;
  static bool _isLoaded = false;

  /// Load vocabulary data from assets/vocab.json
  /// Returns a list of Vocabulary objects
  static Future<List<Vocabulary>> loadVocabulary() async {
    if (_isLoaded && _vocabularyList != null) {
      return _vocabularyList!;
    }

    try {
      // Load JSON data from assets
      final String jsonString = await rootBundle.loadString('assets/vocab.json');
      
      // Parse JSON data
      final List<dynamic> jsonList = json.decode(jsonString);
      
      // Convert to Vocabulary objects
      _vocabularyList = jsonList
          .map((json) => Vocabulary.fromJson(json as Map<String, dynamic>))
          .toList();
      
      _isLoaded = true;
      return _vocabularyList!;
    } catch (e) {
      // If loading fails, return empty list
      print('Error loading vocabulary: $e');
      _vocabularyList = [];
      _isLoaded = true;
      return _vocabularyList!;
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
}
