// Reservation Rate Limit Service
//
// Phase 15: Reservation System Implementation
// Section 15.1.8: Rate Limiting Service (CRITICAL GAP FIX)
// CRITICAL: Prevents abuse and spam reservations
//
// Purpose: Rate limiting specifically for reservations to prevent abuse

import 'dart:developer' as developer;

import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/rate_limiting_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:get_it/get_it.dart';

/// Rate limit check result
class RateLimitCheckResult {
  /// Whether the request is allowed
  final bool allowed;

  /// Reason if not allowed
  final String? reason;

  /// Remaining requests in current window
  final int? remaining;

  /// When rate limit resets
  final DateTime? resetAt;

  /// Retry after (seconds)
  final int? retryAfter;

  const RateLimitCheckResult({
    required this.allowed,
    this.reason,
    this.remaining,
    this.resetAt,
    this.retryAfter,
  });

  /// Create allowed result
  factory RateLimitCheckResult.allowed({
    int? remaining,
    DateTime? resetAt,
  }) {
    return RateLimitCheckResult(
      allowed: true,
      remaining: remaining,
      resetAt: resetAt,
    );
  }

  /// Create denied result
  factory RateLimitCheckResult.denied({
    required String reason,
    DateTime? resetAt,
  }) {
    final retryAfter =
        resetAt?.difference(DateTime.now()).inSeconds;
    return RateLimitCheckResult(
      allowed: false,
      reason: reason,
      resetAt: resetAt,
      retryAfter: retryAfter,
    );
  }
}

/// Reservation Rate Limit Service
///
/// **CRITICAL GAP FIX:** Prevents abuse and spam reservations
///
/// **Rate Limits:**
/// - Per-user reservation creation (e.g., 10 per hour)
/// - Per-target reservation creation (e.g., 3 per day per spot/event)
/// - Per-time-window limits (e.g., 5 per hour)
///
/// **Abuse Prevention:**
/// - Prevents spam reservations
/// - Prevents reservation hoarding
/// - Protects businesses from abuse
class ReservationRateLimitService {
  static const String _logName = 'ReservationRateLimitService';

  final RateLimitingService _rateLimitingService;
  final AgentIdService _agentIdService;
  // ignore: unused_field - Reserved for future reservation history checking
  final ReservationService _reservationService;

  // Default rate limits (reserved for future configuration)
  // ignore: unused_field
  static const int _defaultReservationsPerHour = 10;
  // ignore: unused_field
  static const int _defaultReservationsPerDay = 50;
  // ignore: unused_field
  static const int _defaultReservationsPerTargetPerDay = 3;
  // ignore: unused_field
  static const int _defaultReservationsPerTargetPerWeek = 10;

  ReservationRateLimitService({
    RateLimitingService? rateLimitingService,
    AgentIdService? agentIdService,
    ReservationService? reservationService,
  })  : _rateLimitingService =
            rateLimitingService ?? GetIt.instance<RateLimitingService>(),
        _agentIdService = agentIdService ?? GetIt.instance<AgentIdService>(),
        _reservationService =
            reservationService ?? GetIt.instance<ReservationService>();

