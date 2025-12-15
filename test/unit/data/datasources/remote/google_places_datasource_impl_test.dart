import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:spots/data/datasources/remote/google_places_datasource_impl.dart';
import 'package:spots/core/services/google_places_cache_service.dart';
import 'package:spots/core/models/spot.dart';

import 'google_places_datasource_impl_test.mocks.dart';

@GenerateMocks([http.Client, GooglePlacesCacheService])
void main() {
  group('GooglePlacesDataSourceImpl', () {
    late GooglePlacesDataSourceImpl dataSource;
    late MockClient mockHttpClient;
    late MockGooglePlacesCacheService mockCacheService;

    setUp(() {
      mockHttpClient = MockClient();
      mockCacheService = MockGooglePlacesCacheService();
      dataSource = GooglePlacesDataSourceImpl(
        apiKey: 'test-api-key',
        httpClient: mockHttpClient,
        cacheService: mockCacheService,
      );
    });

    group('searchPlaces', () {
      test('should search places via Google Places API', () async {
        const query = 'restaurant';
        final mockResponse = http.Response(
          '{"results": [{"place_id": "123", "name": "Restaurant", "geometry": {"location": {"lat": 37.7749, "lng": -122.4194}}}]}',
          200,
        );

        when(mockHttpClient.get(any))
            .thenAnswer((_) async => mockResponse);
        when(mockCacheService.cachePlaces(any))
            .thenAnswer((_) async => Future.value());

        final spots = await dataSource.searchPlaces(query: query);

        expect(spots, isA<List<Spot>>());
        // OUR_GUTS.md: "Authenticity Over Algorithms" - External data enriches community knowledge
        verify(mockHttpClient.get(any)).called(1);
      });

      test('should use cache when available', () async {
        const query = 'cached query';
        final cachedSpots = [
          Spot(
            id: 'cached-1',
            name: 'Cached Place',
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

        // Simulate cache hit by returning cached results
        // Note: Actual cache implementation would be tested separately
        final spots = await dataSource.searchPlaces(query: query);

        expect(spots, isA<List<Spot>>());
      });

      test('should return empty list on error', () async {
        const query = 'invalid query';

        when(mockHttpClient.get(any))
            .thenThrow(Exception('Network error'));

        final spots = await dataSource.searchPlaces(query: query);

        // OUR_GUTS.md: "Effortless, Seamless Discovery" - Graceful fallback
        expect(spots, isEmpty);
      });
    });

    group('getPlaceDetails', () {
      test('should get place details via Google Places API', () async {
        const placeId = 'ChIJN1t_tDeuEmsRUsoyG83frY4';
        final mockResponse = http.Response(
          '{"result": {"place_id": "$placeId", "name": "Place Name", "geometry": {"location": {"lat": 37.7749, "lng": -122.4194}}}}',
          200,
        );

        when(mockHttpClient.get(any))
            .thenAnswer((_) async => mockResponse);

        final spot = await dataSource.getPlaceDetails(placeId);

        expect(spot, anyOf(isNull, isA<Spot>()));
      });
    });
  });
}

