import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/geographic_scope.dart';
import 'package:spots/core/models/expertise_level.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for GeographicScope model
void main() {
  group('GeographicScope Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create geographic scope for local expert', () {
        final scope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          city: 'Brooklyn',
          state: 'New York',
          country: 'USA',
          allowedLocalities: ['Greenpoint'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(scope.userId, equals('user-123'));
        expect(scope.level, equals(ExpertiseLevel.local));
        expect(scope.locality, equals('Greenpoint'));
        expect(scope.city, equals('Brooklyn'));
        expect(scope.allowedLocalities, equals(['Greenpoint']));
      });

      test('should create geographic scope for city expert', () {
        final scope = GeographicScope(
          userId: 'user-456',
          level: ExpertiseLevel.city,
          city: 'Brooklyn',
          allowedLocalities: ['Greenpoint', 'DUMBO', 'Sunset Park'],
          allowedCities: ['Brooklyn'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(scope.level, equals(ExpertiseLevel.city));
        expect(scope.city, equals('Brooklyn'));
        expect(scope.allowedLocalities.length, equals(3));
      });
    });

    group('canHostInLocality', () {
      test('should return true for local expert in their locality', () {
        final scope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          allowedLocalities: ['Greenpoint'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(scope.canHostInLocality('Greenpoint'), isTrue);
        expect(scope.canHostInLocality('DUMBO'), isFalse);
      });

      test('should return true for city expert in any locality in their city', () {
        final scope = GeographicScope(
          userId: 'user-456',
          level: ExpertiseLevel.city,
          city: 'Brooklyn',
          allowedLocalities: ['Greenpoint', 'DUMBO', 'Sunset Park'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(scope.canHostInLocality('Greenpoint'), isTrue);
        expect(scope.canHostInLocality('DUMBO'), isTrue);
        expect(scope.canHostInLocality('Manhattan'), isFalse);
      });

      test('should return true for regional+ experts in any locality', () {
        final regionalScope = GeographicScope(
          userId: 'user-789',
          level: ExpertiseLevel.regional,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(regionalScope.canHostInLocality('Greenpoint'), isTrue);
        expect(regionalScope.canHostInLocality('Manhattan'), isTrue);
        expect(regionalScope.canHostInLocality('Austin'), isTrue);

        final nationalScope = GeographicScope(
          userId: 'user-101',
          level: ExpertiseLevel.national,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(nationalScope.canHostInLocality('Any Locality'), isTrue);
      });
    });

    group('canHostInCity', () {
      test('should return false for local expert (cannot host outside locality)', () {
        final scope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          city: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(scope.canHostInCity('Brooklyn'), isFalse);
        expect(scope.canHostInCity('Manhattan'), isFalse);
      });

      test('should return true for city expert in their city', () {
        final scope = GeographicScope(
          userId: 'user-456',
          level: ExpertiseLevel.city,
          city: 'Brooklyn',
          allowedCities: ['Brooklyn'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(scope.canHostInCity('Brooklyn'), isTrue);
        expect(scope.canHostInCity('Manhattan'), isFalse);
      });

      test('should return true for regional+ experts in any city', () {
        final regionalScope = GeographicScope(
          userId: 'user-789',
          level: ExpertiseLevel.regional,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(regionalScope.canHostInCity('Brooklyn'), isTrue);
        expect(regionalScope.canHostInCity('Austin'), isTrue);
        expect(regionalScope.canHostInCity('Los Angeles'), isTrue);
      });
    });

    group('getHostableLocalities', () {
      test('should return list of allowed localities', () {
        final scope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.city,
          allowedLocalities: ['Greenpoint', 'DUMBO', 'Sunset Park'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final localities = scope.getHostableLocalities();
        expect(localities.length, equals(3));
        expect(localities, contains('Greenpoint'));
        expect(localities, contains('DUMBO'));
        expect(localities, contains('Sunset Park'));
      });
    });

    group('getHostableCities', () {
      test('should return list of allowed cities', () {
        final scope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.regional,
          allowedCities: ['Brooklyn', 'Manhattan', 'Queens'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final cities = scope.getHostableCities();
        expect(cities.length, equals(3));
        expect(cities, contains('Brooklyn'));
        expect(cities, contains('Manhattan'));
        expect(cities, contains('Queens'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON', () {
        final scope = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          city: 'Brooklyn',
          state: 'New York',
          country: 'USA',
          allowedLocalities: ['Greenpoint'],
          allowedCities: [],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = scope.toJson();

        expect(json['userId'], equals('user-123'));
        expect(json['level'], equals('local'));
        expect(json['locality'], equals('Greenpoint'));
        expect(json['city'], equals('Brooklyn'));
        expect(json['state'], equals('New York'));
        expect(json['country'], equals('USA'));
        expect(json['allowedLocalities'], equals(['Greenpoint']));
        expect(json['allowedCities'], isEmpty);
        expect(json['createdAt'], equals(testDate.toIso8601String()));
        expect(json['updatedAt'], equals(testDate.toIso8601String()));
      });

      test('should deserialize from JSON', () {
        final json = {
          'userId': 'user-123',
          'level': 'local',
          'locality': 'Greenpoint',
          'city': 'Brooklyn',
          'state': 'New York',
          'country': 'USA',
          'allowedLocalities': ['Greenpoint'],
          'allowedCities': [],
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final scope = GeographicScope.fromJson(json);

        expect(scope.userId, equals('user-123'));
        expect(scope.level, equals(ExpertiseLevel.local));
        expect(scope.locality, equals('Greenpoint'));
        expect(scope.city, equals('Brooklyn'));
        expect(scope.state, equals('New York'));
        expect(scope.country, equals('USA'));
        expect(scope.allowedLocalities, equals(['Greenpoint']));
        expect(scope.allowedCities, isEmpty);
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final original = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          level: ExpertiseLevel.city,
          city: 'Brooklyn',
          allowedLocalities: ['Greenpoint', 'DUMBO'],
        );

        expect(updated.userId, equals('user-123'));
        expect(updated.level, equals(ExpertiseLevel.city));
        expect(updated.locality, equals('Greenpoint'));
        expect(updated.city, equals('Brooklyn'));
        expect(updated.allowedLocalities, equals(['Greenpoint', 'DUMBO']));
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final scope1 = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final scope2 = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(scope1, equals(scope2));
      });

      test('should not be equal when properties differ', () {
        final scope1 = GeographicScope(
          userId: 'user-123',
          level: ExpertiseLevel.local,
          locality: 'Greenpoint',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final scope2 = GeographicScope(
          userId: 'user-456',
          level: ExpertiseLevel.city,
          city: 'Brooklyn',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(scope1, isNot(equals(scope2)));
      });
    });
  });
}

