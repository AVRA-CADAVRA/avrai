import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/ai/continuous_learning_system.dart';

/// Continuous Learning Progress Widget
/// 
/// Phase 7, Section 39 (7.4.1): Continuous Learning UI - Integration & Polish
/// 
/// Displays progress for all 10 learning dimensions:
/// - user_preference_understanding
/// - location_intelligence
/// - temporal_patterns
/// - social_dynamics
/// - authenticity_detection
/// - community_evolution
/// - recommendation_accuracy
/// - personalization_depth
/// - trend_prediction
/// - collaboration_effectiveness
/// 
/// Uses AppColors/AppTheme for 100% design token compliance.
class ContinuousLearningProgressWidget extends StatefulWidget {
  final String userId;
  final ContinuousLearningSystem learningSystem;
  
  const ContinuousLearningProgressWidget({
    super.key,
    required this.userId,
    required this.learningSystem,
  });
  
  @override
  State<ContinuousLearningProgressWidget> createState() => _ContinuousLearningProgressWidgetState();
}

class _ContinuousLearningProgressWidgetState extends State<ContinuousLearningProgressWidget> {
  Map<String, double> _progress = {};
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, bool> _expandedSections = {};
  
  // Learning rates for display
  static const Map<String, double> _learningRates = {
    'user_preference_understanding': 0.15,
    'location_intelligence': 0.12,
    'temporal_patterns': 0.10,
    'social_dynamics': 0.13,
    'authenticity_detection': 0.20,
    'community_evolution': 0.11,
    'recommendation_accuracy': 0.18,
    'personalization_depth': 0.16,
    'trend_prediction': 0.14,
    'collaboration_effectiveness': 0.17,
  };
  
  @override
  void initState() {
    super.initState();
    _loadProgress();
    
    // Refresh progress periodically
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _loadProgress();
      }
    });
  }
  
  Future<void> _loadProgress() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final progress = await widget.learningSystem.getLearningProgress();
      
      if (mounted) {
        setState(() {
          _progress = progress;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load progress: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Semantics(
        label: 'Loading learning progress',
        child: const Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Semantics(
        label: 'Error loading learning progress',
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Retry loading progress',
                  button: true,
                  child: TextButton(
                    onPressed: _loadProgress,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_progress.isEmpty) {
      return Semantics(
        label: 'No progress data available',
        child: const Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'No progress data available',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    // Sort dimensions by progress (descending)
    final sortedDimensions = _progress.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Calculate average progress
    final averageProgress = _progress.values.isEmpty
        ? 0.0
        : _progress.values.reduce((a, b) => a + b) / _progress.length;
    
    return Semantics(
      label: 'Learning progress for ${_progress.length} dimensions',
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
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.trending_up,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Learning Progress',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Average Progress
              _buildAverageProgress(averageProgress),
              const SizedBox(height: 24),
              
              // Divider
              const Divider(),
              const SizedBox(height: 16),
              
              // Dimensions List
              Text(
                'Learning Dimensions (${_progress.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...sortedDimensions.map((entry) => _buildProgressItem(
                entry.key,
                entry.value,
              )),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildAverageProgress(double average) {
    final percentage = (average * 100).toStringAsFixed(1);
    final color = _getProgressColor(average);
    
    return Semantics(
      label: 'Average learning progress: $percentage%',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Average Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: average,
              backgroundColor: AppColors.grey200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressItem(String dimension, double progress) {
    final percentage = (progress * 100).toStringAsFixed(1);
    final isExpanded = _expandedSections[dimension] ?? false;
    final progressColor = _getProgressColor(progress);
    final learningRate = _learningRates[dimension] ?? 0.1;
    
    return Semantics(
      label: '${_formatDimensionName(dimension)}: $percentage% progress',
      button: true,
      child: InkWell(
        onTap: () {
          setState(() {
            _expandedSections[dimension] = !isExpanded;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: progressColor.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getDimensionIcon(dimension),
                      color: progressColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDimensionName(dimension),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: progressColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.grey200,
                                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                minHeight: 6,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              
              // Expanded section
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricItem(
                        'Learning Rate',
                        '${(learningRate * 100).toStringAsFixed(0)}%',
                        Icons.speed,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricItem(
                        'Progress',
                        '$percentage%',
                        Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Semantics(
      label: '$label: $value',
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getProgressColor(double progress) {
    if (progress >= 0.75) return AppColors.success;
    if (progress >= 0.5) return AppColors.electricGreen;
    if (progress >= 0.25) return AppColors.warning;
    return AppColors.error;
  }
  
  IconData _getDimensionIcon(String dimension) {
    switch (dimension) {
      case 'user_preference_understanding':
        return Icons.person;
      case 'location_intelligence':
        return Icons.location_on;
      case 'temporal_patterns':
        return Icons.access_time;
      case 'social_dynamics':
        return Icons.people;
      case 'authenticity_detection':
        return Icons.verified;
      case 'community_evolution':
        return Icons.groups;
      case 'recommendation_accuracy':
        return Icons.recommend;
      case 'personalization_depth':
        return Icons.tune;
      case 'trend_prediction':
        return Icons.trending_up;
      case 'collaboration_effectiveness':
        return Icons.handshake;
      default:
        return Icons.insights;
    }
  }
  
  String _formatDimensionName(String dimension) {
    return dimension
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

