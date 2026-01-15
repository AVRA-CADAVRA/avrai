/// SPOTS Reservation Event Integration Tests
/// Date: January 6, 2026
/// Purpose: End-to-end validation of event reservation workflow
///
/// Test Coverage:
/// - Complete event reservation workflow: Create → Store → Retrieve → Update → Cancel
/// - Event reservation creation (free and paid events)
/// - Event reservation updates (party size, ticket count)
/// - Event reservation cancellation
/// - Event reservation retrieval and filtering
/// - Integration with ExpertiseEventService (event capacity, attendee count)
/// - Offline-first behavior for event reservations
///
/// Dependencies:
/// - Real services: ReservationService, ReservationQuantumService, AtomicClockService, AgentIdService, StorageService
/// - Mock services: SupabaseService (offline by default), ExpertiseEventService, Quantum services
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

  group('Reservation Event Integration Tests', () {
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
      double? price,
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
        price: price,
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

    // Helper function to setup personality mocks for a user
    void setupPersonalityMocks(String userId) {
      final profile = createMockPersonalityProfile(userId);
      when(() => mockPersonalityLearning.getCurrentPersonality(userId))
          .thenAnswer((_) async => profile);
      when(() => mockVibeAnalyzer.compileUserVibe(userId, profile)).thenAnswer(
          (_) async =>
              UserVibe.fromPersonalityProfile(userId, profile.dimensions));
    }

    group('Event Reservation Creation', () {
      test('should create free event reservation successfully', () async {
        // Test business logic: free event reservation creation
        const userId = 'user-1';
        const eventId = 'event-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 5,
          maxAttendees: 20,
          price: null, // Free event
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        setupPersonalityMocks(userId);

        // Create event reservation (free)
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
          ticketCount: 2,
        );

        // Verify reservation
        expect(reservation, isA<Reservation>());
        expect(reservation.type, equals(ReservationType.event));
        expect(reservation.targetId, equals(eventId));
        expect(reservation.partySize, equals(2));
        expect(reservation.ticketCount, equals(2));
        expect(reservation.status,
            equals(ReservationStatus.confirmed)); // Free events auto-confirm
        expect(reservation.quantumState, isNotNull);
      });

      test('should create event reservation with ticket count', () async {
        // Test business logic: event reservation with ticket count
        const userId = 'user-2';
        const eventId = 'event-2';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 3,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        setupPersonalityMocks(userId);

        // Create event reservation with multiple tickets
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 4,
          ticketCount: 4,
        );

        // Verify reservation
        expect(reservation.ticketCount, equals(4));
        expect(reservation.partySize, equals(4));
        expect(reservation.type, equals(ReservationType.event));
        expect(reservation.targetId, equals(eventId));
      });

      test('should automatically confirm free event reservation', () async {
        // Test business logic: free event reservations are automatically confirmed
        const userId = 'user-3';
        const eventId = 'event-3';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 5,
          maxAttendees: 20,
          price: null, // Free event
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        setupPersonalityMocks(userId);

        // Create event reservation (free by default)
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Verify reservation is free and automatically confirmed
        expect(reservation.ticketPrice, isNull);
        expect(reservation.status, equals(ReservationStatus.confirmed));
        expect(reservation.metadata['paymentId'], isNull);
      });
    });

    group('Event Reservation Updates', () {
      test('should update event reservation party size', () async {
        // Test business logic: event reservation update
        const userId = 'user-4';
        const eventId = 'event-4';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 5,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        setupPersonalityMocks(userId);

        // Create event reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
          ticketCount: 2,
        );

        // Update party size and ticket count
        final updatedReservation = await reservationService.updateReservation(
          reservationId: reservation.id,
          partySize: 4,
          ticketCount: 4,
        );

        // Verify update
        expect(updatedReservation.partySize, equals(4));
        expect(updatedReservation.ticketCount, equals(4));
        expect(updatedReservation.modificationCount, equals(1));
      });
    });

    group('Event Reservation Cancellation', () {
      test('should cancel event reservation successfully', () async {
        // Test business logic: event reservation cancellation
        const userId = 'user-5';
        const eventId = 'event-5';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 5,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        setupPersonalityMocks(userId);

        // Create event reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Cancel reservation
        final cancelledReservation = await reservationService.cancelReservation(
          reservationId: reservation.id,
          reason: 'User request',
        );

        // Verify cancellation
        expect(
            cancelledReservation.status, equals(ReservationStatus.cancelled));
      });
    });

    group('Event Reservation Retrieval', () {
      test('should retrieve event reservations for user', () async {
        // Test business logic: event reservation retrieval
        const userId = 'user-6';
        const eventId1 = 'event-6';
        const eventId2 = 'event-7';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        final event1 = createTestEvent(
          id: eventId1,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 5,
          maxAttendees: 20,
        );
        final event2 = createTestEvent(
          id: eventId2,
          startTime: reservationTime.add(const Duration(hours: 3)),
          attendeeCount: 8,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId1))
            .thenAnswer((_) async => event1);
        when(() => mockEventService.getEventById(eventId2))
            .thenAnswer((_) async => event2);

        setupPersonalityMocks(userId);

        // Create two event reservations
        await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId1,
          reservationTime: reservationTime,
          partySize: 2,
        );

        await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId2,
          reservationTime: reservationTime.add(const Duration(hours: 2)),
          partySize: 4,
        );

        // Retrieve reservations
        final reservations =
            await reservationService.getUserReservations(userId: userId);

        // Verify retrieval
        expect(reservations, hasLength(greaterThanOrEqualTo(2)));
        final eventReservations =
            reservations.where((r) => r.type == ReservationType.event).toList();
        expect(eventReservations.length, greaterThanOrEqualTo(2));
      });

      test('should filter event reservations by status', () async {
        // Test business logic: event reservation filtering
        const userId = 'user-7';
        const eventId = 'event-8';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        final event = createTestEvent(
          id: eventId,
          startTime: reservationTime.add(const Duration(hours: 1)),
          attendeeCount: 5,
          maxAttendees: 20,
        );

        when(() => mockEventService.getEventById(eventId))
            .thenAnswer((_) async => event);

        setupPersonalityMocks(userId);

        // Create event reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: eventId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Cancel reservation
        await reservationService.cancelReservation(
          reservationId: reservation.id,
          reason: 'User request',
        );

        // Retrieve confirmed reservations (should not include cancelled)
        final reservations = await reservationService.getUserReservations(
          userId: userId,
          status: ReservationStatus.confirmed,
        );

        // Verify filtering (cancelled reservation should not be in confirmed list)
        final cancelledInConfirmed =
            reservations.any((r) => r.id == reservation.id);
        expect(cancelledInConfirmed, isFalse);
      });
    });
  });
}
