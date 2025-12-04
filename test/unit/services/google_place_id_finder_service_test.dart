import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:spots/core/services/google_place_id_finder_service.dart';
import 'package:spots/core/models/spot.dart';
import '../../fixtures/model_factories.dart';

import 'google_place_id_finder_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('GooglePlaceIdFinderService Tests (Legacy)', () {
    // ignore: deprecated_member_use_from_same_package
    late GooglePlaceIdFinderService service;
    late MockClient mockHttpClient;
    late Spot spot;

    setUp(() {
      mockHttpClient = MockClient();
      // ignore: deprecated_member_use_from_same_package
      service = GooglePlaceIdFinderService(
        apiKey: 'test-api-key',
        httpClient: mockHttpClient,
      );
      spot = ModelFactories.createTestSpot(
        name: 'Test Restaurant',
        latitude: 40.7128,
        longitude: -74.0060,
      );
    });

    group('findPlaceId', () {
      test('should return null when no place ID found', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            '{"results": []}',
            200,
          ),
        );

        final placeId = await service.findPlaceId(spot);

        expect(placeId, isNull);
      });

      test('should return place ID when found via nearby search', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'name': 'Test Restaurant',
                  'place_id': 'ChIJN1t_tDeuEmsRUsoyG83frY4',
                  'geometry': {
                    'location': {
                      'lat': 40.7128,
                      'lng': -74.0060,
                    },
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

      test('should return null when distance exceeds threshold', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'name': 'Test Restaurant',
                  'place_id': 'ChIJN1t_tDeuEmsRUsoyG83frY4',
                  'geometry': {
                    'location': {
                      'lat': 40.8, // Far away
                      'lng': -74.1,
                    },
                  },
                },
              ],
            }),
            200,
          ),
        );

        final placeId = await service.findPlaceId(spot);

        expect(placeId, isNull);
      });

      test('should return null when name similarity is too low', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response(
            jsonEncode({
              'results': [
                {
                  'name': 'Completely Different Name',
                  'place_id': 'ChIJN1t_tDeuEmsRUsoyG83frY4',
                  'geometry': {
                    'location': {
                      'lat': 40.7128,
                      'lng': -74.0060,
                    },
                  },
                },
              ],
            }),
            200,
          ),
        );

        final placeId = await service.findPlaceId(spot);

        expect(placeId, isNull);
      });

      test('should handle HTTP errors gracefully', () async {
        when(mockHttpClient.get(any)).thenAnswer(
          (_) async => http.Response('Error', 500),
        );

        final placeId = await service.findPlaceId(spot);

        expect(placeId, isNull);
      });

      test('should handle network exceptions gracefully', () async {
        when(mockHttpClient.get(any)).thenThrow(Exception('Network error'));

        final placeId = await service.findPlaceId(spot);

        expect(placeId, isNull);
      });
    });
  });
}

