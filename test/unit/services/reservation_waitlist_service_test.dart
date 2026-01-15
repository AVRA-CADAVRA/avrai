/// SPOTS Reservation Waitlist Service Tests
/// Date: January 6, 2026
/// Purpose: Test ReservationWaitlistService functionality
///
/// Test Coverage:
/// - Core Methods: addToWaitlist, getWaitlistPosition, findWaitlistPosition, promoteWaitlistEntries, checkExpiredPromotions
/// - Waitlist Operations: Add entry, position calculation, promotion, expiry
/// - Error Handling: Service errors, graceful degradation
/// - Privacy: Uses agentId (not userId) for internal tracking
///
/// Dependencies:
/// - Mock AtomicClockService: Atomic timestamp generation
/// - Mock AgentIdService: Agent ID resolution
/// - Mock StorageService: Local storage (in-memory map for tests)
/// - Mock SupabaseService: Cloud sync availability
/// - Mock ReservationNotificationService: Notification sending (optional)
///
/// ⚠️  TEST QUALITY GUIDELINES:
/// ✅ DO: Test business logic, error handling, async operations, side effects
/// ✅ DO: Test service behavior and interactions with dependencies
/// ✅ DO: Consolidate related checks into comprehensive test blocks
///
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:avrai/core/services/reservation_waitlist_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/services/reservation_notification_service.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

// Mock dependencies
class MockAtomicClockService extends Mock implements AtomicClockService {}
class MockAgentIdService extends Mock implements AgentIdService {}
class MockStorageService extends Mock implements StorageService {}
class MockSupabaseService extends Mock implements SupabaseService {}
class MockReservationNotificationService extends Mock implements ReservationNotificationService {}

