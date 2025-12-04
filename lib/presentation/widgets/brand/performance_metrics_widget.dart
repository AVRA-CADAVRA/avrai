import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/pages/brand/brand_analytics_page.dart';

/// Performance Metrics Widget
/// 
/// Displays performance metrics for brand sponsorships.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PerformanceMetricsWidget extends StatelessWidget {
  final BrandAnalytics analytics;

  const PerformanceMetricsWidget({
    super.key,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Total Events',
                    analytics.performanceMetrics.totalEvents.toString(),
                    Icons.event,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    'Active Sponsorships',
                    analytics.performanceMetrics.activeSponsorships.toString(),
                    Icons.campaign,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Average ROI',
                    '${analytics.performanceMetrics.averageROI.toStringAsFixed(0)}%',
                    Icons.trending_up,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricItem(
                    'Brand Value',
                    '\$${analytics.performanceMetrics.totalBrandValue.toStringAsFixed(0)}',
                    Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// BrandAnalytics, PerformanceMetrics are imported from brand_analytics_page.dart