  /// Check rate limit for reservation creation
  ///
  /// **CRITICAL:** Uses agentId (not userId) for privacy-protected rate limiting
  ///
  /// **Checks:**
  /// - Per-user reservation creation rate (per hour, per day)
  /// - Per-target reservation creation rate (per day, per week)
  /// - Overall reservation creation rate
  Future<RateLimitCheckResult> checkRateLimit({
    required String userId, // Will be converted to agentId internally
    required ReservationType type,
    required String targetId,
    DateTime? reservationTime,
  }) async {
    developer.log(
      'Checking rate limit: userId=$userId, type=$type, targetId=$targetId',
      name: _logName,
    );

    try {
      // Get agentId for privacy-protected internal tracking
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Check 1: Per-user reservation creation rate (per hour)
      final hourlyCheck = await _rateLimitingService.checkRateLimit(
        agentId,
        'reservation_create_hourly',
      );
      if (!hourlyCheck) {
        final info = await _rateLimitingService.getRateLimitInfo(
          agentId,
          'reservation_create_hourly',
        );
        return RateLimitCheckResult.denied(
          reason:
              'Too many reservations created in the last hour. Limit: ${info.limit} per hour.',
          resetAt: info.resetAt,
        );
      }

      // Check 2: Per-user reservation creation rate (per day)
      final dailyCheck = await _rateLimitingService.checkRateLimit(
        agentId,
        'reservation_create_daily',
      );
      if (!dailyCheck) {
        final info = await _rateLimitingService.getRateLimitInfo(
          agentId,
          'reservation_create_daily',
        );
        return RateLimitCheckResult.denied(
          reason:
              'Too many reservations created today. Limit: ${info.limit} per day.',
          resetAt: info.resetAt,
        );
      }

      // Check 3: Per-target reservation creation rate (per day)
      final targetDailyKey = 'reservation_create_target_daily:$targetId';
      final targetDailyCheck = await _rateLimitingService.checkRateLimit(
        agentId,
        targetDailyKey,
      );
      if (!targetDailyCheck) {
        final info = await _rateLimitingService.getRateLimitInfo(
          agentId,
          targetDailyKey,
        );
        return RateLimitCheckResult.denied(
          reason:
              'Too many reservations at this location today. Limit: ${info.limit} per day per location.',
          resetAt: info.resetAt,
        );
      }

      // Check 4: Per-target reservation creation rate (per week)
      final targetWeeklyKey = 'reservation_create_target_weekly:$targetId';
      final targetWeeklyCheck = await _rateLimitingService.checkRateLimit(
        agentId,
        targetWeeklyKey,
      );
      if (!targetWeeklyCheck) {
        final info = await _rateLimitingService.getRateLimitInfo(
          agentId,
          targetWeeklyKey,
        );
        return RateLimitCheckResult.denied(
          reason:
              'Too many reservations at this location this week. Limit: ${info.limit} per week per location.',
          resetAt: info.resetAt,
        );
      }

      // All checks passed
      final hourlyInfo = await _rateLimitingService.getRateLimitInfo(
        agentId,
        'reservation_create_hourly',
      );
      return RateLimitCheckResult.allowed(
        remaining: hourlyInfo.remaining,
        resetAt: hourlyInfo.resetAt,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error checking rate limit: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Default to allowed on error (don't block reservations if check fails)
      return RateLimitCheckResult.allowed();
    }
  }

  /// Get rate limit information
  ///
  /// **CRITICAL:** Uses agentId (not userId)
  Future<RateLimitCheckResult> getRateLimitInfo({
    required String userId, // Will be converted to agentId internally
    required ReservationType type,
    required String targetId,
  }) async {
    try {
      // Get agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Get hourly rate limit info
      final hourlyInfo = await _rateLimitingService.getRateLimitInfo(
        agentId,
        'reservation_create_hourly',
      );

      return RateLimitCheckResult.allowed(
        remaining: hourlyInfo.remaining,
        resetAt: hourlyInfo.resetAt,
      );
    } catch (e) {
      developer.log(
        'Error getting rate limit info: $e',
        name: _logName,
        error: e,
      );
      return RateLimitCheckResult.allowed();
    }
  }

  /// Reset rate limit for user (admin function)
  Future<void> resetRateLimit({
    required String userId, // Will be converted to agentId internally
    String? targetId,
  }) async {
    developer.log(
      'Resetting rate limit: userId=$userId, targetId=$targetId',
      name: _logName,
    );

    try {
      // Get agentId
      final agentId = await _agentIdService.getUserAgentId(userId);

      if (targetId != null) {
        // Reset target-specific limits
        await _rateLimitingService.resetRateLimit(
          agentId,
          'reservation_create_target_daily:$targetId',
        );
        await _rateLimitingService.resetRateLimit(
          agentId,
          'reservation_create_target_weekly:$targetId',
        );
      } else {
        // Reset all reservation rate limits for user
        await _rateLimitingService.resetRateLimit(
          agentId,
          'reservation_create_hourly',
        );
        await _rateLimitingService.resetRateLimit(
          agentId,
          'reservation_create_daily',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error resetting rate limit: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }
}
