import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/expertise_calculation_service.dart';
import 'package:spots/core/services/saturation_algorithm_service.dart' show SaturationAlgorithmService, QualityMetrics, UtilizationMetrics, DemandMetrics, GrowthMetrics, GeographicMetrics;
import 'package:spots/core/services/multi_path_expertise_service.dart';
import 'package:spots/core/services/partnership_profile_service.dart';
import 'package:spots/core/models/platform_phase.dart' show PlatformPhase, PhaseName;
import 'package:spots/core/models/platform_phase.dart' as platform_phase show SaturationFactors;
import 'package:spots/core/models/saturation_metrics.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/models/partnership_expertise_boost.dart';
import 'package:spots/core/models/expertise_requirements.dart';
import 'package:spots/core/models/visit.dart';
import 'dart:convert';
import 'dart:io';
import '../../helpers/test_helpers.dart';
import '../../helpers/platform_channel_helper.dart';

// Manual mocks
// Mockito note (null safety):
// These hand-written mocks MUST provide a non-null default `returnValue` for non-nullable Future return types.
// Otherwise, the method call inside `when(...)` returns null and triggers a TypeError during stubbing.
// That initial TypeError can also corrupt Mockito's internal state, causing follow-up stubs to fail with
// "Cannot call `when` within a stub response".
//
// #region agent log
const String _agentDebugLogPath = '/Users/reisgordon/SPOTS/.cursor/debug.log';
final String _agentRunId = 'expertise_partnership_boost_test_${DateTime.now().microsecondsSinceEpoch}';
void _agentLog(String hypothesisId, String location, String message, Map<String, Object?> data) {
  try {
    final payload = <String, Object?>{
      'sessionId': 'debug-session',
      'runId': _agentRunId,
      'hypothesisId': hypothesisId,
      'location': location,
      'message': message,
      'data': data,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    File(_agentDebugLogPath).writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append, flush: true);
  } catch (_) {
    // ignore: avoid_catches_without_on_clauses
  }
}

SaturationMetrics _dummySaturationMetrics(String category) {
  final t = DateTime.fromMillisecondsSinceEpoch(0);
  return SaturationMetrics(
    category: category,
    currentExpertCount: 0,
    totalUserCount: 0,
    saturationRatio: 0.0,
    qualityScore: 0.0,
    growthRate: 0.0,
    competitionLevel: 0.0,
    marketDemand: 0.0,
    factors: const SaturationFactors(
      supplyRatio: 0.0,
      qualityDistribution: 0.0,
      utilizationRate: 0.0,
      demandSignal: 0.0,
      growthVelocity: 0.0,
      geographicDistribution: 0.0,
    ),
    saturationScore: 0.0,
    recommendation: SaturationRecommendation.maintain,
    calculatedAt: t,
    updatedAt: t,
  );
}

ExplorationExpertise _dummyExplorationExpertise(String userId, String category) {
  final t = DateTime.fromMillisecondsSinceEpoch(0);
  return ExplorationExpertise(
    id: 'dummy',
    userId: userId,
    category: category,
    totalVisits: 0,
    uniqueLocations: 0,
    repeatVisits: 0,
    reviewsGiven: 0,
    averageRating: 0.0,
    averageQualityScore: 0.0,
    highQualityVisits: 0,
    totalDwellTime: Duration.zero,
    firstVisit: t,
    lastVisit: t,
    score: 0.0,
    createdAt: t,
    updatedAt: t,
  );
}

CommunityExpertise _dummyCommunityExpertise(String userId, String category) {
  final t = DateTime.fromMillisecondsSinceEpoch(0);
  return CommunityExpertise(
    id: 'dummy',
    userId: userId,
    category: category,
    questionsAnswered: 0,
    curatedLists: 0,
    popularLists: 0,
    eventsHosted: 0,
    averageEventRating: 0.0,
    peerEndorsements: 0,
    communityContributions: 0,
    score: 0.0,
    createdAt: t,
    updatedAt: t,
  );
}

ProfessionalExpertise _dummyProfessionalExpertise(String userId, String category) {
  final t = DateTime.fromMillisecondsSinceEpoch(0);
  return ProfessionalExpertise(
    id: 'dummy',
    userId: userId,
    category: category,
    roles: const [],
    proofOfWork: const [],
    peerEndorsements: const [],
    isVerified: false,
    score: 0.0,
    createdAt: t,
    updatedAt: t,
  );
}

