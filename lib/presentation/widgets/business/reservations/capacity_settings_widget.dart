// Capacity Settings Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget for configuring capacity limits and max party size

import 'package:flutter/material.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Capacity Settings Widget
///
/// **Purpose:** Configure capacity limits and max party size
///
/// **Features:**
/// - Total capacity setting
/// - Max party size setting (HIGH PRIORITY GAP FIX)
/// - Capacity override per time slot (optional)
class CapacitySettingsWidget extends StatefulWidget {
  final String businessId;

  const CapacitySettingsWidget({
    super.key,
    required this.businessId,
  });

  @override
  State<CapacitySettingsWidget> createState() => _CapacitySettingsWidgetState();
}

class _CapacitySettingsWidgetState extends State<CapacitySettingsWidget> {
  final StorageService _storageService = GetIt.instance<StorageService>();
  static const String _storageKeyPrefix = 'reservation_capacity_';
  final _capacityController = TextEditingController();
  final _maxPartySizeController = TextEditingController();

  bool _unlimitedCapacity = true;
  int? _totalCapacity;
  int? _maxPartySize;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _capacityController.dispose();
    _maxPartySizeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final capacity = _storageService
          .getInt('${_storageKeyPrefix}total_${widget.businessId}');
      if (capacity != null) {
        _unlimitedCapacity = false;
        _totalCapacity = capacity;
        _capacityController.text = _totalCapacity.toString();
      } else {
        _unlimitedCapacity = true;
        _totalCapacity = null;
      }

      final maxPartySize = _storageService
          .getInt('${_storageKeyPrefix}max_party_${widget.businessId}');
      if (maxPartySize != null) {
        _maxPartySize = maxPartySize;
        _maxPartySizeController.text = _maxPartySize.toString();
      } else {
        _maxPartySize = null;
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
      if (_unlimitedCapacity) {
        await _storageService
            .remove('${_storageKeyPrefix}total_${widget.businessId}');
      } else {
        final capacity = int.tryParse(_capacityController.text);
        if (capacity != null && capacity > 0) {
          await _storageService.setInt(
              '${_storageKeyPrefix}total_${widget.businessId}', capacity);
          _totalCapacity = capacity;
        }
      }

      final maxPartySize = int.tryParse(_maxPartySizeController.text);
      if (maxPartySize != null && maxPartySize > 0) {
        await _storageService.setInt(
            '${_storageKeyPrefix}max_party_${widget.businessId}', maxPartySize);
        _maxPartySize = maxPartySize;
      } else {
        await _storageService
            .remove('${_storageKeyPrefix}max_party_${widget.businessId}');
        _maxPartySize = null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Capacity settings saved'),
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
            // Total Capacity
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total Capacity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: !_unlimitedCapacity,
                  onChanged: (value) {
                    setState(() {
                      _unlimitedCapacity = !value;
                      if (_unlimitedCapacity) {
                        _capacityController.clear();
                        _totalCapacity = null;
                      }
                    });
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _unlimitedCapacity ? 'Unlimited' : 'Limited',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            if (!_unlimitedCapacity) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Capacity',
                  hintText: 'Enter total capacity',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                onChanged: (value) {
                  // Validate input
                  final capacity = int.tryParse(value);
                  if (capacity != null && capacity > 0) {
                    _saveSettings();
                  }
                },
              ),
            ],
            const SizedBox(height: 24),

            // Max Party Size
            Text(
              'Max Party Size',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum number of people allowed per reservation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxPartySizeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max Party Size',
                hintText: 'Enter max party size (e.g., 10)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
              onChanged: (value) {
                // Validate and save
                final maxPartySize = int.tryParse(value);
                if (maxPartySize != null && maxPartySize > 0) {
                  _saveSettings();
                } else if (value.isEmpty) {
                  // Allow clearing
                  _saveSettings();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
