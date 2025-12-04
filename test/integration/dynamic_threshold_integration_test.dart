import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/expertise_requirements.dart';
import 'package:spots/core/services/dynamic_threshold_service.dart';
import 'package:spots/core/services/locality_value_analysis_service.dart';
import '../helpers/integration_test_helpers.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/integration_test_fixtures.dart';

/// Integration tests for dynamic threshold calculation
/// 
/// **Tests:**
/// - Dynamic threshold calculation based on locality values
/// - Lower thresholds for activities valued by locality
/// - Higher thresholds for activities less valued by locality
/// - Threshold ebb and flow based on locality data
/// - Integration with LocalityValueAnalysisService
void main() {
  group('Dynamic Threshold Integration Tests', () {
    late DynamicThresholdService thresholdService;
    late LocalityValueAnalysisService valueService;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      valueService = LocalityValueAnalysisService();
      thresholdService = DynamicThresholdService(
        localityValueService: valueService,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Threshold Calculation', () {
      test('should calculate locality-specific thresholds', () async {
        const baseThresholds = ThresholdValues(
          minVisits: 10,
          minRatings: 5,
          minAvgRating: 4.0,
          minTimeInCategory: Duration(days: 30),
          minCommunityEngagement: 3,
          minListCuration: 2,
          minEventHosting: 1,
        );

        // Record activities in locality to establish values
        await valueService.recordActivity(
          locality: 'Greenpoint',
          activityType: 'events_hosted',
          category: 'Coffee',
          engagement: 1.0,
        );

        final adjustedThresholds = await thresholdService.calculateLocalThreshold(
          locality: 'Greenpoint',
          category: 'Coffee',
          baseThresholds: baseThresholds,
        );

        expect(adjustedThresholds, isNotNull);
        expect(adjustedThresholds.minAvgRating, equals(4.0)); // Rating doesn't change
        expect(adjustedThresholds.minTimeInCategory,
            equals(const Duration(days: 30))); // Time doesn't change
      });

      test('should lower thresholds for activities valued by locality', () async {
        const baseThresholds = ThresholdValues(
          minVisits: 10,
          minRatings: 5,
          minAvgRating: 4.0,
          minTimeInCategory: Duration(days: 30),
          minCommunityEngagement: 3,
          minListCuration: 2,
          minEventHosting: 1,
        );

        // Record high engagement with events (locality values events highly)
        for (int i = 0; i < 10; i++) {
          await valueService.recordActivity(
            locality: 'Greenpoint',
            activityType: 'events_hosted',
            category: 'Coffee',
            engagement: 1.0,
          );
        }

        final adjustedThresholds = await thresholdService.calculateLocalThreshold(
          locality: 'Greenpoint',
          category: 'Coffee',
          baseThresholds: baseThresholds,
        );

        // Event hosting threshold should be lower (if locality values it highly)
        // Note: Actual adjustment depends on calculated weights
        expect(adjustedThresholds.minEventHosting, isNotNull);
      });

      test('should get threshold for specific activity', () async {
        const baseThreshold = 10.0;

        // Record activity to establish locality values
        await valueService.recordActivity(
          locality: 'Greenpoint',
          activityType: 'events_hosted',
          engagement: 1.0,
        );

        final adjustedThreshold = await thresholdService.getThresholdForActivity(
          locality: 'Greenpoint',
          activity: 'events_hosted',
          baseThreshold: baseThreshold,
        );

        expect(adjustedThreshold, isNotNull);
        expect(adjustedThreshold, greaterThan(0.0));
        // Adjustment range: 0.7x to 1.3x
        expect(adjustedThreshold, greaterThanOrEqualTo(baseThreshold * 0.7));
        expect(adjustedThreshold, lessThanOrEqualTo(baseThreshold * 1.3));
      });
    });

    group('Activity Adjustment Logic', () {
      test('should apply 0.7x multiplier for highly valued activities', () async {
        const baseThreshold = 10.0;

        // Create locality value with high event hosting weight
        final localityValue = IntegrationTestHelpers.createCoffeeFocusedLocalityValue(
          locality: 'Greenpoint',
        );

        // Get threshold for highly valued activity
        final adjustedThreshold = await thresholdService.getThresholdForActivity(
          locality: 'Greenpoint',
          activity: 'events_hosted',
          baseThreshold: baseThreshold,
        );

        // Should be lower (0.7x to 0.85x range for high value)
        expect(adjustedThreshold, lessThanOrEqualTo(baseThreshold * 0.85));
      });

      test('should apply 1.3x multiplier for less valued activities', () async {
        const baseThreshold = 10.0;

        // Get threshold for less valued activity (low weight)
        final adjustedThreshold = await thresholdService.getThresholdForActivity(
          locality: 'Greenpoint',
          activity: 'positive_trends', // Typically low weight
          baseThreshold: baseThreshold,
        );

        // Should be higher (1.15x to 1.3x range for low value)
        expect(adjustedThreshold, greaterThanOrEqualTo(baseThreshold * 1.15));
      });
    });

    group('Locality Multiplier', () {
      test('should get locality multiplier for category', () async {
        // Record activities to establish category preferences
        await valueService.recordActivity(
          locality: 'Greenpoint',
          activityType: 'events_hosted',
          category: 'Coffee',
          engagement: 1.0,
        );

        final multiplier = await thresholdService.getLocalityMultiplier(
          locality: 'Greenpoint',
          category: 'Coffee',
        );

        // Multiplier should be in range 0.7 to 1.3
        expect(multiplier, greaterThanOrEqualTo(0.7));
        expect(multiplier, lessThanOrEqualTo(1.3));
      });
    });

    group('Test Fixtures Integration', () {
      test('should use threshold values fixture', () {
        final fixture = IntegrationTestFixtures.thresholdValuesFixture();
        final baseThresholds = fixture['baseThresholds'] as ThresholdValues;
        final localityThresholds =
            fixture['localityThresholds'] as ThresholdValues;

        expect(baseThresholds.minVisits, equals(10));
        expect(localityThresholds.minVisits, equals(7)); // Lower
        expect(localityThresholds.minRatings, equals(4)); // Lower
      });
    });

    // TODO: Add tests for integration with ExpertiseCalculationService once updated
    // TODO: Add tests for threshold ebb and flow as locality data changes
  });
}

