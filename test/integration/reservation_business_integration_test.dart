/// SPOTS Reservation Business Integration Tests
/// Date: January 6, 2026
/// Purpose: End-to-end validation of business reservation workflow
///
/// Test Coverage:
/// - Complete business reservation workflow: Create → Store → Retrieve → Update → Cancel
/// - Business reservation creation (typically free, no platform fees)
/// - Business reservation updates (party size, special requests)
/// - Business reservation cancellation
/// - Business reservation retrieval and filtering
/// - Offline-first behavior for business reservations
///
/// Dependencies:
/// - Real services: ReservationService, ReservationQuantumService, AtomicClockService, AgentIdService, StorageService
/// - Mock services: SupabaseService (offline by default), Quantum services
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
import 'package:avrai/core/services/secure_mapping_encryption_service.dart';
import 'package:avrai/core/models/reservation.dart';
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

class MockQuantumVibeEngine extends Mock implements QuantumVibeEngine {}

class MockUserVibeAnalyzer extends Mock implements UserVibeAnalyzer {}

class MockPersonalityLearning extends Mock implements PersonalityLearning {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reservation Business Integration Tests', () {
    late ReservationService reservationService;
    late AtomicClockService atomicClock;
    late AgentIdService agentIdService;
    late StorageService storageService;
    late ReservationQuantumService quantumService;
    late LocationTimingQuantumStateService locationTimingService;
    late MockSupabaseService mockSupabaseService;
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

    group('Business Reservation Creation', () {
      test('should create business reservation successfully', () async {
        // Test business logic: business reservation creation
        const userId = 'user-1';
        const businessId = 'business-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Create business reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: businessId,
          reservationTime: reservationTime,
          partySize: 4,
        );

        // Verify reservation
        expect(reservation, isA<Reservation>());
        expect(reservation.type, equals(ReservationType.business));
        expect(reservation.targetId, equals(businessId));
        expect(reservation.partySize, equals(4));
        expect(
            reservation.status,
            equals(
                ReservationStatus.confirmed)); // Free reservations auto-confirm
        expect(reservation.quantumState, isNotNull);
      });

      test('should create business reservation with special requests',
          () async {
        // Test business logic: business reservation with special requests
        const userId = 'user-2';
        const businessId = 'business-2';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        const specialRequests = 'Window seat preferred';

        setupPersonalityMocks(userId);

        // Create business reservation with special requests
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: businessId,
          reservationTime: reservationTime,
          partySize: 2,
          specialRequests: specialRequests,
        );

        // Verify reservation
        expect(reservation.specialRequests, equals(specialRequests));
        expect(reservation.type, equals(ReservationType.business));
        expect(reservation.targetId, equals(businessId));
      });

      test('should create free business reservation (no payment)', () async {
        // Test business logic: business reservations are typically free
        const userId = 'user-3';
        const businessId = 'business-3';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Create business reservation (free by default)
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: businessId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Verify reservation is free and automatically confirmed
        expect(reservation.ticketPrice, isNull);
        expect(reservation.status, equals(ReservationStatus.confirmed));
        expect(reservation.metadata['paymentId'], isNull);
      });
    });

    group('Business Reservation Updates', () {
      test('should update business reservation party size', () async {
        // Test business logic: business reservation update
        const userId = 'user-4';
        const businessId = 'business-4';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Create business reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: businessId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Update party size
        final updatedReservation = await reservationService.updateReservation(
          reservationId: reservation.id,
          partySize: 4,
        );

        // Verify update
        expect(updatedReservation.partySize, equals(4));
        expect(updatedReservation.modificationCount, equals(1));
      });

      test('should update business reservation special requests', () async {
        // Test business logic: business reservation special requests update
        const userId = 'user-5';
        const businessId = 'business-5';
        final reservationTime = DateTime.now().add(const Duration(days: 7));
        const updatedRequests = 'Vegetarian options needed';

        setupPersonalityMocks(userId);

        // Create business reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: businessId,
          reservationTime: reservationTime,
          partySize: 2,
          specialRequests: 'Window seat',
        );

        // Update special requests
        final updatedReservation = await reservationService.updateReservation(
          reservationId: reservation.id,
          specialRequests: updatedRequests,
        );

        // Verify update
        expect(updatedReservation.specialRequests, equals(updatedRequests));
        expect(updatedReservation.modificationCount, equals(1));
      });
    });

    group('Business Reservation Cancellation', () {
      test('should cancel business reservation successfully', () async {
        // Test business logic: business reservation cancellation
        const userId = 'user-6';
        const businessId = 'business-6';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Create business reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: businessId,
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

    group('Business Reservation Retrieval', () {
      test('should retrieve business reservations for user', () async {
        // Test business logic: business reservation retrieval
        const userId = 'user-7';
        const businessId1 = 'business-7';
        const businessId2 = 'business-8';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Create two business reservations
        await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: businessId1,
          reservationTime: reservationTime,
          partySize: 2,
        );

        await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: businessId2,
          reservationTime: reservationTime.add(const Duration(hours: 2)),
          partySize: 4,
        );

        // Retrieve reservations
        final reservations =
            await reservationService.getUserReservations(userId: userId);

        // Verify retrieval
        expect(reservations, hasLength(greaterThanOrEqualTo(2)));
        final businessReservations = reservations
            .where((r) => r.type == ReservationType.business)
            .toList();
        expect(businessReservations.length, greaterThanOrEqualTo(2));
      });

      test('should filter business reservations by status', () async {
        // Test business logic: business reservation filtering
        const userId = 'user-8';
        const businessId = 'business-9';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Create business reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: businessId,
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
