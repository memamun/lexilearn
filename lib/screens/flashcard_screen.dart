import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flip_card/flip_card.dart';
import '../models/vocabulary.dart';
import '../services/vocab_loader.dart';
import '../services/favorites_service.dart';
import '../services/learning_stats_service.dart';
import '../utils/app_themes.dart';
import 'quiz_screen.dart';

/// Flashcard screen for learning vocabulary
class FlashcardScreen extends StatefulWidget {
  final bool favoritesOnly;
  final List<Vocabulary>? favorites;
  
  const FlashcardScreen({
    super.key,
    this.favoritesOnly = false,
    this.favorites,
  });

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  List<Vocabulary> _vocabularyList = [];
  List<Vocabulary> _sessionReviewWords = [];
  List<Vocabulary> _completedWords = [];
  int _currentIndex = 0;
  bool _isShuffled = false;
  bool _isFavorite = false;
  bool _isLoading = true;
  bool _showSessionComplete = false;
  bool _isInReviewMode = false;
  int _sessionKnownCount = 0;
  int _sessionUnknownCount = 0;
  final GlobalKey<FlipCardState> _flipCardKey = GlobalKey<FlipCardState>();
  String? _dismissedWord;

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  /// Load vocabulary data
  Future<void> _loadVocabulary() async {
    try {
      List<Vocabulary> vocabList;
      
      if (widget.favoritesOnly && widget.favorites != null) {
        vocabList = widget.favorites!;
      } else {
        // Load random vocabulary words
        final List<Vocabulary> allVocab = await VocabLoader.loadVocabulary();
        allVocab.shuffle();
        vocabList = allVocab.take(20).toList();
      }
      
      setState(() {
        _vocabularyList = vocabList;
        _sessionReviewWords = [];
        _completedWords = [];
        _isLoading = false;
        _isInReviewMode = false;
        _sessionKnownCount = 0;
        _sessionUnknownCount = 0;
        _dismissedWord = null;
      });
      await _checkFavoriteStatus();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load vocabulary');
    }
  }

