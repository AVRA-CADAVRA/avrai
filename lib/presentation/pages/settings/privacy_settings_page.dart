import 'package:flutter/material.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  // Privacy preferences - would normally be stored in user preferences
  bool _shareLocation = true;
  bool _ai2aiLearning = true;
  bool _communityRecommendations = true;
  bool _publicProfile = false;
  bool _publicLists = false;
  bool _analyticsOptIn = false;
  bool _personalizedAds = false;
  // Removed unused _dataExportEnabled field
  
  String _profileVisibility = 'Friends Only';
  String _locationSharing = 'Precise';
  String _dataRetention = '1 Year';

  final List<String> _profileOptions = ['Private', 'Friends Only', 'Public'];
  final List<String> _locationOptions = ['Precise', 'Approximate', 'City Only', 'Disabled'];
  final List<String> _retentionOptions = ['3 Months', '6 Months', '1 Year', '2 Years', 'Forever'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Settings'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OUR_GUTS.md Commitment
            Card(
              color: AppColors.grey100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user, color: AppTheme.successColor),
                        const SizedBox(width: 8),
                        Text(
                          'OUR_GUTS.md Commitment',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '"Privacy and Control Are Non-Negotiable" - You own your data, you control your experience, and you decide what to share.',
                      style: TextStyle(color: AppTheme.successColor),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Core Privacy Controls
            Text(
              'Core Privacy Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildDropdownTile(
              'Profile Visibility',
              'Who can see your profile and activity',
              _profileVisibility,
              _profileOptions,
              (value) => setState(() => _profileVisibility = value!),
              Icons.person,
            ),

            _buildDropdownTile(
              'Location Sharing',
              'How precise location data is shared',
              _locationSharing,
              _locationOptions,
              (value) => setState(() => _locationSharing = value!),
              Icons.location_on,
            ),

            _buildSwitchTile(
              'Share Location Data',
              'Allow location-based recommendations',
              _shareLocation,
              (value) => setState(() => _shareLocation = value),
              Icons.share_location,
            ),

            const SizedBox(height: 24),

            // AI & Learning Controls
            Text(
              'AI & Learning Controls',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Control how AI learns from your behavior and preferences',
                     style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                 color: AppColors.textSecondary,
               ),
            ),
            const SizedBox(height: 16),

            _buildSwitchTile(
              'AI2AI Learning',
              'Enable anonymous personality learning between devices',
              _ai2aiLearning,
              (value) => setState(() => _ai2aiLearning = value),
              Icons.psychology,
            ),

            _buildSwitchTile(
              'Community Recommendations',
              'Use community data for personalized recommendations',
              _communityRecommendations,
              (value) => setState(() => _communityRecommendations = value),
              Icons.group,
            ),

            const SizedBox(height: 24),

            // Public Sharing
            Text(
              'Public Sharing',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildSwitchTile(
              'Public Profile',
              'Make your profile visible to everyone',
              _publicProfile,
              (value) => setState(() => _publicProfile = value),
              Icons.public,
            ),

            _buildSwitchTile(
              'Default Public Lists',
              'Make new lists public by default',
              _publicLists,
              (value) => setState(() => _publicLists = value),
              Icons.list,
            ),

            const SizedBox(height: 24),

            // Data & Analytics
            Text(
              'Data & Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildDropdownTile(
              'Data Retention',
              'How long to keep your activity data',
              _dataRetention,
              _retentionOptions,
              (value) => setState(() => _dataRetention = value!),
              Icons.schedule,
            ),

            _buildSwitchTile(
              'Usage Analytics',
              'Help improve SPOTS with anonymous usage data',
              _analyticsOptIn,
              (value) => setState(() => _analyticsOptIn = value),
              Icons.analytics,
            ),

            _buildSwitchTile(
              'Personalized Ads',
              'Show ads based on your interests (off by default)',
              _personalizedAds,
              (value) => setState(() => _personalizedAds = value),
              Icons.ad_units,
            ),

            const SizedBox(height: 24),

            // Data Rights
            Text(
              'Your Data Rights',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download, color: AppTheme.primaryColor),
                    title: const Text('Export My Data'),
                    subtitle: const Text('Download all your SPOTS data'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _exportData,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.delete_forever, color: AppTheme.errorColor),
                    title: const Text('Delete My Account'),
                    subtitle: const Text('Permanently delete your account and data'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _showDeleteAccountDialog,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.policy, color: AppTheme.primaryColor),
                    title: const Text('Privacy Policy'),
                    subtitle: const Text('Read our full privacy policy'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: _openPrivacyPolicy,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reset Settings
            Card(
              color: AppColors.grey100,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restore, color: AppTheme.warningColor),
                        const SizedBox(width: 8),
                        Text(
                          'Reset Privacy Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                     const Text(
                      'Reset all privacy settings to their default values',
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _resetPrivacySettings,
                      // Use global ElevatedButtonTheme
                      child: const Text('Reset to Defaults'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        secondary: Icon(icon, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String subtitle,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option,
              child: Text(option),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export initiated. You will receive an email with download instructions.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to permanently delete your account? This action cannot be undone and will remove all your data, spots, and lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion requires additional verification. Check your email.'),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  void _openPrivacyPolicy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening privacy policy...'),
      ),
    );
  }

  void _resetPrivacySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Privacy Settings'),
        content: const Text('This will reset all privacy settings to their default values. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _shareLocation = true;
                _ai2aiLearning = true;
                _communityRecommendations = true;
                _publicProfile = false;
                _publicLists = false;
                _analyticsOptIn = false;
                _personalizedAds = false;
                _profileVisibility = 'Friends Only';
                _locationSharing = 'Precise';
                _dataRetention = '1 Year';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy settings reset to defaults'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}