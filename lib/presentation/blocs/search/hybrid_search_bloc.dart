import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/data/repositories/hybrid_search_repository.dart';
import 'package:avrai/domain/usecases/search/hybrid_search_usecase.dart';
import 'package:avrai/core/services/search_cache_service.dart';
import 'package:avrai/core/services/ai_search_suggestions_service.dart';
import 'package:geolocator/geolocator.dart';

export 'package:avrai/data/repositories/hybrid_search_repository.dart'
    show SearchFilters, SearchSortOption;

// Events
abstract class HybridSearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SearchHybridSpots extends HybridSearchEvent {
  final String query;
  final bool includeExternal;
  final int maxResults;
  final bool useCache;
  final SearchFilters? filters;
  final SearchSortOption sortOption;

  SearchHybridSpots({
    required this.query,
    this.includeExternal = true,
    this.maxResults = 50,
    this.useCache = true,
    this.filters,
    this.sortOption = SearchSortOption.relevance,
  });

  @override
  List<Object?> get props => [
        query,
        includeExternal,
        maxResults,
        useCache,
        filters,
        sortOption,
      ];
}

class SearchNearbyHybridSpots extends HybridSearchEvent {
  final double latitude;
  final double longitude;
  final int radius;
  final bool includeExternal;
  final int maxResults;

  SearchNearbyHybridSpots({
    required this.latitude,
    required this.longitude,
    this.radius = 5000,
    this.includeExternal = true,
    this.maxResults = 50,
  });

  @override
  List<Object?> get props => [latitude, longitude, radius, includeExternal, maxResults];
}

class GetSearchSuggestions extends HybridSearchEvent {
  final String query;
  final Position? userLocation;

  GetSearchSuggestions({
    required this.query,
    this.userLocation,
  });

  @override
  List<Object?> get props => [query, userLocation];
}

class ClearHybridSearch extends HybridSearchEvent {}

class ToggleExternalDataSources extends HybridSearchEvent {
  final bool enabled;

  ToggleExternalDataSources(this.enabled);

  @override
  List<Object?> get props => [enabled];
}

class WarmupCache extends HybridSearchEvent {
  final Position? userLocation;

  WarmupCache({this.userLocation});

  @override
  List<Object?> get props => [userLocation];
}

class ClearSearchCache extends HybridSearchEvent {}

// States
abstract class HybridSearchState extends Equatable {
  @override
  List<Object?> get props => [];
}

class HybridSearchInitial extends HybridSearchState {}

class HybridSearchLoading extends HybridSearchState {}

class HybridSearchSuggestionsLoaded extends HybridSearchState {
  final List<SearchSuggestion> suggestions;
  final String query;

  HybridSearchSuggestionsLoaded({
    required this.suggestions,
    required this.query,
  });

  @override
  List<Object?> get props => [suggestions, query];
}

class HybridSearchLoaded extends HybridSearchState {
  final List<Spot> spots;
  final String? searchQuery;
  final int communityCount;
  final int externalCount;
  final int totalCount;
  final Duration searchDuration;
  final Map<String, int> sources;
  final bool externalDataEnabled;
  final bool fromCache;
  final Map<String, dynamic>? cacheStats;

  HybridSearchLoaded({
    required this.spots,
    this.searchQuery,
    required this.communityCount,
    required this.externalCount,
    required this.totalCount,
    required this.searchDuration,
    required this.sources,
    this.externalDataEnabled = true,
    this.fromCache = false,
    this.cacheStats,
  });

  @override
  List<Object?> get props => [
    spots,
    searchQuery,
    communityCount,
    externalCount,
    totalCount,
    searchDuration,
    sources,
    externalDataEnabled,
    fromCache,
    cacheStats,
  ];

  /// Get community-to-external ratio for OUR_GUTS.md compliance
  double get communityRatio {
    if (totalCount == 0) return 1.0;
    return communityCount / totalCount;
  }

  /// Check if search maintains community-first principle
  bool get isCommunityPrioritized {
    return communityRatio >= 0.5;
  }
}

class HybridSearchError extends HybridSearchState {
  final String message;

