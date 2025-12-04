/// AI2AI Learning Effectiveness Widget
/// 
/// Phase 7, Week 38: AI2AI Learning Methods UI - Integration & Polish
/// 
/// Widget displaying learning effectiveness metrics:
/// - Effectiveness metrics display
/// - Learning insights count
/// - Knowledge acquisition rate
/// - Visual indicators (progress bars, charts)
/// 
/// Uses AppColors/AppTheme for 100% design token compliance.

import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/services/ai2ai_learning_service.dart';
import 'package:spots/core/ai/ai2ai_learning.dart';

/// Widget displaying AI2AI learning effectiveness metrics
class AI2AILearningEffectivenessWidget extends StatefulWidget {
  /// User ID to show metrics for
  final String userId;
  
  /// AI2AI learning service
  final AI2AILearning learningService;
  
  const AI2AILearningEffectivenessWidget({
    super.key,
    required this.userId,
    required this.learningService,
  });
  
  @override
  State<AI2AILearningEffectivenessWidget> createState() => _AI2AILearningEffectivenessWidgetState();
}

class _AI2AILearningEffectivenessWidgetState extends State<AI2AILearningEffectivenessWidget> {
  LearningEffectivenessMetrics? _metrics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Measure learning effectiveness
      final metrics = await widget.learningService.analyzeLearningEffectiveness(widget.userId);

      if (mounted) {
        setState(() {
          _metrics = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load effectiveness metrics: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Semantics(
        label: 'Loading learning effectiveness metrics',
        child: const Card(
          margin: EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Semantics(
        label: 'Error loading effectiveness metrics',
        child: Card(
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
                TextButton(
                  onPressed: _loadMetrics,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_metrics == null) {
      return const SizedBox.shrink();
    }

    return Semantics(
      label: 'AI2AI learning effectiveness metrics',
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
                      'Learning Effectiveness',
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
              
              // Overall Effectiveness Score
              _buildOverallScore(_metrics!.overallEffectiveness),
              const SizedBox(height: 24),
              
              // Individual Metrics
              _buildMetricRow(
                'Evolution Rate',
                _metrics!.evolutionRate,
                Icons.timeline,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'Knowledge Acquisition',
                _metrics!.knowledgeAcquisition,
                Icons.lightbulb_outline,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'Insight Quality',
                _metrics!.insightQuality,
                Icons.auto_awesome,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'Trust Network Growth',
                _metrics!.trustNetworkGrowth,
                Icons.people_outline,
              ),
              const SizedBox(height: 12),
              _buildMetricRow(
                'Collective Contribution',
                _metrics!.collectiveContribution,
                Icons.share,
              ),
              const SizedBox(height: 16),
              
              // Summary Stats
              _buildSummaryStats(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverallScore(double score) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Overall Effectiveness',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: _getScoreColor(score),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: score,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getScoreColor(score),
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, double value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(value * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getScoreColor(value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getScoreColor(value),
                ),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Interactions',
            _metrics!.totalInteractions.toString(),
            Icons.chat_bubble_outline,
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.grey300,
          ),
          _buildStatItem(
            'Time Window',
            '${_metrics!.timeWindow.inDays} days',
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.7) return AppColors.success;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.error;
  }
}
