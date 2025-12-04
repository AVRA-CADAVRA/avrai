import 'package:flutter/material.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget displaying personality overview with dimensions, confidence, and archetype
class PersonalityOverviewCard extends StatelessWidget {
  final PersonalityProfile profile;

  const PersonalityOverviewCard({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
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
                  'Personality Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  label: Text(
                    profile.archetype.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: AppColors.success.withValues(alpha: 0.2),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Authenticity Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Authenticity',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  '${(profile.authenticity * 100).round()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: profile.authenticity,
                minHeight: 8,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Core Dimensions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...profile.dimensions.entries.map((entry) => _buildDimensionBar(
                  context,
                  entry.key,
                  entry.value,
                  profile.dimensionConfidence[entry.key] ?? 0.0,
                )),
            const SizedBox(height: 16),
            // Evolution Generation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Evolution Generation',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                Text(
                  '${profile.evolutionGeneration}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionBar(
    BuildContext context,
    String dimension,
    double value,
    double confidence,
  ) {
    final displayName = dimension.replaceAll('_', ' ').split(' ').map(
          (word) => word.isEmpty
              ? word
              : word[0].toUpperCase() + word.substring(1),
        ).join(' ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  displayName,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.circle,
                size: 8,
                color: confidence >= 0.7
                    ? AppColors.success
                    : confidence >= 0.4
                        ? AppColors.warning
                        : AppColors.error,
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 6,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getDimensionColor(value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getDimensionColor(double value) {
    if (value >= 0.7) return AppColors.success;
    if (value >= 0.4) return AppColors.warning;
    return AppColors.grey500;
  }
}

