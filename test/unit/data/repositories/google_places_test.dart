import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:spots/data/datasources/remote/google_places_datasource_new_impl.dart';
import 'package:spots/core/services/google_places_cache_service.dart';

import 'google_places_test.mocks.dart';

@GenerateMocks([http.Client, GooglePlacesCacheService])
void main() {
  group('Google Places API (New) Tests', () {
    late GooglePlacesDataSourceNewImpl googlePlaces;
    late MockClient mockClient;
    late MockGooglePlacesCacheService mockCacheService;
    
    setUp(() {
      mockClient = MockClient();
      mockCacheService = MockGooglePlacesCacheService();
      googlePlaces = GooglePlacesDataSourceNewImpl(
        apiKey: 'test_api_key',
        httpClient: mockClient,
        cacheService: mockCacheService,
      );
    });

    group('OUR_GUTS.md Compliance', () {
      test('marks external data with clear source indicators', () async {
        // Mock successful response (New API format)
        final mockResponse = '''
        {
          "places": [
            {
              "id": "places/test_place_123",
              "displayName": {
                "text": "Test Restaurant"
              },
              "formattedAddress": "123 Test St, Test City",
              "location": {
                "latitude": 40.7589,
                "longitude": -73.9851
              },
              "rating": 4.5,
              "types": ["restaurant", "food"]
            }
          ]
        }
        ''';
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(mockResponse, 200));
        when(mockCacheService.cachePlaces(any)).thenAnswer((_) async => {});

        final spots = await googlePlaces.searchPlaces(query: 'restaurant');
        
        expect(spots.length, 1);
        final spot = spots.first;
        
        // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
        expect(spot.tags, contains('external_data'));
        expect(spot.tags, contains('google_places'));
        expect(spot.metadata['source'], 'google_places');
        expect(spot.metadata['is_external'], true);
        expect(spot.createdBy, 'google_places_api');
      });

      test('maintains authenticity over algorithms principle', () async {
        final mockResponse = '''
        {
          "places": [
            {
              "id": "places/test_place_456",
              "displayName": {
                "text": "Authentic Local Spot"
              },
              "formattedAddress": "456 Local Ave",
              "location": {
                "latitude": 40.7505,
                "longitude": -73.9934
              },
              "rating": 4.2,
              "types": ["tourist_attraction"]
            }
          ]
        }
        ''';
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(mockResponse, 200));
        when(mockCacheService.cachePlaces(any)).thenAnswer((_) async => {});

        final spots = await googlePlaces.searchPlaces(query: 'local attraction');
        
        expect(spots.length, 1);
        final spot = spots.first;
        
        // Verify external data doesn't masquerade as community content
        expect(spot.id, startsWith('google_'));
        expect(spot.createdBy, 'google_places_api');
        expect(spot.metadata['source'], 'google_places');
      });
    });

    group('Performance and Reliability', () {
      test('implements caching for performance', () async {
        final mockResponse = '''
        {
          "places": [
            {
              "id": "places/cached_place",
              "displayName": {
                "text": "Cached Restaurant"
              },
              "formattedAddress": "789 Cache St",
              "location": {
                "latitude": 40.7600,
                "longitude": -73.9800
              },
              "rating": 4.0,
              "types": ["restaurant"]
            }
          ]
        }
        ''';
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(mockResponse, 200));
        when(mockCacheService.cachePlaces(any)).thenAnswer((_) async => {});

        // First call should hit the API
        final spots1 = await googlePlaces.searchPlaces(query: 'test restaurant');
        expect(spots1.length, 1);
        
        // Second identical call should use cache (no additional HTTP call)
        final spots2 = await googlePlaces.searchPlaces(query: 'test restaurant');
        expect(spots2.length, 1);
        expect(spots2.first.name, spots1.first.name);
        
        // Verify only one HTTP call was made
        verify(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
      });

      test('handles API errors gracefully', () async {
        // Mock API error
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response('{"error": {"message": "API Error"}}', 500));

        // OUR_GUTS.md: "Effortless, Seamless Discovery"
        final spots = await googlePlaces.searchPlaces(query: 'error test');
        
        // Should return empty list, not throw exception
        expect(spots, isEmpty);
      });

      test('handles network errors gracefully', () async {
        // Mock network error
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenThrow(Exception('Network error'));

        final spots = await googlePlaces.searchPlaces(query: 'network test');
        
        // Should return empty list, not throw exception
        expect(spots, isEmpty);
      });
    });

    group('Google Places API (New) Functionality', () {
      test('searches places with location bias', () async {
        final mockResponse = '''
        {
          "places": [
            {
              "id": "places/location_biased_place",
              "displayName": {
                "text": "Nearby Cafe"
              },
              "formattedAddress": "Near User Location",
              "location": {
                "latitude": 40.7589,
                "longitude": -73.9851
              },
              "rating": 4.3,
              "types": ["cafe"]
            }
          ]
        }
        ''';
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(mockResponse, 200));
        when(mockCacheService.cachePlaces(any)).thenAnswer((_) async => {});

        final spots = await googlePlaces.searchPlaces(
          query: 'cafe',
          latitude: 40.7589,
          longitude: -73.9851,
          radius: 1000,
        );
        
        expect(spots.length, 1);
        expect(spots.first.name, 'Nearby Cafe');
        expect(spots.first.category, 'Other'); // cafe maps to Other category
      });

      test('searches nearby places', () async {
        final mockResponse = '''
        {
          "places": [
            {
              "id": "places/nearby_place_1",
              "displayName": {
                "text": "Nearby Restaurant"
              },
              "formattedAddress": "Close by",
              "location": {
                "latitude": 40.7590,
                "longitude": -73.9850
              },
              "rating": 4.1,
              "types": ["restaurant"]
            }
          ]
        }
        ''';
        
        when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
            .thenAnswer((_) async => http.Response(mockResponse, 200));
        when(mockCacheService.cachePlaces(any)).thenAnswer((_) async => {});

        final spots = await googlePlaces.searchNearbyPlaces(
          latitude: 40.7589,
          longitude: -73.9851,
          radius: 500,
          type: 'restaurant',
        );
        
        expect(spots.length, 1);
        expect(spots.first.name, 'Nearby Restaurant');
        expect(spots.first.category, 'Food');
      });

      test('gets place details', () async {
        final mockResponse = '''
        {
          "id": "places/detailed_place",
          "displayName": {
            "text": "Detailed Restaurant"
          },
          "formattedAddress": "123 Detail St, Detail City",
          "location": {
            "latitude": 40.7595,
            "longitude": -73.9845
          },
          "rating": 4.7,
          "types": ["restaurant"],
          "nationalPhoneNumber": "(555) 123-4567",
          "websiteUri": "https://example.com",
          "regularOpeningHours": {
            "openNow": true
          }
        }
        ''';
        
        when(mockClient.get(any, headers: anyNamed('headers')))
            .thenAnswer((_) async => http.Response(mockResponse, 200));

        final spot = await googlePlaces.getPlaceDetails('detailed_place');
        
        expect(spot, isNotNull);
        expect(spot!.name, 'Detailed Restaurant');
        expect(spot.metadata['phone'], '(555) 123-4567');
        expect(spot.metadata['website'], 'https://example.com');
        expect(spot.metadata['opening_hours'], isNotNull);
      });
    });

    group('Category Mapping', () {
      test('maps Google types to SPOTS categories correctly', () async {
        final testCases = [
          {'types': ['restaurant'], 'expected': 'Food'},
          {'types': ['tourist_attraction'], 'expected': 'Attractions'},
          {'types': ['shopping_mall'], 'expected': 'Shopping'},
          {'types': ['night_club'], 'expected': 'Nightlife'},
          {'types': ['lodging'], 'expected': 'Stay'},
          {'types': ['unknown_type'], 'expected': 'Other'},
        ];
        
        for (final testCase in testCases) {
          final types = testCase['types'] as List<String>;
          final expected = testCase['expected'] as String;
          
          final mockResponse = '''
          {
            "places": [
              {
                "id": "places/category_test",
                "displayName": {
                  "text": "Test Place"
                },
                "formattedAddress": "Test Address",
                "location": {
                  "latitude": 40.7589,
                  "longitude": -73.9851
                },
                "rating": 4.0,
                "types": ${types.map((t) => '"$t"').toList()}
              }
            ]
          }
          ''';
          
          when(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body')))
              .thenAnswer((_) async => http.Response(mockResponse, 200));
          when(mockCacheService.cachePlaces(any)).thenAnswer((_) async => {});

          final spots = await googlePlaces.searchPlaces(query: 'test');
          expect(spots.first.category, expected);
        }
      });
    });
  });
}