  /// Check if current word is in favorites
  Future<void> _checkFavoriteStatus() async {
    if (_vocabularyList.isNotEmpty) {
      final isFav = await FavoritesService.isFavorite(_vocabularyList[_currentIndex].word);
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  /// Mark current word as known
  Future<void> _markAsKnown() async {
    if (_vocabularyList.isNotEmpty) {
      final currentWord = _vocabularyList[_currentIndex];
      
      await LearningStatsService.markAsKnownWithoutDailyTracking(currentWord.word);
      
      setState(() {
        _sessionKnownCount++;
        _completedWords.add(currentWord);
        // Remove from review words if it was there
        _sessionReviewWords.removeWhere((vocab) => vocab.word == currentWord.word);
      });
      await _nextCard();
    }
  }

  /// Mark current word as unknown
  Future<void> _markAsUnknown() async {
    if (_vocabularyList.isNotEmpty) {
      final currentWord = _vocabularyList[_currentIndex];
      
      await LearningStatsService.markAsUnknownWithoutDailyTracking(currentWord.word);
      
      setState(() {
        _sessionUnknownCount++;
        _completedWords.add(currentWord);
        // Add to review words if not already there
        if (!_sessionReviewWords.any((vocab) => vocab.word == currentWord.word)) {
          _sessionReviewWords.add(currentWord);
        }
      });
      await _nextCard();
    }
  }

  /// Navigate to next card
  Future<void> _nextCard() async {
    if (_vocabularyList.isNotEmpty) {
      bool sessionCompleted = false;
      
      setState(() {
        if (_currentIndex < _vocabularyList.length - 1) {
          _currentIndex++;
        } else {
          // Check if there are review words to study
          if (_sessionReviewWords.isNotEmpty) {
            // Continue with review words
            _continueWithReviewWords();
          } else {
            // Session completed
            _showSessionComplete = true;
            sessionCompleted = true;
          }
        }
      });
      
      // Handle session completion outside of setState
      if (sessionCompleted) {
        await _updateSessionStats();
      }
      
      // Only proceed if session is not complete
      if (!_showSessionComplete) {
        // Always show the front side (English word) when navigating
        // Double toggle to ensure we're on the front side
        if (_flipCardKey.currentState?.isFront == false) {
          _flipCardKey.currentState?.toggleCard();
        }
        await _checkFavoriteStatus();
      }
    }
  }

  /// Continue with review words (Quizlet-like behavior)
  void _continueWithReviewWords() {
    // Shuffle review words and continue studying them
    _sessionReviewWords.shuffle();
    _vocabularyList = List<Vocabulary>.from(_sessionReviewWords);
    _currentIndex = 0;
    _isInReviewMode = true;
    _dismissedWord = null;
    // Clear the review words list since we're now studying them
    _sessionReviewWords.clear();
  }

  /// Update session statistics
  Future<void> _updateSessionStats() async {
    await LearningStatsService.updateSessionStats(_sessionKnownCount, _sessionUnknownCount);
    
    // Record completed flashcard session for daily tracking
    // Always count as 20 words per completed session (standard flashcard session size)
    await LearningStatsService.recordFlashcardSessionCompleted(20);
  }

  /// Shuffle the vocabulary list
  void _shuffleCards() {
    if (_vocabularyList.isNotEmpty) {
      setState(() {
        _vocabularyList.shuffle();
        _currentIndex = 0;
        _isShuffled = true;
      });
      // Always show the front side (English word) when shuffling
      // Double toggle to ensure we're on the front side
      if (_flipCardKey.currentState?.isFront == false) {
        _flipCardKey.currentState?.toggleCard();
      }
      _checkFavoriteStatus();
    }
  }

  /// Toggle favorite status
  Future<void> _toggleFavorite() async {
    if (_vocabularyList.isEmpty) return;

    final currentWord = _vocabularyList[_currentIndex];
    bool success;

    if (_isFavorite) {
      success = await FavoritesService.removeFromFavorites(currentWord.word);
    } else {
      success = await FavoritesService.addToFavorites(currentWord);
    }

    if (success) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      _showSnackBar(
        _isFavorite ? 'Added to favorites' : 'Removed from favorites',
      );
    } else {
      _showErrorSnackBar('Failed to update favorites');
    }
  }

  /// Show success message
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppThemes.getPrimaryColor(context),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppThemes.getBackgroundColor(context),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: AppThemes.getTextColor(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Flashcards',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppThemes.getTextColor(context),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isShuffled ? Icons.shuffle : Icons.shuffle,
              color: AppThemes.getTextColor(context),
            ),
            onPressed: _shuffleCards,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppThemes.getPrimaryColor(context)),
              ),
            )
          : _showSessionComplete
              ? _buildSessionCompleteScreen()
              : _vocabularyList.isEmpty
                  ? Center(
                      child: Text(
                        'No vocabulary found',
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          color: AppThemes.getTextColor(context),
                        ),
                      ),
                    )
                  : Column(
                  children: [
                     // Progress indicator
                     Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Column(
                         children: [
                           if (_isInReviewMode) ...[
                             Text(
                               'REVIEW MODE',
                               style: GoogleFonts.lexend(
                                 fontSize: 16,
                                 color: Colors.orange,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                             const SizedBox(height: 4),
                             Text(
                               '${_currentIndex + 1} of ${_vocabularyList.length}',
                               style: GoogleFonts.lexend(
                                 fontSize: 14,
                                 color: Colors.orange,
                                 fontWeight: FontWeight.w600,
                               ),
                             ),
                           ] else ...[
                             Text(
                               '${_currentIndex + 1} of ${_vocabularyList.length}',
                               style: GoogleFonts.lexend(
                                 fontSize: 14,
                                 color: AppThemes.getSecondaryTextColor(context),
                               ),
                             ),
                             if (_sessionReviewWords.isNotEmpty) ...[
                               const SizedBox(height: 4),
                               Text(
                                 'Review: ${_sessionReviewWords.length} words',
                                 style: GoogleFonts.lexend(
                                   fontSize: 12,
                                   color: Colors.orange,
                                   fontWeight: FontWeight.w600,
                                 ),
                               ),
                             ],
                           ],
                         ],
                       ),
                     ),
                    
                    // Flashcard
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: _vocabularyList.isNotEmpty && 
                                 _currentIndex < _vocabularyList.length &&
                                 _dismissedWord != _vocabularyList[_currentIndex].word
                              ? Dismissible(
                                  key: Key('${_vocabularyList[_currentIndex].word}_${_currentIndex}'),
                                  direction: DismissDirection.horizontal,
                                  onDismissed: (direction) {
                                    setState(() {
                                      _dismissedWord = _vocabularyList[_currentIndex].word;
                                    });
                                    
                                    if (direction == DismissDirection.endToStart) {
                                      // Swipe left - mark as unknown
                                      _markAsUnknown();
                                    } else if (direction == DismissDirection.startToEnd) {
                                      // Swipe right - mark as known
                                      _markAsKnown();
                                    }
                                  },
                                  child: FlipCard(
                                    key: _flipCardKey,
                                    direction: FlipDirection.HORIZONTAL,
                                    front: _buildCardFront(),
                                    back: _buildCardBack(),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    
                    // Instructions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Tap card to flip',
                        style: GoogleFonts.lexend(
                          fontSize: 14,
                          color: AppThemes.getSecondaryTextColor(context),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Add to favorites button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _toggleFavorite,
                              icon: Icon(
                                _isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: const Color(0xFF1132D4),
                              ),
                              label: Text(
                                _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                                style: GoogleFonts.lexend(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1132D4),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppThemes.getPrimaryColor(context).withOpacity(0.1),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Swipe instructions
                          Text(
                            'Swipe right for Known • Swipe left for Unknown • Or tap buttons below',
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                                color: AppThemes.getSecondaryTextColor(context),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          
                          // Known/Unknown buttons (main navigation)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _markAsUnknown,
                                  icon: const Icon(Icons.close, size: 20),
                                   label: const Text('Unknown'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: AppThemes.getPrimaryColor(context).withOpacity(0.1), // Light blue like secondary buttons
                                     foregroundColor: AppThemes.getTextColor(context), // Dark text like other buttons
                                     elevation: 1,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _markAsKnown,
                                  icon: const Icon(Icons.check, size: 20),
                                   label: const Text('Known'),
                                   style: ElevatedButton.styleFrom(
                                     backgroundColor: AppThemes.getPrimaryColor(context), // Main app blue
                                     foregroundColor: Colors.white,
                                     elevation: 1,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  /// Build the front of the flashcard
  Widget _buildCardFront() {
    if (_vocabularyList.isEmpty || _currentIndex >= _vocabularyList.length) {
      return const SizedBox.shrink();
    }
    
    final vocabulary = _vocabularyList[_currentIndex];
    // In review mode, all words are review words
    final isReviewWord = _isInReviewMode;
    
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Review chip
          if (isReviewWord)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'REVIEW',
                  style: GoogleFonts.lexend(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppThemes.getCardColor(context),
                  ),
                ),
              ),
            ),
          
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                vocabulary.word,
                style: GoogleFonts.lexend(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppThemes.getTextColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the back of the flashcard
  Widget _buildCardBack() {
    if (_vocabularyList.isEmpty || _currentIndex >= _vocabularyList.length) {
      return const SizedBox.shrink();
    }
    
    final vocabulary = _vocabularyList[_currentIndex];
    return Container(
      width: double.infinity,
      height: 300,
      decoration: BoxDecoration(
        color: AppThemes.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Bengali meaning
            Text(
              vocabulary.bengaliMeaning,
              style: GoogleFonts.notoSansBengali(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppThemes.getPrimaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // English definition
            Text(
              vocabulary.englishDefinition,
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppThemes.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build session complete screen
  Widget _buildSessionCompleteScreen() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 60,
              color: Colors.green,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Session Complete!',
            style: GoogleFonts.lexend(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppThemes.getTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Statistics
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppThemes.getCardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Session Statistics',
                  style: GoogleFonts.lexend(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppThemes.getTextColor(context),
                  ),
                ),
                const SizedBox(height: 20),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Known',
                      (20 - _sessionUnknownCount).toString(),
                      Colors.green,
                      Icons.check_circle,
                    ),
                    _buildStatItem(
                      'Unknown',
                      _sessionUnknownCount.toString(),
                      Colors.red,
                      Icons.cancel,
                    ),
                    if (_sessionReviewWords.isNotEmpty)
                      _buildStatItem(
                        'Review',
                        _sessionReviewWords.length.toString(),
                        Colors.orange,
                        Icons.refresh,
                      ),
                    _buildStatItem(
                      'Total',
                      '20',
                      const Color(0xFF1132D4),
                      Icons.quiz,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Action buttons
          Column(
            children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizScreen(
                              vocabularySet: _completedWords,
                              isFromFlashcard: true,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.quiz),
                      label: const Text('Take Quiz on This Set'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppThemes.getPrimaryColor(context),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _showSessionComplete = false;
                      _currentIndex = 0;
                      _sessionKnownCount = 0;
                      _sessionUnknownCount = 0;
                    });
                    _loadVocabulary();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Start New Session'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppThemes.getPrimaryColor(context).withOpacity(0.1),
                    foregroundColor: AppThemes.getPrimaryColor(context),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.home),
                  label: const Text('Back to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build stat item for session complete screen
  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: color,
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.lexend(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.lexend(
            fontSize: 14,
                                color: AppThemes.getSecondaryTextColor(context),
          ),
        ),
      ],
    );
  }

}
