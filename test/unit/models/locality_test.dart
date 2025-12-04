import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/locality.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for Locality model
void main() {
  group('Locality Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create locality with required fields', () {
        final locality = Locality(
          id: 'locality-123',
          name: 'Greenpoint',
          city: 'Brooklyn',
          state: 'New York',
          country: 'USA',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(locality.id, equals('locality-123'));
        expect(locality.name, equals('Greenpoint'));
        expect(locality.city, equals('Brooklyn'));
        expect(locality.state, equals('New York'));
        expect(locality.country, equals('USA'));
        expect(locality.isNeighborhood, isFalse);
        expect(locality.parentCity, isNull);
      });

      test('should create neighborhood locality', () {
        final locality = Locality(
          id: 'locality-456',
          name: 'Greenpoint',
          isNeighborhood: true,
          parentCity: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(locality.isNeighborhood, isTrue);
        expect(locality.parentCity, equals('Brooklyn'));
        expect(locality.isInLargeCity, isTrue);
      });

      test('should create locality with coordinates', () {
        final locality = Locality(
          id: 'locality-789',
          name: 'Austin',
          latitude: 30.2672,
          longitude: -97.7431,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(locality.latitude, equals(30.2672));
        expect(locality.longitude, equals(-97.7431));
      });
    });

    group('Display Name', () {
      test('should return name only when no city/state', () {
        final locality = Locality(
          id: 'locality-1',
          name: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(locality.displayName, equals('Greenpoint'));
      });

      test('should return name and city when city provided', () {
        final locality = Locality(
          id: 'locality-2',
          name: 'Greenpoint',
          city: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(locality.displayName, equals('Greenpoint, Brooklyn'));
      });

      test('should return name and state when city and state provided', () {
        final locality = Locality(
          id: 'locality-3',
          name: 'Austin',
          city: 'Austin',
          state: 'Texas',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(locality.displayName, equals('Austin, Texas'));
      });

      test('should return name and parent city for neighborhoods', () {
        final locality = Locality(
          id: 'locality-4',
          name: 'Greenpoint',
          isNeighborhood: true,
          parentCity: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(locality.displayName, equals('Greenpoint, Brooklyn'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON', () {
        final locality = Locality(
          id: 'locality-123',
          name: 'Greenpoint',
          city: 'Brooklyn',
          state: 'New York',
          country: 'USA',
          latitude: 40.7295,
          longitude: -73.9545,
          isNeighborhood: true,
          parentCity: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = locality.toJson();

        expect(json['id'], equals('locality-123'));
        expect(json['name'], equals('Greenpoint'));
        expect(json['city'], equals('Brooklyn'));
        expect(json['state'], equals('New York'));
        expect(json['country'], equals('USA'));
        expect(json['latitude'], equals(40.7295));
        expect(json['longitude'], equals(-73.9545));
        expect(json['isNeighborhood'], isTrue);
        expect(json['parentCity'], equals('Brooklyn'));
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
      });

      test('should deserialize from JSON', () {
        final json = {
          'id': 'locality-123',
          'name': 'Greenpoint',
          'city': 'Brooklyn',
          'state': 'New York',
          'country': 'USA',
          'latitude': 40.7295,
          'longitude': -73.9545,
          'isNeighborhood': true,
          'parentCity': 'Brooklyn',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final locality = Locality.fromJson(json);

        expect(locality.id, equals('locality-123'));
        expect(locality.name, equals('Greenpoint'));
        expect(locality.city, equals('Brooklyn'));
        expect(locality.state, equals('New York'));
        expect(locality.country, equals('USA'));
        expect(locality.latitude, equals(40.7295));
        expect(locality.longitude, equals(-73.9545));
        expect(locality.isNeighborhood, isTrue);
        expect(locality.parentCity, equals('Brooklyn'));
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final original = Locality(
          id: 'locality-123',
          name: 'Greenpoint',
          city: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          name: 'DUMBO',
          parentCity: 'Brooklyn',
          isNeighborhood: true,
        );

        expect(updated.id, equals('locality-123'));
        expect(updated.name, equals('DUMBO'));
        expect(updated.city, equals('Brooklyn'));
        expect(updated.isNeighborhood, isTrue);
        expect(updated.parentCity, equals('Brooklyn'));
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final locality1 = Locality(
          id: 'locality-123',
          name: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final locality2 = Locality(
          id: 'locality-123',
          name: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(locality1, equals(locality2));
      });

      test('should not be equal when properties differ', () {
        final locality1 = Locality(
          id: 'locality-123',
          name: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final locality2 = Locality(
          id: 'locality-456',
          name: 'DUMBO',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(locality1, isNot(equals(locality2)));
      });
    });
  });
}

