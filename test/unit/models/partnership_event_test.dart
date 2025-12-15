import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/partnership_event.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import '../../fixtures/model_factories.dart';
import '../../helpers/test_helpers.dart';

/// Comprehensive tests for PartnershipEvent model
/// Tests partnership event creation, JSON serialization, and partnership integration
void main() {
  group('PartnershipEvent Model Tests', () {
    late DateTime testDate;
    late DateTime startTime;
    late DateTime endTime;
    late UnifiedUser testHost;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      startTime = testDate.add(Duration(days: 1));
      endTime = startTime.add(Duration(hours: 2));
      testHost = ModelFactories.createTestUser(
        id: 'host-123',
        displayName: 'Expert Host',
      );
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    // Removed: Constructor and Properties group
    // These tests only verified Dart constructor behavior, not business logic

    group('Partnership Detection', () {
      test(
          'should correctly detect partnership and revenue split in factory and direct creation',
          () {
        // Test business logic: partnership detection
        final baseEvent = ExpertiseEvent(
          id: 'event-123',
          title: 'Coffee Tour',
          description: 'A guided tour of local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: startTime,
          endTime: endTime,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final withPartnership = PartnershipEvent.fromExpertiseEvent(
          event: baseEvent,
          partnershipId: 'partnership-123',
          revenueSplitId: 'split-123',
          partnerIds: ['user-123', 'business-123'],
          partnerCount: 2,
        );
        final withoutPartnership = PartnershipEvent.fromExpertiseEvent(
          event: baseEvent,
        );
        final directEvent = PartnershipEvent(
          id: 'event-456',
          title: 'Solo Tour',
          description: 'A solo tour',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: startTime,
          endTime: endTime,
          createdAt: testDate,
          updatedAt: testDate,
          partnershipId: 'partnership-123',
          revenueSplitId: 'split-123',
        );

        // Test factory method behavior
        expect(withPartnership.hasPartnership, isTrue);
        expect(withoutPartnership.hasPartnership, isFalse);
        expect(withPartnership.partnerIds, hasLength(2));

        // Test direct creation
        expect(directEvent.hasPartnership, isTrue);
        expect(directEvent.hasRevenueSplit, isTrue);
        expect(withoutPartnership.isRevenueSplitLocked, isFalse);
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize partnership data correctly', () {
        final event = PartnershipEvent(
          id: 'event-123',
          title: 'Coffee Tour',
          description: 'A guided tour of local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: startTime,
          endTime: endTime,
          createdAt: testDate,
          updatedAt: testDate,
          partnershipId: 'partnership-123',
          revenueSplitId: 'split-123',
          isPartnershipEvent: true,
          partnerIds: ['user-123', 'business-123'],
          partnerCount: 2,
        );

        final json = event.toJson();
        final reconstructed = PartnershipEvent.fromJson(json, testHost);

        // Test critical partnership fields (business logic validation)
        expect(reconstructed.partnershipId, equals(event.partnershipId));
        expect(reconstructed.revenueSplitId, equals(event.revenueSplitId));
        expect(reconstructed.partnerIds, equals(event.partnerIds));
        expect(reconstructed.partnerCount, equals(event.partnerCount));
      });
    });

    group('Copy With', () {
      test('should create immutable copy with updated fields', () {
        final event = PartnershipEvent(
          id: 'event-123',
          title: 'Coffee Tour',
          description: 'A guided tour of local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: startTime,
          endTime: endTime,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = event.copyWith(
          title: 'Updated Coffee Tour',
          partnershipId: 'partnership-123',
          partnerIds: ['user-123'],
        );

        // Test immutability (business logic)
        expect(event.title, isNot(equals('Updated Coffee Tour')));
        expect(updated.title, equals('Updated Coffee Tour'));
        expect(updated.id, equals(event.id)); // Unchanged fields preserved
        expect(updated.hasPartnership, isTrue); // Partnership detection works
      });
    });

    group('Inheritance from ExpertiseEvent', () {
      test('should inherit all ExpertiseEvent methods', () {
        // Use real "future" times relative to DateTime.now() so time-based getters
        // (`hasStarted` / `hasEnded`) are deterministic regardless of the testDate fixture.
        final now = DateTime.now();
        final futureStart = now.add(const Duration(hours: 1));
        final futureEnd = futureStart.add(const Duration(hours: 2));

        final event = PartnershipEvent(
          id: 'event-123',
          title: 'Coffee Tour',
          description: 'A guided tour of local coffee shops',
          category: 'Coffee',
          eventType: ExpertiseEventType.tour,
          host: testHost,
          startTime: futureStart,
          endTime: futureEnd,
          createdAt: testDate,
          updatedAt: testDate,
          maxAttendees: 20,
          attendeeCount: 10,
        );

        // Test inherited methods
        expect(event.isFull, isFalse);
        expect(event.hasStarted, isFalse);
        expect(event.hasEnded, isFalse);
        expect(event.canUserAttend('user-456'), isTrue);
        expect(event.getEventTypeDisplayName(), equals('Expert Tour'));
        expect(event.getEventTypeEmoji(), equals('🚶'));
      });
    });
  });
}
