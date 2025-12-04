import 'package:flutter/material.dart';
import 'package:spots/core/models/saturation_metrics.dart';
import 'package:spots/core/theme/colors.dart';

/// Saturation Info Widget
/// 
/// Displays category saturation information and how it affects expertise requirements.
/// Shows 6-factor breakdown and recommendations.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to expertise recognition
/// - Maintains quality through transparent saturation info
/// - Prevents oversaturation while allowing growth
class SaturationInfoWidget extends StatelessWidget {
  final SaturationMetrics saturationMetrics;
  final bool showDetails;

  const SaturationInfoWidget({
    super.key,
    required this.saturationMetrics,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getRecommendationColor(),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.analytics,
                size: 20,
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Category Saturation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getRecommendationColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  saturationMetrics.recommendation.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getRecommendationColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Saturation score
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saturation Score',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(saturationMetrics.saturationScore * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expert Ratio',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(saturationMetrics.saturationRatio * 100).toStringAsFixed(2)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: saturationMetrics.saturationScore.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(_getRecommendationColor()),
            ),
          ),
          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  label: 'Experts',
                  value: saturationMetrics.currentExpertCount.toString(),
                ),
              ),
              Expanded(
                child: _buildStat(
                  label: 'Users',
                  value: saturationMetrics.totalUserCount.toString(),
                ),
              ),
              Expanded(
                child: _buildStat(
                  label: 'Quality',
                  value: '${(saturationMetrics.qualityScore * 100).toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),

          // 6-Factor Breakdown (if details shown)
          if (showDetails) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '6-Factor Analysis',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildFactorRow('Supply Ratio', saturationMetrics.factors.supplyRatio, 0.25),
            _buildFactorRow('Quality Distribution', saturationMetrics.factors.qualityDistribution, 0.20),
            _buildFactorRow('Utilization Rate', saturationMetrics.factors.utilizationRate, 0.20),
            _buildFactorRow('Demand Signal', saturationMetrics.factors.demandSignal, 0.15),
            _buildFactorRow('Growth Velocity', saturationMetrics.factors.growthVelocity, 0.10),
            _buildFactorRow('Geographic Distribution', saturationMetrics.factors.geographicDistribution, 0.10),
          ],
        ],
      ),
    );
  }

  Widget _buildStat({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFactorRow(String label, double value, double weight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '${(weight * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRecommendationColor() {
    switch (saturationMetrics.recommendation) {
      case SaturationRecommendation.decrease:
        return AppColors.electricGreen;
      case SaturationRecommendation.maintain:
        return AppColors.primaryBlue;
      case SaturationRecommendation.increase:
        return AppColors.warning;
      case SaturationRecommendation.significantIncrease:
        return AppColors.error;
    }
  }
}

