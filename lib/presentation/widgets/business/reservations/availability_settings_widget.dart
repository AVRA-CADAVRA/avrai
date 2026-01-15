// Availability Settings Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
// CRITICAL GAP FIX: Business hours and holiday/closure calendar configuration
//
// Widget for configuring business hours and holiday/closure dates

import 'package:flutter/material.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Availability Settings Widget
///
/// **Purpose:** Configure business hours and holiday/closure calendar
///
/// **Features:**
/// - Business hours configuration (CRITICAL GAP FIX)
/// - Holiday/closure calendar (CRITICAL GAP FIX)
/// - Availability toggle
class AvailabilitySettingsWidget extends StatefulWidget {
  final String businessId;

  const AvailabilitySettingsWidget({
    super.key,
    required this.businessId,
  });

  @override
  State<AvailabilitySettingsWidget> createState() =>
      _AvailabilitySettingsWidgetState();
}

class _AvailabilitySettingsWidgetState
    extends State<AvailabilitySettingsWidget> {
  final StorageService _storageService = GetIt.instance<StorageService>();
  static const String _storageKeyPrefix = 'reservation_availability_';

  // Business hours (simplified - stores as JSON for now)
  Map<String, Map<String, String>> _businessHours = {};
  List<DateTime> _holidayDates = [];
  List<DateTime> _closureDates = [];
  bool _isAvailable = true;
  bool _isLoading = false;

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
      // Load business hours
      final hoursJson = _storageService.getObject<Map<String, dynamic>>(
          '${_storageKeyPrefix}hours_${widget.businessId}');
      if (hoursJson != null) {
        _businessHours = hoursJson.map((key, value) => MapEntry(
              key,
              Map<String, String>.from(value as Map),
            ));
      } else {
        // Default hours (9 AM - 10 PM, Monday-Sunday)
        _businessHours = _getDefaultHours();
      }

      // Load holiday dates
      final holidaysJson = _storageService
          .getStringList('${_storageKeyPrefix}holidays_${widget.businessId}');
      if (holidaysJson != null) {
        _holidayDates = holidaysJson.map((d) => DateTime.parse(d)).toList();
      }

      // Load closure dates
      final closuresJson = _storageService
          .getStringList('${_storageKeyPrefix}closures_${widget.businessId}');
      if (closuresJson != null) {
        _closureDates = closuresJson.map((d) => DateTime.parse(d)).toList();
      }

      // Load availability toggle
      _isAvailable = _storageService
              .getBool('${_storageKeyPrefix}available_${widget.businessId}') ??
          true;
    } catch (e) {
      // Error loading - use defaults
      _businessHours = _getDefaultHours();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, Map<String, String>> _getDefaultHours() {
    return {
      'Monday': {'open': '09:00', 'close': '22:00'},
      'Tuesday': {'open': '09:00', 'close': '22:00'},
      'Wednesday': {'open': '09:00', 'close': '22:00'},
      'Thursday': {'open': '09:00', 'close': '22:00'},
      'Friday': {'open': '09:00', 'close': '22:00'},
      'Saturday': {'open': '09:00', 'close': '22:00'},
      'Sunday': {'open': '09:00', 'close': '22:00'},
    };
  }

  Future<void> _saveSettings() async {
    try {
      await _storageService.setObject(
          '${_storageKeyPrefix}hours_${widget.businessId}',
          _businessHours.map((key, value) => MapEntry(key, value)));
      await _storageService.setStringList(
        '${_storageKeyPrefix}holidays_${widget.businessId}',
        _holidayDates.map((d) => d.toIso8601String()).toList(),
      );
      await _storageService.setStringList(
        '${_storageKeyPrefix}closures_${widget.businessId}',
        _closureDates.map((d) => d.toIso8601String()).toList(),
      );
      await _storageService.setBool(
          '${_storageKeyPrefix}available_${widget.businessId}', _isAvailable);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability settings saved'),
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

  Future<void> _selectHolidayDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && !mounted) return;

    if (selected != null) {
      setState(() {
        _holidayDates
            .add(DateTime(selected.year, selected.month, selected.day));
        _holidayDates.sort();
      });
      await _saveSettings();
    }
  }

  Future<void> _selectClosureDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null && !mounted) return;

    if (selected != null) {
      setState(() {
        _closureDates
            .add(DateTime(selected.year, selected.month, selected.day));
        _closureDates.sort();
      });
      await _saveSettings();
    }
  }

  Future<void> _editHours(String day) async {
    final currentHours =
        _businessHours[day] ?? {'open': '09:00', 'close': '22:00'};
    final openTime = TimeOfDay(
      hour: int.parse(currentHours['open']!.split(':')[0]),
      minute: int.parse(currentHours['open']!.split(':')[1]),
    );
    final closeTime = TimeOfDay(
      hour: int.parse(currentHours['close']!.split(':')[0]),
      minute: int.parse(currentHours['close']!.split(':')[1]),
    );

    final open = await showTimePicker(
      context: context,
      initialTime: openTime,
    );
    if (open != null && !mounted) return;

    if (open != null) {
      final close = await showTimePicker(
        context: context,
        initialTime: closeTime,
      );
      if (close != null && !mounted) return;

      if (close != null) {
        setState(() {
          _businessHours[day] = {
            'open':
                '${open.hour.toString().padLeft(2, '0')}:${open.minute.toString().padLeft(2, '0')}',
            'close':
                '${close.hour.toString().padLeft(2, '0')}:${close.minute.toString().padLeft(2, '0')}',
          };
        });
        await _saveSettings();
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
            // Availability Toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Accept Reservations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: _isAvailable,
                  onChanged: (value) async {
                    setState(() {
                      _isAvailable = value;
                    });
                    await _saveSettings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Business Hours
            Text(
              'Business Hours',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ..._businessHours.entries.map((entry) {
              final day = entry.key;
              final hours = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${hours['open']} - ${hours['close']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _editHours(day),
                      child: const Text('Edit'),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),

            // Holiday Calendar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Holidays',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: _selectHolidayDate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Holiday'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_holidayDates.isEmpty)
              Text(
                'No holidays configured',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final date in _holidayDates)
                    Chip(
                      label: Text(_formatDate(date)),
                      onDeleted: () async {
                        setState(() {
                          _holidayDates.remove(date);
                        });
                        await _saveSettings();
                      },
                    ),
                ],
              ),
            const SizedBox(height: 24),

            // Closure Dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Closure Dates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: _selectClosureDate,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Closure'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_closureDates.isEmpty)
              Text(
                'No closure dates configured',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final date in _closureDates)
                    Chip(
                      label: Text(_formatDate(date)),
                      onDeleted: () async {
                        setState(() {
                          _closureDates.remove(date);
                        });
                        await _saveSettings();
                      },
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
