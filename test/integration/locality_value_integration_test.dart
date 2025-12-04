import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/locality_value_analysis_service.dart';
import 'package:spots/core/models/locality_value.dart';
import 'package:spots/core/models/local_expert_qualification.dart';
import '../helpers/integration_test_helpers.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/integration_test_fixtures.dart';

/// Integration tests for locality value analysis
/// 
/// **Tests:**
/// - Locality value analysis logic
/// - Activity weight calculation
/// - Category preferences
/// - Local expert qualification logic
/// - Integration with qualification models
void main() {
  group('Locality Value Analysis Integration Tests', () {
    late LocalityValueAnalysisService valueService;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      valueService = LocalityValueAnalysisService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Locality Value Analysis', () {
      test('should analyze locality values', () async {
        final valueData = await valueService.analyzeLocalityValues('Greenpoint');

        expect(valueData, isNotNull);
        expect(valueData.locality, equals('Greenpoint'));
        expect(valueData.activityWeights, isNotEmpty);
      });

      test('should get activity weights for locality', () async {
        final weights = await valueService.getActivityWeights('Greenpoint');

        expect(weights, isNotEmpty);
        expect(weights.containsKey('events_hosted'), isTrue);
        expect(weights.containsKey('lists_created'), isTrue);
        expect(weights.containsKey('reviews_written'), isTrue);

        // Weights should sum to approximately 1.0 (normalized)
        final total = weights.values.fold(0.0, (a, b) => a + b);
        expect(total, closeTo(1.0, 0.1));
      });

      test('should record activity and update weights', () async {
        // Record multiple events to establish high event hosting value
        for (int i = 0; i < 20; i++) {
          await valueService.recordActivity(
            locality: 'Greenpoint',
            activityType: 'events_hosted',
            category: 'Coffee',
            engagement: 1.0,
          );
        }

        final weights = await valueService.getActivityWeights('Greenpoint');
        expect(weights['events_hosted'], isNotNull);
      });
    });

    group('Category Preferences', () {
      test('should get category preferences', () async {
        // Record category-specific activities
        await valueService.recordActivity(
          locality: 'Greenpoint',
          activityType: 'events_hosted',
          category: 'Coffee',
          engagement: 1.0,
        );

        final preferences = await valueService.getCategoryPreferences(
          'Greenpoint',
          'Coffee',
        );

        expect(preferences, isNotEmpty);
        expect(preferences.containsKey('events_hosted'), isTrue);
      });

      test('should return default weights if no category preferences', () async {
        final preferences = await valueService.getCategoryPreferences(
          'Greenpoint',
          'UnknownCategory',
        );

        expect(preferences, isNotEmpty);
        // Should return default weights
      });
    });

    group('Local Expert Qualification', () {
      test('should track qualification progress', () {
        final qualification = IntegrationTestHelpers.createTestQualification(
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          progress: IntegrationTestHelpers.createTestProgress(
            visits: 5,
            ratings: 3,
            avgRating: 4.5,
            communityEngagement: 1,
            listCuration: 1,
            eventHosting: 0,
          ),
        );

        expect(qualification.progressPercentage, greaterThan(0.0));
        expect(qualification.progressPercentage, lessThan(1.0));
        expect(qualification.remainingRequirements, isNotEmpty);
      });

      test('should calculate progress percentage correctly', () {
        final qualification = IntegrationTestHelpers.createTestQualification(
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          progress: IntegrationTestHelpers.createTestProgress(
            visits: 7, // Met
            ratings: 4, // Met
            avgRating: 4.5, // Met
            communityEngagement: 2, // Met
            listCuration: 1, // Met
            eventHosting: 1, // Met
          ),
        );

        expect(qualification.progressPercentage, equals(1.0));
        expect(qualification.remainingRequirements, isEmpty);
      });

      test('should track qualification factors', () {
        final qualification = IntegrationTestHelpers.createTestQualification(
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          factors: IntegrationTestHelpers.createTestFactors(
            listsWithFollowers: 3,
            peerReviewedReviews: 5,
            hasProfessionalBackground: true,
            hasPositiveTrends: true,
            listRespectRate: 0.8,
            eventGrowthRate: 0.5,
          ),
        );

        expect(qualification.factors.listsWithFollowers, equals(3));
        expect(qualification.factors.peerReviewedReviews, equals(5));
        expect(qualification.factors.hasProfessionalBackground, isTrue);
        expect(qualification.factors.hasPositiveTrends, isTrue);
      });
    });

    group('Qualification Logic', () {
      test('should identify qualified local expert', () {
        final qualification = IntegrationTestHelpers.createTestQualification(
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          progress: IntegrationTestHelpers.createTestProgress(
            visits: 7,
            ratings: 4,
            avgRating: 4.5,
            communityEngagement: 2,
            listCuration: 1,
            eventHosting: 1,
          ),
          factors: IntegrationTestHelpers.createTestFactors(
            listsWithFollowers: 2,
            hasPositiveTrends: true,
          ),
          isQualified: true,
        );

        expect(qualification.isQualified, isTrue);
        expect(qualification.qualifiedAt, isNotNull);
        expect(qualification.progressPercentage, equals(1.0));
      });

      test('should identify unqualified user with remaining requirements', () {
        final qualification = IntegrationTestHelpers.createTestQualification(
          userId: 'user-123',
          category: 'Coffee',
          locality: 'Greenpoint',
          progress: IntegrationTestHelpers.createTestProgress(
            visits: 5, // Needs 2 more
            ratings: 2, // Needs 2 more
            avgRating: 4.5, // Met
            communityEngagement: 1, // Needs 1 more
            listCuration: 1, // Met
            eventHosting: 0, // Needs 1 more
          ),
        );

        expect(qualification.isQualified, isFalse);
        expect(qualification.progressPercentage, lessThan(1.0));
        expect(qualification.remainingRequirements.length, greaterThan(0));
      });
    });

    group('Test Fixtures Integration', () {
      test('should use locality value fixture', () {
        final fixture = IntegrationTestFixtures.localityValueFixture();
        final value = fixture['value'] as LocalityValue;

        expect(value.locality, equals('Greenpoint'));
        expect(fixture['valuesEventsHighly'], isTrue);
        expect(value.getActivityWeight('events_hosted'), greaterThan(0.25));
      });

      test('should use local expert qualification fixture', () {
        final fixture = IntegrationTestFixtures.localExpertQualificationFixture();
        final qualification =
            fixture['qualification'] as LocalExpertQualification;

        expect(qualification.category, equals('Coffee'));
        expect(qualification.locality, equals('Greenpoint'));
        expect(qualification.isQualified, isFalse);
        expect(fixture['progressPercentage'], greaterThan(0.0));
        expect(fixture['remainingRequirements'], isNotEmpty);
      });

      test('should use qualified local expert fixture', () {
        final fixture = IntegrationTestFixtures.qualifiedLocalExpertFixture();
        final qualification =
            fixture['qualification'] as LocalExpertQualification;

        expect(qualification.isQualified, isTrue);
        expect(fixture['qualifiedAt'], isNotNull);
      });
    });

    // TODO: Add tests for integration with ExpertiseCalculationService
    // TODO: Add tests for dynamic threshold updates as locality values change
  });
}

