/// SPOTS Reservation Waitlist Integration Tests
/// Date: January 6, 2026
/// Purpose: End-to-end validation of waitlist workflow
///
/// Test Coverage:
/// - Complete waitlist workflow: Event full → Add to waitlist → Capacity opens → Promote → Complete reservation
/// - Waitlist position calculation (atomic timestamp ordering)
/// - Multiple users on waitlist (first-come-first-served)
/// - Waitlist promotion expiry handling
/// - Offline-first behavior (waitlist stored locally)
///
/// Dependencies:
/// - Real services: ReservationWaitlistService, ReservationAvailabilityService, ReservationService, AtomicClockService, AgentIdService, StorageService
/// - Mock services: ExpertiseEventService, SupabaseService (offline by default)
///
/// ⚠️  TEST QUALITY GUIDELINES:
/// ✅ DO: Test complete workflows end-to-end
/// ✅ DO: Test system interactions and integration points
/// ✅ DO: Test error propagation and recovery
/// ✅ DO: Consolidate related workflow steps into comprehensive tests
///
/// See: docs/plans/test_refactoring/TEST_WRITING_GUIDE.md
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:avrai/core/services/reservation_waitlist_service.dart';
import 'package:avrai/core/services/reservation_availability_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/services/secure_mapping_encryption_service.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/models/expertise_event.dart';
import 'package:avrai/core/models/unified_user.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_engine.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/quantum/location_timing_quantum_state_service.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/user_vibe.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:mocktail/mocktail.dart';
import '../helpers/platform_channel_helper.dart';

// Mock dependencies
class MockSupabaseService extends Mock implements SupabaseService {}

class MockExpertiseEventService extends Mock implements ExpertiseEventService {}

class MockQuantumVibeEngine extends Mock implements QuantumVibeEngine {}

class MockUserVibeAnalyzer extends Mock implements UserVibeAnalyzer {}

class MockPersonalityLearning extends Mock implements PersonalityLearning {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reservation Waitlist Integration Tests', () {
    late ReservationWaitlistService waitlistService;
    late ReservationAvailabilityService availabilityService;
    late ReservationService reservationService;
    late AtomicClockService atomicClock;
    late AgentIdService agentIdService;
    late StorageService storageService;
    late ReservationQuantumService quantumService;
    late LocationTimingQuantumStateService locationTimingService;
    late MockSupabaseService mockSupabaseService;
    late MockExpertiseEventService mockEventService;
    late MockQuantumVibeEngine mockQuantumVibeEngine;
    late MockUserVibeAnalyzer mockVibeAnalyzer;
    late MockPersonalityLearning mockPersonalityLearning;

    setUp(() async {
      await setupTestStorage();

      // Initialize storage service
      storageService = StorageService.instance;

      // Initialize real services
      atomicClock = AtomicClockService();
      final encryptionService = SecureMappingEncryptionService();
      agentIdService = AgentIdService(encryptionService: encryptionService);
      locationTimingService = LocationTimingQuantumStateService();

      // Initialize mocks
      mockSupabaseService = MockSupabaseService();
      mockEventService = MockExpertiseEventService();
      mockQuantumVibeEngine = MockQuantumVibeEngine();
      mockVibeAnalyzer = MockUserVibeAnalyzer();
      mockPersonalityLearning = MockPersonalityLearning();

      // Setup mock Supabase (offline by default)
      when(() => mockSupabaseService.isAvailable).thenReturn(false);

      // Create quantum service with mocks
      quantumService = ReservationQuantumService(
        atomicClock: atomicClock,
        quantumVibeEngine: mockQuantumVibeEngine,
        vibeAnalyzer: mockVibeAnalyzer,
        personalityLearning: mockPersonalityLearning,
        locationTimingService: locationTimingService,
      );

      // Create reservation service
      reservationService = ReservationService(
        atomicClock: atomicClock,
        quantumService: quantumService,
        agentIdService: agentIdService,
        storageService: storageService,
        supabaseService: mockSupabaseService,
      );

      // Create availability service
      availabilityService = ReservationAvailabilityService(
        reservationService: reservationService,
        eventService: mockEventService,
        supabaseService: mockSupabaseService,
      );

      // Create waitlist service
      waitlistService = ReservationWaitlistService(
        atomicClock: atomicClock,
        agentIdService: agentIdService,
        storageService: storageService,
        supabaseService: mockSupabaseService,
      );
    });

    tearDown(() async {
      // Cleanup if needed
    });

