import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/expertise_calculation_service.dart';
import 'package:spots/core/services/saturation_algorithm_service.dart';
import 'package:spots/core/services/multi_path_expertise_service.dart';
import 'package:spots/core/services/automatic_check_in_service.dart';
import 'package:spots/core/models/platform_phase.dart';
import 'package:spots/core/models/saturation_metrics.dart';
import 'package:spots/core/models/expertise_requirements.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/models/visit.dart';
import '../../helpers/test_helpers.dart';

/// Integration tests for expertise services
/// Tests the full flow of expertise calculation with all services working together
void main() {
  group('Expertise Services Integration Tests', () {
    late SaturationAlgorithmService saturationService;
    late MultiPathExpertiseService multiPathService;
    late ExpertiseCalculationService calculationService;
    late AutomaticCheckInService checkInService;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      saturationService = SaturationAlgorithmService();
      multiPathService = MultiPathExpertiseService();
      checkInService = AutomaticCheckInService();
      calculationService = ExpertiseCalculationService(
        saturationService: saturationService,
        multiPathService: multiPathService,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Full Expertise Calculation Flow', () {
      test('should calculate expertise from visits to final score', () async {
        // Step 1: Create visits through automatic check-ins
        final checkIn1 = await checkInService.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        // Simulate dwell time
        await Future.delayed(const Duration(milliseconds: 100));
        await checkInService.checkOut(userId: 'user-1');

        final visit1 = await checkInService.getVisitById(checkIn1.visitId);
        expect(visit1, isNotNull);

        // Step 2: Calculate exploration expertise from visits
        final exploration = await multiPathService.calculateExplorationExpertise(
          userId: 'user-1',
          category: 'Coffee',
          visits: [visit1!],
        );

        expect(exploration.totalVisits, equals(1));
        expect(exploration.score, greaterThanOrEqualTo(0.0));

        // Step 3: Calculate saturation metrics
        final saturation = await saturationService.analyzeCategorySaturation(
          category: 'Coffee',
          currentExpertCount: 100,
          totalUserCount: 5000,
          qualityMetrics: const QualityMetrics(
            averageExpertRating: 4.5,
            averageEngagementRate: 0.8,
            verifiedExpertRatio: 0.9,
          ),
          utilizationMetrics: const UtilizationMetrics(
            totalExperts: 100,
            activeExperts: 80,
            totalEvents: 200,
            totalConsultations: 500,
          ),
          demandMetrics: const DemandMetrics(
            expertSearchQueries: 500,
            totalSearchQueries: 1000,
            consultationRequests: 200,
            totalUsers: 5000,
            averageWaitTimeDays: 2.0,
          ),
          growthMetrics: const GrowthMetrics(
            expertsPerMonth: 5,
            totalExperts: 100,
          ),
          geographicMetrics: const GeographicMetrics(
            totalExperts: 100,
            totalCities: 10,
            citiesWithExperts: 9,
          ),
        );

        expect(saturation.category, equals('Coffee'));
        expect(saturation.saturationScore, greaterThanOrEqualTo(0.0));

        // Step 4: Create expertise requirements
        final requirements = ExpertiseRequirements(
          category: 'Coffee',
          thresholdValues: const ThresholdValues(
            minVisits: 20,
            minRatings: 12,
            minAvgRating: 4.2,
            minTimeInCategory: Duration(days: 60),
            minCommunityEngagement: 8,
          ),
          multiPathRequirements: const MultiPathRequirements(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 5: Create platform phase
        final platformPhase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 10000,
          saturationFactors: SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        // Step 6: Calculate full expertise
        final pathScores = MultiPathExpertiseScores(
          exploration: exploration,
          credential: null,
          influence: null,
          professional: null,
          community: null,
          local: null,
        );

        final result = await calculationService.calculateExpertise(
          userId: 'user-1',
          category: 'Coffee',
          requirements: requirements,
          platformPhase: platformPhase,
          saturationMetrics: saturation,
          pathExpertise: pathScores,
        );

        expect(result.userId, equals('user-1'));
        expect(result.category, equals('Coffee'));
        expect(result.totalScore, greaterThanOrEqualTo(0.0));
        expect(result.totalScore, lessThanOrEqualTo(1.0));
        expect(result.expertiseLevel, isNotNull);
      });
    });

    group('Automatic Check-In to Expertise Flow', () {
      test('should track visit and contribute to expertise', () async {
        // Create multiple check-ins
        for (int i = 0; i < 5; i++) {
          await checkInService.handleGeofenceTrigger(
            userId: 'user-1',
            locationId: 'location-$i',
            latitude: 40.7128 + (i * 0.01),
            longitude: -74.0060 + (i * 0.01),
          );
        }

        // Check out all
        for (int i = 0; i < 5; i++) {
          try {
            await checkInService.checkOut(userId: 'user-1');
          } catch (e) {
            // Ignore if no active check-in
          }
        }

        // Get all visits
        final visits = await checkInService.getVisitsForUser('user-1');
        expect(visits.length, equals(5));

        // Calculate expertise from visits
        final exploration = await multiPathService.calculateExplorationExpertise(
          userId: 'user-1',
          category: 'Coffee',
          visits: visits,
        );

        expect(exploration.totalVisits, equals(5));
        expect(exploration.uniqueLocations, equals(5));
      });
    });

    group('Multi-Path Expertise Integration', () {
      test('should combine multiple paths into total score', () async {
        // Create expertise from multiple paths
        final exploration = await multiPathService.calculateExplorationExpertise(
          userId: 'user-1',
          category: 'Coffee',
          visits: [],
        );

        final credential = await multiPathService.calculateCredentialExpertise(
          userId: 'user-1',
          category: 'Coffee',
          degrees: [
            EducationCredential(
              degree: 'MS',
              field: 'Food Science',
              institution: 'University',
              year: 2020,
              isVerified: true,
            ),
          ],
          certifications: [],
        );

        final influence = await multiPathService.calculateInfluenceExpertise(
          userId: 'user-1',
          category: 'Coffee',
          spotsFollowers: 1000,
          listSaves: 500,
          listShares: 200,
          listEngagement: 1000,
          curatedLists: 10,
        );

        final pathScores = MultiPathExpertiseScores(
          exploration: exploration,
          credential: credential,
          influence: influence,
          professional: null,
          community: null,
          local: null,
        );

        // Calculate weighted total
        final totalScore = (exploration.score * 0.40) +
            (credential.score * 0.25) +
            (influence.score * 0.20);

        expect(totalScore, greaterThan(0.0));
        expect(totalScore, lessThanOrEqualTo(1.0));
      });
    });

    group('Saturation to Requirements Flow', () {
      test('should adjust requirements based on saturation', () async {
        // Low saturation
        final lowSaturation = await saturationService.analyzeCategorySaturation(
          category: 'Coffee',
          currentExpertCount: 20,
          totalUserCount: 5000,
          qualityMetrics: const QualityMetrics(
            averageExpertRating: 4.5,
            averageEngagementRate: 0.8,
            verifiedExpertRatio: 0.9,
          ),
          utilizationMetrics: const UtilizationMetrics(
            totalExperts: 20,
            activeExperts: 18,
            totalEvents: 50,
            totalConsultations: 100,
          ),
          demandMetrics: const DemandMetrics(
            expertSearchQueries: 500,
            totalSearchQueries: 1000,
            consultationRequests: 200,
            totalUsers: 5000,
            averageWaitTimeDays: 2.0,
          ),
          growthMetrics: const GrowthMetrics(
            expertsPerMonth: 2,
            totalExperts: 20,
          ),
          geographicMetrics: const GeographicMetrics(
            totalExperts: 20,
            totalCities: 10,
            citiesWithExperts: 8,
          ),
        );

        final lowMultiplier = saturationService.getSaturationMultiplier(lowSaturation);
        expect(lowMultiplier, equals(0.8)); // Reduced requirements

        // High saturation
        final highSaturation = await saturationService.analyzeCategorySaturation(
          category: 'Travel',
          currentExpertCount: 200,
          totalUserCount: 5000,
          qualityMetrics: const QualityMetrics(
            averageExpertRating: 3.8,
            averageEngagementRate: 0.5,
            verifiedExpertRatio: 0.6,
          ),
          utilizationMetrics: const UtilizationMetrics(
            totalExperts: 200,
            activeExperts: 100,
            totalEvents: 150,
            totalConsultations: 300,
          ),
          demandMetrics: const DemandMetrics(
            expertSearchQueries: 100,
            totalSearchQueries: 1000,
            consultationRequests: 50,
            totalUsers: 5000,
            averageWaitTimeDays: 15.0,
          ),
          growthMetrics: const GrowthMetrics(
            expertsPerMonth: 20,
            totalExperts: 200,
          ),
          geographicMetrics: const GeographicMetrics(
            totalExperts: 200,
            totalCities: 10,
            citiesWithExperts: 3,
          ),
        );

        final highMultiplier = saturationService.getSaturationMultiplier(highSaturation);
        expect(highMultiplier, equals(2.0)); // Increased requirements
      });
    });
  });
}

/// Multi-Path Expertise Scores
/// Container for all path expertise scores
class MultiPathExpertiseScores {
  final ExplorationExpertise? exploration;
  final CredentialExpertise? credential;
  final InfluenceExpertise? influence;
  final ProfessionalExpertise? professional;
  final CommunityExpertise? community;
  final LocalExpertise? local;

  const MultiPathExpertiseScores({
    this.exploration,
    this.credential,
    this.influence,
    this.professional,
    this.community,
    this.local,
  });
}

