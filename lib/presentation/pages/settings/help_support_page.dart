import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Message
            const Card(
              color: AppColors.grey100,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent,
                            color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(
                          'We\'re Here to Help',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'avrai is designed to be effortless and seamless. If you need help or have questions, we\'re here to support you.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Help
            Text(
              'Quick Help',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  _buildHelpTile(
                    'Getting Started',
                    'Learn the basics of using avrai',
                    Icons.play_circle_outline,
                    () => _showGettingStarted(context),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'Creating Spots',
                    'How to add and edit your favorite places',
                    Icons.add_location,
                    () => _showCreatingSpots(context),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'Managing Lists',
                    'Organize spots into collections',
                    Icons.list,
                    () => _showManagingLists(context),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'Privacy & Settings',
                    'Control your data and preferences',
                    Icons.privacy_tip,
                    () => _showPrivacyHelp(context),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'AI2AI Learning',
                    'Understanding how avrai learns your preferences',
                    Icons.psychology,
                    () => _showAI2AIHelp(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Contact Support
            Text(
              'Contact Support',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  _buildHelpTile(
                    'Send Feedback',
                    'Share your thoughts and suggestions',
                    Icons.feedback,
                    () => _sendFeedback(context),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'Report a Bug',
                    'Help us improve avrai',
                    Icons.bug_report,
                    () => _reportBug(context),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'Email Support',
                    'Get personalized help from our team',
                    Icons.email,
                    () => _emailSupport(),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'Community Forum',
                    'Connect with other avrai users',
                    Icons.forum,
                    () => _openCommunityForum(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Resources
            Text(
              'Resources',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  _buildHelpTile(
                    'Video Tutorials',
                    'Watch step-by-step guides',
                    Icons.video_library,
                    () => _openVideoTutorials(),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'User Guide',
                    'Complete documentation',
                    Icons.menu_book,
                    () => _openUserGuide(),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'What\'s New',
                    'Latest features and updates',
                    Icons.new_releases,
                    () => _showWhatsNew(context),
                  ),
                  const Divider(height: 1),
                  _buildHelpTile(
                    'OUR_GUTS.md',
                    'Read our core philosophy and values',
                    Icons.favorite,
                    () => _showOurGuts(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // System Information
            Text(
              'System Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('App Version', '1.0.0'),
                    _buildInfoRow('Build Number', '100'),
                    _buildInfoRow('Platform', Theme.of(context).platform.name),
                    _buildInfoRow('Support ID',
                        'USR-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  void _showGettingStarted(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Getting Started'),
        content: const SingleChildScrollView(
          child: Text(
            '🎯 Welcome to avrai!\n\n'
            '1. Create your first spot by tapping the + button\n'
            '2. Add spots to lists to organize them\n'
            '3. Explore nearby spots and recommendations\n'
            '4. Share your favorite places with friends\n'
            '5. Let the AI learn your preferences for better suggestions\n\n'
            'Remember: avrai is designed to be effortless. You don\'t need to check in or jump through hoops - just enjoy discovering places where you belong!',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showCreatingSpots(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Creating Spots'),
        content: const SingleChildScrollView(
          child: Text(
            '📍 Adding Your Favorite Places:\n\n'
            '• Tap the + button on the Spots page\n'
            '• Fill in the spot name and description\n'
            '• Choose a category that fits\n'
            '• Add an address or use your current location\n'
            '• Save and start building your personal map!\n\n'
            '✏️ Editing Spots:\n'
            '• Tap any spot to view details\n'
            '• Use the edit button to modify information\n'
            '• Update location, category, or description\n'
            '• Changes are saved automatically',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showManagingLists(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Managing Lists'),
        content: const SingleChildScrollView(
          child: Text(
            '📝 Creating Lists:\n\n'
            '• Organize spots into themed collections\n'
            '• Create lists like "Date Night", "Weekend Plans", "Hidden Gems"\n'
            '• Choose whether lists are private or public\n'
            '• Add spots from the spot details page\n\n'
            '🎯 List Features:\n'
            '• Edit list details and privacy settings\n'
            '• Share lists with friends\n'
            '• Remove spots you no longer want\n'
            '• Public lists can earn "respects" from the community\n\n'
            'Per OUR_GUTS.md: Creating authentic, well-curated lists helps build expertise and community trust.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy & Control'),
        content: const SingleChildScrollView(
          child: Text(
            '🔒 Your Privacy Matters:\n\n'
            'Per OUR_GUTS.md: "Privacy and Control Are Non-Negotiable"\n\n'
            '• You control all your data and settings\n'
            '• Choose what to share and with whom\n'
            '• Control AI learning and recommendations\n'
            '• Export or delete your data anytime\n\n'
            '⚙️ Key Settings:\n'
            '• Profile visibility (private/friends/public)\n'
            '• Location sharing precision\n'
            '• AI2AI learning preferences\n'
            '• Notification controls\n\n'
            'Access all privacy settings from your profile page.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showAI2AIHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI2AI Learning'),
        content: const SingleChildScrollView(
          child: Text(
            '🤖 How avrai Learns:\n\n'
            'AI2AI learning means your device\'s AI communicates anonymously with other devices to improve recommendations while protecting your privacy.\n\n'
            '🔄 What It Learns:\n'
            '• Your spot preferences and patterns\n'
            '• Time and location preferences\n'
            '• Category and activity interests\n'
            '• Social and community patterns\n\n'
            '🛡️ Privacy Protection:\n'
            '• All learning is anonymous\n'
            '• No personal data is shared\n'
            '• You can opt out anytime\n'
            '• Data stays encrypted and local\n\n'
            'This creates better recommendations while respecting your privacy per OUR_GUTS.md principles.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _sendFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Feedback'),
        content: const Text(
          'We\'d love to hear your thoughts! Your feedback helps us make avrai better for everyone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail('feedback@avrai.app', 'avrai Feedback');
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _reportBug(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report a Bug'),
        content: const Text(
          'Found something that\'s not working right? Help us fix it by reporting the issue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _launchEmail('bugs@avrai.app', 'Bug Report');
            },
            child: const Text('Report Bug'),
          ),
        ],
      ),
    );
  }

  void _emailSupport() {
    _launchEmail('support@avrai.app', 'Support Request');
  }

  void _openCommunityForum() {
    _launchUrl('https://community.avrai.app');
  }

  void _openVideoTutorials() {
    _launchUrl('https://help.avrai.app/videos');
  }

  void _openUserGuide() {
    _launchUrl('https://help.avrai.app/guide');
  }

  void _showWhatsNew(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('What\'s New'),
        content: const SingleChildScrollView(
          child: Text(
            '🎉 avrai v1.0.0\n\n'
            '✨ New Features:\n'
            '• Complete UI overhaul\n'
            '• Edit and share spots\n'
            '• Advanced list management\n'
            '• Comprehensive privacy controls\n'
            '• AI2AI learning system\n'
            '• Maps integration\n\n'
            '🔧 Improvements:\n'
            '• Faster performance\n'
            '• Better error handling\n'
            '• Enhanced privacy controls\n'
            '• Improved notifications\n\n'
            '🛡️ Privacy:\n'
            '• Full OUR_GUTS.md compliance\n'
            '• Enhanced data controls\n'
            '• Anonymous AI learning',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  void _showOurGuts(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('OUR_GUTS.md'),
        content: const SingleChildScrollView(
          child: Text(
            '💝 Our Core Philosophy:\n\n'
            '🏠 Belonging Comes First\n'
            'Help people find places where they truly feel at home.\n\n'
            '🔒 Privacy and Control Are Non-Negotiable\n'
            'You own your data and control your experience.\n\n'
            '✨ Authenticity Over Algorithms\n'
            'Real preferences, not advertising dollars.\n\n'
            '🌊 Effortless, Seamless Discovery\n'
            'No check-ins, no hoops to jump through.\n\n'
            '🤝 Community, Not Just Places\n'
            'Connect with people and experiences.\n\n'
            '🎯 Personalized, Not Prescriptive\n'
            'Suggestions, not commands.\n\n'
            'Read the full philosophy at avrai.app/our-guts',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Love It!'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail(String email, String subject) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent(subject)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
