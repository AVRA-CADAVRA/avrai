import 'package:flutter/material.dart';
import 'package:spots/core/models/user_partnership.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Partnership Visibility Toggle Widget
/// 
/// Provides privacy controls for partnership visibility on profiles.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class PartnershipVisibilityToggle extends StatelessWidget {
  final UserPartnership partnership;
  final ValueChanged<bool> onVisibilityChanged;
  final bool showBulkControls;

  const PartnershipVisibilityToggle({
    super.key,
    required this.partnership,
    required this.onVisibilityChanged,
    this.showBulkControls = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  partnership.isPublic
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: partnership.isPublic
                      ? AppTheme.primaryColor
                      : AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partnership.partnerName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        partnership.isPublic
                            ? 'Visible on your profile'
                            : 'Hidden from your profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: partnership.isPublic,
                  onChanged: onVisibilityChanged,
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bulk Partnership Visibility Controls
/// 
/// Allows users to control visibility for multiple partnerships at once.
class BulkPartnershipVisibilityControls extends StatelessWidget {
  final List<UserPartnership> partnerships;
  final ValueChanged<Map<String, bool>> onBulkVisibilityChanged;

  const BulkPartnershipVisibilityControls({
    super.key,
    required this.partnerships,
    required this.onBulkVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bulk Visibility Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final visibilityMap = <String, bool>{};
                      for (final partnership in partnerships) {
                        visibilityMap[partnership.id] = true;
                      }
                      onBulkVisibilityChanged(visibilityMap);
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('Show All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.grey300),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final visibilityMap = <String, bool>{};
                      for (final partnership in partnerships) {
                        visibilityMap[partnership.id] = false;
                      }
                      onBulkVisibilityChanged(visibilityMap);
                    },
                    icon: const Icon(Icons.visibility_off),
                    label: const Text('Hide All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.grey300),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

