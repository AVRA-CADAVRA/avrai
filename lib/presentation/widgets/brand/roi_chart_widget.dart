import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/pages/brand/brand_analytics_page.dart';

/// ROI Chart Widget
/// 
/// Displays ROI trends and charts for brand analytics.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class ROICartWidget extends StatelessWidget {
  final BrandAnalytics analytics;

  const ROICartWidget({
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
              'ROI Trend',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            // Placeholder for chart - would use a charting library
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 48,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ROI Chart',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${analytics.roiPercentage.toStringAsFixed(0)}% ROI',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: analytics.roiPercentage > 0
                            ? AppColors.electricGreen
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// BrandAnalytics is imported from brand_analytics_page.dart

