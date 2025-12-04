import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/colors.dart';

/// Business Accounts Viewer Page
/// View and manage business accounts
class BusinessAccountsViewerPage extends StatelessWidget {
  final AdminGodModeService? godModeService;
  
  const BusinessAccountsViewerPage({
    super.key,
    this.godModeService,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: AppColors.grey500,
          const SizedBox(height: 16),
          Text(
            'Business Accounts Viewer',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage business accounts',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey500
                ),
          ),
          // TODO: Add business accounts list and management
        ],
      ),
    );
  }
}

