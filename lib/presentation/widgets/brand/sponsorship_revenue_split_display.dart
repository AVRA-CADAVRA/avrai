import 'package:flutter/material.dart';
import 'package:avrai/core/models/revenue_split.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';

/// Sponsorship Revenue Split Display Widget
///
/// Displays revenue breakdown for events with brand sponsorships.
/// Shows platform fees, processing fees, and N-way splits including sponsors.
///
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
///
/// **Features:**
/// - Total revenue display
/// - Platform fee breakdown (10%)
/// - Processing fee breakdown (~3%)
/// - Net revenue after fees
/// - N-way partner splits (including sponsors)
/// - Sponsorship contribution highlight
class SponsorshipRevenueSplitDisplay extends StatelessWidget {
  final RevenueSplit split;
  final double sponsorshipContribution;
  final bool showDetails;

  const SponsorshipRevenueSplitDisplay({
    super.key,
    required this.split,
    required this.sponsorshipContribution,
    this.showDetails = true,
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
            const Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'Revenue Breakdown (with Sponsorship)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
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
                description: '10% to avrai',
              ),
              const SizedBox(height: 8),

              // Processing Fee
              _buildFeeRow(
                label: 'Processing Fee',
                amount: split.processingFee,
                percentage: split.processingFeePercentage,
                description: '~3% to Stripe',
              ),
              const SizedBox(height: 12),
              const Divider(color: AppColors.grey300),
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

            // Sponsorship Contribution Highlight
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.campaign,
                        size: 20,
                        color: AppTheme.primaryColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Your Sponsorship Contribution',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '\$${sponsorshipContribution.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Partner Splits (N-way including sponsors)
            if (split.parties.isNotEmpty) ...[
              const Text(
                'Revenue Distribution',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...split.parties.map((party) => _buildPartyRow(party)),
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
                style: const TextStyle(
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
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)} (${percentage.toStringAsFixed(1)}%)',
          style: const TextStyle(
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
    final isSponsor = party.type == SplitPartyType.sponsor;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSponsor
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppColors.electricGreen.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSponsor
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : AppColors.electricGreen.withValues(alpha: 0.2),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSponsor
                              ? AppTheme.primaryColor.withValues(alpha: 0.2)
                              : AppTheme.primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          partyTypeLabel,
                          style: const TextStyle(
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
                          style: const TextStyle(
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
                      style: const TextStyle(
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
                  color: isSponsor
                      ? AppTheme.primaryColor
                      : AppColors.electricGreen,
                ),
              )
            else if (party.percentage > 0)
              Text(
                '${party.percentage.toStringAsFixed(1)}%',
                style: const TextStyle(
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
