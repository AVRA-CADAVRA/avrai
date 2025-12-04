import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget displaying network health score as an enhanced gauge with visual improvements
/// Features: Better gradients, historical trend indicators (sparkline), animated transitions,
/// improved color coding with more granular status
class NetworkHealthGauge extends StatefulWidget {
  final NetworkHealthReport healthReport;

  const NetworkHealthGauge({
    super.key,
    required this.healthReport,
  });

  @override
  State<NetworkHealthGauge> createState() => _NetworkHealthGaugeState();
}

class _NetworkHealthGaugeState extends State<NetworkHealthGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scoreAnimation;
  double _previousScore = 0.0;

  @override
  void initState() {
    super.initState();
    _previousScore = widget.healthReport.overallHealthScore;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: widget.healthReport.overallHealthScore,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _animationController.forward();
  }

  @override
  void didUpdateWidget(NetworkHealthGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.healthReport.overallHealthScore !=
        widget.healthReport.overallHealthScore) {
      _previousScore = oldWidget.healthReport.overallHealthScore;
      _scoreAnimation = Tween<double>(
        begin: _previousScore,
        end: widget.healthReport.overallHealthScore,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ));
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getHealthColor(double score) {
    // More granular color coding
    if (score >= 0.9) return AppColors.success; // Excellent
    if (score >= 0.75) return AppColors.primary; // Very Good
    if (score >= 0.6) return AppColors.warning; // Good
    if (score >= 0.45) return AppColors.warning.withValues(alpha: 0.8); // Fair
    if (score >= 0.3) return AppColors.error.withValues(alpha: 0.7); // Poor
    return AppColors.error; // Critical
  }

  Color _getHealthGradientStart(double score) {
    final baseColor = _getHealthColor(score);
    return baseColor.withValues(alpha: 0.3);
  }

  Color _getHealthGradientEnd(double score) {
    return _getHealthColor(score);
  }

  String _getHealthLabel(double score) {
    if (score >= 0.9) return 'Excellent';
    if (score >= 0.75) return 'Very Good';
    if (score >= 0.6) return 'Good';
    if (score >= 0.45) return 'Fair';
    if (score >= 0.3) return 'Poor';
    return 'Critical';
  }

  List<double> _generateHistoricalData() {
    // Generate mock historical data for sparkline (last 24 hours)
    // In real implementation, this would come from NetworkAnalytics performance history
    final data = <double>[];
    final baseScore = widget.healthReport.overallHealthScore;
    for (int i = 0; i < 24; i++) {
      // Add some variation to create a trend
      final variation = (i % 5) * 0.02 - 0.04; // Small variation
      data.add((baseScore + variation).clamp(0.0, 1.0));
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scoreAnimation,
      builder: (context, child) {
        final score = _scoreAnimation.value;
        final percentage = (score * 100).round();
        final color = _getHealthColor(widget.healthReport.overallHealthScore);
        final label = _getHealthLabel(widget.healthReport.overallHealthScore);
        final historicalData = _generateHistoricalData();

        return Semantics(
          label: 'Network health gauge showing $percentage percent, status: $label',
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'Network Health',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Gradient background circle
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _getHealthGradientStart(
                                  widget.healthReport.overallHealthScore),
                              _getHealthGradientEnd(
                                      widget.healthReport.overallHealthScore)
                                  .withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                      // Enhanced circular progress indicator with gradient
                      SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator(
                          value: score,
                          strokeWidth: 20,
                          backgroundColor: AppColors.grey200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getHealthColor(
                                widget.healthReport.overallHealthScore),
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      // Center content
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$percentage%',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Historical trend sparkline
                  _buildSparkline(historicalData, color),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        context,
                        'Active Connections',
                        '${widget.healthReport.totalActiveConnections}',
                      ),
                      _buildStatItem(
                        context,
                        'Network Utilization',
                        '${(widget.healthReport.networkUtilization * 100).round()}%',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSparkline(List<double> data, Color color) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: CustomPaint(
        painter: _SparklinePainter(data, color),
        child: Container(),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Semantics(
      label: '$label: $value',
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
}

/// Custom painter for sparkline chart
class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minValue = data.reduce((a, b) => a < b ? a : b);
    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    final normalizedRange = range > 0 ? range : 1.0;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final normalizedY = (data[i] - minValue) / normalizedRange;
      final x = i * stepX;
      final y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Fill area under the line
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(_SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}

