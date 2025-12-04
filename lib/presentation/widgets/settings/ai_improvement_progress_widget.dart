/// AI Improvement Progress Widget
/// 
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
/// Section 2.2: AI Self-Improvement Visibility
/// 
/// Widget showing AI improvement progress over time:
/// - Progress charts for dimensions
/// - Evolution graphs showing trends
/// - Performance trends over time
/// - Accuracy trends
/// 
/// Location: Settings/Account page
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/services/ai_improvement_tracking_service.dart';

/// Widget displaying AI improvement progress visualization
class AIImprovementProgressWidget extends StatefulWidget {
  /// User ID to show progress for
  final String userId;
  
  /// Improvement tracking service
  final AIImprovementTrackingService trackingService;
  
  /// Time window for history display
  final Duration timeWindow;
  
  const AIImprovementProgressWidget({
    super.key,
    required this.userId,
    required this.trackingService,
    this.timeWindow = const Duration(days: 30),
  });
  
  @override
  State<AIImprovementProgressWidget> createState() => _AIImprovementProgressWidgetState();
}

class _AIImprovementProgressWidgetState extends State<AIImprovementProgressWidget> {
  List<AIImprovementSnapshot> _history = [];
  String _selectedDimension = 'overall';
  
  @override
  void initState() {
    super.initState();
    _loadHistory();
  }
  
  void _loadHistory() {
    setState(() {
      _history = widget.trackingService.getHistory(
        userId: widget.userId,
        timeWindow: widget.timeWindow,
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_history.isEmpty) {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.show_chart,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Progress Data Yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your AI will start tracking improvement progress soon',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    return Semantics(
      label: 'AI Improvement Progress Visualization',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildDimensionSelector(),
              const SizedBox(height: 20),
              _buildProgressChart(),
              const SizedBox(height: 24),
              _buildTrendSummary(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.show_chart,
            color: AppColors.electricGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Progress Visualization',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Last ${widget.timeWindow.inDays} days',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDimensionSelector() {
    final dimensions = _getAvailableDimensions();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: dimensions.map((dimension) {
          final isSelected = _selectedDimension == dimension.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              label: 'Select ${dimension.label} dimension',
              selected: isSelected,
              button: true,
              child: ChoiceChip(
                label: Text(dimension.label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedDimension = dimension.key;
                  });
                },
                selectedColor: AppColors.electricGreen.withValues(alpha: 0.2),
                backgroundColor: AppColors.grey100,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.electricGreen : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildProgressChart() {
    final dataPoints = _getDataPoints(_selectedDimension);
    
    if (dataPoints.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text('No data available for this dimension'),
        ),
      );
    }
    
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _getDimensionLabel(_selectedDimension),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Semantics(
              label: 'Progress chart for ${_getDimensionLabel(_selectedDimension)}',
              child: CustomPaint(
                painter: _LineChartPainter(dataPoints),
                child: Container(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrendSummary() {
    final trend = _calculateTrend();
    final isImproving = trend > 0;
    final color = isImproving ? AppColors.success : 
                  trend < 0 ? AppColors.error : AppColors.warning;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isImproving ? Icons.arrow_upward : 
            trend < 0 ? Icons.arrow_downward : Icons.remove,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isImproving 
                  ? 'Improving: +${(trend * 100).toStringAsFixed(1)}% over period'
                  : trend < 0
                      ? 'Declining: ${(trend * 100).toStringAsFixed(1)}% over period'
                      : 'Stable performance',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<DimensionOption> _getAvailableDimensions() {
    if (_history.isEmpty) return [];
    
    final dimensions = <DimensionOption>[
      DimensionOption('overall', 'Overall'),
    ];
    
    // Get all unique dimensions from history
    final dimensionKeys = <String>{};
    for (final snapshot in _history) {
      dimensionKeys.addAll(snapshot.dimensions.keys);
    }
    
    // Add dimension options
    for (final key in dimensionKeys.take(5)) {
      dimensions.add(DimensionOption(key, _formatDimensionName(key)));
    }
    
    return dimensions;
  }
  
  List<ChartDataPoint> _getDataPoints(String dimension) {
    final points = <ChartDataPoint>[];
    
    for (final snapshot in _history.reversed) {
      final value = dimension == 'overall' 
          ? snapshot.overallScore 
          : snapshot.dimensions[dimension] ?? 0.0;
      
      points.add(ChartDataPoint(
        timestamp: snapshot.timestamp,
        value: value,
      ));
    }
    
    return points;
  }
  
  double _calculateTrend() {
    final dataPoints = _getDataPoints(_selectedDimension);
    
    if (dataPoints.length < 2) return 0.0;
    
    // Note: dataPoints are reversed (newest first), so first is latest, last is oldest
    final latestValue = dataPoints.first.value;  // Newest data point
    final oldestValue = dataPoints.last.value;   // Oldest data point
    
    return latestValue - oldestValue;  // Positive = improving, negative = declining
  }
  
  String _getDimensionLabel(String dimension) {
    if (dimension == 'overall') return 'Overall Performance';
    return _formatDimensionName(dimension);
  }
  
  String _formatDimensionName(String dimension) {
    return dimension
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// Dimension option for selector
class DimensionOption {
  final String key;
  final String label;
  
  DimensionOption(this.key, this.label);
}

/// Chart data point
class ChartDataPoint {
  final DateTime timestamp;
  final double value;
  
  ChartDataPoint({
    required this.timestamp,
    required this.value,
  });
}

/// Custom painter for line chart
class _LineChartPainter extends CustomPainter {
  final List<ChartDataPoint> dataPoints;
  
  _LineChartPainter(this.dataPoints);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;
    
    // Find min and max values for scaling
    final values = dataPoints.map((p) => p.value).toList();
    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final range = maxValue - minValue;
    
    // Create paint for the line
    final linePaint = Paint()
      ..color = AppColors.electricGreen
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Create paint for the fill area
    final fillPaint = Paint()
      ..color = AppColors.electricGreen.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    
    // Create path for the line
    final linePath = Path();
    final fillPath = Path();
    
    // Calculate points
    // Handle single data point case (avoid division by zero)
    final pointSpacing = dataPoints.length > 1 
        ? size.width / (dataPoints.length - 1) 
        : 0.0;
    
    for (int i = 0; i < dataPoints.length; i++) {
      // Center single point, otherwise space evenly
      final x = dataPoints.length == 1 
          ? size.width / 2 
          : i * pointSpacing;
      final normalizedValue = range > 0 ? (dataPoints[i].value - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);
      
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    
    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();
    
    // Draw fill and line
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
    
    // Draw data points
    final pointPaint = Paint()
      ..color = AppColors.electricGreen
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < dataPoints.length; i++) {
      // Center single point, otherwise space evenly
      final x = dataPoints.length == 1 
          ? size.width / 2 
          : i * pointSpacing;
      final normalizedValue = range > 0 ? (dataPoints[i].value - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);
      
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }
  
  @override
  bool shouldRepaint(_LineChartPainter oldDelegate) {
    return oldDelegate.dataPoints != dataPoints;
  }
}

