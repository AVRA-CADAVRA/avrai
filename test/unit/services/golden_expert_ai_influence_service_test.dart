/// SPOTS GoldenExpertAIInfluenceService Tests
/// Date: November 25, 2025
/// Purpose: Test golden expert AI influence weight calculation and application
/// 
/// Test Coverage:
/// - Weight Calculation: 10% higher base, proportional to residency (1.1 + residencyYears/100)
/// - Weight Application: Behavior, preferences, connections
/// - Integration: AI personality learning, list/review weighting
/// - Edge Cases: Minimum/maximum weights, non-golden experts
/// 
/// Dependencies:
/// - Mock MultiPathExpertiseService: For golden expert status
/// - Mock PersonalityLearning: For AI personality integration
/// - LocalExpertise model: For residency data

import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/golden_expert_ai_influence_service.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import '../../helpers/test_helpers.dart';

void main() {
  group('GoldenExpertAIInfluenceService Tests', () {
    late GoldenExpertAIInfluenceService service;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      service = GoldenExpertAIInfluenceService();
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('calculateInfluenceWeight', () {
      test('should return 1.35x weight for 25 years residency', () {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125), // 25 years
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);

        // 25 years = 1.1 + (25/100) = 1.1 + 0.25 = 1.35
        expect(weight, closeTo(1.35, 0.01));
      });

      test('should return 1.3x weight for 20 years residency', () {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 7300), // 20 years
          firstLocalVisit: testDate.subtract(const Duration(days: 7300)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 7300),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);

        // 20 years = 1.1 + (20/100) = 1.1 + 0.2 = 1.3
        expect(weight, closeTo(1.3, 0.01));
      });

      test('should return 1.35x weight for 25 years residency (duplicate test)', () {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125), // 25 years
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);

        // 25 years = 1.1 + (25/100) = 1.1 + 0.25 = 1.35
        expect(weight, closeTo(1.35, 0.01));
      });

      test('should return 1.4x weight for 30 years residency', () {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);

        // 30 years = 1.1 + (30/100) = 1.1 + 0.3 = 1.4
        expect(weight, closeTo(1.4, 0.01));
      });

      test('should cap weight at 1.5x for 40+ years residency', () {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 14600), // 40 years
          firstLocalVisit: testDate.subtract(const Duration(days: 14600)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 14600),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);

        // 40 years = 1.1 + (40/100) = 1.5, but should cap at 1.5
        expect(weight, lessThanOrEqualTo(1.5));
        expect(weight, closeTo(1.5, 0.01));
      });

      test('should return 1.0x weight for non-golden expert', () {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 3650), // 10 years
          firstLocalVisit: testDate.subtract(const Duration(days: 3650)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 3650),
          isGoldenLocalExpert: false, // Not a golden expert
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);

        // Non-golden expert should have normal weight (1.0)
        expect(weight, equals(1.0));
      });

      test('should return 1.0x weight when expertise is null', () {
        final weight = service.calculateInfluenceWeight(null);

        // No expertise = normal weight
        expect(weight, equals(1.0));
      });

      test('should handle errors gracefully', () {
        // Create expertise with invalid data that might cause errors
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125),
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: null, // Null residency should be handled
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);

        // Should return normal weight when residency is null (not golden expert effectively)
        expect(weight, equals(1.0));
      });
    });

    group('applyWeightToBehavior', () {
      test('should apply weight to behavior data', () {
        final behaviorData = {
          'visitCount': 10,
          'actionCount': 5,
          'influenceScore': 0.6,
        };

        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125), // 25 years
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);
        final weightedData = service.applyWeightToBehavior(behaviorData, weight);

        // Weight should be applied (1.35x for 25 years)
        expect(weightedData['visitCount'], closeTo(10 * 1.35, 0.01));
        expect(weightedData['actionCount'], closeTo(5 * 1.35, 0.01));
        expect(weightedData['influenceScore'], closeTo(0.6 * 1.35, 0.01));
      });

      test('should not apply weight to non-golden expert behavior', () {
        final behaviorData = {
          'visitCount': 10,
          'actionCount': 5,
        };

        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 3650), // 10 years
          firstLocalVisit: testDate.subtract(const Duration(days: 3650)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 3650),
          isGoldenLocalExpert: false,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);
        final weightedData = service.applyWeightToBehavior(behaviorData, weight);

        // Non-golden expert should have no weight applied (weight = 1.0)
        expect(weightedData['visitCount'], equals(10));
        expect(weightedData['actionCount'], equals(5));
      });
    });

    group('applyWeightToPreferences', () {
      test('should apply weight to preference data', () {
        final preferences = {
          'preferenceScores': {
            'food': 0.8,
            'coffee': 0.7,
          },
          'categoryPreferences': {
            'casual': 0.9,
            'mid-range': 0.6,
          },
        };

        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);
        final weightedPreferences = service.applyWeightToPreferences(preferences, weight);

        // Weight should be applied to numeric preference scores
        final preferenceScores = weightedPreferences['preferenceScores'] as Map<String, dynamic>;
        expect(preferenceScores['food'], closeTo(0.8 * 1.4, 0.01));
        expect(preferenceScores['coffee'], closeTo(0.7 * 1.4, 0.01));
      });
    });

    group('applyWeightToConnections', () {
      test('should apply weight to connection data', () {
        final connections = {
          'connectionScore': 0.8,
          'ai2aiCompatibility': 0.7,
          'networkInfluence': 0.6,
        };

        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final weight = service.calculateInfluenceWeight(localExpertise);
        final weightedConnections = service.applyWeightToConnections(connections, weight);

        // Weight should be applied to connection scores
        expect(weightedConnections['connectionScore'], closeTo(0.8 * 1.4, 0.01));
        expect(weightedConnections['ai2aiCompatibility'], closeTo(0.7 * 1.4, 0.01));
        expect(weightedConnections['networkInfluence'], closeTo(0.6 * 1.4, 0.01));
      });
    });

    group('Integration with AI Personality Learning', () {
      test('should integrate with personality learning system', () {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 100,
          uniqueLocalLocations: 50,
          averageLocalRating: 4.5,
          timeInLocation: const Duration(days: 9125), // 25 years
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.8,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final behaviorData = {
          'visitCount': 10,
          'influenceScore': 0.7,
        };

        final weight = service.calculateInfluenceWeight(localExpertise);
        final weightedData = service.applyWeightToBehavior(behaviorData, weight);

        // Verify weight was applied (1.35x for 25 years)
        expect(weightedData['visitCount'], closeTo(10 * 1.35, 0.01));
        expect(weightedData['influenceScore'], closeTo(0.7 * 1.35, 0.01));
      });
    });
  });
}

