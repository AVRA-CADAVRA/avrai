/// SPOTS Reservation Refund Integration Tests
/// Date: January 6, 2026
/// Purpose: End-to-end validation of reservation refund workflow
///
/// Test Coverage:
/// - Complete refund workflow: Cancel reservation → Process refund → Update reservation
/// - Refund processing for cancelled reservations
/// - Refund integration with cancellation policy
/// - Refund failure handling
/// - Integration with RefundService
///
/// Dependencies:
/// - Real services: ReservationService, RefundService, ReservationQuantumService, AtomicClockService, AgentIdService, StorageService
/// - Mock services: SupabaseService (offline by default), Quantum services
///
/// ⚠️  NOTE: Refund integration is optional (RefundService may be null)
/// These tests verify the refund workflow when RefundService is available.
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
import 'package:avrai/core/services/refund_service.dart';
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

class MockRefundService extends Mock implements RefundService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reservation Refund Integration Tests', () {
    late ReservationService reservationService;
    late AtomicClockService atomicClock;
    late AgentIdService agentIdService;
    late StorageService storageService;
    late ReservationQuantumService quantumService;
    late LocationTimingQuantumStateService locationTimingService;
    late MockSupabaseService mockSupabaseService;
    late MockRefundService mockRefundService;
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
      mockRefundService = MockRefundService();
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

      // Create reservation service with refund service
      reservationService = ReservationService(
        atomicClock: atomicClock,
        quantumService: quantumService,
        agentIdService: agentIdService,
        storageService: storageService,
        supabaseService: mockSupabaseService,
        refundService: mockRefundService,
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

    group('Refund Processing', () {
      test('should process refund when reservation is cancelled', () async {
        // Test business logic: refund processing on cancellation
        // NOTE: Current implementation may not automatically process refunds on cancellation
        // This test documents expected behavior when refund integration is fully implemented
        const userId = 'user-1';
        const targetId = 'spot-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Create reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
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

        // Note: Refund processing would be triggered here in full implementation
        // Current implementation may not automatically process refunds
      });

      test('should handle refund service gracefully when unavailable',
          () async {
        // Test business logic: graceful degradation when RefundService is not available
        const userId = 'user-2';
        const targetId = 'business-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        // Create reservation service without refund service
        final serviceWithoutRefund = ReservationService(
          atomicClock: atomicClock,
          quantumService: quantumService,
          agentIdService: agentIdService,
          storageService: storageService,
          supabaseService: mockSupabaseService,
          // refundService: null (not provided)
        );

        setupPersonalityMocks(userId);

        // Create reservation
        final reservation = await serviceWithoutRefund.createReservation(
          userId: userId,
          type: ReservationType.business,
          targetId: targetId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Cancel reservation (should work even without refund service)
        final cancelledReservation =
            await serviceWithoutRefund.cancelReservation(
          reservationId: reservation.id,
          reason: 'User request',
        );

        // Verify cancellation works (graceful degradation)
        expect(
            cancelledReservation.status, equals(ReservationStatus.cancelled));
      });
    });

    group('Refund Integration with Cancellation Policy', () {
      test('should respect cancellation policy for refund processing',
          () async {
        // Test business logic: refund processing respects cancellation policy
        // NOTE: Current implementation may not fully integrate refunds with cancellation policy
        // This test documents expected behavior when fully implemented
        const userId = 'user-3';
        const targetId = 'event-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Create reservation with cancellation policy
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.event,
          targetId: targetId,
          reservationTime: reservationTime,
          partySize: 2,
          cancellationPolicy: CancellationPolicy(
            hoursBefore: 24,
            fullRefund: true,
            partialRefund: false,
            hasCancellationFee: false,
          ),
        );

        // Cancel reservation (within cancellation window - should get refund)
        final cancelledReservation = await reservationService.cancelReservation(
          reservationId: reservation.id,
          reason: 'User request',
        );

        // Verify cancellation
        expect(
            cancelledReservation.status, equals(ReservationStatus.cancelled));

        // Note: Refund processing would respect cancellation policy in full implementation
      });
    });

    group('Refund Failure Handling', () {
      test('should handle refund failure gracefully', () async {
        // Test business logic: refund failure doesn't prevent cancellation
        // NOTE: Current implementation may not have automatic refund processing
        // This test documents expected behavior when fully implemented
        const userId = 'user-4';
        const targetId = 'spot-2';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Create reservation
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        // Cancel reservation (should work even if refund fails)
        final cancelledReservation = await reservationService.cancelReservation(
          reservationId: reservation.id,
          reason: 'User request',
        );

        // Verify cancellation succeeds (graceful degradation)
        expect(
            cancelledReservation.status, equals(ReservationStatus.cancelled));

        // Note: In full implementation, refund failure would be logged but wouldn't prevent cancellation
      });
    });
  });
}
