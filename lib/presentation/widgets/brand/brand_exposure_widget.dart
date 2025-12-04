import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/pages/brand/brand_analytics_page.dart';

/// Brand Exposure Widget
/// 
/// Displays brand exposure metrics from sponsorships.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class BrandExposureWidget extends StatelessWidget {
  final BrandAnalytics analytics;

  const BrandExposureWidget({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final exposure = analytics.exposureMetrics;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Brand Exposure Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Total Reach
            _buildExposureRow(
              Icons.people,
              'Total Reach',
              _formatNumber(exposure.totalReach),
              'Total audience reached',
            ),
            const SizedBox(height: 12),
            
            // Impressions
            _buildExposureRow(
              Icons.visibility,
              'Impressions',
              _formatNumber(exposure.totalImpressions),
              'Total impressions',
            ),
            const SizedBox(height: 12),
            
            // Product Sampling
            _buildExposureRow(
              Icons.shopping_bag,
              'Product Sampling',
              exposure.productSampling.toString(),
              'People who sampled products',
            ),
            const SizedBox(height: 12),
            
            // Email Signups
            _buildExposureRow(
              Icons.email,
              'Email Signups',
              exposure.emailSignups.toString(),
              'New email subscribers',
            ),
            const SizedBox(height: 12),
            
            // Website Visits
            _buildExposureRow(
              Icons.language,
              'Website Visits',
              exposure.websiteVisits.toString(),
              'Website traffic from events',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExposureRow(IconData icon, String label, String value, String description) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
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
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

// BrandAnalytics, BrandExposureMetrics are imported from brand_analytics_page.dart

