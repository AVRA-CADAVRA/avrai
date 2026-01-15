// Notification Preferences Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.3: Business Reservation Notifications
//
// Widget for configuring business notification preferences

import 'package:flutter/material.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Notification Preferences Widget
///
/// **Purpose:** Configure notification preferences for business reservations
///
/// **Features:**
/// - New reservation notifications
/// - Reservation modification notifications
/// - Cancellation notifications
/// - No-show alerts
/// - Daily reservation summary
class NotificationPreferencesWidget extends StatefulWidget {
  final String businessId;

  const NotificationPreferencesWidget({
    super.key,
    required this.businessId,
  });

  @override
  State<NotificationPreferencesWidget> createState() =>
      _NotificationPreferencesWidgetState();
}

class _NotificationPreferencesWidgetState
    extends State<NotificationPreferencesWidget> {
  final StorageService _storageService = GetIt.instance<StorageService>();
  static const String _storageKeyPrefix = 'reservation_notification_';

  bool _newReservationEnabled = true;
  bool _modificationEnabled = true;
  bool _cancellationEnabled = true;
  bool _noShowEnabled = true;
  bool _dailySummaryEnabled = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _newReservationEnabled = _storageService.getBool(
              '${_storageKeyPrefix}new_reservation_${widget.businessId}') ??
          true;
      _modificationEnabled = _storageService.getBool(
              '${_storageKeyPrefix}modification_${widget.businessId}') ??
          true;
      _cancellationEnabled = _storageService.getBool(
              '${_storageKeyPrefix}cancellation_${widget.businessId}') ??
          true;
      _noShowEnabled = _storageService
              .getBool('${_storageKeyPrefix}no_show_${widget.businessId}') ??
          true;
      _dailySummaryEnabled = _storageService.getBool(
              '${_storageKeyPrefix}daily_summary_${widget.businessId}') ??
          true;
    } catch (e) {
      // Error loading - use defaults
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _storageService.setBool(
          '${_storageKeyPrefix}new_reservation_${widget.businessId}',
          _newReservationEnabled);
      await _storageService.setBool(
          '${_storageKeyPrefix}modification_${widget.businessId}',
          _modificationEnabled);
      await _storageService.setBool(
          '${_storageKeyPrefix}cancellation_${widget.businessId}',
          _cancellationEnabled);
      await _storageService.setBool(
          '${_storageKeyPrefix}no_show_${widget.businessId}', _noShowEnabled);
      await _storageService.setBool(
          '${_storageKeyPrefix}daily_summary_${widget.businessId}',
          _dailySummaryEnabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification preferences saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Preferences',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Configure which reservation notifications you want to receive',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 16),
            _buildNotificationTile(
              context,
              title: 'New Reservations',
              subtitle: 'Notify when a customer makes a reservation',
              icon: Icons.event_available,
              value: _newReservationEnabled,
              onChanged: (value) {
                setState(() {
                  _newReservationEnabled = value;
                });
                _savePreferences();
              },
            ),
            _buildNotificationTile(
              context,
              title: 'Reservation Modifications',
              subtitle: 'Notify when a customer modifies their reservation',
              icon: Icons.edit,
              value: _modificationEnabled,
              onChanged: (value) {
                setState(() {
                  _modificationEnabled = value;
                });
                _savePreferences();
              },
            ),
            _buildNotificationTile(
              context,
              title: 'Cancellations',
              subtitle: 'Notify when a customer cancels their reservation',
              icon: Icons.cancel,
              value: _cancellationEnabled,
              onChanged: (value) {
                setState(() {
                  _cancellationEnabled = value;
                });
                _savePreferences();
              },
            ),
            _buildNotificationTile(
              context,
              title: 'No-Show Alerts',
              subtitle: 'Notify when a customer doesn\'t show up',
              icon: Icons.warning,
              value: _noShowEnabled,
              onChanged: (value) {
                setState(() {
                  _noShowEnabled = value;
                });
                _savePreferences();
              },
            ),
            _buildNotificationTile(
              context,
              title: 'Daily Summary',
              subtitle: 'Receive a daily summary of reservations',
              icon: Icons.calendar_today,
              value: _dailySummaryEnabled,
              onChanged: (value) {
                setState(() {
                  _dailySummaryEnabled = value;
                });
                _savePreferences();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
