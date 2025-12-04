/// Action Error Dialog Widget
/// 
/// Part of Feature Matrix Phase 1: Action Execution UI & Integration
/// 
/// Displays an error dialog when an AI action fails, showing:
/// - Error message (user-friendly)
/// - Optional retry mechanism
/// - Intent context (what failed)
/// - View Details button (shows technical details)
/// - Actionable guidance and alternatives
/// 
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'package:spots/core/ai/action_models.dart';
import 'package:spots/core/theme/colors.dart';

/// Dialog widget that shows action failure details
class ActionErrorDialog extends StatefulWidget {
  /// The error message to display
  final String error;
  
  /// The intent that failed (optional)
  final ActionIntent? intent;
  
  /// Callback when user dismisses the dialog
  final VoidCallback onDismiss;
  
  /// Callback when user wants to retry (optional)
  final VoidCallback? onRetry;
  
  /// Technical error details (optional, shown in View Details)
  final String? technicalDetails;

  const ActionErrorDialog({
    super.key,
    required this.error,
    this.intent,
    required this.onDismiss,
    this.onRetry,
    this.technicalDetails,
  });

  @override
  State<ActionErrorDialog> createState() => _ActionErrorDialogState();
}

class _ActionErrorDialogState extends State<ActionErrorDialog> {
  bool _showDetails = false;

  @override
  Widget build(BuildContext context) {
    final userFriendlyError = _translateError(widget.error);
    final suggestions = _getSuggestions(widget.error, widget.intent);

    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Action Failed',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.intent != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.grey300,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getIconForIntent(widget.intent!),
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getFailureContext(widget.intent!),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              userFriendlyError,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.electricGreen.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: AppColors.electricGreen,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Suggestions',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...suggestions.map((suggestion) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '• ',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              suggestion,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
            if (widget.technicalDetails != null || _showDetails) ...[
              const SizedBox(height: 16),
              if (_showDetails) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.grey300,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Technical Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.technicalDetails ?? widget.error,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        if (widget.technicalDetails != null || widget.error != userFriendlyError)
          TextButton(
            onPressed: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            child: Text(
              _showDetails ? 'Hide Details' : 'View Details',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        TextButton(
          onPressed: () {
            widget.onDismiss();
            Navigator.of(context).pop();
          },
          child: Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (widget.onRetry != null)
          ElevatedButton(
            onPressed: () {
              widget.onRetry!();
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.electricGreen,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  String _getFailureContext(ActionIntent intent) {
    if (intent is CreateSpotIntent) {
      return 'Failed to create spot: ${intent.name}';
    } else if (intent is CreateListIntent) {
      return 'Failed to create list: ${intent.title}';
    } else if (intent is AddSpotToListIntent) {
      return 'Failed to add spot to list';
    }
    return 'Failed to execute action';
  }

  IconData _getIconForIntent(ActionIntent intent) {
    if (intent is CreateSpotIntent) {
      return Icons.place;
    } else if (intent is CreateListIntent) {
      return Icons.list;
    } else if (intent is AddSpotToListIntent) {
      return Icons.add_circle_outline;
    }
    return Icons.help_outline;
  }

  /// Translate technical errors to user-friendly messages
  String _translateError(String error) {
    final lowerError = error.toLowerCase();
    
    // Network errors
    if (lowerError.contains('network') || lowerError.contains('connection') || lowerError.contains('timeout')) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }
    
    // Permission errors
    if (lowerError.contains('permission') || lowerError.contains('unauthorized') || lowerError.contains('forbidden')) {
      return 'You don\'t have permission to perform this action. Please check your account settings.';
    }
    
    // Validation errors
    if (lowerError.contains('invalid') || lowerError.contains('validation') || lowerError.contains('required')) {
      return 'The information provided is invalid. Please check your input and try again.';
    }
    
    // Not found errors
    if (lowerError.contains('not found') || lowerError.contains('does not exist')) {
      return 'The requested item could not be found. It may have been deleted or moved.';
    }
    
    // Duplicate errors
    if (lowerError.contains('duplicate') || lowerError.contains('already exists')) {
      return 'This item already exists. Please use a different name or check your existing items.';
    }
    
    // Storage errors
    if (lowerError.contains('storage') || lowerError.contains('save') || lowerError.contains('database')) {
      return 'Unable to save the data. Please try again or contact support if the problem persists.';
    }
    
    // Generic fallback
    return error;
  }

  /// Get actionable suggestions based on error and intent
  List<String> _getSuggestions(String error, ActionIntent? intent) {
    final suggestions = <String>[];
    final lowerError = error.toLowerCase();
    
    // Network-related suggestions
    if (lowerError.contains('network') || lowerError.contains('connection')) {
      suggestions.add('Check your internet connection');
      suggestions.add('Try again in a few moments');
      if (intent != null) {
        suggestions.add('You can try this action again later');
      }
    }
    
    // Validation-related suggestions
    if (lowerError.contains('invalid') || lowerError.contains('validation')) {
      if (intent is CreateSpotIntent) {
        suggestions.add('Make sure the spot name is not empty');
        suggestions.add('Check that the location is valid');
      } else if (intent is CreateListIntent) {
        suggestions.add('Make sure the list name is not empty');
        suggestions.add('Try using a different name');
      }
    }
    
    // Not found suggestions
    if (lowerError.contains('not found')) {
      if (intent is AddSpotToListIntent) {
        suggestions.add('The spot or list may have been deleted');
        suggestions.add('Try creating a new list or selecting a different spot');
      }
    }
    
    // Duplicate suggestions
    if (lowerError.contains('duplicate') || lowerError.contains('already exists')) {
      if (intent is CreateSpotIntent) {
        suggestions.add('A spot with this name may already exist');
        suggestions.add('Try using a different name or location');
      } else if (intent is CreateListIntent) {
        suggestions.add('A list with this name may already exist');
        suggestions.add('Try using a different name');
      }
    }
    
    // Generic suggestions if no specific ones
    if (suggestions.isEmpty && intent != null) {
      suggestions.add('Please try again');
      if (widget.onRetry != null) {
        suggestions.add('You can retry this action using the Retry button');
      }
    }
    
    return suggestions;
  }
}

