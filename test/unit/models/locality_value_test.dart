import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/locality_value.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for LocalityValue model
void main() {
  group('LocalityValue Model Tests', () {
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create locality value with required fields', () {
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {
            'events_hosted': 0.30,
            'lists_created': 0.25,
            'reviews_written': 0.20,
            'event_attendance': 0.15,
            'professional_background': 0.10,
          },
          categoryPreferences: {},
          activityCounts: {
            'events_hosted': 50,
            'lists_created': 30,
          },
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(localityValue.id, equals('value-123'));
        expect(localityValue.locality, equals('Greenpoint'));
        expect(localityValue.activityWeights.length, equals(5));
        expect(localityValue.activityCounts.length, equals(2));
      });
    });

    group('Activity Weight Methods', () {
      test('should return activity weight', () {
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {
            'events_hosted': 0.30,
            'lists_created': 0.25,
          },
          categoryPreferences: {},
          activityCounts: {},
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(localityValue.getActivityWeight('events_hosted'), equals(0.30));
        expect(localityValue.getActivityWeight('lists_created'), equals(0.25));
        expect(localityValue.getActivityWeight('unknown'), equals(0.0));
      });

      test('should check if activity is valued highly', () {
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {
            'events_hosted': 0.30, // High (>= 0.25)
            'lists_created': 0.20, // Low (< 0.25)
          },
          categoryPreferences: {},
          activityCounts: {},
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(localityValue.valuesActivityHighly('events_hosted'), isTrue);
        expect(localityValue.valuesActivityHighly('lists_created'), isFalse);
      });
    });

    group('Category Preferences', () {
      test('should return category preferences', () {
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {
            'events_hosted': 0.20,
          },
          categoryPreferences: {
            'Coffee': {
              'events_hosted': 0.35,
              'lists_created': 0.30,
            },
          },
          activityCounts: {},
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final coffeePrefs = localityValue.getCategoryPreferences('Coffee');
        expect(coffeePrefs['events_hosted'], equals(0.35));
        expect(coffeePrefs['lists_created'], equals(0.30));

        // Unknown category returns default weights
        final unknownPrefs = localityValue.getCategoryPreferences('Unknown');
        expect(unknownPrefs['events_hosted'], equals(0.20));
      });
    });

    group('Activity Counts', () {
      test('should return activity count', () {
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {},
          categoryPreferences: {},
          activityCounts: {
            'events_hosted': 50,
            'lists_created': 30,
          },
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(localityValue.getActivityCount('events_hosted'), equals(50));
        expect(localityValue.getActivityCount('lists_created'), equals(30));
        expect(localityValue.getActivityCount('unknown'), equals(0));
      });

      test('should calculate total activity count', () {
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {},
          categoryPreferences: {},
          activityCounts: {
            'events_hosted': 50,
            'lists_created': 30,
            'reviews_written': 20,
          },
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(localityValue.totalActivityCount, equals(100));
      });
    });

    group('JSON Serialization', () {
      test('should serialize to JSON', () {
        final localityValue = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {
            'events_hosted': 0.30,
            'lists_created': 0.25,
          },
          categoryPreferences: {
            'Coffee': {
              'events_hosted': 0.35,
            },
          },
          activityCounts: {
            'events_hosted': 50,
          },
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = localityValue.toJson();

        expect(json['id'], equals('value-123'));
        expect(json['locality'], equals('Greenpoint'));
        expect(json['activityWeights'], equals({
          'events_hosted': 0.30,
          'lists_created': 0.25,
        }));
        expect(json['activityCounts'], equals({'events_hosted': 50}));
        expect(json['lastAnalyzed'], equals(testDate.toIso8601String()));
      });

      test('should deserialize from JSON', () {
        final json = {
          'id': 'value-123',
          'locality': 'Greenpoint',
          'activityWeights': {
            'events_hosted': 0.30,
            'lists_created': 0.25,
          },
          'categoryPreferences': {
            'Coffee': {
              'events_hosted': 0.35,
            },
          },
          'activityCounts': {
            'events_hosted': 50,
          },
          'lastAnalyzed': testDate.toIso8601String(),
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final localityValue = LocalityValue.fromJson(json);

        expect(localityValue.id, equals('value-123'));
        expect(localityValue.locality, equals('Greenpoint'));
        expect(localityValue.getActivityWeight('events_hosted'), equals(0.30));
        expect(localityValue.getActivityCount('events_hosted'), equals(50));
      });
    });

    group('Copy With', () {
      test('should create copy with updated fields', () {
        final original = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {'events_hosted': 0.30},
          categoryPreferences: {},
          activityCounts: {},
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          locality: 'DUMBO',
          activityWeights: {'events_hosted': 0.35},
        );

        expect(updated.id, equals('value-123'));
        expect(updated.locality, equals('DUMBO'));
        expect(updated.getActivityWeight('events_hosted'), equals(0.35));
      });
    });

    group('Equality', () {
      test('should be equal when all properties match', () {
        final value1 = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {'events_hosted': 0.30},
          categoryPreferences: {},
          activityCounts: {},
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final value2 = LocalityValue(
          id: 'value-123',
          locality: 'Greenpoint',
          activityWeights: {'events_hosted': 0.30},
          categoryPreferences: {},
          activityCounts: {},
          lastAnalyzed: testDate,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(value1, equals(value2));
      });
    });
  });
}