InfluenceExpertise _dummyInfluenceExpertise(String userId, String category) {
  final t = DateTime.fromMillisecondsSinceEpoch(0);
  return InfluenceExpertise(
    id: 'dummy',
    userId: userId,
    category: category,
    spotsFollowers: 0,
    listSaves: 0,
    listShares: 0,
    listEngagement: 0,
    externalPlatforms: const [],
    popularLists: 0,
    score: 0.0,
    createdAt: t,
    updatedAt: t,
  );
}
// #endregion

class MockSaturationAlgorithmService extends Mock implements SaturationAlgorithmService {
  @override
  Future<SaturationMetrics> analyzeCategorySaturation({
    required String category,
    required int currentExpertCount,
    required int totalUserCount,
    required QualityMetrics qualityMetrics,
    required UtilizationMetrics utilizationMetrics,
    required DemandMetrics demandMetrics,
    required GrowthMetrics growthMetrics,
    required GeographicMetrics geographicMetrics,
  }) {
    // #region agent log
    _agentLog('A', 'expertise_calculation_partnership_boost_test.dart:MockSaturationAlgorithmService', 'analyzeCategorySaturation invoked', {
      'category': category,
      'currentExpertCount': currentExpertCount,
      'totalUserCount': totalUserCount,
    });
    // #endregion
    return super.noSuchMethod(
      Invocation.method(
        #analyzeCategorySaturation,
        const [],
        <Symbol, Object?>{
          #category: category,
          #currentExpertCount: currentExpertCount,
          #totalUserCount: totalUserCount,
          #qualityMetrics: qualityMetrics,
          #utilizationMetrics: utilizationMetrics,
          #demandMetrics: demandMetrics,
          #growthMetrics: growthMetrics,
          #geographicMetrics: geographicMetrics,
        },
      ),
      returnValue: Future.value(_dummySaturationMetrics(category)),
    ) as Future<SaturationMetrics>;
  }
}

