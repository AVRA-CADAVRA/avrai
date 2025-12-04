import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/community_event_service.dart';
import 'package:spots/core/services/community_event_upgrade_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_event.dart';
import '../helpers/integration_test_helpers.dart';
import '../helpers/test_helpers.dart';
import '../fixtures/model_factories.dart';

/// Integration tests for Community Events system
/// Tests end-to-end flows: creation, metrics tracking, upgrade, and event discovery
///
/// **Philosophy Alignment:**
/// - Opens doors for non-experts to host community events
/// - Enables organic community building
/// - Creates natural path from community events to expert events
void main() {
  group('Community Event Integration Tests', () {
    late CommunityEventService communityEventService;
    late CommunityEventUpgradeService upgradeService;
    late ExpertiseEventService expertiseEventService;
    late UnifiedUser nonExpertHost;
    late UnifiedUser expertHost;

    setUp(() {
      TestHelpers.setupTestEnvironment();

      expertiseEventService = ExpertiseEventService();
      communityEventService = CommunityEventService();
      upgradeService = CommunityEventUpgradeService(
        communityEventService: communityEventService,
        expertiseEventService: expertiseEventService,
      );

      // Create non-expert host (no expertise)
      nonExpertHost = ModelFactories.createTestUser(
        id: 'non-expert-1',
      );

      // Create expert host (has Local level expertise)
      expertHost = IntegrationTestHelpers.createUserWithLocalExpertise(
        id: 'expert-1',
        category: 'Coffee',
        location: 'Mission District, San Francisco',
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('End-to-End Community Event Creation', () {
      test('should create community event from start to finish', () async {
        // Step 1: Create community event
        final event = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Community Coffee Meetup',
          description: 'A casual meetup for coffee lovers',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          location: 'Third Coast Coffee',
          maxAttendees: 30,
        );

        expect(event, isA<CommunityEvent>());
        expect(event.title, equals('Community Coffee Meetup'));
        expect(event.isCommunityEvent, isTrue);
        expect(event.hostExpertiseLevel, isNull);
        expect(event.price, isNull);
        expect(event.isPaid, isFalse);
        expect(event.isPublic, isTrue);

        // Step 2: Track attendance
        await communityEventService.trackAttendance(event, 15);
        final eventWithAttendance =
            await communityEventService.getCommunityEventById(event.id);
        expect(eventWithAttendance?.attendeeCount, equals(15));

        // Step 3: Track engagement
        await communityEventService.trackEngagement(
          event,
          viewCount: 100,
          saveCount: 25,
          shareCount: 10,
        );
        final eventWithEngagement =
            await communityEventService.getCommunityEventById(event.id);
        expect(eventWithEngagement?.engagementScore, greaterThan(0.0));

        // Step 4: Verify event appears in community events list
        final allEvents = await communityEventService.getCommunityEvents();
        expect(allEvents, contains(event));
      });

      test('should allow expert to create community event', () async {
        final event = await communityEventService.createCommunityEvent(
          host: expertHost,
          title: 'Expert Community Event',
          description: 'An expert hosting a community event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        expect(event, isA<CommunityEvent>());
        expect(event.isCommunityEvent, isTrue);
        expect(event.host.id, equals(expertHost.id));
      });
    });

    group('Community Event Upgrade Flow', () {
      test('should upgrade community event to local expert event', () async {
        // Step 1: Create community event
        final event = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Growing Community Event',
          description: 'An event that will grow and upgrade',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Step 2: Build up metrics to become eligible
        await communityEventService.trackAttendance(event, 25);
        await communityEventService.trackEngagement(
          event,
          viewCount: 200,
          saveCount: 50,
          shareCount: 20,
        );
        await communityEventService.trackGrowth(
          event,
          [15, 25],
        );
        await communityEventService.trackDiversity(
          event,
          0.7, // diversity score
        );

        // Refresh event to get updated metrics
        final updatedEvent =
            await communityEventService.getCommunityEventById(event.id);
        expect(updatedEvent, isNotNull);

        // Step 3: Check upgrade eligibility
        final isEligible =
            await upgradeService.checkUpgradeEligibility(updatedEvent!);
        expect(isEligible, isTrue);

        // Step 4: Calculate upgrade score
        final score = await upgradeService.calculateUpgradeScore(updatedEvent);
        expect(score, greaterThan(0.0));
        expect(score, lessThanOrEqualTo(1.0));

        // Step 5: Get upgrade criteria
        final criteria = await upgradeService.getUpgradeCriteria(updatedEvent);
        expect(criteria, isNotEmpty);

        // Step 6: Upgrade to local expert event
        final upgradedEvent = await upgradeService.upgradeToLocalEvent(
            updatedEvent, nonExpertHost);
        expect(upgradedEvent, isA<ExpertiseEvent>());
        expect(upgradedEvent.title, equals(event.title));
        expect(upgradedEvent.category, equals(event.category));
      });

      test('should preserve event history during upgrade', () async {
        // Create event with history
        final event = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Event With History',
          description: 'An event with attendance history',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Build metrics
        await communityEventService.trackAttendance(event, 30);

        // Refresh event
        final updatedEvent =
            await communityEventService.getCommunityEventById(event.id);
        expect(updatedEvent, isNotNull);

        // Upgrade
        final upgradedEvent = await upgradeService.upgradeToLocalEvent(
            updatedEvent!, nonExpertHost);

        // Verify history preserved
        expect(upgradedEvent.attendeeCount, equals(30));
        expect(upgradedEvent.createdAt, equals(event.createdAt));
      });
    });

    group('Community Events in Event Search', () {
      test('should include community events in event search', () async {
        // Create community event
        final communityEvent = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Searchable Community Event',
          description: 'This should appear in search',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Create expert event
        final expertEvent = await expertiseEventService.createEvent(
          host: expertHost,
          title: 'Expert Event',
          description: 'An expert event',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Both should be searchable
        final communityEvents =
            await communityEventService.getCommunityEvents();
        expect(communityEvents, contains(communityEvent));

        // Expert event should be accessible
        final retrievedExpertEvent =
            await expertiseEventService.getEventById(expertEvent.id);
        expect(retrievedExpertEvent, isNotNull);
      });
    });

    group('Community Events in Event Browse', () {
      test('should display community events in browse', () async {
        // Create multiple community events
        final event1 = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Community Event 1',
          description: 'First community event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        final event2 = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Community Event 2',
          description: 'Second community event',
          category: 'Food',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 2)),
          endTime: DateTime.now().add(const Duration(days: 2, hours: 2)),
        );

        // Get all community events
        final allEvents = await communityEventService.getCommunityEvents();
        expect(allEvents.length, greaterThanOrEqualTo(2));
        expect(allEvents, contains(event1));
        expect(allEvents, contains(event2));
      });

      test('should filter community events by category', () async {
        // Create events in different categories
        final coffeeEvent = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Coffee Event',
          description: 'Coffee community event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        final foodEvent = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Food Event',
          description: 'Food community event',
          category: 'Food',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Filter by category
        final coffeeEvents =
            await communityEventService.getCommunityEventsByCategory('Coffee');
        expect(coffeeEvents, contains(coffeeEvent));
        expect(coffeeEvents, isNot(contains(foodEvent)));

        final foodEvents =
            await communityEventService.getCommunityEventsByCategory('Food');
        expect(foodEvents, contains(foodEvent));
        expect(foodEvents, isNot(contains(coffeeEvent)));
      });

      test('should filter community events by host', () async {
        // Create events with different hosts
        final host1Event = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Host 1 Event',
          description: 'Event by host 1',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        final host2 = ModelFactories.createTestUser(
          id: 'host-2',
        );

        final host2Event = await communityEventService.createCommunityEvent(
          host: host2,
          title: 'Host 2 Event',
          description: 'Event by host 2',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Filter by host
        final host1Events =
            await communityEventService.getCommunityEventsByHost(nonExpertHost);
        expect(host1Events, contains(host1Event));
        expect(host1Events, isNot(contains(host2Event)));

        final host2Events =
            await communityEventService.getCommunityEventsByHost(host2);
        expect(host2Events, contains(host2Event));
        expect(host2Events, isNot(contains(host1Event)));
      });
    });

    group('Community Event Management', () {
      test('should update community event details', () async {
        // Create event
        final event = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Original Title',
          description: 'Original description',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Update event
        final updatedEvent = await communityEventService.updateCommunityEvent(
          event: event,
          title: 'Updated Title',
          description: 'Updated description',
        );

        expect(updatedEvent.title, equals('Updated Title'));
        expect(updatedEvent.description, equals('Updated description'));
        expect(updatedEvent.id, equals(event.id));
      });

      test('should cancel community event', () async {
        // Create event
        final event = await communityEventService.createCommunityEvent(
          host: nonExpertHost,
          title: 'Event to Cancel',
          description: 'This event will be cancelled',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Cancel event
        final cancelledEvent =
            await communityEventService.cancelCommunityEvent(event);

        expect(cancelledEvent.status, equals(EventStatus.cancelled));
      });
    });
  });
}
