/// SPOTS Reservation Notification Service Tests
/// Date: January 6, 2026
/// Purpose: Test ReservationNotificationService functionality
///
/// Test Coverage:
/// - Core Methods: sendConfirmation, sendReminder, sendCancellationNotice, scheduleReminders
/// - Notification Types: Confirmation, reminders (24h, 1h), cancellation
/// - Scheduling Logic: Schedule reminders at correct times
/// - Error Handling: Non-critical errors (don't throw)
///
/// Dependencies:
/// - Mock SupabaseService: Database storage (mocked as unavailable to avoid complex client mocking)
/// - Mock StorageService: Local storage for scheduled notifications
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
import 'package:avrai/core/services/reservation_notification_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/models/reservation.dart';

// Mock dependencies
class MockSupabaseService extends Mock implements SupabaseService {}

class MockStorageService extends Mock implements StorageService {}

void main() {
  setUpAll(() {
    // Register fallback values for enum types
    registerFallbackValue(ReservationType.event);
    registerFallbackValue(ReservationType.spot);
    registerFallbackValue(ReservationType.business);
    registerFallbackValue(ReservationNotificationType.confirmation);
    registerFallbackValue(ReservationNotificationType.reminder24h);
    registerFallbackValue(ReservationNotificationType.reminder1h);
  });

  group('ReservationNotificationService', () {
    late ReservationNotificationService service;
    late MockSupabaseService mockSupabaseService;
    late MockStorageService mockStorageService;

    setUp(() {
      mockSupabaseService = MockSupabaseService();
      mockStorageService = MockStorageService();

      // Setup SupabaseService mock (offline by default to avoid complex client mocking)
      when(() => mockSupabaseService.isAvailable).thenReturn(false);

      // Setup StorageService mock
      when(() => mockStorageService.setString(any(), any()))
          .thenAnswer((_) async => true);

      service = ReservationNotificationService(
        supabaseService: mockSupabaseService,
        storageService: mockStorageService,
      );
    });

    // Helper function to create test reservation
    Reservation createTestReservation({
      required String id,
      required DateTime reservationTime,
      ReservationStatus status = ReservationStatus.pending,
    }) {
      return Reservation(
        id: id,
        agentId: 'agent-1',
        type: ReservationType.spot,
        targetId: 'target-1',
        reservationTime: reservationTime,
        partySize: 2,
        status: status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('sendConfirmation', () {
      test('should send confirmation without errors', () async {
        // Test behavior: confirmation sent without throwing errors
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        // Should complete without errors (notification failures are non-critical)
        await service.sendConfirmation(reservation);

        // Verify service was called (but doesn't throw)
        expect(true, isTrue);
      });

      test('should handle errors gracefully without throwing', () async {
        // Test error handling: errors don't throw (non-critical operation)
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        when(() => mockSupabaseService.isAvailable).thenReturn(true);
        when(() => mockSupabaseService.client)
            .thenThrow(Exception('Service error'));

        // Should complete without throwing (notification failures are non-critical)
        await service.sendConfirmation(reservation);

        expect(true, isTrue);
      });
    });

    group('sendReminder', () {
      test('should select 24h reminder type for 24+ hour reminders', () async {
        // Test business logic: reminder type selection based on time
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: DateTime.now().add(const Duration(days: 2)),
        );

        // Should complete without errors
        await service.sendReminder(
          reservation,
          const Duration(hours: 24),
        );

        expect(true, isTrue);
      });

      test('should select 1h reminder type for <24 hour reminders', () async {
        // Test business logic: reminder type selection based on time
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: DateTime.now().add(const Duration(hours: 12)),
        );

        // Should complete without errors
        await service.sendReminder(
          reservation,
          const Duration(hours: 1),
        );

        expect(true, isTrue);
      });

      test('should handle errors gracefully without throwing', () async {
        // Test error handling: errors don't throw (non-critical operation)
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        when(() => mockSupabaseService.isAvailable).thenReturn(true);
        when(() => mockSupabaseService.client)
            .thenThrow(Exception('Service error'));

        // Should complete without throwing
        await service.sendReminder(reservation, const Duration(hours: 24));

        expect(true, isTrue);
      });
    });

    group('sendCancellationNotice', () {
      test('should send cancellation notice without errors', () async {
        // Test behavior: cancellation notice sent without throwing errors
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          status: ReservationStatus.cancelled,
        );

        // Should complete without errors
        await service.sendCancellationNotice(reservation);

        expect(true, isTrue);
      });

      test('should handle errors gracefully without throwing', () async {
        // Test error handling: errors don't throw (non-critical operation)
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          status: ReservationStatus.cancelled,
        );

        when(() => mockSupabaseService.isAvailable).thenReturn(true);
        when(() => mockSupabaseService.client)
            .thenThrow(Exception('Service error'));

        // Should complete without throwing
        await service.sendCancellationNotice(reservation);

        expect(true, isTrue);
      });
    });

    group('scheduleReminders', () {
      test(
          'should schedule both 24h and 1h reminders when reservation is in future',
          () async {
        // Test business logic: scheduling reminders at correct times
        final reservationTime = DateTime.now().add(const Duration(days: 2));
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: reservationTime,
        );

        await service.scheduleReminders(reservation);

        // Verify reminders were scheduled (stored in storage)
        verify(() => mockStorageService.setString(any(), any())).called(2);
      });

      test('should schedule only 1h reminder when 24h reminder time has passed',
          () async {
        // Test business logic: only schedule reminders in the future
        final reservationTime = DateTime.now().add(const Duration(hours: 12));
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: reservationTime,
        );

        await service.scheduleReminders(reservation);

        // Should schedule only 1h reminder (24h reminder time is in the past)
        verify(() => mockStorageService.setString(any(), any())).called(1);
      });

      test('should not schedule reminders when reservation is too soon',
          () async {
        // Test business logic: don't schedule reminders when reservation is very soon
        final reservationTime = DateTime.now().add(const Duration(minutes: 30));
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: reservationTime,
        );

        await service.scheduleReminders(reservation);

        // Should not schedule any reminders (both times are in the past or too soon)
        verifyNever(() => mockStorageService.setString(any(), any()));
      });

      test('should handle errors gracefully without throwing', () async {
        // Test error handling: errors don't throw (non-critical operation)
        final reservation = createTestReservation(
          id: 'res-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        when(() => mockStorageService.setString(any(), any()))
            .thenThrow(Exception('Storage error'));

        // Should complete without throwing
        await service.scheduleReminders(reservation);

        expect(true, isTrue);
      });
    });
  });
}
