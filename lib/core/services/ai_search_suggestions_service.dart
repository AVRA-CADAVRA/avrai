import 'dart:developer' as developer;
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:spots/core/models/spot.dart';

/// AI-Powered Search Suggestions Service for Phase 4
/// OUR_GUTS.md: "Effortless, Seamless Discovery" - Intelligent, context-aware search assistance
class AISearchSuggestionsService {
  static const String _logName = 'AISearchSuggestionsService';
  
  // Context tracking (privacy-preserving)
  final List<String> _recentSearches = [];
  final Map<String, int> _categoryPreferences = {};
  final Map<String, List<String>> _locationSuggestions = {};
  final Map<String, DateTime> _searchTimestamps = {};
  
  // AI suggestion patterns
  final Map<String, List<String>> _synonymMap = {
    'food': ['restaurant', 'dining', 'eat', 'meal', 'cuisine', 'cafe', 'bistro'],
    'coffee': ['cafe', 'espresso', 'latte', 'cappuccino', 'brew', 'roastery'],
    'drinks': ['bar', 'pub', 'brewery', 'cocktails', 'wine', 'spirits'],
    'outdoor': ['park', 'hiking', 'nature', 'garden', 'trail', 'beach'],
    'shopping': ['store', 'mall', 'boutique', 'market', 'retail', 'shop'],
    'culture': ['museum', 'gallery', 'art', 'theater', 'history', 'exhibit'],
    'fitness': ['gym', 'yoga', 'sport', 'workout', 'training', 'exercise'],
    'entertainment': ['cinema', 'movie', 'show', 'concert', 'event', 'fun'],
  };
  
  final Map<String, List<String>> _contextualSuggestions = {
    'morning': ['coffee', 'breakfast', 'bakery', 'juice bar', 'gym'],
    'lunch': ['restaurant', 'cafe', 'deli', 'food truck', 'quick bite'],
    'evening': ['bar', 'restaurant', 'cinema', 'theater', 'nightlife'],
    'weekend': ['park', 'museum', 'shopping', 'brunch', 'activities'],
    'rainy': ['museum', 'mall', 'cafe', 'library', 'indoor activities'],
    'sunny': ['park', 'beach', 'outdoor dining', 'hiking', 'garden'],
  };
  
  final List<String> _discoveryPrompts = [
    'Try searching for specific cuisines like "Thai food" or "Italian"',
    'Look for activities like "hiking trails" or "art galleries"',
    'Find places by mood: "cozy cafe" or "lively bar"',
    'Search by time: "late night food" or "Sunday brunch"',
    'Discover by feature: "outdoor seating" or "live music"',
    'Explore categories: "local bookstore" or "vintage shopping"',
  ];
  
