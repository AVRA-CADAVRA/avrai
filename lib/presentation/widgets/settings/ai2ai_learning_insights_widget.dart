/// AI2AI Learning Insights Widget
/// 
/// Phase 7, Week 38: AI2AI Learning Methods UI - Integration & Polish
/// 
/// Widget displaying recent learning insights:
/// - Recent learning insights list
/// - Cross-personality insights
/// - Emerging patterns
/// - Expandable details
/// 
/// Uses AppColors/AppTheme for 100% design token compliance.

import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/services/ai2ai_learning_service.dart';

/// Widget displaying AI2AI learning insights
class AI2AILearningInsightsWidget extends StatefulWidget {
  /// User ID to show insights for
  final String userId;
  
  /// AI2AI learning service
  final AI2AILearning learningService;
  
  const AI2AILearningInsightsWidget({
    super.key,
    required this.userId,
    required this.learningService,
  });
  
  @override
  State<AI2AILearningInsightsWidget> createState() => _AI2AILearningInsightsWidgetState();
}

class _AI2AILearningInsightsWidgetState extends State<AI2AILearningInsightsWidget> {
  List<LearningInsight> _insights = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Map<String, bool> _expandedInsights = {};

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get learning insights
      final insightsList = await widget.learningService.getLearningInsights(widget.userId);
      final chatHistory = await widget.learningService.getChatHistoryForAdmin(widget.userId);
      
      final insights = <LearningInsight>[];
      
      // Convert insights from service to widget format
      for (final insight in insightsList) {
        insights.add(LearningInsight(
          id: insight.type,
          title: _getInsightTitle(insight.type),
          description: insight.insight,
          type: _mapInsightType(insight.type),
          timestamp: insight.timestamp,
          reliability: insight.reliability,
          details: 'Value: ${insight.value.toStringAsFixed(2)}',
        ));
      }
      
      // If no insights from service, generate from chat history
      if (insights.isEmpty && chatHistory.isNotEmpty) {
        // Insight 1: Cross-personality patterns
        if (chatHistory.length >= 2) {
          insights.add(LearningInsight(
            id: 'cross_personality_1',
            title: 'Cross-Personality Pattern Detected',
            description: 'Your AI has identified patterns across ${chatHistory.length} different personality interactions. '
                'This suggests strong learning from diverse AI personalities.',
            type: InsightType.crossPersonality,
            timestamp: chatHistory.last.timestamp,
            reliability: 0.85,
            details: 'Pattern strength: ${(chatHistory.length / 10.0).clamp(0.0, 1.0).toStringAsFixed(2)}',
          ));
        }
      }
      
      // If no insights, add placeholder
      if (insights.isEmpty) {
        insights.add(LearningInsight(
          id: 'no_insights',
          title: 'No Insights Yet',
          description: 'Start AI2AI connections to generate learning insights. '
              'Your AI will discover patterns and knowledge as it interacts with other AIs.',
          type: InsightType.general,
          timestamp: DateTime.now(),
          reliability: 0.0,
          details: 'Connect with other AIs to begin learning',
        ));
      }

      if (mounted) {
        setState(() {
          _insights = insights;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load insights: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleExpanded(String insightId) {
    setState(() {
      _expandedInsights[insightId] = !(_expandedInsights[insightId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Semantics(
        label: 'Loading learning insights',
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
        label: 'Error loading insights',
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
                  onPressed: _loadInsights,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      label: 'AI2AI learning insights',
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
                      Icons.lightbulb_outline,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Learning Insights',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '${_insights.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_insights.isEmpty)
                _buildEmptyState()
              else
                ..._insights.map((insight) => _buildInsightCard(insight)),
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
              'No insights yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start AI2AI connections to generate insights',
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

  Widget _buildInsightCard(LearningInsight insight) {
    final isExpanded = _expandedInsights[insight.id] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getInsightTypeColor(insight.type).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _toggleExpanded(insight.id),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _getInsightTypeColor(insight.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getInsightTypeIcon(insight.type),
                      color: _getInsightTypeColor(insight.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          insight.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          insight.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: isExpanded ? null : 2,
                          overflow: isExpanded ? null : TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimestamp(insight.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.verified,
                        size: 16,
                        color: _getReliabilityColor(insight.reliability),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${(insight.reliability * 100).toStringAsFixed(0)}% reliable',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getReliabilityColor(insight.reliability),
                        ),
                      ),
                    ],
                  ),
                  if (insight.details != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.grey200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        insight.details!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getInsightTypeColor(InsightType type) {
    switch (type) {
      case InsightType.crossPersonality:
        return AppColors.primary;
      case InsightType.emergingPattern:
        return AppColors.success;
      case InsightType.knowledgeAcquisition:
        return AppColors.warning;
      case InsightType.general:
        return AppColors.textSecondary;
    }
  }

  IconData _getInsightTypeIcon(InsightType type) {
    switch (type) {
      case InsightType.crossPersonality:
        return Icons.people;
      case InsightType.emergingPattern:
        return Icons.trending_up;
      case InsightType.knowledgeAcquisition:
        return Icons.school;
      case InsightType.general:
        return Icons.info;
    }
  }

  Color _getReliabilityColor(double reliability) {
    if (reliability >= 0.8) return AppColors.success;
    if (reliability >= 0.6) return AppColors.warning;
    return AppColors.error;
  }

  String _getInsightTitle(String type) {
    switch (type) {
      case 'interaction_frequency':
        return 'Interaction Frequency Pattern';
      case 'compatibility_evolution':
        return 'Compatibility Evolution';
      case 'knowledge_sharing':
        return 'Knowledge Sharing Pattern';
      case 'trust_building':
        return 'Trust Building Pattern';
      case 'learning_acceleration':
        return 'Learning Acceleration';
      default:
        return 'Learning Insight';
    }
  }

  InsightType _mapInsightType(String type) {
    switch (type) {
      case 'interaction_frequency':
      case 'compatibility_evolution':
        return InsightType.crossPersonality;
      case 'knowledge_sharing':
      case 'learning_acceleration':
        return InsightType.knowledgeAcquisition;
      case 'trust_building':
        return InsightType.emergingPattern;
      default:
        return InsightType.general;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Learning insight data model
class LearningInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final DateTime timestamp;
  final double reliability;
  final String? details;

  LearningInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.timestamp,
    required this.reliability,
    this.details,
  });
}

/// Insight type
enum InsightType {
  crossPersonality,
  emergingPattern,
  knowledgeAcquisition,
  general,
}
