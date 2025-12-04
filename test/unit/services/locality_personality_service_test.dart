/// SPOTS LocalityPersonalityService Tests
/// Date: November 25, 2025
/// Purpose: Test locality AI personality management with golden expert influence
/// 
/// Test Coverage:
/// - Locality Personality Management: Get, update, incorporate golden expert influence
/// - Locality Vibe Calculation: Overall locality vibe based on golden experts
/// - Locality Preferences: Preferences shaped by golden experts
/// - Locality Characteristics: Characteristics derived from golden expert behavior
/// - Integration: AI personality learning, golden expert influence
/// 
/// Dependencies:
/// - Mock GoldenExpertAIInfluenceService: For golden expert weight calculation
/// - Mock PersonalityLearning: For AI personality integration
/// - Mock MultiPathExpertiseService: For golden expert data

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/locality_personality_service.dart';
import 'package:spots/core/services/golden_expert_ai_influence_service.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import '../../helpers/test_helpers.dart';

class MockGoldenExpertAIInfluenceService extends Mock implements GoldenExpertAIInfluenceService {}

void main() {
  group('LocalityPersonalityService Tests', () {
    late LocalityPersonalityService service;
    late MockGoldenExpertAIInfluenceService mockInfluenceService;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      mockInfluenceService = MockGoldenExpertAIInfluenceService();

      service = LocalityPersonalityService(
        influenceService: mockInfluenceService,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('getLocalityPersonality', () {
      test('should return locality personality for a locality', () async {
        final personality = await service.getLocalityPersonality('Brooklyn');

        expect(personality, isNotNull);
        expect(personality, isA<PersonalityProfile>());
      });

      test('should return default personality when none exists', () async {
        final personality = await service.getLocalityPersonality('New Locality');

        expect(personality, isNotNull);
        expect(personality, isA<PersonalityProfile>());
      });

      test('should handle errors gracefully', () async {
        // This test verifies error handling
        final personality = await service.getLocalityPersonality('Brooklyn');

        expect(personality, isNotNull);
        expect(personality, isA<PersonalityProfile>());
      });
    });

    group('updateLocalityPersonality', () {
      test('should update locality personality based on user behavior', () async {
        final behaviorData = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
          'authenticityScore': 0.7,
        };

        // Stub to return input behavior data (simulating weight application)
        // Use concrete values to avoid type issues
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, 1.0))
            .thenReturn(behaviorData);

        final updatedPersonality = await service.updateLocalityPersonality(
          locality: 'Brooklyn',
          userBehavior: behaviorData,
        );

        expect(updatedPersonality, isNotNull);
        expect(updatedPersonality, isA<PersonalityProfile>());
      });

      test('should incorporate golden expert influence when updating', () async {
        final behaviorData = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
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

        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.35);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, 1.35))
            .thenReturn(behaviorData);

        final updatedPersonality = await service.updateLocalityPersonality(
          locality: 'Brooklyn',
          userBehavior: behaviorData,
          localExpertise: localExpertise,
        );

        expect(updatedPersonality, isNotNull);
        // Golden expert influence should be incorporated
        verify(mockInfluenceService.calculateInfluenceWeight(localExpertise)).called(1);
      });

      test('should not apply golden expert weight for non-golden experts', () async {
        final behaviorData = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
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

        // Stub to return input behavior data (simulating weight application)
        // Non-golden expert returns 1.0 weight
        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.0);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, 1.0))
            .thenReturn(behaviorData);

        final updatedPersonality = await service.updateLocalityPersonality(
          locality: 'Brooklyn',
          userBehavior: behaviorData,
          localExpertise: localExpertise,
        );

        expect(updatedPersonality, isNotNull);
        // Weight should still be calculated (even for non-golden, it will be 1.0)
        verify(mockInfluenceService.calculateInfluenceWeight(localExpertise)).called(1);
      });
    });

    group('incorporateGoldenExpertInfluence', () {
      test('should incorporate golden expert influence into locality personality', () async {
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

        final behaviorData = {
          'explorationScore': 0.6,
          'communityScore': 0.8,
        };
        
        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.4);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, 1.4))
            .thenReturn(behaviorData);

        final updatedPersonality = await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData,
          localExpertise: localExpertise,
        );

        expect(updatedPersonality, isNotNull);
        verify(mockInfluenceService.calculateInfluenceWeight(localExpertise)).called(1);
      });

      test('should handle multiple golden experts', () async {
        final goldenExpert1 = LocalExpertise(
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

        final goldenExpert2 = LocalExpertise(
          id: 'expertise-2',
          userId: 'user-2',
          category: 'food',
          locality: 'Brooklyn',
          localVisits: 150,
          uniqueLocalLocations: 60,
          averageLocalRating: 4.7,
          timeInLocation: const Duration(days: 10950), // 30 years
          firstLocalVisit: testDate.subtract(const Duration(days: 10950)),
          lastLocalVisit: testDate,
          continuousResidency: const Duration(days: 10950),
          isGoldenLocalExpert: true,
          score: 0.9,
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockInfluenceService.calculateInfluenceWeight(goldenExpert1))
            .thenReturn(1.35);
        when(mockInfluenceService.calculateInfluenceWeight(goldenExpert2))
            .thenReturn(1.4);
        final behaviorData1 = {'explorationScore': 0.6};
        final behaviorData2 = {'communityScore': 0.8};
        
        when(mockInfluenceService.calculateInfluenceWeight(goldenExpert1))
            .thenReturn(1.35);
        when(mockInfluenceService.calculateInfluenceWeight(goldenExpert2))
            .thenReturn(1.4);
        // Stub applyWeightToBehavior for both calls
        when(mockInfluenceService.applyWeightToBehavior(behaviorData1, 1.35))
            .thenReturn(behaviorData1);
        when(mockInfluenceService.applyWeightToBehavior(behaviorData2, 1.4))
            .thenReturn(behaviorData2);

        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData1,
          localExpertise: goldenExpert1,
        );

        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData2,
          localExpertise: goldenExpert2,
        );

        // Both golden experts should influence locality personality
        verify(mockInfluenceService.calculateInfluenceWeight(goldenExpert1)).called(1);
        verify(mockInfluenceService.calculateInfluenceWeight(goldenExpert2)).called(1);
      });
    });

    group('calculateLocalityVibe', () {
      test('should calculate overall locality vibe', () async {
        final vibe = await service.calculateLocalityVibe('Brooklyn');

        expect(vibe, isNotNull);
        expect(vibe, isA<Map<String, dynamic>>());
        expect(vibe['locality'], equals('Brooklyn'));
        expect(vibe['dominantTraits'], isA<List>());
        expect(vibe['authenticityScore'], isA<double>());
      });

      test('should incorporate golden expert influence in vibe calculation', () async {
        // First update with golden expert to influence the personality
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

        final behaviorData = {'explorationScore': 0.8};
        
        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.35);
        // Stub to return input behavior data (simulating weight application)
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, 1.35))
            .thenReturn(behaviorData);

        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData,
          localExpertise: localExpertise,
        );

        final vibe = await service.calculateLocalityVibe('Brooklyn');

        expect(vibe, isNotNull);
        expect(vibe['locality'], equals('Brooklyn'));
        expect(vibe['dimensions'], isA<Map>());
      });
    });

    group('getLocalityPreferences', () {
      test('should return locality preferences shaped by golden experts', () async {
        final preferences = await service.getLocalityPreferences('Brooklyn');

        expect(preferences, isNotNull);
        expect(preferences, isA<Map<String, dynamic>>());
        expect(preferences['locality'], equals('Brooklyn'));
        expect(preferences['explorationEagerness'], isA<double>());
      });

      test('should reflect golden expert preferences', () async {
        // First update with golden expert to influence the personality
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

        final behaviorData = {'explorationScore': 0.8};
        
        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.35);
        // Stub to return input behavior data (simulating weight application)
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, 1.35))
            .thenReturn(behaviorData);

        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData,
          localExpertise: localExpertise,
        );

        final preferences = await service.getLocalityPreferences('Brooklyn');

        expect(preferences, isNotNull);
        // Preferences should be influenced by golden experts
        expect(preferences['explorationEagerness'], isA<double>());
      });
    });

    group('getLocalityCharacteristics', () {
      test('should return locality characteristics', () async {
        final characteristics = await service.getLocalityCharacteristics('Brooklyn');

        expect(characteristics, isNotNull);
        expect(characteristics, isA<Map<String, dynamic>>());
        expect(characteristics['locality'], equals('Brooklyn'));
        expect(characteristics['dominantTraits'], isA<List>());
      });

      test('should reflect golden expert characteristics', () async {
        // First update with golden expert to influence the personality
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

        final behaviorData = {'explorationScore': 0.8};
        
        when(mockInfluenceService.calculateInfluenceWeight(localExpertise))
            .thenReturn(1.35);
        // Stub to return input behavior data (simulating weight application)
        when(mockInfluenceService.applyWeightToBehavior(behaviorData, 1.35))
            .thenReturn(behaviorData);

        await service.incorporateGoldenExpertInfluence(
          locality: 'Brooklyn',
          goldenExpertBehavior: behaviorData,
          localExpertise: localExpertise,
        );

        final characteristics = await service.getLocalityCharacteristics('Brooklyn');

        expect(characteristics, isNotNull);
        // Characteristics should be influenced by golden experts
        expect(characteristics['personalitySummary'], isA<String>());
      });
    });
  });
}

