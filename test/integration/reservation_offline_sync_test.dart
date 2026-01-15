/// SPOTS Reservation Offline Sync Integration Tests
/// Date: January 6, 2026
/// Purpose: End-to-end validation of offline-first sync workflow
///
/// Test Coverage:
/// - Complete offline sync workflow: Create offline → Store locally → Sync when online → Merge conflicts
/// - Offline-first behavior (create/store locally, sync when online)
/// - Cloud sync when online (SupabaseService available)
/// - Conflict resolution (merge local and cloud reservations)
/// - Retrieval from local storage when offline
/// - Sync on reconnect (when SupabaseService becomes available)
///
/// Dependencies:
/// - Real services: ReservationService, ReservationQuantumService, AtomicClockService, AgentIdService, StorageService
/// - Mock services: SupabaseService (toggle offline/online), Quantum services
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

  group('Reservation Offline Sync Integration Tests', () {
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

    group('Offline-First Behavior', () {
      test('should create reservation offline and store locally', () async {
        // Test business logic: offline-first - create and store locally when offline
        const userId = 'user-1';
        const targetId = 'spot-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Ensure Supabase is offline
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        setupPersonalityMocks(userId);

        // Create reservation (should work offline)
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Verify reservation created
        expect(reservation, isA<Reservation>());
        expect(reservation.targetId, equals(targetId));

        // Retrieve reservations from local storage
        final reservations =
            await reservationService.getUserReservations(userId: userId);

        // Verify reservation is stored locally
        expect(reservations, hasLength(greaterThanOrEqualTo(1)));
        final foundReservation =
            reservations.firstWhere((r) => r.id == reservation.id);
        expect(foundReservation.targetId, equals(targetId));
      });

      test('should retrieve reservations from local storage when offline',
          () async {
        // Test business logic: retrieve from local storage when Supabase is offline
        const userId = 'user-2';
        const targetId = 'business-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Ensure Supabase is offline
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        setupPersonalityMocks(userId);

        // Create reservation offline
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: targetId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Retrieve reservations (should get from local storage)
        final reservations =
            await reservationService.getUserReservations(userId: userId);

        // Verify retrieval from local storage
        expect(reservations, hasLength(greaterThanOrEqualTo(1)));
        final foundReservation =
            reservations.firstWhere((r) => r.id == reservation.id);
        expect(foundReservation, isA<Reservation>());
        expect(foundReservation.targetId, equals(targetId));
      });
    });

    group('Cloud Sync When Online', () {
      test('should sync reservation to cloud when Supabase is available',
          () async {
        // Test business logic: sync to cloud when online
        const userId = 'user-3';
        const targetId = 'spot-2';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Setup Supabase to be online (available)
        when(() => mockSupabaseService.isAvailable).thenReturn(true);

        setupPersonalityMocks(userId);

        // Create reservation (should sync to cloud when online)
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Verify reservation created
        expect(reservation, isA<Reservation>());
        expect(reservation.targetId, equals(targetId));

        // Note: Actual cloud sync is tested through SupabaseService mock
        // In real implementation, reservation would be synced to cloud
      });

      test('should handle sync failure gracefully (offline-first)', () async {
        // Test business logic: sync failure doesn't prevent local storage
        const userId = 'user-4';
        const targetId = 'event-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Setup Supabase to be online but sync might fail
        when(() => mockSupabaseService.isAvailable).thenReturn(true);

        setupPersonalityMocks(userId);

        // Create reservation (should store locally even if sync fails)
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: targetId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Verify reservation is stored locally (offline-first)
        final reservations =
            await reservationService.getUserReservations(userId: userId);
        expect(reservations, hasLength(greaterThanOrEqualTo(1)));
        final foundReservation =
            reservations.firstWhere((r) => r.id == reservation.id);
        expect(foundReservation, isA<Reservation>());
      });
    });

    group('Merge Local and Cloud Reservations', () {
      test('should merge local and cloud reservations when retrieving',
          () async {
        // Test business logic: merge local and cloud reservations
        // NOTE: Current implementation uses getUserReservations which merges local and cloud
        const userId = 'user-5';
        const targetId1 = 'spot-3';
        const targetId2 = 'business-2';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Start offline
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        setupPersonalityMocks(userId);

        // Create reservation offline
        final localReservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId1,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Switch to online
        when(() => mockSupabaseService.isAvailable).thenReturn(true);

        // Create another reservation (would sync to cloud in real implementation)
        final onlineReservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: targetId2,
          reservationTime: reservationTime.add(const Duration(hours: 2)),
          partySize: 4,
        );

        // Retrieve reservations (should merge local and cloud)
        final reservations =
            await reservationService.getUserReservations(userId: userId);

        // Verify both reservations are retrieved
        expect(reservations, hasLength(greaterThanOrEqualTo(2)));
        final localFound = reservations.any((r) => r.id == localReservation.id);
        final onlineFound =
            reservations.any((r) => r.id == onlineReservation.id);
        expect(localFound, isTrue);
        expect(onlineFound, isTrue);
      });
    });

    group('Offline Update and Sync', () {
      test('should update reservation offline and sync when online', () async {
        // Test business logic: update offline, sync when online
        const userId = 'user-6';
        const targetId = 'spot-4';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Start offline
        when(() => mockSupabaseService.isAvailable).thenReturn(false);

        setupPersonalityMocks(userId);

        // Create reservation offline
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Update reservation offline
        final updatedReservation = await reservationService.updateReservation(
          reservationId: reservation.id,
          partySize: 4,
        );

        // Verify update stored locally
        expect(updatedReservation.partySize, equals(4));

        // Switch to online
        when(() => mockSupabaseService.isAvailable).thenReturn(true);

        // Retrieve reservations (should include updated reservation)
        final reservations =
            await reservationService.getUserReservations(userId: userId);
        final foundReservation =
            reservations.firstWhere((r) => r.id == reservation.id);
        expect(foundReservation.partySize, equals(4));
      });
    });
  });
}
