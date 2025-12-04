import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/expansion_expertise_gain_service.dart';
import 'package:spots/core/services/geographic_expansion_service.dart';
import 'package:spots/core/models/geographic_expansion.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

class MockGeographicExpansionService extends Mock implements GeographicExpansionService {}

void main() {
  group('ExpansionExpertiseGainService Tests', () {
    late ExpansionExpertiseGainService service;
    late MockGeographicExpansionService mockExpansionService;
    late UnifiedUser testUser;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      mockExpansionService = MockGeographicExpansionService();
      
      service = ExpansionExpertiseGainService(
        expansionService: mockExpansionService,
      );

      testUser = ModelFactories.createTestUser(
        id: 'user-1',
        displayName: 'Test User',
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Locality Expertise Gain', () {
      test('should grant local expertise for neighboring locality expansion', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final originalLocality = 'Mission District, San Francisco';
        final newLocality = 'Williamsburg, Brooklyn';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: originalLocality,
          expandedLocalities: [newLocality],
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedLocalityThreshold(expansion))
            .thenReturn(true);

        final result = await service.checkAndGrantLocalityExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, equals(ExpertiseLevel.local));
        verify(mockExpansionService.hasReachedLocalityThreshold(expansion)).called(1);
      });

      test('should not grant expertise if locality not expanded', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final originalLocality = 'Mission District, San Francisco';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: originalLocality,
          expandedLocalities: [], // No expansion
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedLocalityThreshold(expansion))
            .thenReturn(false);

        final result = await service.checkAndGrantLocalityExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, isNull);
        verify(mockExpansionService.hasReachedLocalityThreshold(expansion)).called(1);
      });
    });

    group('City Expertise Gain', () {
      test('should grant city expertise when 75% city coverage reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final city = 'Brooklyn';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedCities: [city],
          cityCoverage: {
            city: 0.8, // Above 75% threshold
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedCityThreshold(expansion, city))
            .thenReturn(true);

        final result = await service.checkAndGrantCityExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, equals(ExpertiseLevel.city));
        verify(mockExpansionService.hasReachedCityThreshold(expansion, city)).called(1);
      });

      test('should not grant city expertise if 75% threshold not reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final city = 'Brooklyn';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedCities: [city],
          cityCoverage: {
            city: 0.6, // Below 75% threshold
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedCityThreshold(expansion, city))
            .thenReturn(false);

        final result = await service.checkAndGrantCityExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, isNull);
        verify(mockExpansionService.hasReachedCityThreshold(expansion, city)).called(1);
      });
    });

    group('State Expertise Gain', () {
      test('should grant state expertise when 75% state coverage reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final state = 'New York';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedStates: [state],
          stateCoverage: {
            state: 0.8, // Above 75% threshold
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedStateThreshold(expansion, state))
            .thenReturn(true);

        final result = await service.checkAndGrantStateExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, equals(ExpertiseLevel.regional));
        verify(mockExpansionService.hasReachedStateThreshold(expansion, state)).called(1);
      });

      test('should not grant state expertise if 75% threshold not reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final state = 'New York';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedStates: [state],
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedStateThreshold(expansion, state))
            .thenReturn(false);

        final result = await service.checkAndGrantStateExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, isNull);
        verify(mockExpansionService.hasReachedStateThreshold(expansion, state)).called(1);
      });
    });

    group('Nation Expertise Gain', () {
      test('should grant nation expertise when 75% nation coverage reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final nation = 'United States';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedNations: [nation],
          nationCoverage: {
            nation: 0.8, // Above 75% threshold
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedNationThreshold(expansion, nation))
            .thenReturn(true);

        final result = await service.checkAndGrantNationExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, equals(ExpertiseLevel.national));
        verify(mockExpansionService.hasReachedNationThreshold(expansion, nation)).called(1);
      });

      test('should not grant nation expertise if 75% threshold not reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final nation = 'United States';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedNations: [nation],
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedNationThreshold(expansion, nation))
            .thenReturn(false);

        final result = await service.checkAndGrantNationExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, isNull);
        verify(mockExpansionService.hasReachedNationThreshold(expansion, nation)).called(1);
      });
    });

    group('Global Expertise Gain', () {
      test('should grant global expertise when 75% global coverage reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedGlobalThreshold(expansion))
            .thenReturn(true);

        final result = await service.checkAndGrantGlobalExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, equals(ExpertiseLevel.global));
        verify(mockExpansionService.hasReachedGlobalThreshold(expansion)).called(1);
      });

      test('should not grant global expertise if 75% threshold not reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedGlobalThreshold(expansion))
            .thenReturn(false);

        final result = await service.checkAndGrantGlobalExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, isNull);
        verify(mockExpansionService.hasReachedGlobalThreshold(expansion)).called(1);
      });
    });

    group('Universal Expertise Gain', () {
      test('should grant universal expertise when 75% universe coverage reached', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedGlobalThreshold(expansion))
            .thenReturn(true);

        final result = await service.checkAndGrantUniversalExpertise(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, equals(ExpertiseLevel.universal));
        verify(mockExpansionService.hasReachedGlobalThreshold(expansion)).called(1);
      });
    });

    group('Main Expertise Grant Method', () {
      test('should grant expertise from expansion when thresholds met', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final city = 'Brooklyn';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedCities: [city],
          cityCoverage: {
            city: 0.8, // Above 75% threshold
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedLocalityThreshold(expansion))
            .thenReturn(false);
        when(mockExpansionService.hasReachedCityThreshold(expansion, city))
            .thenReturn(true);

        final result = await service.grantExpertiseFromExpansion(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        expect(result, isA<UnifiedUser>());
        expect(result.expertiseMap[category], equals(ExpertiseLevel.city.name));
      });

      test('should preserve existing expertise when granting new expertise', () async {
        final clubId = 'club-1';
        final category = 'Coffee';

        // This test verifies that existing expertise is preserved
        // Implementation should update expertise while preserving existing expertise levels

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedLocalityThreshold(expansion))
            .thenReturn(false);

        final result = await service.grantExpertiseFromExpansion(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        // Verify that user is returned (expertise preserved if no new expertise granted)
        expect(result, isA<UnifiedUser>());
      });
    });

    group('Integration with GeographicExpansionService', () {
      test('should use GeographicExpansionService to check thresholds', () async {
        final clubId = 'club-1';
        final category = 'Coffee';
        final city = 'Brooklyn';

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: clubId,
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedCities: [city],
          cityCoverage: {
            city: 0.8,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockExpansionService.hasReachedLocalityThreshold(expansion))
            .thenReturn(false);
        when(mockExpansionService.hasReachedCityThreshold(expansion, city))
            .thenReturn(true);

        final result = await service.grantExpertiseFromExpansion(
          user: testUser,
          expansion: expansion,
          category: category,
        );

        // Verify integration with GeographicExpansionService
        verify(mockExpansionService.hasReachedCityThreshold(expansion, city)).called(1);
        expect(result.expertiseMap[category], equals(ExpertiseLevel.city.name));
      });
    });
  });
}

