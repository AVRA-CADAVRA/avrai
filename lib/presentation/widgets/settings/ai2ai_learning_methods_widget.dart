/// AI2AI Learning Methods Widget
/// 
/// Phase 7, Week 38: AI2AI Learning Methods UI - Integration & Polish
/// 
/// Widget displaying active learning methods, status, and effectiveness scores:
/// - Active learning methods display
/// - Method status (active, paused, completed)
/// - Method effectiveness scores
/// - Visual indicators for method performance
/// 
/// Uses AppColors/AppTheme for 100% design token compliance.

import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/services/ai2ai_learning_service.dart';

/// Widget displaying AI2AI learning methods overview
class AI2AILearningMethodsWidget extends StatefulWidget {
  /// User ID to show methods for
  final String userId;
  
  /// AI2AI learning service
  final AI2AILearning learningService;
  
  const AI2AILearningMethodsWidget({
    super.key,
    required this.userId,
    required this.learningService,
  });
  
  @override
  State<AI2AILearningMethodsWidget> createState() => _AI2AILearningMethodsWidgetState();
}

class _AI2AILearningMethodsWidgetState extends State<AI2AILearningMethodsWidget> {
  List<LearningMethod> _methods = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  Future<void> _loadMethods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get insights to determine active methods
      final insights = await widget.learningService.getLearningInsights(widget.userId);
      
      // Determine active learning methods based on insights
      final methods = <LearningMethod>[];
      
      // Method 1: Cross-Personality Learning
      if (insights.isNotEmpty) {
        final avgReliability = insights.map((i) => i.reliability).reduce((a, b) => a + b) / insights.length;
        methods.add(LearningMethod(
          id: 'cross_personality',
          name: 'Cross-Personality Learning',
          description: 'Learning from interactions with other AI personalities',
          status: LearningMethodStatus.active,
          effectivenessScore: avgReliability,
          lastActive: insights.isNotEmpty ? insights.map((i) => i.timestamp).reduce((a, b) => a.isAfter(b) ? a : b) : DateTime.now(),
        ));
      }
      
      // Method 2: Collective Intelligence
      if (insights.length >= 3) {
        final avgReliability = insights.map((i) => i.reliability).reduce((a, b) => a + b) / insights.length;
        methods.add(LearningMethod(
          id: 'collective_intelligence',
          name: 'Collective Intelligence',
          description: 'Building knowledge from multiple AI interactions',
          status: LearningMethodStatus.active,
          effectivenessScore: avgReliability,
          lastActive: insights.isNotEmpty ? insights.map((i) => i.timestamp).reduce((a, b) => a.isAfter(b) ? a : b) : DateTime.now(),
        ));
      }
      
      // Method 3: Pattern Recognition
      if (insights.length >= 5) {
        final avgReliability = insights.map((i) => i.reliability).reduce((a, b) => a + b) / insights.length;
        methods.add(LearningMethod(
          id: 'pattern_recognition',
          name: 'Pattern Recognition',
          description: 'Identifying patterns across AI2AI conversations',
          status: LearningMethodStatus.active,
          effectivenessScore: avgReliability,
          lastActive: insights.isNotEmpty ? insights.map((i) => i.timestamp).reduce((a, b) => a.isAfter(b) ? a : b) : DateTime.now(),
        ));
      }
      
      // If no methods found, show placeholder
      if (methods.isEmpty) {
        methods.add(LearningMethod(
          id: 'no_methods',
          name: 'No Active Methods',
          description: 'Start AI2AI connections to begin learning',
          status: LearningMethodStatus.paused,
          effectivenessScore: 0.0,
          lastActive: DateTime.now(),
        ));
      }

      if (mounted) {
        setState(() {
          _methods = methods;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load learning methods: $e';
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Semantics(
        label: 'Loading AI2AI learning methods',
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
        label: 'Error loading learning methods',
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
                  onPressed: _loadMethods,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'AI2AI learning methods overview',
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
                      Icons.psychology,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Active Learning Methods',
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
              if (_methods.isEmpty)
                _buildEmptyState()
              else
                ..._methods.map((method) => _buildMethodCard(method)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No active learning methods',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start AI2AI connections to begin learning',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textHint,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard(LearningMethod method) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(method.status).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  method.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              _buildStatusBadge(method.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            method.description,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Effectiveness',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: method.effectivenessScore,
                      backgroundColor: AppColors.grey200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getEffectivenessColor(method.effectivenessScore),
                      ),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${(method.effectivenessScore * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Last Active',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatLastActive(method.lastActive),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(LearningMethodStatus status) {
    final color = _getStatusColor(status);
    final text = _getStatusText(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(LearningMethodStatus status) {
    switch (status) {
      case LearningMethodStatus.active:
        return AppColors.success;
      case LearningMethodStatus.paused:
        return AppColors.warning;
      case LearningMethodStatus.completed:
        return AppColors.textSecondary;
    }
  }

  String _getStatusText(LearningMethodStatus status) {
    switch (status) {
      case LearningMethodStatus.active:
        return 'Active';
      case LearningMethodStatus.paused:
        return 'Paused';
      case LearningMethodStatus.completed:
        return 'Completed';
    }
  }

  Color _getEffectivenessColor(double score) {
    if (score >= 0.7) return AppColors.success;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.error;
  }

  String _formatLastActive(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
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

/// Learning method data model
class LearningMethod {
  final String id;
  final String name;
  final String description;
  final LearningMethodStatus status;
  final double effectivenessScore;
  final DateTime lastActive;

  LearningMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.effectivenessScore,
    required this.lastActive,
  });
}

/// Learning method status
enum LearningMethodStatus {
  active,
  paused,
  completed,
}
