import 'package:flutter/material.dart';
import 'package:avrai/core/services/business_auth_service.dart';
import 'package:avrai/core/services/business_account_service.dart';
import 'package:avrai/core/models/business_account.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/presentation/pages/business/business_login_page.dart';
import 'package:avrai/presentation/pages/business/business_conversations_list_page.dart';
import 'package:avrai/presentation/pages/business/business_expert_discovery_page.dart';
import 'package:avrai/presentation/pages/business/reservations/reservation_dashboard_page.dart';
import 'package:avrai/presentation/pages/business/reservations/reservation_settings_page.dart';
import 'package:avrai/presentation/pages/business/reservations/business_reservation_analytics_page.dart';
import 'package:avrai/core/models/reservation.dart';

/// Business Dashboard Page
/// Main dashboard for business accounts after login
class BusinessDashboardPage extends StatefulWidget {
  const BusinessDashboardPage({super.key});

  @override
  State<BusinessDashboardPage> createState() => _BusinessDashboardPageState();
}

class _BusinessDashboardPageState extends State<BusinessDashboardPage> {
  BusinessAuthService? _authService;
  BusinessAccountService? _businessService;
  BusinessAccount? _businessAccount;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadBusinessData();
  }

  Future<void> _initializeServices() async {
    try {
      if (GetIt.instance.isRegistered<BusinessAuthService>()) {
        _authService = GetIt.instance<BusinessAuthService>();
      }
      if (GetIt.instance.isRegistered<BusinessAccountService>()) {
        _businessService = GetIt.instance<BusinessAccountService>();
      }

      // Check if authenticated
      if (_authService == null || !_authService!.isAuthenticated()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const BusinessLoginPage(),
              ),
            );
          }
        });
        return;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to initialize services: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadBusinessData() async {
    if (_authService == null || _businessService == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final businessId = _authService!.getCurrentBusinessId();
      if (businessId == null) {
        setState(() {
          _errorMessage = 'No business ID found in session';
          _isLoading = false;
        });
        return;
      }

      // Load business account
      final business = await _businessService!.getBusinessAccount(businessId);

      setState(() {
        _businessAccount = business;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load business data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    await _authService?.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const BusinessLoginPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.grey50,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: AppColors.grey50,
        appBar: AppBar(
          title: const Text('Business Dashboard'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loadBusinessData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.grey50,
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBusinessData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Info Card
              if (_businessAccount != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business,
                                color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              _businessAccount!.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const Spacer(),
                            if (_businessAccount!.isVerified)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.success.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: AppColors.success,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (_businessAccount!.description != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _businessAccount!.description!,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_businessAccount!.location != null)
                              Chip(
                                label: Text(_businessAccount!.location!),
                                avatar: const Icon(Icons.location_on, size: 16),
                              ),
                            if (_businessAccount!.businessType.isNotEmpty)
                              Chip(
                                label: Text(_businessAccount!.businessType),
                                avatar: const Icon(Icons.category, size: 16),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
                children: [
                  _buildActionCard(
                    context,
                    icon: Icons.message,
                    title: 'Messages',
                    subtitle: 'Chat with experts',
                    onTap: () {
                      final businessId = _businessAccount?.id;
                      if (businessId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessConversationsListPage(
                              businessId: businessId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.search,
                    title: 'Discover',
                    subtitle: 'Find experts',
                    onTap: () {
                      final businessId = _businessAccount?.id;
                      if (businessId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BusinessExpertDiscoveryPage(
                              businessId: businessId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.event_available,
                    title: 'Reservations',
                    subtitle: 'Manage reservations',
                    onTap: () {
                      final businessId = _businessAccount?.id;
                      if (businessId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ReservationDashboardPage(
                              businessId: businessId,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.event,
                    title: 'Events',
                    subtitle: 'Manage events',
                    onTap: () {
                      // TODO: Navigate to events
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Events feature coming soon'),
                        ),
                      );
                    },
                  ),
                  _buildActionCard(
                    context,
                    icon: Icons.analytics,
                    title: 'Analytics',
                    subtitle: 'View insights',
                    onTap: () {
                      final businessId = _businessAccount?.id;
                      if (businessId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BusinessReservationAnalyticsPage(
                              businessId: businessId,
                              type: ReservationType.business,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),

              // Reservation Settings Section
              const SizedBox(height: 24),
              Text(
                'Reservation Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.settings,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Reservation Preferences',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage reservation hours, capacity, time slots, and cancellation policies.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ReservationSettingsPage(
                                businessId: _businessAccount?.id ?? '',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Configure Settings'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Coming Soon',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Business-expert chat, business-business partnerships, and multi-party event creation will be available in the next phase.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: AppTheme.primaryColor),
              const SizedBox(height: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
