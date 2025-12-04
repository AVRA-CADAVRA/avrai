import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/large_city.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for LargeCity model
void main() {
  group('LargeCity Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create large city with required fields', () {
        final city = LargeCity(
          id: 'city-123',
          name: 'Brooklyn',
          state: 'New York',
          country: 'USA',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(city.id, equals('city-123'));
        expect(city.name, equals('Brooklyn'));
        expect(city.state, equals('New York'));
        expect(city.country, equals('USA'));
        expect(city.neighborhoods, isEmpty);
        expect(city.isDetected, isFalse);
      });

      test('should create large city with neighborhoods', () {
        final city = LargeCity(
          id: 'city-456',
          name: 'Brooklyn',
          neighborhoods: ['greenpoint', 'dumbo', 'sunset-park'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(city.neighborhoods.length, equals(3));
        expect(city.hasNeighborhoods, isTrue);
        expect(city.neighborhoodCount, equals(3));
      });

      test('should create large city with population and size', () {
        final city = LargeCity(
          id: 'city-789',
          name: 'Los Angeles',
          population: 4000000,
          geographicSizeKm2: 1302.0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(city.population, equals(4000000));
        expect(city.geographicSizeKm2, equals(1302.0));
      });
    });

    group('Display Name', () {
      test('should return name only when no state', () {
        final city = LargeCity(
          id: 'city-1',
          name: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(city.displayName, equals('Brooklyn'));
      });

      test('should return name and state when state provided', () {
        final city = LargeCity(
          id: 'city-2',
          name: 'Brooklyn',
          state: 'New York',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(city.displayName, equals('Brooklyn, New York'));
      });
    });

    group('Neighborhoods', () {
      test('should return false when no neighborhoods', () {
        final city = LargeCity(
          id: 'city-1',
          name: 'Austin',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(city.hasNeighborhoods, isFalse);
        expect(city.neighborhoodCount, equals(0));
      });

      test('should return true when neighborhoods exist', () {
        final city = LargeCity(
          id: 'city-2',
          name: 'Brooklyn',
          neighborhoods: ['greenpoint', 'dumbo'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(city.hasNeighborhoods, isTrue);
        expect(city.neighborhoodCount, equals(2));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON', () {
        final city = LargeCity(
          id: 'city-123',
          name: 'Brooklyn',
          state: 'New York',
          country: 'USA',
          latitude: 40.6782,
          longitude: -73.9442,
          population: 2736074,
          geographicSizeKm2: 251.0,
          neighborhoods: ['greenpoint', 'dumbo'],
          isDetected: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = city.toJson();

        expect(json['id'], equals('city-123'));
        expect(json['name'], equals('Brooklyn'));
        expect(json['state'], equals('New York'));
        expect(json['country'], equals('USA'));
        expect(json['latitude'], equals(40.6782));
        expect(json['longitude'], equals(-73.9442));
        expect(json['population'], equals(2736074));
        expect(json['geographicSizeKm2'], equals(251.0));
        expect(json['neighborhoods'], equals(['greenpoint', 'dumbo']));
        expect(json['isDetected'], isTrue);
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
      });

      test('should deserialize from JSON', () {
        final json = {
          'id': 'city-123',
          'name': 'Brooklyn',
          'state': 'New York',
          'country': 'USA',
          'latitude': 40.6782,
          'longitude': -73.9442,
          'population': 2736074,
          'geographicSizeKm2': 251.0,
          'neighborhoods': ['greenpoint', 'dumbo'],
          'isDetected': true,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final city = LargeCity.fromJson(json);

        expect(city.id, equals('city-123'));
        expect(city.name, equals('Brooklyn'));
        expect(city.state, equals('New York'));
        expect(city.country, equals('USA'));
        expect(city.latitude, equals(40.6782));
        expect(city.longitude, equals(-73.9442));
        expect(city.population, equals(2736074));
        expect(city.geographicSizeKm2, equals(251.0));
        expect(city.neighborhoods, equals(['greenpoint', 'dumbo']));
        expect(city.isDetected, isTrue);
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final original = LargeCity(
          id: 'city-123',
          name: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          name: 'Los Angeles',
          state: 'California',
          neighborhoods: ['hollywood', 'santa-monica'],
        );

        expect(updated.id, equals('city-123'));
        expect(updated.name, equals('Los Angeles'));
        expect(updated.state, equals('California'));
        expect(updated.neighborhoods, equals(['hollywood', 'santa-monica']));
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final city1 = LargeCity(
          id: 'city-123',
          name: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final city2 = LargeCity(
          id: 'city-123',
          name: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(city1, equals(city2));
      });

      test('should not be equal when properties differ', () {
        final city1 = LargeCity(
          id: 'city-123',
          name: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final city2 = LargeCity(
          id: 'city-456',
          name: 'Los Angeles',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(city1, isNot(equals(city2)));
      });
    });
  });
}

