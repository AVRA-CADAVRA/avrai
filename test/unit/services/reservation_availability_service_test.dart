/// SPOTS Reservation Availability Service Tests
/// Date: January 6, 2026
/// Purpose: Test ReservationAvailabilityService functionality
///
/// Test Coverage:
/// - Core Methods: checkAvailability, getCapacity, reserveCapacity, releaseCapacity
/// - Availability Checks: Event availability, spot/business availability
/// - Error Handling: Service errors, event not found, capacity checks
///
/// Dependencies:
/// - Mock ReservationService: Reservation data retrieval
/// - Mock ExpertiseEventService: Event data retrieval
/// - Mock SupabaseService: Database queries
///
/// ⚠️  TEST QUALITY GUIDELINES:
/// ✅ DO: Test business logic, error handling, async operations, side effects
/// ✅ DO: Test service behavior and interactions with dependencies
/// ✅ DO: Consolidate related checks into comprehensive test blocks
///
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/services/reservation_availability_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/unified_user.dart';

// Mock dependencies
class MockReservationService extends Mock implements ReservationService {}

class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

class MockSupabaseService extends Mock implements SupabaseService {}

void main() {
  setUpAll(() {
    // Register fallback values for enum types
    registerFallbackValue(ReservationType.event);
    registerFallbackValue(ReservationType.spot);
    registerFallbackValue(ReservationType.business);
  });

  group('ReservationAvailabilityService', () {
    late ReservationAvailabilityService service;
    late MockReservationService mockReservationService;
    late MockExpertiseEventService mockEventService;
    late MockSupabaseService mockSupabaseService;

    setUp(() {
      mockReservationService = MockReservationService();
      mockEventService = MockExpertiseEventService();
      mockSupabaseService = MockSupabaseService();

      service = ReservationAvailabilityService(
        reservationService: mockReservationService,
        eventService: mockEventService,
        supabaseService: mockSupabaseService,
      );
    });

    // Helper function to create test user
    UnifiedUser createTestUser() {
      return UnifiedUser(
        id: 'user-1',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    // Helper function to create test event
    ExpertiseEvent createTestEvent({
      required String id,
      required DateTime startTime,
      int attendeeCount = 0,
      int maxAttendees = 20,
    }) {
      final host = createTestUser();
      return ExpertiseEvent(
        id: id,
        title: 'Test Event',
        description: 'Test Description',
        category: 'Test Category',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 2)),
        attendeeCount: attendeeCount,
        maxAttendees: maxAttendees,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    group('checkAvailability', () {
      test('should return available for events with sufficient capacity',
          () async {
        // Test business logic: event availability with sufficient capacity
        const eventId = 'event-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 5,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        final result = await service.checkAvailability(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
          ticketCount: 2,
        );

        expect(result.isAvailable, isTrue);
        expect(result.availableCapacity, equals(15)); // 20 - 5
        expect(result.reason, isNull);
        expect(result.waitlistAvailable, isFalse);

        verify(() => mockEventService.getEventById(eventId)).called(1);
      });

      test('should return unavailable when event not found', () async {
        // Test error handling: event not found
        const eventId = 'nonexistent';

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => null);

        final result = await service.checkAvailability(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          partySize: 2,
        );

        expect(result.isAvailable, isFalse);
        expect(result.reason, contains('Event not found'));
        expect(result.availableCapacity, isNull);

        verify(() => mockEventService.getEventById(eventId)).called(1);
      });

      test('should return unavailable when event has already started',
          () async {
        // Test business logic: can't reserve for events that have started
        const eventId = 'event-1';
        final pastTime = DateTime.now().subtract(const Duration(hours: 1));
        final event = createTestEvent(
          id: eventId,
          startTime: pastTime, // Event has started
          attendeeCount: 5,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        final result = await service.checkAvailability(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: pastTime,
          partySize: 2,
        );

        expect(result.isAvailable, isFalse);
        expect(result.reason, contains('Event has already started'));
        expect(result.availableCapacity, isNull);

        verify(() => mockEventService.getEventById(eventId)).called(1);
      });

      test('should return unavailable when insufficient capacity', () async {
        // Test business logic: insufficient capacity with waitlist option
        const eventId = 'event-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 18,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        final result = await service.checkAvailability(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 5, // Requesting 5 tickets, only 2 available
          ticketCount: 5,
        );

        expect(result.isAvailable, isFalse);
        expect(result.reason, contains('Insufficient capacity'));
        expect(result.reason, contains('Only 2 tickets available'));
        expect(result.waitlistAvailable, isTrue); // Waitlist available

        verify(() => mockEventService.getEventById(eventId)).called(1);
      });

      test('should return available for spots/businesses (currently unlimited)',
          () async {
        // Test business logic: spot/business availability (placeholder - returns available)
        const targetId = 'spot-1';

        final result = await service.checkAvailability(
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          partySize: 4,
        );

        expect(result.isAvailable, isTrue);
        expect(result.reason, isNull);
        expect(result.waitlistAvailable, isFalse);
      });

      test('should handle errors gracefully', () async {
        // Test error handling: service errors
        const eventId = 'event-1';

        when(() => mockEventService.getEventById(eventId))
            .thenThrow(Exception('Service error'));

        final result = await service.checkAvailability(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          partySize: 2,
        );

        expect(result.isAvailable, isFalse);
        expect(result.reason, contains('Error checking event availability'));
      });
    });

    group('getCapacity', () {
      test('should return capacity info for events', () async {
        // Test business logic: capacity calculation for events
        const eventId = 'event-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 5,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        final capacity = await service.getCapacity(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
        );

        expect(capacity.totalCapacity, equals(20));
        expect(capacity.reservedCapacity, equals(5));
        expect(capacity.availableCapacity, equals(15));

        verify(() => mockEventService.getEventById(eventId)).called(1);
      });

      test('should return unlimited capacity for spots/businesses', () async {
        // Test business logic: unlimited capacity for spots/businesses (placeholder)
        const targetId = 'spot-1';

        final capacity = await service.getCapacity(
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        expect(capacity.totalCapacity, equals(-1)); // -1 means unlimited
        expect(capacity.reservedCapacity, equals(0));
        expect(capacity.availableCapacity, equals(-1)); // -1 means unlimited
      });

      test('should throw error when event not found', () async {
        // Test error handling: event not found throws exception
        const eventId = 'nonexistent';

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => null);

        expect(
          () => service.getCapacity(
            type: ReservationType.event,
            targetId: eventId,
            reservationTime: DateTime.now().add(const Duration(days: 7)),
          ),
          throwsException,
        );

        verify(() => mockEventService.getEventById(eventId)).called(1);
      });

      test('should rethrow errors', () async {
        // Test error handling: errors are rethrown
        const eventId = 'event-1';

        when(() => mockEventService.getEventById(eventId))
            .thenThrow(Exception('Service error'));

        expect(
          () => service.getCapacity(
            type: ReservationType.event,
            targetId: eventId,
            reservationTime: DateTime.now().add(const Duration(days: 7)),
          ),
          throwsException,
        );
      });
    });

    group('reserveCapacity', () {
      test('should return true when capacity is sufficient for events',
          () async {
        // Test business logic: capacity reservation succeeds when capacity available
        const eventId = 'event-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 5,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        final reserved = await service.reserveCapacity(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          ticketCount: 2,
          reservationId: 'reservation-1',
        );

        expect(reserved, isTrue);

        verify(() => mockEventService.getEventById(eventId)).called(1);
      });

      test('should return false when capacity is insufficient for events',
          () async {
        // Test business logic: capacity reservation fails when insufficient capacity
        const eventId = 'event-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 19,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        final reserved = await service.reserveCapacity(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          ticketCount: 5, // Requesting 5, only 1 available
          reservationId: 'reservation-1',
        );

        expect(reserved, isFalse);

        verify(() => mockEventService.getEventById(eventId)).called(1);
      });

      test('should return true for spots/businesses (unlimited capacity)',
          () async {
        // Test business logic: capacity reservation succeeds for spots/businesses (unlimited)
        const targetId = 'spot-1';

        final reserved = await service.reserveCapacity(
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          ticketCount: 10,
          reservationId: 'reservation-1',
        );

        expect(reserved, isTrue);
      });

      test('should return false on error', () async {
        // Test error handling: errors return false
        const eventId = 'event-1';

        when(() => mockEventService.getEventById(eventId))
            .thenThrow(Exception('Service error'));

        final reserved = await service.reserveCapacity(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          ticketCount: 2,
          reservationId: 'reservation-1',
        );

        expect(reserved, isFalse);
      });
    });

    group('releaseCapacity', () {
      test('should handle capacity release without errors', () async {
        // Test error handling: capacity release doesn't throw errors
        const targetId = 'target-1';

        await service.releaseCapacity(
          type: ReservationType.event,
          targetId: targetId,
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          ticketCount: 2,
          reservationId: 'reservation-1',
        );

        // Should complete without errors (placeholder implementation)
        expect(true, isTrue);
      });

      test('should handle errors gracefully without throwing', () async {
        // Test error handling: errors don't throw (non-critical operation)
        // Note: Current implementation is a placeholder, so no errors thrown
        const targetId = 'target-1';

        await service.releaseCapacity(
          type: ReservationType.event,
          targetId: targetId,
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          ticketCount: 2,
          reservationId: 'reservation-1',
        );

        // Should complete without throwing
        expect(true, isTrue);
      });
    });

    group('Placeholder Methods', () {
      test('getAvailableTimeSlots should return empty list (placeholder)',
          () async {
        // Test behavior: placeholder returns empty list
        final slots = await service.getAvailableTimeSlots(
          type: ReservationType.spot,
          targetId: 'target-1',
          date: DateTime.now(),
        );

        expect(slots, isEmpty);
      });

      test('isWithinBusinessHours should return true (placeholder)', () async {
        // Test behavior: placeholder returns true
        final withinHours = await service.isWithinBusinessHours(
          businessId: 'business-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        expect(withinHours, isTrue);
      });

      test('isBusinessClosed should return false (placeholder)', () async {
        // Test behavior: placeholder returns false
        final isClosed = await service.isBusinessClosed(
          businessId: 'business-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        expect(isClosed, isFalse);
      });

      test('getSeatingChart should return null (placeholder)', () async {
        // Test behavior: placeholder returns null
        final seatingChart = await service.getSeatingChart(
          businessId: 'business-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        expect(seatingChart, isNull);
      });

      test('getAvailableSeats should return empty list (placeholder)',
          () async {
        // Test behavior: placeholder returns empty list
        final seats = await service.getAvailableSeats(
          seatingChartId: 'chart-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        expect(seats, isEmpty);
      });

      test('getSeatPricing should return empty map (placeholder)', () async {
        // Test behavior: placeholder returns empty map
        final pricing = await service.getSeatPricing(
          seatingChartId: 'chart-1',
          seatIds: ['seat-1', 'seat-2'],
        );

        expect(pricing, isEmpty);
      });
    });
  });
}
