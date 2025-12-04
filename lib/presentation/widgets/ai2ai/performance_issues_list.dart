import 'package:flutter/material.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget displaying performance issues and optimization recommendations
class PerformanceIssuesList extends StatelessWidget {
  final List<PerformanceIssue> issues;
  final List<OptimizationRecommendation> recommendations;

  const PerformanceIssuesList({
    super.key,
    required this.issues,
    required this.recommendations,
  });

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return AppColors.error;
      case 'high':
        return AppColors.warning;
      default:
        return AppColors.grey600;
    }
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance & Optimization',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            if (issues.isEmpty && recommendations.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No issues detected. Network operating optimally.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              )
            else ...[
              if (issues.isNotEmpty) ...[
                Text(
                  'Issues (${issues.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...issues.map((issue) => _buildIssueTile(context, issue)),
                const SizedBox(height: 16),
              ],
              if (recommendations.isNotEmpty) ...[
                Text(
                  'Recommendations (${recommendations.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...recommendations.map((rec) => _buildRecommendationTile(context, rec)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIssueTile(BuildContext context, PerformanceIssue issue) {
    final color = _getSeverityColor(issue.severity.name);
    final icon = _getSeverityIcon(issue.severity.name);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        issue.description,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      trailing: Chip(
        label: Text(
          issue.severity.name,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.2),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  Widget _buildRecommendationTile(
    BuildContext context,
    OptimizationRecommendation recommendation,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: const Icon(Icons.lightbulb_outline, color: AppColors.success, size: 20),
      title: Text(
        recommendation.recommendation,
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      subtitle: recommendation.priority != null
          ? Text(
              'Priority: ${recommendation.priority}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            )
          : null,
    );
  }
}

