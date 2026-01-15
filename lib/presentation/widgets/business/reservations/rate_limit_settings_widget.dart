// Rate Limit Settings Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
// CRITICAL GAP FIX: Rate limit configuration
//
// Widget for configuring rate limits to prevent abuse

import 'package:flutter/material.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Rate Limit Settings Widget
///
/// **Purpose:** Configure rate limits for reservations
///
/// **Features:**
/// - Per-user reservation limits (per hour, per day)
/// - Per-target reservation limits (per day, per week)
/// - Custom rate limit configuration
class RateLimitSettingsWidget extends StatefulWidget {
  final String businessId;

  const RateLimitSettingsWidget({
    super.key,
    required this.businessId,
  });

  @override
  State<RateLimitSettingsWidget> createState() =>
      _RateLimitSettingsWidgetState();
}

class _RateLimitSettingsWidgetState extends State<RateLimitSettingsWidget> {
  final StorageService _storageService = GetIt.instance<StorageService>();
  static const String _storageKeyPrefix = 'reservation_rate_limit_';
  final _hourlyLimitController = TextEditingController();
  final _dailyLimitController = TextEditingController();
  final _targetDailyLimitController = TextEditingController();
  final _targetWeeklyLimitController = TextEditingController();

  bool _useDefaults = true;
  int? _hourlyLimit;
  int? _dailyLimit;
  int? _targetDailyLimit;
  int? _targetWeeklyLimit;
  bool _isLoading = false;

  // Default limits
  static const int _defaultHourlyLimit = 10;
  static const int _defaultDailyLimit = 50;
  static const int _defaultTargetDailyLimit = 3;
  static const int _defaultTargetWeeklyLimit = 10;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _hourlyLimitController.dispose();
    _dailyLimitController.dispose();
    _targetDailyLimitController.dispose();
    _targetWeeklyLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _useDefaults = _storageService.getBool(
              '${_storageKeyPrefix}use_defaults_${widget.businessId}') ??
          true;

      if (!_useDefaults) {
        final hourlyLimit = _storageService
            .getInt('${_storageKeyPrefix}hourly_${widget.businessId}');
        if (hourlyLimit != null) {
          _hourlyLimit = hourlyLimit;
          _hourlyLimitController.text = _hourlyLimit.toString();
        }

        final dailyLimit = _storageService
            .getInt('${_storageKeyPrefix}daily_${widget.businessId}');
        if (dailyLimit != null) {
          _dailyLimit = dailyLimit;
          _dailyLimitController.text = _dailyLimit.toString();
        }

        final targetDailyLimit = _storageService
            .getInt('${_storageKeyPrefix}target_daily_${widget.businessId}');
        if (targetDailyLimit != null) {
          _targetDailyLimit = targetDailyLimit;
          _targetDailyLimitController.text = _targetDailyLimit.toString();
        }

        final targetWeeklyLimit = _storageService
            .getInt('${_storageKeyPrefix}target_weekly_${widget.businessId}');
        if (targetWeeklyLimit != null) {
          _targetWeeklyLimit = targetWeeklyLimit;
          _targetWeeklyLimitController.text = _targetWeeklyLimit.toString();
        }
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
      await _storageService.setBool(
          '${_storageKeyPrefix}use_defaults_${widget.businessId}',
          _useDefaults);

      if (!_useDefaults) {
        final hourlyLimit = int.tryParse(_hourlyLimitController.text);
        if (hourlyLimit != null && hourlyLimit > 0) {
          await _storageService.setInt(
              '${_storageKeyPrefix}hourly_${widget.businessId}', hourlyLimit);
          _hourlyLimit = hourlyLimit;
        }

        final dailyLimit = int.tryParse(_dailyLimitController.text);
        if (dailyLimit != null && dailyLimit > 0) {
          await _storageService.setInt(
              '${_storageKeyPrefix}daily_${widget.businessId}', dailyLimit);
          _dailyLimit = dailyLimit;
        }

        final targetDailyLimit = int.tryParse(_targetDailyLimitController.text);
        if (targetDailyLimit != null && targetDailyLimit > 0) {
          await _storageService.setInt(
              '${_storageKeyPrefix}target_daily_${widget.businessId}',
              targetDailyLimit);
          _targetDailyLimit = targetDailyLimit;
        }

        final targetWeeklyLimit =
            int.tryParse(_targetWeeklyLimitController.text);
        if (targetWeeklyLimit != null && targetWeeklyLimit > 0) {
          await _storageService.setInt(
              '${_storageKeyPrefix}target_weekly_${widget.businessId}',
              targetWeeklyLimit);
          _targetWeeklyLimit = targetWeeklyLimit;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rate limit settings saved'),
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
            // Use Defaults
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Use Default Rate Limits',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: _useDefaults,
                  onChanged: (value) {
                    setState(() {
                      _useDefaults = value;
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Default limits: $_defaultHourlyLimit per hour, $_defaultDailyLimit per day, $_defaultTargetDailyLimit per location per day, $_defaultTargetWeeklyLimit per location per week',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (!_useDefaults) ...[
              const SizedBox(height: 24),

              // Per-User Limits
              Text(
                'Per-User Limits',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hourlyLimitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Reservations Per Hour',
                  hintText: _defaultHourlyLimit.toString(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.schedule),
                  helperText: 'Maximum reservations a user can make per hour',
                ),
                onChanged: (value) {
                  final limit = int.tryParse(value);
                  if (limit != null && limit > 0) {
                    _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _dailyLimitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Reservations Per Day',
                  hintText: _defaultDailyLimit.toString(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                  helperText: 'Maximum reservations a user can make per day',
                ),
                onChanged: (value) {
                  final limit = int.tryParse(value);
                  if (limit != null && limit > 0) {
                    _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 24),

              // Per-Target Limits
              Text(
                'Per-Location Limits',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _targetDailyLimitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Reservations Per Location Per Day',
                  hintText: _defaultTargetDailyLimit.toString(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.location_on),
                  helperText:
                      'Maximum reservations a user can make at this location per day',
                ),
                onChanged: (value) {
                  final limit = int.tryParse(value);
                  if (limit != null && limit > 0) {
                    _saveSettings();
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _targetWeeklyLimitController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Reservations Per Location Per Week',
                  hintText: _defaultTargetWeeklyLimit.toString(),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.date_range),
                  helperText:
                      'Maximum reservations a user can make at this location per week',
                ),
                onChanged: (value) {
                  final limit = int.tryParse(value);
                  if (limit != null && limit > 0) {
                    _saveSettings();
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
