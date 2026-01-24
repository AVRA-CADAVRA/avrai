// Cancellation Policy Settings Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget for configuring cancellation policy settings

import 'package:flutter/material.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_cancellation_policy_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Cancellation Policy Settings Widget
///
/// **Purpose:** Configure cancellation policy for business
///
/// **Features:**
/// - Hours before cancellation requirement
/// - Full/partial refund settings
/// - Refund percentage
/// - Use baseline policy option
class CancellationPolicySettingsWidget extends StatefulWidget {
  final String businessId;

  const CancellationPolicySettingsWidget({
    super.key,
    required this.businessId,
  });

  @override
  State<CancellationPolicySettingsWidget> createState() =>
      _CancellationPolicySettingsWidgetState();
}

class _CancellationPolicySettingsWidgetState
    extends State<CancellationPolicySettingsWidget> {
  final ReservationCancellationPolicyService _policyService =
      GetIt.instance<ReservationCancellationPolicyService>();
  final _hoursController = TextEditingController();
  final _refundPercentageController = TextEditingController();

  bool _useBaseline = true;
  int _hoursBefore = 24;
  bool _allowsRefund = true;
  bool _isFullRefund = true;
  double? _refundPercentage;
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _refundPercentageController.dispose();
    super.dispose();
  }

  Future<void> _loadPolicy() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final policy = await _policyService.getCancellationPolicy(
        type: ReservationType.business,
        targetId: widget.businessId,
      );

      // Check if it's the baseline policy
      final baselinePolicy = _policyService.getBaselinePolicy();
      _useBaseline = policy.hoursBefore == baselinePolicy.hoursBefore &&
          policy.fullRefund == baselinePolicy.fullRefund &&
          policy.partialRefund == baselinePolicy.partialRefund;

      _hoursBefore = policy.hoursBefore;
      _hoursController.text = _hoursBefore.toString();
      _allowsRefund = policy.fullRefund || policy.partialRefund;
      _isFullRefund = policy.fullRefund;
      _refundPercentage = policy.refundPercentage;
      if (_refundPercentage != null) {
        _refundPercentageController.text =
            (_refundPercentage! * 100).toStringAsFixed(0);
      }
    } catch (e) {
      // Error loading - use baseline
      final baselinePolicy = _policyService.getBaselinePolicy();
      _hoursBefore = baselinePolicy.hoursBefore;
      _hoursController.text = _hoursBefore.toString();
      _allowsRefund = true;
      _isFullRefund = true;
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePolicy() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (_useBaseline) {
        // Don't save custom policy - will use baseline
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Using baseline cancellation policy'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      }

      final hoursBefore = int.tryParse(_hoursController.text);
      if (hoursBefore == null || hoursBefore < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid hours before cancellation'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      double? refundPercentage;
      if (!_isFullRefund && _allowsRefund) {
        final percent = double.tryParse(_refundPercentageController.text);
        if (percent != null && percent >= 0 && percent <= 100) {
          refundPercentage = percent / 100;
        }
      }

      await _policyService.setBusinessPolicy(
        businessId: widget.businessId,
        hoursBeforeForRefund: hoursBefore,
        allowsRefund: _allowsRefund,
        refundPercentage: refundPercentage,
        allowsDisputes: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cancellation policy saved'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving policy: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
            // Use Baseline Policy
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Use Baseline Policy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: _useBaseline,
                  onChanged: (value) {
                    setState(() {
                      _useBaseline = value;
                      if (value) {
                        // Reset to baseline
                        final baselinePolicy =
                            _policyService.getBaselinePolicy();
                        _hoursBefore = baselinePolicy.hoursBefore;
                        _hoursController.text = _hoursBefore.toString();
                        _allowsRefund = true;
                        _isFullRefund = true;
                        _refundPercentage = null;
                        _refundPercentageController.clear();
                      }
                    });
                    _savePolicy();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Baseline policy: 24 hours before reservation for full refund',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (!_useBaseline) ...[
              const SizedBox(height: 24),

              // Hours Before
              Text(
                'Hours Before Cancellation',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hours Before',
                  hintText: '24',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.access_time),
                ),
                onChanged: (value) {
                  final hours = int.tryParse(value);
                  if (hours != null && hours >= 0) {
                    setState(() {
                      _hoursBefore = hours;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              // Refund Settings
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Allow Refunds',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Switch(
                    value: _allowsRefund,
                    onChanged: (value) {
                      setState(() {
                        _allowsRefund = value;
                        if (!value) {
                          _isFullRefund = false;
                          _refundPercentage = null;
                          _refundPercentageController.clear();
                        } else {
                          _isFullRefund = true;
                        }
                      });
                    },
                  ),
                ],
              ),
              if (_allowsRefund) ...[
                const SizedBox(height: 16),
                RadioGroup<bool>(
                  groupValue: _isFullRefund,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _isFullRefund = val;
                        if (val) {
                          _refundPercentage = null;
                          _refundPercentageController.clear();
                        }
                      });
                    }
                  },
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Full Refund',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Radio<bool>(
                            value: true,
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Partial Refund',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Radio<bool>(
                            value: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_isFullRefund) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _refundPercentageController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Refund Percentage (%)',
                      hintText: '50',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.percent),
                    ),
                    onChanged: (value) {
                      final percent = double.tryParse(value);
                      if (percent != null && percent >= 0 && percent <= 100) {
                        _refundPercentage = percent / 100;
                      }
                    },
                  ),
                ],
              ],
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePolicy,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Policy'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
