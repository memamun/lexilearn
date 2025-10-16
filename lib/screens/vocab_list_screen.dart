import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary.dart';
import '../services/vocab_loader.dart';
import '../services/favorites_service.dart';
import '../services/learning_stats_service.dart';
import '../utils/app_themes.dart';

/// Vocabulary list screen with search functionality
class VocabListScreen extends StatefulWidget {
  const VocabListScreen({super.key});

  @override
  State<VocabListScreen> createState() => _VocabListScreenState();
}

class _VocabListScreenState extends State<VocabListScreen> {
  List<Vocabulary> _allVocabulary = [];
  List<Vocabulary> _filteredVocabulary = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isLoading = true;
  String _searchQuery = '';
  String _currentFilter = 'All'; // All, Read, Unread, Favourite
  Set<String> _studiedWords = {};
  String _sortBy = 'Alphabetical'; // Alphabetical, Reverse, Random, Date
  Timer? _searchTimer;
  Map<String, bool> _favoriteStatus = {}; // Cache favorite status
  bool _isSelectionMode = false; // Bulk selection mode
  Set<String> _selectedWords = {}; // Selected words for bulk operations
  bool _isAllSelected = false; // Whether all visible items are selected
  int _currentPage = 0; // Current page for pagination
  static const int _itemsPerPage = 20; // Items per page
  bool _hasMoreItems = true; // Whether there are more items to load
  Map<String, List<Vocabulary>> _searchCache = {}; // Cache search results
  bool _isLoadingMore = false; // Loading state for pagination

  @override
  void initState() {
    super.initState();
    _loadVocabulary();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }

  /// Load vocabulary data
  Future<void> _loadVocabulary() async {
    try {
      final vocabulary = await VocabLoader.loadVocabulary();
      final studiedWords = await _loadStudiedWords();
      await _loadFavoriteStatuses(vocabulary);
      
      setState(() {
        _allVocabulary = vocabulary;
        _studiedWords = studiedWords;
        _isLoading = false;
      });
      await _applyFilters();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Load favorite statuses for all vocabulary
  Future<void> _loadFavoriteStatuses(List<Vocabulary> vocabulary) async {
    _favoriteStatus.clear();
    for (final vocab in vocabulary) {
      _favoriteStatus[vocab.word] = await FavoritesService.isFavorite(vocab.word);
    }
  }

  /// Load studied words from learning stats
  Future<Set<String>> _loadStudiedWords() async {
    try {
      // Only get known words as studied (unknown words are not considered studied)
      final prefs = await SharedPreferences.getInstance();
      final List<String> knownWordsList = prefs.getStringList('known_words') ?? [];
      
      return knownWordsList.toSet();
    } catch (e) {
      return <String>{};
    }
  }

  /// Filter vocabulary based on search query and current filter
  Future<void> _filterVocabulary(String query) async {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () async {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
      await _applyFilters();
    });
  }

  /// Apply filters based on current filter and search query
  Future<void> _applyFilters() async {
    final cacheKey = '${_searchQuery}_${_currentFilter}_${_sortBy}';
    
    // Check cache first
    if (_searchCache.containsKey(cacheKey)) {
      setState(() {
        _filteredVocabulary = _searchCache[cacheKey]!;
        _currentPage = 0;
        _hasMoreItems = _filteredVocabulary.length > _itemsPerPage;
      });
      return;
    }

    List<Vocabulary> filtered = List.from(_allVocabulary);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((vocab) {
        return vocab.word.toLowerCase().contains(_searchQuery) ||
            vocab.bengaliMeaning.toLowerCase().contains(_searchQuery) ||
            vocab.englishDefinition.toLowerCase().contains(_searchQuery);
      }).toList();
    }

    // Apply category filter
    switch (_currentFilter) {
      case 'Read':
        filtered = filtered.where((vocab) => _studiedWords.contains(vocab.word)).toList();
        break;
      case 'Unread':
        filtered = filtered.where((vocab) => !_studiedWords.contains(vocab.word)).toList();
        break;
      case 'Favourite':
        // Filter to only show favorited words
        filtered = filtered.where((vocab) => _favoriteStatus[vocab.word] == true).toList();
        break;
      case 'All':
      default:
        // No additional filtering
        break;
    }

    // Apply sorting
    if (_sortBy == 'Date') {
      await _applyDateSorting(filtered);
    } else {
      _applySorting(filtered);
    }

    // Cache the result
    _searchCache[cacheKey] = List.from(filtered);
    
    // Limit cache size
    if (_searchCache.length > 10) {
      final oldestKey = _searchCache.keys.first;
      _searchCache.remove(oldestKey);
    }

    setState(() {
      _filteredVocabulary = filtered;
      _currentPage = 0;
      _hasMoreItems = filtered.length > _itemsPerPage;
    });
    
  }

