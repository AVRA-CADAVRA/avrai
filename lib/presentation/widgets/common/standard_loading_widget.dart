/// Standard Loading Widget
/// 
/// Phase 7, Section 42 (7.4.4): UI Integration Improvements
/// Agent 2: Frontend & UX Specialist
/// 
/// Provides a consistent loading indicator pattern across all UI components.
/// Standardizes loading indicators, loading messages, and loading placement.
/// 
/// Uses AppColors and AppTheme for 100% design token compliance.

import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Standardized loading widget for consistent loading states across the app
class StandardLoadingWidget extends StatelessWidget {
  /// Optional loading message
  final String? message;
  
  /// Size of the loading indicator (defaults to 40)
  final double size;
  
  /// Stroke width of the circular progress indicator (defaults to 3)
  final double strokeWidth;
  
  /// Compact mode - smaller size and text (defaults to false)
  final bool compact;

  const StandardLoadingWidget({
    super.key,
    this.message,
    this.size = 40,
    this.strokeWidth = 3,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: compact ? size * 0.75 : size,
            height: compact ? size * 0.75 : size,
            child: CircularProgressIndicator(
              strokeWidth: compact ? strokeWidth * 0.75 : strokeWidth,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: compact ? 12 : 16),
            Text(
              message!,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  /// Inline loading widget (for buttons, small spaces)
  static Widget inline({
    String? message,
    double size = 20,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.primaryColor,
            ),
          ),
        ),
        if (message != null) ...[
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  /// Full-screen loading widget (for pages)
  static Widget fullScreen({
    String? message,
  }) {
    return Center(
      child: StandardLoadingWidget(
        message: message,
        size: 40,
      ),
    );
  }

  /// Container loading widget (for cards, containers)
  static Widget container({
    String? message,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(24),
      child: StandardLoadingWidget(
        message: message,
        size: 40,
      ),
    );
  }

  /// Compact loading widget (for lists, small spaces)
  static Widget compactSize({
    String? message,
  }) {
    return StandardLoadingWidget(
      message: message,
      size: 24,
      strokeWidth: 2,
      compact: true,
    );
  }
}

