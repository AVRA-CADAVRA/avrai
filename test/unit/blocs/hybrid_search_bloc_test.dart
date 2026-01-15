/// HybridSearchBloc Unit Tests - Phase 4: BLoC State Management Testing
///
/// Comprehensive testing of HybridSearchBloc with AI-powered search, caching, and performance optimization
/// Ensures optimal development stages and deployment optimization
/// Tests current implementation as-is without modifying production code
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:avrai/data/repositories/hybrid_search_repository.dart';
import '../../helpers/bloc_test_helpers.dart';
import '../../mocks/bloc_mock_dependencies.dart';

void main() {
  group('HybridSearchBloc', () {
    late HybridSearchBloc hybridSearchBloc;
    late MockHybridSearchUseCase mockHybridSearchUseCase;
    late MockSearchCacheService mockSearchCacheService;
    late MockAISearchSuggestionsService mockAISearchSuggestionsService;

    setUpAll(() {
      BlocMockFactory.registerFallbacks();
      // Register fallback values for search-specific objects
      registerFallbackValue(HybridSearchResult.empty());
      registerFallbackValue(SearchSortOption.relevance);
      registerFallbackValue(const SearchFilters());
      registerFallbackValue(Position(
        latitude: 0.0,
        longitude: 0.0,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      ));
    });

    setUp(() {
      mockHybridSearchUseCase = BlocMockFactory.hybridSearchUseCase;
      mockSearchCacheService = BlocMockFactory.searchCacheService;
      mockAISearchSuggestionsService =
          BlocMockFactory.aiSearchSuggestionsService;

      BlocMockFactory.resetAll();
      MockBehaviorSetup.setupSuccessfulSearch();

      hybridSearchBloc = HybridSearchBloc(
        hybridSearchUseCase: mockHybridSearchUseCase,
        cacheService: mockSearchCacheService,
        suggestionsService: mockAISearchSuggestionsService,
      );
    });

    tearDown(() {
      hybridSearchBloc.close();
    });

    group('Reservation Filter', () {
      const testQuery = 'restaurant';

      blocTest<HybridSearchBloc, HybridSearchState>(
        'passes reservation filter to use case when filter is enabled',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(
          SearchHybridSpots(
            query: testQuery,
            filters: const SearchFilters(reservationAvailable: true),
          ),
        ),
        wait: const Duration(milliseconds: 10),
        verify: (_) {
          verify(() => mockHybridSearchUseCase.searchSpots(
                query: testQuery,
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: 50,
                includeExternal: true,
                filters: any(
                  named: 'filters',
                  that: predicate<SearchFilters?>(
                    (filters) =>
                        filters != null && filters.reservationAvailable == true,
                  ),
                ),
                sortOption: any(named: 'sortOption'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'passes null filters when reservation filter is not enabled',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(
          SearchHybridSpots(
            query: testQuery,
            filters: null,
          ),
        ),
        wait: const Duration(milliseconds: 10),
        verify: (_) {
          verify(() => mockHybridSearchUseCase.searchSpots(
                query: testQuery,
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: 50,
                includeExternal: true,
                filters: null,
                sortOption: any(named: 'sortOption'),
              )).called(1);
        },
      );
    });

    group('Initial State', () {
      test('should have HybridSearchInitial as initial state', () {
        expect(hybridSearchBloc.state, isA<HybridSearchInitial>());
      });
    });

    group('SearchHybridSpots Event', () {
      const testQuery = 'coffee shop';

      blocTest<HybridSearchBloc, HybridSearchState>(
        'emits [HybridSearchLoading, HybridSearchLoaded] when search succeeds',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(SearchHybridSpots(query: testQuery)),
        // The bloc performs async work (location attempt + search + cache write). Give it a beat to emit + verify.
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>()
              .having((state) => state.spots.length, 'spots length', 10)
              .having((state) => state.searchQuery, 'search query', testQuery)
              .having((state) => state.communityCount, 'community count', 5)
              .having((state) => state.externalCount, 'external count', 5)
              .having((state) => state.totalCount, 'total count', 10)
              .having((state) => state.externalDataEnabled,
                  'external data enabled', true)
              .having((state) => state.fromCache, 'from cache', false),
        ],
        verify: (_) {
          verify(() => mockHybridSearchUseCase.searchSpots(
                query: testQuery,
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: 50,
                includeExternal: true,
                filters: any(named: 'filters'),
                sortOption: any(named: 'sortOption'),
              )).called(1);

          verify(() => mockSearchCacheService.cacheResult(
                query: testQuery,
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: 50,
                includeExternal: true,
                result: any(named: 'result'),
              )).called(1);

          verify(() => mockAISearchSuggestionsService.learnFromSearch(
                query: testQuery,
                results: any(named: 'results'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'uses cached results when available',
        build: () {
          when(() => mockSearchCacheService.getCachedResult(
                query: any(named: 'query'),
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
              )).thenAnswer((_) async => HybridSearchResult(
                spots: TestDataFactory.createTestSpots(5),
                communityCount: 3,
                externalCount: 2,
                totalCount: 5,
                searchDuration: const Duration(milliseconds: 50),
                sources: {'community': 3, 'external': 2},
              ));
          return hybridSearchBloc;
        },
        act: (bloc) =>
            bloc.add(SearchHybridSpots(query: testQuery, useCache: true)),
        // The bloc performs async work (location attempt + cache read). Give it a beat to emit.
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>()
              .having((state) => state.fromCache, 'from cache', true)
              .having((state) => state.spots.length, 'spots length', 5),
        ],
        verify: (_) {
          verify(() => mockSearchCacheService.getCachedResult(
                query: testQuery,
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: 50,
                includeExternal: true,
              )).called(1);

          // Should not call actual search if cache hit
          verifyNever(() => mockHybridSearchUseCase.searchSpots(
                query: any(named: 'query'),
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
                filters: any(named: 'filters'),
                sortOption: any(named: 'sortOption'),
              ));
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'bypasses cache when useCache is false',
        build: () => hybridSearchBloc,
        act: (bloc) =>
            bloc.add(SearchHybridSpots(query: testQuery, useCache: false)),
        // Async: location attempt + search + cache write.
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>()
              .having((state) => state.fromCache, 'from cache', false),
        ],
        verify: (_) {
          verifyNever(() => mockSearchCacheService.getCachedResult(
                query: any(named: 'query'),
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
              ));

          verify(() => mockHybridSearchUseCase.searchSpots(
                query: testQuery,
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: 50,
                includeExternal: true,
                filters: any(named: 'filters'),
                sortOption: any(named: 'sortOption'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'handles custom maxResults parameter',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(SearchHybridSpots(
          query: testQuery,
          maxResults: 25,
        )),
        // Async: location attempt + search call.
        wait: const Duration(milliseconds: 10),
        verify: (_) {
          verify(() => mockHybridSearchUseCase.searchSpots(
                query: testQuery,
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: 25,
                includeExternal: true,
                filters: any(named: 'filters'),
                sortOption: any(named: 'sortOption'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'handles includeExternal false parameter',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(SearchHybridSpots(
          query: testQuery,
          includeExternal: false,
        )),
        // Async: location attempt + search call.
        wait: const Duration(milliseconds: 10),
        verify: (_) {
          verify(() => mockHybridSearchUseCase.searchSpots(
                query: testQuery,
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: 50,
                includeExternal: false,
                filters: any(named: 'filters'),
                sortOption: any(named: 'sortOption'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'emits [HybridSearchLoading, HybridSearchError] when search fails',
        build: () {
          when(() => mockHybridSearchUseCase.searchSpots(
                query: any(named: 'query'),
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
                filters: any(named: 'filters'),
                sortOption: any(named: 'sortOption'),
              )).thenThrow(Exception('Search failed'));
          return hybridSearchBloc;
        },
        act: (bloc) => bloc.add(SearchHybridSpots(query: testQuery)),
        // Async: location attempt + failing search path.
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchError>().having(
              (state) => state.message, 'message', contains('Search failed')),
        ],
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'handles empty search results',
        build: () {
          when(() => mockHybridSearchUseCase.searchSpots(
                query: any(named: 'query'),
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
                filters: any(named: 'filters'),
                sortOption: any(named: 'sortOption'),
              )).thenAnswer((_) async => HybridSearchResult.empty());
          return hybridSearchBloc;
        },
        act: (bloc) => bloc.add(SearchHybridSpots(query: testQuery)),
        // Async: location attempt + search path.
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>()
              .having((state) => state.spots.length, 'spots length', 0)
              .having((state) => state.totalCount, 'total count', 0),
        ],
      );
    });

    group('SearchNearbyHybridSpots Event', () {
      const testLatitude = 37.7749;
      const testLongitude = -122.4194;
      const testRadius = 1000;

      blocTest<HybridSearchBloc, HybridSearchState>(
        'emits [HybridSearchLoading, HybridSearchLoaded] when nearby search succeeds',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(SearchNearbyHybridSpots(
          latitude: testLatitude,
          longitude: testLongitude,
          radius: testRadius,
        )),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>()
              .having((state) => state.searchQuery, 'search query',
                  'Nearby (${testRadius}m)')
              .having((state) => state.spots.length, 'spots length', 5)
              .having((state) => state.communityCount, 'community count', 3)
              .having((state) => state.externalCount, 'external count', 2),
        ],
        verify: (_) {
          verify(() => mockHybridSearchUseCase.searchNearbySpots(
                latitude: testLatitude,
                longitude: testLongitude,
                radius: testRadius,
                maxResults: 50,
                includeExternal: true,
              )).called(1);

          verify(() => mockSearchCacheService.cacheResult(
                query: 'nearby',
                latitude: testLatitude,
                longitude: testLongitude,
                maxResults: 50,
                includeExternal: true,
                result: any(named: 'result'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'uses cached results for nearby searches',
        build: () {
          when(() => mockSearchCacheService.getCachedResult(
                query: 'nearby',
                latitude: testLatitude,
                longitude: testLongitude,
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
              )).thenAnswer((_) async => HybridSearchResult(
                spots: TestDataFactory.createTestSpots(3),
                communityCount: 2,
                externalCount: 1,
                totalCount: 3,
                searchDuration: const Duration(milliseconds: 25),
                sources: {'community': 2, 'external': 1},
              ));
          return hybridSearchBloc;
        },
        act: (bloc) => bloc.add(SearchNearbyHybridSpots(
          latitude: testLatitude,
          longitude: testLongitude,
        )),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>()
              .having((state) => state.fromCache, 'from cache', true)
              .having((state) => state.spots.length, 'spots length', 3),
        ],
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'handles custom maxResults and includeExternal parameters',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(SearchNearbyHybridSpots(
          latitude: testLatitude,
          longitude: testLongitude,
          maxResults: 25,
          includeExternal: false,
        )),
        verify: (_) {
          verify(() => mockHybridSearchUseCase.searchNearbySpots(
                latitude: testLatitude,
                longitude: testLongitude,
                radius: 5000, // default
                maxResults: 25,
                includeExternal: false,
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'emits [HybridSearchLoading, HybridSearchError] when nearby search fails',
        build: () {
          when(() => mockHybridSearchUseCase.searchNearbySpots(
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                radius: any(named: 'radius'),
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
              )).thenThrow(Exception('Nearby search failed'));
          return hybridSearchBloc;
        },
        act: (bloc) => bloc.add(SearchNearbyHybridSpots(
          latitude: testLatitude,
          longitude: testLongitude,
        )),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchError>().having((state) => state.message, 'message',
              contains('Nearby search failed')),
        ],
      );
    });

    group('GetSearchSuggestions Event', () {
      const testQuery = 'cof';

      blocTest<HybridSearchBloc, HybridSearchState>(
        'emits [HybridSearchSuggestionsLoaded] when suggestions are generated successfully',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(GetSearchSuggestions(query: testQuery)),
        expect: () => [
          isA<HybridSearchSuggestionsLoaded>()
              .having((state) => state.query, 'query', testQuery)
              .having(
                  (state) => state.suggestions.length, 'suggestions length', 2)
              .having((state) => state.suggestions.first.text,
                  'first suggestion', 'coffee shop'),
        ],
        verify: (_) {
          verify(() => mockAISearchSuggestionsService.generateSuggestions(
                query: testQuery,
                userLocation: any(named: 'userLocation'),
                communityTrends: any(named: 'communityTrends'),
              )).called(1);

          verify(() => mockSearchCacheService.getCacheStatistics()).called(1);
          verify(() => mockAISearchSuggestionsService.getSearchPatterns())
              .called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'includes user location in suggestions when provided',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(GetSearchSuggestions(
          query: testQuery,
          userLocation: Position(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ),
        )),
        verify: (_) {
          verify(() => mockAISearchSuggestionsService.generateSuggestions(
                query: testQuery,
                userLocation: any(named: 'userLocation'),
                communityTrends: any(named: 'communityTrends'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'emits [HybridSearchError] when suggestions generation fails',
        build: () {
          when(() => mockAISearchSuggestionsService.generateSuggestions(
                query: any(named: 'query'),
                userLocation: any(named: 'userLocation'),
                communityTrends: any(named: 'communityTrends'),
              )).thenThrow(Exception('Suggestions failed'));
          return hybridSearchBloc;
        },
        act: (bloc) => bloc.add(GetSearchSuggestions(query: testQuery)),
        expect: () => [
          isA<HybridSearchError>().having((state) => state.message, 'message',
              contains('Failed to get suggestions')),
        ],
      );
    });

    group('ClearHybridSearch Event', () {
      blocTest<HybridSearchBloc, HybridSearchState>(
        'emits [HybridSearchInitial] when clearing search',
        seed: () => HybridSearchLoaded(
          spots: TestDataFactory.createTestSpots(5),
          searchQuery: 'test',
          communityCount: 3,
          externalCount: 2,
          totalCount: 5,
          searchDuration: const Duration(milliseconds: 100),
          sources: const {'community': 3, 'external': 2},
        ),
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(ClearHybridSearch()),
        expect: () => [
          isA<HybridSearchInitial>(),
        ],
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'can clear from any state',
        seed: () => HybridSearchError('Some error'),
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(ClearHybridSearch()),
        expect: () => [
          isA<HybridSearchInitial>(),
        ],
      );
    });

    group('ToggleExternalDataSources Event', () {
      blocTest<HybridSearchBloc, HybridSearchState>(
        'enables external data sources',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(ToggleExternalDataSources(true)),
        verify: (_) {
          // Verify internal state change (would need to be tested through subsequent search)
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'disables external data sources',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(ToggleExternalDataSources(false)),
        verify: (_) {
          // Verify internal state change (would need to be tested through subsequent search)
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'refreshes current search when toggling external data',
        seed: () => HybridSearchLoaded(
          spots: TestDataFactory.createTestSpots(5),
          searchQuery: 'coffee',
          communityCount: 3,
          externalCount: 2,
          totalCount: 5,
          searchDuration: const Duration(milliseconds: 100),
          sources: const {'community': 3, 'external': 2},
        ),
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(ToggleExternalDataSources(false)),
        // Async: toggling can trigger a refreshed search.
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>(),
        ],
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'clears nearby search when toggling external data',
        seed: () => HybridSearchLoaded(
          spots: TestDataFactory.createTestSpots(5),
          searchQuery: 'Nearby (1000m)',
          communityCount: 3,
          externalCount: 2,
          totalCount: 5,
          searchDuration: const Duration(milliseconds: 100),
          sources: const {'community': 3, 'external': 2},
        ),
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(ToggleExternalDataSources(false)),
        expect: () => [
          isA<HybridSearchInitial>(),
        ],
      );
    });

    group('WarmupCache Event', () {
      blocTest<HybridSearchBloc, HybridSearchState>(
        'warms up cache without location',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(WarmupCache()),
        expect: () => [],
        verify: (_) {
          verify(() => mockSearchCacheService.prefetchPopularSearches(
                searchFunction: any(named: 'searchFunction'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'warms up cache with location',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(WarmupCache(
          userLocation: Position(
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: DateTime.now(),
            accuracy: 10.0,
            altitude: 0.0,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          ),
        )),
        expect: () => [],
        verify: (_) {
          verify(() => mockSearchCacheService.prefetchPopularSearches(
                searchFunction: any(named: 'searchFunction'),
              )).called(1);

          verify(() => mockSearchCacheService.warmLocationCache(
                latitude: 37.7749,
                longitude: -122.4194,
                nearbySearchFunction: any(named: 'nearbySearchFunction'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'handles cache warmup failures gracefully',
        build: () {
          when(() => mockSearchCacheService.prefetchPopularSearches(
                searchFunction: any(named: 'searchFunction'),
              )).thenThrow(Exception('Cache warmup failed'));
          return hybridSearchBloc;
        },
        act: (bloc) => bloc.add(WarmupCache()),
        expect: () => [],
        // Should not emit error state for non-critical cache operations
      );
    });

    group('ClearSearchCache Event', () {
      blocTest<HybridSearchBloc, HybridSearchState>(
        'clears cache and learning data',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(ClearSearchCache()),
        expect: () => [],
        verify: (_) {
          verify(() => mockSearchCacheService.clearCache(
                preserveOffline: true,
              )).called(1);

          verify(() => mockAISearchSuggestionsService.clearLearningData())
              .called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'resets to initial state when clearing cache from loaded state',
        seed: () => HybridSearchLoaded(
          spots: TestDataFactory.createTestSpots(5),
          searchQuery: 'test',
          communityCount: 3,
          externalCount: 2,
          totalCount: 5,
          searchDuration: const Duration(milliseconds: 100),
          sources: const {'community': 3, 'external': 2},
        ),
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(ClearSearchCache()),
        expect: () => [
          isA<HybridSearchInitial>(),
        ],
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'emits error when cache clearing fails',
        build: () {
          when(() => mockSearchCacheService.clearCache(
                preserveOffline: any(named: 'preserveOffline'),
              )).thenThrow(Exception('Failed to clear cache'));
          return hybridSearchBloc;
        },
        act: (bloc) => bloc.add(ClearSearchCache()),
        expect: () => [
          isA<HybridSearchError>().having((state) => state.message, 'message',
              contains('Failed to clear cache')),
        ],
      );
    });

    group('Performance Metrics and Analytics', () {
      test('HybridSearchLoaded calculates community ratio correctly', () {
        final state = HybridSearchLoaded(
          spots: TestDataFactory.createTestSpots(10),
          communityCount: 7,
          externalCount: 3,
          totalCount: 10,
          searchDuration: const Duration(milliseconds: 150),
          sources: const {'community': 7, 'external': 3},
        );

        expect(state.communityRatio, equals(0.7));
        expect(state.isCommunityPrioritized, isTrue);
      });

      test('HybridSearchLoaded handles zero total count', () {
        final state = HybridSearchLoaded(
          spots: const [],
          communityCount: 0,
          externalCount: 0,
          totalCount: 0,
          searchDuration: const Duration(milliseconds: 50),
          sources: const {},
        );

        expect(state.communityRatio, equals(1.0));
        expect(state.isCommunityPrioritized, isTrue);
      });

      test('HybridSearchLoaded identifies non-community prioritized results',
          () {
        final state = HybridSearchLoaded(
          spots: TestDataFactory.createTestSpots(10),
          communityCount: 3,
          externalCount: 7,
          totalCount: 10,
          searchDuration: const Duration(milliseconds: 150),
          sources: const {'community': 3, 'external': 7},
        );

        expect(state.communityRatio, equals(0.3));
        expect(state.isCommunityPrioritized, isFalse);
      });

      blocTest<HybridSearchBloc, HybridSearchState>(
        'tracks search performance metrics',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(SearchHybridSpots(query: 'performance test')),
        // Async: search handler performs async work before emitting Loaded.
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>()
              .having((state) => state.searchDuration, 'search duration',
                  isA<Duration>())
              .having(
                  (state) => state.sources, 'sources breakdown', isNotEmpty),
        ],
      );
    });

    group('Complex Scenarios and Edge Cases', () {
      blocTest<HybridSearchBloc, HybridSearchState>(
        'handles rapid search queries gracefully',
        build: () => hybridSearchBloc,
        act: (bloc) {
          bloc.add(SearchHybridSpots(query: 'coffee'));
          bloc.add(SearchHybridSpots(query: 'restaurant'));
          bloc.add(SearchHybridSpots(query: 'bar'));
        },
        // Async: multiple queued events; allow processing before verify.
        wait: const Duration(milliseconds: 50),
        // Should handle rapid events without crashing
        verify: (_) {
          verify(() => mockHybridSearchUseCase.searchSpots(
                query: any(named: 'query'),
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
                filters: any(named: 'filters'),
                sortOption: any(named: 'sortOption'),
              )).called(greaterThan(0));
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'handles mixed event types in sequence',
        build: () => hybridSearchBloc,
        act: (bloc) async {
          bloc.add(SearchHybridSpots(query: 'coffee'));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(GetSearchSuggestions(query: 'cof'));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(
              SearchNearbyHybridSpots(latitude: 37.7749, longitude: -122.4194));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(ClearHybridSearch());
        },
        // Should handle mixed events gracefully
        verify: (_) {
          // Verify that various services were called
          verify(() => mockHybridSearchUseCase.searchSpots(
                query: any(named: 'query'),
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
                filters: any(named: 'filters'),
                sortOption: any(named: 'sortOption'),
              )).called(greaterThan(0));
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'maintains cache statistics throughout operations',
        build: () => hybridSearchBloc,
        act: (bloc) async {
          bloc.add(SearchHybridSpots(query: 'test'));
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(WarmupCache());
          await Future.delayed(const Duration(milliseconds: 50));

          bloc.add(SearchHybridSpots(query: 'test2'));
        },
        // Async: multiple events; allow last event to complete before verify.
        wait: const Duration(milliseconds: 50),
        verify: (_) {
          verify(() => mockSearchCacheService.getCacheStatistics())
              .called(greaterThan(0));
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'handles empty query gracefully',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(SearchHybridSpots(query: '')),
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>(),
        ],
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'handles very long query strings',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(SearchHybridSpots(
          query: 'a' * 1000, // Very long query
        )),
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>(),
        ],
      );
    });

    group('AI Integration and Learning', () {
      blocTest<HybridSearchBloc, HybridSearchState>(
        'integrates with AI suggestions service for learning',
        build: () => hybridSearchBloc,
        act: (bloc) =>
            bloc.add(SearchHybridSpots(query: 'machine learning test')),
        wait: const Duration(milliseconds: 10),
        verify: (_) {
          verify(() => mockAISearchSuggestionsService.learnFromSearch(
                query: 'machine learning test',
                results: any(named: 'results'),
              )).called(1);
        },
      );

      blocTest<HybridSearchBloc, HybridSearchState>(
        'uses community trends for better suggestions',
        build: () => hybridSearchBloc,
        act: (bloc) => bloc.add(GetSearchSuggestions(query: 'trending')),
        wait: const Duration(milliseconds: 10),
        verify: (_) {
          verify(() => mockSearchCacheService.getCacheStatistics()).called(1);
          verify(() => mockAISearchSuggestionsService.getSearchPatterns())
              .called(1);
        },
      );
    });

    group('Cache Performance Optimization', () {
      blocTest<HybridSearchBloc, HybridSearchState>(
        'prioritizes cache hits for better performance',
        build: () {
          when(() => mockSearchCacheService.getCachedResult(
                query: any(named: 'query'),
                latitude: any(named: 'latitude'),
                longitude: any(named: 'longitude'),
                maxResults: any(named: 'maxResults'),
                includeExternal: any(named: 'includeExternal'),
              )).thenAnswer((_) async => HybridSearchResult(
                spots: TestDataFactory.createTestSpots(10),
                communityCount: 6,
                externalCount: 4,
                totalCount: 10,
                searchDuration:
                    const Duration(milliseconds: 10), // Very fast from cache
                sources: {'community': 6, 'external': 4},
              ));
          return hybridSearchBloc;
        },
        act: (bloc) => bloc.add(SearchHybridSpots(query: 'cached query')),
        wait: const Duration(milliseconds: 10),
        expect: () => [
          isA<HybridSearchLoading>(),
          isA<HybridSearchLoaded>()
              .having((state) => state.fromCache, 'from cache', true)
              .having((state) => state.searchDuration.inMilliseconds,
                  'duration', lessThan(50)),
        ],
      );
    });
  });
}