  /// Apply sorting to the filtered list
  void _applySorting(List<Vocabulary> list) {
    switch (_sortBy) {
      case 'Alphabetical':
        list.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
        break;
      case 'Reverse':
        list.sort((a, b) => b.word.toLowerCase().compareTo(a.word.toLowerCase()));
        break;
      case 'Random':
        list.shuffle();
        break;
      case 'Date':
        // For date sorting, we'll handle it in _applyFilters with async
        break;
    }
  }

  /// Apply date sorting to the filtered list (most recent first)
  Future<void> _applyDateSorting(List<Vocabulary> list) async {
    // Get study dates for all words
    final Map<String, DateTime?> studyDates = {};
    for (final vocab in list) {
      studyDates[vocab.word] = await LearningStatsService.getStudyDate(vocab.word);
    }
    
    // Sort by study date (most recent first, null dates last)
    list.sort((a, b) {
      final dateA = studyDates[a.word];
      final dateB = studyDates[b.word];
      
      // If both have dates, sort by most recent first
      if (dateA != null && dateB != null) {
        return dateB.compareTo(dateA);
      }
      
      // If only one has a date, prioritize it
      if (dateA != null && dateB == null) return -1;
      if (dateA == null && dateB != null) return 1;
      
      // If neither has a date, sort alphabetically
      return a.word.toLowerCase().compareTo(b.word.toLowerCase());
    });
  }

  /// Mark word as studied
  Future<void> _markAsStudied(Vocabulary vocab) async {
    HapticFeedback.mediumImpact(); // Stronger feedback for important action
    await LearningStatsService.markAsKnown(vocab.word);
    setState(() {
      _studiedWords.add(vocab.word);
    });
    await _applyFilters();
  }

  /// Mark word as unread
  Future<void> _markAsUnread(Vocabulary vocab) async {
    HapticFeedback.lightImpact(); // Add haptic feedback
    await LearningStatsService.markAsUnknown(vocab.word);
    setState(() {
      _studiedWords.remove(vocab.word);
    });
    await _applyFilters();
  }

  /// Toggle favorite status
  Future<void> _toggleFavorite(Vocabulary vocab) async {
    HapticFeedback.lightImpact(); // Add haptic feedback
    final isFavorite = _favoriteStatus[vocab.word] ?? false;
    if (isFavorite) {
      await FavoritesService.removeFromFavorites(vocab.word);
      _favoriteStatus[vocab.word] = false;
    } else {
      await FavoritesService.addToFavorites(vocab);
      _favoriteStatus[vocab.word] = true;
    }
    
    // If we're currently viewing favorites, refresh the filter
    if (_currentFilter == 'Favourite') {
      await _applyFilters();
    } else {
      setState(() {}); // Just refresh UI
    }
  }


  /// Set sort and filter with one action
  Future<void> _setSortAndFilter(String sort, String filter) async {
    // Clear cache when changing filters to ensure fresh results
    _searchCache.clear();
    
    
    setState(() {
      _sortBy = sort;
      _currentFilter = filter;
    });
    await _applyFilters();
  }

  /// Refresh data
  Future<void> _refreshData() async {
    await _loadVocabulary();
  }

  /// Refresh studied words
  Future<void> _refreshStudiedWords() async {
    final studiedWords = await _loadStudiedWords();
    setState(() {
      _studiedWords = studiedWords;
    });
    await _applyFilters();
  }

