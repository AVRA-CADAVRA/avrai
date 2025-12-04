import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget displaying learning metrics as an enhanced interactive chart
/// Features: Interactive features, multiple chart types, time range selectors
enum ChartType { line, bar, area }
enum TimeRange { hour, day, week, month }

/// Widget displaying learning metrics as an interactive chart
class LearningMetricsChart extends StatefulWidget {
  final RealTimeMetrics metrics;

  const LearningMetricsChart({
    super.key,
    required this.metrics,
  });

  @override
  State<LearningMetricsChart> createState() => _LearningMetricsChartState();
}

class _LearningMetricsChartState extends State<LearningMetricsChart> {
  ChartType _selectedChartType = ChartType.line;
  TimeRange _selectedTimeRange = TimeRange.day;
  String? _selectedMetric;
  Map<String, double>? _hoveredPoint;

  // Generate mock historical data for visualization
  List<Map<String, double>> _generateHistoricalData(TimeRange range) {
    final now = DateTime.now();
    final dataPoints = <Map<String, double>>[];
    final baseMetrics = widget.metrics;

    int count = 0;
    Duration step = const Duration(hours: 1);
    switch (range) {
      case TimeRange.hour:
        count = 12;
        step = const Duration(minutes: 5);
        break;
      case TimeRange.day:
        count = 24;
        step = const Duration(hours: 1);
        break;
      case TimeRange.week:
        count = 7;
        step = const Duration(days: 1);
        break;
      case TimeRange.month:
        count = 30;
        step = const Duration(days: 1);
        break;
    }

    for (int i = count - 1; i >= 0; i--) {
      final timestamp = now.subtract(step * i);
      // Add some variation to base metrics for historical look
      final variation = (i % 3) * 0.05 - 0.075;
      dataPoints.add({
        'timestamp': timestamp.millisecondsSinceEpoch.toDouble(),
        'matchingSuccessRate': (baseMetrics.matchingSuccessRate + variation)
            .clamp(0.0, 1.0),
        'learningConvergenceSpeed':
            (baseMetrics.learningConvergenceSpeed + variation).clamp(0.0, 1.0),
        'vibeSynchronizationQuality':
            (baseMetrics.vibeSynchronizationQuality + variation).clamp(0.0, 1.0),
        'networkResponsiveness':
            (baseMetrics.networkResponsiveness + variation).clamp(0.0, 1.0),
      });
    }

    return dataPoints;
  }

