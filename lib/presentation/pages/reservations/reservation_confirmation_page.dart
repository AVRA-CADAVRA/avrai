// Reservation Confirmation Page
//
// Phase 15: Reservation System Implementation
// Section 15.2.1: Reservation Creation UI
//
// Page shown after successful reservation creation

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/presentation/pages/reservations/reservation_detail_page.dart';

/// Reservation Confirmation Page
///
/// **Purpose:** Display confirmation after successful reservation creation
///
/// **Features:**
/// - Success message
/// - Reservation details
/// - Queue position (if applicable)
/// - Waitlist position (if applicable)
/// - Navigation to reservation details
class ReservationConfirmationPage extends StatelessWidget {
  final Reservation reservation;
  final double? compatibilityScore;
  final int? queuePosition;
  final int? waitlistPosition;

  const ReservationConfirmationPage({
    super.key,
    required this.reservation,
    this.compatibilityScore,
    this.queuePosition,
    this.waitlistPosition,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Reservation Confirmed',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 40),

                // Success Icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 80,
                    color: AppTheme.successColor,
                  ),
                ),

                const SizedBox(height: 24),

                // Success Message
                const Text(
                  'Reservation Confirmed!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 12),

                Text(
                  queuePosition != null
                      ? 'Your reservation has been confirmed and added to the queue.'
                      : waitlistPosition != null
                          ? 'Your reservation has been confirmed and added to the waitlist.'
                          : 'Your reservation has been confirmed.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Reservation Details Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.grey300),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow(
                        Icons.event,
                        'Type',
                        reservation.type.toString().split('.').last.toUpperCase(),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.calendar_today,
                        'Date & Time',
                        _formatDateTime(reservation.reservationTime),
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        Icons.people,
                        'Party Size',
                        reservation.partySize.toString(),
                      ),
                      if (reservation.ticketCount != reservation.partySize) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.confirmation_number,
                          'Tickets',
                          reservation.ticketCount.toString(),
                        ),
                      ],
                      if (reservation.ticketPrice != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.attach_money,
                          'Ticket Price',
                          '\$${reservation.ticketPrice!.toStringAsFixed(2)}',
                        ),
                      ],
                      if (reservation.depositAmount != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.payment,
                          'Deposit',
                          '\$${reservation.depositAmount!.toStringAsFixed(2)}',
                        ),
                      ],
                      if (reservation.specialRequests != null &&
                          reservation.specialRequests!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.note,
                          'Special Requests',
                          reservation.specialRequests!,
                        ),
                      ],
                      if (compatibilityScore != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.star,
                          'Compatibility',
                          '${(compatibilityScore! * 100).toStringAsFixed(0)}%',
                        ),
                      ],
                    ],
                  ),
                ),

                // Queue Position (if applicable)
                if (queuePosition != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.queue, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your queue position: #$queuePosition',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Waitlist Position (if applicable)
                if (waitlistPosition != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.warningColor),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: AppTheme.warningColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your waitlist position: #$waitlistPosition',
                            style: const TextStyle(
                              color: AppTheme.warningColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Action Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReservationDetailPage(
                            reservationId: reservation.id,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.event_note, size: 20),
                    label: const Text('View Reservation Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final weekday = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][dateTime.weekday - 1];
    final month = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][dateTime.month - 1];
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour == 0 ? 12 : dateTime.hour;
    final ampm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$weekday, $month ${dateTime.day} at $hour:$minute $ampm';
  }
}
