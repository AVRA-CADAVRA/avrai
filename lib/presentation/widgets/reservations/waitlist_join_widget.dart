// Waitlist Join Widget
//
// Phase 15: Reservation System Implementation
// Section 15.2.1: Reservation Creation UI
//
// Widget for joining waitlist when event/spot is sold out

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/services/reservation_waitlist_service.dart';
import 'package:avrai/core/models/reservation.dart';

/// Waitlist Join Widget
///
/// **Purpose:** Allow users to join waitlist when event/spot is sold out
///
/// **Features:**
/// - Join waitlist button
/// - Display waitlist position
/// - Show estimated wait time
/// - Notify when spot becomes available
class WaitlistJoinWidget extends StatefulWidget {
  final ReservationWaitlistService? waitlistService;
  final ReservationType type;
  final String targetId;
  final DateTime reservationTime;
  final String userId;
  final int partySize;
  final Function(WaitlistEntry?) onJoined;
  final Function(String)? onError;

  const WaitlistJoinWidget({
    super.key,
    this.waitlistService,
    required this.type,
    required this.targetId,
    required this.reservationTime,
    required this.userId,
    required this.partySize,
    required this.onJoined,
    this.onError,
  });

  @override
  State<WaitlistJoinWidget> createState() => _WaitlistJoinWidgetState();
}

class _WaitlistJoinWidgetState extends State<WaitlistJoinWidget> {
  bool _isLoading = false;
  int? _position;

  @override
  void initState() {
    super.initState();
    _checkWaitlistStatus();
  }

  Future<void> _checkWaitlistStatus() async {
    if (widget.waitlistService == null) return;

    try {
      // Check if user is already on waitlist using findWaitlistPosition
      final position = await widget.waitlistService!.findWaitlistPosition(
        userId: widget.userId,
        type: widget.type,
        targetId: widget.targetId,
        reservationTime: widget.reservationTime,
      );

      if (position != null) {
        setState(() {
          _position = position;
          // Note: We can't create a full WaitlistEntry here without the entry ID
          // The position is sufficient for display purposes
        });
      }
    } catch (e) {
      // Ignore errors when checking status
    }
  }

  Future<void> _joinWaitlist() async {
    if (widget.waitlistService == null) {
      if (widget.onError != null) {
        widget.onError!('Waitlist service not available');
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Add to waitlist (use partySize as ticketCount)
      final entry = await widget.waitlistService!.addToWaitlist(
        userId: widget.userId,
        type: widget.type,
        targetId: widget.targetId,
        reservationTime: widget.reservationTime,
        ticketCount: widget.partySize, // Use partySize as ticketCount
      );

      // Get position using entry ID
      final position = await widget.waitlistService!.getWaitlistPosition(
        userId: widget.userId,
        waitlistEntryId: entry.id,
      );

      setState(() {
        _position = position ?? entry.position ?? 0;
        _isLoading = false;
      });

      widget.onJoined(entry);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (widget.onError != null) {
        widget.onError!('Failed to join waitlist: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_position != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.primaryColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You are on the waitlist',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your position: #$_position',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You will be notified when a spot becomes available.',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.event_busy, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sold Out',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.warningColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This event/spot is currently sold out. Join the waitlist to be notified if a spot becomes available.',
            style: TextStyle(
              color: AppTheme.warningColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _joinWaitlist,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Icon(Icons.add_circle_outline),
              label: Text(_isLoading ? 'Joining...' : 'Join Waitlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
