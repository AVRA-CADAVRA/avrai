import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/models/partnership_event.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
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
    late List<Spot> testSpots;

    setUp(() {
      TestHelpers.setupTestEnvironment();
      testDate = TestHelpers.createTestDateTime();
      startTime = testDate.add(Duration(days: 1));
      endTime = startTime.add(Duration(hours: 2));
      testHost = ModelFactories.createTestUser(
        id: 'host-123',
        displayName: 'Expert Host',
      );
      testSpots = [
        ModelFactories.createTestSpot(id: 'spot-1', name: 'Coffee Shop 1'),
        ModelFactories.createTestSpot(id: 'spot-2', name: 'Coffee Shop 2'),
      ];
    });

    tearDown(() {
      TestHelpers.teardownTestEnvironment();
    });

    group('Constructor and Properties', () {
      test('should create partnership event with required fields', () {
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

        expect(event.id, equals('event-123'));
        expect(event.title, equals('Coffee Tour'));
        expect(event.category, equals('Coffee'));
        expect(event.host, equals(testHost));
        expect(event.isPartnershipEvent, isFalse);
        expect(event.hasPartnership, isFalse);
        expect(event.hasRevenueSplit, isFalse);
        expect(event.partnerIds, isEmpty);
        expect(event.partnerCount, equals(0));
      });

      test('should create partnership event with partnership fields', () {
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

        expect(event.partnershipId, equals('partnership-123'));
        expect(event.revenueSplitId, equals('split-123'));
        expect(event.isPartnershipEvent, isTrue);
        expect(event.hasPartnership, isTrue);
        expect(event.hasRevenueSplit, isTrue);
        expect(event.partnerIds, hasLength(2));
        expect(event.partnerCount, equals(2));
      });
    });

    group('From ExpertiseEvent Factory', () {
      test('should create partnership event from expertise event', () {
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

        final partnershipEvent = PartnershipEvent.fromExpertiseEvent(
          event: baseEvent,
          partnershipId: 'partnership-123',
          revenueSplitId: 'split-123',
          partnerIds: ['user-123', 'business-123'],
          partnerCount: 2,
        );

        expect(partnershipEvent.id, equals(baseEvent.id));
        expect(partnershipEvent.title, equals(baseEvent.title));
        expect(partnershipEvent.category, equals(baseEvent.category));
        expect(partnershipEvent.host, equals(baseEvent.host));
        expect(partnershipEvent.partnershipId, equals('partnership-123'));
        expect(partnershipEvent.revenueSplitId, equals('split-123'));
        expect(partnershipEvent.isPartnershipEvent, isTrue);
        expect(partnershipEvent.partnerIds, hasLength(2));
        expect(partnershipEvent.partnerCount, equals(2));
      });

      test('should create non-partnership event from expertise event', () {
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

        final partnershipEvent = PartnershipEvent.fromExpertiseEvent(
          event: baseEvent,
        );

        expect(partnershipEvent.id, equals(baseEvent.id));
        expect(partnershipEvent.isPartnershipEvent, isFalse);
        expect(partnershipEvent.hasPartnership, isFalse);
        expect(partnershipEvent.hasRevenueSplit, isFalse);
      });
    });

    group('Partnership Checks', () {
      test('should detect partnership when partnershipId is set', () {
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
        );

        expect(event.hasPartnership, isTrue);
        expect(event.isPartnershipEvent, isFalse); // Not set explicitly
      });

      test('should detect revenue split when revenueSplitId is set', () {
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
          revenueSplitId: 'split-123',
        );

        expect(event.hasRevenueSplit, isTrue);
      });

      test('should check if revenue split is locked', () {
        // This would require a RevenueSplit object with isLocked = true
        // For now, we test the null case
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

        expect(event.isRevenueSplitLocked, isFalse);
      });
    });

    group('JSON Serialization', () {
      test('should serialize partnership event to JSON', () {
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

        // Base event fields
        expect(json['id'], equals('event-123'));
        expect(json['title'], equals('Coffee Tour'));
        expect(json['category'], equals('Coffee'));
        
        // Partnership fields
        expect(json['partnershipId'], equals('partnership-123'));
        expect(json['revenueSplitId'], equals('split-123'));
        expect(json['isPartnershipEvent'], isTrue);
        expect(json['partnerIds'], hasLength(2));
        expect(json['partnerCount'], equals(2));
      });

      test('should deserialize partnership event from JSON', () {
        final json = {
          'id': 'event-123',
          'title': 'Coffee Tour',
          'description': 'A guided tour of local coffee shops',
          'category': 'Coffee',
          'eventType': 'tour',
          'hostId': 'host-123',
          'attendeeIds': [],
          'attendeeCount': 0,
          'maxAttendees': 20,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'spotIds': [],
          'location': null,
          'latitude': null,
          'longitude': null,
          'price': null,
          'isPaid': false,
          'isPublic': true,
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
          'status': 'upcoming',
          'partnershipId': 'partnership-123',
          'revenueSplitId': 'split-123',
          'isPartnershipEvent': true,
          'partnerIds': ['user-123', 'business-123'],
          'partnerCount': 2,
        };

        final event = PartnershipEvent.fromJson(json, testHost);

        expect(event.id, equals('event-123'));
        expect(event.title, equals('Coffee Tour'));
        expect(event.partnershipId, equals('partnership-123'));
        expect(event.revenueSplitId, equals('split-123'));
        expect(event.isPartnershipEvent, isTrue);
        expect(event.partnerIds, hasLength(2));
        expect(event.partnerCount, equals(2));
      });
    });

    group('Copy With', () {
      test('should create copy with updated base fields', () {
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
          category: 'Updated Coffee',
        );

        expect(updated.id, equals(event.id));
        expect(updated.title, equals('Updated Coffee Tour'));
        expect(updated.category, equals('Updated Coffee'));
        expect(updated.host, equals(event.host));
      });

      test('should create copy with updated partnership fields', () {
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
          partnershipId: 'partnership-123',
          revenueSplitId: 'split-123',
          isPartnershipEvent: true,
          partnerIds: ['user-123', 'business-123'],
          partnerCount: 2,
        );

        expect(updated.partnershipId, equals('partnership-123'));
        expect(updated.revenueSplitId, equals('split-123'));
        expect(updated.isPartnershipEvent, isTrue);
        expect(updated.partnerIds, hasLength(2));
        expect(updated.partnerCount, equals(2));
      });
    });

    group('Inheritance from ExpertiseEvent', () {
      test('should inherit all ExpertiseEvent methods', () {
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

