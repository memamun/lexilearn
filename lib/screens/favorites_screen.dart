import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vocabulary.dart';
import '../services/favorites_service.dart';
import '../utils/app_themes.dart';
import 'flashcard_screen.dart';

/// Favorites screen for managing saved vocabulary words
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Vocabulary> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  /// Load favorites from storage
  Future<void> _loadFavorites() async {
    try {
      final favorites = await FavoritesService.getFavorites();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load favorites');
    }
  }

  /// Remove a word from favorites
  Future<void> _removeFavorite(Vocabulary vocabulary) async {
    final success = await FavoritesService.removeFromFavorites(vocabulary.word);
    if (success) {
      setState(() {
        _favorites.removeWhere((fav) => fav.word == vocabulary.word);
      });
      _showSnackBar('Removed from favorites');
    } else {
      _showErrorSnackBar('Failed to remove from favorites');
    }
  }

  /// Clear all favorites
  Future<void> _clearAllFavorites() async {
    final confirmed = await _showConfirmDialog(
      'Clear All Favorites',
      'Are you sure you want to remove all words from your favorites?',
    );

    if (confirmed == true) {
      final success = await FavoritesService.clearFavorites();
      if (success) {
        setState(() {
          _favorites.clear();
        });
        _showSnackBar('All favorites cleared');
      } else {
        _showErrorSnackBar('Failed to clear favorites');
      }
    }
  }


  /// Show confirmation dialog
  Future<bool?> _showConfirmDialog(String title, String content) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.lexend(fontWeight: FontWeight.bold),
        ),
        content: Text(
          content,
          style: GoogleFonts.lexend(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.lexend(color: AppThemes.getTextColor(context)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Confirm',
              style: GoogleFonts.lexend(color: AppThemes.getPrimaryColor(context)),
            ),
          ),
        ],
      ),
    );
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
          'Favorites',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppThemes.getTextColor(context),
          ),
        ),
        centerTitle: true,
        actions: _favorites.isNotEmpty
            ? [
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppThemes.getTextColor(context)),
                  onSelected: (value) {
                    if (value == 'clear_all') {
                      _clearAllFavorites();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'clear_all',
                      child: Text('Clear All'),
                    ),
                  ],
                ),
              ]
            : null,
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppThemes.getPrimaryColor(context)),
              ),
            )
          : _favorites.isEmpty
              ? _buildEmptyState()
              : _buildFavoritesList(),
    );
  }

  /// Build empty state when no favorites
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: AppThemes.getSecondaryTextColor(context).withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppThemes.getTextColor(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add words to your favorites while studying flashcards to see them here.',
              style: GoogleFonts.lexend(
                fontSize: 16,
                color: AppThemes.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const FlashcardScreen()),
                );
              },
              icon: const Icon(Icons.style),
              label: const Text('Start Studying'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.getPrimaryColor(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build favorites list
  Widget _buildFavoritesList() {
    return Column(
      children: [
        // Header with count
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                '${_favorites.length} favorite${_favorites.length == 1 ? '' : 's'}',
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),
              const Spacer(),
              if (_favorites.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearAllFavorites,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
            ],
          ),
        ),

        // Favorites list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _favorites.length,
            itemBuilder: (context, index) {
              final vocabulary = _favorites[index];
              return _buildFavoriteItem(vocabulary);
            },
          ),
        ),
      ],
    );
  }

  /// Build individual favorite item
  Widget _buildFavoriteItem(Vocabulary vocabulary) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Show word details in a dialog
            _showWordDetails(vocabulary);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Word content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vocabulary.word,
                        style: GoogleFonts.lexend(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppThemes.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vocabulary.bengaliMeaning,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppThemes.getPrimaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vocabulary.englishDefinition,
                        style: GoogleFonts.lexend(
                          fontSize: 12,
                          color: AppThemes.getSecondaryTextColor(context),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Remove button
                IconButton(
                  onPressed: () => _removeFavorite(vocabulary),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.red,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.1),
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show word details in a dialog
  void _showWordDetails(Vocabulary vocabulary) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          vocabulary.word,
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bengali Meaning:',
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppThemes.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vocabulary.bengaliMeaning,
              style: GoogleFonts.notoSansBengali(
                fontSize: 16,
                color: AppThemes.getPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'English Definition:',
              style: GoogleFonts.lexend(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppThemes.getTextColor(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              vocabulary.englishDefinition,
              style: GoogleFonts.lexend(
                fontSize: 16,
                color: AppThemes.getTextColor(context),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.lexend(color: AppThemes.getPrimaryColor(context)),
            ),
          ),
        ],
      ),
    );
  }

}
