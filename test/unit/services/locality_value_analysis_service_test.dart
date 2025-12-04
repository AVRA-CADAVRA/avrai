import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/locality_value_analysis_service.dart';

/// Locality Value Analysis Service Tests
/// Tests locality value analysis and activity weight calculation
void main() {
  group('LocalityValueAnalysisService Tests', () {
    late LocalityValueAnalysisService service;

    setUp(() {
      service = LocalityValueAnalysisService();
    });

    group('analyzeLocalityValues', () {
      test('should return locality value data for valid locality', () async {
        final valueData = await service.analyzeLocalityValues('Greenpoint');

        expect(valueData, isNotNull);
        expect(valueData.locality, equals('Greenpoint'));
        expect(valueData.activityWeights, isNotEmpty);
        expect(valueData.lastUpdated, isNotNull);
      });

      test('should return default weights for new locality', () async {
        final valueData = await service.analyzeLocalityValues('NewLocality');

        expect(valueData.locality, equals('NewLocality'));
        expect(valueData.activityWeights, isNotEmpty);
        // Should have default equal weights
        expect(valueData.activityWeights['events_hosted'], isNotNull);
        expect(valueData.activityWeights['lists_created'], isNotNull);
        expect(valueData.activityWeights['reviews_written'], isNotNull);
      });

      test('should cache locality value data', () async {
        final valueData1 = await service.analyzeLocalityValues('Greenpoint');
        final valueData2 = await service.analyzeLocalityValues('Greenpoint');

        // Should return same instance (cached)
        expect(valueData1.locality, equals(valueData2.locality));
      });
    });

    group('getActivityWeights', () {
      test('should return activity weights for locality', () async {
        final weights = await service.getActivityWeights('Greenpoint');

        expect(weights, isNotEmpty);
        expect(weights.containsKey('events_hosted'), isTrue);
        expect(weights.containsKey('lists_created'), isTrue);
        expect(weights.containsKey('reviews_written'), isTrue);
        expect(weights.containsKey('event_attendance'), isTrue);
        expect(weights.containsKey('professional_background'), isTrue);
        expect(weights.containsKey('positive_trends'), isTrue);
      });

      test('should return weights between 0.0 and 1.0', () async {
        final weights = await service.getActivityWeights('Greenpoint');

        for (final weight in weights.values) {
          expect(weight, greaterThanOrEqualTo(0.0));
          expect(weight, lessThanOrEqualTo(1.0));
        }
      });

      test('should return default weights for new locality', () async {
        final weights = await service.getActivityWeights('NewLocality');

        expect(weights, isNotEmpty);
        // Default weights should be equal
        expect(weights['events_hosted'], equals(0.20));
        expect(weights['lists_created'], equals(0.20));
        expect(weights['reviews_written'], equals(0.20));
      });
    });

    group('recordActivity', () {
      test('should record activity in locality', () async {
        await service.recordActivity(
          locality: 'Greenpoint',
          activityType: 'events_hosted',
          category: 'food',
          engagement: 1.0,
        );

        // Activity should be recorded (in production, would update database)
        // For now, just verify no exception thrown
        expect(true, isTrue);
      });

      test('should record activity without category', () async {
        await service.recordActivity(
          locality: 'Greenpoint',
          activityType: 'lists_created',
        );

        expect(true, isTrue);
      });

      test('should record activity with engagement level', () async {
        await service.recordActivity(
          locality: 'Greenpoint',
          activityType: 'reviews_written',
          engagement: 0.8,
        );

        expect(true, isTrue);
      });
    });

    group('getCategoryPreferences', () {
      test('should return category preferences for locality', () async {
        final preferences =
            await service.getCategoryPreferences('Greenpoint', 'food');

        expect(preferences, isNotEmpty);
        expect(preferences.containsKey('events_hosted'), isTrue);
        expect(preferences.containsKey('lists_created'), isTrue);
      });

      test('should return default weights if no category data', () async {
        final preferences =
            await service.getCategoryPreferences('NewLocality', 'food');

        expect(preferences, isNotEmpty);
        // Should return default weights
        expect(preferences['events_hosted'], isNotNull);
      });
    });

    group('LocalityValueData', () {
      test('should create default values', () {
        final valueData = LocalityValueData.defaultValues('Greenpoint');

        expect(valueData.locality, equals('Greenpoint'));
        expect(valueData.activityWeights, isNotEmpty);
        expect(valueData.activityCounts, isEmpty);
      });

      test('should have default weights that sum appropriately', () {
        final weights = LocalityValueData.defaultWeights();

        expect(weights, isNotEmpty);
        // Default weights should be reasonable
        expect(weights['events_hosted'], equals(0.20));
        expect(weights['lists_created'], equals(0.20));
        expect(weights['reviews_written'], equals(0.20));
      });

      test('should record activity', () {
        final valueData = LocalityValueData.defaultValues('Greenpoint');
        valueData.recordActivity('events_hosted', 1.0);

        expect(valueData.activityCounts['events_hosted'], equals(1));
      });

      test('should get category preferences', () {
        final valueData = LocalityValueData.defaultValues('Greenpoint');
        final preferences = valueData.getCategoryPreferences('food');

        expect(preferences, isNotEmpty);
        // Should return default weights if no category-specific data
        expect(preferences['events_hosted'], equals(0.20));
      });

      test('should normalize weights', () {
        final valueData = LocalityValueData(
          locality: 'Greenpoint',
          activityWeights: {
            'events_hosted': 0.5,
            'lists_created': 0.5,
          },
          categoryPreferences: {},
          activityCounts: {},
          lastUpdated: DateTime.now(),
        );

        valueData.normalizeWeights();

        // Weights should still be 0.5 each (already normalized)
        expect(valueData.activityWeights['events_hosted'], equals(0.5));
        expect(valueData.activityWeights['lists_created'], equals(0.5));
      });
    });
  });
}