  /// Generate intelligent search suggestions
  /// OUR_GUTS.md: "Authenticity Over Algorithms" - Suggestions based on real community preferences
  Future<List<SearchSuggestion>> generateSuggestions({
    required String query,
    Position? userLocation,
    List<Spot>? recentSpots,
    Map<String, int>? communityTrends,
  }) async {
    try {
      // #region agent log
      developer.log('Generating suggestions: query="$query", hasLocation=${userLocation != null}, recentSpots=${recentSpots?.length ?? 0}, trends=${communityTrends != null ? communityTrends.length : 0}', name: _logName);
      // #endregion
      
      final suggestions = <SearchSuggestion>[];
      final normalizedQuery = query.toLowerCase().trim();
      
      // STEP 1: Query completion suggestions
      if (normalizedQuery.isNotEmpty) {
        final completions = await _generateQueryCompletions(normalizedQuery);
        suggestions.addAll(completions);
        // #region agent log
        developer.log('Query completions: ${completions.length} suggestions', name: _logName);
        // #endregion
      }
      
      // STEP 2: Contextual suggestions based on time/location
      if (userLocation != null) {
        final contextual = await _generateContextualSuggestions(userLocation);
        suggestions.addAll(contextual);
        // #region agent log
        developer.log('Contextual suggestions: ${contextual.length} suggestions', name: _logName);
        // #endregion
      }
      
      // STEP 3: Personalized suggestions based on search history
      final personalized = _generatePersonalizedSuggestions(normalizedQuery);
      suggestions.addAll(personalized);
      // #region agent log
      developer.log('Personalized suggestions: ${personalized.length} suggestions', name: _logName);
      // #endregion
      
      // STEP 4: Community trend suggestions
      if (communityTrends != null) {
        final trends = _generateCommunityTrendSuggestions(communityTrends);
        suggestions.addAll(trends);
        // #region agent log
        developer.log('Community trend suggestions: ${trends.length} suggestions', name: _logName);
        // #endregion
      }
      
      // STEP 5: Discovery suggestions for exploration
      if (query.isEmpty || query.length < 3) {
        final discovery = _generateDiscoverySuggestions();
        suggestions.addAll(discovery);
        // #region agent log
        developer.log('Discovery suggestions: ${discovery.length} suggestions', name: _logName);
        // #endregion
      }
      
      // STEP 6: Natural language processing suggestions
      final nlp = _generateNLPSuggestions(normalizedQuery);
      suggestions.addAll(nlp);
      // #region agent log
      developer.log('NLP suggestions: ${nlp.length} suggestions', name: _logName);
      // #endregion
      
      // Deduplicate and rank suggestions
      final uniqueSuggestions = _deduplicateAndRank(suggestions);
      
      // Track suggestion generation for learning
      _trackSuggestionGeneration(query, uniqueSuggestions.length);
      
      // #region agent log
      developer.log('Generated ${uniqueSuggestions.length} unique suggestions (from ${suggestions.length} total) for: "$query"', name: _logName);
      // #endregion
      return uniqueSuggestions.take(8).toList(); // Limit to top 8
      
    } catch (e) {
      // #region agent log
      developer.log('Error generating suggestions: $e', name: _logName);
      // #endregion
      return [];
    }
  }
  
