import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';

/// Widget displaying privacy controls for AI2AI participation
class PrivacyControlsWidget extends StatefulWidget {
  const PrivacyControlsWidget({super.key});

  @override
  State<PrivacyControlsWidget> createState() => _PrivacyControlsWidgetState();
}

class _PrivacyControlsWidgetState extends State<PrivacyControlsWidget> {
  bool _ai2aiEnabled = true;
  String _privacyLevel = 'MAXIMUM_ANONYMIZATION';
  bool _shareLearningInsights = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.privacy_tip, color: AppColors.success),
                const SizedBox(width: 8),
                Text(
                  'Privacy Controls',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // AI2AI Participation Toggle
            SwitchListTile(
              title: const Text('AI2AI Participation'),
              subtitle: const Text(
                'Allow your AI personality to connect with other AIs',
              ),
              value: _ai2aiEnabled,
              onChanged: (value) {
                setState(() {
                  _ai2aiEnabled = value;
                });
              },
              activeColor: AppColors.success,
            ),
            const Divider(),
            // Privacy Level Selector
            ListTile(
              title: const Text('Privacy Level'),
              subtitle: const Text('Maximum anonymization recommended'),
              trailing: DropdownButton<String>(
                value: _privacyLevel,
                items: const [
                  DropdownMenuItem(
                    value: 'MAXIMUM_ANONYMIZATION',
                    child: Text('Maximum'),
                  ),
                  DropdownMenuItem(
                    value: 'HIGH_ANONYMIZATION',
                    child: Text('High'),
                  ),
                  DropdownMenuItem(
                    value: 'MODERATE_ANONYMIZATION',
                    child: Text('Moderate'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _privacyLevel = value;
                    });
                  }
                },
              ),
            ),
            const Divider(),
            // Share Learning Insights Toggle
            SwitchListTile(
              title: const Text('Share Learning Insights'),
              subtitle: const Text(
                'Contribute anonymized insights to improve the network',
              ),
              value: _shareLearningInsights,
              onChanged: (value) {
                setState(() {
                  _shareLearningInsights = value;
                });
              },
              activeColor: AppColors.success,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'All data is anonymized and privacy-preserving. Your identity is never exposed.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

