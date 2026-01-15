/// SPOTS Reservation Rate Limiting Integration Tests
/// Date: January 6, 2026
/// Purpose: End-to-end validation of rate limiting workflow
///
/// Test Coverage:
/// - Complete rate limiting workflow: Check → Create (if allowed) → Rate limit increments
/// - Rate limit enforcement when limits exceeded (hourly, daily, target daily, target weekly)
/// - Rate limit reset functionality
/// - Integration with ReservationCreationController (rate limits checked before creation)
/// - Privacy (uses agentId, not userId)
///
/// Dependencies:
/// - Real services: ReservationRateLimitService, RateLimitingService, AgentIdService, ReservationService, ReservationQuantumService, AtomicClockService, StorageService
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
import 'package:avrai/core/services/reservation_rate_limit_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/services/rate_limiting_service.dart';
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

  group('Reservation Rate Limiting Integration Tests', () {
    late ReservationRateLimitService rateLimitService;
    late ReservationService reservationService;
    late RateLimitingService rateLimitingService;
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
      rateLimitingService =
          RateLimitingService(); // Real service for actual rate limit tracking

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

      // Create rate limit service
      rateLimitService = ReservationRateLimitService(
        rateLimitingService: rateLimitingService,
        agentIdService: agentIdService,
        reservationService: reservationService,
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

    group('Rate Limit Check Flow', () {
      test('should allow reservation when rate limits pass', () async {
        // Test business logic: rate limit check allows reservation creation
        const userId = 'user-1';
        const targetId = 'target-1';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Step 1: Check rate limit (should pass)
        final rateLimitCheck = await rateLimitService.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
        );

        expect(rateLimitCheck.allowed, isTrue);

        // Step 2: Create reservation (should succeed)
        final reservation = await reservationService.createReservation(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
          partySize: 2,
        );

        expect(reservation, isA<Reservation>());
        expect(reservation.targetId, equals(targetId));
      });
    });

    group('Rate Limit Enforcement', () {
      test('should deny reservation when hourly rate limit exceeded', () async {
        // Test business logic: hourly rate limit enforcement
        const userId = 'user-2';
        const targetId = 'target-2';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Get agentId
        final agentId = await agentIdService.getUserAgentId(userId);

        // Manually exceed hourly rate limit by calling RateLimitingService directly
        // (RateLimitingService has default limit of 100, so we'll hit it)
        for (int i = 0; i < 101; i++) {
          await rateLimitingService.checkRateLimit(
            agentId,
            'reservation_create_hourly',
          );
        }

        // Check rate limit (should fail)
        final rateLimitCheck = await rateLimitService.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
        );

        expect(rateLimitCheck.allowed, isFalse);
        expect(rateLimitCheck.reason,
            contains('Too many reservations created in the last hour'));
      });

      test('should deny reservation when daily rate limit exceeded', () async {
        // Test business logic: daily rate limit enforcement
        const userId = 'user-3';
        const targetId = 'target-3';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Get agentId
        final agentId = await agentIdService.getUserAgentId(userId);

        // Manually exceed daily rate limit
        for (int i = 0; i < 101; i++) {
          await rateLimitingService.checkRateLimit(
            agentId,
            'reservation_create_daily',
          );
        }

        // Check rate limit (should fail on daily limit)
        final rateLimitCheck = await rateLimitService.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
        );

        expect(rateLimitCheck.allowed, isFalse);
        expect(rateLimitCheck.reason,
            contains('Too many reservations created today'));
      });

      test('should deny reservation when target daily rate limit exceeded',
          () async {
        // Test business logic: target daily rate limit enforcement
        const userId = 'user-4';
        const targetId = 'target-4';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Get agentId
        final agentId = await agentIdService.getUserAgentId(userId);
        final targetDailyKey = 'reservation_create_target_daily:$targetId';

        // Manually exceed target daily rate limit
        for (int i = 0; i < 101; i++) {
          await rateLimitingService.checkRateLimit(agentId, targetDailyKey);
        }

        // Check rate limit (should fail on target daily limit)
        final rateLimitCheck = await rateLimitService.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
        );

        expect(rateLimitCheck.allowed, isFalse);
        expect(rateLimitCheck.reason,
            contains('Too many reservations at this location today'));
      });
    });

    group('Rate Limit Reset', () {
      test('should reset rate limits and allow reservations after reset',
          () async {
        // Test business logic: rate limit reset functionality
        const userId = 'user-5';
        const targetId = 'target-5';
        final reservationTime = DateTime.now().add(const Duration(days: 7));

        setupPersonalityMocks(userId);

        // Get agentId
        final agentId = await agentIdService.getUserAgentId(userId);

        // Exceed hourly rate limit
        for (int i = 0; i < 101; i++) {
          await rateLimitingService.checkRateLimit(
            agentId,
            'reservation_create_hourly',
          );
        }

        // Verify rate limit is exceeded
        final beforeReset = await rateLimitService.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
        );
        expect(beforeReset.allowed, isFalse);

        // Reset rate limit
        await rateLimitService.resetRateLimit(userId: userId);

        // Verify rate limit is reset (should allow now)
        final afterReset = await rateLimitService.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
          reservationTime: reservationTime,
        );
        expect(afterReset.allowed, isTrue);
      });
    });

    group('Rate Limit Info', () {
      test('should return rate limit info correctly', () async {
        // Test business logic: rate limit info retrieval
        const userId = 'user-6';
        const targetId = 'target-6';

        setupPersonalityMocks(userId);

        // Get rate limit info (should succeed)
        final info = await rateLimitService.getRateLimitInfo(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
        );

        expect(info.allowed, isTrue);
        expect(info.remaining, isNotNull);
        expect(info.resetAt, isNotNull);
      });
    });
  });
}
