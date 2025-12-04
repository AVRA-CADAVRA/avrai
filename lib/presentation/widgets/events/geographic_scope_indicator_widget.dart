import 'package:flutter/material.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Geographic Scope Indicator Widget
/// Agent 2: Phase 6, Week 24 - Geographic Scope UI
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Show what areas user can host events in
/// - Display scope based on expertise level (Local, City, State, National, etc.)
/// - Visual indicator of hosting scope
/// - Helpful messaging about scope limitations
class GeographicScopeIndicatorWidget extends StatelessWidget {
  final UnifiedUser user;
  final String category;

  const GeographicScopeIndicatorWidget({
    super.key,
    required this.user,
    required this.category,
  });

  /// Get user's expertise level for the category
  ExpertiseLevel? _getUserExpertiseLevel() {
    return user.getExpertiseLevel(category);
  }

  /// Get scope description based on expertise level
  String _getScopeDescription() {
    final level = _getUserExpertiseLevel();
    if (level == null) return 'No expertise in this category';

    switch (level) {
      case ExpertiseLevel.local:
        return 'Your Locality Only';
      case ExpertiseLevel.city:
        return 'All Localities in Your City';
      case ExpertiseLevel.state:
        return 'All Cities in Your State';
      case ExpertiseLevel.national:
        return 'All States in Your Nation';
      case ExpertiseLevel.global:
        return 'All Nations';
      case ExpertiseLevel.universal:
        return 'Everywhere';
      default:
        return 'Limited Scope';
    }
  }

  /// Get scope icon based on expertise level
  IconData _getScopeIcon() {
    final level = _getUserExpertiseLevel();
    if (level == null) return Icons.location_off;

    switch (level) {
      case ExpertiseLevel.local:
        return Icons.location_on;
      case ExpertiseLevel.city:
        return Icons.location_city;
      case ExpertiseLevel.state:
        return Icons.map;
      case ExpertiseLevel.national:
        return Icons.public;
      case ExpertiseLevel.global:
        return Icons.language;
      case ExpertiseLevel.universal:
        return Icons.explore;
      default:
        return Icons.location_on;
    }
  }

  /// Get scope color based on expertise level
  Color _getScopeColor() {
    final level = _getUserExpertiseLevel();
    if (level == null) return AppColors.textSecondary;

    switch (level) {
      case ExpertiseLevel.local:
        return AppColors.electricGreen;
      case ExpertiseLevel.city:
        return AppTheme.primaryColor;
      case ExpertiseLevel.state:
        return AppTheme.accentColor;
      case ExpertiseLevel.national:
        return AppColors.electricGreen;
      case ExpertiseLevel.global:
        return AppColors.grey600;
      case ExpertiseLevel.universal:
        return AppColors.gold;
      default:
        return AppColors.textSecondary;
    }
  }

  /// Get detailed scope message
  String _getDetailedMessage() {
    final level = _getUserExpertiseLevel();
    if (level == null) {
      return 'Build expertise in this category to host events.';
    }

    switch (level) {
      case ExpertiseLevel.local:
        return 'You can host events in your locality only. '
            'This ensures local experts focus on their community.';
      case ExpertiseLevel.city:
        return 'You can host events in all localities within your city. '
            'Choose the locality that best fits your event.';
      case ExpertiseLevel.state:
        return 'You can host events anywhere in your state. '
            'Select any city or locality within your state.';
      case ExpertiseLevel.national:
        return 'You can host events anywhere in your nation. '
            'Select any state, city, or locality.';
      case ExpertiseLevel.global:
        return 'You can host events anywhere in the world. '
            'Your expertise is recognized globally.';
      case ExpertiseLevel.universal:
        return 'You can host events anywhere. '
            'Your expertise is universally recognized.';
      default:
        return 'Your hosting scope is limited by your expertise level.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = _getUserExpertiseLevel();
    if (level == null) {
      return const SizedBox.shrink();
    }

    final scopeColor = _getScopeColor();
    final scopeIcon = _getScopeIcon();
    final scopeDescription = _getScopeDescription();
    final detailedMessage = _getDetailedMessage();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scopeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scopeColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and scope description
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scopeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  scopeIcon,
                  color: scopeColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hosting Scope',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scopeDescription,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: scopeColor,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: detailedMessage,
                child: Icon(
                  Icons.help_outline,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Detailed message
          Text(
            detailedMessage,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

