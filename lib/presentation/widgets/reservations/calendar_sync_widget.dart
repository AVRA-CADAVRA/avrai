// Calendar Sync Widget
//
// Phase 10.2: Calendar Integration
// Widget for syncing reservations to device calendar
//
// Displays calendar sync status and allows users to sync/unsync reservations

import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_calendar_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/injection_container.dart' as di;

/// Calendar Sync Widget
///
/// **Purpose:** Display calendar sync status and allow syncing/unsyncing reservations
///
/// **Features:**
/// - Shows current sync status
/// - Sync to calendar button
/// - Unsync from calendar button (if synced)
/// - Loading states
/// - Error handling
/// - Success/error feedback
///
/// **Phase 10.2:** Calendar integration with full AVRAI system integration
class CalendarSyncWidget extends StatefulWidget {
  final Reservation reservation;
  final VoidCallback? onSyncComplete;
  final VoidCallback? onUnsyncComplete;

  const CalendarSyncWidget({
    super.key,
    required this.reservation,
    this.onSyncComplete,
    this.onUnsyncComplete,
  });

  @override
  State<CalendarSyncWidget> createState() => _CalendarSyncWidgetState();
}

class _CalendarSyncWidgetState extends State<CalendarSyncWidget> {
  static const String _logName = 'CalendarSyncWidget';

  late final ReservationCalendarService _calendarService;

  bool _isLoading = false;
  bool _isSynced = false;
  String? _calendarEventId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calendarService = di.sl<ReservationCalendarService>();
    _checkSyncStatus();
  }

  /// Check if reservation is already synced to calendar
  Future<void> _checkSyncStatus() async {
    setState(() {
      _isSynced = widget.reservation.calendarEventId != null;
      _calendarEventId = widget.reservation.calendarEventId;
    });
  }

  /// Sync reservation to device calendar
  Future<void> _syncToCalendar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _calendarService.syncReservationToCalendar(
        reservationId: widget.reservation.id,
      );

      if (mounted) {
        if (result.success) {
          setState(() {
            _isSynced = true;
            _calendarEventId = result.eventId;
            _error = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Reservation synced to calendar successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );

          // Notify parent
          widget.onSyncComplete?.call();
        } else {
          setState(() {
            _error = result.error ?? 'Failed to sync to calendar';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.error ?? 'Failed to sync to calendar'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing reservation to calendar: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _error = 'Failed to sync: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Unsync reservation from calendar
  ///
  /// **Note:** add_2_calendar doesn't support removing events programmatically
  /// This is a placeholder for future implementation
  Future<void> _unsyncFromCalendar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // TODO(Phase 10.2): Implement unsync when calendar event removal is available
      // For now, just clear the calendarEventId from reservation
      // Note: The actual calendar event will remain in the device calendar
      // until the user manually removes it

      developer.log(
        'Unsync not yet implemented (add_2_calendar doesn\'t support removing events)',
        name: _logName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'To remove from calendar, please delete the event manually from your device calendar.',
            ),
            backgroundColor: AppTheme.warningColor,
          ),
        );

        // Note: We can't actually remove the calendar event, but we can
        // clear the reference in the reservation
        // This would require updating the reservation to clear calendarEventId
        // For now, just show the message
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error unsyncing reservation from calendar: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );

      if (mounted) {
        setState(() {
          _error = 'Failed to unsync: ${e.toString()}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unsync: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: _isSynced
            ? AppTheme.successColor.withValues(alpha: 0.1)
            : AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isSynced ? AppTheme.successColor : AppTheme.primaryColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            children: [
              Icon(
                _isSynced ? Icons.event_available : Icons.event,
                color:
                    _isSynced ? AppTheme.successColor : AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isSynced ? 'Synced to Calendar' : 'Sync to Calendar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isSynced
                        ? AppTheme.successColor
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),

          // Status message
          if (_isSynced) ...[
            const SizedBox(height: 8),
            Text(
              'This reservation has been added to your device calendar.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            if (_calendarEventId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Event ID: ${_calendarEventId!.substring(0, _calendarEventId!.length > 20 ? 20 : _calendarEventId!.length)}...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 8),
            Text(
              'Add this reservation to your device calendar to receive reminders and view it alongside your other events.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ],

          // Error message
          if (_error != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.errorColor),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppTheme.errorColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.errorColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons
          const SizedBox(height: 12),
          if (_isSynced) ...[
            // Unsync button (with note about manual removal)
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _unsyncFromCalendar,
              icon: const Icon(Icons.event_busy),
              label: const Text('Remove from Calendar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.warningColor,
                side: const BorderSide(color: AppTheme.warningColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: You may need to manually remove the event from your device calendar.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            // Sync button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _syncToCalendar,
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
                  : const Icon(Icons.event),
              label: Text(_isLoading ? 'Syncing...' : 'Sync to Calendar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
