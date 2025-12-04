import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/models/usage_pattern.dart';

/// OUR_GUTS.md: "See your door journey"
/// Shows which doors user has opened (spots → communities → events)
class DoorJourneyWidget extends StatelessWidget {
  final UsagePattern usagePattern;
  
  const DoorJourneyWidget({
    Key? key,
    required this.usagePattern,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Your Door Journey',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Doors you\'ve opened with your key:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildDoorStats(),
          const SizedBox(height: 20),
          _buildUsageMode(),
        ],
      ),
    );
  }
  
  Widget _buildDoorStats() {
    return Column(
      children: [
        if (usagePattern.totalSpotVisits > 0)
          _buildDoorStat(
            icon: Icons.place,
            label: 'Spots',
            count: usagePattern.totalSpotVisits,
            color: AppColors.primary,
          ),
        if (usagePattern.totalEventsAttended > 0)
          _buildDoorStat(
            icon: Icons.event,
            label: 'Events',
            count: usagePattern.totalEventsAttended,
            color: AppColors.success,
          ),
        if (usagePattern.totalCommunitiesJoined > 0)
          _buildDoorStat(
            icon: Icons.group,
            label: 'Communities',
            count: usagePattern.totalCommunitiesJoined,
            color: AppColors.warning,
          ),
      ],
    );
  }
  
  Widget _buildDoorStat({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '$count opened',
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
  
  Widget _buildUsageMode() {
    final mode = usagePattern.primaryMode;
    final modeInfo = _getModeInfo(mode);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modeInfo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: modeInfo.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(modeInfo.icon, color: modeInfo.color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your key adapts to you',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  modeInfo.description,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  _ModeInfo _getModeInfo(UsageMode mode) {
    switch (mode) {
      case UsageMode.recommendations:
        return _ModeInfo(
          icon: Icons.explore,
          color: AppColors.primary,
          description: 'Quick spot suggestions',
        );
      case UsageMode.community:
        return _ModeInfo(
          icon: Icons.group,
          color: AppColors.success,
          description: 'Community discovery',
        );
      case UsageMode.events:
        return _ModeInfo(
          icon: Icons.event,
          color: AppColors.warning,
          description: 'Event-focused',
        );
      case UsageMode.balanced:
        return _ModeInfo(
          icon: Icons.dashboard,
          color: AppColors.textSecondary,
          description: 'Balanced usage',
        );
    }
  }
}

class _ModeInfo {
  final IconData icon;
  final Color color;
  final String description;
  
  _ModeInfo({
    required this.icon,
    required this.color,
    required this.description,
  });
}

/// Compact version for dashboard
class DoorJourneyCompact extends StatelessWidget {
  final UsagePattern usagePattern;
  final VoidCallback? onTap;
  
  const DoorJourneyCompact({
    Key? key,
    required this.usagePattern,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.vpn_key, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Key Journey',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${usagePattern.openedDoorTypes.length} door types opened',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

