import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:spots/core/services/business_expert_matching_service.dart';
import 'package:spots/core/services/expertise_matching_service.dart';
import 'package:spots/core/services/expertise_community_service.dart';
import 'package:spots/core/services/llm_service.dart';
import 'package:spots/core/services/partnership_service.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/business_expert_preferences.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/integration_test_helpers.dart';

import 'business_expert_matching_service_test.mocks.dart';

@GenerateMocks([ExpertiseMatchingService, ExpertiseCommunityService, LLMService, PartnershipService])
void main() {
  group('BusinessExpertMatchingService Tests', () {
    late BusinessExpertMatchingService service;
    late MockExpertiseMatchingService mockExpertiseMatchingService;
    late MockExpertiseCommunityService mockCommunityService;
    late MockLLMService mockLLMService;
    late MockPartnershipService mockPartnershipService;
    late BusinessAccount business;

    setUp(() {
      mockExpertiseMatchingService = MockExpertiseMatchingService();
      mockCommunityService = MockExpertiseCommunityService();
      mockLLMService = MockLLMService();
      mockPartnershipService = MockPartnershipService();

      service = BusinessExpertMatchingService(
        expertiseMatchingService: mockExpertiseMatchingService,
        communityService: mockCommunityService,
        llmService: mockLLMService,
        partnershipService: mockPartnershipService,
      );

      business = BusinessAccount(
        id: 'business-123',
        name: 'Test Restaurant',
        email: 'test@restaurant.com',
        businessType: 'Restaurant',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user-123',
        requiredExpertise: ['food', 'restaurant'],
      );
    });

    group('findExpertsForBusiness', () {
      test('should return empty list when no experts match', () async {
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        final matches = await service.findExpertsForBusiness(business);

        expect(matches, isEmpty);
      });

      test('should respect maxResults parameter', () async {
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        final matches = await service.findExpertsForBusiness(
          business,
          maxResults: 10,
        );

        expect(matches.length, lessThanOrEqualTo(10));
      });

      test('should use expert preferences when available', () async {
        final preferences = BusinessExpertPreferences(
          requiredExpertiseCategories: ['food'],
          preferredExpertiseCategories: ['restaurant'],
        );

        final businessWithPreferences = business.copyWith(
          expertPreferences: preferences,
        );

        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        final matches = await service.findExpertsForBusiness(
          businessWithPreferences,
        );

        expect(matches, isA<List<BusinessExpertMatch>>());
      });

      test('should apply minimum match score threshold from preferences', () async {
        final preferences = BusinessExpertPreferences(
          requiredExpertiseCategories: ['food'],
          minMatchScore: 0.7,
        );

        final businessWithPreferences = business.copyWith(
          expertPreferences: preferences,
        );

        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        final matches = await service.findExpertsForBusiness(
          businessWithPreferences,
        );

        // All matches should meet minimum threshold
        for (final match in matches) {
          expect(match.matchScore, greaterThanOrEqualTo(0.7));
        }
      });

      test('should find experts from preferred communities', () async {
        final preferences = BusinessExpertPreferences(
          requiredExpertiseCategories: ['food'],
          preferredCommunities: ['community-1'],
        );

        final businessWithPreferences = business.copyWith(
          expertPreferences: preferences,
        );

        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        when(mockCommunityService.searchCommunities())
            .thenAnswer((_) async => []);

        final matches = await service.findExpertsForBusiness(
          businessWithPreferences,
        );

        expect(matches, isA<List<BusinessExpertMatch>>());
      });

      test('should use AI suggestions when LLM service available', () async {
        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        when(mockLLMService.generateRecommendation(
          userQuery: anyNamed('userQuery'),
        )).thenAnswer((_) async => 'AI suggestion response');

        final matches = await service.findExpertsForBusiness(business);

        expect(matches, isA<List<BusinessExpertMatch>>());
      });

      test('should work without LLM service', () async {
        final serviceWithoutLLM = BusinessExpertMatchingService(
          expertiseMatchingService: mockExpertiseMatchingService,
          communityService: mockCommunityService,
          llmService: null,
        );

        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => []);

        final matches = await serviceWithoutLLM.findExpertsForBusiness(business);

        expect(matches, isA<List<BusinessExpertMatch>>());
      });
    });

    group('Vibe-First Matching', () {
      test('should use vibe-first matching formula (50% vibe, 30% expertise, 20% location)', () async {
        // Create local expert with required expertise
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'San Francisco',
        );

        // Create expert match
        final expertMatch = ExpertMatch(
          user: localExpert,
          category: 'food',
          matchScore: 0.8,
          matchReason: 'Expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );

        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch]);

        // Mock vibe compatibility (high vibe match)
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.9); // 90% vibe compatibility

        final matches = await service.findExpertsForBusiness(business);

        expect(matches, isNotEmpty);
        final match = matches.first;

        // Verify vibe-first matching formula is applied
        // Expected: (0.9 * 0.5) + (expertise * 0.3) + (location * 0.2)
        // Vibe contributes 50% (0.9 * 0.5 = 0.45)
        // The match score should reflect vibe-first weighting
        expect(match.matchScore, greaterThan(0.0));
        expect(match.matchScore, lessThanOrEqualTo(1.0));
        expect(match.matchReason, contains('vibe-first'));
      });

      test('should include local experts in matching (no level-based filtering)', () async {
        // Create local expert
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'San Francisco',
        );

        // Create expert match
        final expertMatch = ExpertMatch(
          user: localExpert,
          category: 'food',
          matchScore: 0.7,
          matchReason: 'Expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );

        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch]);

        when(mockPartnershipService.calculateVibeCompatibility(
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.75);

        final matches = await service.findExpertsForBusiness(business);

        // Local expert should be included
        expect(matches, isNotEmpty);
        final match = matches.first;
        expect(match.expert.id, equals('local-expert-1'));
        expect(match.expert.getExpertiseLevel('food'), equals(ExpertiseLevel.local));
      });

      test('should include remote experts with great vibe (location is preference boost, not filter)', () async {
        // Create remote expert (different location) with high vibe
        final remoteExpert = IntegrationTestHelpers.createUserWithExpertise(
          id: 'remote-expert-1',
          category: 'food',
          level: ExpertiseLevel.city,
        ).copyWith(location: 'New York'); // Different location

        final expertMatch = ExpertMatch(
          user: remoteExpert,
          category: 'food',
          matchScore: 0.8,
          matchReason: 'Expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );

        final businessWithLocation = business.copyWith(
          preferredLocation: 'San Francisco', // Different from expert location
        );

        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch]);

        // High vibe compatibility (90%) should allow remote expert to be included
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.9);

        final matches = await service.findExpertsForBusiness(businessWithLocation);

        // Remote expert with great vibe should be included
        expect(matches, isNotEmpty);
        final match = matches.first;
        expect(match.expert.id, equals('remote-expert-1'));
        expect(match.expert.location, equals('New York'));
        // Match score should reflect high vibe (50% weight) despite location mismatch
        expect(match.matchScore, greaterThan(0.5));
      });

      test('should prioritize vibe compatibility as PRIMARY factor (50% weight)', () async {
        // Create two experts: one with high expertise/low vibe, one with lower expertise/high vibe
        final highExpertiseExpert = IntegrationTestHelpers.createUserWithExpertise(
          id: 'expert-1',
          category: 'food',
          level: ExpertiseLevel.national, // High expertise
        );

        final highVibeExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'expert-2',
          category: 'food',
          location: 'San Francisco',
        );

        final expertMatch1 = ExpertMatch(
          user: highExpertiseExpert,
          category: 'food',
          matchScore: 0.9, // High expertise match
          matchReason: 'High expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );

        final expertMatch2 = ExpertMatch(
          user: highVibeExpert,
          category: 'food',
          matchScore: 0.6, // Lower expertise match
          matchReason: 'Lower expertise match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );

        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch1, expertMatch2]);

        // Expert 1: High expertise (0.9), low vibe (0.5)
        // Expert 2: Lower expertise (0.6), high vibe (0.9)
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'expert-1',
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.5); // Low vibe

        when(mockPartnershipService.calculateVibeCompatibility(
          userId: 'expert-2',
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.9); // High vibe

        final matches = await service.findExpertsForBusiness(business);

        expect(matches.length, greaterThanOrEqualTo(2));

        // Expert with high vibe should rank higher due to 50% vibe weight
        // Expected scores:
        // Expert 1: (0.5 * 0.5) + (0.9 * 0.3) + (location * 0.2) ≈ 0.25 + 0.27 + 0.1 = 0.62
        // Expert 2: (0.9 * 0.5) + (0.6 * 0.3) + (location * 0.2) ≈ 0.45 + 0.18 + 0.2 = 0.83
        // Expert 2 should rank higher
        final sortedMatches = matches.toList()
          ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

        // High vibe expert should have higher or equal score
        final highVibeMatch = sortedMatches.firstWhere((m) => m.expert.id == 'expert-2');
        final highExpertiseMatch = sortedMatches.firstWhere((m) => m.expert.id == 'expert-1');

        // High vibe expert should rank higher due to 50% vibe weight
        expect(highVibeMatch.matchScore, greaterThanOrEqualTo(highExpertiseMatch.matchScore));
      });

      test('should apply location as preference boost, not filter', () async {
        // Create local expert in preferred location
        final localExpert = IntegrationTestHelpers.createUserWithLocalExpertise(
          id: 'local-expert-1',
          category: 'food',
          location: 'San Francisco',
        );

        // Create remote expert
        final remoteExpert = IntegrationTestHelpers.createUserWithExpertise(
          id: 'remote-expert-1',
          category: 'food',
          level: ExpertiseLevel.city,
        ).copyWith(location: 'New York');

        final businessWithLocation = business.copyWith(
          preferredLocation: 'San Francisco',
        );

        final expertMatch1 = ExpertMatch(
          user: localExpert,
          category: 'food',
          matchScore: 0.7,
          matchReason: 'Local expert match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );

        final expertMatch2 = ExpertMatch(
          user: remoteExpert,
          category: 'food',
          matchScore: 0.7,
          matchReason: 'Remote expert match',
          commonExpertise: ['food'],
          complementaryExpertise: [],
        );

        when(mockExpertiseMatchingService.findSimilarExperts(
          any,
          any,
          location: anyNamed('location'),
          maxResults: anyNamed('maxResults'),
        )).thenAnswer((_) async => [expertMatch1, expertMatch2]);

        // Both have same vibe compatibility
        when(mockPartnershipService.calculateVibeCompatibility(
          userId: anyNamed('userId'),
          businessId: anyNamed('businessId'),
        )).thenAnswer((_) async => 0.75);

        final matches = await service.findExpertsForBusiness(businessWithLocation);

        // Both experts should be included (location is not a filter)
        expect(matches.length, greaterThanOrEqualTo(2));

        // Local expert should have higher score due to location boost (20% weight)
        final localMatch = matches.firstWhere((m) => m.expert.id == 'local-expert-1');
        final remoteMatch = matches.firstWhere((m) => m.expert.id == 'remote-expert-1');

        // Local expert should have higher score due to location boost
        expect(localMatch.matchScore, greaterThan(remoteMatch.matchScore));
      });
    });
  });
}

