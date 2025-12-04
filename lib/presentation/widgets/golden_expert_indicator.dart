import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Golden Expert Indicator Widget
/// Agent 2: Frontend & UX Specialist (Phase 6, Week 31)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required - NO direct Colors.* usage)
/// 
/// Features:
/// - Display golden expert status badge/indicator
/// - Show residency length
/// - Show influence weight (if available)
/// - Philosophy: Show doors (golden expert recognition) that users can open
class GoldenExpertIndicator extends StatelessWidget {
  /// User ID (to check golden expert status)
  final String userId;
  
  /// Locality where user is a golden expert
  final String? locality;
  
  /// Residency length in years (if available)
  final int? residencyYears;
  
  /// Influence weight (if available, e.g., 1.3x for 30 years)
  final double? influenceWeight;
  
  /// Display style
  final GoldenExpertDisplayStyle displayStyle;
  
  /// Show detailed information (residency, weight)
  final bool showDetails;
  
  /// Size of the indicator
  final double? size;

  const GoldenExpertIndicator({
    super.key,
    required this.userId,
    this.locality,
    this.residencyYears,
    this.influenceWeight,
    this.displayStyle = GoldenExpertDisplayStyle.badge,
    this.showDetails = false,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    switch (displayStyle) {
      case GoldenExpertDisplayStyle.badge:
        return _buildBadge();
      case GoldenExpertDisplayStyle.indicator:
        return _buildIndicator();
      case GoldenExpertDisplayStyle.card:
        return _buildCard();
    }
  }

  /// Build badge style (small icon with tooltip)
  Widget _buildBadge() {
    return Semantics(
      label: 'Golden Expert${locality != null ? ' in $locality' : ''}',
      child: Tooltip(
        message: _getTooltipMessage(),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryColor,
              width: 2,
            ),
          ),
          child: Icon(
            Icons.star,
            color: AppTheme.primaryColor,
            size: size ?? 20,
          ),
        ),
      ),
    );
  }

  /// Build indicator style (icon with text)
  Widget _buildIndicator() {
    return Semantics(
      label: 'Golden Expert${locality != null ? ' in $locality' : ''}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            color: AppTheme.primaryColor,
            size: size ?? 18,
          ),
          const SizedBox(width: 4),
          Text(
            'Golden Expert',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          if (showDetails && residencyYears != null) ...[
            const SizedBox(width: 4),
            Text(
              '($residencyYears years)',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build card style (detailed information)
  Widget _buildCard() {
    return Semantics(
      label: 'Golden Expert information',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.primaryColor,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: AppTheme.primaryColor,
                  size: size ?? 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Golden Expert',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            if (locality != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locality!,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
            if (showDetails && residencyYears != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$residencyYears years of residency',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (showDetails && influenceWeight != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(influenceWeight! * 100).toStringAsFixed(0)}% influence weight',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTooltipMessage() {
    final parts = <String>['Golden Expert'];
    if (locality != null) {
      parts.add('in $locality');
    }
    if (residencyYears != null) {
      parts.add('($residencyYears years)');
    }
    return parts.join(' ');
  }
}

/// Display style for golden expert indicator
enum GoldenExpertDisplayStyle {
  /// Small badge (icon only)
  badge,
  
  /// Indicator (icon + text)
  indicator,
  
  /// Card (detailed information)
  card,
}

