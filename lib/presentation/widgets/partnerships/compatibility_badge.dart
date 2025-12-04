import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';

/// Compatibility Badge Widget
/// 
/// Displays vibe compatibility percentage with color coding.
/// Green for 70%+, warning for below.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class CompatibilityBadge extends StatelessWidget {
  final double compatibility; // 0.0 to 1.0

  const CompatibilityBadge({
    super.key,
    required this.compatibility,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (compatibility * 100).toInt();
    final isGood = compatibility >= 0.70;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isGood
            ? AppColors.electricGreen.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGood
              ? AppColors.electricGreen.withValues(alpha: 0.3)
              : AppColors.warning.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGood ? Icons.check_circle : Icons.warning_amber_rounded,
            size: 14,
            color: isGood ? AppColors.electricGreen : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            '$percentage%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isGood ? AppColors.electricGreen : AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}


