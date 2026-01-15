// Seating Chart Settings Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget for configuring seating charts (optional feature)

import 'package:flutter/material.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Seating Chart Settings Widget
///
/// **Purpose:** Configure seating charts for reservations
///
/// **Features:**
/// - Enable/disable seating charts
/// - Seat pricing configuration (placeholder)
/// - Seating chart management (placeholder)
class SeatingChartSettingsWidget extends StatefulWidget {
  final String businessId;

  const SeatingChartSettingsWidget({
    super.key,
    required this.businessId,
  });

  @override
  State<SeatingChartSettingsWidget> createState() =>
      _SeatingChartSettingsWidgetState();
}

class _SeatingChartSettingsWidgetState
    extends State<SeatingChartSettingsWidget> {
  final StorageService _storageService = GetIt.instance<StorageService>();
  static const String _storageKeyPrefix = 'reservation_seating_chart_';

  bool _seatingChartsEnabled = false;
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
      _seatingChartsEnabled = _storageService
              .getBool('${_storageKeyPrefix}enabled_${widget.businessId}') ??
          false;
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
          '${_storageKeyPrefix}enabled_${widget.businessId}',
          _seatingChartsEnabled);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seating chart settings saved'),
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
            // Enable Seating Charts
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Enable Seating Charts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: _seatingChartsEnabled,
                  onChanged: (value) async {
                    setState(() {
                      _seatingChartsEnabled = value;
                    });
                    await _saveSettings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Allow customers to select specific seats when making reservations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (_seatingChartsEnabled) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.primaryColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Coming Soon',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Seating chart creation and seat pricing configuration will be available in a future update.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