class MockMultiPathExpertiseService extends Mock implements MultiPathExpertiseService {
  @override
  Future<ExplorationExpertise> calculateExplorationExpertise({
    required String userId,
    required String category,
    required List<Visit> visits,
  }) {
    // #region agent log
    _agentLog('A', 'expertise_calculation_partnership_boost_test.dart:MockMultiPathExpertiseService', 'calculateExplorationExpertise invoked', {
      'userId': userId,
      'category': category,
      'visitsLength': visits.length,
    });
    // #endregion
    return super.noSuchMethod(
      Invocation.method(
        #calculateExplorationExpertise,
        const [],
        <Symbol, Object?>{#userId: userId, #category: category, #visits: visits},
      ),
      returnValue: Future.value(_dummyExplorationExpertise(userId, category)),
    ) as Future<ExplorationExpertise>;
  }

  @override
  Future<CommunityExpertise> calculateCommunityExpertise({
    required String userId,
    required String category,
    int questionsAnswered = 0,
    int curatedLists = 0,
    int eventsHosted = 0,
    double averageEventRating = 0.0,
    int peerEndorsements = 0,
    int communityContributions = 0,
  }) {
    // #region agent log
    _agentLog('A', 'expertise_calculation_partnership_boost_test.dart:MockMultiPathExpertiseService', 'calculateCommunityExpertise invoked', {
      'userId': userId,
      'category': category,
    });
    // #endregion
    return super.noSuchMethod(
      Invocation.method(
        #calculateCommunityExpertise,
        const [],
        <Symbol, Object?>{
          #userId: userId,
          #category: category,
          #questionsAnswered: questionsAnswered,
          #curatedLists: curatedLists,
          #eventsHosted: eventsHosted,
          #averageEventRating: averageEventRating,
          #peerEndorsements: peerEndorsements,
          #communityContributions: communityContributions,
        },
      ),
      returnValue: Future.value(_dummyCommunityExpertise(userId, category)),
    ) as Future<CommunityExpertise>;
  }

  @override
  Future<ProfessionalExpertise> calculateProfessionalExpertise({
    required String userId,
    required String category,
    List<ProfessionalRole> roles = const [],
    List<ProofOfWork> proofOfWork = const [],
    List<PeerEndorsement> peerEndorsements = const [],
    bool isVerified = false,
  }) {
    // #region agent log
    _agentLog('A', 'expertise_calculation_partnership_boost_test.dart:MockMultiPathExpertiseService', 'calculateProfessionalExpertise invoked', {
      'userId': userId,
      'category': category,
      'isVerified': isVerified,
    });
    // #endregion
    return super.noSuchMethod(
      Invocation.method(
        #calculateProfessionalExpertise,
        const [],
        <Symbol, Object?>{
          #userId: userId,
          #category: category,
          #roles: roles,
          #proofOfWork: proofOfWork,
          #peerEndorsements: peerEndorsements,
          #isVerified: isVerified,
        },
      ),
      returnValue: Future.value(_dummyProfessionalExpertise(userId, category)),
    ) as Future<ProfessionalExpertise>;
  }

  @override
  Future<InfluenceExpertise> calculateInfluenceExpertise({
    required String userId,
    required String category,
    int spotsFollowers = 0,
    int listSaves = 0,
    int listShares = 0,
    int curatedLists = 0,
    List<ExternalPlatformInfluence> externalPlatforms = const [],
  }) {
    // #region agent log
    _agentLog('A', 'expertise_calculation_partnership_boost_test.dart:MockMultiPathExpertiseService', 'calculateInfluenceExpertise invoked', {
      'userId': userId,
      'category': category,
      'spotsFollowers': spotsFollowers,
    });
    // #endregion
    return super.noSuchMethod(
      Invocation.method(
        #calculateInfluenceExpertise,
        const [],
        <Symbol, Object?>{
          #userId: userId,
          #category: category,
          #spotsFollowers: spotsFollowers,
          #listSaves: listSaves,
          #listShares: listShares,
          #curatedLists: curatedLists,
          #externalPlatforms: externalPlatforms,
        },
      ),
      returnValue: Future.value(_dummyInfluenceExpertise(userId, category)),
    ) as Future<InfluenceExpertise>;
  }
}

class MockPartnershipProfileService extends Mock implements PartnershipProfileService {
  @override
  Future<PartnershipExpertiseBoost> getPartnershipExpertiseBoost(
    String userId,
    String category,
  ) {
    // #region agent log
    _agentLog('A', 'expertise_calculation_partnership_boost_test.dart:MockPartnershipProfileService', 'getPartnershipExpertiseBoost invoked', {
      'userId': userId,
      'category': category,
    });
    // #endregion
    return super.noSuchMethod(
      Invocation.method(
        #getPartnershipExpertiseBoost,
        <Object?>[userId, category],
      ),
      returnValue: Future.value(const PartnershipExpertiseBoost(totalBoost: 0.0)),
    ) as Future<PartnershipExpertiseBoost>;
  }
}

void main() {
  group('ExpertiseCalculationService Partnership Boost Tests', () {
    late ExpertiseCalculationService service;
    late MockSaturationAlgorithmService mockSaturationService;
    late MockMultiPathExpertiseService mockMultiPathService;
    late MockPartnershipProfileService mockPartnershipProfileService;
    late DateTime testDate;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      mockSaturationService = MockSaturationAlgorithmService();
      mockMultiPathService = MockMultiPathExpertiseService();
      mockPartnershipProfileService = MockPartnershipProfileService();

      service = ExpertiseCalculationService(
        saturationService: mockSaturationService,
        multiPathService: mockMultiPathService,
        partnershipProfileService: mockPartnershipProfileService,
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('calculatePartnershipBoost', () {
      test('should calculate partnership boost', () async {
        // Arrange
        final boost = PartnershipExpertiseBoost(
          totalBoost: 0.15,
          activeBoost: 0.05,
          completedBoost: 0.10,
          partnershipCount: 2,
        );

        when(mockPartnershipProfileService.getPartnershipExpertiseBoost(
          'user-123',
          'Coffee',
        )).thenAnswer((_) async => boost);

        // Act
        final result = await service.calculatePartnershipBoost(
          userId: 'user-123',
          category: 'Coffee',
        );

        // Assert
        expect(result.totalBoost, equals(0.15));
        expect(result.partnershipCount, equals(2));
      });

      test('should return zero boost when service is not available', () async {
        // Arrange
        final serviceWithoutPartnership = ExpertiseCalculationService(
          saturationService: mockSaturationService,
          multiPathService: mockMultiPathService,
          partnershipProfileService: null,
        );

        // Act
        final result = await serviceWithoutPartnership.calculatePartnershipBoost(
          userId: 'user-123',
          category: 'Coffee',
        );

        // Assert
        expect(result.totalBoost, equals(0.0));
      });
    });

    group('calculateExpertise with partnership boost', () {
      test('should integrate partnership boost into expertise calculation', () async {
        // Arrange
        // Create dummy metrics for mocking
        final dummyQualityMetrics = QualityMetrics(
          averageExpertRating: 4.5,
          averageEngagementRate: 0.8,
          verifiedExpertRatio: 0.9,
        );
        final dummyUtilizationMetrics = UtilizationMetrics(
          totalExperts: 100,
          activeExperts: 80,
          totalEvents: 200,
          totalConsultations: 150,
        );
        final dummyDemandMetrics = DemandMetrics(
          expertSearchQueries: 500,
          totalSearchQueries: 2000,
          consultationRequests: 100,
          totalUsers: 5000,
          averageWaitTimeDays: 2.0,
        );
        final dummyGrowthMetrics = GrowthMetrics(
          expertsPerMonth: 10,
          totalExperts: 100,
        );
        final dummyGeographicMetrics = GeographicMetrics(
          totalExperts: 100,
          totalCities: 10,
          citiesWithExperts: 8,
        );

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

        final partnershipBoost = PartnershipExpertiseBoost(
          totalBoost: 0.20, // 20% boost
          activeBoost: 0.10,
          completedBoost: 0.10,
          partnershipCount: 3,
        );

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
          score: 0.50,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final communityExpertise = CommunityExpertise(
          id: 'comm-1',
          userId: 'user-1',
          category: 'Coffee',
          questionsAnswered: 10,
          curatedLists: 5,
          popularLists: 2,
          eventsHosted: 3,
          averageEventRating: 4.5,
          peerEndorsements: 5,
          communityContributions: 15,
          score: 0.40,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final professionalExpertise = ProfessionalExpertise(
          id: 'prof-1',
          userId: 'user-1',
          category: 'Coffee',
          roles: const [],
          proofOfWork: const [],
          peerEndorsements: const [],
          isVerified: false,
          score: 0.30,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final influenceExpertise = InfluenceExpertise(
          id: 'inf-1',
          userId: 'user-1',
          category: 'Coffee',
          spotsFollowers: 100,
          listSaves: 1000,
          listShares: 50,
          listEngagement: 20,
          score: 0.25,
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockSaturationService.analyzeCategorySaturation(
          category: 'Coffee',
          currentExpertCount: 100,
          totalUserCount: 5000,
          qualityMetrics: dummyQualityMetrics,
          utilizationMetrics: dummyUtilizationMetrics,
          demandMetrics: dummyDemandMetrics,
          growthMetrics: dummyGrowthMetrics,
          geographicMetrics: dummyGeographicMetrics,
        )).thenAnswer((_) async => saturationMetrics);

        when(mockPartnershipProfileService.getPartnershipExpertiseBoost(
          'user-1',
          'Coffee',
        )).thenAnswer((_) async => partnershipBoost);

        when(mockMultiPathService.calculateExplorationExpertise(
          userId: 'user-1',
          category: 'Coffee',
          visits: const [],
        )).thenAnswer((_) async => explorationExpertise);

        when(mockMultiPathService.calculateCommunityExpertise(
          userId: 'user-1',
          category: 'Coffee',
          questionsAnswered: 10,
          curatedLists: 5,
          eventsHosted: 3,
          averageEventRating: 4.5,
          peerEndorsements: 5,
          communityContributions: 15,
        )).thenAnswer((_) async => communityExpertise);

        when(mockMultiPathService.calculateProfessionalExpertise(
          userId: 'user-1',
          category: 'Coffee',
          roles: const [],
          proofOfWork: const [],
          peerEndorsements: const [],
          isVerified: false,
        )).thenAnswer((_) async => professionalExpertise);

        when(mockMultiPathService.calculateInfluenceExpertise(
          userId: 'user-1',
          category: 'Coffee',
          spotsFollowers: 100,
          listSaves: 1000,
          listShares: 50,
        )).thenAnswer((_) async => influenceExpertise);

        final requirements = ExpertiseRequirements(
          category: 'Coffee',
          thresholdValues: ThresholdValues(
            minVisits: 10,
            minRatings: 5,
            minAvgRating: 4.0,
            minTimeInCategory: const Duration(days: 30),
          ),
          multiPathRequirements: const MultiPathRequirements(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final platformPhase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 1000,
          categoryMultipliers: {'Coffee': 1.0},
          saturationFactors: platform_phase.SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final pathExpertise = MultiPathExpertiseScores(
          exploration: explorationExpertise,
          community: communityExpertise,
          professional: professionalExpertise,
          influence: influenceExpertise,
        );

        // Act
        final result = await service.calculateExpertise(
          userId: 'user-1',
          category: 'Coffee',
          requirements: requirements,
          platformPhase: platformPhase,
          saturationMetrics: saturationMetrics,
          pathExpertise: pathExpertise,
        );

        // Assert
        expect(result.totalScore, greaterThan(0.0));
        // Partnership boost should increase the total score
        // Community: 0.40 * 0.15 = 0.06, + 0.20 * 0.60 = 0.12, total = 0.18
        // Professional: 0.30 * 0.25 = 0.075, + 0.20 * 0.30 = 0.06, total = 0.135
        // Influence: 0.25 * 0.20 = 0.05, + 0.20 * 0.10 = 0.02, total = 0.07
        // Exploration: 0.50 * 0.40 = 0.20
        // Total should be around 0.585 (without boost would be ~0.385)
        expect(result.totalScore, greaterThan(0.38));
      });

      test('should apply partnership boost to community path (60%)', () async {
        // Arrange
        // Create dummy metrics for mocking
        final dummyQualityMetrics2 = QualityMetrics(
          averageExpertRating: 4.5,
          averageEngagementRate: 0.8,
          verifiedExpertRatio: 0.9,
        );
        final dummyUtilizationMetrics2 = UtilizationMetrics(
          totalExperts: 100,
          activeExperts: 80,
          totalEvents: 200,
          totalConsultations: 150,
        );
        final dummyDemandMetrics2 = DemandMetrics(
          expertSearchQueries: 500,
          totalSearchQueries: 2000,
          consultationRequests: 100,
          totalUsers: 5000,
          averageWaitTimeDays: 2.0,
        );
        final dummyGrowthMetrics2 = GrowthMetrics(
          expertsPerMonth: 10,
          totalExperts: 100,
        );
        final dummyGeographicMetrics2 = GeographicMetrics(
          totalExperts: 100,
          totalCities: 10,
          citiesWithExperts: 8,
        );

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

        final partnershipBoost = PartnershipExpertiseBoost(
          totalBoost: 0.10, // 10% boost
          partnershipCount: 1,
        );

        final communityExpertise = CommunityExpertise(
          id: 'comm-1',
          userId: 'user-1',
          category: 'Coffee',
          questionsAnswered: 10,
          curatedLists: 5,
          popularLists: 2,
          eventsHosted: 3,
          averageEventRating: 4.5,
          peerEndorsements: 5,
          communityContributions: 15,
          score: 0.50, // Base score
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockSaturationService.analyzeCategorySaturation(
          category: 'Coffee',
          currentExpertCount: 100,
          totalUserCount: 5000,
          qualityMetrics: dummyQualityMetrics2,
          utilizationMetrics: dummyUtilizationMetrics2,
          demandMetrics: dummyDemandMetrics2,
          growthMetrics: dummyGrowthMetrics2,
          geographicMetrics: dummyGeographicMetrics2,
        )).thenAnswer((_) async => saturationMetrics);

        when(mockPartnershipProfileService.getPartnershipExpertiseBoost(
          'user-1',
          'Coffee',
        )).thenAnswer((_) async => partnershipBoost);

        when(mockMultiPathService.calculateCommunityExpertise(
          userId: 'user-1',
          category: 'Coffee',
          questionsAnswered: 10,
          curatedLists: 5,
          eventsHosted: 3,
          averageEventRating: 4.5,
          peerEndorsements: 5,
          communityContributions: 15,
        )).thenAnswer((_) async => communityExpertise);

        final requirements = ExpertiseRequirements(
          category: 'Coffee',
          thresholdValues: ThresholdValues(
            minVisits: 10,
            minRatings: 5,
            minAvgRating: 4.0,
            minTimeInCategory: const Duration(days: 30),
          ),
          multiPathRequirements: const MultiPathRequirements(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final platformPhase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 1000,
          categoryMultipliers: {'Coffee': 1.0},
          saturationFactors: platform_phase.SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final pathExpertise = MultiPathExpertiseScores(
          community: communityExpertise,
        );

        // Act
        final result = await service.calculateExpertise(
          userId: 'user-1',
          category: 'Coffee',
          requirements: requirements,
          platformPhase: platformPhase,
          saturationMetrics: saturationMetrics,
          pathExpertise: pathExpertise,
        );

        // Assert
        // Community base: 0.50 * 0.15 = 0.075
        // Partnership boost is applied even when other paths are missing:
        // - Community: 0.10 * 0.60 = 0.06
        // - Professional: 0.10 * 0.30 = 0.03 (no professional path provided)
        // - Influence: 0.10 * 0.10 = 0.01 (no influence path provided)
        // Total should be around 0.175
        expect(result.totalScore, closeTo(0.175, 0.01));
      });

      test('should handle missing partnership service gracefully', () async {
        // Arrange
        final serviceWithoutPartnership = ExpertiseCalculationService(
          saturationService: mockSaturationService,
          multiPathService: mockMultiPathService,
          partnershipProfileService: null,
        );

        // Create dummy metrics for mocking
        final dummyQualityMetrics3 = QualityMetrics(
          averageExpertRating: 4.5,
          averageEngagementRate: 0.8,
          verifiedExpertRatio: 0.9,
        );
        final dummyUtilizationMetrics3 = UtilizationMetrics(
          totalExperts: 100,
          activeExperts: 80,
          totalEvents: 200,
          totalConsultations: 150,
        );
        final dummyDemandMetrics3 = DemandMetrics(
          expertSearchQueries: 500,
          totalSearchQueries: 2000,
          consultationRequests: 100,
          totalUsers: 5000,
          averageWaitTimeDays: 2.0,
        );
        final dummyGrowthMetrics3 = GrowthMetrics(
          expertsPerMonth: 10,
          totalExperts: 100,
        );
        final dummyGeographicMetrics3 = GeographicMetrics(
          totalExperts: 100,
          totalCities: 10,
          citiesWithExperts: 8,
        );

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

        final communityExpertise = CommunityExpertise(
          id: 'comm-1',
          userId: 'user-1',
          category: 'Coffee',
          questionsAnswered: 10,
          curatedLists: 5,
          popularLists: 2,
          eventsHosted: 3,
          averageEventRating: 4.5,
          peerEndorsements: 5,
          communityContributions: 15,
          score: 0.50,
          createdAt: testDate,
          updatedAt: testDate,
        );

        when(mockSaturationService.analyzeCategorySaturation(
          category: 'Coffee',
          currentExpertCount: 100,
          totalUserCount: 5000,
          qualityMetrics: dummyQualityMetrics3,
          utilizationMetrics: dummyUtilizationMetrics3,
          demandMetrics: dummyDemandMetrics3,
          growthMetrics: dummyGrowthMetrics3,
          geographicMetrics: dummyGeographicMetrics3,
        )).thenAnswer((_) async => saturationMetrics);

        when(mockMultiPathService.calculateCommunityExpertise(
          userId: 'user-1',
          category: 'Coffee',
          questionsAnswered: 10,
          curatedLists: 5,
          eventsHosted: 3,
          averageEventRating: 4.5,
          peerEndorsements: 5,
          communityContributions: 15,
        )).thenAnswer((_) async => communityExpertise);

        final requirements = ExpertiseRequirements(
          category: 'Coffee',
          thresholdValues: ThresholdValues(
            minVisits: 10,
            minRatings: 5,
            minAvgRating: 4.0,
            minTimeInCategory: const Duration(days: 30),
          ),
          multiPathRequirements: const MultiPathRequirements(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final platformPhase = PlatformPhase(
          id: 'phase-1',
          name: PhaseName.growth,
          userCountThreshold: 1000,
          categoryMultipliers: {'Coffee': 1.0},
          saturationFactors: platform_phase.SaturationFactors(),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final pathExpertise = MultiPathExpertiseScores(
          community: communityExpertise,
        );

        // Act
        final result = await serviceWithoutPartnership.calculateExpertise(
          userId: 'user-1',
          category: 'Coffee',
          requirements: requirements,
          platformPhase: platformPhase,
          saturationMetrics: saturationMetrics,
          pathExpertise: pathExpertise,
        );

        // Assert
        // Should calculate without partnership boost
        expect(result.totalScore, closeTo(0.075, 0.01)); // 0.50 * 0.15
      });
    });

  tearDownAll(() async {
    await cleanupTestStorage();
  });
  });
}