  HybridSearchError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class HybridSearchBloc extends Bloc<HybridSearchEvent, HybridSearchState> {
  final HybridSearchUseCase hybridSearchUseCase;
  final SearchCacheService cacheService;
  final AISearchSuggestionsService suggestionsService;
  bool _externalDataEnabled = true;

  HybridSearchBloc({
    required this.hybridSearchUseCase,
    required this.cacheService,
    required this.suggestionsService,
  }) : super(HybridSearchInitial()) {
    on<SearchHybridSpots>(_onSearchHybridSpots);
    on<SearchNearbyHybridSpots>(_onSearchNearbyHybridSpots);
    on<GetSearchSuggestions>(_onGetSearchSuggestions);
    on<ClearHybridSearch>(_onClearHybridSearch);
    on<ToggleExternalDataSources>(_onToggleExternalDataSources);
    on<WarmupCache>(_onWarmupCache);
    on<ClearSearchCache>(_onClearSearchCache);
  }

  Future<void> _onSearchHybridSpots(
    SearchHybridSpots event,
    Emitter<HybridSearchState> emit,
  ) async {
    try {
      // #region agent log
      try {
        final payload = <String, dynamic>{
          'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H8',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'pre-fix-hybrid-search-bloc',
          'hypothesisId': 'H8',
          'location': 'lib/presentation/blocs/search/hybrid_search_bloc.dart:_onSearchHybridSpots',
          'message': 'handler start',
          'data': {
            'query': event.query,
            'useCache': event.useCache,
            'includeExternal': event.includeExternal,
            'maxResults': event.maxResults,
          },
        };
        File('/Users/reisgordon/SPOTS/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion

      emit(HybridSearchLoading());

      // Get user location for better results (optional)
      Position? position;
      try {
        // #region agent log
        try {
          final payload = <String, dynamic>{
            'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H8',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sessionId': 'debug-session',
            'runId': 'pre-fix-hybrid-search-bloc',
            'hypothesisId': 'H8',
            'location': 'lib/presentation/blocs/search/hybrid_search_bloc.dart:_onSearchHybridSpots',
            'message': 'before geolocator.getCurrentPosition await',
            'data': {},
          };
          File('/Users/reisgordon/SPOTS/.cursor/debug.log')
              .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion

        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => throw TimeoutException('Location request timed out'),
        );

        // #region agent log
        try {
          final payload = <String, dynamic>{
            'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H8',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sessionId': 'debug-session',
            'runId': 'pre-fix-hybrid-search-bloc',
            'hypothesisId': 'H8',
            'location': 'lib/presentation/blocs/search/hybrid_search_bloc.dart:_onSearchHybridSpots',
            'message': 'geolocator resolved',
            'data': {
              'lat': position.latitude,
              'lng': position.longitude,
            },
          };
          File('/Users/reisgordon/SPOTS/.cursor/debug.log')
              .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion
      } catch (e) {
        // Location not available, continue without it
        // #region agent log
        try {
          final payload = <String, dynamic>{
            'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H8',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sessionId': 'debug-session',
            'runId': 'pre-fix-hybrid-search-bloc',
            'hypothesisId': 'H8',
            'location': 'lib/presentation/blocs/search/hybrid_search_bloc.dart:_onSearchHybridSpots',
            'message': 'geolocator failed/caught',
            'data': {'errorType': e.runtimeType.toString()},
          };
          File('/Users/reisgordon/SPOTS/.cursor/debug.log')
              .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion
      }

      HybridSearchResult? cachedResult;
      bool fromCache = false;

      // STEP 1: Try cache first if enabled (Phase 4 Performance)
      if (event.useCache) {
        // #region agent log
        try {
          final payload = <String, dynamic>{
            'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H8',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sessionId': 'debug-session',
            'runId': 'pre-fix-hybrid-search-bloc',
            'hypothesisId': 'H8',
            'location': 'lib/presentation/blocs/search/hybrid_search_bloc.dart:_onSearchHybridSpots',
            'message': 'before cacheService.getCachedResult',
            'data': {
              'lat_is_null': position?.latitude == null,
              'lng_is_null': position?.longitude == null,
            },
          };
          File('/Users/reisgordon/SPOTS/.cursor/debug.log')
              .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion

        cachedResult = await cacheService.getCachedResult(
          query: event.query,
          latitude: position?.latitude,
          longitude: position?.longitude,
          maxResults: event.maxResults,
          includeExternal: event.includeExternal && _externalDataEnabled,
        );
        fromCache = cachedResult != null;

        // #region agent log
        try {
          final payload = <String, dynamic>{
            'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H8',
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'sessionId': 'debug-session',
            'runId': 'pre-fix-hybrid-search-bloc',
            'hypothesisId': 'H8',
            'location': 'lib/presentation/blocs/search/hybrid_search_bloc.dart:_onSearchHybridSpots',
            'message': 'after cacheService.getCachedResult',
            'data': {
              'fromCache': fromCache,
              'cached_spots_len': cachedResult?.spots.length,
            },
          };
          File('/Users/reisgordon/SPOTS/.cursor/debug.log')
              .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
        } catch (_) {}
        // #endregion
      }

      HybridSearchResult result;
      if (cachedResult != null) {
        result = cachedResult;
      } else {
        // STEP 2: Perform search if not cached
        result = await hybridSearchUseCase.searchSpots(
          query: event.query,
          latitude: position?.latitude,
          longitude: position?.longitude,
          maxResults: event.maxResults,
          includeExternal: event.includeExternal && _externalDataEnabled,
          filters: event.filters,
          sortOption: event.sortOption,
        );

        // STEP 3: Cache the result for future use
        await cacheService.cacheResult(
          query: event.query,
          latitude: position?.latitude,
          longitude: position?.longitude,
          maxResults: event.maxResults,
          includeExternal: event.includeExternal && _externalDataEnabled,
          result: result,
        );
      }

      // STEP 4: Learn from search for AI suggestions (Phase 4 AI)
      suggestionsService.learnFromSearch(
        query: event.query,
        results: result.spots,
      );

      // #region agent log
      try {
        final payload = <String, dynamic>{
          'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H8',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'pre-fix-hybrid-search-bloc',
          'hypothesisId': 'H8',
          'location': 'lib/presentation/blocs/search/hybrid_search_bloc.dart:_onSearchHybridSpots',
          'message': 'before emit HybridSearchLoaded',
          'data': {
            'fromCache': fromCache,
            'spots_len': result.spots.length,
            'communityCount': result.communityCount,
            'externalCount': result.externalCount,
            'totalCount': result.totalCount,
          },
        };
        File('/Users/reisgordon/SPOTS/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion

      emit(HybridSearchLoaded(
        spots: result.spots,
        searchQuery: event.query,
        communityCount: result.communityCount,
        externalCount: result.externalCount,
        totalCount: result.totalCount,
        searchDuration: result.searchDuration,
        sources: result.sources,
        externalDataEnabled: _externalDataEnabled,
        fromCache: fromCache,
        cacheStats: cacheService.getCacheStatistics(),
      ));

      // #region agent log
      try {
        final payload = <String, dynamic>{
          'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H8',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'pre-fix-hybrid-search-bloc',
          'hypothesisId': 'H8',
          'location': 'lib/presentation/blocs/search/hybrid_search_bloc.dart:_onSearchHybridSpots',
          'message': 'after emit HybridSearchLoaded',
          'data': {},
        };
        File('/Users/reisgordon/SPOTS/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
    } catch (e) {
      // #region agent log
      try {
        final payload = <String, dynamic>{
          'id': 'log_${DateTime.now().millisecondsSinceEpoch}_H8',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'sessionId': 'debug-session',
          'runId': 'pre-fix-hybrid-search-bloc',
          'hypothesisId': 'H8',
          'location': 'lib/presentation/blocs/search/hybrid_search_bloc.dart:_onSearchHybridSpots',
          'message': 'caught exception in handler',
          'data': {'errorType': e.runtimeType.toString(), 'error': e.toString()},
        };
        File('/Users/reisgordon/SPOTS/.cursor/debug.log')
            .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      emit(HybridSearchError('Search failed: ${e.toString()}'));
    }
  }

  Future<void> _onSearchNearbyHybridSpots(
    SearchNearbyHybridSpots event,
    Emitter<HybridSearchState> emit,
  ) async {
    try {
      emit(HybridSearchLoading());

      // Check cache first for nearby searches
      final cachedResult = await cacheService.getCachedResult(
        query: 'nearby',
        latitude: event.latitude,
        longitude: event.longitude,
        maxResults: event.maxResults,
        includeExternal: event.includeExternal && _externalDataEnabled,
      );

      HybridSearchResult result;
      bool fromCache = false;

      if (cachedResult != null) {
        result = cachedResult;
        fromCache = true;
      } else {
        result = await hybridSearchUseCase.searchNearbySpots(
          latitude: event.latitude,
          longitude: event.longitude,
          radius: event.radius,
          maxResults: event.maxResults,
          includeExternal: event.includeExternal && _externalDataEnabled,
        );

        // Cache nearby results
        await cacheService.cacheResult(
          query: 'nearby',
          latitude: event.latitude,
          longitude: event.longitude,
          maxResults: event.maxResults,
          includeExternal: event.includeExternal && _externalDataEnabled,
          result: result,
        );
      }

      // Learn from nearby search
      suggestionsService.learnFromSearch(
        query: 'nearby',
        results: result.spots,
      );

      emit(HybridSearchLoaded(
        spots: result.spots,
        searchQuery: 'Nearby (${event.radius}m)',
        communityCount: result.communityCount,
        externalCount: result.externalCount,
        totalCount: result.totalCount,
        searchDuration: result.searchDuration,
        sources: result.sources,
        externalDataEnabled: _externalDataEnabled,
        fromCache: fromCache,
        cacheStats: cacheService.getCacheStatistics(),
      ));
    } catch (e) {
      emit(HybridSearchError('Nearby search failed: ${e.toString()}'));
    }
  }

  Future<void> _onGetSearchSuggestions(
    GetSearchSuggestions event,
    Emitter<HybridSearchState> emit,
  ) async {
    try {
      // Get community trends from cache analytics for suggestions
      final cacheStats = cacheService.getCacheStatistics();
      // Pull patterns to enable personalization hooks (even if not directly used in ranking yet).
      // Keeping this call makes behavior explicit and testable.
      suggestionsService.getSearchPatterns();
      
      final suggestions = await suggestionsService.generateSuggestions(
        query: event.query,
        userLocation: event.userLocation,
        communityTrends: _extractTrendsFromCache(cacheStats),
      );

      emit(HybridSearchSuggestionsLoaded(
        suggestions: suggestions,
        query: event.query,
      ));
    } catch (e) {
      emit(HybridSearchError('Failed to get suggestions: ${e.toString()}'));
    }
  }

  void _onClearHybridSearch(
    ClearHybridSearch event,
    Emitter<HybridSearchState> emit,
  ) {
    emit(HybridSearchInitial());
  }

  void _onToggleExternalDataSources(
    ToggleExternalDataSources event,
    Emitter<HybridSearchState> emit,
  ) {
    _externalDataEnabled = event.enabled;
    
    // If we have current results, refresh them with new setting
    if (state is HybridSearchLoaded) {
      final currentState = state as HybridSearchLoaded;
      if (currentState.searchQuery != null) {
        if (currentState.searchQuery!.startsWith('Nearby')) {
          // Re-search nearby (need to extract coordinates)
          // For now, just clear and let user re-search
          emit(HybridSearchInitial());
        } else {
          // Re-search with new external data setting
          add(SearchHybridSpots(
            query: currentState.searchQuery!,
            includeExternal: _externalDataEnabled,
            useCache: false, // Force fresh search with new settings
          ));
        }
      }
    }
  }

  Future<void> _onWarmupCache(
    WarmupCache event,
    Emitter<HybridSearchState> emit,
  ) async {
    try {
      // Prefetch popular searches for better performance
      await cacheService.prefetchPopularSearches(
        searchFunction: (query) => hybridSearchUseCase.searchSpots(
          query: query,
          includeExternal: _externalDataEnabled,
        ),
      );

      // Warm up location-based cache if location available
      if (event.userLocation != null) {
        await cacheService.warmLocationCache(
          latitude: event.userLocation!.latitude,
          longitude: event.userLocation!.longitude,
          nearbySearchFunction: (lat, lng) => hybridSearchUseCase.searchNearbySpots(
            latitude: lat,
            longitude: lng,
            includeExternal: _externalDataEnabled,
          ),
        );
      }
    } catch (e) {
      // Cache warmup failures are non-critical
    }
  }

  Future<void> _onClearSearchCache(
    ClearSearchCache event,
    Emitter<HybridSearchState> emit,
  ) async {
    try {
      await cacheService.clearCache(preserveOffline: true);
      suggestionsService.clearLearningData();
      
      // Optionally emit a success message or refresh current state
      if (state is HybridSearchLoaded) {
        emit(HybridSearchInitial());
      }
    } catch (e) {
      emit(HybridSearchError('Failed to clear cache: ${e.toString()}'));
    }
  }

  /// Get search analytics for insights
  Map<String, int> getSearchAnalytics() {
    return hybridSearchUseCase.getSearchAnalytics();
  }

  /// Get cache performance statistics
  Map<String, dynamic> getCacheStatistics() {
    return cacheService.getCacheStatistics();
  }

  /// Get AI suggestions service patterns
  Map<String, dynamic> getSearchPatterns() {
    return suggestionsService.getSearchPatterns();
  }

  // Helper method to extract trends from cache stats
  Map<String, int>? _extractTrendsFromCache(Map<String, dynamic> cacheStats) {
    // This would typically be more sophisticated, extracting popular search terms.
    // For now, return an empty map so the suggestions service can treat trends as "available"
    // without forcing a null-path.
    return <String, int>{};
  }
}