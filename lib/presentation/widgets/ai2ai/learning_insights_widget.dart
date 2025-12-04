import 'package:flutter/material.dart';
import 'package:spots/core/ai/ai2ai_learning.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget displaying recent learning insights
class LearningInsightsWidget extends StatelessWidget {
  final List<SharedInsight> insights;

  const LearningInsightsWidget({
    super.key,
    required this.insights,
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
                  'Learning Insights',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (insights.isNotEmpty)
                  Chip(
                    label: Text('${insights.length}'),
                    backgroundColor: AppColors.grey100,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (insights.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No insights yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Insights will appear as your AI learns from interactions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ...insights.take(5).map((insight) => _buildInsightCard(context, insight)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, SharedInsight insight) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: AppColors.grey50,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: _getInsightColor(insight).withValues(alpha: 0.2),
          child: Icon(
            _getInsightIcon(insight),
            color: _getInsightColor(insight),
            size: 20,
          ),
        ),
        title: Text(
          insight.category,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              insight.description,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  '${insight.dimension}: ${(insight.value * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• Reliability: ${(insight.reliability * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${_formatTimestamp(insight.timestamp)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getInsightColor(SharedInsight insight) {
    if (insight.reliability >= 0.8) return AppColors.success;
    if (insight.reliability >= 0.5) return AppColors.warning;
    return AppColors.grey500;
  }

  IconData _getInsightIcon(SharedInsight insight) {
    if (insight.reliability >= 0.8) return Icons.trending_up;
    if (insight.reliability >= 0.5) return Icons.info;
    return Icons.help_outline;
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

