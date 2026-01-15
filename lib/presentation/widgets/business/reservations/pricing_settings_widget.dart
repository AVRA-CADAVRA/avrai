// Pricing Settings Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.2: Business Reservation Settings
//
// Widget for configuring pricing settings (free/paid, deposits, group pricing)

import 'package:flutter/material.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Pricing Settings Widget
///
/// **Purpose:** Configure pricing settings for reservations
///
/// **Features:**
/// - Free/paid toggle (free by default)
/// - Ticket pricing
/// - Deposit requirements (optional)
/// - Group pricing (HIGH PRIORITY GAP FIX)
/// - Ticket limits (max tickets per reservation)
class PricingSettingsWidget extends StatefulWidget {
  final String businessId;

  const PricingSettingsWidget({
    super.key,
    required this.businessId,
  });

  @override
  State<PricingSettingsWidget> createState() => _PricingSettingsWidgetState();
}

class _PricingSettingsWidgetState extends State<PricingSettingsWidget> {
  final StorageService _storageService = GetIt.instance<StorageService>();
  static const String _storageKeyPrefix = 'reservation_pricing_';
  final _ticketPriceController = TextEditingController();
  final _depositAmountController = TextEditingController();
  final _groupSizeController = TextEditingController();
  final _groupDiscountController = TextEditingController();
  final _maxTicketsController = TextEditingController();

  bool _isFree = true;
  double? _ticketPrice;
  bool _requiresDeposit = false;
  double? _depositAmount;
  bool _hasGroupPricing = false;
  int? _groupSize;
  double? _groupDiscount; // Percentage (0.0 to 1.0)
  int? _maxTickets;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _ticketPriceController.dispose();
    _depositAmountController.dispose();
    _groupSizeController.dispose();
    _groupDiscountController.dispose();
    _maxTicketsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _isFree = _storageService
              .getBool('${_storageKeyPrefix}free_${widget.businessId}') ??
          true;

      final ticketPrice = _storageService
          .getDouble('${_storageKeyPrefix}price_${widget.businessId}');
      if (ticketPrice != null) {
        _ticketPrice = ticketPrice;
        _ticketPriceController.text = _ticketPrice!.toStringAsFixed(2);
        _isFree = false;
      }

      _requiresDeposit = _storageService.getBool(
              '${_storageKeyPrefix}deposit_required_${widget.businessId}') ??
          false;

      final depositAmount = _storageService
          .getDouble('${_storageKeyPrefix}deposit_${widget.businessId}');
      if (depositAmount != null) {
        _depositAmount = depositAmount;
        _depositAmountController.text = _depositAmount!.toStringAsFixed(2);
      }

      _hasGroupPricing = _storageService.getBool(
              '${_storageKeyPrefix}group_pricing_${widget.businessId}') ??
          false;

      final groupSize = _storageService
          .getInt('${_storageKeyPrefix}group_size_${widget.businessId}');
      if (groupSize != null) {
        _groupSize = groupSize;
        _groupSizeController.text = _groupSize.toString();
      }

      final groupDiscount = _storageService
          .getDouble('${_storageKeyPrefix}group_discount_${widget.businessId}');
      if (groupDiscount != null) {
        _groupDiscount = groupDiscount;
        _groupDiscountController.text =
            (_groupDiscount! * 100).toStringAsFixed(0);
      }

      final maxTickets = _storageService
          .getInt('${_storageKeyPrefix}max_tickets_${widget.businessId}');
      if (maxTickets != null) {
        _maxTickets = maxTickets;
        _maxTicketsController.text = _maxTickets.toString();
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
          '${_storageKeyPrefix}free_${widget.businessId}', _isFree);

      if (!_isFree) {
        final ticketPrice = double.tryParse(_ticketPriceController.text);
        if (ticketPrice != null && ticketPrice >= 0) {
          await _storageService.setDouble(
              '${_storageKeyPrefix}price_${widget.businessId}', ticketPrice);
          _ticketPrice = ticketPrice;
        }
      } else {
        await _storageService
            .remove('${_storageKeyPrefix}price_${widget.businessId}');
        _ticketPrice = null;
      }

      await _storageService.setBool(
          '${_storageKeyPrefix}deposit_required_${widget.businessId}',
          _requiresDeposit);

      if (_requiresDeposit) {
        final depositAmount = double.tryParse(_depositAmountController.text);
        if (depositAmount != null && depositAmount >= 0) {
          await _storageService.setDouble(
              '${_storageKeyPrefix}deposit_${widget.businessId}',
              depositAmount);
          _depositAmount = depositAmount;
        }
      } else {
        await _storageService
            .remove('${_storageKeyPrefix}deposit_${widget.businessId}');
        _depositAmount = null;
      }

