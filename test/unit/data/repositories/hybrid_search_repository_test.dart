import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/data/repositories/hybrid_search_repository.dart';
import 'package:spots/data/datasources/local/spots_local_datasource.dart';
import 'package:spots/data/datasources/remote/spots_remote_datasource.dart';
import 'package:spots/data/datasources/remote/google_places_datasource.dart';
import 'package:spots/data/datasources/remote/openstreetmap_datasource.dart';
import 'package:spots/core/services/google_places_cache_service.dart';
import 'package:spots/core/models/spot.dart';

import 'hybrid_search_repository_test.mocks.dart';

@GenerateMocks([
  SpotsLocalDataSource,
  SpotsRemoteDataSource,
  GooglePlacesDataSource,
  OpenStreetMapDataSource,
  GooglePlacesCacheService,
  Connectivity,
])
void main() {
  group('HybridSearchRepository', () {
    late HybridSearchRepository repository;
    late MockSpotsLocalDataSource mockLocalDataSource;
    late MockSpotsRemoteDataSource mockRemoteDataSource;
    late MockGooglePlacesDataSource mockGooglePlacesDataSource;
    late MockOpenStreetMapDataSource mockOsmDataSource;
    late MockGooglePlacesCacheService mockGooglePlacesCache;
    late MockConnectivity mockConnectivity;

    setUp(() {
      mockLocalDataSource = MockSpotsLocalDataSource();
      mockRemoteDataSource = MockSpotsRemoteDataSource();
      mockGooglePlacesDataSource = MockGooglePlacesDataSource();
      mockOsmDataSource = MockOpenStreetMapDataSource();
      mockGooglePlacesCache = MockGooglePlacesCacheService();
      mockConnectivity = MockConnectivity();
      
      repository = HybridSearchRepository(
        localDataSource: mockLocalDataSource,
        remoteDataSource: mockRemoteDataSource,
        googlePlacesDataSource: mockGooglePlacesDataSource,
        osmDataSource: mockOsmDataSource,
        googlePlacesCache: mockGooglePlacesCache,
        connectivity: mockConnectivity,
      );
    });

    group('searchSpots', () {
      test('should prioritize community data over external sources', () async {
        const query = 'coffee shop';
        final communitySpots = [
          Spot(
            id: 'spot-1',
            name: 'Local Coffee',
            description: 'Community favorite',
            latitude: 37.7749,
            longitude: -122.4194,
            category: 'cafe',
            rating: 0.0,
            createdBy: 'test-user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockLocalDataSource.searchSpots(any))
            .thenAnswer((_) async => communitySpots);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final result = await repository.searchSpots(query: query);

        expect(result, isNotNull);
        expect(result.communityCount, greaterThan(0));
        // OUR_GUTS.md: "Community, Not Just Places" - Community data prioritized
        verify(mockLocalDataSource.searchSpots(any)).called(1);
      });

      test('should use cached external data when offline', () async {
        const query = 'restaurant';
        final cachedSpots = [
          Spot(
            id: 'cached-1',
            name: 'Cached Restaurant',
            description: 'From cache',
            latitude: 37.7749,
            longitude: -122.4194,
            category: 'restaurant',
            rating: 0.0,
            createdBy: 'test-user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockLocalDataSource.searchSpots(any))
            .thenAnswer((_) async => []);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockGooglePlacesCache.searchCachedPlaces(query))
            .thenAnswer((_) async => cachedSpots);

        final result = await repository.searchSpots(
          query: query,
          includeExternal: true,
        );

        expect(result, isNotNull);
        verify(mockGooglePlacesCache.searchCachedPlaces(query)).called(1);
      });

      test('should return empty result on error', () async {
        const query = 'invalid query';

        when(mockLocalDataSource.searchSpots(any))
            .thenThrow(Exception('Search error'));

        final result = await repository.searchSpots(query: query);

        // OUR_GUTS.md: "Effortless, Seamless Discovery" - Graceful fallback
        expect(result, isNotNull);
        expect(result.totalCount, equals(0));
      });
    });

    group('searchNearbySpots', () {
      test('should search nearby spots with community priority', () async {
        const latitude = 37.7749;
        const longitude = -122.4194;
        const radius = 1000;

        final nearbySpots = [
          Spot(
            id: 'nearby-1',
            name: 'Nearby Spot',
            description: 'Close by',
            latitude: latitude,
            longitude: longitude,
            category: 'restaurant',
            rating: 0.0,
            createdBy: 'test-user',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockLocalDataSource.searchSpots(any))
            .thenAnswer((_) async => nearbySpots);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.wifi]);

        final result = await repository.searchNearbySpots(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
        );

        expect(result, isNotNull);
        expect(result.communityCount, greaterThan(0));
      });
    });

    group('Offline Behavior', () {
      test('should work offline with cached data', () async {
        const query = 'test query';

        when(mockLocalDataSource.searchSpots(any))
            .thenAnswer((_) async => []);
        when(mockConnectivity.checkConnectivity())
            .thenAnswer((_) async => [ConnectivityResult.none]);
        when(mockGooglePlacesCache.searchCachedPlaces(query))
            .thenAnswer((_) async => []);

        final result = await repository.searchSpots(
          query: query,
          includeExternal: true,
        );

        expect(result, isNotNull);
        // Should gracefully handle offline scenario
        verify(mockGooglePlacesCache.searchCachedPlaces(query)).called(1);
      });
    });
  });
}

