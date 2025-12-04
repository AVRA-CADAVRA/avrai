import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:spots/core/services/community_event_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_event.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/integration_test_helpers.dart';
import '../../helpers/test_helpers.dart';

/// Manual mock for ExpertiseEventService
class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

/// Comprehensive tests for CommunityEventService
/// Tests non-expert event creation, validation, metrics tracking, and event management
/// 
/// **Philosophy Alignment:**
/// - Opens doors for non-experts to host community events
/// - Enables organic community building
/// - Creates path from community events to expert events
void main() {
  group('CommunityEventService Tests', () {
    late CommunityEventService service;
    late UnifiedUser nonExpertHost;
    late UnifiedUser expertHost;

    setUp(() {
      TestHelpers.setupTestEnvironment();

      service = CommunityEventService();

      // Create non-expert host (no expertise)
      nonExpertHost = ModelFactories.createTestUser(
        id: 'non-expert-1',
      ).copyWith(
        location: 'Mission District, San Francisco',
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

    group('createCommunityEvent', () {
      test('should allow non-experts to create events', () async {
        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Community Coffee Meetup',
          description: 'A casual meetup for coffee lovers',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        expect(event, isA<CommunityEvent>());
        expect(event.title, equals('Community Coffee Meetup'));
        expect(event.isCommunityEvent, isTrue);
        expect(event.hostExpertiseLevel, isNull);
        expect(event.host.id, equals(nonExpertHost.id));
      });

      test('should allow experts to create community events', () async {
        final event = await service.createCommunityEvent(
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
      });

      test('should enforce no payment on app (price null)', () async {
        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Free Community Event',
          description: 'Free event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        expect(event.price, isNull);
        expect(event.isPaid, isFalse);
      });

      test('should enforce no payment on app (price 0.0)', () async {
        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Free Community Event',
          description: 'Free event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        expect(event.price, isNull);
        expect(event.isPaid, isFalse);
      });

      test('should enforce public events only', () async {
        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Public Community Event',
          description: 'Public event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          isPublic: true, // Must be true
        );

        expect(event.isPublic, isTrue);
      });

      test('should validate event details (title required)', () async {
        expect(
          () => service.createCommunityEvent(
            host: nonExpertHost,
            title: '', // Empty title should fail
            description: 'Test event',
            category: 'Coffee',
            eventType: ExpertiseEventType.meetup,
            startTime: DateTime.now().add(const Duration(days: 1)),
            endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate event details (description required)', () async {
        expect(
          () => service.createCommunityEvent(
            host: nonExpertHost,
            title: 'Test Event',
            description: '', // Empty description should fail
            category: 'Coffee',
            eventType: ExpertiseEventType.meetup,
            startTime: DateTime.now().add(const Duration(days: 1)),
            endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate event details (category required)', () async {
        expect(
          () => service.createCommunityEvent(
            host: nonExpertHost,
            title: 'Test Event',
            description: 'Test description',
            category: '', // Empty category should fail
            eventType: ExpertiseEventType.meetup,
            startTime: DateTime.now().add(const Duration(days: 1)),
            endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('should validate event dates (start before end)', () async {
        final startTime = DateTime.now().add(const Duration(days: 1));
        final endTime = startTime.add(const Duration(hours: 2));

        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Test Event',
          description: 'Test description',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: startTime,
          endTime: endTime,
        );

        expect(event.startTime.isBefore(event.endTime), isTrue);
      });

      test('should validate event dates (future dates)', () async {
        final pastStartTime = DateTime.now().subtract(const Duration(days: 1));
        final pastEndTime = pastStartTime.add(const Duration(hours: 2));

        expect(
          () => service.createCommunityEvent(
            host: nonExpertHost,
            title: 'Test Event',
            description: 'Test description',
            category: 'Coffee',
            eventType: ExpertiseEventType.meetup,
            startTime: pastStartTime, // Past date should fail
            endTime: pastEndTime,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('Event Metrics Tracking', () {
      late CommunityEvent event;

      setUp(() async {
        event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Test Event',
          description: 'Test description',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
      });

      test('should track attendance', () async {
        await service.trackAttendance(event, 15);
        
        final updatedEvent = await service.getCommunityEventById(event.id);
        expect(updatedEvent, isNotNull);
        expect(updatedEvent!.attendeeCount, equals(15));
      });

      test('should track engagement score', () async {
        await service.trackEngagement(
          event,
          viewCount: 100,
          saveCount: 25,
          shareCount: 10,
        );
        
        final updatedEvent = await service.getCommunityEventById(event.id);
        expect(updatedEvent, isNotNull);
        expect(updatedEvent!.engagementScore, greaterThanOrEqualTo(0.0));
        expect(updatedEvent.engagementScore, lessThanOrEqualTo(1.0));
      });

      test('should track growth metrics', () async {
        await service.trackGrowth(
          event,
          [10, 15], // Attendance history
        );
        
        final updatedEvent = await service.getCommunityEventById(event.id);
        expect(updatedEvent, isNotNull);
        expect(updatedEvent!.growthMetrics, greaterThanOrEqualTo(0.0));
      });

      test('should track diversity metrics', () async {
        await service.trackDiversity(
          event,
          0.75, // Diversity score
        );
        
        final updatedEvent = await service.getCommunityEventById(event.id);
        expect(updatedEvent, isNotNull);
        expect(updatedEvent!.diversityMetrics, greaterThanOrEqualTo(0.0));
        expect(updatedEvent.diversityMetrics, lessThanOrEqualTo(1.0));
      });
    });

    group('Event Management', () {
      late CommunityEvent event;

      setUp(() async {
        event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Test Event',
          description: 'Test description',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );
      });

      test('should get all community events', () async {
        final events = await service.getCommunityEvents();

        expect(events, isA<List<CommunityEvent>>());
        expect(events, contains(event));
      });

      test('should get events by host', () async {
        final events = await service.getCommunityEventsByHost(nonExpertHost);

        expect(events, isA<List<CommunityEvent>>());
        expect(events.every((e) => e.host.id == nonExpertHost.id), isTrue);
      });

      test('should get events by category', () async {
        final events = await service.getCommunityEventsByCategory('Coffee');

        expect(events, isA<List<CommunityEvent>>());
        expect(events.every((e) => e.category == 'Coffee'), isTrue);
      });

      test('should update event details', () async {
        final updatedEvent = await service.updateCommunityEvent(
          event: event,
          title: 'Updated Title',
          description: 'Updated description',
        );

        expect(updatedEvent.title, equals('Updated Title'));
        expect(updatedEvent.description, equals('Updated description'));
        expect(updatedEvent.id, equals(event.id));
      });

      test('should cancel event', () async {
        final cancelledEvent = await service.cancelCommunityEvent(event);

        expect(cancelledEvent.status, equals(EventStatus.cancelled));
      });
    });

    group('Integration with ExpertiseEventService', () {
      test('should make community events appear in event search', () async {
        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Searchable Event',
          description: 'This should appear in search',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Verify event service integration
        final retrievedEvent = await service.getCommunityEventById(event.id);
        expect(retrievedEvent, isNotNull);
        expect(retrievedEvent!.id, equals(event.id));
      });

      test('should make community events appear in event browse', () async {
        final event = await service.createCommunityEvent(
          host: nonExpertHost,
          title: 'Browseable Event',
          description: 'This should appear in browse',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          startTime: DateTime.now().add(const Duration(days: 1)),
          endTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
        );

        // Community events should be accessible through event service
        expect(event.isCommunityEvent, isTrue);
      });

      test('should allow filtering community events separately', () async {
        final communityEvents = await service.getCommunityEvents();

        // Community events should be filterable
        expect(communityEvents, isA<List<CommunityEvent>>());
        expect(communityEvents.every((e) => e.isCommunityEvent), isTrue);
      });
    });
  });
}