      await _storageService.setBool(
          '${_storageKeyPrefix}group_pricing_${widget.businessId}',
          _hasGroupPricing);

      if (_hasGroupPricing) {
        final groupSize = int.tryParse(_groupSizeController.text);
        if (groupSize != null && groupSize > 0) {
          await _storageService.setInt(
              '${_storageKeyPrefix}group_size_${widget.businessId}', groupSize);
          _groupSize = groupSize;
        }

        final groupDiscountPercent =
            double.tryParse(_groupDiscountController.text);
        if (groupDiscountPercent != null &&
            groupDiscountPercent >= 0 &&
            groupDiscountPercent <= 100) {
          final discount = groupDiscountPercent / 100;
          await _storageService.setDouble(
              '${_storageKeyPrefix}group_discount_${widget.businessId}',
              discount);
          _groupDiscount = discount;
        }
      } else {
        await _storageService
            .remove('${_storageKeyPrefix}group_size_${widget.businessId}');
        await _storageService
            .remove('${_storageKeyPrefix}group_discount_${widget.businessId}');
        _groupSize = null;
        _groupDiscount = null;
      }

      final maxTickets = int.tryParse(_maxTicketsController.text);
      if (maxTickets != null && maxTickets > 0) {
        await _storageService.setInt(
            '${_storageKeyPrefix}max_tickets_${widget.businessId}', maxTickets);
        _maxTickets = maxTickets;
      } else {
        await _storageService
            .remove('${_storageKeyPrefix}max_tickets_${widget.businessId}');
        _maxTickets = null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pricing settings saved'),
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
            // Free/Paid Toggle
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reservation Pricing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: !_isFree,
                  onChanged: (value) {
                    setState(() {
                      _isFree = !value;
                      if (_isFree) {
                        _ticketPriceController.clear();
                        _ticketPrice = null;
                      }
                    });
                    _saveSettings();
                  },
                ),
                const SizedBox(width: 8),
                Text(
                  _isFree ? 'Free' : 'Paid',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Reservations are free by default. Enable paid reservations to require ticket fees.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (!_isFree) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _ticketPriceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Ticket Price (\$)',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                onChanged: (value) {
                  final price = double.tryParse(value);
                  if (price != null && price >= 0) {
                    _saveSettings();
                  }
                },
              ),
            ],
            const SizedBox(height: 24),

            // Deposit Requirements
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Deposit Required',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: _requiresDeposit,
                  onChanged: (value) {
                    setState(() {
                      _requiresDeposit = value;
                      if (!value) {
                        _depositAmountController.clear();
                        _depositAmount = null;
                      }
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            if (_requiresDeposit) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _depositAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Deposit Amount (\$)',
                  hintText: '0.00',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                onChanged: (value) {
                  final amount = double.tryParse(value);
                  if (amount != null && amount >= 0) {
                    _saveSettings();
                  }
                },
              ),
            ],
            const SizedBox(height: 24),

            // Group Pricing (HIGH PRIORITY GAP FIX)
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Group Pricing',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Switch(
                  value: _hasGroupPricing,
                  onChanged: (value) {
                    setState(() {
                      _hasGroupPricing = value;
                      if (!value) {
                        _groupSizeController.clear();
                        _groupDiscountController.clear();
                        _groupSize = null;
                        _groupDiscount = null;
                      }
                    });
                    _saveSettings();
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Enable discounts for large groups',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            if (_hasGroupPricing) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _groupSizeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Group Size',
                        hintText: '10',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.group),
                      ),
                      onChanged: (value) {
                        final size = int.tryParse(value);
                        if (size != null && size > 0) {
                          _saveSettings();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _groupDiscountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Discount (%)',
                        hintText: '10',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.percent),
                      ),
                      onChanged: (value) {
                        final discount = double.tryParse(value);
                        if (discount != null &&
                            discount >= 0 &&
                            discount <= 100) {
                          _saveSettings();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),

            // Max Tickets
            Text(
              'Max Tickets Per Reservation',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum number of tickets allowed per reservation',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _maxTicketsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Max Tickets',
                hintText: 'Leave empty for unlimited',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.confirmation_number),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  _saveSettings();
                } else {
                  final maxTickets = int.tryParse(value);
                  if (maxTickets != null && maxTickets > 0) {
                    _saveSettings();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
