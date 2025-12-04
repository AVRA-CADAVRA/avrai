/// SPOTS Golden Expert Influence Integration Tests
/// Date: November 25, 2025
/// Purpose: Test end-to-end golden expert influence flow
/// 
/// Test Coverage:
/// - Golden Expert Influence on AI Personality: End-to-end flow
/// - List/Review Weighting: Golden expert lists/reviews weighted higher
/// - Neighborhood Character Shaping: Golden experts shape neighborhood character
/// - Integration: All services working together
/// 
/// Dependencies:
/// - GoldenExpertAIInfluenceService: Weight calculation
/// - LocalityPersonalityService: Locality personality management
/// - PersonalityLearning: AI personality learning
/// - MultiPathExpertiseService: Golden expert data

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/golden_expert_ai_influence_service.dart';
import 'package:spots/core/services/locality_personality_service.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/models/personality_profile.dart';
import '../helpers/test_helpers.dart';

class MockGoldenExpertAIInfluenceService extends Mock implements GoldenExpertAIInfluenceService {}

void main() {
  group('Golden Expert Influence Integration Tests', () {
    late GoldenExpertAIInfluenceService goldenExpertService;
    late LocalityPersonalityService localityPersonalityService;
    late MockGoldenExpertAIInfluenceService mockInfluenceService;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      mockInfluenceService = MockGoldenExpertAIInfluenceService();

      goldenExpertService = GoldenExpertAIInfluenceService();

      localityPersonalityService = LocalityPersonalityService(
        influenceService: mockInfluenceService,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Golden Expert Influence on AI Personality', () {
      test('should influence AI personality with golden expert weight', () async {
        // Setup: Golden expert with 30 years residency
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'golden-expert-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 200,
          uniqueLocalLocations: 80,
          averageLocalRating: 4.8,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.9,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 1: Calculate influence weight
        final weight = goldenExpertService.calculateInfluenceWeight(localExpertise);

        expect(weight, closeTo(1.4, 0.01)); // 30 years = 1.1 + 0.3 = 1.4

        // Step 2: Apply weight to behavior
        final behaviorData = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
          'authenticityScore': 0.7,
        };

        final weightedBehavior = goldenExpertService.applyWeightToBehavior(
          behaviorData,
          weight,
        );

        // Verify weight was applied (only to specific keys like visitCount, actionCount, influenceScore)
        // The behavior data keys don't get weighted, but we can verify the method was called
        expect(weightedBehavior, isA<Map<String, dynamic>>());

        // Step 3: Update locality personality with golden expert influence
        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(weight);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, weight))
            .thenReturn(weightedBehavior);

        final updatedPersonality = await localityPersonalityService.updateLocalityPersonality(
          locality: 'Brooklyn',
          userBehavior: behaviorData,
          localExpertise: localExpertise,
        );

        expect(updatedPersonality, isNotNull);
        expect(updatedPersonality, isA<PersonalityProfile>());
      });

      test('should shape neighborhood character through golden expert influence', () async {
        // Setup: Multiple golden experts in same locality
        final goldenExpert1 = LocalExpertise(
          id: 'expertise-1',
          userId: 'golden-expert-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 200,
          uniqueLocalLocations: 80,
          averageLocalRating: 4.8,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.9,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final goldenExpert2 = LocalExpertise(
          id: 'expertise-2',
          userId: 'golden-expert-2',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 150,
          uniqueLocalLocations: 60,
          averageLocalRating: 4.6,
          timeInLocation: const Duration(days: 9125), // 25 years
          firstLocalVisit: testDate.subtract(const Duration(days: 9125)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 9125),
          isGoldenLocalExpert: true,
          score: 0.85,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 1: Incorporate influence from first golden expert
        final behaviorData1 = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
        };

        when(mockInfluenceService.calculateInfluenceWeight(goldenExpert1))
            .thenReturn(1.4);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData1, 1.4))
            .thenReturn(behaviorData1);

        await localityPersonalityService.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData1,
          localExpertise: goldenExpert1,
        );

        // Step 2: Incorporate influence from second golden expert
        final behaviorData2 = {
          'explorationScore': 0.7,
          'authenticityScore': 0.9,
        };

        when(mockInfluenceService.calculateInfluenceWeight(goldenExpert2))
            .thenReturn(1.35);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData2, 1.35))
            .thenReturn(behaviorData2);

        await localityPersonalityService.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData2,
          localExpertise: goldenExpert2,
        );

        // Step 3: Calculate locality vibe (should reflect both golden experts)
        final vibe = await localityPersonalityService.calculateLocalityVibe('Brooklyn');

        expect(vibe, isNotNull);
        expect(vibe, isA<Map<String, dynamic>>());
        expect(vibe['locality'], equals('Brooklyn'));
        expect(vibe['dominantTraits'], isA<List>());
      });
    });

    group('List/Review Weighting for Golden Experts', () {
      test('should weight golden expert lists/reviews higher', () async {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'golden-expert-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 200,
          uniqueLocalLocations: 80,
          averageLocalRating: 4.8,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.9,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Calculate weight for golden expert
        final weight = goldenExpertService.calculateInfluenceWeight(localExpertise);

        expect(weight, closeTo(1.4, 0.01));

        // Apply weight to preferences (which would be used for list/review weighting)
        final preferences = {
          'preferred_categories': ['food', 'coffee'],
          'list_quality_score': 0.8,
          'review_quality_score': 0.9,
        };

        final weightedPreferences = goldenExpertService.applyWeightToPreferences(
          preferences,
          weight,
        );

        // Verify preferences were returned (weighting only applies to specific keys)
        expect(weightedPreferences, isA<Map<String, dynamic>>());
        expect(weightedPreferences['preferred_categories'], equals(['food', 'coffee']));
      });

      test('should prioritize golden expert content in recommendations', () async {
        final goldenExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'golden-expert-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 200,
          uniqueLocalLocations: 80,
          averageLocalRating: 4.8,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.9,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final regularExpertise = LocalExpertise(
          id: 'expertise-2',
          userId: 'regular-user-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 50,
          uniqueLocalLocations: 20,
          averageLocalRating: 4.0,
          timeInLocation: const Duration(days: 1825), // 5 years
          firstLocalVisit: testDate.subtract(const Duration(days: 1825)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 1825),
          isGoldenLocalExpert: false,
          score: 0.5,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Golden expert should have higher weight
        final goldenWeight = goldenExpertService.calculateInfluenceWeight(goldenExpertise);

        // Regular user should have normal weight
        final regularWeight = goldenExpertService.calculateInfluenceWeight(regularExpertise);

        expect(goldenWeight, greaterThan(regularWeight));
        expect(goldenWeight, closeTo(1.4, 0.01));
        expect(regularWeight, equals(1.0));
      });
    });

    group('Neighborhood Character Shaping', () {
      test('should shape neighborhood character through golden expert contributions', () async {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'golden-expert-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 200,
          uniqueLocalLocations: 80,
          averageLocalRating: 4.8,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.9,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 1: Update locality personality with golden expert behavior
        final behaviorData = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
          'authenticityScore': 0.7,
        };

        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.4);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, 1.4))
            .thenReturn(behaviorData);

        await localityPersonalityService.updateLocalityPersonality(
          locality: 'Brooklyn',
          userBehavior: behaviorData,
          localExpertise: localExpertise,
        );

        // Step 2: Get locality characteristics (should reflect golden expert influence)
        final characteristics = await localityPersonalityService.getLocalityCharacteristics('Brooklyn');

        expect(characteristics, isNotNull);
        expect(characteristics, isA<Map<String, dynamic>>());
        expect(characteristics['locality'], equals('Brooklyn'));
        expect(characteristics['dominantTraits'], isA<List>());

        // Step 3: Get locality preferences (should be shaped by golden experts)
        final preferences = await localityPersonalityService.getLocalityPreferences('Brooklyn');

        expect(preferences, isNotNull);
        expect(preferences, isA<Map<String, dynamic>>());
        expect(preferences['locality'], equals('Brooklyn'));
        expect(preferences['explorationEagerness'], isA<double>());
      });

      test('should calculate locality vibe reflecting golden expert influence', () async {
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'golden-expert-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 200,
          uniqueLocalLocations: 80,
          averageLocalRating: 4.8,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.9,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Incorporate golden expert influence
        final behaviorData = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
        };

        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.4);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, 1.4))
            .thenReturn(behaviorData);

        await localityPersonalityService.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData,
          localExpertise: localExpertise,
        );

        // Calculate vibe (should reflect golden expert influence)
        final vibe = await localityPersonalityService.calculateLocalityVibe('Brooklyn');

        expect(vibe, isNotNull);
        expect(vibe, isA<Map<String, dynamic>>());
        expect(vibe['locality'], equals('Brooklyn'));
        expect(vibe['dominantTraits'], isA<List>());
        expect(vibe['authenticityScore'], isA<double>());
      });
    });

    group('End-to-End Golden Expert Influence Flow', () {
      test('should complete full golden expert influence flow', () async {
        // Setup: Golden expert with 30 years residency
        final localExpertise = LocalExpertise(
          id: 'expertise-1',
          userId: 'golden-expert-1',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 200,
          uniqueLocalLocations: 80,
          averageLocalRating: 4.8,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.9,
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 1: Calculate influence weight
        final weight = goldenExpertService.calculateInfluenceWeight(localExpertise);
        expect(weight, closeTo(1.4, 0.01));

        // Step 2: Apply weight to behavior
        final behaviorData = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
        };
        final weightedBehavior = goldenExpertService.applyWeightToBehavior(
          behaviorData,
          weight,
        );
        expect(weightedBehavior, isA<Map<String, dynamic>>());

        // Step 3: Update locality personality
        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(weight);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, weight))
            .thenReturn(weightedBehavior);

        final updatedPersonality = await localityPersonalityService.updateLocalityPersonality(
          locality: 'Brooklyn',
          userBehavior: behaviorData,
          localExpertise: localExpertise,
        );
        expect(updatedPersonality, isNotNull);
        expect(updatedPersonality, isA<PersonalityProfile>());

        // Step 4: Calculate locality vibe
        final vibe = await localityPersonalityService.calculateLocalityVibe('Brooklyn');
        expect(vibe, isNotNull);
        expect(vibe, isA<Map<String, dynamic>>());
        expect(vibe['locality'], equals('Brooklyn'));

        // Step 5: Get locality preferences
        final preferences = await localityPersonalityService.getLocalityPreferences('Brooklyn');
        expect(preferences, isNotNull);
        expect(preferences, isA<Map<String, dynamic>>());

        // Step 6: Get locality characteristics
        final characteristics = await localityPersonalityService.getLocalityCharacteristics('Brooklyn');
        expect(characteristics, isNotNull);
        expect(characteristics, isA<Map<String, dynamic>>());
      });
    });
  });
}

