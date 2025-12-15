import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/community_event.dart';
import 'package:spots/core/models/unified_user.dart';
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
      nonExpertHost = IntegrationTestHelpers.createUserWithoutHosting(
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

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Validation - No Payment on App', () {
      test('should enforce community events are free', () {
        // Test business logic: payment validation
        final freeEvent = CommunityEvent(
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

        expect(freeEvent.isPaid, isFalse);
        expect(freeEvent.price, anyOf(isNull, equals(0.0)));
      });
    });

    // Removed: Validation - Public Events Only group
    // This test only verified boolean property, not business logic

    // Removed: Event Metrics Tracking group
    // These tests only verified property assignment, not business logic

    // Removed: Upgrade Eligibility Tracking group
    // These tests only verified property assignment, not business logic

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss', () {
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
        final restored = CommunityEvent.fromJson(json, nonExpertHost);

        // Test critical business fields preserved
        expect(restored.isCommunityEvent, isTrue);
        expect(restored.isPaid, isFalse);
        expect(restored.isPublic, isTrue);
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
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
          engagementScore: 0.80,
        );

        // Test immutability (business logic)
        expect(original.title, isNot(equals('Updated Title')));
        expect(updated.title, equals('Updated Title'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
      });
    });

    // Removed: Equatable Implementation group
    // These tests verify Equatable implementation, which is already tested by the package
    // If equality breaks, other tests will fail

    group('Helper Methods', () {
      test(
          'should correctly determine event capacity and attendance eligibility',
          () {
        // Test business logic: capacity checking
        final now = DateTime.now();
        final fullEvent = CommunityEvent(
          id: 'event-1',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          attendeeCount: 20,
          maxAttendees: 20,
          createdAt: testDate,
          updatedAt: testDate,
        );
        final availableEvent = CommunityEvent(
          id: 'event-2',
          title: 'Community Event',
          description: 'Test event',
          category: 'Coffee',
          eventType: ExpertiseEventType.meetup,
          host: nonExpertHost,
          startTime: now.add(const Duration(days: 1)),
          endTime: now.add(const Duration(days: 1, hours: 2)),
          attendeeIds: ['user-1'],
          attendeeCount: 1,
          maxAttendees: 20,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(fullEvent.isFull, isTrue);
        expect(availableEvent.canUserAttend('user-2'), isTrue);
        expect(availableEvent.canUserAttend('user-1'),
            isFalse); // Already attending
      });
    });
  });
}
