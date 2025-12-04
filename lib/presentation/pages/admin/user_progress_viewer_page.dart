import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/colors.dart';

/// User Progress Viewer Page
/// View user progress and expertise tracking
class UserProgressViewerPage extends StatelessWidget {
  final AdminGodModeService? godModeService;
  
  const UserProgressViewerPage({
    super.key,
    this.godModeService,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: AppColors.grey500,
          const SizedBox(height: 16),
          Text(
            'User Progress Viewer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Search for a user to view their progress',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500
                ),
          ),
          // TODO: Add user search and progress display
        ],
      ),
    );
  }
}

