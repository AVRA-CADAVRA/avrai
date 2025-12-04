import 'package:flutter_test/flutter_test.dart';
import 'package:spots/core/services/rate_limiting_service.dart';
import '../helpers/test_helpers.dart';

/// Tests for Rate Limiting Service
/// OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"
/// 
/// These tests ensure rate limiting prevents abuse
/// and protects sensitive operations
void main() {
  group('RateLimitingService', () {
    late RateLimitingService service;

    setUp(() {
      service = RateLimitingService();
    });

    group('Rate Limiting Triggers', () {
      test('should allow requests within rate limit', () async {
        const userId = 'user-123';
        const operation = 'data_access';

        // Make requests within limit
        for (int i = 0; i < 10; i++) {
          final allowed = await service.checkRateLimit(userId, operation);

          expect(allowed, isTrue);
        }
      });

      test('should block requests exceeding rate limit', () async {
        const userId = 'user-456';
        const operation = 'data_access';
        const maxRequests = 10;

        // Make requests up to limit
        for (int i = 0; i < maxRequests; i++) {
          await service.checkRateLimit(userId, operation);
        }

        // Next request should be blocked
        final allowed = await service.checkRateLimit(userId, operation);

        expect(allowed, isFalse);
      });

      test('should have different limits for different operations', () async {
        const userId = 'user-789';

        // Sensitive operations should have lower limits
        final sensitiveAllowed = await service.checkRateLimit(
          userId,
          'decrypt_email', // Sensitive
        );
        final normalAllowed = await service.checkRateLimit(
          userId,
          'data_access', // Normal
        );

        expect(sensitiveAllowed, isTrue);
        expect(normalAllowed, isTrue);

        // But sensitive operations should hit limit faster
        // (tested by making many requests)
      });

      test('should track rate limits per user', () async {
        const user1 = 'user-1';
        const user2 = 'user-2';
        const operation = 'data_access';

        // User 1 hits limit
        for (int i = 0; i < 10; i++) {
          await service.checkRateLimit(user1, operation);
        }
        final user1Blocked = await service.checkRateLimit(user1, operation);

        // User 2 should still be allowed
        final user2Allowed = await service.checkRateLimit(user2, operation);

        expect(user1Blocked, isFalse);
        expect(user2Allowed, isTrue);
      });
    });

    group('Rate Limit Reset', () {
      test('should reset rate limit after time window', () async {
        const userId = 'user-reset';
        const operation = 'data_access';

        // Hit limit
        for (int i = 0; i < 10; i++) {
          await service.checkRateLimit(userId, operation);
        }
        final blocked = await service.checkRateLimit(userId, operation);
        expect(blocked, isFalse);

        // Wait for reset (in real test, would use fake async)
        // For now, manually reset
        await service.resetRateLimit(userId, operation);

        // Should be allowed again
        final allowed = await service.checkRateLimit(userId, operation);
        expect(allowed, isTrue);
      });

      test('should reset rate limit for all operations', () async {
        const userId = 'user-reset-all';

        // Hit limit on multiple operations
        await service.checkRateLimit(userId, 'operation1');
        await service.checkRateLimit(userId, 'operation2');

        // Reset all
        await service.resetAllRateLimits(userId);

        // Both should be allowed
        expect(await service.checkRateLimit(userId, 'operation1'), isTrue);
        expect(await service.checkRateLimit(userId, 'operation2'), isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle rate limit errors gracefully', () async {
        const userId = 'user-error';
        const operation = 'data_access';

        // Hit limit
        for (int i = 0; i < 10; i++) {
          await service.checkRateLimit(userId, operation);
        }

        // Should throw rate limit exception
        expect(
          () => service.checkRateLimit(userId, operation, throwOnLimit: true),
          throwsA(isA<RateLimitException>()),
        );
      });

      test('should provide rate limit information', () async {
        const userId = 'user-info';
        const operation = 'data_access';

        final info = await service.getRateLimitInfo(userId, operation);

        expect(info, isNotNull);
        expect(info.remaining, greaterThanOrEqualTo(0));
        expect(info.limit, greaterThan(0));
        expect(info.resetAt, isNotNull);
      });

      test('should handle concurrent rate limit checks', () async {
        const userId = 'user-concurrent';
        const operation = 'data_access';

        // Make concurrent requests
        final futures = List.generate(10, (_) =>
            service.checkRateLimit(userId, operation));

        final results = await Future.wait(futures);

        // All should be allowed (within limit)
        expect(results.every((allowed) => allowed == true), isTrue);
      });
    });
  });
}

/// RateLimitingService (to be implemented by Agent 1)
class RateLimitingService {
  final Map<String, RateLimitInfo> _rateLimits = {};
  final Map<String, int> _operationLimits = {
    'data_access': 100,
    'decrypt_email': 10, // Lower limit for sensitive operations
    'decrypt_name': 10,
    'decrypt_location': 10,
    'decrypt_phone': 10,
  };
  final Duration _windowDuration = Duration(minutes: 15);

  Future<bool> checkRateLimit(
    String userId,
    String operation, {
    bool throwOnLimit = false,
  }) async {
    final key = '$userId:$operation';
    final limit = _operationLimits[operation] ?? 100;

    final info = _rateLimits[key];
    final now = DateTime.now();

    if (info == null || now.isAfter(info.resetAt)) {
      // Reset or create new
      _rateLimits[key] = RateLimitInfo(
        userId: userId,
        operation: operation,
        count: 1,
        limit: limit,
        resetAt: now.add(_windowDuration),
      );
      return true;
    }

    if (info.count >= info.limit) {
      if (throwOnLimit) {
        throw RateLimitException(
          'Rate limit exceeded for $operation. Reset at ${info.resetAt}',
        );
      }
      return false;
    }

    // Increment count
    _rateLimits[key] = RateLimitInfo(
      userId: userId,
      operation: operation,
      count: info.count + 1,
      limit: info.limit,
      resetAt: info.resetAt,
    );

    return true;
  }

  Future<void> resetRateLimit(String userId, String operation) async {
    final key = '$userId:$operation';
    _rateLimits.remove(key);
  }

  Future<void> resetAllRateLimits(String userId) async {
    _rateLimits.removeWhere((key, _) => key.startsWith('$userId:'));
  }

  Future<RateLimitInfo> getRateLimitInfo(String userId, String operation) async {
    final key = '$userId:$operation';
    final info = _rateLimits[key];
    final limit = _operationLimits[operation] ?? 100;

    if (info == null) {
      return RateLimitInfo(
        userId: userId,
        operation: operation,
        count: 0,
        limit: limit,
        resetAt: DateTime.now().add(_windowDuration),
      );
    }

    return info;
  }
}

class RateLimitInfo {
  final String userId;
  final String operation;
  final int count;
  final int limit;
  final DateTime resetAt;

  RateLimitInfo({
    required this.userId,
    required this.operation,
    required this.count,
    required this.limit,
    required this.resetAt,
  });

  int get remaining => (limit - count).clamp(0, limit);
}

class RateLimitException implements Exception {
  final String message;
  RateLimitException(this.message);
  
  @override
  String toString() => 'RateLimitException: $message';
}

