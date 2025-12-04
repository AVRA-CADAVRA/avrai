import 'package:flutter/material.dart';
import 'package:spots/core/models/revenue_split.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Revenue Split Display Widget
/// 
/// Displays transparent revenue breakdown for partnerships.
/// Shows platform fees, processing fees, and N-way partner splits.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
/// 
/// **Features:**
/// - Total revenue display
/// - Platform fee breakdown (10%)
/// - Processing fee breakdown (~3%)
/// - Net revenue after fees
/// - N-way partner splits
/// - Lock status indicator
class RevenueSplitDisplay extends StatelessWidget {
  final RevenueSplit split;
  final bool showDetails;
  final bool showLockStatus;

  const RevenueSplitDisplay({
    super.key,
    required this.split,
    this.showDetails = true,
    this.showLockStatus = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Revenue Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (showLockStatus && split.isLocked) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.electricGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock,
                          size: 12,
                          color: AppColors.electricGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Locked',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.electricGreen,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Total Revenue
            _buildRevenueRow(
              label: 'Total Revenue',
              amount: split.totalAmount,
              isTotal: true,
              ticketsSold: split.ticketsSold,
            ),
            const SizedBox(height: 12),

            if (showDetails) ...[
              // Platform Fee
              _buildFeeRow(
                label: 'Platform Fee',
                amount: split.platformFee,
                percentage: split.platformFeePercentage,
                description: '10% to SPOTS',
              ),
              const SizedBox(height: 8),

              // Processing Fee
              _buildFeeRow(
                label: 'Processing Fee',
                amount: split.processingFee,
                percentage: split.processingFeePercentage,
                description: '~3% to Stripe (2.9% + \$0.30 per ticket)',
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.grey300),
              const SizedBox(height: 12),
            ],

            // Net Revenue
            _buildRevenueRow(
              label: 'Net Revenue',
              amount: split.splitAmount,
              isTotal: false,
              isHighlighted: true,
            ),
            const SizedBox(height: 16),

            // Partner Splits (N-way)
            if (split.parties.isNotEmpty) ...[
              Text(
                'Partner Distribution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...split.parties.map((party) => _buildPartyRow(party)),
            ] else if (split.hostPayout != null) ...[
              // Solo event (legacy)
              _buildRevenueRow(
                label: 'Host Payout',
                amount: split.hostPayout!,
                isTotal: false,
                isHighlighted: true,
              ),
            ],

            if (showLockStatus && !split.isLocked) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 20,
                      color: AppColors.warning,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Revenue split must be locked before event starts',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
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

  Widget _buildRevenueRow({
    required String label,
    required double amount,
    required bool isTotal,
    int? ticketsSold,
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 18 : 16,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (ticketsSold != null && ticketsSold > 0)
              Text(
                '($ticketsSold tickets)',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isTotal ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: isHighlighted
                ? AppColors.electricGreen
                : isTotal
                    ? AppTheme.primaryColor
                    : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeeRow({
    required String label,
    required double amount,
    required double percentage,
    required String description,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPartyRow(SplitParty party) {
    final partyTypeLabel = party.type.displayName;
    final partyName = party.name ?? partyTypeLabel;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.electricGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.electricGreen.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          partyTypeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          partyName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (party.percentage > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${party.percentage.toStringAsFixed(1)}% of net revenue',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (party.amount != null)
              Text(
                '\$${party.amount!.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.electricGreen,
                ),
              )
            else if (party.percentage > 0)
              Text(
                '${party.percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

