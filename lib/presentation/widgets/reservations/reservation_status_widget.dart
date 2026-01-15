// Reservation Status Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.2: Reservation Management UI
//
// Widget for displaying reservation status badge

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Reservation Status Widget
///
/// **Purpose:** Display reservation status with appropriate color and icon
///
/// **Features:**
/// - Status badge with color coding
/// - Status icon
/// - Optional compact mode for cards
class ReservationStatusWidget extends StatelessWidget {
  final ReservationStatus status;
  final bool compact;

  const ReservationStatusWidget({
    super.key,
    required this.status,
    this.compact = false,
  });

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return AppTheme.warningColor;
      case ReservationStatus.confirmed:
        return AppTheme.successColor;
      case ReservationStatus.cancelled:
        return AppTheme.errorColor;
      case ReservationStatus.completed:
        return AppTheme.primaryColor;
      case ReservationStatus.noShow:
        return AppTheme.errorColor;
    }
  }

  IconData _getStatusIcon(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Icons.schedule;
      case ReservationStatus.confirmed:
        return Icons.check_circle;
      case ReservationStatus.cancelled:
        return Icons.cancel;
      case ReservationStatus.completed:
        return Icons.done_all;
      case ReservationStatus.noShow:
        return Icons.event_busy;
    }
  }

  String _getStatusLabel(ReservationStatus status) {
    return status.toString().split('.').last.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(status);
    final icon = _getStatusIcon(status);
    final label = _getStatusLabel(status);

    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
