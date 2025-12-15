import 'package:flutter/material.dart';
import 'package:spots/core/services/admin_auth_service.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:spots/presentation/pages/admin/god_mode_login_page.dart';
import 'package:spots/presentation/pages/admin/user_data_viewer_page.dart';
import 'package:spots/presentation/pages/admin/user_progress_viewer_page.dart';
import 'package:spots/presentation/pages/admin/user_predictions_viewer_page.dart';
import 'package:spots/presentation/pages/admin/business_accounts_viewer_page.dart';
import 'package:spots/presentation/pages/admin/communications_viewer_page.dart';
import 'package:spots/presentation/pages/admin/clubs_communities_viewer_page.dart';
import 'package:spots/presentation/pages/admin/ai_live_map_page.dart';
import 'package:spots/presentation/widgets/admin/admin_federated_rounds_widget.dart';

/// God-Mode Admin Dashboard
/// Comprehensive real-time monitoring and data access
class GodModeDashboardPage extends StatefulWidget {
  const GodModeDashboardPage({super.key});

  @override
  State<GodModeDashboardPage> createState() => _GodModeDashboardPageState();
}

class _GodModeDashboardPageState extends State<GodModeDashboardPage> with SingleTickerProviderStateMixin {
  AdminAuthService? _authService;
  AdminGodModeService? _godModeService;
  GodModeDashboardData? _dashboardData;
  bool _isLoading = true;
  int _selectedTab = 0;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTab = _tabController.index;
      });
    });
    _initializeServices();
    _loadDashboardData();
  }

  Future<void> _initializeServices() async {
    try {
      // Get services from dependency injection
      _authService = GetIt.instance<AdminAuthService>();
      
      // Check authentication
      if (!_authService!.isAuthenticated()) {
        // Defer navigation to after the frame completes to avoid Navigator lock errors
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _navigateToLogin();
          }
        });
        return;
      }
      
      // Get god-mode service from DI
      _godModeService = GetIt.instance<AdminGodModeService>();
    } catch (e) {
      debugPrint('Error initializing services: $e');
      // Defer navigation to after the frame completes to avoid Navigator lock errors
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _navigateToLogin();
        }
      });
    }
  }

  Future<void> _loadDashboardData() async {
    if (_godModeService == null) {
      await _initializeServices();
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final data = await _godModeService!.getDashboardData();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GodModeLoginPage(),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService?.logout();
      _navigateToLogin();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _godModeService?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _dashboardData == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading God-Mode Dashboard...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('God-Mode Admin'),
                Text(
                  'Privacy: IDs Only',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                ),
              ],
            ),
            const Spacer(),
            if (_dashboardData != null)
              Text(
                'Updated: ${_formatTime(_dashboardData!.lastUpdated)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.8),
                    ),
              ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.white,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.school), text: 'FL Rounds'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.trending_up), text: 'Progress'),
            Tab(icon: Icon(Icons.psychology), text: 'Predictions'),
            Tab(icon: Icon(Icons.business), text: 'Businesses'),
            Tab(icon: Icon(Icons.chat), text: 'Communications'),
            Tab(icon: Icon(Icons.group), text: 'Clubs'),
            Tab(icon: Icon(Icons.map), text: 'AI Map'),
          ],
        ),
        actions: [
          // Dynamic warning icon that changes color based on system status
          if (_dashboardData != null)
            IconButton(
              icon: Icon(
                Icons.warning_amber_rounded,
                color: _getWarningIconColor(),
              ),
              onPressed: () {
                // Show tooltip with status information
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_getWarningStatusMessage()),
                    backgroundColor: _getWarningIconColor(),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              tooltip: _getWarningTooltip(),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(),
          _buildFederatedLearningTab(),
          UserDataViewerPage(godModeService: _godModeService),
          UserProgressViewerPage(godModeService: _godModeService),
          UserPredictionsViewerPage(godModeService: _godModeService),
          BusinessAccountsViewerPage(godModeService: _godModeService),
          CommunicationsViewerPage(godModeService: _godModeService),
          ClubsCommunitiesViewerPage(godModeService: _godModeService),
          AILiveMapPage(godModeService: _godModeService),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    if (_dashboardData == null) {
      return const Center(child: Text('No data available'));
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // System Health Card
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'System Health',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _dashboardData!.systemHealth,
                      backgroundColor: AppColors.grey200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _dashboardData!.systemHealth >= 0.8
                            ? AppColors.success
                            : _dashboardData!.systemHealth >= 0.6
                                ? AppColors.warning
                                : AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_dashboardData!.systemHealth * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Metrics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricCard(
                  'Total Users',
                  '${_dashboardData!.totalUsers}',
                  Icons.people,
                  AppTheme.primaryColor,
                ),
                _buildMetricCard(
                  'Active Users',
                  '${_dashboardData!.activeUsers}',
                  Icons.person,
                  AppColors.success,
                ),
                _buildMetricCard(
                  'Business Accounts',
                  '${_dashboardData!.totalBusinessAccounts}',
                  Icons.business,
                  AppColors.electricGreen,
                ),
                _buildMetricCard(
                  'Active Connections',
                  '${_dashboardData!.activeConnections}',
                  Icons.link,
                  AppColors.warning,
                ),
                _buildMetricCard(
                  'Total Communications',
                  '${_dashboardData!.totalCommunications}',
                  Icons.chat,
                  AppTheme.primaryColor,
                ),
                _buildMetricCard(
                  'Last Updated',
                  _formatTime(_dashboardData!.lastUpdated),
                  Icons.update,
                  AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Aggregate Privacy Metrics Card
            ...[
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.privacy_tip, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'System-Wide Privacy Metrics',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mean Privacy Score: ${(_dashboardData!.aggregatePrivacyMetrics.meanOverallPrivacyScore * 100).toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: _dashboardData!.aggregatePrivacyMetrics.meanOverallPrivacyScore,
                      backgroundColor: AppColors.grey200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _dashboardData!.aggregatePrivacyMetrics.meanOverallPrivacyScore >= 0.9
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _dashboardData!.aggregatePrivacyMetrics.scoreLabel,
                      style: TextStyle(
                        color: _dashboardData!.aggregatePrivacyMetrics.meanOverallPrivacyScore >= 0.9
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_dashboardData!.aggregatePrivacyMetrics.userCount} users included',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

            // Fraud Review Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Fraud Review',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.event, color: AppTheme.primaryColor),
                      title: const Text('Event Fraud Review'),
                      subtitle: const Text('Review flagged events for fraud'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to fraud review list (would need to create)
                        // For now, show a placeholder
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fraud review list coming soon'),
                            backgroundColor: AppTheme.warningColor,
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.reviews, color: AppTheme.primaryColor),
                      title: const Text('Review Fraud Review'),
                      subtitle: const Text('Review flagged feedback for fraud'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // Navigate to review fraud review list (would need to create)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Review fraud review list coming soon'),
                            backgroundColor: AppTheme.warningColor,
                          ),
                        );
                      },
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
  
  Widget _buildFederatedLearningTab() {
    if (_godModeService == null) {
      return const Center(child: Text('Service not initialized'));
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: AdminFederatedRoundsWidget(
        godModeService: _godModeService!,
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Determines the warning icon color based on system health and privacy metrics
  Color _getWarningIconColor() {
    if (_dashboardData == null) {
      return AppColors.warning; // Default to warning if no data
    }

    final systemHealth = _dashboardData!.systemHealth;
    final privacyScore = _dashboardData!.aggregatePrivacyMetrics.meanOverallPrivacyScore;

    // Determine worst status
    // System health priority: < 60% = error, 60-80% = warning, >= 80% = success
    // Privacy priority: < 90% = warning, >= 90% = success
    
    if (systemHealth < 0.6) {
      return AppColors.error; // Critical system health
    } else if (systemHealth < 0.8 || privacyScore < 0.9) {
      return AppColors.warning; // Warning level
    } else {
      return AppColors.success; // All good
    }
  }

  /// Returns tooltip text for the warning icon
  String _getWarningTooltip() {
    if (_dashboardData == null) {
      return 'System Status: Unknown';
    }

    final systemHealth = _dashboardData!.systemHealth;
    final privacyScore = _dashboardData!.aggregatePrivacyMetrics.meanOverallPrivacyScore;

    if (systemHealth < 0.6) {
      return 'System Health: Critical (${(systemHealth * 100).toStringAsFixed(0)}%)';
    } else if (systemHealth < 0.8) {
      return 'System Health: Warning (${(systemHealth * 100).toStringAsFixed(0)}%)';
    } else if (privacyScore < 0.9) {
      return 'Privacy Score: ${(privacyScore * 100).toStringAsFixed(0)}%';
    } else {
      return 'System Status: All Good';
    }
  }

  /// Returns detailed status message for the warning icon
  String _getWarningStatusMessage() {
    if (_dashboardData == null) {
      return 'System Status: Unknown - No data available';
    }

    final systemHealth = _dashboardData!.systemHealth;
    final privacyScore = _dashboardData!.aggregatePrivacyMetrics.meanOverallPrivacyScore;
    final healthPercent = (systemHealth * 100).toStringAsFixed(1);
    final privacyPercent = (privacyScore * 100).toStringAsFixed(1);

    final List<String> issues = [];

    if (systemHealth < 0.6) {
      issues.add('System Health: CRITICAL ($healthPercent%)');
    } else if (systemHealth < 0.8) {
      issues.add('System Health: Warning ($healthPercent%)');
    }

    if (privacyScore < 0.9) {
      issues.add('Privacy Score: $privacyPercent% (below 90%)');
    }

    if (issues.isEmpty) {
      return 'System Status: All Good\n• System Health: $healthPercent%\n• Privacy Score: $privacyPercent%';
    } else {
      return 'System Status: ${issues.length > 1 ? 'Multiple Issues' : 'Issue Detected'}\n${issues.join('\n')}';
    }
  }
}

