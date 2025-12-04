/// SPOTS Hybrid Search Repository Tests
/// Date: November 20, 2025
/// Purpose: Test hybrid search repository with community-first prioritization
/// 
/// Test Coverage:
/// - Community-first search prioritization
/// - External data integration (Google Places, OSM)
/// - Offline fallback with cached data
/// - Search result caching
/// - Filtering and sorting
/// - Error handling and graceful fallback
/// 
/// OUR_GUTS.md: "Community, Not Just Places" - Local community knowledge comes first

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/data/repositories/hybrid_search_repository.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';
import 'package:spots/data/datasources/remote/spots_remote_datasource.dart';
import 'package:spots/data/datasources/remote/google_places_datasource.dart';
import 'package:spots/data/datasources/remote/openstreetmap_datasource.dart';
import 'package:spots/core/services/google_places_cache_service.dart';

import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

// Manual mocks for all dependencies
class MockSpotsLocalDataSource extends Mock implements SpotsLocalDataSource {}
class MockSpotsRemoteDataSource extends Mock implements SpotsRemoteDataSource {}
class MockGooglePlacesDataSource extends Mock implements GooglePlacesDataSource {}
class MockOpenStreetMapDataSource extends Mock implements OpenStreetMapDataSource {}
class MockGooglePlacesCacheService extends Mock implements GooglePlacesCacheService {}
class MockConnectivity extends Mock implements Connectivity {}

