// Reservation Actions Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget for displaying action buttons (cancel, modify, dispute)

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Reservation Actions Widget
///
/// **Purpose:** Display action buttons based on reservation status
///
/// **Features:**
/// - Cancel button (if allowed)
/// - Modify button (if allowed, shows modification count)
/// - Dispute button (if applicable)
/// - Check-in button (if applicable)
/// - Proper state management
class ReservationActionsWidget extends StatelessWidget {
  final Reservation reservation;
  final bool canModify;
  final int? modificationCount;
  final String? modificationReason;
  final VoidCallback? onCancel;
  final VoidCallback? onModify;
  final VoidCallback? onDispute;
  final VoidCallback? onCheckIn;
  final bool isLoading;

  const ReservationActionsWidget({
    super.key,
    required this.reservation,
    this.canModify = true,
    this.modificationCount,
    this.modificationReason,
    this.onCancel,
    this.onModify,
    this.onDispute,
    this.onCheckIn,
    this.isLoading = false,
  });

  bool get _isActive =>
      reservation.status == ReservationStatus.pending ||
      reservation.status == ReservationStatus.confirmed;

  bool get _canCancel =>
      _isActive && reservation.status != ReservationStatus.cancelled;

  bool get _canCheckIn =>
      reservation.status == ReservationStatus.confirmed &&
      reservation.reservationTime.difference(DateTime.now()).inHours <= 2;

  @override
  Widget build(BuildContext context) {
    if (!_isActive && _canCheckIn == false) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Modification Info
        if (!canModify && modificationReason != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.warningColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.warningColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        modificationReason!,
                        style: const TextStyle(
                          color: AppTheme.warningColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (modificationCount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Modifications: $modificationCount/3',
                    style: const TextStyle(
                      color: AppTheme.warningColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),

        // Check-in Button
        if (_canCheckIn && onCheckIn != null)
          ElevatedButton.icon(
            onPressed: isLoading ? null : onCheckIn,
            icon: const Icon(Icons.check_circle),
            label: const Text('Check In'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

        // Modify Button
        if (canModify && _isActive && onModify != null) ...[
          if (_canCheckIn) const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onModify,
            icon: const Icon(Icons.edit),
            label: Text(
              modificationCount != null
                  ? 'Modify ($modificationCount/3)'
                  : 'Modify',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],

        // Dispute Button
        if (reservation.disputeStatus == DisputeStatus.none && onDispute != null &&
            (reservation.status == ReservationStatus.cancelled ||
                !_isActive)) ...[
          if (_canCheckIn || (canModify && _isActive))
            const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onDispute,
            icon: const Icon(Icons.help_outline),
            label: const Text('File Dispute'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.warningColor,
              side: const BorderSide(color: AppTheme.warningColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],

        // Cancel Button
        if (_canCancel && onCancel != null) ...[
          if (_canCheckIn ||
              (canModify && _isActive) ||
              (reservation.disputeStatus == DisputeStatus.none && onDispute != null &&
                  (reservation.status == ReservationStatus.cancelled ||
                      !_isActive)))
            const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: isLoading ? null : onCancel,
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel Reservation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