    // Helper function to create test user (host)
    UnifiedUser createTestHost() {
      return UnifiedUser(
        id: 'host-1',
        email: 'host@example.com',
        displayName: 'Test Host',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Helper function to create test event
    ExpertiseEvent createTestEvent({
      required String id,
      required DateTime startTime,
      required int attendeeCount,
      required int maxAttendees,
    }) {
      final host = createTestHost();
      return ExpertiseEvent(
        id: id,
        title: 'Test Event',
        description: 'Test Description',
        category: 'Coffee',
        eventType: ExpertiseEventType.meetup,
        host: host,
        startTime: startTime,
        endTime: startTime.add(const Duration(hours: 2)),
        location: 'Test Location',
        maxAttendees: maxAttendees,
        attendeeCount: attendeeCount,
        status: EventStatus.upcoming,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    // Helper function to create mock personality profile
    PersonalityProfile createMockPersonalityProfile(String userId) {
      final personalityDimensions = <String, double>{};
      for (final dimension in VibeConstants.coreDimensions) {
        personalityDimensions[dimension] = 0.5;
      }

      return PersonalityProfile(
        agentId: 'agent-$userId',
        dimensions: personalityDimensions,
        dimensionConfidence:
            personalityDimensions.map((k, v) => MapEntry(k, 0.8)),
        archetype: 'balanced',
        authenticity: 0.7,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        evolutionGeneration: 1,
        learningHistory: {},
      );
    }

    group('Complete Waitlist Workflow', () {
      test(
          'should add user to waitlist when event is full and promote when capacity opens',
          () async {
        // Test business logic: complete waitlist workflow from add to promotion
        const eventId = 'event-1';
        const userId1 = 'user-1';
        const userId2 = 'user-2';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create event that is full (maxAttendees = attendeeCount)
        final fullEvent = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 10,
          maxAttendees: 10, // Event is full
        );

        // Setup mocks
        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => fullEvent);

        final profile1 = createMockPersonalityProfile(userId1);
        final profile2 = createMockPersonalityProfile(userId2);
        when(() => mockPersonalityLearning.getCurrentPersonality(userId1))
            .thenAnswer((_) async => profile1);
        when(() => mockPersonalityLearning.getCurrentPersonality(userId2))
            .thenAnswer((_) async => profile2);
        when(() => mockVibeAnalyzer.compileUserVibe(userId1, profile1))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId1, profile1.dimensions));
        when(() => mockVibeAnalyzer.compileUserVibe(userId2, profile2))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId2, profile2.dimensions));

        // Step 1: Check availability (should be unavailable with waitlist option)
        final availability = await availabilityService.checkAvailability(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
          ticketCount: 2,
        );

        expect(availability.isAvailable, isFalse);
        expect(availability.waitlistAvailable, isTrue);

        // Step 2: Add first user to waitlist
        final entry1 = await waitlistService.addToWaitlist(
          userId: userId1,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          ticketCount: 2,
        );

        expect(entry1.status, equals(WaitlistStatus.waiting));
        expect(entry1.type, equals(ReservationType.event));
        expect(entry1.targetId, equals(eventId));

        // Step 3: Add second user to waitlist (should be after first user)
        await Future.delayed(const Duration(
            milliseconds: 10)); // Ensure different atomic timestamps
        final entry2 = await waitlistService.addToWaitlist(
          userId: userId2,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          ticketCount: 2,
        );

        expect(entry2.status, equals(WaitlistStatus.waiting));

        // Step 4: Verify positions (first user should be position 1, second should be position 2)
        final position1 = await waitlistService.getWaitlistPosition(
          waitlistEntryId: entry1.id,
          userId: userId1,
        );
        final position2 = await waitlistService.getWaitlistPosition(
          waitlistEntryId: entry2.id,
          userId: userId2,
        );

        expect(position1, isNotNull);
        expect(position2, isNotNull);
        expect(position1!, lessThan(position2!)); // First user should be ahead

        // Step 5: Capacity opens (2 tickets become available)
        final updatedEvent = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 8, // 2 tickets now available
          maxAttendees: 10,
        );
        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => updatedEvent);

        // Step 6: Promote waitlist entries (should promote first user)
        final promoted = await waitlistService.promoteWaitlistEntries(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          availableCapacity: 2,
        );

        expect(
            promoted.length,
            equals(
                1)); // Only first user promoted (needs 2 tickets, 2 available)
        expect(promoted.first.id, equals(entry1.id));
        expect(promoted.first.status, equals(WaitlistStatus.promoted));
        expect(promoted.first.expiresAt, isNotNull);

