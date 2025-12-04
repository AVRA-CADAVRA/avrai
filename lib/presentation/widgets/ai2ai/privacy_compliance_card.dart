import 'package:flutter/material.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget displaying privacy compliance metrics
class PrivacyComplianceCard extends StatelessWidget {
  final PrivacyMetrics privacyMetrics;

  const PrivacyComplianceCard({
    super.key,
    required this.privacyMetrics,
  });

  Color _getComplianceColor(double score) {
    if (score >= 0.95) return AppColors.success;
    if (score >= 0.85) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final complianceScore = privacyMetrics.overallPrivacyScore;
    final color = _getComplianceColor(complianceScore);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Privacy Compliance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  label: Text(
                    '${(complianceScore * 100).round()}%',
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: color.withValues(alpha: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPrivacyMetric(
              context,
              'Anonymization Quality',
              privacyMetrics.anonymizationQuality,
            ),
            const SizedBox(height: 12),
            _buildPrivacyMetric(
              context,
              'Re-identification Risk',
              privacyMetrics.reidentificationRisk,
              isRisk: true,
            ),
            const SizedBox(height: 12),
            _buildPrivacyMetric(
              context,
              'Data Exposure Level',
              privacyMetrics.dataExposureLevel,
              isRisk: true,
            ),
            const SizedBox(height: 12),
            _buildPrivacyMetric(
              context,
              'Privacy Compliance Rate',
              privacyMetrics.complianceRate,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyMetric(
    BuildContext context,
    String label,
    double value, {
    bool isRisk = false,
  }) {
    final displayValue = isRisk
        ? '${(value * 100).toStringAsFixed(1)}%'
        : '${(value * 100).round()}%';
    final color = isRisk
        ? (value < 0.05 ? AppColors.success : AppColors.error)
        : _getComplianceColor(value);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          displayValue,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}

