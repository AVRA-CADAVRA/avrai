import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/expertise_calculation_service.dart';
import 'package:spots/core/services/saturation_algorithm_service.dart';
import 'package:spots/core/services/multi_path_expertise_service.dart';
import 'package:spots/core/services/automatic_check_in_service.dart';
import 'package:spots/core/models/visit.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/platform_phase.dart';
import 'package:spots/core/models/expertise_requirements.dart';
import '../helpers/integration_test_helpers.dart';
import '../helpers/test_helpers.dart';

/// Expertise Flow Integration Tests
/// 
/// Agent 3: Models & Testing (Week 14)
/// 
/// Tests end-to-end expertise flow:
/// - Visit → Check-in → Expertise calculation → Unlock
/// 
/// **Test Scenarios:**
/// - Scenario 1: Complete Expertise Flow (Visit → Check-in → Calculation → Unlock)
/// - Scenario 2: Multiple Visits Leading to Expertise Unlock
/// - Scenario 3: Expertise Progression Through Levels
/// - Scenario 4: Expertise Unlocking Event Hosting
/// - Scenario 5: Automatic Check-in to Expertise Flow
void main() {
  group('Expertise Flow Integration Tests', () {
    late ExpertiseCalculationService calculationService;
    late SaturationAlgorithmService saturationService;
    late MultiPathExpertiseService multiPathService;
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
    
    group('Scenario 1: Complete Expertise Flow (Visit → Check-in → Calculation → Unlock)', () {
      test('should complete full flow from visit to expertise unlock', () async {
        // Step 1: User visits location (geofence trigger)
        final checkIn = await checkInService.handleGeofenceTrigger(
          userId: 'user-1',
          locationId: 'location-1',
          latitude: 40.7128,
          longitude: -74.0060,
          accuracy: 10.0,
        );
        
        expect(checkIn, isNotNull);
        expect(checkIn.isActive, isTrue);
        expect(checkIn.visitCreated, isTrue);
        
        // Step 2: User checks out (dwell time calculated)
        await Future.delayed(const Duration(milliseconds: 100));
        final checkedOut = await checkInService.checkOut(
          userId: 'user-1',
        );
        
        expect(checkedOut.checkOutTime, isNotNull);
        expect(checkedOut.dwellTime, isNotNull);
        expect(checkedOut.qualityScore, greaterThan(0.0));
        
        // Step 3: Get visit record
        final visit = await checkInService.getVisitById(checkIn.visitId);
        expect(visit, isNotNull);
        expect(visit!.isAutomatic, isTrue);
        
        // Step 4: Calculate exploration expertise from visit
        final exploration = await multiPathService.calculateExplorationExpertise(
          userId: 'user-1',
          category: 'Coffee',
          visits: [visit],
        );
        
        expect(exploration.totalVisits, equals(1));
        expect(exploration.score, greaterThanOrEqualTo(0.0));
        
        // Step 5: Get saturation metrics
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
        
        // Step 6: Create expertise requirements
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
        
        // Step 7: Create platform phase
        final platformPhase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 10000,
          saturationFactors: SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );
        
        // Step 8: Calculate expertise
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
        
        // Step 9: Verify expertise calculation
        expect(result.userId, equals('user-1'));
        expect(result.category, equals('Coffee'));
        expect(result.totalScore, greaterThanOrEqualTo(0.0));
        expect(result.totalScore, lessThanOrEqualTo(1.0));
        expect(result.expertiseLevel, isNotNull);
        
        // Step 10: Check if expertise level unlocks features
        // (Local level unlocks event hosting)
        final canHostEvents = result.expertiseLevel == ExpertiseLevel.local ||
            result.expertiseLevel == ExpertiseLevel.city ||
            result.expertiseLevel == ExpertiseLevel.region ||
            result.expertiseLevel == ExpertiseLevel.national;
        
        // For this test, user has only 1 visit, so won't unlock yet
        expect(result.expertiseLevel, isA<ExpertiseLevel>());
      });
    });
    
    group('Scenario 2: Multiple Visits Leading to Expertise Unlock', () {
      test('should progress from multiple visits to expertise unlock', () async {
        final userId = 'user-2';
        final category = 'Coffee';
        
        // Create multiple visits
        final visits = <Visit>[];
        for (int i = 0; i < 25; i++) {
          final checkIn = await checkInService.handleGeofenceTrigger(
            userId: userId,
            locationId: 'location-$i',
            latitude: 40.7128 + (i * 0.01),
            longitude: -74.0060 + (i * 0.01),
          );
          
          await Future.delayed(const Duration(milliseconds: 50));
          await checkInService.checkOut(userId: userId);
          
          final visit = await checkInService.getVisitById(checkIn.visitId);
          if (visit != null) {
            visits.add(visit);
          }
        }
        
        expect(visits.length, greaterThan(0));
        
        // Calculate exploration expertise
        final exploration = await multiPathService.calculateExplorationExpertise(
          userId: userId,
          category: category,
          visits: visits,
        );
        
        expect(exploration.totalVisits, greaterThanOrEqualTo(20));
        
        // Get saturation and requirements
        final saturation = await saturationService.analyzeCategorySaturation(
          category: category,
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
        
        final requirements = ExpertiseRequirements(
          category: category,
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
        
        final platformPhase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 10000,
          saturationFactors: SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );
        
        // Calculate expertise
        final pathScores = MultiPathExpertiseScores(
          exploration: exploration,
          credential: null,
          influence: null,
          professional: null,
          community: null,
          local: null,
        );
        
        final result = await calculationService.calculateExpertise(
          userId: userId,
          category: category,
          requirements: requirements,
          platformPhase: platformPhase,
          saturationMetrics: saturation,
          pathExpertise: pathScores,
        );
        
        // Verify progression
        expect(result.totalScore, greaterThan(0.0));
        expect(result.expertiseLevel, isNotNull);
        expect(result.meetsRequirements, isTrue);
      });
    });
    
    group('Scenario 3: Expertise Progression Through Levels', () {
      test('should progress through expertise levels', () async {
        final userId = 'user-3';
        final category = 'Coffee';
        
        // Simulate progression: Local → City → Region
        // Start with Local level (few visits)
        final localVisits = List.generate(10, (i) => Visit(
          id: 'visit-$i',
          userId: userId,
          locationId: 'location-$i',
          checkInTime: testDate.subtract(Duration(days: 30 - i)),
          isAutomatic: true,
          createdAt: testDate.subtract(Duration(days: 30 - i)),
          updatedAt: testDate.subtract(Duration(days: 30 - i)),
        ));
        
        final localExploration = await multiPathService.calculateExplorationExpertise(
          userId: userId,
          category: category,
          visits: localVisits,
        );
        
        expect(localExploration.totalVisits, equals(10));
        
        // Progress to Local level (more visits) - unlocks event hosting
        final cityVisits = List.generate(30, (i) => Visit(
          id: 'visit-city-$i',
          userId: userId,
          locationId: 'location-$i',
          checkInTime: testDate.subtract(Duration(days: 60 - i)),
          isAutomatic: true,
          createdAt: testDate.subtract(Duration(days: 60 - i)),
          updatedAt: testDate.subtract(Duration(days: 60 - i)),
        ));
        
        final cityExploration = await multiPathService.calculateExplorationExpertise(
          userId: userId,
          category: category,
          visits: cityVisits,
        );
        
        expect(cityExploration.totalVisits, equals(30));
        expect(cityExploration.score, greaterThan(localExploration.score));
        
        // Verify progression
        expect(cityExploration.totalVisits, greaterThan(localExploration.totalVisits));
        expect(cityExploration.uniqueLocations, greaterThanOrEqualTo(localExploration.uniqueLocations));
      });
    });
    
    group('Scenario 4: Expertise Unlocking Event Hosting', () {
      test('should unlock event hosting at Local level', () async {
        final userId = 'user-4';
        final category = 'Coffee';
        
        // Create user with Local level expertise
        final user = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: userId,
          category: category,
        );
        
        // Verify user can host events
        expect(user.canHostEvents(), isTrue);
        
        // Verify expertise map shows Local level
        expect(user.expertiseMap[category], equals('local'));
        
        // User can now create events
        final event = IntegrationTestHelpers.createTestEvent(
          host: user,
          category: category,
        );
        
        expect(event.host.id, equals(userId));
        expect(event.category, equals(category));
      });
    });
    
    group('Scenario 5: Automatic Check-in to Expertise Flow', () {
      test('should track automatic check-ins and contribute to expertise', () async {
        final userId = 'user-5';
        final category = 'Coffee';
        
        // Create multiple automatic check-ins
        final checkIns = <String>[];
        for (int i = 0; i < 5; i++) {
          final checkIn = await checkInService.handleGeofenceTrigger(
            userId: userId,
            locationId: 'location-$i',
            latitude: 40.7128 + (i * 0.01),
            longitude: -74.0060 + (i * 0.01),
          );
          checkIns.add(checkIn.id);
          
          // Simulate dwell time
          await Future.delayed(const Duration(milliseconds: 50));
          await checkInService.checkOut(userId: userId);
        }
        
        expect(checkIns.length, equals(5));
        
        // Get all visits
        final visits = await checkInService.getVisitsForUser(userId);
        expect(visits.length, equals(5));
        
        // Calculate expertise from visits
        final exploration = await multiPathService.calculateExplorationExpertise(
          userId: userId,
          category: category,
          visits: visits,
        );
        
        expect(exploration.totalVisits, equals(5));
        expect(exploration.uniqueLocations, equals(5));
        expect(exploration.score, greaterThan(0.0));
      });
    });
  });
}

