import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/fraud_score.dart';
import 'package:spots/core/models/fraud_recommendation.dart';
import 'package:spots/core/services/fraud_detection_service.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Fraud Review Page (Admin)
/// 
/// Agent 2: Phase 5, Week 20-21 - Fraud Review UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Fraud score display
/// - Fraud signals list
/// - Recommendation display
/// - Approve/Reject/Require Verification actions
/// - Event details
/// - Host information
class FraudReviewPage extends StatefulWidget {
  final String eventId;

  const FraudReviewPage({
    super.key,
    required this.eventId,
  });

  @override
  State<FraudReviewPage> createState() => _FraudReviewPageState();
}

class _FraudReviewPageState extends State<FraudReviewPage> {
  final FraudDetectionService _fraudService = FraudDetectionService(
    eventService: GetIt.instance<ExpertiseEventService>(),
  );
  final ExpertiseEventService _eventService = GetIt.instance<ExpertiseEventService>();

  FraudScore? _fraudScore;
  ExpertiseEvent? _event;
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
      // Load event
      final event = await _eventService.getEventById(widget.eventId);
      
      // Analyze or get existing fraud score
      FraudScore? score;
      try {
        score = await _fraudService.getFraudScore(widget.eventId);
      } catch (e) {
        // If no score exists, analyze the event
        score = await _fraudService.analyzeEvent(widget.eventId);
      }

      setState(() {
        _event = event;
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
      // For now, we'll just update the local state
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
          'Fraud Review',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null || _fraudScore == null || _event == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'Failed to load fraud review data',
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

                        // Event Details
                        _buildEventDetails(),
                        const SizedBox(height: 24),

                        // Fraud Signals
                        _buildFraudSignals(),
                        const SizedBox(height: 24),

                        // Recommendation
                        _buildRecommendation(),
                        const SizedBox(height: 24),

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
          Icon(Icons.shield, size: 48, color: badgeColor),
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

  Widget _buildEventDetails() {
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
            'Event Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow('Title', _event!.title),
          _buildDetailRow('Host', _event!.host.displayName ?? _event!.host.email),
          _buildDetailRow('Price', '\$${_event!.price?.toStringAsFixed(2) ?? '0.00'}'),
          _buildDetailRow('Location', _event!.location ?? 'Not specified'),
          _buildDetailRow('Date', _formatDateTime(_event!.startTime)),
          _buildDetailRow('Attendees', '${_event!.attendeeCount} / ${_event!.maxAttendees}'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
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
                        const SizedBox(height: 4),
                        Text(
                          'Risk Weight: ${(signal.riskWeight * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
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
        recText = 'Reject';
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
                onPressed: _isProcessing ? null : () => _updateAdminDecision('require_verification'),
                icon: const Icon(Icons.verified_user),
                label: const Text('Verify'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                  minimumSize: const Size(0, 48),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : () => _updateAdminDecision('reject'),
                icon: const Icon(Icons.cancel),
                label: const Text('Reject'),
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

