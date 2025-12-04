import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/pages/settings/notifications_settings_page.dart';
import 'package:spots/presentation/pages/settings/privacy_settings_page.dart';
import 'package:spots/presentation/pages/settings/help_support_page.dart';
import 'package:spots/presentation/pages/settings/about_page.dart';
import 'package:spots/presentation/pages/tax/tax_profile_page.dart';
import 'package:spots/presentation/pages/tax/tax_documents_page.dart';
import 'package:spots/presentation/pages/legal/terms_of_service_page.dart';
import 'package:spots/presentation/pages/legal/privacy_policy_page.dart';
import 'package:spots/presentation/pages/verification/identity_verification_page.dart';
// Phase 1 Integration: Device Discovery & AI2AI
import 'package:go_router/go_router.dart';
// Phase 4.5: Partnership Profile Visibility
import 'package:spots/presentation/widgets/profile/partnership_display_widget.dart';
import 'package:spots/core/models/user_partnership.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: AppTheme.primaryColor,
                                child: Text(
                                  state.user.displayName
                                          ?.substring(0, 1)
                                          .toUpperCase() ??
                                      state.user.email
                                          .substring(0, 1)
                                          .toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.user.displayName ?? 'User',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    Text(
                                      state.user.email,
                                  style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppTheme.offlineColor,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          state.isOffline
                                              ? Icons.wifi_off
                                              : Icons.wifi,
                                          size: 16,
                                          color: state.isOffline
                                              ? AppTheme.offlineColor
                                              : AppTheme.successColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          state.isOffline
                                              ? 'Offline'
                                              : 'Online',
                                          style: TextStyle(
                                            color: state.isOffline
                                                ? AppTheme.offlineColor
                                                : AppTheme.successColor,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Partnerships Section (Phase 4.5)
                  _buildPartnershipsSection(context, state.user.id),

                  const SizedBox(height: 24),

                  // Settings Section
                  Text(
                    'Settings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Settings Items
                  _buildSettingsItem(
                    context,
                    icon: Icons.notifications,
                    title: 'Notifications',
                    subtitle: 'Manage your notifications',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationsSettingsPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.privacy_tip,
                    title: 'Privacy',
                    subtitle: 'Manage your privacy settings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacySettingsPage(),
                        ),
                      );
                    },
                  ),
                  // Phase 4: Expertise Dashboard Navigation
                  _buildSettingsItem(
                    context,
                    icon: Icons.school,
                    title: 'Expertise Dashboard',
                    subtitle: 'View your expertise profile and progress',
                    onTap: () {
                      context.go('/profile/expertise-dashboard');
                    },
                  ),
                  // Phase 1 Integration: New settings links
                  _buildSettingsItem(
                    context,
                    icon: Icons.radar,
                    title: 'Device Discovery',
                    subtitle: 'View nearby SPOTS-enabled devices',
                    onTap: () {
                      context.go('/device-discovery');
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.psychology,
                    title: 'AI2AI Connections',
                    subtitle: 'Manage AI personality connections',
                    onTap: () {
                      context.go('/ai2ai-connections');
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.settings_input_antenna,
                    title: 'Discovery Settings',
                    subtitle: 'Configure discovery preferences',
                    onTap: () {
                      context.go('/discovery-settings');
                    },
                  ),
                  // Phase 2.1: Federated Learning
                  _buildSettingsItem(
                    context,
                    icon: Icons.school,
                    title: 'Federated Learning',
                    subtitle: 'Privacy-preserving AI training',
                    onTap: () {
                      context.go('/federated-learning');
                    },
                  ),
                  // Phase 7, Week 37: AI Self-Improvement Visibility
                  _buildSettingsItem(
                    context,
                    icon: Icons.trending_up,
                    title: 'AI Improvement',
                    subtitle: 'See how your AI is improving',
                    onTap: () {
                      context.go('/ai-improvement');
                    },
                  ),
                  // Phase 7, Week 38: AI2AI Learning Methods UI
                  _buildSettingsItem(
                    context,
                    icon: Icons.psychology,
                    title: 'AI2AI Learning Methods',
                    subtitle: 'See how your AI learns from other AIs',
                    onTap: () {
                      context.go('/ai2ai-learning-methods');
                    },
                  ),
                  // Phase 7, Section 39: Continuous Learning UI
                  _buildSettingsItem(
                    context,
                    icon: Icons.auto_awesome,
                    title: 'Continuous Learning',
                    subtitle: 'See how your AI continuously learns',
                    onTap: () {
                      context.go('/continuous-learning');
                    },
                  ),
                  // Tax & Legal Section
                  _buildSettingsItem(
                    context,
                    icon: Icons.verified_user,
                    title: 'Identity Verification',
                    subtitle: 'Verify your identity for high earnings',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IdentityVerificationPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.receipt_long,
                    title: 'Tax Profile',
                    subtitle: 'Manage W-9 and tax information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TaxProfilePage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.description,
                    title: 'Tax Documents',
                    subtitle: 'View and download tax forms',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TaxDocumentsPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.gavel,
                    title: 'Terms of Service',
                    subtitle: 'View terms and conditions',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TermsOfServicePage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    subtitle: 'View privacy policy',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrivacyPolicyPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.help,
                    title: 'Help & Support',
                    subtitle: 'Get help and contact support',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HelpSupportPage(),
                        ),
                      );
                    },
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.info,
                    title: 'About',
                    subtitle: 'App version and information',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutPage(),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showSignOutDialog(context);
                      },
                      // Use global ElevatedButtonTheme; color implied by theme
                      child: const Text('Sign Out'),
                    ),
                  ),
                ],
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildPartnershipsSection(BuildContext context, String userId) {
    // TODO: Replace with actual PartnershipProfileService once Agent 1 completes it
    // For now, using FutureBuilder with empty list
    // The service will be: sl<PartnershipProfileService>().getActivePartnerships(userId)
    
    return FutureBuilder<List<UserPartnership>>(
      future: _loadPartnerships(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // Don't show loading, just skip if not ready
        }

        final partnerships = snapshot.data ?? [];
        
        if (partnerships.isEmpty) {
          return const SizedBox.shrink(); // Don't show empty state on profile page
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PartnershipDisplayWidget(
              partnerships: partnerships,
              maxDisplayCount: 3,
              onViewAllTap: (_) {
                context.go('/profile/partnerships');
              },
              onPartnershipTap: (partnership) {
                // Navigate to partnership details if needed
                // For now, just navigate to partnerships page
                context.go('/profile/partnerships');
              },
            ),
          ],
        );
      },
    );
  }

  Future<List<UserPartnership>> _loadPartnerships(String userId) async {
    // TODO: Replace with actual service call once PartnershipProfileService is available
    // Example:
    // final service = sl<PartnershipProfileService>();
    // return await service.getActivePartnerships(userId);
    
    // For now, return empty list
    // This will be replaced when Agent 1 completes PartnershipProfileService
    return [];
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(SignOutRequested());
              },
              // Use global ElevatedButtonTheme
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
