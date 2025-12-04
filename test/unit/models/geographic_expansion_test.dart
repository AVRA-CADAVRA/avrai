import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/geographic_expansion.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for GeographicExpansion Model
/// Tests expansion tracking, coverage calculation, expansion history
/// 
/// **Philosophy Alignment:**
/// - Clubs/communities can expand naturally (doors open through growth)
/// - 75% coverage rule (fair expertise gain thresholds)
/// - Geographic expansion enabled (locality → universe)
void main() {
  group('GeographicExpansion Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Model Creation', () {
      test('should create GeographicExpansion with required fields', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.id, equals('expansion-1'));
        expect(expansion.clubId, equals('club-1'));
        expect(expansion.isClub, equals(true));
        expect(expansion.originalLocality, equals('Mission District, San Francisco'));
        expect(expansion.expandedLocalities, isEmpty);
        expect(expansion.expandedCities, isEmpty);
        expect(expansion.expandedStates, isEmpty);
        expect(expansion.expandedNations, isEmpty);
        expect(expansion.localityCoverage, isEmpty);
        expect(expansion.cityCoverage, isEmpty);
        expect(expansion.stateCoverage, isEmpty);
        expect(expansion.nationCoverage, isEmpty);
        expect(expansion.commutePatterns, isEmpty);
        expect(expansion.eventHostingLocations, isEmpty);
        expect(expansion.expansionHistory, isEmpty);
        expect(expansion.firstExpansionAt, isNull);
        expect(expansion.lastExpansionAt, isNull);
      });

      test('should create GeographicExpansion with optional fields', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedLocalities: ['Williamsburg, Brooklyn', 'Greenpoint, Brooklyn'],
          expandedCities: ['Brooklyn', 'Queens'],
          expandedStates: ['New York'],
          expandedNations: ['United States'],
          localityCoverage: {
            'Mission District, San Francisco': 1.0,
            'Williamsburg, Brooklyn': 0.5,
          },
          cityCoverage: {
            'San Francisco': 0.3,
            'Brooklyn': 0.8,
          },
          stateCoverage: {
            'California': 0.2,
            'New York': 0.75,
          },
          nationCoverage: {
            'United States': 0.1,
          },
          commutePatterns: {
            'Mission District, San Francisco': ['SOMA, San Francisco', 'Castro, San Francisco'],
          },
          eventHostingLocations: {
            'Mission District, San Francisco': ['event-1', 'event-2'],
            'Williamsburg, Brooklyn': ['event-3'],
          },
          expansionHistory: [
            ExpansionEvent(
              timestamp: testDate,
              location: 'Williamsburg, Brooklyn',
              geographicLevel: 'locality',
              expansionMethod: 'event_hosting',
              eventId: 'event-1',
              coveragePercentage: 0.5,
            ),
          ],
          firstExpansionAt: testDate,
          lastExpansionAt: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.expandedLocalities, hasLength(2));
        expect(expansion.expandedCities, hasLength(2));
        expect(expansion.expandedStates, hasLength(1));
        expect(expansion.expandedNations, hasLength(1));
        expect(expansion.localityCoverage, hasLength(2));
        expect(expansion.cityCoverage, hasLength(2));
        expect(expansion.stateCoverage, hasLength(2));
        expect(expansion.nationCoverage, hasLength(1));
        expect(expansion.commutePatterns, hasLength(1));
        expect(expansion.eventHostingLocations, hasLength(2));
        expect(expansion.expansionHistory, hasLength(1));
        expect(expansion.firstExpansionAt, equals(testDate));
        expect(expansion.lastExpansionAt, equals(testDate));
      });
    });

    group('Expansion Tracking', () {
      test('should track expanded localities', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedLocalities: ['Williamsburg, Brooklyn'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.expandedLocalities, contains('Williamsburg, Brooklyn'));
        expect(expansion.hasReachedLocalityThreshold(), isTrue);
      });

      test('should track expanded cities', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedCities: ['Brooklyn', 'Queens'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.expandedCities, containsAll(['Brooklyn', 'Queens']));
      });

      test('should track expanded states', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedStates: ['New York', 'New Jersey'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.expandedStates, containsAll(['New York', 'New Jersey']));
      });

      test('should track expanded nations', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedNations: ['United States', 'Canada'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.expandedNations, containsAll(['United States', 'Canada']));
      });

      test('should indicate no expansion when no localities expanded', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.hasReachedLocalityThreshold(), isFalse);
      });
    });

    group('Coverage Calculation', () {
      test('should track locality coverage', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          localityCoverage: {
            'Mission District, San Francisco': 1.0,
            'Williamsburg, Brooklyn': 0.75,
            'Greenpoint, Brooklyn': 0.5,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.localityCoverage['Mission District, San Francisco'], equals(1.0));
        expect(expansion.localityCoverage['Williamsburg, Brooklyn'], equals(0.75));
        expect(expansion.localityCoverage['Greenpoint, Brooklyn'], equals(0.5));
      });

      test('should track city coverage', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          cityCoverage: {
            'San Francisco': 0.3,
            'Brooklyn': 0.8,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.cityCoverage['San Francisco'], equals(0.3));
        expect(expansion.cityCoverage['Brooklyn'], equals(0.8));
      });

      test('should track state coverage', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          stateCoverage: {
            'California': 0.2,
            'New York': 0.75,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.stateCoverage['California'], equals(0.2));
        expect(expansion.stateCoverage['New York'], equals(0.75));
      });

      test('should track nation coverage', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          nationCoverage: {
            'United States': 0.1,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.nationCoverage['United States'], equals(0.1));
      });

      test('should check if 75% city threshold reached', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          cityCoverage: {
            'Brooklyn': 0.8, // Above 75%
            'Queens': 0.6, // Below 75%
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.hasReachedCityThreshold('Brooklyn'), isTrue);
        expect(expansion.hasReachedCityThreshold('Queens'), isFalse);
      });

      test('should check if 75% state threshold reached', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          stateCoverage: {
            'New York': 0.8, // Above 75%
            'California': 0.6, // Below 75%
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.hasReachedStateThreshold('New York'), isTrue);
        expect(expansion.hasReachedStateThreshold('California'), isFalse);
      });

      test('should check if 75% nation threshold reached', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          nationCoverage: {
            'United States': 0.8, // Above 75%
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.hasReachedNationThreshold('United States'), isTrue);
      });
    });

    group('Coverage Methods', () {
      test('should track commute patterns', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          commutePatterns: {
            'Mission District, San Francisco': ['SOMA, San Francisco', 'Castro, San Francisco'],
            'Williamsburg, Brooklyn': ['Greenpoint, Brooklyn', 'DUMBO, Brooklyn'],
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.commutePatterns['Mission District, San Francisco'], hasLength(2));
        expect(expansion.commutePatterns['Williamsburg, Brooklyn'], hasLength(2));
        expect(expansion.commutePatterns['Mission District, San Francisco'], contains('SOMA, San Francisco'));
      });

      test('should track event hosting locations', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          eventHostingLocations: {
            'Mission District, San Francisco': ['event-1', 'event-2'],
            'Williamsburg, Brooklyn': ['event-3'],
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.eventHostingLocations['Mission District, San Francisco'], hasLength(2));
        expect(expansion.eventHostingLocations['Williamsburg, Brooklyn'], hasLength(1));
        expect(expansion.eventHostingLocations['Mission District, San Francisco'], contains('event-1'));
      });
    });

    group('Expansion History', () {
      test('should track expansion history', () {
        final firstExpansion = testDate.subtract(const Duration(days: 30));
        final lastExpansion = testDate;

        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expansionHistory: [
            ExpansionEvent(
              timestamp: firstExpansion,
              location: 'Williamsburg, Brooklyn',
              geographicLevel: 'locality',
              expansionMethod: 'event_hosting',
              eventId: 'event-1',
              coveragePercentage: 0.5,
            ),
            ExpansionEvent(
              timestamp: lastExpansion,
              location: 'Greenpoint, Brooklyn',
              geographicLevel: 'locality',
              expansionMethod: 'commute_pattern',
              coveragePercentage: 0.3,
            ),
          ],
          firstExpansionAt: firstExpansion,
          lastExpansionAt: lastExpansion,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.expansionHistory, hasLength(2));
        expect(expansion.firstExpansionAt, equals(firstExpansion));
        expect(expansion.lastExpansionAt, equals(lastExpansion));
        expect(expansion.expansionHistory[0].location, equals('Williamsburg, Brooklyn'));
        expect(expansion.expansionHistory[1].location, equals('Greenpoint, Brooklyn'));
      });

      test('should have null expansion timestamps when no expansion occurred', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion.firstExpansionAt, isNull);
        expect(expansion.lastExpansionAt, isNull);
      });
    });

    group('JSON Serialization/Deserialization', () {
      test('should serialize to JSON correctly', () {
        final expansion = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedLocalities: ['Williamsburg, Brooklyn'],
          cityCoverage: {
            'Brooklyn': 0.8,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = expansion.toJson();

        expect(json['id'], equals('expansion-1'));
        expect(json['clubId'], equals('club-1'));
        expect(json['isClub'], equals(true));
        expect(json['originalLocality'], equals('Mission District, San Francisco'));
        expect(json['expandedLocalities'], isA<List>());
        expect(json['cityCoverage'], isA<Map>());
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'expansion-1',
          'clubId': 'club-1',
          'isClub': true,
          'originalLocality': 'Mission District, San Francisco',
          'expandedLocalities': ['Williamsburg, Brooklyn'],
          'expandedCities': [],
          'expandedStates': [],
          'expandedNations': [],
          'localityCoverage': {},
          'cityCoverage': {'Brooklyn': 0.8},
          'stateCoverage': {},
          'nationCoverage': {},
          'commutePatterns': {},
          'eventHostingLocations': {},
          'expansionHistory': [],
          'firstExpansionAt': null,
          'lastExpansionAt': null,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final expansion = GeographicExpansion.fromJson(json);

        expect(expansion.id, equals('expansion-1'));
        expect(expansion.clubId, equals('club-1'));
        expect(expansion.isClub, equals(true));
        expect(expansion.originalLocality, equals('Mission District, San Francisco'));
        expect(expansion.expandedLocalities, contains('Williamsburg, Brooklyn'));
        expect(expansion.cityCoverage['Brooklyn'], equals(0.8));
      });

      test('should handle JSON roundtrip correctly', () {
        final original = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedLocalities: ['Williamsburg, Brooklyn'],
          cityCoverage: {
            'Brooklyn': 0.8,
          },
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = original.toJson();
        final restored = GeographicExpansion.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.clubId, equals(original.clubId));
        expect(restored.isClub, equals(original.isClub));
        expect(restored.originalLocality, equals(original.originalLocality));
        expect(restored.expandedLocalities, equals(original.expandedLocalities));
        expect(restored.cityCoverage, equals(original.cityCoverage));
      });
    });

    group('CopyWith Method', () {
      test('should create copy with updated fields', () {
        final original = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          expandedLocalities: ['Williamsburg, Brooklyn'],
          cityCoverage: {'Brooklyn': 0.8},
        );

        expect(updated.id, equals(original.id));
        expect(updated.clubId, equals(original.clubId));
        expect(updated.expandedLocalities, contains('Williamsburg, Brooklyn'));
        expect(updated.cityCoverage['Brooklyn'], equals(0.8));
        expect(updated.isClub, equals(original.isClub));
      });

      test('should preserve original values when fields not specified', () {
        final original = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          expandedLocalities: ['Williamsburg, Brooklyn'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          cityCoverage: {'Brooklyn': 0.8},
        );

        expect(updated.expandedLocalities, equals(original.expandedLocalities));
        expect(updated.isClub, equals(original.isClub));
      });
    });

    group('Equatable Implementation', () {
      test('should be equal when all properties match', () {
        final expansion1 = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final expansion2 = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion1, equals(expansion2));
      });

      test('should not be equal when properties differ', () {
        final expansion1 = GeographicExpansion(
          id: 'expansion-1',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        final expansion2 = GeographicExpansion(
          id: 'expansion-2',
          clubId: 'club-1',
          isClub: true,
          originalLocality: 'Mission District, San Francisco',
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(expansion1, isNot(equals(expansion2)));
      });
    });
  });
}

