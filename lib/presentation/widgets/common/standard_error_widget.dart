/// Standard Error Widget
/// 
/// Phase 7, Section 42 (7.4.4): UI Integration Improvements
/// Agent 2: Frontend & UX Specialist
/// 
/// Provides a consistent error display widget across all UI components.
/// Standardizes error message format, error state displays, and retry mechanisms.
/// 
/// Uses AppColors and AppTheme for 100% design token compliance.

import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/services/logger.dart';

/// Standardized error widget for consistent error display across the app
class StandardErrorWidget extends StatelessWidget {
  static const String _logName = 'StandardErrorWidget';
  static const AppLogger _logger = AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.info,
  );
  /// The error message to display (user-friendly)
  final String message;
  
  /// Optional retry callback - if provided, shows retry button
  final VoidCallback? onRetry;
  
  /// Optional retry label (defaults to "Retry")
  final String? retryLabel;
  
  /// Whether to show the error icon (defaults to true)
  final bool showIcon;
  
  /// Compact mode - smaller padding and text (defaults to false)
  final bool compact;

  const StandardErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel,
    this.showIcon = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Log error display for monitoring and debugging
    _logger.error(
      'Error displayed: ${message.length > 100 ? message.substring(0, 100) + "..." : message}',
      tag: _logName,
    );
    
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showIcon) ...[
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: compact ? 18 : 20,
                ),
                SizedBox(width: compact ? 8 : 12),
              ],
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    color: AppColors.error,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (onRetry != null) ...[
            SizedBox(height: compact ? 8 : 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 16),
                label: Text(retryLabel ?? 'Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 16 : 20,
                    vertical: compact ? 8 : 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Inline error widget (for form fields, etc.)
  static Widget inline({
    required String message,
    bool showIcon = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              Icons.error_outline,
              size: 16,
              color: AppColors.error,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Full-screen error widget (for pages)
  static Widget fullScreen({
    required String message,
    VoidCallback? onRetry,
    String? retryLabel,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: StandardErrorWidget(
          message: message,
          onRetry: onRetry,
          retryLabel: retryLabel,
        ),
      ),
    );
  }
}

