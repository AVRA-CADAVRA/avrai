/// SPOTS Reservation Model Tests
/// Date: January 6, 2026
/// Purpose: Test Reservation model functionality
///
/// Test Coverage:
/// - Business Logic: canModify, canCancel, isWithinCancellationWindow
/// - JSON Serialization: Round-trip serialization/deserialization
/// - copyWith: Immutability and field updates
///
/// ⚠️  TEST QUALITY GUIDELINES:
/// ✅ DO: Test business logic, error handling, async operations, side effects
/// ✅ DO: Test service behavior and interactions with dependencies
/// ✅ DO: Consolidate related checks into comprehensive test blocks
///
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

void main() {
  group('Reservation Model', () {
    late DateTime testDate;
    late AtomicTimestamp testAtomicTimestamp;

    setUp(() {
      testDate = DateTime(2026, 1, 15, 18, 0);
      testAtomicTimestamp = AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: testDate,
      );
    });

    group('Business Logic', () {
      test('canModify should return false when modification limit reached', () {
        // Test business logic: modification limit enforcement
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          modificationCount: 3, // Max modifications reached
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.canModify(), isFalse);
      });

      test(
          'canModify should return false when within 1 hour of reservation time',
          () {
        // Test business logic: time restriction for modifications
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: DateTime.now()
              .add(const Duration(minutes: 30)), // 30 minutes from now
          partySize: 2,
          modificationCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.canModify(), isFalse);
      });

      test('canModify should return false when reservation is cancelled', () {
        // Test business logic: can't modify cancelled reservations
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          status: ReservationStatus.cancelled,
          modificationCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.canModify(), isFalse);
      });

      test('canModify should return false when reservation is completed', () {
        // Test business logic: can't modify completed reservations
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          status: ReservationStatus.completed,
          modificationCount: 0,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.canModify(), isFalse);
      });

      test('canModify should return true when all conditions met', () {
        // Test business logic: modifications allowed when conditions met
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          modificationCount: 1,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.canModify(), isTrue);
      });

      test('canCancel should return false when reservation is cancelled', () {
        // Test business logic: can't cancel already cancelled reservations
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          status: ReservationStatus.cancelled,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.canCancel(), isFalse);
      });

      test('canCancel should return false when reservation is completed', () {
        // Test business logic: can't cancel completed reservations
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          status: ReservationStatus.completed,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.canCancel(), isFalse);
      });

      test('canCancel should return true when cancellation is allowed', () {
        // Test business logic: cancellation allowed when not cancelled/completed
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          status: ReservationStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.canCancel(), isTrue);
      });

      test('isWithinCancellationWindow should return false when no policy', () {
        // Test business logic: no window when no policy
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          cancellationPolicy: null,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.isWithinCancellationWindow(), isFalse);
      });

      test(
          'isWithinCancellationWindow should return true when within policy window',
          () {
        // Test business logic: within window when time exceeds policy hours
        final policy = const CancellationPolicy(hoursBefore: 24);
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: DateTime.now()
              .add(const Duration(hours: 48)), // 48 hours from now
          partySize: 2,
          cancellationPolicy: policy,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.isWithinCancellationWindow(), isTrue);
      });

      test(
          'isWithinCancellationWindow should return false when outside policy window',
          () {
        // Test business logic: outside window when time less than policy hours
        final policy = const CancellationPolicy(hoursBefore: 24);
        final reservation = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: DateTime.now()
              .add(const Duration(hours: 12)), // 12 hours from now
          partySize: 2,
          cancellationPolicy: policy,
          createdAt: testDate,
          updatedAt: testDate,
        );

        expect(reservation.isWithinCancellationWindow(), isFalse);
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize without data loss (round-trip)',
          () {
        // Test business logic: round-trip preserves all critical data
        final original = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          userData: {'name': 'Test User', 'phone': '555-1234'},
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          ticketCount: 2,
          specialRequests: 'Window seat please',
          status: ReservationStatus.confirmed,
          ticketPrice: 50.0,
          depositAmount: 10.0,
          seatId: 'seat-1',
          cancellationPolicy: const CancellationPolicy(hoursBefore: 24),
          modificationCount: 1,
          lastModifiedAt: testDate.add(const Duration(days: 1)),
          disputeStatus: DisputeStatus.none,
          atomicTimestamp: testAtomicTimestamp,
          metadata: {'source': 'app', 'platform': 'ios'},
          createdAt: testDate,
          updatedAt: testDate,
        );

        final json = original.toJson();
        final restored = Reservation.fromJson(json);

        expect(restored.id, equals(original.id));
        expect(restored.agentId, equals(original.agentId));
        expect(restored.userData, equals(original.userData));
        expect(restored.type, equals(original.type));
        expect(restored.targetId, equals(original.targetId));
        expect(restored.reservationTime, equals(original.reservationTime));
        expect(restored.partySize, equals(original.partySize));
        expect(restored.ticketCount, equals(original.ticketCount));
        expect(restored.specialRequests, equals(original.specialRequests));
        expect(restored.status, equals(original.status));
        expect(restored.ticketPrice, equals(original.ticketPrice));
        expect(restored.depositAmount, equals(original.depositAmount));
        expect(restored.seatId, equals(original.seatId));
        expect(restored.modificationCount, equals(original.modificationCount));
        expect(restored.metadata, equals(original.metadata));
        expect(restored.canModify(), equals(original.canModify()));
        expect(restored.canCancel(), equals(original.canCancel()));
      });

      test('should handle missing and null fields with sensible defaults', () {
        // Test error handling: default values for missing fields
        final minimalJson = {
          'id': 'res-1',
          'agentId': 'agent-1',
          'type': 'spot',
          'targetId': 'target-1',
          'reservationTime':
              testDate.add(const Duration(days: 7)).toIso8601String(),
          'partySize': 2,
          'status': 'pending',
          'disputeStatus': 'none',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final reservation = Reservation.fromJson(minimalJson);

        expect(reservation.ticketCount, equals(1)); // Default ticket count
        expect(reservation.modificationCount,
            equals(0)); // Default modification count
        expect(reservation.userData, isNull);
        expect(reservation.specialRequests, isNull);
        expect(reservation.ticketPrice, isNull);
        expect(reservation.cancellationPolicy, isNull);
        expect(reservation.metadata, isEmpty);
        expect(reservation.disputeStatus, equals(DisputeStatus.none));
      });

      test('should handle invalid enum values with defaults', () {
        // Test error handling: invalid enum values default correctly
        final invalidJson = {
          'id': 'res-1',
          'agentId': 'agent-1',
          'type': 'invalid_type',
          'targetId': 'target-1',
          'reservationTime':
              testDate.add(const Duration(days: 7)).toIso8601String(),
          'partySize': 2,
          'status': 'invalid_status',
          'disputeStatus': 'invalid_dispute',
          'createdAt': testDate.toIso8601String(),
          'updatedAt': testDate.toIso8601String(),
        };

        final reservation = Reservation.fromJson(invalidJson);

        expect(reservation.type, equals(ReservationType.spot)); // Default type
        expect(reservation.status,
            equals(ReservationStatus.pending)); // Default status
        expect(reservation.disputeStatus,
            equals(DisputeStatus.none)); // Default dispute status
      });
    });

    group('copyWith', () {
      test('should create immutable copy with updated fields', () {
        // Test business logic: immutability preserved
        final original = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          status: ReservationStatus.pending,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          status: ReservationStatus.confirmed,
          specialRequests: 'Window seat',
        );

        // Test immutability (business logic)
        expect(original.status, isNot(equals(ReservationStatus.confirmed)));
        expect(updated.status, equals(ReservationStatus.confirmed));
        expect(updated.specialRequests, equals('Window seat'));
        expect(updated.id, equals(original.id)); // Unchanged fields preserved
        expect(updated.agentId, equals(original.agentId));
        expect(updated.type, equals(original.type));
      });

      test('should preserve business logic after copyWith', () {
        // Test business logic: canModify behavior preserved after copyWith
        final original = Reservation(
          id: 'res-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: testDate.add(const Duration(days: 7)),
          partySize: 2,
          modificationCount: 2,
          createdAt: testDate,
          updatedAt: testDate,
        );

        final updated = original.copyWith(
          modificationCount: 3, // Max modifications
        );

        expect(original.canModify(), isTrue);
        expect(updated.canModify(), isFalse); // Modification limit reached
      });
    });
  });
}