  /// Toggle selection mode
  void _toggleSelectionMode() {
    HapticFeedback.selectionClick(); // Selection feedback
    print('Toggling selection mode. Current mode: $_isSelectionMode');
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedWords.clear();
        _isAllSelected = false;
        print('Exiting selection mode. Cleared selections.');
      } else {
        print('Entering selection mode.');
      }
    });
  }

  /// Toggle word selection
  void _toggleWordSelection(String word) {
    HapticFeedback.lightImpact(); // Light feedback for selection
    print('Toggling selection for word: $word');
    setState(() {
      if (_selectedWords.contains(word)) {
        _selectedWords.remove(word);
        print('Removed from selection. Selected count: ${_selectedWords.length}');
      } else {
        _selectedWords.add(word);
        print('Added to selection. Selected count: ${_selectedWords.length}');
      }
      // Update select all state
      _updateSelectAllState();
    });
  }

  /// Update select all state based on current selection
  void _updateSelectAllState() {
    final visibleItems = _getPaginatedItems();
    _isAllSelected = visibleItems.isNotEmpty && 
        visibleItems.every((vocab) => _selectedWords.contains(vocab.word));
  }

  /// Mark selected words as studied
  Future<void> _markSelectedAsStudied() async {
    for (final word in _selectedWords) {
      await LearningStatsService.markAsKnown(word);
      _studiedWords.add(word);
    }
    setState(() {
      _selectedWords.clear();
      _isSelectionMode = false;
    });
    await _applyFilters();
  }

  /// Mark selected words as unread
  Future<void> _markSelectedAsUnread() async {
    for (final word in _selectedWords) {
      await LearningStatsService.markAsUnknown(word);
      _studiedWords.remove(word);
    }
    setState(() {
      _selectedWords.clear();
      _isSelectionMode = false;
    });
    await _applyFilters();
  }

  /// Add selected words to favorites
  Future<void> _addSelectedToFavorites() async {
    for (final word in _selectedWords) {
      final vocab = _allVocabulary.firstWhere((v) => v.word == word);
      await FavoritesService.addToFavorites(vocab);
      _favoriteStatus[word] = true;
    }
    setState(() {
      _selectedWords.clear();
      _isSelectionMode = false;
    });
  }

  /// Exit selection mode
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedWords.clear();
      _isAllSelected = false;
    });
  }

  /// Toggle select all items in current view
  void _toggleSelectAll() {
    setState(() {
      if (_isAllSelected) {
        // Deselect all
        _selectedWords.clear();
        _isAllSelected = false;
      } else {
        // Select all visible items
        _selectedWords.clear();
        for (var vocab in _getPaginatedItems()) {
          _selectedWords.add(vocab.word);
        }
        _isAllSelected = true;
      }
    });
  }

  /// Load more items for pagination
  Future<void> _loadMoreItems() async {
    if (!_hasMoreItems || _isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    // Simulate loading delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _currentPage++;
      _hasMoreItems = _filteredVocabulary.length > (_currentPage + 1) * _itemsPerPage;
      _isLoadingMore = false;
    });
  }

  /// Get paginated items
  List<Vocabulary> _getPaginatedItems() {
    final endIndex = (_currentPage + 1) * _itemsPerPage;
    return _filteredVocabulary.take(endIndex).toList();
  }

  /// Build selection icon button (icon only)
  Widget _buildSelectionIconButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onPressed != null 
              ? AppThemes.getPrimaryColor(context).withOpacity(0.2) 
              : AppThemes.getPrimaryColor(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5),
        ),
      ),
    );
  }

  /// Build selection action button
  Widget _buildSelectionActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: onPressed != null 
              ? AppThemes.getPrimaryColor(context).withOpacity(0.2) 
              : AppThemes.getPrimaryColor(context).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5),
            ),
            const SizedBox(width: 4),
            Text(
        label,
              style: GoogleFonts.lexend(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: onPressed != null ? Colors.white : Colors.white.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build quick action button
  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onTap, {bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? AppThemes.getPrimaryColor(context) : AppThemes.getCardColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppThemes.getPrimaryColor(context) : AppThemes.getBorderColor(context),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isActive 
                  ? AppThemes.getPrimaryColor(context).withOpacity(0.3)
                  : Colors.transparent,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              size: 18, 
              color: isActive ? Colors.white : AppThemes.getTextColor(context),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : AppThemes.getTextColor(context),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }


  /// Show sort and filter menu
  void _showSortFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppThemes.getCardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppThemes.getSecondaryTextColor(context).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Sort & Filter',
                    style: GoogleFonts.lexend(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppThemes.getTextColor(context),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Sort Options
                  Text(
                    'Sort By',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppThemes.getTextColor(context),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Sort chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Alphabetical', 'Reverse', 'Random', 'Date'].map((sortOption) {
                      final isSelected = _sortBy == sortOption;
                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            _sortBy = sortOption;
                          });
                          await _applyFilters();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppThemes.getPrimaryColor(context) : AppThemes.getCardColor(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppThemes.getPrimaryColor(context) : AppThemes.getBorderColor(context),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                    ? AppThemes.getPrimaryColor(context).withOpacity(0.3)
                                    : Colors.transparent,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            sortOption,
        style: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : AppThemes.getTextColor(context),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Filter Options
                  Text(
                    'Filter By',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppThemes.getTextColor(context),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Filter chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'Read', 'Unread', 'Favourite'].map((filterOption) {
                      final isSelected = _currentFilter == filterOption;
                      return GestureDetector(
                        onTap: () async {
        setState(() {
                            _currentFilter = filterOption;
                          });
                          await _applyFilters();
                          Navigator.pop(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppThemes.getPrimaryColor(context) : AppThemes.getCardColor(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppThemes.getPrimaryColor(context) : AppThemes.getBorderColor(context),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                    ? AppThemes.getPrimaryColor(context).withOpacity(0.3)
                                    : Colors.transparent,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            filterOption,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : AppThemes.getTextColor(context),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
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
          'Vocabulary List',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppThemes.getTextColor(context),
            letterSpacing: 0.2,
            height: 1.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.checklist,
              color: AppThemes.getTextColor(context),
            ),
            onPressed: _toggleSelectionMode,
          ),
          IconButton(
            icon: Icon(
              Icons.sort,
              color: AppThemes.getTextColor(context),
            ),
            onPressed: () => _showSortFilterMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
              focusNode: _searchFocusNode,
                onChanged: _filterVocabulary,
              style: GoogleFonts.lexend(
                color: AppThemes.getTextColor(context),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
                decoration: InputDecoration(
                hintText: 'Search words...',
                  hintStyle: GoogleFonts.lexend(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppThemes.getTextColor(context).withOpacity(0.7)
                      : AppThemes.getSecondaryTextColor(context),
                    fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppThemes.getSecondaryTextColor(context)
                      : AppThemes.getSecondaryTextColor(context),
                  size: 22,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: AppThemes.getSecondaryTextColor(context),
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _filterVocabulary('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppThemes.getCardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppThemes.getBorderColor(context).withOpacity(0.2)
                        : AppThemes.getBorderColor(context).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppThemes.getBorderColor(context).withOpacity(0.2)
                        : AppThemes.getBorderColor(context).withOpacity(0.5),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: AppThemes.getPrimaryColor(context).withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
          
          // Selection bar - positioned right after search bar
          if (_isSelectionMode)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppThemes.getPrimaryColor(context),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppThemes.getPrimaryColor(context).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Select All checkbox
                  GestureDetector(
                    onTap: _toggleSelectAll,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        _isAllSelected ? Icons.check_box : Icons.check_box_outline_blank,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Selection count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_selectedWords.length} selected',
                style: GoogleFonts.lexend(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Action buttons
                  _buildSelectionIconButton(
                    icon: Icons.favorite,
                    onPressed: _selectedWords.isNotEmpty ? _addSelectedToFavorites : null,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 8),
                  _buildSelectionIconButton(
                    icon: Icons.check_circle,
                    onPressed: _selectedWords.isNotEmpty ? _markSelectedAsStudied : null,
                    color: AppThemes.getPrimaryColor(context),
                  ),
                  const SizedBox(width: 8),
                  _buildSelectionIconButton(
                    icon: Icons.radio_button_unchecked,
                    onPressed: _selectedWords.isNotEmpty ? _markSelectedAsUnread : null,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  // Close button
                  GestureDetector(
                    onTap: _exitSelectionMode,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          
          // Quick action buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickActionButton(
                    'A-Z',
                    Icons.sort_by_alpha,
                    () => _setSortAndFilter('Alphabetical', 'All'),
                    isActive: _sortBy == 'Alphabetical' && _currentFilter == 'All',
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    'Recent',
                    Icons.access_time,
                    () => _setSortAndFilter('Date', 'All'),
                    isActive: _sortBy == 'Date' && _currentFilter == 'All',
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    'Unread',
                    Icons.radio_button_unchecked,
                    () => _setSortAndFilter('Alphabetical', 'Unread'),
                    isActive: _currentFilter == 'Unread',
                  ),
                  const SizedBox(width: 8),
                  _buildQuickActionButton(
                    'Favorites',
                    Icons.favorite,
                    () => _setSortAndFilter('Alphabetical', 'Favourite'),
                    isActive: _currentFilter == 'Favourite',
                  ),
                ],
              ),
            ),
          ),
          
          // Minimal spacing after filter chips
          const SizedBox(height: 8),
          
          // Vocabulary list
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppThemes.getPrimaryColor(context)),
                    ),
                  )
                : _filteredVocabulary.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                            onRefresh: _refreshData,
                            child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _getPaginatedItems().length + (_hasMoreItems ? 1 : 0),
                            itemBuilder: (context, index) {
                                if (index == _getPaginatedItems().length) {
                                  // Load more indicator
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Center(
                                      child: _isLoadingMore
                                          ? CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(AppThemes.getPrimaryColor(context)),
                                            )
                                          : ElevatedButton(
                                              onPressed: _hasMoreItems ? _loadMoreItems : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: AppThemes.getPrimaryColor(context),
                                                foregroundColor: Colors.white,
                                              ),
                                              child: Text(_hasMoreItems ? 'Load More' : 'No More Items'),
                                            ),
                                    ),
                                  );
                                }
                                final vocab = _getPaginatedItems()[index];
                              return _buildVocabularyCard(vocab);
                            },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  /// Build vocabulary card
  Widget _buildVocabularyCard(Vocabulary vocab) {
    final isStudied = _studiedWords.contains(vocab.word);
    final isFavorite = _favoriteStatus[vocab.word] ?? false;
    final isSelected = _selectedWords.contains(vocab.word);

    return Semantics(
      label: 'Vocabulary word: ${vocab.word}. Bengali meaning: ${vocab.bengaliMeaning}. English definition: ${vocab.englishDefinition}. ${isStudied ? 'Studied' : 'Not studied'}. ${isFavorite ? 'Favorited' : 'Not favorited'}. ${_isSelectionMode ? (isSelected ? 'Selected' : 'Not selected') : 'Long press to enter selection mode'}',
      button: true,
      child: _isSelectionMode 
          ? GestureDetector(
              onTap: () => _toggleWordSelection(vocab.word),
              child: _buildCardContent(vocab, isStudied, isFavorite, isSelected),
            )
          : Dismissible(
              key: Key(vocab.word),
              direction: DismissDirection.horizontal,
              background: _buildSwipeBackground(
                context, 
                isStudied ? 'Mark as Unread' : 'Mark as Studied', 
                isStudied ? Icons.undo : Icons.check_circle, 
                isStudied ? Colors.orange : Colors.green
              ),
              secondaryBackground: _buildSwipeBackground(
                context, 
                isStudied ? 'Mark as Unread' : 'Mark as Studied', 
                isStudied ? Icons.undo : Icons.check_circle, 
                isStudied ? Colors.orange : Colors.green
              ),
              confirmDismiss: (direction) async {
                // Don't actually dismiss, just perform action
                if (direction == DismissDirection.endToStart || direction == DismissDirection.startToEnd) {
                  await _handleSwipeAction(vocab, isStudied);
                }
                return false; // Don't dismiss the card
              },
              child: GestureDetector(
                onLongPress: _toggleSelectionMode,
                onTap: _isSelectionMode ? null : () => _markAsStudied(vocab),
                child: _buildCardContent(vocab, isStudied, isFavorite, isSelected),
              ),
            ),
    );
  }

  /// Build the card content (moved from main method)
  Widget _buildCardContent(Vocabulary vocab, bool isStudied, bool isFavorite, bool isSelected) {
    return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
            color: isSelected 
                ? AppThemes.getPrimaryColor(context).withOpacity(0.1) 
                : AppThemes.getCardColor(context),
            borderRadius: BorderRadius.circular(20),
            border: isSelected
                ? Border.all(color: AppThemes.getPrimaryColor(context), width: 2)
                : isStudied 
                    ? Border.all(color: AppThemes.getPrimaryColor(context).withOpacity(0.4), width: 2)
                    : null,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black.withOpacity(0.4)
                      : Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20), // Match container radius
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Word, studied status, and favorite button
                  Row(
                    children: [
                      if (_isSelectionMode) ...[
                        GestureDetector(
                          onTap: () => _toggleWordSelection(vocab.word),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                              key: ValueKey(isSelected),
                              color: isSelected 
                                  ? AppThemes.getPrimaryColor(context) 
                                  : AppThemes.getSecondaryTextColor(context),
                              size: 24,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          vocab.word,
                          style: GoogleFonts.lexend(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF4A90E2) // Brighter blue for dark mode
                                : AppThemes.getPrimaryColor(context),
                            letterSpacing: -0.3,
                            height: 1.1,
                          ),
                        ),
                      ),
                      if (isStudied) ...[
                        GestureDetector(
                          onTap: _isSelectionMode ? null : () => _markAsUnread(vocab),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                              color: _isSelectionMode 
                                  ? AppThemes.getPrimaryColor(context).withOpacity(0.3)
                                  : AppThemes.getPrimaryColor(context),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: _isSelectionMode 
                                      ? Colors.transparent
                                      : AppThemes.getPrimaryColor(context).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle, 
                                  color: _isSelectionMode 
                                      ? Colors.white.withOpacity(0.5)
                                      : Colors.white, 
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                            'Studied',
                            style: GoogleFonts.lexend(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                              color: _isSelectionMode 
                                  ? Colors.white.withOpacity(0.5)
                                  : Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      GestureDetector(
                        onTap: _isSelectionMode ? null : () async {
                          await _toggleFavorite(vocab);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _isSelectionMode 
                                ? AppThemes.getSecondaryTextColor(context).withOpacity(0.05)
                                : isFavorite 
                                    ? Colors.red.withOpacity(0.15)
                                    : AppThemes.getSecondaryTextColor(context).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _isSelectionMode 
                                    ? Colors.transparent
                                    : isFavorite 
                                        ? Colors.red.withOpacity(0.2)
                                        : Colors.transparent,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isSelectionMode 
                                ? AppThemes.getSecondaryTextColor(context).withOpacity(0.3)
                                : isFavorite 
                                    ? Colors.red 
                                    : AppThemes.getSecondaryTextColor(context),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                
                  const SizedBox(height: 16),
                
                // Bengali meaning
                Text(
                  vocab.bengaliMeaning,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppThemes.getTextColor(context),
                    letterSpacing: 0.1,
                    height: 1.3,
                  ),
                ),
                
                  const SizedBox(height: 12),
                
                // English definition
                Text(
                  vocab.englishDefinition,
                  style: GoogleFonts.lexend(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppThemes.getSecondaryTextColor(context),
                    letterSpacing: 0.1,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build swipe background (Samsung dialer style)
  Widget _buildSwipeBackground(BuildContext context, String actionText, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            actionText,
            style: GoogleFonts.lexend(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  /// Handle swipe action
  Future<void> _handleSwipeAction(Vocabulary vocab, bool isStudied) async {
    HapticFeedback.mediumImpact();
    
    if (isStudied) {
      // If already studied, mark as unread
      await _markAsUnread(vocab);
      _showSwipeSnackBar('${vocab.word} marked as unread', Icons.undo, Colors.orange);
    } else {
      // If not studied, mark as studied
      await _markAsStudied(vocab);
      _showSwipeSnackBar('${vocab.word} marked as studied', Icons.check_circle, Colors.green);
    }
  }

  /// Show swipe action feedback
  void _showSwipeSnackBar(String message, IconData icon, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.lexend(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 2000),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    String title, subtitle, actionText;
    IconData icon;
    VoidCallback? onAction;
    
    if (_searchQuery.isNotEmpty) {
      title = 'No results found';
      subtitle = 'Try a different search term or check spelling';
      actionText = 'Clear search';
      icon = Icons.search_off;
      onAction = () {
        _searchController.clear();
        _filterVocabulary('');
      };
    } else if (_currentFilter == 'Favourite') {
      title = 'No favorites yet';
      subtitle = 'Tap the heart icon on any word to add it to favorites';
      actionText = 'Browse all words';
      icon = Icons.favorite_border;
      onAction = () => _setSortAndFilter('Alphabetical', 'All');
    } else if (_currentFilter == 'Unread') {
      title = 'All caught up!';
      subtitle = 'You\'ve studied all the words. Great job!';
      actionText = 'View all words';
      icon = Icons.check_circle;
      onAction = () => _setSortAndFilter('Alphabetical', 'All');
    } else {
      title = 'No vocabulary found';
      subtitle = 'Try refreshing the app';
      actionText = 'Refresh';
      icon = Icons.book_outlined;
      onAction = _refreshData;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppThemes.getSecondaryTextColor(context).withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppThemes.getTextColor(context),
              letterSpacing: 0.2,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppThemes.getSecondaryTextColor(context),
              letterSpacing: 0.1,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
            if (onAction != null) ...[
              const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppThemes.getPrimaryColor(context),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: AppThemes.getPrimaryColor(context).withOpacity(0.3),
              ),
              child: Text(
                actionText,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ],
        ),
      ),
    );
  }

}
