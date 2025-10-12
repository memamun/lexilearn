import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/vocabulary.dart';
import '../services/vocab_loader.dart';
import '../services/favorites_service.dart';
import '../services/learning_stats_service.dart';

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
      // Get all studied words (known + unknown)
      final prefs = await SharedPreferences.getInstance();
      final List<String> knownWordsList = prefs.getStringList('known_words') ?? [];
      final List<String> unknownWordsList = prefs.getStringList('unknown_words') ?? [];
      
      return {...knownWordsList, ...unknownWordsList}.toSet();
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
        // For favorites, we'll filter in the build method using FutureBuilder
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
    setState(() {}); // Refresh UI
  }

  /// Get favorite words
  Future<List<Vocabulary>> _getFavoriteWords() async {
    final favorites = await FavoritesService.getFavorites();
    return favorites;
  }

  /// Set sort and filter with one action
  Future<void> _setSortAndFilter(String sort, String filter) async {
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

  /// Toggle selection mode
  void _toggleSelectionMode() {
    HapticFeedback.selectionClick(); // Selection feedback
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedWords.clear();
        _isAllSelected = false;
      }
    });
  }

  /// Toggle word selection
  void _toggleWordSelection(String word) {
    HapticFeedback.lightImpact(); // Light feedback for selection
    setState(() {
      if (_selectedWords.contains(word)) {
        _selectedWords.remove(word);
      } else {
        _selectedWords.add(word);
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
              ? Colors.white.withOpacity(0.2) 
              : Colors.white.withOpacity(0.1),
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
              ? Colors.white.withOpacity(0.2) 
              : Colors.white.withOpacity(0.1),
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1132D4) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? const Color(0xFF1132D4) : const Color(0xFFE0E0E0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? Colors.white : const Color(0xFF2C3E50)),
            const SizedBox(width: 4),
            Text(
        label,
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF2C3E50),
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
      backgroundColor: const Color(0xFFF6F6F8),
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
                        color: const Color(0xFF2C3E50).withOpacity(0.3),
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
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Sort Options
                  Text(
                    'Sort By',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1132D4) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF1132D4) : const Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            sortOption,
        style: GoogleFonts.lexend(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isSelected ? Colors.white : const Color(0xFF2C3E50),
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
                      color: const Color(0xFF2C3E50),
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF1132D4) : const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
        color: isSelected ? const Color(0xFF1132D4) : const Color(0xFFE0E0E0),
        width: 1,
      ),
                          ),
                          child: Text(
                            filterOption,
                            style: GoogleFonts.lexend(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF2C3E50),
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
      backgroundColor: const Color(0xFFF6F6F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F6F8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Vocabulary List',
          style: GoogleFonts.lexend(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2C3E50),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isSelectionMode ? Icons.close : Icons.checklist,
              color: const Color(0xFF2C3E50),
            ),
            onPressed: _toggleSelectionMode,
          ),
          IconButton(
            icon: const Icon(Icons.sort, color: Color(0xFF2C3E50)),
            onPressed: () => _showSortFilterMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterVocabulary,
                decoration: InputDecoration(
                  hintText: 'Search words',
                  hintStyle: GoogleFonts.lexend(
                    color: const Color(0xFF2C3E50).withOpacity(0.5),
                    fontSize: 16,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF2C3E50),
                    size: 24,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(
                            Icons.clear,
                            color: Color(0xFF2C3E50),
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _filterVocabulary('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                style: GoogleFonts.lexend(
                  fontSize: 16,
                  color: const Color(0xFF2C3E50),
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
                color: const Color(0xFF1132D4),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1132D4).withOpacity(0.3),
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
                    color: Colors.green,
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
                ? const Center(child: CircularProgressIndicator())
                : _filteredVocabulary.isEmpty
                    ? _buildEmptyState()
                    : _currentFilter == 'Favourite'
                        ? FutureBuilder<List<Vocabulary>>(
                            future: _getFavoriteWords(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final favoriteWords = snapshot.data ?? [];
                              return favoriteWords.isEmpty
                                  ? _buildEmptyState()
                                  : RefreshIndicator(
                                      onRefresh: _refreshData,
                                      child: ListView.builder(
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      itemCount: favoriteWords.length,
                                      itemBuilder: (context, index) {
                                        final vocab = favoriteWords[index];
                                        return _buildVocabularyCard(vocab);
                                      },
                                      ),
                                    );
                            },
                          )
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
                                          ? const CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1132D4)),
                                            )
                                          : ElevatedButton(
                                              onPressed: _hasMoreItems ? _loadMoreItems : null,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF1132D4),
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
        child: GestureDetector(
        onLongPress: _isSelectionMode ? null : _toggleSelectionMode,
        onTap: _isSelectionMode 
            ? () => _toggleWordSelection(vocab.word)
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1132D4).withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(20), // More rounded
            border: isSelected
                ? Border.all(color: const Color(0xFF1132D4), width: 2)
                : isStudied 
                    ? Border.all(color: Colors.green.withOpacity(0.3), width: 2)
                    : null,
              boxShadow: [
                BoxShadow(
                color: Colors.black.withOpacity(0.08), // Slightly stronger
                blurRadius: 12, // Increased
                offset: const Offset(0, 4), // Increased
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
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            key: ValueKey(isSelected),
                            color: isSelected ? const Color(0xFF1132D4) : const Color(0xFF2C3E50).withOpacity(0.5),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          vocab.word,
                          style: GoogleFonts.lexend(
                            fontSize: 24, // Increased from 22
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1132D4),
                          ),
                        ),
                      ),
                      if (isStudied) ...[
                        GestureDetector(
                          onTap: () => _markAsUnread(vocab),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Increased padding
                          decoration: BoxDecoration(
                            color: Colors.green,
                              borderRadius: BorderRadius.circular(16), // More rounded
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, color: Colors.white, size: 14),
                                const SizedBox(width: 4),
                                Text(
                            'Studied',
                            style: GoogleFonts.lexend(
                                    fontSize: 12, // Increased from 10
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      IconButton(
                        onPressed: () async {
                          await _toggleFavorite(vocab);
                        },
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : const Color(0xFF2C3E50).withOpacity(0.5),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                
                  const SizedBox(height: 12), // Increased from 8
                
                // Bengali meaning
                Text(
                  vocab.bengaliMeaning,
                  style: GoogleFonts.lexend(
                      fontSize: 16, // Decreased from 18 for better hierarchy
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                
                  const SizedBox(height: 8),
                
                // English definition
                Text(
                  vocab.englishDefinition,
                  style: GoogleFonts.lexend(
                      fontSize: 15, // Increased from 14 for better readability
                      color: const Color(0xFF2C3E50).withOpacity(0.7), // Less muted
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          ),
        ),
      ),
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
            color: const Color(0xFF2C3E50).withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
              title,
            style: GoogleFonts.lexend(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
              subtitle,
            style: GoogleFonts.lexend(
              fontSize: 14,
                color: const Color(0xFF2C3E50).withOpacity(0.7),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null) ...[
              const SizedBox(height: 24),
            ElevatedButton(
                onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1132D4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                  actionText,
                style: GoogleFonts.lexend(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
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
