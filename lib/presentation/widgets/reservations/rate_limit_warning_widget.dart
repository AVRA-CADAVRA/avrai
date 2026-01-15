// Rate Limit Warning Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.1: Reservation Creation UI
//
// Widget to warn users about rate limits

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_rate_limit_service.dart';

/// Rate Limit Warning Widget
///
/// **Purpose:** Display rate limit warnings and status to users
///
/// **Features:**
/// - Shows current rate limit status
/// - Warns when approaching limits
/// - Blocks when limit exceeded
/// - Displays reset time
class RateLimitWarningWidget extends StatelessWidget {
  final RateLimitCheckResult? rateLimitResult;
  final String? userId;
  final ReservationType? type;
  final String? targetId;

  const RateLimitWarningWidget({
    super.key,
    this.rateLimitResult,
    this.userId,
    this.type,
    this.targetId,
  });

  /// Get warning level based on usage
  WarningLevel get _warningLevel {
    if (rateLimitResult == null) return WarningLevel.none;

    if (!rateLimitResult!.allowed) {
      return WarningLevel.blocked;
    }

    // Check if approaching limits (80% threshold)
    // RateLimitCheckResult only has a single `remaining` field
    // If remaining is low (< 20% of a typical limit), show warning
    if (rateLimitResult!.remaining != null && rateLimitResult!.remaining! < 2) {
      return WarningLevel.warning;
    }

    return WarningLevel.none;
  }

  @override
  Widget build(BuildContext context) {
    if (rateLimitResult == null || _warningLevel == WarningLevel.none) {
      return const SizedBox.shrink();
    }

    final warningLevel = _warningLevel;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: warningLevel == WarningLevel.blocked
            ? AppTheme.errorColor.withValues(alpha: 0.1)
            : AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: warningLevel == WarningLevel.blocked
              ? AppTheme.errorColor
              : AppTheme.warningColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                warningLevel == WarningLevel.blocked
                    ? Icons.error_outline
                    : Icons.warning_amber_rounded,
                color: warningLevel == WarningLevel.blocked
                    ? AppTheme.errorColor
                    : AppTheme.warningColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  warningLevel == WarningLevel.blocked
                      ? 'Rate Limit Exceeded'
                      : 'Rate Limit Warning',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: warningLevel == WarningLevel.blocked
                        ? AppTheme.errorColor
                        : AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (warningLevel == WarningLevel.blocked) ...[
            Text(
              'You have exceeded the rate limit for reservations. Please try again later.',
              style: const TextStyle(
                color: AppTheme.errorColor,
                fontSize: 14,
              ),
            ),
            if (rateLimitResult!.resetAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Resets at: ${_formatResetTime(rateLimitResult!.resetAt!)}',
                style: const TextStyle(
                  color: AppTheme.errorColor,
                  fontSize: 12,
                ),
              ),
            ],
          ] else ...[
            Text(
              'You are approaching the rate limit for reservations.',
              style: const TextStyle(
                color: AppTheme.warningColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            if (rateLimitResult!.remaining != null)
              Text(
                'Remaining: ${rateLimitResult!.remaining}',
                style: const TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 12,
                ),
              ),
            if (rateLimitResult!.resetAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Resets at: ${_formatResetTime(rateLimitResult!.resetAt!)}',
                style: const TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _formatResetTime(DateTime resetTime) {
    final now = DateTime.now();
    final difference = resetTime.difference(now);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours';
    } else {
      return '${difference.inDays} days';
    }
  }
}

/// Warning level enum
enum WarningLevel {
  none,
  warning,
  blocked,
}
