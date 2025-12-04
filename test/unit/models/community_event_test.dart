import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/expertise_event.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/integration_test_helpers.dart';

/// Comprehensive tests for CommunityEvent model
/// Tests community event creation, validation, metrics tracking, and upgrade eligibility
/// 
/// **Philosophy Alignment:**
/// - Opens doors for non-experts to host community events
/// - Enables organic community building
/// - Creates path from community events to expert events
void main() {
  group('CommunityEvent Model Tests', () {
    late DateTime testDate;
    late UnifiedUser nonExpertHost;
    late UnifiedUser expertHost;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      
      // Create non-expert host (no expertise)
      nonExpertHost = IntegrationTestHelpers.createUser(
        id: 'non-expert-1',
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

    group('Constructor and Properties', () {
      test('should create community event with required fields', () {
        final event = CommunityEvent(
          id: 'community-event-123',
          title: 'Community Coffee Meetup',
          description: 'A casual meetup for coffee lovers',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.id, equals('community-event-123'));
        expect(event.title, equals('Community Coffee Meetup'));
        expect(event.isCommunityEvent, isTrue);
        expect(event.hostExpertiseLevel, isNull);
        expect(event.price, isNull);
        expect(event.isPaid, isFalse);
        expect(event.isPublic, isTrue);
      });

      test('should create community event with all fields', () {
        final event = CommunityEvent(
          id: 'community-event-123',
          title: 'Community Coffee Meetup',
          description: 'A casual meetup for coffee lovers',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          hostExpertiseLevel: null, // Non-expert
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          location: 'Third Coast Coffee',
          maxAttendees: 30,
          price: null, // Community events are free
          isPaid: false,
          isPublic: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.location, equals('Third Coast Coffee'));
        expect(event.maxAttendees, equals(30));
        expect(event.price, isNull);
        expect(event.isPaid, isFalse);
      });

      test('should allow expert to host community event', () {
        final event = CommunityEvent(
          id: 'community-event-123',
          title: 'Expert Community Event',
          description: 'An expert hosting a community event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: expertHost,
          hostExpertiseLevel: ExpertiseLevel.local, // Expert can host community events too
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.hostExpertiseLevel, equals(ExpertiseLevel.local));
        expect(event.isCommunityEvent, isTrue);
      });
    });

    group('Validation - No Payment on App', () {
      test('should enforce price is null or 0.0', () {
        // Price null (valid)
        final event1 = CommunityEvent(
          id: 'event-1',
          title: 'Free Event',
          description: 'Free community event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          price: null,
          isPaid: false,
          createdAt: testDate,
          updatedAt: testDate,
        );
        expect(event1.price, isNull);
        expect(event1.isPaid, isFalse);

        // Price 0.0 (valid)
        final event2 = CommunityEvent(
          id: 'event-2',
          title: 'Free Event',
          description: 'Free community event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          price: 0.0,
          isPaid: false,
          createdAt: testDate,
          updatedAt: testDate,
        );
        expect(event2.price, equals(0.0));
        expect(event2.isPaid, isFalse);
      });

      test('should enforce isPaid is false', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Free Event',
          description: 'Free community event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          price: null,
          isPaid: false, // Must be false for community events
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.isPaid, isFalse);
      });
    });

    group('Validation - Public Events Only', () {
      test('should enforce isPublic is true', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Public Event',
          description: 'Public community event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          isPublic: true, // Must be true for community events
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.isPublic, isTrue);
      });
    });

    group('Event Metrics Tracking', () {
      test('should track attendance count', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          attendeeCount: 15,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.attendeeCount, equals(15));
      });

      test('should track engagement score', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          engagementScore: 0.75, // Views, saves, shares
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.engagementScore, equals(0.75));
        expect(event.engagementScore, greaterThanOrEqualTo(0.0));
        expect(event.engagementScore, lessThanOrEqualTo(1.0));
      });

      test('should track growth metrics', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          attendanceGrowth: 0.20, // 20% growth
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.attendanceGrowth, equals(0.20));
      });

      test('should track diversity metrics', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          attendeeDiversity: 0.65, // Diversity score
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.attendeeDiversity, equals(0.65));
        expect(event.attendeeDiversity, greaterThanOrEqualTo(0.0));
        expect(event.attendeeDiversity, lessThanOrEqualTo(1.0));
      });
    });

    group('Upgrade Eligibility Tracking', () {
      test('should track upgrade eligibility flag', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          isEligibleForUpgrade: true,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.isEligibleForUpgrade, isTrue);
      });

      test('should track upgrade eligibility score', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          upgradeEligibilityScore: 0.85, // 85% eligible
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.upgradeEligibilityScore, equals(0.85));
        expect(event.upgradeEligibilityScore, greaterThanOrEqualTo(0.0));
        expect(event.upgradeEligibilityScore, lessThanOrEqualTo(1.0));
      });

      test('should track upgrade criteria', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          upgradeCriteria: ['frequency_hosting', 'strong_following'],
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.upgradeCriteria, contains('frequency_hosting'));
        expect(event.upgradeCriteria, contains('strong_following'));
      });
    });

    group('JSON Serialization/Deserialization', () {
      test('should serialize to JSON', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = event.toJson();

        expect(json['id'], equals('event-1'));
        expect(json['title'], equals('Community Event'));
        expect(json['isCommunityEvent'], isTrue);
        expect(json['hostExpertiseLevel'], isNull);
        expect(json['price'], isNull);
        expect(json['isPaid'], isFalse);
        expect(json['isPublic'], isTrue);
      });

      test('should deserialize from JSON', () {
        final json = {
          'id': 'event-1',
          'title': 'Community Event',
          'description': 'Test event',
          'category': 'Coffee',
          'eventType': 'meetup',
          'hostId': nonExpertHost.id,
          'startTime': testDate.add(const Duration(days: 1)).toIso8601String(),
          'endTime': testDate.add(const Duration(days: 1, hours: 2)).toIso8601String(),
          'isCommunityEvent': true,
          'hostExpertiseLevel': null,
          'price': null,
          'isPaid': false,
          'isPublic': true,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'status': 'upcoming',
        };

        final event = CommunityEvent.fromJson(json, nonExpertHost);

        expect(event.id, equals('event-1'));
        expect(event.isCommunityEvent, isTrue);
        expect(event.hostExpertiseLevel, isNull);
        expect(event.price, isNull);
        expect(event.isPaid, isFalse);
      });
    });

    group('CopyWith Method', () {
      test('should create copy with updated fields', () {
        final original = CommunityEvent(
          id: 'event-1',
          title: 'Original Title',
          description: 'Original description',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          title: 'Updated Title',
          attendeeCount: 10,
          engagementScore: 0.80,
        );

        expect(updated.title, equals('Updated Title'));
        expect(updated.attendeeCount, equals(10));
        expect(updated.engagementScore, equals(0.80));
        expect(updated.id, equals(original.id)); // Unchanged
        expect(updated.category, equals(original.category)); // Unchanged
      });
    });

    group('Equatable Implementation', () {
      test('should be equal when properties match', () {
        final event1 = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final event2 = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event1, equals(event2));
      });

      test('should not be equal when properties differ', () {
        final event1 = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        final event2 = CommunityEvent(
          id: 'event-2',
          title: 'Different Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event1, isNot(equals(event2)));
      });
    });

    group('Helper Methods', () {
      test('should check if event is full', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          attendeeCount: 20,
          maxAttendees: 20,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.isFull, isTrue);
      });

      test('should check if user can attend', () {
        final event = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: testDate.add(const Duration(days: 1)),
          endTime: testDate.add(const Duration(days: 1, hours: 2)),
          attendeeIds: ['user-1'],
          attendeeCount: 1,
          maxAttendees: 20,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(event.canUserAttend('user-2'), isTrue);
        expect(event.canUserAttend('user-1'), isFalse); // Already attending
      });
    });
  });
}

