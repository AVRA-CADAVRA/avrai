import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Expansion Timeline Widget
/// Agent 2: Frontend & UX Specialist (Phase 6, Week 30)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required - NO direct Colors.* usage)
/// 
/// Features:
/// - Display expansion timeline showing how community/club expanded from original locality
/// - Timeline of expansion events (when, where, how)
/// - Visual representation of expansion path
/// - Show coverage milestones (75% thresholds reached)
/// - Philosophy: Show doors (geographic expansion) that clubs can open
class ExpansionTimelineWidget extends StatelessWidget {
  /// Original locality where club/community formed
  final String? originalLocality;
  
  /// Expansion history (list of expansion events)
  /// Format: List of maps with 'locality', 'timestamp', 'method' (event/commute), 'coverage'
  final List<Map<String, dynamic>> expansionHistory;
  
  /// Coverage milestones (75% thresholds reached)
  /// Format: List of maps with 'level' (city/state/national/global/universal), 'timestamp', 'coverage'
  final List<Map<String, dynamic>> coverageMilestones;
  
  /// Events hosted in each locality
  /// Format: Map of locality → list of event names/IDs
  final Map<String, List<String>> eventsByLocality;
  
  /// Commute patterns (people traveling to events)
  /// Format: Map of locality → list of source localities
  final Map<String, List<String>> commutePatterns;
  
  /// Coverage percentages over time
  /// Format: Map of timestamp → coverage percentage
  final Map<DateTime, double> coverageOverTime;

  const ExpansionTimelineWidget({
    super.key,
    this.originalLocality,
    this.expansionHistory = const [],
    this.coverageMilestones = const [],
    this.eventsByLocality = const {},
    this.commutePatterns = const {},
    this.coverageOverTime = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.timeline,
                color: AppTheme.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Expansion Timeline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Original Locality
          if (originalLocality != null)
            _buildTimelineItem(
              title: 'Original Locality',
              subtitle: originalLocality!,
              icon: Icons.location_on,
              isStart: true,
              isMilestone: true,
            ),
          
          // Expansion History
          if (expansionHistory.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Expansion Events',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...expansionHistory.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildExpansionEventItem(
                  event: event,
                  index: index,
                  isLast: index == expansionHistory.length - 1,
                ),
              );
            }),
          ],
          
          // Coverage Milestones
          if (coverageMilestones.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              'Coverage Milestones',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...coverageMilestones.map((milestone) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildMilestoneItem(milestone: milestone),
              );
            }),
          ],
          
          // Empty State
          if (expansionHistory.isEmpty && coverageMilestones.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No expansion history available yet',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isStart = false,
    bool isMilestone = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isMilestone
                    ? AppTheme.primaryColor
                    : AppColors.grey400,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white,
                  width: 2,
                ),
              ),
              child: Icon(
                icon,
                size: 14,
                color: AppColors.white,
              ),
            ),
            if (!isStart)
              Container(
                width: 2,
                height: 40,
                color: AppColors.grey300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isMilestone
                  ? AppTheme.primaryColor.withValues(alpha: 0.1)
                  : AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isMilestone
                    ? AppTheme.primaryColor
                    : AppColors.grey300,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpansionEventItem({
    required Map<String, dynamic> event,
    required int index,
    required bool isLast,
  }) {
    final locality = event['locality'] as String? ?? 'Unknown';
    final timestamp = event['timestamp'] as DateTime?;
    final method = event['method'] as String? ?? 'event';
    final coverage = event['coverage'] as double?;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.white,
                  width: 2,
                ),
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: AppColors.grey300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        // Content
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey100,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grey300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      method == 'commute' ? Icons.directions_transit : Icons.event,
                      size: 16,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locality,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (coverage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: coverage,
                          backgroundColor: AppColors.grey300,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(coverage * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
                // Show events or commute patterns if available
                if (eventsByLocality.containsKey(locality) && eventsByLocality[locality]!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${eventsByLocality[locality]!.length} event(s)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (commutePatterns.containsKey(locality) && commutePatterns[locality]!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Commute from ${commutePatterns[locality]!.length} locality(ies)',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneItem({
    required Map<String, dynamic> milestone,
  }) {
    final level = milestone['level'] as String? ?? 'unknown';
    final timestamp = milestone['timestamp'] as DateTime?;
    final coverage = milestone['coverage'] as double? ?? 0.0;
    
    final displayName = _getLevelDisplayName(level);
    final icon = _getLevelIcon(level);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: AppColors.white,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '75% ACHIEVED',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                if (timestamp != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (coverage > 0) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${(coverage * 100).toStringAsFixed(0)}% coverage',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else {
      return 'Just now';
    }
  }

  String _getLevelDisplayName(String level) {
    switch (level.toLowerCase()) {
      case 'city':
        return 'City Coverage Milestone';
      case 'state':
        return 'State Coverage Milestone';
      case 'national':
        return 'National Coverage Milestone';
      case 'global':
        return 'Global Coverage Milestone';
      case 'universal':
        return 'Universal Coverage Milestone';
      default:
        return 'Coverage Milestone';
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level.toLowerCase()) {
      case 'city':
        return Icons.location_city;
      case 'state':
        return Icons.map;
      case 'national':
        return Icons.public;
      case 'global':
        return Icons.language;
      case 'universal':
        return Icons.public;
      default:
        return Icons.star;
    }
  }
}