void main() {
  setUpAll(() {
    // Register fallback values for enum types
    registerFallbackValue(ReservationType.event);
    registerFallbackValue(ReservationType.spot);
    registerFallbackValue(ReservationType.business);
    registerFallbackValue(WaitlistStatus.waiting);
    registerFallbackValue(WaitlistStatus.promoted);
  });

  group('ReservationWaitlistService', () {
    late ReservationWaitlistService service;
    late MockAtomicClockService mockAtomicClock;
    late MockAgentIdService mockAgentIdService;
    late MockStorageService mockStorageService;
    late MockSupabaseService mockSupabaseService;
    late MockReservationNotificationService? mockNotificationService;

    // In-memory storage for tests
    final Map<String, String> storageMap = {};

    setUp(() {
      mockAtomicClock = MockAtomicClockService();
      mockAgentIdService = MockAgentIdService();
      mockStorageService = MockStorageService();
      mockSupabaseService = MockSupabaseService();
      mockNotificationService = null;

      // Reset storage
      storageMap.clear();

      // Setup StorageService mock
      when(() => mockStorageService.setString(any(), any()))
          .thenAnswer((invocation) async {
        final key = invocation.positionalArguments[0] as String;
        final value = invocation.positionalArguments[1] as String;
        storageMap[key] = value;
        return true;
      });

      when(() => mockStorageService.getString(any()))
          .thenAnswer((invocation) {
        final key = invocation.positionalArguments[0] as String;
        return storageMap[key];
      });

      when(() => mockStorageService.getKeys())
          .thenAnswer((_) => storageMap.keys.toList());

      // Setup SupabaseService mock (offline by default)
      when(() => mockSupabaseService.isAvailable).thenReturn(false);

      service = ReservationWaitlistService(
        atomicClock: mockAtomicClock,
        agentIdService: mockAgentIdService,
        storageService: mockStorageService,
        supabaseService: mockSupabaseService,
        notificationService: mockNotificationService,
      );
    });

    // Helper function to create atomic timestamp
    AtomicTimestamp createAtomicTimestamp({
      DateTime? serverTime,
    }) {
      final time = serverTime ?? DateTime.now();
      return AtomicTimestamp.now(
        precision: TimePrecision.millisecond,
        serverTime: time,
      );
    }

    // Helper function to create waitlist entry
    WaitlistEntry createWaitlistEntry({
      required String id,
      required String agentId,
      required ReservationType type,
      required String targetId,
      required DateTime reservationTime,
      required int ticketCount,
      AtomicTimestamp? entryTimestamp,
      WaitlistStatus status = WaitlistStatus.waiting,
      int? position,
    }) {
      return WaitlistEntry(
        id: id,
        agentId: agentId,
        type: type,
        targetId: targetId,
        reservationTime: reservationTime,
        ticketCount: ticketCount,
        entryTimestamp: entryTimestamp ?? createAtomicTimestamp(),
        status: status,
        position: position,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    group('addToWaitlist', () {
      test('should add entry to waitlist and store locally', () async {
        // Test business logic: add entry to waitlist
        const userId = 'user-1';
        const agentId = 'agent-1';
        const targetId = 'target-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        const ticketCount = 2;

        final atomicTimestamp = createAtomicTimestamp();

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockAtomicClock.getTicketPurchaseTimestamp())
            .thenAnswer((_) async => atomicTimestamp);

        final entry = await service.addToWaitlist(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          ticketCount: ticketCount,
        );

        expect(entry.agentId, equals(agentId));
        expect(entry.type, equals(ReservationType.spot));
        expect(entry.targetId, equals(targetId));
        expect(entry.reservationTime, equals(reservationTime));
        expect(entry.ticketCount, equals(ticketCount));
        expect(entry.status, equals(WaitlistStatus.waiting));
        expect(entry.entryTimestamp, equals(atomicTimestamp));
        expect(entry.id, isNotEmpty);

        // Verify entry was stored
        verify(() => mockStorageService.setString(any(), any())).called(greaterThan(0));
        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(() => mockAtomicClock.getTicketPurchaseTimestamp()).called(1);
      });

      test('should use agentId (not userId) for privacy protection', () async {
        // Test privacy: verify agentId is used (not userId)
        const userId = 'user-1';
        const agentId = 'agent-1';
        final atomicTimestamp = createAtomicTimestamp();

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockAtomicClock.getTicketPurchaseTimestamp())
            .thenAnswer((_) async => atomicTimestamp);

        final entry = await service.addToWaitlist(
          userId: userId,
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          ticketCount: 2,
        );

        // Verify agentId (not userId) is used
        expect(entry.agentId, equals(agentId));
        expect(entry.agentId, isNot(equals(userId)));

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
      });

      test('should handle storage errors gracefully', () async {
        // Test error handling: storage errors
        const userId = 'user-1';
        final atomicTimestamp = createAtomicTimestamp();

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => 'agent-1');

        when(() => mockAtomicClock.getTicketPurchaseTimestamp())
            .thenAnswer((_) async => atomicTimestamp);

        when(() => mockStorageService.setString(any(), any()))
            .thenThrow(Exception('Storage error'));

        expect(
          () => service.addToWaitlist(
            userId: userId,
            type: ReservationType.spot,
            targetId: 'target-1',
            reservationTime: DateTime.now().add(const Duration(days: 7)),
            ticketCount: 2,
          ),
          throwsException,
        );
      });
    });

    group('getWaitlistPosition', () {
      test('should return position when entry exists', () async {
        // Test business logic: get position for existing entry
        const userId = 'user-1';
        const agentId = 'agent-1';
        const entryId = 'entry-1';
        const targetId = 'target-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final entry = createWaitlistEntry(
          id: entryId,
          agentId: agentId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          ticketCount: 2,
          position: 1,
        );

        // Store entry in storage
        storageMap['waitlist_$entryId'] = jsonEncode(entry.toJson());

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        final position = await service.getWaitlistPosition(
          userId: userId,
          waitlistEntryId: entryId,
        );

        expect(position, equals(1));

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(() => mockStorageService.getString('waitlist_$entryId')).called(1);
      });

      test('should return null when entry does not exist', () async {
        // Test error handling: entry not found
        const userId = 'user-1';
        const entryId = 'nonexistent';

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => 'agent-1');

        when(() => mockStorageService.getString('waitlist_$entryId'))
            .thenReturn(null);

        final position = await service.getWaitlistPosition(
          userId: userId,
          waitlistEntryId: entryId,
        );

        expect(position, isNull);

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
      });

      test('should return null when agentId mismatch (privacy protection)', () async {
        // Test privacy: agentId mismatch returns null
        const userId = 'user-1';
        const agentId = 'agent-1';
        const wrongAgentId = 'agent-2';
        const entryId = 'entry-1';

        final entry = createWaitlistEntry(
          id: entryId,
          agentId: wrongAgentId, // Different agentId
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          ticketCount: 2,
        );

        // Store entry in storage
        storageMap['waitlist_$entryId'] = jsonEncode(entry.toJson());

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        final position = await service.getWaitlistPosition(
          userId: userId,
          waitlistEntryId: entryId,
        );

        // Privacy protection: should return null for agentId mismatch
        expect(position, isNull);

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
      });

      test('should handle errors gracefully', () async {
        // Test error handling: service errors
        const userId = 'user-1';

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenThrow(Exception('Service error'));

        final position = await service.getWaitlistPosition(
          userId: userId,
          waitlistEntryId: 'entry-1',
        );

        expect(position, isNull);
      });
    });

    group('findWaitlistPosition', () {
      test('should return position when user is on waitlist', () async {
        // Test business logic: find position by target parameters
        const userId = 'user-1';
        const agentId = 'agent-1';
        const targetId = 'target-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final entry = createWaitlistEntry(
          id: 'entry-1',
          agentId: agentId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          ticketCount: 2,
          position: 1,
        );

        // Store entry in storage
        storageMap['waitlist_entry-1'] = jsonEncode(entry.toJson());
        when(() => mockStorageService.getKeys())
            .thenReturn(['waitlist_entry-1']);

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        final position = await service.findWaitlistPosition(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
        );

        expect(position, equals(1));

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
      });

      test('should return null when user is not on waitlist', () async {
        // Test error handling: user not on waitlist
        const userId = 'user-1';

        when(() => mockStorageService.getKeys()).thenReturn([]);

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => 'agent-1');

        final position = await service.findWaitlistPosition(
          userId: userId,
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        expect(position, isNull);
      });

      test('should handle errors gracefully', () async {
        // Test error handling: service errors
        const userId = 'user-1';

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenThrow(Exception('Service error'));

        final position = await service.findWaitlistPosition(
          userId: userId,
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        expect(position, isNull);
      });
    });

    group('promoteWaitlistEntries', () {
      test('should promote entries up to available capacity', () async {
        // Test business logic: promote entries when capacity available
        const targetId = 'target-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        const availableCapacity = 5;

        final entry1 = createWaitlistEntry(
          id: 'entry-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          ticketCount: 2,
          entryTimestamp: createAtomicTimestamp(serverTime: DateTime(2026, 1, 1, 10, 0)),
        );

        final entry2 = createWaitlistEntry(
          id: 'entry-2',
          agentId: 'agent-2',
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          ticketCount: 2,
          entryTimestamp: createAtomicTimestamp(serverTime: DateTime(2026, 1, 1, 10, 1)),
        );

        // Store entries in storage
        storageMap['waitlist_entry-1'] = jsonEncode(entry1.toJson());
        storageMap['waitlist_entry-2'] = jsonEncode(entry2.toJson());
        when(() => mockStorageService.getKeys())
            .thenReturn(['waitlist_entry-1', 'waitlist_entry-2']);

        final promoted = await service.promoteWaitlistEntries(
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          availableCapacity: availableCapacity,
        );

        expect(promoted.length, equals(2));
        expect(promoted[0].status, equals(WaitlistStatus.promoted));
        expect(promoted[1].status, equals(WaitlistStatus.promoted));
        expect(promoted[0].expiresAt, isNotNull);
        expect(promoted[1].expiresAt, isNotNull);

        verify(() => mockStorageService.setString(any(), any())).called(greaterThan(0));
      });

      test('should promote entries in order of atomic timestamp', () async {
        // Test business logic: first-come-first-served ordering
        const targetId = 'target-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        const availableCapacity = 3;

        // Entry 2 comes first (earlier timestamp)
        final entry2 = createWaitlistEntry(
          id: 'entry-2',
          agentId: 'agent-2',
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          ticketCount: 1,
          entryTimestamp: createAtomicTimestamp(serverTime: DateTime(2026, 1, 1, 10, 0)),
        );

        // Entry 1 comes second (later timestamp)
        final entry1 = createWaitlistEntry(
          id: 'entry-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          ticketCount: 1,
          entryTimestamp: createAtomicTimestamp(serverTime: DateTime(2026, 1, 1, 10, 1)),
        );

        // Store entries in storage
        storageMap['waitlist_entry-1'] = jsonEncode(entry1.toJson());
        storageMap['waitlist_entry-2'] = jsonEncode(entry2.toJson());
        when(() => mockStorageService.getKeys())
            .thenReturn(['waitlist_entry-1', 'waitlist_entry-2']);

        final promoted = await service.promoteWaitlistEntries(
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          availableCapacity: availableCapacity,
        );

        expect(promoted.length, equals(2));
        // Entry 2 should be promoted first (earlier timestamp)
        expect(promoted[0].id, equals('entry-2'));
        expect(promoted[1].id, equals('entry-1'));
      });

      test('should handle errors gracefully and return empty list', () async {
        // Test error handling: service errors
        when(() => mockStorageService.getKeys())
            .thenThrow(Exception('Storage error'));

        final promoted = await service.promoteWaitlistEntries(
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
          availableCapacity: 5,
        );

        expect(promoted, isEmpty);
      });
    });

    group('checkExpiredPromotions', () {
      test('should mark expired promotions as expired', () async {
        // Test business logic: expire promotions past expiry time
        const targetId = 'target-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final now = DateTime.now();
        final expiredTime = now.subtract(const Duration(hours: 3)); // 3 hours ago

        final entry = createWaitlistEntry(
          id: 'entry-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          ticketCount: 2,
          status: WaitlistStatus.promoted,
          entryTimestamp: createAtomicTimestamp(),
        ).copyWith(
          expiresAt: expiredTime, // Expired
          promotedAt: expiredTime.subtract(const Duration(hours: 2)),
        );

        // Store entry in storage
        storageMap['waitlist_entry-1'] = jsonEncode(entry.toJson());
        when(() => mockStorageService.getKeys())
            .thenReturn(['waitlist_entry-1']);

        final expired = await service.checkExpiredPromotions(
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
        );

        expect(expired.length, equals(1));
        expect(expired[0].status, equals(WaitlistStatus.expired));

        verify(() => mockStorageService.setString(any(), any())).called(greaterThan(0));
      });

      test('should not mark non-expired promotions as expired', () async {
        // Test business logic: don't expire promotions before expiry time
        const targetId = 'target-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final futureTime = DateTime.now().add(const Duration(hours: 1)); // 1 hour from now

        final entry = createWaitlistEntry(
          id: 'entry-1',
          agentId: 'agent-1',
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          ticketCount: 2,
          status: WaitlistStatus.promoted,
          entryTimestamp: createAtomicTimestamp(),
        ).copyWith(
          expiresAt: futureTime, // Not expired yet
          promotedAt: DateTime.now(),
        );

        // Store entry in storage
        storageMap['waitlist_entry-1'] = jsonEncode(entry.toJson());
        when(() => mockStorageService.getKeys())
            .thenReturn(['waitlist_entry-1']);

        final expired = await service.checkExpiredPromotions(
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
        );

        expect(expired, isEmpty);
      });

      test('should handle errors gracefully and return empty list', () async {
        // Test error handling: service errors
        when(() => mockStorageService.getKeys())
            .thenThrow(Exception('Storage error'));

        final expired = await service.checkExpiredPromotions(
          type: ReservationType.spot,
          targetId: 'target-1',
          reservationTime: DateTime.now().add(const Duration(days: 7)),
        );

        expect(expired, isEmpty);
      });
    });
  });
}
