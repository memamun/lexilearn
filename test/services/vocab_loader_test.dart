import 'package:flutter_test/flutter_test.dart';
import 'package:lexilearn/services/vocab_loader.dart';
import 'package:lexilearn/models/vocabulary.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('VocabLoader Tests', () {
    setUp(() {
      // Clear cache before each test
      VocabLoader.clearCache();
    });

    test('loadVocabulary should return list of Vocabulary objects', () async {
      final vocabulary = await VocabLoader.loadVocabulary();
      
      expect(vocabulary, isA<List<Vocabulary>>());
      expect(vocabulary.isNotEmpty, true);
      
      // Check first item structure
      final firstItem = vocabulary.first;
      expect(firstItem.word, isA<String>());
      expect(firstItem.bengaliMeaning, isA<String>());
      expect(firstItem.englishDefinition, isA<String>());
    });

    test('loadVocabulary should cache results', () async {
      final firstCall = await VocabLoader.loadVocabulary();
      final secondCall = await VocabLoader.loadVocabulary();
      
      expect(identical(firstCall, secondCall), true);
    });

    test('getVocabularyCount should return correct count', () async {
      final count = await VocabLoader.getVocabularyCount();
      final vocabulary = await VocabLoader.loadVocabulary();
      
      expect(count, equals(vocabulary.length));
    });

    test('getRandomVocabulary should return valid vocabulary', () async {
      final randomVocab = await VocabLoader.getRandomVocabulary();
      
      expect(randomVocab, isNotNull);
      expect(randomVocab!.word, isNotEmpty);
      expect(randomVocab.bengaliMeaning, isNotEmpty);
      expect(randomVocab.englishDefinition, isNotEmpty);
    });

    test('getRandomVocabularyList should return correct count', () async {
      final randomList = await VocabLoader.getRandomVocabularyList(5);
      
      expect(randomList.length, lessThanOrEqualTo(5));
      expect(randomList.every((vocab) => vocab.word.isNotEmpty), true);
    });

    test('searchVocabulary should find existing word', () async {
      final vocabulary = await VocabLoader.loadVocabulary();
      final firstWord = vocabulary.first.word;
      
      final found = await VocabLoader.searchVocabulary(firstWord);
      
      expect(found, isNotNull);
      expect(found!.word, equals(firstWord));
    });

    test('searchVocabulary should return null for non-existent word', () async {
      final found = await VocabLoader.searchVocabulary('NonExistentWord123');
      
      expect(found, isNull);
    });

    test('getVocabularyByIndex should return correct item', () async {
      final vocabulary = await VocabLoader.loadVocabulary();
      final firstItem = await VocabLoader.getVocabularyByIndex(0);
      
      expect(firstItem, isNotNull);
      expect(firstItem!.word, equals(vocabulary[0].word));
    });

    test('getVocabularyByIndex should return null for invalid index', () async {
      final item = await VocabLoader.getVocabularyByIndex(-1);
      expect(item, isNull);
      
      final item2 = await VocabLoader.getVocabularyByIndex(99999);
      expect(item2, isNull);
    });

    test('validateVocabularyData should return true for valid data', () async {
      final isValid = await VocabLoader.validateVocabularyData();
      expect(isValid, true);
    });

    test('getVocabularyStats should return correct statistics', () async {
      final stats = await VocabLoader.getVocabularyStats();
      
      expect(stats['totalWords'], greaterThan(0));
      expect(stats['uniqueWords'], greaterThan(0));
      expect(stats['uniqueWords'], lessThanOrEqualTo(stats['totalWords']!));
    });

    test('clearCache should reset cached data', () async {
      await VocabLoader.loadVocabulary();
      VocabLoader.clearCache();
      
      // This should reload from source
      final vocabulary = await VocabLoader.loadVocabulary();
      expect(vocabulary, isNotEmpty);
    });
  });
}