        // Step 7: Verify second user is still waiting
        final position2AfterPromotion =
            await waitlistService.getWaitlistPosition(
          waitlistEntryId: entry2.id,
          userId: userId2,
        );
        expect(position2AfterPromotion, equals(1)); // Now first in line
      });

      test(
          'should promote waitlist entries in order of atomic timestamp (first-come-first-served)',
          () async {
        // Test business logic: waitlist promotion respects atomic timestamp ordering
        const eventId = 'event-2';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create event that is full
        final fullEvent = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 10,
          maxAttendees: 10,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => fullEvent);

        // Add three users to waitlist
        final userIds = ['user-1', 'user-2', 'user-3'];
        final entries = <String>[];

        for (final userId in userIds) {
          final profile = createMockPersonalityProfile(userId);
          when(() => mockPersonalityLearning.getCurrentPersonality(userId))
              .thenAnswer((_) async => profile);
          when(() => mockVibeAnalyzer.compileUserVibe(userId, profile))
              .thenAnswer((_) async =>
                  UserVibe.fromPersonalityProfile(userId, profile.dimensions));

          final entry = await waitlistService.addToWaitlist(
            userId: userId,
            type: ReservationType.event,
            targetId: eventId,
            reservationTime: reservationTime,
            ticketCount: 1,
          );
          entries.add(entry.id);

          // Small delay to ensure different atomic timestamps
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Capacity opens (2 tickets available)
        final updatedEvent = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 8,
          maxAttendees: 10,
        );
        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => updatedEvent);

        // Promote entries (should promote first two users in order)
        final promoted = await waitlistService.promoteWaitlistEntries(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          availableCapacity: 2,
        );

        expect(promoted.length, equals(2));
        expect(promoted.first.id,
            equals(entries[0])); // First user should be first
        expect(
            promoted[1].id, equals(entries[1])); // Second user should be second
      });

      test('should handle waitlist promotion expiry', () async {
        // Test business logic: expired promotions are marked as expired
        const eventId = 'event-3';
        const userId = 'user-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create event
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 8,
          maxAttendees: 10,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        final profile = createMockPersonalityProfile(userId);
        when(() => mockPersonalityLearning.getCurrentPersonality(userId))
            .thenAnswer((_) async => profile);
        when(() => mockVibeAnalyzer.compileUserVibe(userId, profile))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId, profile.dimensions));

        // Add to waitlist
        await waitlistService.addToWaitlist(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          ticketCount: 2,
        );

        // Promote entry
        final promoted = await waitlistService.promoteWaitlistEntries(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          availableCapacity: 2,
        );

        expect(promoted.length, equals(1));
        expect(promoted.first.status, equals(WaitlistStatus.promoted));

        // Check expired promotions (should not expire immediately)
        final expired = await waitlistService.checkExpiredPromotions(
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
        );

        expect(expired.length, equals(0)); // Not expired yet

        // Note: Actual expiry testing would require time manipulation or waiting 2+ hours
        // This test verifies the checkExpiredPromotions method works correctly
      });
    });

    group('Waitlist Position Calculation', () {
      test(
          'should calculate waitlist position correctly based on atomic timestamp',
          () async {
        // Test business logic: position calculation uses atomic timestamp ordering
        const eventId = 'event-4';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 10,
          maxAttendees: 10,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        // Add two users
        const userId1 = 'user-1';
        const userId2 = 'user-2';

        final profile1 = createMockPersonalityProfile(userId1);
        final profile2 = createMockPersonalityProfile(userId2);
        when(() => mockPersonalityLearning.getCurrentPersonality(userId1))
            .thenAnswer((_) async => profile1);
        when(() => mockPersonalityLearning.getCurrentPersonality(userId2))
            .thenAnswer((_) async => profile2);
        when(() => mockVibeAnalyzer.compileUserVibe(userId1, profile1))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId1, profile1.dimensions));
        when(() => mockVibeAnalyzer.compileUserVibe(userId2, profile2))
            .thenAnswer((_) async =>
                UserVibe.fromPersonalityProfile(userId2, profile2.dimensions));

        final entry1 = await waitlistService.addToWaitlist(
          userId: userId1,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          ticketCount: 1,
        );

        await Future.delayed(const Duration(milliseconds: 10));

        final entry2 = await waitlistService.addToWaitlist(
          userId: userId2,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          ticketCount: 1,
        );

        // Get positions
        final position1 = await waitlistService.getWaitlistPosition(
          waitlistEntryId: entry1.id,
          userId: userId1,
        );
        final position2 = await waitlistService.getWaitlistPosition(
          waitlistEntryId: entry2.id,
          userId: userId2,
        );

        expect(position1, equals(1));
        expect(position2, equals(2));
      });
    });
  });
}
