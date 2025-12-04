import 'package:flutter/material.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/pages/admin/connection_communication_detail_page.dart';

/// Widget displaying list of active AI2AI connections
class ConnectionsList extends StatelessWidget {
  final ActiveConnectionsOverview overview;

  const ConnectionsList({
    super.key,
    required this.overview,
  });

  Color _getQualityColor(double quality) {
    if (quality >= 0.8) return AppColors.success;
    if (quality >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  String _getQualityLabel(double quality) {
    if (quality >= 0.8) return 'Excellent';
    if (quality >= 0.6) return 'Good';
    if (quality >= 0.4) return 'Fair';
    return 'Poor';
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Active Connections',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Chip(
                  label: Text('${overview.totalActiveConnections}'),
                  backgroundColor: AppColors.grey100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (overview.totalActiveConnections == 0)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No active connections',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              )
            else ...[
              if (overview.topPerformingConnections.isNotEmpty) ...[
                Text(
                  'Top Performing',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                ...overview.topPerformingConnections.map((connectionId) => _buildConnectionTile(
                      context,
                      connectionId,
                      isPerforming: true,
                    )),
                const SizedBox(height: 16),
              ],
              if (overview.connectionsNeedingAttention.isNotEmpty) ...[
                Text(
                  'Needs Attention',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warning,
                      ),
                ),
                const SizedBox(height: 8),
                ...overview.connectionsNeedingAttention.map((connectionId) => _buildConnectionTile(
                      context,
                      connectionId,
                      isPerforming: false,
                    )),
                const SizedBox(height: 16),
              ],
              const Divider(),
              const SizedBox(height: 8),
              _buildAggregateMetrics(context, overview.aggregateMetrics),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTile(
    BuildContext context,
    String connectionId, {
    required bool isPerforming,
  }) {
    final color = isPerforming ? AppColors.success : AppColors.warning;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.2),
        child: Icon(
          isPerforming ? Icons.trending_up : Icons.warning,
          color: color,
          size: 20,
        ),
      ),
      title: Text(
        'Connection ${connectionId.length > 8 ? connectionId.substring(0, 8) : connectionId}...',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
      ),
      subtitle: Text(
        isPerforming ? 'High performance connection' : 'May need optimization',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectionCommunicationDetailPage(
              connectionId: connectionId,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAggregateMetrics(BuildContext context, AggregateConnectionMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Aggregate Metrics',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(
              context,
              'Avg Compatibility',
              '${(metrics.averageCompatibility * 100).round()}%',
            ),
            _buildMetricItem(
              context,
              'Avg Duration',
              '${overview.averageConnectionDuration.inMinutes}min',
            ),
            _buildMetricItem(
              context,
              'Total Alerts',
              '${overview.totalAlertsGenerated}',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

