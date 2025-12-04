import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/geographic_scope.dart';
import 'package:spots/core/models/locality.dart';
import 'package:spots/core/models/large_city.dart';
import '../helpers/integration_test_helpers.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/integration_test_fixtures.dart';

/// Integration tests for geographic scope validation
/// 
/// **Tests:**
/// - Local experts can only host events in their locality
/// - City experts can host events in all localities in their city
/// - Geographic hierarchy enforcement (Local → City → Regional → National → Global → Universal)
/// - Large city detection and neighborhood handling
/// - Event creation with geographic scope validation
/// 
/// **Note:** These tests will be completed once GeographicScopeService and
/// LargeCityDetectionService are created by Agent 1.
void main() {
  group('Geographic Scope Integration Tests', () {
    setUp(() {
      TestHelpers.setupTestEnvironment();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Local Expert Scope Validation', () {
      test('should allow local expert to host in their locality', () {
        final scope = IntegrationTestHelpers.createLocalExpertScope(
          userId: 'user-123',
          locality: 'Greenpoint',
          city: 'Brooklyn',
          state: 'New York',
          country: 'USA',
        );

        expect(scope.canHostInLocality('Greenpoint'), isTrue);
      });

      test('should prevent local expert from hosting in other locality', () {
        final scope = IntegrationTestHelpers.createLocalExpertScope(
          userId: 'user-123',
          locality: 'Greenpoint',
          city: 'Brooklyn',
          state: 'New York',
          country: 'USA',
        );

        expect(scope.canHostInLocality('DUMBO'), isFalse);
        expect(scope.canHostInLocality('Manhattan'), isFalse);
      });

      test('should prevent local expert from hosting in other city', () {
        final scope = IntegrationTestHelpers.createLocalExpertScope(
          userId: 'user-123',
          locality: 'Greenpoint',
          city: 'Brooklyn',
          state: 'New York',
          country: 'USA',
        );

        expect(scope.canHostInCity('Brooklyn'), isFalse);
        expect(scope.canHostInCity('Manhattan'), isFalse);
      });
    });

    group('City Expert Scope Validation', () {
      test('should allow city expert to host in any locality in their city', () {
        final scope = IntegrationTestHelpers.createCityExpertScope(
          userId: 'user-456',
          city: 'Brooklyn',
          localities: ['Greenpoint', 'DUMBO', 'Sunset Park', 'Bath Beach'],
          state: 'New York',
          country: 'USA',
        );

        expect(scope.canHostInLocality('Greenpoint'), isTrue);
        expect(scope.canHostInLocality('DUMBO'), isTrue);
        expect(scope.canHostInLocality('Sunset Park'), isTrue);
        expect(scope.canHostInLocality('Bath Beach'), isTrue);
      });

      test('should prevent city expert from hosting in other city', () {
        final scope = IntegrationTestHelpers.createCityExpertScope(
          userId: 'user-456',
          city: 'Brooklyn',
          localities: ['Greenpoint', 'DUMBO'],
          state: 'New York',
          country: 'USA',
        );

        expect(scope.canHostInCity('Brooklyn'), isTrue);
        expect(scope.canHostInCity('Manhattan'), isFalse);
        expect(scope.canHostInCity('Queens'), isFalse);
      });
    });

    group('Regional+ Expert Scope Validation', () {
      test('should allow regional expert to host in any locality', () {
        final scope = IntegrationTestHelpers.createRegionalExpertScope(
          userId: 'user-789',
          level: ExpertiseLevel.regional,
          state: 'New York',
          country: 'USA',
        );

        expect(scope.canHostInLocality('Greenpoint'), isTrue);
        expect(scope.canHostInLocality('Manhattan'), isTrue);
        expect(scope.canHostInLocality('Austin'), isTrue);
      });

      test('should allow regional expert to host in any city', () {
        final scope = IntegrationTestHelpers.createRegionalExpertScope(
          userId: 'user-789',
          level: ExpertiseLevel.regional,
          state: 'New York',
          country: 'USA',
        );

        expect(scope.canHostInCity('Brooklyn'), isTrue);
        expect(scope.canHostInCity('Manhattan'), isTrue);
        expect(scope.canHostInCity('Austin'), isTrue);
      });

      test('should allow national expert to host anywhere', () {
        final scope = IntegrationTestHelpers.createRegionalExpertScope(
          userId: 'user-101',
          level: ExpertiseLevel.national,
          country: 'USA',
        );

        expect(scope.canHostInLocality('Any Locality'), isTrue);
        expect(scope.canHostInCity('Any City'), isTrue);
      });

      test('should allow global expert to host anywhere', () {
        final scope = IntegrationTestHelpers.createRegionalExpertScope(
          userId: 'user-202',
          level: ExpertiseLevel.global,
        );

        expect(scope.canHostInLocality('Any Locality'), isTrue);
        expect(scope.canHostInCity('Any City'), isTrue);
      });

      test('should allow universal expert to host anywhere', () {
        final scope = IntegrationTestHelpers.createRegionalExpertScope(
          userId: 'user-303',
          level: ExpertiseLevel.universal,
        );

        expect(scope.canHostInLocality('Any Locality'), isTrue);
        expect(scope.canHostInCity('Any City'), isTrue);
      });
    });

    group('Geographic Hierarchy Enforcement', () {
      test('should enforce Local < City < Regional < National < Global < Universal', () {
        final localScope = IntegrationTestHelpers.createLocalExpertScope(
          userId: 'user-local',
          locality: 'Greenpoint',
          city: 'Brooklyn',
        );

        final cityScope = IntegrationTestHelpers.createCityExpertScope(
          userId: 'user-city',
          city: 'Brooklyn',
          localities: ['Greenpoint', 'DUMBO'],
        );

        final regionalScope = IntegrationTestHelpers.createRegionalExpertScope(
          userId: 'user-regional',
          level: ExpertiseLevel.regional,
        );

        // Local expert can only host in their locality
        expect(localScope.canHostInLocality('Greenpoint'), isTrue);
        expect(localScope.canHostInLocality('DUMBO'), isFalse);

        // City expert can host in all localities in their city
        expect(cityScope.canHostInLocality('Greenpoint'), isTrue);
        expect(cityScope.canHostInLocality('DUMBO'), isTrue);

        // Regional expert can host anywhere
        expect(regionalScope.canHostInLocality('Greenpoint'), isTrue);
        expect(regionalScope.canHostInLocality('Any Locality'), isTrue);
      });
    });

    group('Large City Detection', () {
      test('should identify large cities with neighborhoods', () {
        final city = IntegrationTestHelpers.createTestLargeCity(
          name: 'Brooklyn',
          state: 'New York',
          population: 2736074,
          geographicSizeKm2: 251.0,
          neighborhoods: [
            'locality-greenpoint',
            'locality-dumbo',
            'locality-sunset-park',
          ],
          isDetected: true,
        );

        expect(city.hasNeighborhoods, isTrue);
        expect(city.neighborhoodCount, equals(3));
        expect(city.isDetected, isTrue);
      });

      test('should handle neighborhood localities in large cities', () {
        final locality = IntegrationTestHelpers.createTestLocality(
          name: 'Greenpoint',
          city: 'Brooklyn',
          isNeighborhood: true,
          parentCity: 'Brooklyn',
        );

        expect(locality.isNeighborhood, isTrue);
        expect(locality.isInLargeCity, isTrue);
        expect(locality.parentCity, equals('Brooklyn'));
      });
    });

    group('Event Creation with Geographic Scope Validation', () {
      test('should allow local expert to create event in their locality', () {
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-123',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn',
        );

        final scope = IntegrationTestHelpers.createLocalExpertScope(
          userId: user.id,
          locality: 'Greenpoint',
          city: 'Brooklyn',
        );

        // Event location should match user's locality
        expect(scope.canHostInLocality('Greenpoint'), isTrue);
      });

      test('should prevent local expert from creating event in other locality', () {
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'user-123',
          category: 'Coffee',
          location: 'Greenpoint, Brooklyn',
        );

        final scope = IntegrationTestHelpers.createLocalExpertScope(
          userId: user.id,
          locality: 'Greenpoint',
          city: 'Brooklyn',
        );

        // Event location should NOT match other localities
        expect(scope.canHostInLocality('DUMBO'), isFalse);
        expect(scope.canHostInLocality('Manhattan'), isFalse);
      });

      test('should allow city expert to create event in any locality in their city', () {
        final user = IntegrationTestHelpers.createUserWithCityExpertise(
          id: 'user-456',
          category: 'Coffee',
          location: 'Brooklyn',
        );

        final scope = IntegrationTestHelpers.createCityExpertScope(
          userId: user.id,
          city: 'Brooklyn',
          localities: ['Greenpoint', 'DUMBO', 'Sunset Park'],
        );

        // City expert can host in any locality in their city
        expect(scope.canHostInLocality('Greenpoint'), isTrue);
        expect(scope.canHostInLocality('DUMBO'), isTrue);
        expect(scope.canHostInLocality('Sunset Park'), isTrue);
      });
    });

    group('Test Fixtures Integration', () {
      test('should use local expert scope fixture', () {
        final fixture = IntegrationTestFixtures.localExpertScopeFixture();
        final scope = fixture['scope'] as GeographicScope;

        expect(scope.level, equals(ExpertiseLevel.local));
        expect(fixture['canHostInLocality'], isTrue);
        expect(fixture['cannotHostInOtherLocality'], isTrue);
      });

      test('should use city expert scope fixture', () {
        final fixture = IntegrationTestFixtures.cityExpertScopeFixture();
        final scope = fixture['scope'] as GeographicScope;

        expect(scope.level, equals(ExpertiseLevel.city));
        expect(fixture['canHostInLocality'], isTrue);
        expect(fixture['canHostInCity'], isTrue);
      });

      test('should use locality fixture', () {
        final fixture = IntegrationTestFixtures.localityFixture();
        final locality = fixture['locality'] as Locality;

        expect(locality.name, equals('Greenpoint'));
        expect(fixture['isNeighborhood'], isTrue);
        expect(fixture['parentCity'], equals('Brooklyn'));
      });

      test('should use large city fixture', () {
        final fixture = IntegrationTestFixtures.largeCityFixture();
        final city = fixture['city'] as LargeCity;

        expect(city.name, equals('Brooklyn'));
        expect(fixture['hasNeighborhoods'], isTrue);
        expect(fixture['neighborhoodCount'], equals(4));
      });
    });

    // TODO: Add tests for GeographicScopeService integration once service is created
    // TODO: Add tests for LargeCityDetectionService integration once service is created
    // TODO: Add tests for ExpertiseEventService.createEvent() with geographic scope validation
  });
}

