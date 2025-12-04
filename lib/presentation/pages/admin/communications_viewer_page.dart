import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/pages/admin/connection_communication_detail_page.dart';

/// Communications Viewer Page
/// View AI2AI and user communications
class CommunicationsViewerPage extends StatelessWidget {
  final AdminGodModeService? godModeService;
  
  const CommunicationsViewerPage({
    super.key,
    this.godModeService,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Communications Viewer',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat, size: 64, color: AppColors.grey500,
                const SizedBox(height: 16),
                Text(
                  'View AI2AI and user communications',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.grey500
                      ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to AI2AI admin dashboard
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConnectionCommunicationDetailPage(
                          connectionId: 'example',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('View AI2AI Communications'),
                ),
                // TODO: Add user communications viewer
              ],
            ),
          ),
        ),
      ],
    );
  }
}

