import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/expertise_calculation_service.dart';
import 'package:spots/core/services/saturation_algorithm_service.dart';
import 'package:spots/core/services/multi_path_expertise_service.dart';
import 'package:spots/core/models/platform_phase.dart';
import 'package:spots/core/models/saturation_metrics.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import '../../helpers/test_helpers.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'expertise_calculation_service_test.mocks.dart';

@GenerateMocks([
  SaturationAlgorithmService,
  MultiPathExpertiseService,
])
void main() {
  group('ExpertiseCalculationService Tests', () {
    late ExpertiseCalculationService service;
    late MockSaturationAlgorithmService mockSaturationService;
    late MockMultiPathExpertiseService mockMultiPathService;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      mockSaturationService = MockSaturationAlgorithmService();
      mockMultiPathService = MockMultiPathExpertiseService();
      service = ExpertiseCalculationService(
        saturationService: mockSaturationService,
        multiPathService: mockMultiPathService,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('calculateExpertise', () {
      test('should calculate expertise with all paths', () async {
        // Setup mocks
        final saturationMetrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 100,
          totalUserCount: 5000,
          saturationRatio: 0.02,
          qualityScore: 0.8,
          growthRate: 5.0,
          competitionLevel: 0.4,
          marketDemand: 0.6,
          factors: SaturationFactors(
            supplyRatio: 0.5,
            qualityDistribution: 0.8,
            utilizationRate: 0.7,
            demandSignal: 0.6,
            growthVelocity: 0.3,
            geographicDistribution: 0.4,
          ),
          saturationScore: 0.5,
          recommendation: SaturationRecommendation.maintain,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        when(mockSaturationService.analyzeCategorySaturation(
          category: anyNamed('category'),
          currentExpertCount: anyNamed('currentExpertCount'),
          totalUserCount: anyNamed('totalUserCount'),
          qualityMetrics: anyNamed('qualityMetrics'),
          utilizationMetrics: anyNamed('utilizationMetrics'),
          demandMetrics: anyNamed('demandMetrics'),
          growthMetrics: anyNamed('growthMetrics'),
          geographicMetrics: anyNamed('geographicMetrics'),
        )).thenAnswer((_) async => saturationMetrics);

        final explorationExpertise = ExplorationExpertise(
          id: 'exp-1',
          userId: 'user-1',
          category: 'Coffee',
          totalVisits: 50,
          uniqueLocations: 30,
          repeatVisits: 20,
          reviewsGiven: 35,
          averageRating: 4.5,
          averageQualityScore: 1.2,
          highQualityVisits: 25,
          totalDwellTime: const Duration(hours: 50),
          firstVisit: testDate.subtract(const Duration(days: 180)),
          lastVisit: testDate,
          score: 0.85,
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockMultiPathService.calculateExplorationExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
          visits: anyNamed('visits'),
        )).thenAnswer((_) async => explorationExpertise);

        when(mockMultiPathService.calculateCredentialExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
        )).thenAnswer((_) async => CredentialExpertise(
              id: 'cred-1',
              userId: 'user-1',
              category: 'Coffee',
              score: 0.0,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        when(mockMultiPathService.calculateInfluenceExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
        )).thenAnswer((_) async => InfluenceExpertise(
              id: 'inf-1',
              userId: 'user-1',
              category: 'Coffee',
              score: 0.0,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        when(mockMultiPathService.calculateProfessionalExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
        )).thenAnswer((_) async => ProfessionalExpertise(
              id: 'prof-1',
              userId: 'user-1',
              category: 'Coffee',
              score: 0.0,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        when(mockMultiPathService.calculateCommunityExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
        )).thenAnswer((_) async => CommunityExpertise(
              id: 'comm-1',
              userId: 'user-1',
              category: 'Coffee',
              score: 0.0,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        when(mockMultiPathService.calculateLocalExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
          locality: anyNamed('locality'),
        )).thenAnswer((_) async => LocalExpertise(
              id: 'local-1',
              userId: 'user-1',
              category: 'Coffee',
              locality: 'NYC',
              localVisits: 0,
              uniqueLocalLocations: 0,
              averageLocalRating: 0.0,
              timeInLocation: Duration.zero,
              firstLocalVisit: testDate,
              lastLocalVisit: testDate,
              score: 0.0,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        // Execute
        final result = await service.calculateExpertise(
          userId: 'user-1',
          category: 'Coffee',
          platformPhase: PhaseName.growth,
          userCount: 5000,
        );

        // Verify
        expect(result.userId, equals('user-1'));
        expect(result.category, equals('Coffee'));
        expect(result.totalScore, greaterThan(0.0));
        expect(result.pathScores, isNotEmpty);
        expect(result.expertiseLevel, isNotNull);
      });

      test('should calculate expertise level based on total score', () async {
        // Setup mocks for high expertise user
        final saturationMetrics = SaturationMetrics(
          category: 'Coffee',
          currentExpertCount: 100,
          totalUserCount: 5000,
          saturationRatio: 0.02,
          qualityScore: 0.8,
          growthRate: 5.0,
          competitionLevel: 0.4,
          marketDemand: 0.6,
          factors: SaturationFactors(
            supplyRatio: 0.5,
            qualityDistribution: 0.8,
            utilizationRate: 0.7,
            demandSignal: 0.6,
            growthVelocity: 0.3,
            geographicDistribution: 0.4,
          ),
          saturationScore: 0.5,
          recommendation: SaturationRecommendation.maintain,
          calculatedAt: testDate,
          updatedAt: testDate,
        );

        when(mockSaturationService.analyzeCategorySaturation(
          category: anyNamed('category'),
          currentExpertCount: anyNamed('currentExpertCount'),
          totalUserCount: anyNamed('totalUserCount'),
          qualityMetrics: anyNamed('qualityMetrics'),
          utilizationMetrics: anyNamed('utilizationMetrics'),
          demandMetrics: anyNamed('demandMetrics'),
          growthMetrics: anyNamed('growthMetrics'),
          geographicMetrics: anyNamed('geographicMetrics'),
        )).thenAnswer((_) async => saturationMetrics);

        // High scores for all paths
        when(mockMultiPathService.calculateExplorationExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
          visits: anyNamed('visits'),
        )).thenAnswer((_) async => ExplorationExpertise(
              id: 'exp-1',
              userId: 'user-1',
              category: 'Coffee',
              totalVisits: 100,
              uniqueLocations: 50,
              repeatVisits: 50,
              reviewsGiven: 80,
              averageRating: 4.8,
              averageQualityScore: 1.4,
              highQualityVisits: 60,
              totalDwellTime: const Duration(hours: 200),
              firstVisit: testDate.subtract(const Duration(days: 365)),
              lastVisit: testDate,
              score: 0.95,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        when(mockMultiPathService.calculateCredentialExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
        )).thenAnswer((_) async => CredentialExpertise(
              id: 'cred-1',
              userId: 'user-1',
              category: 'Coffee',
              score: 0.90,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        when(mockMultiPathService.calculateInfluenceExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
        )).thenAnswer((_) async => InfluenceExpertise(
              id: 'inf-1',
              userId: 'user-1',
              category: 'Coffee',
              spotsFollowers: 1000,
              listSaves: 500,
              listShares: 200,
              listEngagement: 1000,
              score: 0.85,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        when(mockMultiPathService.calculateProfessionalExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
        )).thenAnswer((_) async => ProfessionalExpertise(
              id: 'prof-1',
              userId: 'user-1',
              category: 'Coffee',
              score: 0.80,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        when(mockMultiPathService.calculateCommunityExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
        )).thenAnswer((_) async => CommunityExpertise(
              id: 'comm-1',
              userId: 'user-1',
              category: 'Coffee',
              questionsAnswered: 50,
              curatedLists: 20,
              popularLists: 10,
              eventsHosted: 15,
              averageEventRating: 4.7,
              peerEndorsements: 25,
              communityContributions: 100,
              score: 0.90,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        when(mockMultiPathService.calculateLocalExpertise(
          userId: anyNamed('userId'),
          category: anyNamed('category'),
          locality: anyNamed('locality'),
        )).thenAnswer((_) async => LocalExpertise(
              id: 'local-1',
              userId: 'user-1',
              category: 'Coffee',
              locality: 'NYC',
              localVisits: 80,
              uniqueLocalLocations: 40,
              averageLocalRating: 4.6,
              timeInLocation: const Duration(days: 730),
              firstLocalVisit: testDate.subtract(const Duration(days: 730)),
              lastLocalVisit: testDate,
              score: 0.75,
              createdAt: testDate,
              updatedAt: testDate,
            ));

        // Execute
        final result = await service.calculateExpertise(
          userId: 'user-1',
          category: 'Coffee',
          platformPhase: PhaseName.growth,
          userCount: 5000,
        );

        // Verify high expertise level
        expect(result.totalScore, greaterThan(0.7));
        expect(result.expertiseLevel, isNotNull);
        expect(result.meetsRequirements, isTrue);
      });
    });

    group('calculateCategoryExpertise', () {
      test('should calculate expertise for multiple categories', () async {
        // This would test calculating expertise across multiple categories
        // Implementation depends on service method
      });
    });
  });
}

