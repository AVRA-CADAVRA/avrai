import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/event_success_metrics.dart';
import 'package:spots/core/models/event_success_level.dart';
import 'package:spots/core/services/event_success_analysis_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/post_event_feedback_service.dart';
import 'package:spots/core/services/payment_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Event Success Dashboard
/// 
/// Agent 2: Phase 5, Week 17 - Success Dashboard UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Success level badge
/// - Key metrics display (attendance, revenue, rating)
/// - NPS score display
/// - Success factors display
/// - Improvement areas display
/// - Partner satisfaction scores
/// - Comparison to similar events
/// - Actionable recommendations
class EventSuccessDashboard extends StatefulWidget {
  final ExpertiseEvent event;

  const EventSuccessDashboard({
    super.key,
    required this.event,
  });

  @override
  State<EventSuccessDashboard> createState() => _EventSuccessDashboardState();
}

class _EventSuccessDashboardState extends State<EventSuccessDashboard> {
  final EventSuccessAnalysisService _analysisService = EventSuccessAnalysisService(
    eventService: GetIt.instance<ExpertiseEventService>(),
    feedbackService: PostEventFeedbackService(
      eventService: GetIt.instance<ExpertiseEventService>(),
    ),
    paymentService: GetIt.instance<PaymentService>(),
  );

  EventSuccessMetrics? _metrics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Try to get existing metrics first
      var metrics = await _analysisService.getEventMetrics(widget.event.id);
      
      // If no metrics exist, analyze the event
      if (metrics == null) {
        metrics = await _analysisService.analyzeEventSuccess(widget.event.id);
      }

      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Event Success Dashboard',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMetrics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_metrics == null) {
      return const Center(
        child: Text('No metrics available'),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Level Badge
            _buildSuccessLevelBadge(),
            const SizedBox(height: 24),

            // Key Metrics
            _buildKeyMetrics(),
            const SizedBox(height: 24),

            // NPS Score
            _buildNPSScore(),
            const SizedBox(height: 24),

            // Success Factors
            if (_metrics!.successFactors.isNotEmpty) ...[
              _buildSuccessFactors(),
              const SizedBox(height: 24),
            ],

            // Improvement Areas
            if (_metrics!.improvementAreas.isNotEmpty) ...[
              _buildImprovementAreas(),
              const SizedBox(height: 24),
            ],

            // Partner Satisfaction
            if (_metrics!.partnerSatisfaction.isNotEmpty) ...[
              _buildPartnerSatisfaction(),
              const SizedBox(height: 24),
            ],

            // Recommendations
            _buildRecommendations(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessLevelBadge() {
    final level = _metrics!.successLevel;
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (level) {
      case EventSuccessLevel.exceptional:
        badgeColor = AppColors.electricGreen;
        badgeText = 'Exceptional Success';
        badgeIcon = Icons.emoji_events;
        break;
      case EventSuccessLevel.high:
        badgeColor = AppColors.electricGreen;
        badgeText = 'High Success';
        badgeIcon = Icons.check_circle;
        break;
      case EventSuccessLevel.medium:
        badgeColor = AppTheme.warningColor;
        badgeText = 'Moderate Success';
        badgeIcon = Icons.info;
        break;
      case EventSuccessLevel.low:
        badgeColor = AppColors.error;
        badgeText = 'Needs Improvement';
        badgeIcon = Icons.trending_down;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(badgeIcon, size: 48, color: badgeColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.event.title,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Attendance',
                '${_metrics!.actualAttendance}/${_metrics!.ticketsSold}',
                '${(_metrics!.attendanceRate * 100).toStringAsFixed(0)}%',
                Icons.people,
                AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Revenue',
                '\$${_metrics!.netRevenue.toStringAsFixed(0)}',
                'Net',
                Icons.attach_money,
                AppColors.electricGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                'Rating',
                _metrics!.averageRating.toStringAsFixed(1),
                'out of 5.0',
                Icons.star,
                AppTheme.warningColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                'Feedback',
                '${(_metrics!.feedbackResponseRate * 100).toStringAsFixed(0)}%',
                'Response Rate',
                Icons.feedback,
                AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNPSScore() {
    final nps = _metrics!.nps;
    Color npsColor;
    String npsLabel;

    if (nps >= 50) {
      npsColor = AppColors.electricGreen;
      npsLabel = 'Excellent';
    } else if (nps >= 0) {
      npsColor = AppTheme.primaryColor;
      npsLabel = 'Good';
    } else if (nps >= -50) {
      npsColor = AppTheme.warningColor;
      npsLabel = 'Needs Improvement';
    } else {
      npsColor = AppColors.error;
      npsLabel = 'Poor';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: npsColor),
              const SizedBox(width: 8),
              Text(
                'Net Promoter Score (NPS)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                nps.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: npsColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      npsLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: npsColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_metrics!.attendeesWhoWouldRecommend} would recommend',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // NPS Scale
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.electricGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('-100', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('0', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('50', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              Text('100', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessFactors() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.electricGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.electricGreen),
              const SizedBox(width: 8),
              Text(
                'Success Factors',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._metrics!.successFactors.map((factor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.check, size: 16, color: AppColors.electricGreen),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      factor,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
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

  Widget _buildImprovementAreas() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: AppTheme.warningColor),
              const SizedBox(width: 8),
              Text(
                'Improvement Areas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._metrics!.improvementAreas.map((area) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: AppTheme.warningColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      area,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
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

  Widget _buildPartnerSatisfaction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.handshake, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Partner Satisfaction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._metrics!.partnerSatisfaction.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Partner ${entry.key.substring(0, 8)}...',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          entry.value >= (index + 1)
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: entry.value >= (index + 1)
                              ? AppTheme.warningColor
                              : AppColors.grey400,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        entry.value.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          if (_metrics!.partnersWouldCollaborateAgain) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.electricGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.electricGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Partners would collaborate again',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.electricGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final recommendations = _generateRecommendations();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                'Actionable Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...recommendations.map((recommendation) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
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

  List<String> _generateRecommendations() {
    final recommendations = <String>[];

    // Attendance recommendations
    if (_metrics!.attendanceRate < 0.8) {
      recommendations.add('Consider sending reminder notifications to increase attendance');
    }

    // Rating recommendations
    if (_metrics!.averageRating < 4.0) {
      recommendations.add('Focus on improving event quality based on feedback');
    }

    // NPS recommendations
    if (_metrics!.nps < 0) {
      recommendations.add('Work on improving attendee satisfaction to increase recommendations');
    }

    // Revenue recommendations
    if (_metrics!.revenueVsProjected < 0) {
      recommendations.add('Review pricing strategy to meet revenue goals');
    }

    // Feedback recommendations
    if (_metrics!.feedbackResponseRate < 0.5) {
      recommendations.add('Encourage more attendees to provide feedback');
    }

    // Improvement area recommendations
    if (_metrics!.improvementAreas.isNotEmpty) {
      recommendations.add('Address improvement areas: ${_metrics!.improvementAreas.join(", ")}');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Keep up the great work! Continue focusing on what made this event successful.');
    }

    return recommendations;
  }
}

