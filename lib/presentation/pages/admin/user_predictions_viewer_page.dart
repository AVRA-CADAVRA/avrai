import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/colors.dart';

/// User Predictions Viewer Page
/// View AI predictions for user behavior
class UserPredictionsViewerPage extends StatelessWidget {
  final AdminGodModeService? godModeService;
  
  const UserPredictionsViewerPage({
    super.key,
    this.godModeService,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 64, color: AppColors.grey500,
          const SizedBox(height: 16),
          Text(
            'User Predictions Viewer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a user to view their predictions',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500
                ),
          ),
          // TODO: Add user search and predictions display
        ],
      ),
    );
  }
}

