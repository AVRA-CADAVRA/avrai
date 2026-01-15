// Time Slot Settings Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget for configuring time slot intervals

import 'package:flutter/material.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Time Slot Settings Widget
///
/// **Purpose:** Configure time slot intervals for reservations
///
/// **Features:**
/// - Time slot interval (15 min, 30 min, 60 min, etc.)
/// - Default slot duration
class TimeSlotSettingsWidget extends StatefulWidget {
  final String businessId;

  const TimeSlotSettingsWidget({
    super.key,
    required this.businessId,
  });

  @override
  State<TimeSlotSettingsWidget> createState() => _TimeSlotSettingsWidgetState();
}

class _TimeSlotSettingsWidgetState extends State<TimeSlotSettingsWidget> {
  final StorageService _storageService = GetIt.instance<StorageService>();
  static const String _storageKeyPrefix = 'reservation_time_slot_';

  int _slotIntervalMinutes = 30; // Default: 30 minutes
  int _defaultSlotDurationMinutes = 60; // Default: 1 hour
  bool _isLoading = false;

  static const List<int> _intervalOptions = [15, 30, 60, 90, 120];
  static const List<int> _durationOptions = [30, 60, 90, 120, 180];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final interval = _storageService
          .getInt('${_storageKeyPrefix}interval_${widget.businessId}');
      if (interval != null) {
        _slotIntervalMinutes = interval;
      }

      final duration = _storageService
          .getInt('${_storageKeyPrefix}duration_${widget.businessId}');
      if (duration != null) {
        _defaultSlotDurationMinutes = duration;
      }
    } catch (e) {
      // Error loading - use defaults
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _storageService.setInt(
          '${_storageKeyPrefix}interval_${widget.businessId}',
          _slotIntervalMinutes);
      await _storageService.setInt(
          '${_storageKeyPrefix}duration_${widget.businessId}',
          _defaultSlotDurationMinutes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Time slot settings saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $mins minutes';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Slot Interval
            Text(
              'Time Slot Interval',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interval between available reservation times',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _intervalOptions.map((interval) {
                final isSelected = _slotIntervalMinutes == interval;
                return FilterChip(
                  label: Text(_formatMinutes(interval)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _slotIntervalMinutes = interval;
                      });
                      _saveSettings();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Default Slot Duration
            Text(
              'Default Slot Duration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Default duration for each reservation slot',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _durationOptions.map((duration) {
                final isSelected = _defaultSlotDurationMinutes == duration;
                return FilterChip(
                  label: Text(_formatMinutes(duration)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _defaultSlotDurationMinutes = duration;
                      });
                      _saveSettings();
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
