import 'package:flutter/material.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_requirements.dart';
import 'package:spots/core/services/dynamic_threshold_service.dart';
import 'package:spots/core/services/locality_value_analysis_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Locality Threshold Widget
/// Agent 2: Phase 6, Week 25 - Qualification UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Show current threshold for user's locality
/// - Show how locality values different activities
/// - Show progress to local expert qualification
/// - Display locality-specific adjustments
class LocalityThresholdWidget extends StatefulWidget {
  final UnifiedUser user;
  final String category;
  final String? locality;
  final ThresholdValues? baseThresholds;

  const LocalityThresholdWidget({
    super.key,
    required this.user,
    required this.category,
    this.locality,
    this.baseThresholds,
  });

  @override
  State<LocalityThresholdWidget> createState() => _LocalityThresholdWidgetState();
}

class _LocalityThresholdWidgetState extends State<LocalityThresholdWidget> {
  final DynamicThresholdService _thresholdService = DynamicThresholdService();
  final LocalityValueAnalysisService _valueService = LocalityValueAnalysisService();
  
  ThresholdValues? _localityThresholds;
  Map<String, double>? _activityWeights;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocalityThresholds();
  }

  Future<void> _loadLocalityThresholds() async {
    if (widget.locality == null || widget.baseThresholds == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Get locality-specific thresholds
      final thresholds = await _thresholdService.calculateLocalThreshold(
        locality: widget.locality!,
        category: widget.category,
        baseThresholds: widget.baseThresholds!,
      );

      // Get activity weights to show what locality values
      final weights = await _valueService.getActivityWeights(widget.locality!);

      setState(() {
        _localityThresholds = thresholds;
        _activityWeights = weights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Get activity display name
  String _getActivityDisplayName(String activity) {
    switch (activity) {
      case 'events_hosted':
        return 'Events Hosted';
      case 'lists_created':
        return 'Lists Created';
      case 'reviews_written':
        return 'Reviews Written';
      case 'event_attendance':
        return 'Event Attendance';
      case 'professional_background':
        return 'Professional Background';
      case 'positive_trends':
        return 'Positive Trends';
      default:
        return activity;
    }
  }

  /// Get activity icon
  IconData _getActivityIcon(String activity) {
    switch (activity) {
      case 'events_hosted':
        return Icons.event;
      case 'lists_created':
        return Icons.list;
      case 'reviews_written':
        return Icons.rate_review;
      case 'event_attendance':
        return Icons.people;
      case 'professional_background':
        return Icons.work;
      case 'positive_trends':
        return Icons.trending_up;
      default:
        return Icons.info;
    }
  }

  /// Get weight color based on value
  Color _getWeightColor(double weight) {
    if (weight >= 0.25) {
      return AppColors.electricGreen; // High value
    } else if (weight >= 0.15) {
      return AppTheme.primaryColor; // Medium value
    } else {
      return AppColors.textSecondary; // Low value
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.locality == null) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Loading locality-specific thresholds...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              size: 16,
              color: AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Error loading thresholds: $_error',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.electricGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: AppColors.electricGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Locality-Specific Thresholds',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      widget.locality!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Thresholds adapt to what your locality values most. '
                    'Activities valued by your locality have lower thresholds.',
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Threshold Summary
          if (_localityThresholds != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qualification Requirements',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildThresholdRow('Visits', _localityThresholds!.minVisits),
                  if (_localityThresholds!.minRatings > 0)
                    _buildThresholdRow('Ratings', _localityThresholds!.minRatings),
                  if (_localityThresholds!.minEventHosting != null)
                    _buildThresholdRow('Events Hosted', _localityThresholds!.minEventHosting!),
                  if (_localityThresholds!.minListCuration != null)
                    _buildThresholdRow('Lists Created', _localityThresholds!.minListCuration!),
                  if (_localityThresholds!.minCommunityEngagement != null)
                    _buildThresholdRow('Community Engagement', _localityThresholds!.minCommunityEngagement!),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Activity Values
          if (_activityWeights != null && _activityWeights!.isNotEmpty) ...[
            Text(
              'What Your Locality Values',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            ..._activityWeights!.entries.map((entry) {
              final activity = entry.key;
              final weight = entry.value;
              return _buildActivityValueRow(activity, weight);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildThresholdRow(String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityValueRow(String activity, double weight) {
    final displayName = _getActivityDisplayName(activity);
    final icon = _getActivityIcon(activity);
    final color = _getWeightColor(weight);
    final percentage = (weight * 100).toStringAsFixed(0);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$percentage%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

