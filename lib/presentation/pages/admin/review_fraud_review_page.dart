import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/event_feedback.dart';
import 'package:spots/core/models/review_fraud_score.dart';
import 'package:spots/core/models/fraud_recommendation.dart';
import 'package:spots/core/services/review_fraud_detection_service.dart';
import 'package:spots/core/services/post_event_feedback_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Review Fraud Review Page (Admin)
/// 
/// Agent 2: Phase 5, Week 20-21 - Fraud Review UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Review fraud score
/// - Fraud signals
/// - Review details
/// - User information
/// - Actions (approve/remove)
class ReviewFraudReviewPage extends StatefulWidget {
  final String eventId;

  const ReviewFraudReviewPage({
    super.key,
    required this.eventId,
  });

  @override
  State<ReviewFraudReviewPage> createState() => _ReviewFraudReviewPageState();
}

class _ReviewFraudReviewPageState extends State<ReviewFraudReviewPage> {
  final ReviewFraudDetectionService _reviewFraudService = ReviewFraudDetectionService(
    feedbackService: PostEventFeedbackService(
      eventService: GetIt.instance<ExpertiseEventService>(),
    ),
  );
  final PostEventFeedbackService _feedbackService = PostEventFeedbackService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );

  ReviewFraudScore? _fraudScore;
  List<EventFeedback> _feedbacks = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load feedbacks for event
      final feedbacks = await _feedbackService.getFeedbackForEvent(widget.eventId);
      
      // Analyze or get existing fraud score
      ReviewFraudScore? score;
      try {
        score = await _reviewFraudService.getFraudScore(widget.eventId);
      } catch (e) {
        // If no score exists, analyze the reviews
        score = await _reviewFraudService.analyzeReviews(widget.eventId);
      }

      setState(() {
        _feedbacks = feedbacks;
        _fraudScore = score;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateAdminDecision(String decision) async {
    if (_fraudScore == null) return;

    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      // In production, this would call an admin service to update the decision
      setState(() {
        _fraudScore = _fraudScore!.copyWith(
          reviewedByAdmin: true,
          adminDecision: decision,
          reviewedAt: DateTime.now(),
        );
        _isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Decision saved: ${decision.toUpperCase()}'),
            backgroundColor: AppColors.electricGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Review Fraud Review',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _fraudScore == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'Failed to load review fraud data',
                        style: TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Risk Score Badge
                        _buildRiskScoreBadge(),
                        const SizedBox(height: 24),

                        // Review Summary
                        _buildReviewSummary(),
                        const SizedBox(height: 24),

                        // Fraud Signals
                        _buildFraudSignals(),
                        const SizedBox(height: 24),

                        // Recommendation
                        _buildRecommendation(),
                        const SizedBox(height: 24),

                        // Reviews List
                        if (_feedbacks.isNotEmpty) ...[
                          _buildReviewsList(),
                          const SizedBox(height: 24),
                        ],

                        // Admin Actions
                        if (!_fraudScore!.reviewedByAdmin) _buildAdminActions(),
                        if (_fraudScore!.reviewedByAdmin) _buildReviewStatus(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildRiskScoreBadge() {
    final score = _fraudScore!.riskScore;
    Color badgeColor;
    String riskLevel;

    if (score >= 0.7) {
      badgeColor = AppColors.error;
      riskLevel = 'High Risk';
    } else if (score >= 0.4) {
      badgeColor = AppTheme.warningColor;
      riskLevel = 'Medium Risk';
    } else {
      badgeColor = AppColors.electricGreen;
      riskLevel = 'Low Risk';
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
          Icon(Icons.reviews, size: 48, color: badgeColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  riskLevel,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
                Text(
                  'Risk Score: ${(score * 100).toStringAsFixed(0)}%',
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

  Widget _buildReviewSummary() {
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
          Text(
            'Review Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Total Reviews', '${_feedbacks.length}'),
          if (_feedbacks.isNotEmpty) ...[
            _buildDetailRow(
              'Average Rating',
              '${(_feedbacks.map((f) => f.overallRating).reduce((a, b) => a + b) / _feedbacks.length).toStringAsFixed(1)} / 5.0',
            ),
            _buildDetailRow(
              '5-Star Reviews',
              '${_feedbacks.where((f) => f.overallRating >= 4.5).length}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFraudSignals() {
    if (_fraudScore!.signals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.electricGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.electricGreen.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.electricGreen),
            const SizedBox(width: 12),
            Text(
              'No fraud signals detected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.electricGreen,
              ),
            ),
          ],
        ),
      );
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
          Text(
            'Fraud Signals (${_fraudScore!.signals.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._fraudScore!.signals.map((signal) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signal.displayName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          signal.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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

  Widget _buildRecommendation() {
    final recommendation = _fraudScore!.recommendation;
    Color recColor;
    IconData recIcon;
    String recText;

    switch (recommendation) {
      case FraudRecommendation.approve:
        recColor = AppColors.electricGreen;
        recIcon = Icons.check_circle;
        recText = 'Approve';
        break;
      case FraudRecommendation.review:
        recColor = AppTheme.warningColor;
        recIcon = Icons.review;
        recText = 'Review';
        break;
      case FraudRecommendation.requireVerification:
        recColor = AppTheme.primaryColor;
        recIcon = Icons.verified_user;
        recText = 'Require Verification';
        break;
      case FraudRecommendation.reject:
        recColor = AppColors.error;
        recIcon = Icons.cancel;
        recText = 'Remove';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: recColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: recColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(recIcon, size: 32, color: recColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recommendation',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  recText,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: recColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsList() {
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
          Text(
            'Reviews (${_feedbacks.length})',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._feedbacks.take(5).map((feedback) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      ...List.generate(5, (index) {
                        return Icon(
                          feedback.overallRating >= (index + 1)
                              ? Icons.star
                              : Icons.star_border,
                          size: 16,
                          color: feedback.overallRating >= (index + 1)
                              ? AppTheme.warningColor
                              : AppColors.grey400,
                        );
                      }),
                      const SizedBox(width: 8),
                      Text(
                        feedback.overallRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(feedback.submittedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (feedback.comments != null && feedback.comments!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      feedback.comments!,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            );
          }),
          if (_feedbacks.length > 5)
            Text(
              '... and ${_feedbacks.length - 5} more reviews',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdminActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Admin Decision',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _updateAdminDecision('approve'),
                icon: const Icon(Icons.check),
                label: const Text('Approve'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.electricGreen,
                  side: BorderSide(color: AppColors.electricGreen),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _updateAdminDecision('remove'),
                icon: const Icon(Icons.delete),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: BorderSide(color: AppColors.error),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.electricGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.electricGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reviewed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                  ),
                ),
                Text(
                  'Decision: ${_fraudScore!.adminDecision?.toUpperCase() ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (_fraudScore!.reviewedAt != null)
                  Text(
                    'Reviewed on ${_formatDate(_fraudScore!.reviewedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

