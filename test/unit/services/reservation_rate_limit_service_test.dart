/// SPOTS Reservation Rate Limit Service Tests
/// Date: January 6, 2026
/// Purpose: Test ReservationRateLimitService functionality
///
/// Test Coverage:
/// - Core Methods: checkRateLimit, getRateLimitInfo, resetRateLimit
/// - Rate Limit Checks: Hourly, daily, target daily, target weekly
/// - Error Handling: Service errors, graceful degradation
/// - Privacy: Uses agentId (not userId) for internal tracking
///
/// Dependencies:
/// - Mock RateLimitingService: Core rate limiting functionality
/// - Mock AgentIdService: Agent ID resolution
/// - Mock ReservationService: Reserved for future use
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
import 'package:avrai/core/services/reservation_rate_limit_service.dart';
import 'package:avrai/core/services/rate_limiting_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/models/reservation.dart';

// Mock dependencies
class MockRateLimitingService extends Mock implements RateLimitingService {}

class MockAgentIdService extends Mock implements AgentIdService {}

class MockReservationService extends Mock implements ReservationService {}

void main() {
  setUpAll(() {
    // Register fallback values for enum types
    registerFallbackValue(ReservationType.event);
    registerFallbackValue(ReservationType.spot);
    registerFallbackValue(ReservationType.business);
  });

  group('ReservationRateLimitService', () {
    late ReservationRateLimitService service;
    late MockRateLimitingService mockRateLimitingService;
    late MockAgentIdService mockAgentIdService;
    late MockReservationService mockReservationService;

    setUp(() {
      mockRateLimitingService = MockRateLimitingService();
      mockAgentIdService = MockAgentIdService();
      mockReservationService = MockReservationService();

      service = ReservationRateLimitService(
        rateLimitingService: mockRateLimitingService,
        agentIdService: mockAgentIdService,
        reservationService: mockReservationService,
      );
    });

    group('checkRateLimit', () {
      test('should allow reservation when all rate limits pass', () async {
        // Test business logic: successful rate limit check with all limits passing
        const userId = 'user-1';
        const agentId = 'agent-1';
        const targetId = 'target-1';
        final now = DateTime.now();
        final resetAt = now.add(const Duration(minutes: 15));

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_hourly',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_daily',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_daily:$targetId',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_weekly:$targetId',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.getRateLimitInfo(
              agentId,
              'reservation_create_hourly',
            )).thenAnswer((_) async => RateLimitInfo(
              userId: agentId,
              operation: 'reservation_create_hourly',
              count: 5,
              limit: 10,
              resetAt: resetAt,
            ));

        final result = await service.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
        );

        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
        expect(result.remaining, equals(5));
        expect(result.resetAt, equals(resetAt));

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_hourly',
            )).called(1);
        verify(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_daily',
            )).called(1);
        verify(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_daily:$targetId',
            )).called(1);
        verify(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_weekly:$targetId',
            )).called(1);
      });

      test('should deny reservation when hourly rate limit exceeded', () async {
        // Test business logic: rate limit denial when hourly limit exceeded
        const userId = 'user-1';
        const agentId = 'agent-1';
        const targetId = 'target-1';
        final now = DateTime.now();
        final resetAt = now.add(const Duration(minutes: 15));

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_hourly',
            )).thenAnswer((_) async => false);

        when(() => mockRateLimitingService.getRateLimitInfo(
              agentId,
              'reservation_create_hourly',
            )).thenAnswer((_) async => RateLimitInfo(
              userId: agentId,
              operation: 'reservation_create_hourly',
              count: 10,
              limit: 10,
              resetAt: resetAt,
            ));

        final result = await service.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
        );

        expect(result.allowed, isFalse);
        expect(result.reason,
            contains('Too many reservations created in the last hour'));
        expect(result.reason, contains('Limit: 10 per hour'));
        expect(result.resetAt, equals(resetAt));
        expect(result.retryAfter, isNotNull);

        verify(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_hourly',
            )).called(1);
        verifyNever(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_daily',
            ));
      });

      test('should deny reservation when daily rate limit exceeded', () async {
        // Test business logic: rate limit denial when daily limit exceeded
        const userId = 'user-1';
        const agentId = 'agent-1';
        const targetId = 'target-1';
        final now = DateTime.now();
        final resetAt = now.add(const Duration(hours: 2));

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_hourly',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_daily',
            )).thenAnswer((_) async => false);

        when(() => mockRateLimitingService.getRateLimitInfo(
              agentId,
              'reservation_create_daily',
            )).thenAnswer((_) async => RateLimitInfo(
              userId: agentId,
              operation: 'reservation_create_daily',
              count: 50,
              limit: 50,
              resetAt: resetAt,
            ));

        final result = await service.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
        );

        expect(result.allowed, isFalse);
        expect(result.reason, contains('Too many reservations created today'));
        expect(result.reason, contains('Limit: 50 per day'));
        expect(result.resetAt, equals(resetAt));

        verify(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_daily',
            )).called(1);
        verifyNever(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_daily:$targetId',
            ));
      });

      test('should deny reservation when target daily rate limit exceeded',
          () async {
        // Test business logic: rate limit denial when target daily limit exceeded
        const userId = 'user-1';
        const agentId = 'agent-1';
        const targetId = 'target-1';
        final now = DateTime.now();
        final resetAt = now.add(const Duration(hours: 6));

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_hourly',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_daily',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_daily:$targetId',
            )).thenAnswer((_) async => false);

        when(() => mockRateLimitingService.getRateLimitInfo(
              agentId,
              'reservation_create_target_daily:$targetId',
            )).thenAnswer((_) async => RateLimitInfo(
              userId: agentId,
              operation: 'reservation_create_target_daily:$targetId',
              count: 3,
              limit: 3,
              resetAt: resetAt,
            ));

        final result = await service.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
        );

        expect(result.allowed, isFalse);
        expect(result.reason,
            contains('Too many reservations at this location today'));
        expect(result.reason, contains('Limit: 3 per day per location'));
        expect(result.resetAt, equals(resetAt));

        verify(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_daily:$targetId',
            )).called(1);
        verifyNever(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_weekly:$targetId',
            ));
      });

      test('should deny reservation when target weekly rate limit exceeded',
          () async {
        // Test business logic: rate limit denial when target weekly limit exceeded
        const userId = 'user-1';
        const agentId = 'agent-1';
        const targetId = 'target-1';
        final now = DateTime.now();
        final resetAt = now.add(const Duration(days: 2));

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_hourly',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_daily',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_daily:$targetId',
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              'reservation_create_target_weekly:$targetId',
            )).thenAnswer((_) async => false);

        when(() => mockRateLimitingService.getRateLimitInfo(
              agentId,
              'reservation_create_target_weekly:$targetId',
            )).thenAnswer((_) async => RateLimitInfo(
              userId: agentId,
              operation: 'reservation_create_target_weekly:$targetId',
              count: 10,
              limit: 10,
              resetAt: resetAt,
            ));

        final result = await service.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
        );

        expect(result.allowed, isFalse);
        expect(result.reason,
            contains('Too many reservations at this location this week'));
        expect(result.reason, contains('Limit: 10 per week per location'));
        expect(result.resetAt, equals(resetAt));
      });

      test('should default to allowed on error (graceful degradation)',
          () async {
        // Test error handling: graceful degradation when service error occurs
        const userId = 'user-1';

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenThrow(Exception('Service error'));

        final result = await service.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: 'target-1',
        );

        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
      });
    });

    group('getRateLimitInfo', () {
      test('should return rate limit info correctly', () async {
        // Test business logic: rate limit info retrieval
        const userId = 'user-1';
        const agentId = 'agent-1';
        final now = DateTime.now();
        final resetAt = now.add(const Duration(minutes: 15));

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.getRateLimitInfo(
              agentId,
              'reservation_create_hourly',
            )).thenAnswer((_) async => RateLimitInfo(
              userId: agentId,
              operation: 'reservation_create_hourly',
              count: 7,
              limit: 10,
              resetAt: resetAt,
            ));

        final result = await service.getRateLimitInfo(
          userId: userId,
          type: ReservationType.spot,
          targetId: 'target-1',
        );

        expect(result.allowed, isTrue);
        expect(result.remaining, equals(3));
        expect(result.resetAt, equals(resetAt));

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(() => mockRateLimitingService.getRateLimitInfo(
              agentId,
              'reservation_create_hourly',
            )).called(1);
      });

      test('should default to allowed on error (graceful degradation)',
          () async {
        // Test error handling: graceful degradation when service error occurs
        const userId = 'user-1';

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenThrow(Exception('Service error'));

        final result = await service.getRateLimitInfo(
          userId: userId,
          type: ReservationType.spot,
          targetId: 'target-1',
        );

        expect(result.allowed, isTrue);
        expect(result.reason, isNull);
      });
    });

    group('resetRateLimit', () {
      test('should reset all rate limits when targetId is null', () async {
        // Test business logic: reset all rate limits for user
        const userId = 'user-1';
        const agentId = 'agent-1';

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_hourly',
            )).thenAnswer((_) async => {});

        when(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_daily',
            )).thenAnswer((_) async => {});

        await service.resetRateLimit(userId: userId);

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_hourly',
            )).called(1);
        verify(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_daily',
            )).called(1);
        verifyNever(() => mockRateLimitingService.resetRateLimit(
              agentId,
              any(that: contains('target')),
            ));
      });

      test('should reset target-specific rate limits when targetId provided',
          () async {
        // Test business logic: reset target-specific rate limits
        const userId = 'user-1';
        const agentId = 'agent-1';
        const targetId = 'target-1';

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_target_daily:$targetId',
            )).thenAnswer((_) async => {});

        when(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_target_weekly:$targetId',
            )).thenAnswer((_) async => {});

        await service.resetRateLimit(userId: userId, targetId: targetId);

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_target_daily:$targetId',
            )).called(1);
        verify(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_target_weekly:$targetId',
            )).called(1);
        verifyNever(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_hourly',
            ));
        verifyNever(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_daily',
            ));
      });

      test('should rethrow error when reset fails', () async {
        // Test error handling: error propagation when reset fails
        const userId = 'user-1';
        const agentId = 'agent-1';

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.resetRateLimit(
              agentId,
              'reservation_create_hourly',
            )).thenThrow(Exception('Reset failed'));

        expect(
          () => service.resetRateLimit(userId: userId),
          throwsException,
        );

        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
      });
    });

    group('privacy', () {
      test('should use agentId (not userId) for all rate limit operations',
          () async {
        // Test privacy: verify agentId is used for internal tracking (not userId)
        const userId = 'user-1';
        const agentId = 'agent-1';
        const targetId = 'target-1';

        when(() => mockAgentIdService.getUserAgentId(userId))
            .thenAnswer((_) async => agentId);

        when(() => mockRateLimitingService.checkRateLimit(
              agentId,
              any(),
            )).thenAnswer((_) async => true);

        when(() => mockRateLimitingService.getRateLimitInfo(
              agentId,
              any(),
            )).thenAnswer((_) async => RateLimitInfo(
              userId: agentId,
              operation: 'reservation_create_hourly',
              count: 0,
              limit: 10,
              resetAt: DateTime.now().add(const Duration(minutes: 15)),
            ));

        await service.checkRateLimit(
          userId: userId,
          type: ReservationType.spot,
          targetId: targetId,
        );

        // Verify agentId (not userId) is used in all rate limit operations
        verify(() => mockAgentIdService.getUserAgentId(userId)).called(1);
        verify(() => mockRateLimitingService.checkRateLimit(
              agentId, // agentId, not userId
              any(),
            )).called(4);
      });
    });
  });
}
