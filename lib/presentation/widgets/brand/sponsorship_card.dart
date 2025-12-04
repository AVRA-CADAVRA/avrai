import 'package:flutter/material.dart';
import 'package:spots/core/models/sponsorship.dart';
import 'package:spots/core/models/product_tracking.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Sponsorship Card Widget
/// 
/// Displays sponsorship information in a card format.
/// Shows contribution details, status, and product tracking if applicable.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class SponsorshipCard extends StatelessWidget {
  final Sponsorship sponsorship;
  final ProductTracking? productTracking;
  final VoidCallback? onTap;
  final VoidCallback? onManage;
  
  const SponsorshipCard({
    super.key,
    required this.sponsorship,
    this.productTracking,
    this.onTap,
    this.onManage,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status Badge
              _buildStatusBadge(),
              
              const SizedBox(height: 12),
              
              // Event Title (would need to fetch event)
              Text(
                'Event: ${sponsorship.eventId}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Contribution Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Contribution:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Financial Contribution
                    if (sponsorship.contributionAmount != null)
                      _buildContributionRow(
                        Icons.account_balance_wallet,
                        'Cash: \$${sponsorship.contributionAmount!.toStringAsFixed(0)}',
                        'Paid ✅',
                      ),
                    
                    // Product Contribution
                    if (sponsorship.productValue != null) ...[
                      const SizedBox(height: 4),
                      _buildContributionRow(
                        Icons.inventory_2,
                        'Product: \$${sponsorship.productValue!.toStringAsFixed(0)} value',
                        'Delivered ✅',
                      ),
                    ],
                    
                    // Total
                    const SizedBox(height: 8),
                    Divider(color: AppColors.grey300),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Contribution:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '\$${sponsorship.totalContributionValue.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Product Tracking Details
              if (productTracking != null) ...[
                const SizedBox(height: 12),
                _buildProductTrackingSection(productTracking!),
              ],
              
              // Revenue Share
              if (sponsorship.revenueSharePercentage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.trending_up, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Revenue Share: ${sponsorship.revenueSharePercentage!.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.grey300),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onManage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Manage'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge() {
    final status = sponsorship.status;
    Color badgeColor;
    String statusText = status.displayName;
    
    switch (status) {
      case SponsorshipStatus.active:
      case SponsorshipStatus.locked:
      case SponsorshipStatus.approved:
        badgeColor = AppColors.electricGreen;
        break;
      case SponsorshipStatus.pending:
      case SponsorshipStatus.proposed:
      case SponsorshipStatus.negotiating:
        badgeColor = AppColors.warning;
        break;
      case SponsorshipStatus.completed:
        badgeColor = AppColors.textSecondary;
        break;
      case SponsorshipStatus.cancelled:
      case SponsorshipStatus.disputed:
        badgeColor = AppColors.error;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }
  
  Widget _buildContributionRow(IconData icon, String label, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.electricGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductTrackingSection(ProductTracking tracking) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Tracking: ${tracking.productName}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildTrackingRow('Provided', tracking.quantityProvided),
          _buildTrackingRow('Sold', tracking.quantitySold),
          if (tracking.quantityGivenAway > 0)
            _buildTrackingRow('Given Away', tracking.quantityGivenAway),
          if (tracking.quantityUsedInEvent > 0)
            _buildTrackingRow('Used in Event', tracking.quantityUsedInEvent),
          _buildTrackingRow('Remaining', tracking.quantityRemaining),
          if (tracking.hasSales) ...[
            const SizedBox(height: 8),
            Divider(color: AppColors.grey300),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Sales:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '\$${tracking.totalSales.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildTrackingRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

