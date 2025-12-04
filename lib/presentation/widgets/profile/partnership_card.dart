import 'package:flutter/material.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Partnership Card Widget for Profile Display
/// 
/// Displays a single partnership card on user profiles.
/// Different from the existing PartnershipCard in partnerships/ folder.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class ProfilePartnershipCard extends StatelessWidget {
  final UserPartnership partnership;
  final VoidCallback? onTap;
  final bool showVisibilityToggle;
  final ValueChanged<bool>? onVisibilityChanged;

  const ProfilePartnershipCard({
    super.key,
    required this.partnership,
    this.onTap,
    this.showVisibilityToggle = false,
    this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Partner Info Row
              Row(
                children: [
                  // Partner Logo/Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: partnership.partnerLogoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              partnership.partnerLogoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  _getTypeIcon(partnership.type),
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                );
                              },
                            ),
                          )
                        : Icon(
                            _getTypeIcon(partnership.type),
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partnership.partnerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildTypeBadge(),
                            const SizedBox(width: 8),
                            _buildStatusBadge(),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (showVisibilityToggle && onVisibilityChanged != null)
                    IconButton(
                      icon: Icon(
                        partnership.isPublic
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: partnership.isPublic
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        onVisibilityChanged!(!partnership.isPublic);
                      },
                      tooltip: partnership.isPublic
                          ? 'Hide from profile'
                          : 'Show on profile',
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Partnership Details
              if (partnership.eventCount > 0) ...[
                Row(
                  children: [
                    Icon(
                      Icons.event,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${partnership.eventCount} ${partnership.eventCount == 1 ? 'event' : 'events'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Date Range (if available)
              if (partnership.startDate != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDateRange(),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],

              // Vibe Compatibility (if available)
              if (partnership.vibeCompatibility != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(partnership.vibeCompatibility! * 100).toStringAsFixed(0)}% match',
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
      ),
    );
  }

  Widget _buildTypeBadge() {
    Color badgeColor;
    switch (partnership.type) {
      case ProfilePartnershipType.business:
        badgeColor = AppTheme.primaryColor;
        break;
      case ProfilePartnershipType.brand:
        badgeColor = AppColors.warning;
        break;
      case ProfilePartnershipType.company:
        badgeColor = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        partnership.type.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String statusText;

    switch (partnership.status) {
      case PartnershipStatus.active:
        badgeColor = AppColors.electricGreen;
        statusText = 'Active';
        break;
      case PartnershipStatus.completed:
        badgeColor = AppColors.textSecondary;
        statusText = 'Completed';
        break;
      case PartnershipStatus.approved:
      case PartnershipStatus.locked:
        badgeColor = AppColors.electricGreen;
        statusText = 'Approved';
        break;
      case PartnershipStatus.pending:
      case PartnershipStatus.proposed:
      case PartnershipStatus.negotiating:
        badgeColor = AppColors.warning;
        statusText = 'Pending';
        break;
      case PartnershipStatus.cancelled:
        badgeColor = AppColors.error;
        statusText = 'Cancelled';
        break;
      case PartnershipStatus.disputed:
        badgeColor = AppColors.error;
        statusText = 'Disputed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: badgeColor,
        ),
      ),
    );
  }

  IconData _getTypeIcon(ProfilePartnershipType type) {
    switch (type) {
      case ProfilePartnershipType.business:
        return Icons.business;
      case ProfilePartnershipType.brand:
        return Icons.local_offer;
      case ProfilePartnershipType.company:
        return Icons.corporate_fare;
    }
  }

  String _formatDateRange() {
    if (partnership.startDate == null) return '';
    
    final start = partnership.startDate!;
    final end = partnership.endDate;
    
    final startStr = '${_getMonthName(start.month)} ${start.day}, ${start.year}';
    
    if (end == null) {
      return 'Since $startStr';
    }
    
    final endStr = '${_getMonthName(end.month)} ${end.day}, ${end.year}';
    return '$startStr - $endStr';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}

