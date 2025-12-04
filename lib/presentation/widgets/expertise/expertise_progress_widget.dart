import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_progress.dart';
import 'package:spots/core/theme/colors.dart';

/// Expertise Progress Widget
/// Shows progress toward next expertise level
/// OUR_GUTS.md: Progress visibility without gamification
class ExpertiseProgressWidget extends StatelessWidget {
  final ExpertiseProgress progress;
  final bool showDetails;
  final VoidCallback? onTap;

  const ExpertiseProgressWidget({
    super.key,
    required this.progress,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  progress.category,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (progress.nextLevel != null)
                  Text(
                    progress.nextLevel!.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Current Level
            Row(
              children: [
                Text(
                  progress.currentLevel.emoji,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 4),
                Text(
                  '${progress.currentLevel.displayName} Level',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (progress.location != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '• ${progress.location}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Progress Bar
            if (progress.nextLevel != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progressPercentage / 100.0,
                  minHeight: 8,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricGreen),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                progress.getFormattedProgress(),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      size: 16,
                      color: AppColors.electricGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Highest level achieved!',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.electricGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Details
            if (showDetails) ...[
              const SizedBox(height: 16),
              _buildContributionSection(),
              if (progress.nextSteps.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildNextStepsSection(),
              ],
              // Locality-specific threshold info (if working toward Local level)
              if (progress.nextLevel != null && 
                  progress.location != null) ...[
                const SizedBox(height: 16),
                _buildLocalityThresholdInfo(),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContributionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Contributions',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          progress.getContributionSummary(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Next Steps',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        ...progress.nextSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6, right: 8),
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.electricGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildLocalityThresholdInfo() {
    // Extract locality from location string
    String? extractLocality(String? location) {
      if (location == null || location.isEmpty) return null;
      final parts = location.split(',').map((s) => s.trim()).toList();
      return parts.isNotEmpty ? parts.first : null;
    }

    final locality = extractLocality(progress.location);
    if (locality == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.electricGreen,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Locality-Specific Qualification',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.electricGreen,
                  ),
                ),
              ),
              Tooltip(
                message: 'Thresholds adapt to what $locality values most. '
                    'Activities valued by your locality have lower thresholds, '
                    'making it easier to qualify as a local expert.',
                child: Icon(
                  Icons.help_outline,
                  size: 14,
                  color: AppColors.electricGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your qualification requirements are adjusted based on what $locality values. '
            'Focus on activities your locality cares about most to reach Local expert faster.',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Expertise Progress Widget
/// Smaller version for use in lists/cards
class CompactExpertiseProgressWidget extends StatelessWidget {
  final ExpertiseProgress progress;

  const CompactExpertiseProgressWidget({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            progress.currentLevel.emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            '${progress.currentLevel.displayName}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          if (progress.nextLevel != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: progress.progressPercentage / 100.0,
                  minHeight: 4,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.electricGreen),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