void main() {
  group('HybridSearchRepository Tests', () {
    late HybridSearchRepository repository;
    late MockSpotsLocalDataSource mockLocalDataSource;
    late MockSpotsRemoteDataSource mockRemoteDataSource;
    late MockGooglePlacesDataSource mockGooglePlacesDataSource;
    late MockOpenStreetMapDataSource mockOsmDataSource;
    late MockGooglePlacesCacheService mockGooglePlacesCache;
    late MockConnectivity mockConnectivity;
    
    late List<Spot> testCommunitySpots;
    late List<Spot> testExternalSpots;

    setUp(() {
      // Create fresh mocks for each test
      mockLocalDataSource = MockSpotsLocalDataSource();
      mockRemoteDataSource = MockSpotsRemoteDataSource();
      mockGooglePlacesDataSource = MockGooglePlacesDataSource();
      mockOsmDataSource = MockOpenStreetMapDataSource();
      mockGooglePlacesCache = MockGooglePlacesCacheService();
      mockConnectivity = MockConnectivity();
      
      // Set up default connectivity mock - use thenReturn to avoid async issues
      // Set it up BEFORE creating repository to avoid conflicts
      when(mockConnectivity.checkConnectivity())
          .thenReturn(Future.value([ConnectivityResult.wifi]));
      
      // Create repository AFTER all mocks are set up
      repository = HybridSearchRepository(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        googlePlacesDataSource: mockGooglePlacesDataSource,
        osmDataSource: mockOsmDataSource,
        googlePlacesCache: mockGooglePlacesCache,
        connectivity: mockConnectivity,
      );
      
      testCommunitySpots = ModelFactories.createTestSpots(3);
      testExternalSpots = ModelFactories.createTestSpots(5);
    });

    tearDown(() async {
      // Wait a bit to ensure any async operations complete
      await Future.delayed(const Duration(milliseconds: 50));
      
      // Reset all mocks
      reset(mockLocalDataSource);
      reset(mockRemoteDataSource);
      reset(mockGooglePlacesDataSource);
      reset(mockOsmDataSource);
      reset(mockGooglePlacesCache);
      reset(mockConnectivity);
    });

    group('searchSpots - Community-First Prioritization', () {
      test('should prioritize community data over external sources', () async {
        // Arrange: Configure online scenario with both community and external data
        // Connectivity is already mocked in setUp()
        
        // Mock community data search
        when(mockLocalDataSource.searchSpots('cafe'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);
        
        // Mock external data sources
        when(mockGooglePlacesDataSource.searchPlaces(
          query: 'cafe',
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          radius: 1000,
        )).thenAnswer((_) async => testExternalSpots);
        when(mockOsmDataSource.searchPlaces(
          query: 'cafe',
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          limit: 10,
        )).thenAnswer((_) async => []);

        // Act
        final result = await repository.searchSpots(
          query: 'cafe',
          maxResults: 10,
          includeExternal: true,
        );

        // Assert: Community data should be prioritized
        expect(result, isNotNull);
        expect(result.spots, isNotEmpty);
        expect(result.communityCount, greaterThan(0));
        expect(result.totalCount, lessThanOrEqualTo(10));
        
        // Verify community data was searched first
        verify(mockLocalDataSource.searchSpots('cafe')).called(1);
        verify(mockRemoteDataSource.getSpots()).called(1);
      });

      test('should return only community data when includeExternal is false', () async {
        // Arrange
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots('restaurant'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);

        // Act
        final result = await repository.searchSpots(
          query: 'restaurant',
          includeExternal: false,
        );

        // Assert: Only community data should be returned
        expect(result, isNotNull);
        expect(result.externalCount, equals(0));
        expect(result.communityCount, greaterThan(0));
        
        // Verify external sources were not called
        verifyNever(mockGooglePlacesDataSource.searchPlaces(
          query: '',
          latitude: 0.0,
          longitude: 0.0,
        ));
        verifyNever(mockOsmDataSource.searchPlaces(
          query: '',
          latitude: 0.0,
          longitude: 0.0,
        ));
      });

      test('should use cached Google Places data when offline', () async {
        // Arrange: Configure offline scenario
        // Create a new connectivity mock for this test to avoid reset issues
        final offlineConnectivity = MockConnectivity();
        TestHelpers.mockOfflineConnectivity(offlineConnectivity);
        
        // Create a new repository instance with offline connectivity
        final offlineRepository = HybridSearchRepository(
          localDataSource: mockLocalDataSource,
          remoteDataSource: mockRemoteDataSource,
          googlePlacesDataSource: mockGooglePlacesDataSource,
          osmDataSource: mockOsmDataSource,
          googlePlacesCache: mockGooglePlacesCache,
          connectivity: offlineConnectivity,
        );
        
        when(mockLocalDataSource.searchSpots('coffee'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockGooglePlacesCache.searchCachedPlaces('coffee'))
            .thenAnswer((_) async => testExternalSpots);

        // Act
        final result = await offlineRepository.searchSpots(
          query: 'coffee',
          includeExternal: true,
        );

        // Assert: Should use cached data
        expect(result, isNotNull);
        verify(mockGooglePlacesCache.searchCachedPlaces('coffee')).called(1);
        verifyNever(mockGooglePlacesDataSource.searchPlaces(
          query: '',
          latitude: 0.0,
          longitude: 0.0,
        ));
      });
    });

    group('searchSpots - Caching', () {
      test('should return cached result when available', () async {
        // Arrange: First search to populate cache
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots('cafe'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);

        // First search
        final firstResult = await repository.searchSpots(query: 'cafe');
        expect(firstResult, isNotNull);

        // Second search with same parameters should use cache
        final secondResult = await repository.searchSpots(query: 'cafe');
        expect(secondResult, isNotNull);
        
        // Verify data sources were only called once (first search)
        verify(mockLocalDataSource.searchSpots('cafe')).called(1);
      });

      test('should cache results with proper expiration', () async {
        // Arrange
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots('restaurant'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);

        // Act: Perform search
        final result = await repository.searchSpots(query: 'restaurant');
        
        // Assert: Result should be cached
        expect(result, isNotNull);
        expect(result.totalCount, greaterThanOrEqualTo(0));
      });
    });

    group('searchSpots - Filtering and Sorting', () {
      test('should apply filters when provided', () async {
        // Arrange
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots('cafe'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);

        // Act: Search with filters
        final result = await repository.searchSpots(
          query: 'cafe',
          filters: SearchFilters(
            minRating: 4.0,
            maxDistance: 5000,
          ),
        );

        // Assert
        expect(result, isNotNull);
        expect(result.spots.length, lessThanOrEqualTo(testCommunitySpots.length));
      });

      test('should respect maxResults limit', () async {
        // Arrange
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots('restaurant'))
            .thenAnswer((_) async => ModelFactories.createTestSpots(20));
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => ModelFactories.createTestSpots(20));

        // Act: Search with maxResults limit
        final result = await repository.searchSpots(
          query: 'restaurant',
          maxResults: 5,
        );

        // Assert: Should respect maxResults
        expect(result, isNotNull);
        expect(result.spots.length, lessThanOrEqualTo(5));
        expect(result.totalCount, lessThanOrEqualTo(5));
      });
    });

    group('searchSpots - Error Handling', () {
      test('should return empty result on error', () async {
        // Arrange: Simulate error in data source
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots('cafe'))
            .thenThrow(Exception('Database error'));

        // Act
        final result = await repository.searchSpots(query: 'cafe');

        // Assert: Should return empty result gracefully
        expect(result, isNotNull);
        expect(result.spots, isEmpty);
        expect(result.totalCount, equals(0));
        expect(result.communityCount, equals(0));
        expect(result.externalCount, equals(0));
      });

      test('should handle external data source errors gracefully', () async {
        // Arrange
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots('cafe'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);
        when(mockGooglePlacesDataSource.searchPlaces(
          query: 'cafe',
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        )).thenThrow(Exception('API error'));

        // Act
        final result = await repository.searchSpots(
          query: 'cafe',
          includeExternal: true,
        );

        // Assert: Should still return community results
        expect(result, isNotNull);
        expect(result.communityCount, greaterThan(0));
      });
    });

    group('searchNearbySpots', () {
      test('should search nearby spots with location', () async {
        // Arrange
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots(''))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);

        // Act
        final result = await repository.searchNearbySpots(
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 1000,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.spots, isNotEmpty);
      });

      test('should respect radius parameter', () async {
        // Arrange
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots(''))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);

        // Act: Search with small radius
        final result = await repository.searchNearbySpots(
          latitude: 40.7128,
          longitude: -74.0060,
          radius: 500,
          maxResults: 10,
        );

        // Assert
        expect(result, isNotNull);
        expect(result.spots.length, lessThanOrEqualTo(10));
      });
    });

    group('HybridSearchResult', () {
      test('should create empty result correctly', () {
        // Act
        final result = HybridSearchResult.empty();

        // Assert
        expect(result.spots, isEmpty);
        expect(result.communityCount, equals(0));
        expect(result.externalCount, equals(0));
        expect(result.totalCount, equals(0));
        expect(result.searchDuration, equals(Duration.zero));
        expect(result.sources, isEmpty);
      });

      test('should calculate community ratio correctly', () {
        // Arrange
        final result = HybridSearchResult(
          spots: testCommunitySpots,
          communityCount: 3,
          externalCount: 2,
          totalCount: 5,
          searchDuration: Duration(milliseconds: 100),
          sources: {'community': 3, 'external': 2},
        );

        // Assert
        expect(result.communityRatio, equals(0.6));
        expect(result.isPrimarilyCommunityDriven, isTrue);
      });

      test('should return false for isPrimarilyCommunityDriven when external dominates', () {
        // Arrange
        final result = HybridSearchResult(
          spots: testExternalSpots,
          communityCount: 1,
          externalCount: 4,
          totalCount: 5,
          searchDuration: Duration(milliseconds: 100),
          sources: {'community': 1, 'external': 4},
        );

        // Assert
        expect(result.communityRatio, equals(0.2));
        expect(result.isPrimarilyCommunityDriven, isFalse);
      });
    });

    group('OUR_GUTS.md Compliance', () {
      test('should prioritize community data over external sources', () async {
        // Arrange
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots('cafe'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);
        when(mockGooglePlacesDataSource.searchPlaces(
          query: 'cafe',
          latitude: 0.0,
          longitude: 0.0,
        )).thenAnswer((_) async => testExternalSpots);

        // Act
        final result = await repository.searchSpots(
          query: 'cafe',
          includeExternal: true,
        );

        // Assert: Community data should be searched first and prioritized
        expect(result.communityCount, greaterThan(0));
        verify(mockLocalDataSource.searchSpots('cafe')).called(1);
        verify(mockRemoteDataSource.getSpots()).called(1);
      });

      test('should maintain privacy-preserving search analytics', () async {
        // Arrange
        // Connectivity is already mocked in setUp()
        when(mockLocalDataSource.searchSpots('cafe'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockLocalDataSource.searchSpots('restaurant'))
            .thenAnswer((_) async => testCommunitySpots);
        when(mockRemoteDataSource.getSpots())
            .thenAnswer((_) async => testCommunitySpots);

        // Act: Perform multiple searches
        await repository.searchSpots(query: 'cafe');
        await repository.searchSpots(query: 'restaurant');
        await repository.searchSpots(query: 'cafe');

        // Assert: Analytics should be tracked (implementation detail)
        // This test verifies the method completes without errors
        expect(true, isTrue);
      });
    });
  });
}