  /// Learn from user search behavior
  /// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable" - Local learning only
  void learnFromSearch({
    required String query,
    required List<Spot> results,
    String? selectedSpotId,
  }) {
    try {
      // #region agent log
      developer.log('Learning from search: query="$query", results=${results.length}, selectedSpot=$selectedSpotId', name: _logName);
      // #endregion
      
      final normalizedQuery = query.toLowerCase().trim();
      
      // Track recent searches (privacy-preserving)
      _recentSearches.add(normalizedQuery);
      if (_recentSearches.length > 20) {
        _recentSearches.removeAt(0); // Keep only recent 20
      }
      
      // Learn category preferences
      final categoryCounts = <String, int>{};
      for (final spot in results) {
        final category = spot.category.toLowerCase();
        _categoryPreferences[category] = (_categoryPreferences[category] ?? 0) + 1;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
      
      // #region agent log
      developer.log('Category preferences updated: ${categoryCounts.length} unique categories, total preferences: ${_categoryPreferences.length}', name: _logName);
      // #endregion
      
      // Track search timestamps for temporal patterns
      _searchTimestamps[normalizedQuery] = DateTime.now();
      
      // Clean up old data (privacy-preserving)
      final beforeCleanup = _searchTimestamps.length;
      _cleanupOldLearningData();
      final afterCleanup = _searchTimestamps.length;
      
      // #region agent log
      developer.log('Learned from search: "$query" (${results.length} results), recentSearches=${_recentSearches.length}, timestamps: $beforeCleanup -> $afterCleanup', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error learning from search: $e', name: _logName);
      // #endregion
    }
  }
  
  /// Get user's search patterns for insights
  Map<String, dynamic> getSearchPatterns() {
    final topCategories = _categoryPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final searchFrequency = _getSearchFrequencyPatterns();
    
    final patterns = {
      'recent_searches': _recentSearches.take(10).toList(),
      'top_categories': topCategories.take(5).map((e) => {
        'category': e.key,
        'count': e.value,
      }).toList(),
      'search_frequency': searchFrequency,
      'total_searches': _searchTimestamps.length,
    };
    
    // #region agent log
    final recentSearchesList = patterns['recent_searches'] as List;
    final topCategoriesList = patterns['top_categories'] as List;
    developer.log('Retrieved search patterns: ${recentSearchesList.length} recent, ${topCategoriesList.length} top categories, ${patterns['total_searches']} total searches', name: _logName);
    // #endregion
    
    return patterns;
  }
  
  /// Clear learning data (privacy control)
  void clearLearningData() {
    _recentSearches.clear();
    _categoryPreferences.clear();
    _locationSuggestions.clear();
    _searchTimestamps.clear();
    developer.log('Cleared all learning data', name: _logName);
  }
  
  // Private helper methods
  
  Future<List<SearchSuggestion>> _generateQueryCompletions(String query) async {
    final suggestions = <SearchSuggestion>[];
    
    // Synonym-based completions
    for (final category in _synonymMap.keys) {
      if (category.startsWith(query)) {
        suggestions.add(SearchSuggestion(
          text: category,
          type: SuggestionType.completion,
          confidence: 0.9,
          icon: _getCategoryIcon(category),
        ));
      }
      
      // Check synonyms
      for (final synonym in _synonymMap[category]!) {
        if (synonym.startsWith(query)) {
          suggestions.add(SearchSuggestion(
            text: synonym,
            type: SuggestionType.completion,
            confidence: 0.8,
            icon: _getCategoryIcon(category),
          ));
        }
      }
    }
    
    // Recent search completions
    for (final recent in _recentSearches) {
      if (recent.startsWith(query) && recent != query) {
        suggestions.add(SearchSuggestion(
          text: recent,
          type: SuggestionType.recent,
          confidence: 0.7,
          icon: 'history',
        ));
      }
    }
    
    return suggestions;
  }
  
  Future<List<SearchSuggestion>> _generateContextualSuggestions(Position location) async {
    final suggestions = <SearchSuggestion>[];
    final hour = DateTime.now().hour;
    final isWeekend = DateTime.now().weekday >= 6;
    
    // Time-based suggestions
    String timeContext;
    if (hour < 11) {
      timeContext = 'morning';
    } else if (hour < 15) {
      timeContext = 'lunch';
    } else if (hour < 19) {
      timeContext = 'afternoon';
    } else {
      timeContext = 'evening';
    }
    
    final timeContextSuggestions = _contextualSuggestions[timeContext] ?? [];
    for (final suggestion in timeContextSuggestions.take(3)) {
      suggestions.add(SearchSuggestion(
        text: suggestion,
        type: SuggestionType.contextual,
        confidence: 0.8,
        icon: _getCategoryIcon(suggestion),
        context: 'Perfect for $timeContext',
      ));
    }
    
    // Weekend suggestions
    if (isWeekend) {
      final weekendSuggestions = _contextualSuggestions['weekend'] ?? [];
      for (final suggestion in weekendSuggestions.take(2)) {
        suggestions.add(SearchSuggestion(
          text: suggestion,
          type: SuggestionType.contextual,
          confidence: 0.7,
          icon: _getCategoryIcon(suggestion),
          context: 'Great for weekends',
        ));
      }
    }
    
    return suggestions;
  }
  
  List<SearchSuggestion> _generatePersonalizedSuggestions(String query) {
    final suggestions = <SearchSuggestion>[];
    
    // Category preference suggestions
    final sortedCategories = _categoryPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final entry in sortedCategories.take(3)) {
      if (entry.key.contains(query) || query.isEmpty) {
        suggestions.add(SearchSuggestion(
          text: entry.key,
          type: SuggestionType.personalized,
          confidence: 0.6 + (entry.value / 20.0).clamp(0.0, 0.3), // Higher confidence for frequent categories
          icon: _getCategoryIcon(entry.key),
          context: 'You often search for this',
        ));
      }
    }
    
    return suggestions;
  }
  
  List<SearchSuggestion> _generateCommunityTrendSuggestions(Map<String, int> trends) {
    final suggestions = <SearchSuggestion>[];
    final sortedTrends = trends.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (final trend in sortedTrends.take(3)) {
      suggestions.add(SearchSuggestion(
        text: trend.key,
        type: SuggestionType.trending,
        confidence: 0.7,
        icon: 'trending_up',
        context: 'Trending in your community',
      ));
    }
    
    return suggestions;
  }
  
  List<SearchSuggestion> _generateDiscoverySuggestions() {
    final suggestions = <SearchSuggestion>[];
    final random = Random();
    
    // Random discovery prompts
    final selectedPrompts = _discoveryPrompts.toList()..shuffle(random);
    for (final prompt in selectedPrompts.take(2)) {
      suggestions.add(SearchSuggestion(
        text: prompt,
        type: SuggestionType.discovery,
        confidence: 0.5,
        icon: 'explore',
        context: 'Discover something new',
      ));
    }
    
    return suggestions;
  }
  
  List<SearchSuggestion> _generateNLPSuggestions(String query) {
    final suggestions = <SearchSuggestion>[];
    
    // Intent detection
    if (query.contains('near me') || query.contains('nearby')) {
      suggestions.add(SearchSuggestion(
        text: 'Find places nearby',
        type: SuggestionType.action,
        confidence: 0.9,
        icon: 'near_me',
        context: 'Use your location',
      ));
    }
    
    if (query.contains('open') || query.contains('hours')) {
      suggestions.add(SearchSuggestion(
        text: 'Places open now',
        type: SuggestionType.action,
        confidence: 0.8,
        icon: 'schedule',
        context: 'Check opening hours',
      ));
    }
    
    if (query.contains('best') || query.contains('top')) {
      suggestions.add(SearchSuggestion(
        text: 'Highly rated places',
        type: SuggestionType.action,
        confidence: 0.8,
        icon: 'star',
        context: 'Community favorites',
      ));
    }
    
    return suggestions;
  }
  
  List<SearchSuggestion> _deduplicateAndRank(List<SearchSuggestion> suggestions) {
    final seen = <String>{};
    final unique = <SearchSuggestion>[];
    
    // Sort by confidence first
    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    for (final suggestion in suggestions) {
      if (!seen.contains(suggestion.text.toLowerCase())) {
        seen.add(suggestion.text.toLowerCase());
        unique.add(suggestion);
      }
    }
    
    return unique;
  }
  
  String _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'restaurant':
      case 'dining':
        return 'restaurant';
      case 'coffee':
      case 'cafe':
        return 'local_cafe';
      case 'drinks':
      case 'bar':
        return 'local_bar';
      case 'outdoor':
      case 'park':
        return 'park';
      case 'shopping':
      case 'store':
        return 'shopping_bag';
      case 'culture':
      case 'museum':
        return 'museum';
      case 'fitness':
      case 'gym':
        return 'fitness_center';
      case 'entertainment':
      case 'cinema':
        return 'movie';
      default:
        return 'search';
    }
  }
  
  void _trackSuggestionGeneration(String query, int count) {
    // Privacy-preserving analytics
    developer.log('Generated $count suggestions for query length: ${query.length}', name: _logName);
  }
  
  void _cleanupOldLearningData() {
    // Keep only last 7 days of timestamps
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    _searchTimestamps.removeWhere((query, timestamp) => timestamp.isBefore(cutoff));
  }
  
  Map<String, int> _getSearchFrequencyPatterns() {
    final patterns = <String, int>{};
    
    for (final timestamp in _searchTimestamps.values) {
      final hour = timestamp.hour;
      String period;
      
      if (hour < 6) period = 'night';
      else if (hour < 12) period = 'morning';
      else if (hour < 17) period = 'afternoon';
      else if (hour < 21) period = 'evening';
      else period = 'night';
      
      patterns[period] = (patterns[period] ?? 0) + 1;
    }
    
    // #region agent log
    developer.log('Search frequency patterns: ${patterns.length} periods tracked, total searches: ${_searchTimestamps.length}', name: _logName);
    // #endregion
    
    return patterns;
  }
}

/// Search suggestion with type and confidence
class SearchSuggestion {
  final String text;
  final SuggestionType type;
  final double confidence;
  final String icon;
  final String? context;
  
  SearchSuggestion({
    required this.text,
    required this.type,
    required this.confidence,
    required this.icon,
    this.context,
  });
  
  @override
  String toString() => 'SearchSuggestion(text: $text, type: $type, confidence: $confidence)';
}

enum SuggestionType {
  completion,    // Query completion
  recent,        // Recent searches
  contextual,    // Time/location context
  personalized,  // User preferences
  trending,      // Community trends
  discovery,     // Exploration prompts
  action,        // Action suggestions
}