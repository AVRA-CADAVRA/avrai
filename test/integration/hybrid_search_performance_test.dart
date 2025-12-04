import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/services/search_cache_service.dart';
import 'package:spots/core/services/ai_search_suggestions_service.dart';
import 'package:spots/data/repositories/hybrid_search_repository.dart';
import 'package:spots/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:spots/domain/usecases/search/hybrid_search_usecase.dart';

// Generate mocks
@GenerateMocks([
  HybridSearchUseCase,
  SearchCacheService,
  AISearchSuggestionsService,
])
import 'hybrid_search_performance_test.mocks.dart';

void main() {
  group('Phase 4: Hybrid Search Performance & AI Tests', () {
    late HybridSearchBloc bloc;
    late MockHybridSearchUseCase mockUseCase;
    late MockSearchCacheService mockCacheService;
    late MockAISearchSuggestionsService mockSuggestionsService;

    setUp(() {
      mockUseCase = MockHybridSearchUseCase();
      mockCacheService = MockSearchCacheService();
      mockSuggestionsService = MockAISearchSuggestionsService();

      bloc = HybridSearchBloc(
        hybridSearchUseCase: mockUseCase,
        cacheService: mockCacheService,
        suggestionsService: mockSuggestionsService,
      );
    });

    tearDown(() {
      bloc.close();
    });

    group('Cache Performance Tests', () {
      test('should use cache for repeated searches', () async {
        // Arrange
        final testResult = _createTestSearchResult();

        when(mockCacheService.getCachedResult(
          query: 'coffee',
          maxResults: 50,
          includeExternal: true,
        )).thenReturn(Future.value(testResult));

        // Act
        bloc.add(SearchHybridSpots(query: 'coffee'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockCacheService.getCachedResult(
          query: 'coffee',
          maxResults: 50,
          includeExternal: true,
        )).called(1);

        expect(bloc.state, isA<HybridSearchLoaded>());
        final state = bloc.state as HybridSearchLoaded;
        expect(state.fromCache, true);
      });

      test('should cache new search results', () async {
        // Arrange
        final testResult = _createTestSearchResult();

        when(mockCacheService.getCachedResult(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenReturn(Future.value(null));
        when(mockUseCase.searchSpots(
          query: 'restaurant',
          maxResults: 50,
          includeExternal: true,
        )).thenReturn(Future.value(testResult));

        // Act
        bloc.add(SearchHybridSpots(query: 'restaurant'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockCacheService.cacheResult(
          query: 'restaurant',
          result: testResult,
          maxResults: 50,
          includeExternal: true,
        )).called(1);
      });

      test('should provide cache statistics', () async {
        // Arrange
        final mockStats = {
          'cache_hits': 5,
          'cache_misses': 2,
          'hit_rate_percent': '71.4',
          'total_requests': 7,
        };

        when(mockCacheService.getCacheStatistics()).thenReturn(mockStats);

        // Act
        final stats = bloc.getCacheStatistics();

        // Assert
        expect(stats, equals(mockStats));
        expect(stats['hit_rate_percent'], equals('71.4'));
      });

      test('should warm up cache with popular searches', () async {
        // Arrange
        when(mockCacheService.prefetchPopularSearches(
          searchFunction: any,
        )).thenReturn(Future.value());

        // Act
        bloc.add(WarmupCache());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockCacheService.prefetchPopularSearches(
          searchFunction: any,
        )).called(1);
      });

      test('should clear cache when requested', () async {
        // Arrange
        when(mockCacheService.clearCache(preserveOffline: true))
            .thenReturn(Future.value());
        when(mockSuggestionsService.clearLearningData()).thenReturn(null);

        // Act
        bloc.add(ClearSearchCache());
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockCacheService.clearCache(preserveOffline: true)).called(1);
        verify(mockSuggestionsService.clearLearningData()).called(1);
      });
    });

    group('AI Suggestions Tests', () {
      test('should generate search suggestions', () async {
        // Arrange
        final mockSuggestions = [
          SearchSuggestion(
            text: 'coffee shops',
            type: SuggestionType.completion,
            confidence: 0.9,
            icon: 'local_cafe',
          ),
          SearchSuggestion(
            text: 'cafe near me',
            type: SuggestionType.contextual,
            confidence: 0.8,
            icon: 'near_me',
            context: 'Perfect for morning',
          ),
        ];

        when(mockSuggestionsService.generateSuggestions(
          query: 'cof',
          userLocation: any,
          communityTrends: any,
        )).thenReturn(Future.value(mockSuggestions));

        // Act
        bloc.add(GetSearchSuggestions(query: 'cof'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(bloc.state, isA<HybridSearchSuggestionsLoaded>());
        final state = bloc.state as HybridSearchSuggestionsLoaded;
        expect(state.suggestions.length, equals(2));
        expect(state.suggestions.first.text, equals('coffee shops'));
      });

      test('should learn from search behavior', () async {
        // Arrange
        final testResult = _createTestSearchResult();

        when(mockCacheService.getCachedResult(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenReturn(Future.value(null));
        when(mockUseCase.searchSpots(
          query: 'pizza',
          maxResults: 50,
          includeExternal: true,
        )).thenReturn(Future.value(testResult));

        // Act
        bloc.add(SearchHybridSpots(query: 'pizza'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        verify(mockSuggestionsService.learnFromSearch(
          query: 'pizza',
          results: testResult.spots,
        )).called(1);
      });

      test('should provide search patterns analytics', () async {
        // Arrange
        final mockPatterns = {
          'recent_searches': ['coffee', 'restaurant', 'park'],
          'top_categories': [
            {'category': 'food', 'count': 5},
            {'category': 'coffee', 'count': 3},
          ],
          'search_frequency': {
            'morning': 4,
            'afternoon': 2,
            'evening': 1,
          },
          'total_searches': 7,
        };

        when(mockSuggestionsService.getSearchPatterns())
            .thenReturn(mockPatterns);

        // Act
        final patterns = bloc.getSearchPatterns();

        // Assert
        expect(patterns, equals(mockPatterns));
        expect(patterns['total_searches'], equals(7));
      });
    });

    group('Performance Optimization Tests', () {
      test('should complete search within performance threshold', () async {
        // Arrange
        final testResult = _createTestSearchResult();

        when(mockCacheService.getCachedResult(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenReturn(Future.value(null));
        when(mockUseCase.searchSpots(
          query: 'test',
          maxResults: 50,
          includeExternal: true,
        )).thenReturn(Future.value(testResult));

        // Act
        final stopwatch = Stopwatch()..start();
        bloc.add(SearchHybridSpots(query: 'test'));
        await Future.delayed(const Duration(milliseconds: 100));
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(500)); // Under 500ms
        expect(bloc.state, isA<HybridSearchLoaded>());
      });

      test('should handle large result sets efficiently', () async {
        // Arrange
        final largeResult = _createLargeSearchResult(100); // 100 spots

        when(mockCacheService.getCachedResult(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenReturn(Future.value(null));
        when(mockUseCase.searchSpots(
          query: 'popular',
          maxResults: 100,
          includeExternal: true,
        )).thenReturn(Future.value(largeResult));

        // Act
        bloc.add(SearchHybridSpots(query: 'popular', maxResults: 100));
        await Future.delayed(const Duration(milliseconds: 200));

        // Assert
        expect(bloc.state, isA<HybridSearchLoaded>());
        final state = bloc.state as HybridSearchLoaded;
        expect(state.spots.length, equals(100));
        expect(state.totalCount, equals(100));
      });

      test('should maintain community-first ranking under load', () async {
        // Arrange
        final mixedResult = _createMixedCommunityExternalResult();

        when(mockCacheService.getCachedResult(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenReturn(Future.value(null));
        when(mockUseCase.searchSpots(
          query: 'mixed',
          maxResults: 50,
          includeExternal: true,
        )).thenReturn(Future.value(mixedResult));

        // Act
        bloc.add(SearchHybridSpots(query: 'mixed'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(bloc.state, isA<HybridSearchLoaded>());
        final state = bloc.state as HybridSearchLoaded;
        expect(state.isCommunityPrioritized, true);
        expect(state.communityRatio, greaterThanOrEqualTo(0.5));
      });
    });

    group('Integration Tests', () {
      test('should integrate cache, AI, and search seamlessly', () async {
        // Arrange
        final testResult = _createTestSearchResult();
        final suggestions = [
          SearchSuggestion(
            text: 'related search',
            type: SuggestionType.completion,
            confidence: 0.8,
            icon: 'search',
          ),
        ];

        when(mockCacheService.getCachedResult(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenReturn(Future.value(null));
        when(mockUseCase.searchSpots(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenReturn(Future.value(testResult));
        when(mockSuggestionsService.generateSuggestions(
          query: anyNamed('query'),
          userLocation: anyNamed('userLocation'),
          communityTrends: anyNamed('communityTrends'),
        )).thenReturn(Future.value(suggestions));

        // Act - Search, then get suggestions
        bloc.add(SearchHybridSpots(query: 'integration'));
        await Future.delayed(const Duration(milliseconds: 100));

        bloc.add(GetSearchSuggestions(query: 'int'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(bloc.state, isA<HybridSearchSuggestionsLoaded>());
        verify(mockSuggestionsService.learnFromSearch(
          query: anyNamed('query'),
          results: anyNamed('results'),
        )).called(1);
        verify(mockCacheService.cacheResult(
          query: anyNamed('query'),
          result: anyNamed('result'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).called(1);
      });

      test('should handle offline scenarios gracefully', () async {
        // Arrange - Simulate offline with cached data
        final cachedResult = _createTestSearchResult();

        when(mockCacheService.getCachedResult(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenReturn(Future.value(cachedResult));

        // Act
        bloc.add(SearchHybridSpots(query: 'offline'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(bloc.state, isA<HybridSearchLoaded>());
        final state = bloc.state as HybridSearchLoaded;
        expect(state.fromCache, true);
        expect(state.spots.isNotEmpty, true);
      });
    });

    group('Error Handling Tests', () {
      test('should handle cache failures gracefully', () async {
        // Arrange
        when(mockCacheService.getCachedResult(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenThrow(Exception('Cache error'));
        when(mockUseCase.searchSpots(
          query: anyNamed('query'),
          maxResults: anyNamed('maxResults'),
          includeExternal: anyNamed('includeExternal'),
        )).thenThrow(Exception('Search error'));

        // Act
        bloc.add(SearchHybridSpots(query: 'error'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(bloc.state, isA<HybridSearchError>());
      });

      test('should recover from AI suggestions errors', () async {
        // Arrange
        when(mockSuggestionsService.generateSuggestions(
          query: anyNamed('query'),
          userLocation: anyNamed('userLocation'),
          communityTrends: anyNamed('communityTrends'),
        )).thenThrow(Exception('AI error'));

        // Act
        bloc.add(GetSearchSuggestions(query: 'error'));
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert
        expect(bloc.state, isA<HybridSearchError>());
      });
    });
  });
}

// Helper functions for creating test data

HybridSearchResult _createTestSearchResult() {
  final spots = [
    Spot(
      id: '1',
      name: 'Test Coffee Shop',
      description: 'A great coffee shop',
      latitude: 40.7128,
      longitude: -74.0060,
      category: 'Coffee',
      rating: 4.5,
      createdBy: 'test_user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['coffee', 'community'],
    ),
    Spot(
      id: '2',
      name: 'Test Restaurant',
      description: 'A nice restaurant',
      latitude: 40.7589,
      longitude: -73.9851,
      category: 'Food',
      rating: 4.0,
      createdBy: 'test_user',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tags: ['food', 'community'],
    ),
  ];

  return HybridSearchResult(
    spots: spots,
    communityCount: 2,
    externalCount: 0,
    totalCount: 2,
    searchDuration: const Duration(milliseconds: 150),
    sources: {'community': 2},
  );
}

HybridSearchResult _createLargeSearchResult(int count) {
  final spots = List.generate(
      count,
      (index) => Spot(
            id: 'test_$index',
            name: 'Test Spot $index',
            description: 'Test description $index',
            latitude: 40.7128 + (index * 0.001),
            longitude: -74.0060 + (index * 0.001),
            category: 'Test',
            rating: 4.0 + (index % 10) * 0.1,
            createdBy: 'test_user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: ['test', 'community'],
          ));

  return HybridSearchResult(
    spots: spots,
    communityCount: count,
    externalCount: 0,
    totalCount: count,
    searchDuration: const Duration(milliseconds: 200),
    sources: {'community': count},
  );
}

HybridSearchResult _createMixedCommunityExternalResult() {
  final communitySpots = List.generate(
      6,
      (index) => Spot(
            id: 'community_$index',
            name: 'Community Spot $index',
            description: 'Community description $index',
            latitude: 40.7128 + (index * 0.001),
            longitude: -74.0060 + (index * 0.001),
            category: 'Community',
            rating: 4.5,
            createdBy: 'community_user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: ['community'],
          ));

  final externalSpots = List.generate(
      4,
      (index) => Spot(
            id: 'external_$index',
            name: 'External Spot $index',
            description: 'External description $index',
            latitude: 40.7128 + (index * 0.002),
            longitude: -74.0060 + (index * 0.002),
            category: 'External',
            rating: 4.0,
            createdBy: 'google_places_api',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            tags: ['external_data', 'google_places'],
            metadata: {'source': 'google_places', 'is_external': true},
          ));

  return HybridSearchResult(
    spots: [...communitySpots, ...externalSpots],
    communityCount: 6,
    externalCount: 4,
    totalCount: 10,
    searchDuration: const Duration(milliseconds: 300),
    sources: {'community': 6, 'google_places': 4},
  );
}
