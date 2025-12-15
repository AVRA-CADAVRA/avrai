import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spots/core/services/google_place_id_finder_service_new.dart';
import 'package:spots/core/models/spot.dart';
import '../../fixtures/model_factories.dart';

import 'google_place_id_finder_service_new_test.mocks.dart';
import '../../helpers/platform_channel_helper.dart';

@GenerateMocks([http.Client])
void main() {
  group('GooglePlaceIdFinderServiceNew Tests', () {
    late GooglePlaceIdFinderServiceNew service;
    late MockClient mockHttpClient;
    late Spot spot;

    setUp(() {
      mockHttpClient = MockClient();
      service = GooglePlaceIdFinderServiceNew(
        apiKey: 'test-api-key',
        httpClient: mockHttpClient,
      );
      spot = ModelFactories.createTestSpot(
        name: 'Test Restaurant',
        latitude: 40.7128,
        longitude: -74.0060,
      );
    });

    // Removed: Property assignment tests
    // Google Place ID finder tests focus on business logic (place ID finding, error handling), not property assignment

    group('findPlaceId', () {
      test(
          'should return null when no place ID found, when distance exceeds threshold, or when name similarity is too low',
          () async {
        // Test business logic: place ID finding with validation failures
        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer(
          (_) async => http.Response(
            '{"places": []}',
            200,
          ),
        );
        final placeId1 = await service.findPlaceId(spot);
        expect(placeId1, isNull);

        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'places': [
                {
                  'id': 'places/ChIJN1t_tDeuEmsRUsoyG83frY4',
                  'displayName': {
                    'text': 'Test Restaurant',
                  },
                  'location': {
                    'latitude': 40.8,
                    'longitude': -74.1,
                  },
                },
              ],
            }),
            200,
          ),
        );
        final placeId2 = await service.findPlaceId(spot);
        expect(placeId2, isNull);

        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'places': [
                {
                  'id': 'places/ChIJN1t_tDeuEmsRUsoyG83frY4',
                  'displayName': {
                    'text': 'Completely Different Name',
                  },
                  'location': {
                    'latitude': 40.7128,
                    'longitude': -74.0060,
                  },
                },
              ],
            }),
            200,
          ),
        );
        final placeId3 = await service.findPlaceId(spot);
        expect(placeId3, isNull);
      });

      test(
          'should return place ID when found via nearby search or remove places/ prefix from place ID',
          () async {
        // Test business logic: successful place ID retrieval
        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'places': [
                {
                  'id': 'places/ChIJN1t_tDeuEmsRUsoyG83frY4',
                  'displayName': {
                    'text': 'Test Restaurant',
                  },
                  'location': {
                    'latitude': 40.7128,
                    'longitude': -74.0060,
                  },
                },
              ],
            }),
            200,
          ),
        );
        final placeId1 = await service.findPlaceId(spot);
        expect(placeId1, equals('ChIJN1t_tDeuEmsRUsoyG83frY4'));
        expect(placeId1, isNotNull);
        expect(placeId1, isNot(contains('places/')));
      });

      test('should try text search when nearby search fails', () async {
        // Stub by endpoint URL (body is JSON and does not contain "searchNearby"/"searchText")
        final nearbyUrl =
            Uri.parse('https://places.googleapis.com/v1/places:searchNearby');
        final textUrl =
            Uri.parse('https://places.googleapis.com/v1/places:searchText');

        // First call (nearby search) returns empty
        when(mockHttpClient.post(
          argThat(equals(nearbyUrl)),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding'),
        )).thenAnswer(
          (_) async => http.Response(
            '{"places": []}',
            200,
          ),
        );

        // Second call (text search) returns a match
        when(mockHttpClient.post(
          argThat(equals(textUrl)),
          headers: anyNamed('headers'),
          body: anyNamed('body'),
          encoding: anyNamed('encoding'),
        )).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'places': [
                {
                  'id': 'places/ChIJN1t_tDeuEmsRUsoyG83frY4',
                  'displayName': {
                    'text': 'Test Restaurant',
                  },
                  'location': {
                    'latitude': 40.7128,
                    'longitude': -74.0060,
                  },
                },
              ],
            }),
            200,
          ),
        );

        final placeId = await service.findPlaceId(spot);

        expect(placeId, equals('ChIJN1t_tDeuEmsRUsoyG83frY4'));
      });

      test(
          'should handle HTTP errors gracefully or handle network exceptions gracefully',
          () async {
        // Test business logic: error handling
        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer(
          (_) async => http.Response('Error', 500),
        );
        final placeId1 = await service.findPlaceId(spot);
        expect(placeId1, isNull);

        when(mockHttpClient.post(any,
                headers: anyNamed('headers'), body: anyNamed('body')))
            .thenThrow(Exception('Network error'));
        final placeId2 = await service.findPlaceId(spot);
        expect(placeId2, isNull);
      });
    });

    tearDownAll(() async {
      await cleanupTestStorage();
    });
  });
}
