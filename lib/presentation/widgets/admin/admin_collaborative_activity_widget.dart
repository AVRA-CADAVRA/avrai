import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spots/core/models/collaborative_activity_metrics.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget displaying collaborative activity analytics
/// Displays privacy-safe aggregate metrics on AI2AI collaborative patterns
class AdminCollaborativeActivityWidget extends StatefulWidget {
  final AdminGodModeService? godModeService;

  const AdminCollaborativeActivityWidget({
    super.key,
    this.godModeService,
  });

  @override
  State<AdminCollaborativeActivityWidget> createState() =>
      _AdminCollaborativeActivityWidgetState();
}

class _AdminCollaborativeActivityWidgetState
    extends State<AdminCollaborativeActivityWidget> {
  CollaborativeActivityMetrics? _metrics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    if (widget.godModeService == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Admin service not available';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Wire to backend service - Agent 1 implementation complete
      final metrics =
          await widget.godModeService!.getCollaborativeActivityMetrics();

      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load metrics: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Collaborative activity analytics widget',
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_errorMessage != null)
                _buildErrorState()
              else if (_metrics == null ||
                  _metrics!.totalCollaborativeLists == 0)
                _buildEmptyState()
              else ...[
                _buildOverallStats(),
                const SizedBox(height: 24),
                _buildGroupVsDM(),
                const SizedBox(height: 24),
                _buildGroupSizeDistribution(),
                const SizedBox(height: 24),
                _buildEngagementMetrics(),
                const SizedBox(height: 24),
                _buildActivityPattern(),
                const SizedBox(height: 16),
                _buildPrivacyBadge(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Collaborative Activity Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadMetrics,
          tooltip: 'Refresh metrics',
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error loading metrics',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.error,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMetrics,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.group_outlined,
              size: 48,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No collaborative activity data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats() {
    final metrics = _metrics!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Collaboration',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Total Lists',
                '${metrics.totalCollaborativeLists}',
                Icons.list_alt,
              ),
              _buildStatCard(
                'Collaboration Rate',
                '${metrics.collaborationRatePercentage.toStringAsFixed(0)}%',
                Icons.trending_up,
              ),
              _buildStatCard(
                'Avg List Size',
                metrics.avgListSize.toStringAsFixed(1),
                Icons.description,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupVsDM() {
    final metrics = _metrics!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Context Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBreakdownCard(
                  'Group Chats (3+)',
                  metrics.groupChatLists,
                  metrics.groupChatPercentage,
                  AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBreakdownCard(
                  'DMs (2 people)',
                  metrics.dmLists,
                  metrics.dmPercentage,
                  AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(
    String label,
    int count,
    double percentage,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '(${percentage.toStringAsFixed(0)}%)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSizeDistribution() {
    final metrics = _metrics!;
    if (metrics.groupSizeDistribution.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Group Size Distribution',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          ...metrics.groupSizeDistribution.entries.map((entry) {
            final total = metrics.groupSizeDistribution.values
                .fold(0, (sum, count) => sum + count);
            final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      entry.key == 5 ? '5+ people' : '${entry.key} people',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 24,
                        backgroundColor: AppColors.grey200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getDistributionColor(entry.key),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getDistributionColor(int groupSize) {
    switch (groupSize) {
      case 2:
        return AppColors.success;
      case 3:
        return AppColors.primary;
      case 4:
        return AppColors.warning;
      default:
        return AppColors.textSecondary;
    }
  }

  Widget _buildEngagementMetrics() {
    final metrics = _metrics!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Engagement Metrics',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          _buildMetricRow(
            'Planning Sessions',
            metrics.totalPlanningSessions.toString(),
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            'Avg Session Duration',
            '${metrics.avgSessionDuration.toStringAsFixed(1)} minutes',
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            'Follow-Through Rate',
            '${metrics.followThroughRatePercentage.toStringAsFixed(0)}%',
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildActivityPattern() {
    final metrics = _metrics!;
    if (metrics.activityByHour.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity by Hour',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: _ActivityBarChartPainter(metrics.activityByHour),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyBadge() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_outline,
            color: AppColors.success,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Privacy: All metrics are anonymous aggregates. No user data, content, or identities exposed.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for activity bar chart
class _ActivityBarChartPainter extends CustomPainter {
  final Map<int, int> activityByHour;

  _ActivityBarChartPainter(this.activityByHour);

  @override
  void paint(Canvas canvas, Size size) {
    if (activityByHour.isEmpty) return;

    final maxValue = activityByHour.values.reduce((a, b) => a > b ? a : b);
    if (maxValue == 0) return;

    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);
    final barWidth = (chartWidth / activityByHour.length) * 0.7;
    final stepX = chartWidth / activityByHour.length;

    final sortedHours = activityByHour.keys.toList()..sort();

    for (int i = 0; i < sortedHours.length; i++) {
      final hour = sortedHours[i];
      final value = activityByHour[hour]!;
      final normalizedHeight = (value / maxValue) * chartHeight;

      final x = padding + (i * stepX) - (barWidth / 2);
      final y = padding + chartHeight - normalizedHeight;

      final paint = Paint()
        ..color = _getHourColor(hour)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, normalizedHeight),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  Color _getHourColor(int hour) {
    // Color by time of day
    if (hour >= 7 && hour <= 9) {
      return AppColors.primary; // Morning
    } else if (hour >= 17 && hour <= 20) {
      return AppColors.success; // Evening (peak)
    } else {
      return AppColors.textSecondary; // Other hours
    }
  }

  @override
  bool shouldRepaint(_ActivityBarChartPainter oldDelegate) {
    return oldDelegate.activityByHour != activityByHour;
  }
}
