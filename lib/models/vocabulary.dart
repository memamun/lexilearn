/// Vocabulary model representing a single vocabulary word with its meanings
class Vocabulary {
  final String word;
  final String bengaliMeaning;
  final String englishDefinition;

  const Vocabulary({
    required this.word,
    required this.bengaliMeaning,
    required this.englishDefinition,
  });

  /// Create a Vocabulary object from JSON data
  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    return Vocabulary(
      word: json['word'] as String,
      bengaliMeaning: json['bengali_meaning'] as String,
      englishDefinition: json['english_definition'] as String,
    );
  }

  /// Convert Vocabulary object to JSON
  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'bengali_meaning': bengaliMeaning,
      'english_definition': englishDefinition,
    };
  }

  /// Create a copy of this Vocabulary with updated fields
  Vocabulary copyWith({
    String? word,
    String? bengaliMeaning,
    String? englishDefinition,
  }) {
    return Vocabulary(
      word: word ?? this.word,
      bengaliMeaning: bengaliMeaning ?? this.bengaliMeaning,
      englishDefinition: englishDefinition ?? this.englishDefinition,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Vocabulary &&
        other.word == word &&
        other.bengaliMeaning == bengaliMeaning &&
        other.englishDefinition == englishDefinition;
  }

  @override
  int get hashCode {
    return word.hashCode ^ bengaliMeaning.hashCode ^ englishDefinition.hashCode;
  }

  @override
  String toString() {
    return 'Vocabulary(word: $word, bengaliMeaning: $bengaliMeaning, englishDefinition: $englishDefinition)';
  }
}
