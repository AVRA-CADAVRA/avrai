/// Action History Item Widget
/// 
/// Part of Feature Matrix Phase 7, Week 33: Action Execution UI & Integration
/// 
/// Displays a single action history entry with:
/// - Action type and description
/// - Timestamp
/// - Success/error status indicator
/// - Undo button (if undoable)
/// 
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'package:spots/core/ai/action_history_entry.dart';
import 'package:spots/core/ai/action_models.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget that displays a single action history entry
class ActionHistoryItemWidget extends StatelessWidget {
  /// The action history entry to display
  final ActionHistoryEntry entry;
  
  /// Callback when undo is requested
  final VoidCallback? onUndo;
  
  /// Whether to show detailed information
  final bool showDetails;

  const ActionHistoryItemWidget({
    super.key,
    required this.entry,
    this.onUndo,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForIntent(entry.intent.type);
    final title = _getTitleForIntent(entry.intent.type);
    final subtitle = _getSubtitleForEntry(entry);
    final timeAgo = _formatTimeAgo(entry.timestamp);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: entry.isUndone
              ? AppColors.grey300
              : entry.result.success
                  ? AppColors.electricGreen.withValues(alpha: 0.3)
                  : AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: entry.isUndone
                        ? AppColors.grey200
                        : entry.result.success
                            ? AppColors.electricGreen.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: entry.isUndone
                        ? AppColors.grey600
                        : entry.result.success
                            ? AppColors.electricGreen
                            : AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title with undone indicator
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: entry.isUndone
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                                decoration: entry.isUndone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          if (entry.isUndone)
                            Text(
                              '(Undone)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      
                      // Subtitle
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Result message
                      if (entry.result.successMessage != null || entry.result.errorMessage != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: entry.result.success
                                ? AppColors.electricGreen.withValues(alpha: 0.1)
                                : AppColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                entry.result.success
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                size: 14,
                                color: entry.result.success
                                    ? AppColors.electricGreen
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  entry.result.successMessage ??
                                      entry.result.errorMessage ??
                                      '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: entry.result.success
                                        ? AppColors.electricGreen
                                        : AppColors.error,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      
                      // Timestamp
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                      
                      // Detailed information (if showDetails is true)
                      if (showDetails) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        _buildDetailsSection(),
                      ],
                    ],
                  ),
                ),
                
                // Undo button
                if (entry.canUndo && !entry.isUndone && onUndo != null)
                  IconButton(
                    icon: const Icon(Icons.undo),
                    color: AppColors.electricGreen,
                    onPressed: onUndo,
                    tooltip: 'Undo',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Details',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Action ID: ${entry.id}',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          'Timestamp: ${entry.timestamp.toIso8601String()}',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          'User ID: ${entry.userId}',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textHint,
            fontFamily: 'monospace',
          ),
        ),
        if (entry.result.data.isNotEmpty)
          Text(
            'Data: ${entry.result.data.toString()}',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textHint,
              fontFamily: 'monospace',
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  IconData _getIconForIntent(String intentType) {
    switch (intentType) {
      case 'create_spot':
        return Icons.place;
      case 'create_list':
        return Icons.list;
      case 'add_spot_to_list':
        return Icons.add_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _getTitleForIntent(String intentType) {
    switch (intentType) {
      case 'create_spot':
        return 'Create Spot';
      case 'create_list':
        return 'Create List';
      case 'add_spot_to_list':
        return 'Add Spot to List';
      default:
        return 'Unknown Action';
    }
  }

  String _getSubtitleForEntry(ActionHistoryEntry entry) {
    final intent = entry.intent;
    
    if (intent.type == 'create_spot') {
      if (intent is CreateSpotIntent) {
        return intent.name;
      }
      return 'Create a new spot';
    } else if (intent.type == 'create_list') {
      if (intent is CreateListIntent) {
        return intent.title;
      }
      return 'Create a new list';
    } else if (intent.type == 'add_spot_to_list') {
      if (intent is AddSpotToListIntent) {
        final spotName = intent.metadata['spotName'] as String? ?? 'Spot';
        final listName = intent.metadata['listName'] as String? ?? 'List';
        return 'Added $spotName to $listName';
      }
      return 'Add spot to list';
    }
    
    return 'Action details';
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

