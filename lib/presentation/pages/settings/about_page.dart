import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About avrai'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.place,
                      size: 60,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'avrai',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'know you belong.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.grey600,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // OUR_GUTS.md Mission
            const Card(
              color: AppColors.grey100,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Our Mission',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'avrai exists to help people find places, experiences, and communities where they truly feel at home—wherever they are. We believe everyone deserves to know they belong.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Core Values
            Text(
              'Our Values',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            _buildValueCard(
              'Belonging Comes First',
              'We help you find places where you truly feel at home.',
              Icons.home,
              AppColors.warning,
            ),
            _buildValueCard(
              'Privacy & Control',
              'Your data is yours. You control your experience.',
              Icons.privacy_tip,
              AppTheme.successColor,
            ),
            _buildValueCard(
              'Authenticity Over Algorithms',
              'Real preferences, not advertising dollars.',
              Icons.psychology,
              AppColors.grey600,
            ),
            _buildValueCard(
              'Effortless Discovery',
              'No check-ins, no hassle. Just enjoy the moment.',
              Icons.auto_awesome,
              AppColors.grey600,
            ),

            const SizedBox(height: 24),

            // App Information
            Text(
              'App Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Version', '1.0.0'),
                    _buildInfoRow('Build', '100'),
                    _buildInfoRow('Release Date', 'August 2025'),
                    _buildInfoRow('Platform', 'Flutter'),
                    _buildInfoRow('Architecture', 'AI2AI Learning'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features
            Text(
              'Key Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  _buildFeatureTile(
                    'Spot Discovery',
                    'Find and create your favorite places',
                    Icons.place,
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    'Smart Lists',
                    'Organize spots into curated collections',
                    Icons.list,
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    'AI2AI Learning',
                    'Anonymous personality learning for better recommendations',
                    Icons.psychology,
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    'Community Sharing',
                    'Share discoveries while maintaining privacy',
                    Icons.share,
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    'Maps Integration',
                    'Seamless navigation to your spots',
                    Icons.directions,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Links & Contact
            Text(
              'Connect With Us',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),

            Card(
              child: Column(
                children: [
                  _buildLinkTile(
                    'Website',
                    'avrai.app',
                    Icons.web,
                    () => _launchUrl('https://avrai.app'),
                  ),
                  const Divider(height: 1),
                  _buildLinkTile(
                    'OUR_GUTS.md',
                    'Read our full philosophy',
                    Icons.favorite,
                    () => _launchUrl('https://avrai.app/our-guts'),
                  ),
                  const Divider(height: 1),
                  _buildLinkTile(
                    'Privacy Policy',
                    'How we protect your data',
                    Icons.policy,
                    () => _launchUrl('https://avrai.app/privacy'),
                  ),
                  const Divider(height: 1),
                  _buildLinkTile(
                    'Terms of Service',
                    'Usage terms and conditions',
                    Icons.gavel,
                    () => _launchUrl('https://avrai.app/terms'),
                  ),
                  const Divider(height: 1),
                  _buildLinkTile(
                    'Support',
                    'Get help and contact us',
                    Icons.support_agent,
                    () => _launchEmail('support@avrai.app'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal
            Text(
              'Legal',
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
                    Text(
                      '© 2025 avrai Technologies, Inc.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All rights reserved. avrai and "know you belong" are trademarks of avrai Technologies, Inc.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Third-Party Licenses',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showLicenses(context),
                      child: const Text('View Open Source Licenses'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Credits
            const Card(
              color: AppColors.grey100,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Made with ❤️',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'avrai is built with care by a team that believes technology should help people feel more connected to the places and communities around them.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Thank you for being part of our community! 🌟',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildValueCard(
      String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(String title, String description, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey600),
      title: Text(title),
      subtitle: Text(description),
    );
  }

  Widget _buildLinkTile(
      String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.grey600),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'avrai',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.place,
          color: AppColors.white,
          size: 32,
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(
      scheme: 'mailto',
      path: email,
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
