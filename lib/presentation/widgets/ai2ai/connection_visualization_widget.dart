import 'package:flutter/material.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget displaying visual network graph of AI2AI connections
class ConnectionVisualizationWidget extends StatelessWidget {
  final ActiveConnectionsOverview overview;
  final String? currentUserId;

  const ConnectionVisualizationWidget({
    super.key,
    required this.overview,
    this.currentUserId,
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
                  'Network Visualization',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  icon: const Icon(Icons.fullscreen),
                  onPressed: () {
                    // TODO: Show fullscreen visualization
                  },
                  tooltip: 'Fullscreen',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (overview.totalActiveConnections == 0)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.account_tree,
                        size: 64,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No connections to visualize',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 300,
                child: _buildNetworkGraph(context),
              ),
            const SizedBox(height: 16),
            // Legend
            _buildLegend(context),
          ],
        ),
      ),
    );
  }

  Widget _buildNetworkGraph(BuildContext context) {
    // Simplified network visualization
    // In a full implementation, this would use a graph library like flutter_graphview
    
    return CustomPaint(
      painter: NetworkGraphPainter(
        connections: overview.topPerformingConnections,
        needsAttention: overview.connectionsNeedingAttention,
        totalConnections: overview.totalActiveConnections,
      ),
      child: Container(),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem(
          context,
          AppColors.success,
          'Top Performing',
        ),
        const SizedBox(width: 16),
        _buildLegendItem(
          context,
          AppColors.warning,
          'Needs Attention',
        ),
        const SizedBox(width: 16),
        _buildLegendItem(
          context,
          AppColors.grey400,
          'Other Connections',
        ),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

/// Custom painter for network graph visualization
class NetworkGraphPainter extends CustomPainter {
  final List<String> connections;
  final List<String> needsAttention;
  final int totalConnections;

  NetworkGraphPainter({
    required this.connections,
    required this.needsAttention,
    required this.totalConnections,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;

    // Draw center node (current user)
    final centerPaint = Paint()
      ..color = AppColors.success
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 20, centerPaint);

    // Draw connection nodes in a circle around center
    final nodeCount = totalConnections.clamp(0, 12); // Limit to 12 nodes for clarity
    final angleStep = (2 * 3.14159) / nodeCount;

    for (int i = 0; i < nodeCount; i++) {
      final angle = angleStep * i;
      final nodeX = center.dx + radius * (1 + 0.3 * (i % 3)) * (i.isEven ? 1 : -1) * (i < 6 ? 1 : -1);
      final nodeY = center.dy + radius * (1 + 0.3 * (i % 3)) * (i < 3 || i > 9 ? 1 : -1);
      final nodePosition = Offset(nodeX, nodeY);

      // Determine node color
      final nodeId = i < connections.length
          ? connections[i]
          : (i < connections.length + needsAttention.length
              ? needsAttention[i - connections.length]
              : 'node_$i');
      
      final isTopPerforming = connections.contains(nodeId);
      final needsAttn = needsAttention.contains(nodeId);

      final nodeColor = isTopPerforming
          ? AppColors.success
          : needsAttn
              ? AppColors.warning
              : AppColors.grey400;

      // Draw connection line
      final linePaint = Paint()
        ..color = nodeColor.withValues(alpha: 0.3)
        ..strokeWidth = 2;
      canvas.drawLine(center, nodePosition, linePaint);

      // Draw node
      final nodePaint = Paint()
        ..color = nodeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(nodePosition, 12, nodePaint);

      // Draw node border
      final borderPaint = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(nodePosition, 12, borderPaint);
    }
  }

  @override
  bool shouldRepaint(NetworkGraphPainter oldDelegate) {
    return oldDelegate.connections != connections ||
        oldDelegate.needsAttention != needsAttention ||
        oldDelegate.totalConnections != totalConnections;
  }
}

