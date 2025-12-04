import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/community_event_upgrade_service.dart';
import 'package:spots/core/services/community_event_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_event.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Manual mocks for services
class MockCommunityEventService extends Mock implements CommunityEventService {}
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

/// Comprehensive tests for CommunityEventUpgradeService
/// Tests upgrade criteria evaluation, eligibility calculation, and upgrade flow
/// 
/// **Philosophy Alignment:**
/// - Opens doors for community events to upgrade to expert events
/// - Rewards successful community building
/// - Creates natural progression path
void main() {
  group('CommunityEventUpgradeService Tests', () {
    late CommunityEventUpgradeService service;
    late MockCommunityEventService mockCommunityEventService;
    late MockExpertiseEventService mockExpertiseEventService;
    late UnifiedUser host;
    late CommunityEvent event;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      mockCommunityEventService = MockCommunityEventService();
      mockExpertiseEventService = MockExpertiseEventService();

      service = CommunityEventUpgradeService(
        communityEventService: mockCommunityEventService,
        expertiseEventService: mockExpertiseEventService,
      );

      // Create host
      host = ModelFactories.createTestUser(
        id: 'host-1',
      ).copyWith(
        location: 'Mission District, San Francisco',
      );

      // Create test event
      event = CommunityEvent(
        id: 'event-1',
        title: 'Community Event',
        description: 'Test event',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: DateTime.now().add(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Upgrade Criteria Evaluation', () {
      test('should evaluate frequency hosting criteria', () async {
        // Host has hosted 5 events in last 3 months
        final eventWithTimesHosted = event.copyWith(timesHosted: 5);
        final criteria = await service.getUpgradeCriteria(eventWithTimesHosted);

        expect(criteria, isNotEmpty);
        expect(criteria.any((c) => c.contains('Frequency hosting')), isTrue);
      });

      test('should evaluate strong following criteria (active returns)', () async {
        // Event has repeat attendees
        final eventWithReturns = event.copyWith(
          attendeeIds: ['user-1', 'user-2', 'user-3', 'user-1', 'user-2'], // user-1 and user-2 returned
          attendeeCount: 5,
          repeatAttendeesCount: 2,
        );

        final criteria = await service.getUpgradeCriteria(eventWithReturns);

        expect(criteria, isNotEmpty);
        expect(criteria.any((c) => c.contains('Active returns')), isTrue);
      });

      test('should evaluate strong following criteria (growth in size)', () async {
        // Event attendance is growing
        final eventWithGrowth = event.copyWith(
          attendeeCount: 20,
          growthMetrics: 0.25, // 25% growth
        );

        final criteria = await service.getUpgradeCriteria(eventWithGrowth);

        expect(criteria, isNotEmpty);
        expect(criteria.any((c) => c.contains('Growth in size')), isTrue);
      });

      test('should evaluate strong following criteria (diversity)', () async {
        // Event has diverse attendee base
        final eventWithDiversity = event.copyWith(
          diversityMetrics: 0.75, // High diversity
        );

        final criteria = await service.getUpgradeCriteria(eventWithDiversity);

        expect(criteria, isNotEmpty);
        expect(criteria.any((c) => c.contains('Diversity')), isTrue);
      });

      test('should evaluate user interaction patterns (high engagement)', () async {
        // Event has high engagement
        final eventWithEngagement = event.copyWith(
          engagementScore: 0.85, // High engagement
        );

        final criteria = await service.getUpgradeCriteria(eventWithEngagement);

        expect(criteria, isNotEmpty);
        expect(criteria.any((c) => c.contains('High engagement')), isTrue);
      });

      test('should evaluate user interaction patterns (positive feedback)', () async {
        // Event has positive feedback/ratings
        final eventWithFeedback = event.copyWith(
          averageRating: 4.5, // High rating
        );

        final criteria = await service.getUpgradeCriteria(eventWithFeedback);

        expect(criteria, isNotEmpty);
        expect(criteria.any((c) => c.contains('Positive feedback')), isTrue);
      });

      test('should evaluate community building indicators', () async {
        // Event shows community building
        final eventWithCommunity = event.copyWith(
          attendeeCount: 30,
          engagementScore: 0.80,
          diversityMetrics: 0.70,
          communityBuildingIndicators: ['community_formed'],
        );

        final criteria = await service.getUpgradeCriteria(eventWithCommunity);

        expect(criteria, isNotEmpty);
        expect(criteria.any((c) => c.contains('Community building')), isTrue);
      });
    });

    group('Upgrade Eligibility Calculation', () {
      test('should check if event is eligible for upgrade', () async {
        final eligibleEvent = event.copyWith(
          attendeeCount: 25,
          engagementScore: 0.80,
          growthMetrics: 0.20,
          diversityMetrics: 0.70,
          timesHosted: 5,
        );

        final isEligible = await service.checkUpgradeEligibility(eligibleEvent);

        expect(isEligible, isTrue);
      });

      test('should return false when event is not eligible', () async {
        final ineligibleEvent = event.copyWith(
          attendeeCount: 5,
          engagementScore: 0.30,
          growthMetrics: 0.0,
          diversityMetrics: 0.20,
          timesHosted: 1,
        );

        final isEligible = await service.checkUpgradeEligibility(ineligibleEvent);

        expect(isEligible, isFalse);
      });

      test('should calculate upgrade eligibility score', () async {
        final eventWithMetrics = event.copyWith(
          attendeeCount: 20,
          engagementScore: 0.75,
          growthMetrics: 0.15,
          diversityMetrics: 0.65,
          timesHosted: 4,
        );

        final score = await service.calculateUpgradeScore(eventWithMetrics);

        expect(score, greaterThanOrEqualTo(0.0));
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('should return score 0.0 for ineligible events', () async {
        final ineligibleEvent = event.copyWith(
          attendeeCount: 2,
          engagementScore: 0.10,
          timesHosted: 1,
        );

        final score = await service.calculateUpgradeScore(ineligibleEvent);

        expect(score, equals(0.0));
      });

      test('should return score 1.0 for highly eligible events', () async {
        final highlyEligibleEvent = event.copyWith(
          attendeeCount: 50,
          engagementScore: 0.95,
          growthMetrics: 0.50,
          diversityMetrics: 0.90,
          averageRating: 4.9,
          timesHosted: 10,
        );

        final score = await service.calculateUpgradeScore(highlyEligibleEvent);

        expect(score, greaterThanOrEqualTo(0.8));
        expect(score, lessThanOrEqualTo(1.0));
      });

      test('should get which criteria are met', () async {
        final eventWithCriteria = event.copyWith(
          attendeeCount: 25,
          engagementScore: 0.80,
          growthMetrics: 0.20,
          timesHosted: 5,
        );

        final criteria = await service.getUpgradeCriteria(eventWithCriteria);

        expect(criteria, isA<List<String>>());
        expect(criteria.length, greaterThan(0));
      });
    });

    group('Upgrade Flow', () {
      ExpertiseEvent _createMockExpertiseEvent(CommunityEvent sourceEvent, UnifiedUser sourceHost) {
        return ExpertiseEvent(
          id: 'expert-event-1',
          title: sourceEvent.title,
          description: sourceEvent.description,
          category: sourceEvent.category,
          eventType: sourceEvent.eventType,
          host: sourceHost,
          startTime: sourceEvent.startTime,
          endTime: sourceEvent.endTime,
          createdAt: sourceEvent.createdAt,
          updatedAt: sourceEvent.updatedAt,
          attendeeCount: sourceEvent.attendeeCount,
        );
      }

      test('should upgrade community event to local expert event', () async {
        final eligibleEvent = event.copyWith(
          attendeeCount: 25,
          engagementScore: 0.80,
          isEligibleForUpgrade: true,
          upgradeEligibilityScore: 0.85,
          timesHosted: 5,
        );

        // Create host with required expertise
        final hostWithExpertise = host.copyWith(
          expertiseMap: {'Coffee': 'local'},
        );

        when(mockExpertiseEventService.createEvent(
          host: hostWithExpertise,
          title: eligibleEvent.title,
          description: eligibleEvent.description,
          category: eligibleEvent.category,
          eventType: eligibleEvent.eventType,
          startTime: eligibleEvent.startTime,
          endTime: eligibleEvent.endTime,
          spots: eligibleEvent.spots,
          location: eligibleEvent.location,
          latitude: eligibleEvent.latitude,
          longitude: eligibleEvent.longitude,
          maxAttendees: eligibleEvent.maxAttendees,
          price: eligibleEvent.price,
          isPublic: eligibleEvent.isPublic,
        )).thenAnswer((_) async => _createMockExpertiseEvent(eligibleEvent, hostWithExpertise));

        when(mockCommunityEventService.cancelCommunityEvent(eligibleEvent))
            .thenAnswer((_) async => eligibleEvent);

        final upgradedEvent = await service.upgradeToLocalEvent(
          eligibleEvent,
          hostWithExpertise,
        );

        expect(upgradedEvent, isA<ExpertiseEvent>());
        expect(upgradedEvent.title, equals(eligibleEvent.title));
        expect(upgradedEvent.category, equals(eligibleEvent.category));
      });

      test('should update event type (community → local)', () async {
        final eligibleEvent = event.copyWith(
          isEligibleForUpgrade: true,
          upgradeEligibilityScore: 0.85,
          timesHosted: 5,
          engagementScore: 0.80,
        );

        final hostWithExpertise = host.copyWith(
          expertiseMap: {'Coffee': 'local'},
        );

        when(mockExpertiseEventService.createEvent(
          host: hostWithExpertise,
          title: eligibleEvent.title,
          description: eligibleEvent.description,
          category: eligibleEvent.category,
          eventType: eligibleEvent.eventType,
          startTime: eligibleEvent.startTime,
          endTime: eligibleEvent.endTime,
          spots: eligibleEvent.spots,
          location: eligibleEvent.location,
          latitude: eligibleEvent.latitude,
          longitude: eligibleEvent.longitude,
          maxAttendees: eligibleEvent.maxAttendees,
          price: eligibleEvent.price,
          isPublic: eligibleEvent.isPublic,
        )).thenAnswer((_) async => _createMockExpertiseEvent(eligibleEvent, hostWithExpertise));

        when(mockCommunityEventService.cancelCommunityEvent(eligibleEvent))
            .thenAnswer((_) async => eligibleEvent);

        final upgradedEvent = await service.upgradeToLocalEvent(
          eligibleEvent,
          hostWithExpertise,
        );

        expect(upgradedEvent, isA<ExpertiseEvent>());
        // Event is now an ExpertiseEvent, not a CommunityEvent
        expect(upgradedEvent, isNot(isA<CommunityEvent>()));
      });

      test('should preserve event history and metrics', () async {
        final eligibleEvent = event.copyWith(
          attendeeCount: 25,
          engagementScore: 0.80,
          growthMetrics: 0.20,
          diversityMetrics: 0.70,
          isEligibleForUpgrade: true,
          upgradeEligibilityScore: 0.85,
          timesHosted: 5,
        );

        final hostWithExpertise = host.copyWith(
          expertiseMap: {'Coffee': 'local'},
        );

        when(mockExpertiseEventService.createEvent(
          host: hostWithExpertise,
          title: eligibleEvent.title,
          description: eligibleEvent.description,
          category: eligibleEvent.category,
          eventType: eligibleEvent.eventType,
          startTime: eligibleEvent.startTime,
          endTime: eligibleEvent.endTime,
          spots: eligibleEvent.spots,
          location: eligibleEvent.location,
          latitude: eligibleEvent.latitude,
          longitude: eligibleEvent.longitude,
          maxAttendees: eligibleEvent.maxAttendees,
          price: eligibleEvent.price,
          isPublic: eligibleEvent.isPublic,
        )).thenAnswer((_) async => _createMockExpertiseEvent(eligibleEvent, hostWithExpertise));

        when(mockCommunityEventService.cancelCommunityEvent(eligibleEvent))
            .thenAnswer((_) async => eligibleEvent);

        final upgradedEvent = await service.upgradeToLocalEvent(
          eligibleEvent,
          hostWithExpertise,
        );

        expect(upgradedEvent.attendeeCount, equals(eligibleEvent.attendeeCount));
        expect(upgradedEvent.createdAt, equals(eligibleEvent.createdAt));
      });

      test('should throw error when event is not eligible', () async {
        final ineligibleEvent = event.copyWith(
          isEligibleForUpgrade: false,
          upgradeEligibilityScore: 0.30,
          timesHosted: 1,
          engagementScore: 0.30,
        );

        final hostWithExpertise = host.copyWith(
          expertiseMap: {'Coffee': 'local'},
        );

        expect(
          () => service.upgradeToLocalEvent(ineligibleEvent, hostWithExpertise),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
