// Cancellation Policy Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget for displaying cancellation policy before cancellation

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Cancellation Policy Widget
///
/// **Purpose:** Display cancellation policy information before cancellation
///
/// **Features:**
/// - Policy hours requirement
/// - Refund information (full/partial/none)
/// - Refund percentage display
/// - Cancellation fee display
/// - Time until reservation calculation
/// - Refund eligibility indicator
class CancellationPolicyWidget extends StatelessWidget {
  final CancellationPolicy policy;
  final DateTime reservationTime;
  final DateTime? cancellationTime;
  final double? ticketPrice;
  final int ticketCount;

  const CancellationPolicyWidget({
    super.key,
    required this.policy,
    required this.reservationTime,
    this.cancellationTime,
    this.ticketPrice,
    this.ticketCount = 1,
  });

  /// Check if cancellation qualifies for refund
  bool get _qualifiesForRefund {
    final cancelTime = cancellationTime ?? DateTime.now();
    final hoursUntilReservation = reservationTime.difference(cancelTime).inHours;
    return hoursUntilReservation >= policy.hoursBefore;
  }

  /// Calculate refund amount
  double? get _refundAmount {
    if (!_qualifiesForRefund || ticketPrice == null || ticketPrice! <= 0) {
      return null;
    }

    final totalPrice = ticketPrice! * ticketCount;

    if (policy.fullRefund) {
      return totalPrice;
    }

    if (policy.partialRefund && policy.refundPercentage != null) {
      return totalPrice * policy.refundPercentage!;
    }

    return null;
  }

  /// Get time until reservation
  Duration get _timeUntilReservation {
    final cancelTime = cancellationTime ?? DateTime.now();
    return reservationTime.difference(cancelTime);
  }

  @override
  Widget build(BuildContext context) {
    final qualifies = _qualifiesForRefund;
    final refundAmount = _refundAmount;
    final timeUntil = _timeUntilReservation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: qualifies
            ? AppTheme.successColor.withValues(alpha: 0.1)
            : AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: qualifies ? AppTheme.successColor : AppTheme.warningColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                qualifies ? Icons.check_circle : Icons.warning_amber_rounded,
                color: qualifies ? AppTheme.successColor : AppTheme.warningColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  qualifies ? 'Refund Eligible' : 'Refund Not Eligible',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: qualifies ? AppTheme.successColor : AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Cancellation Policy:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Cancel at least ${policy.hoursBefore} hours before reservation for ${policy.fullRefund ? "full" : policy.partialRefund ? "partial" : "no"} refund',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Time until reservation: ${_formatDuration(timeUntil)}',
            style: TextStyle(
              fontSize: 14,
              color: qualifies ? AppTheme.successColor : AppTheme.warningColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (refundAmount != null && refundAmount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money, color: AppTheme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Estimated refund: \$${refundAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (policy.partialRefund && policy.refundPercentage != null) ...[
            const SizedBox(height: 4),
            Text(
              'Partial refund: ${(policy.refundPercentage! * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (policy.hasCancellationFee && policy.cancellationFee != null) ...[
            const SizedBox(height: 4),
            Text(
              'Cancellation fee: \$${policy.cancellationFee!.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.errorColor,
              ),
            ),
          ],
          if (!qualifies) ...[
            const SizedBox(height: 8),
            Text(
              'You can still cancel, but no refund will be issued. Consider filing a dispute if you have extenuating circumstances.',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'} ${duration.inHours % 24} hour${(duration.inHours % 24) == 1 ? '' : 's'}';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'} ${duration.inMinutes % 60} minute${(duration.inMinutes % 60) == 1 ? '' : 's'}';
    } else {
      return '${duration.inMinutes} minute${duration.inMinutes == 1 ? '' : 's'}';
    }
  }
}