  void _showMetricDetails(BuildContext context, String metricName, double value) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(metricName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Value: ${(value * 100).toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _getMetricColor(value, true),
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _getMetricDescription(metricName),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getMetricDescription(String metric) {
    switch (metric) {
      case 'Matching Success Rate':
        return 'Percentage of successful personality matches in the AI2AI network.';
      case 'Learning Convergence Speed':
        return 'Rate at which AI personalities converge during learning exchanges.';
      case 'Vibe Synchronization Quality':
        return 'Quality of vibe synchronization between matched personalities.';
      case 'Network Responsiveness':
        return 'Overall responsiveness of the AI2AI network.';
      default:
        return 'Network performance metric.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Learning metrics chart with interactive controls',
      child: Card(
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
                    'Learning Metrics',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  // Time range selector
                  _buildTimeRangeSelector(),
                ],
              ),
              const SizedBox(height: 16),
              // Chart type selector
              _buildChartTypeSelector(),
              const SizedBox(height: 16),
              // Main chart area
              _buildChart(context),
              const SizedBox(height: 16),
              // Legend
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return SegmentedButton<TimeRange>(
      segments: const [
        ButtonSegment(
          value: TimeRange.hour,
          label: Text('1H'),
          tooltip: 'Last hour',
        ),
        ButtonSegment(
          value: TimeRange.day,
          label: Text('1D'),
          tooltip: 'Last day',
        ),
        ButtonSegment(
          value: TimeRange.week,
          label: Text('1W'),
          tooltip: 'Last week',
        ),
        ButtonSegment(
          value: TimeRange.month,
          label: Text('1M'),
          tooltip: 'Last month',
        ),
      ],
      selected: {_selectedTimeRange},
      onSelectionChanged: (Set<TimeRange> selection) {
        setState(() {
          _selectedTimeRange = selection.first;
        });
      },
    );
  }

  Widget _buildChartTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChartTypeButton(ChartType.line, Icons.show_chart, 'Line'),
        const SizedBox(width: 8),
        _buildChartTypeButton(ChartType.bar, Icons.bar_chart, 'Bar'),
        const SizedBox(width: 8),
        _buildChartTypeButton(ChartType.area, Icons.area_chart, 'Area'),
      ],
    );
  }

  Widget _buildChartTypeButton(ChartType type, IconData icon, String label) {
    final isSelected = _selectedChartType == type;
    return Semantics(
      label: '$label chart type${isSelected ? ' selected' : ''}',
      button: true,
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedChartType = type;
            });
          }
        },
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildChart(BuildContext context) {
    final historicalData = _generateHistoricalData(_selectedTimeRange);
    final height = 200.0;

    return GestureDetector(
      onTapDown: (details) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        // Calculate which data point was tapped
        // This is a simplified implementation
        if (historicalData.isNotEmpty) {
          final index = ((localPosition.dx / box.size.width) *
                  historicalData.length)
              .floor()
              .clamp(0, historicalData.length - 1);
          final dataPoint = historicalData[index];
          _showMetricDetails(
            context,
            'Matching Success Rate',
            dataPoint['matchingSuccessRate']!,
          );
        }
      },
      child: Container(
        height: height,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: RepaintBoundary(
          child: CustomPaint(
            painter: _MetricChartPainter(
              historicalData: historicalData,
              chartType: _selectedChartType,
              hoveredPoint: _hoveredPoint,
              metrics: widget.metrics,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        _buildLegendItem(
          'Matching Success Rate',
          AppColors.success,
          widget.metrics.matchingSuccessRate,
        ),
        _buildLegendItem(
          'Learning Convergence',
          AppColors.primary,
          widget.metrics.learningConvergenceSpeed,
        ),
        _buildLegendItem(
          'Vibe Sync',
          AppColors.warning,
          widget.metrics.vibeSynchronizationQuality,
        ),
        _buildLegendItem(
          'Responsiveness',
          AppColors.textSecondary,
          widget.metrics.networkResponsiveness,
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color, double value) {
    return Semantics(
      label: '$label: ${(value * 100).toStringAsFixed(0)}%',
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedMetric = _selectedMetric == label ? null : label;
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _selectedMetric == label
                    ? color
                    : color.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color,
                  width: _selectedMetric == label ? 2 : 1,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _selectedMetric == label
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                    fontWeight: _selectedMetric == label
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMetricColor(double value, bool isPercentage) {
    final normalizedValue = isPercentage ? value : value.clamp(0.0, 1.0);
    if (normalizedValue >= 0.8) return AppColors.success;
    if (normalizedValue >= 0.6) return AppColors.warning;
    return AppColors.error;
  }
}

/// Custom painter for metric charts
class _MetricChartPainter extends CustomPainter {
  final List<Map<String, double>> historicalData;
  final ChartType chartType;
  final Map<String, double>? hoveredPoint;
  final RealTimeMetrics metrics;

  _MetricChartPainter({
    required this.historicalData,
    required this.chartType,
    this.hoveredPoint,
    required this.metrics,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (historicalData.isEmpty) return;

    switch (chartType) {
      case ChartType.line:
        _paintLineChart(canvas, size);
        break;
      case ChartType.bar:
        _paintBarChart(canvas, size);
        break;
      case ChartType.area:
        _paintAreaChart(canvas, size);
        break;
    }
  }

  void _paintLineChart(Canvas canvas, Size size) {
    final metrics = [
      'matchingSuccessRate',
      'learningConvergenceSpeed',
      'vibeSynchronizationQuality',
      'networkResponsiveness',
    ];
    final colors = [
      AppColors.success,
      AppColors.primary,
      AppColors.warning,
      AppColors.textSecondary,
    ];

    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);
    final stepX = chartWidth / (historicalData.length - 1);

    for (int m = 0; m < metrics.length; m++) {
      final metric = metrics[m];
      final color = colors[m];
      final path = Path();
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < historicalData.length; i++) {
        final value = historicalData[i][metric] ?? 0.0;
        final x = padding + (i * stepX);
        final y = padding + chartHeight - (value * chartHeight);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, paint);

      // Draw data points
      final pointPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      for (int i = 0; i < historicalData.length; i++) {
        final value = historicalData[i][metric] ?? 0.0;
        final x = padding + (i * stepX);
        final y = padding + chartHeight - (value * chartHeight);
        canvas.drawCircle(Offset(x, y), 3, pointPaint);
      }
    }
  }

  void _paintBarChart(Canvas canvas, Size size) {
    final metric = 'matchingSuccessRate';
    final color = AppColors.success;
    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);
    final barWidth = (chartWidth / historicalData.length) * 0.7;
    final stepX = chartWidth / historicalData.length;

    final paint = Paint()..color = color;

    for (int i = 0; i < historicalData.length; i++) {
      final value = historicalData[i][metric] ?? 0.0;
      final x = padding + (i * stepX) - (barWidth / 2);
      final barHeight = value * chartHeight;
      final y = padding + chartHeight - barHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  void _paintAreaChart(Canvas canvas, Size size) {
    final metric = 'matchingSuccessRate';
    final color = AppColors.success;
    final padding = 20.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);
    final stepX = chartWidth / (historicalData.length - 1);

    final path = Path();
    path.moveTo(padding, padding + chartHeight);

    for (int i = 0; i < historicalData.length; i++) {
      final value = historicalData[i][metric] ?? 0.0;
      final x = padding + (i * stepX);
      final y = padding + chartHeight - (value * chartHeight);
      path.lineTo(x, y);
    }

    path.lineTo(padding + chartWidth, padding + chartHeight);
    path.close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(_MetricChartPainter oldDelegate) {
    return oldDelegate.historicalData != historicalData ||
        oldDelegate.chartType != chartType ||
        oldDelegate.hoveredPoint != hoveredPoint;
  }
}
