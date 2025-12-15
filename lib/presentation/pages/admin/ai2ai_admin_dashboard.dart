import 'dart:async';
import 'package:flutter/material.dart';
import 'package:spots/core/monitoring/network_analytics.dart';
import 'package:spots/core/monitoring/connection_monitor.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/widgets/ai2ai/network_health_gauge.dart';
import 'package:spots/presentation/widgets/ai2ai/connections_list.dart';
import 'package:spots/presentation/widgets/ai2ai/learning_metrics_chart.dart';
import 'package:spots/presentation/widgets/ai2ai/privacy_compliance_card.dart';
import 'package:spots/presentation/widgets/ai2ai/performance_issues_list.dart';
import 'package:spots/presentation/widgets/admin/admin_collaborative_activity_widget.dart';
import 'package:spots/core/services/admin_god_mode_service.dart';
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat;
import 'package:get_it/get_it.dart';

/// Admin Dashboard for AI2AI Network Monitoring
/// Displays network health, connections, learning metrics, privacy, and performance
class AI2AIAdminDashboard extends StatefulWidget {
  const AI2AIAdminDashboard({super.key});

  @override
  State<AI2AIAdminDashboard> createState() => _AI2AIAdminDashboardState();
}

class _AI2AIAdminDashboardState extends State<AI2AIAdminDashboard> {
  NetworkAnalytics? _networkAnalytics;
  ConnectionMonitor? _connectionMonitor;
  StreamSubscription<NetworkHealthReport>? _healthReportSubscription;
  StreamSubscription<ActiveConnectionsOverview>? _connectionsSubscription;
  StreamSubscription<RealTimeMetrics>? _realTimeMetricsSubscription;
  
  NetworkHealthReport? _healthReport;
  ActiveConnectionsOverview? _connectionsOverview;
  RealTimeMetrics? _realTimeMetrics;
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _errorMessage;
  DateTime? _lastUpdate;
  bool _isStreamConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = GetIt.instance<SharedPreferencesCompat>();
      _networkAnalytics = NetworkAnalytics(prefs: prefs);
      _connectionMonitor = ConnectionMonitor(prefs: prefs);
      _setupStreams();
    } catch (e) {
      debugPrint('Error initializing services: $e');
      setState(() {
        _errorMessage = 'Failed to initialize services: $e';
        _isLoading = false;
      });
    }
  }

  void _setupStreams() {
    if (_networkAnalytics == null || _connectionMonitor == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isStreamConnected = true;
    });

    // Stream network health
    _healthReportSubscription = _networkAnalytics!.streamNetworkHealth().listen(
      (report) {
        setState(() {
          _healthReport = report;
          _lastUpdate = DateTime.now();
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        debugPrint('Error in health report stream: $error');
        setState(() {
          _errorMessage = 'Error loading network health: $error';
          _isLoading = false;
          _isRefreshing = false;
        });
      },
    );

    // Stream active connections
    _connectionsSubscription = _connectionMonitor!.streamActiveConnections().listen(
      (overview) {
        setState(() {
          _connectionsOverview = overview;
          _lastUpdate = DateTime.now();
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        debugPrint('Error in connections stream: $error');
        setState(() {
          _errorMessage = 'Error loading connections: $error';
          _isLoading = false;
          _isRefreshing = false;
        });
      },
    );

    // Stream real-time metrics
    _realTimeMetricsSubscription = _networkAnalytics!.streamRealTimeMetrics().listen(
      (metrics) {
        setState(() {
          _realTimeMetrics = metrics;
          _lastUpdate = DateTime.now();
          _isLoading = false;
          _isRefreshing = false;
          _errorMessage = null;
        });
      },
      onError: (error) {
        debugPrint('Error in real-time metrics stream: $error');
        setState(() {
          _errorMessage = 'Error loading real-time metrics: $error';
          _isLoading = false;
          _isRefreshing = false;
        });
      },
    );
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
      _errorMessage = null;
    });
    
    // Manually trigger refresh by getting latest data
    try {
      if (_networkAnalytics != null && _connectionMonitor != null) {
        final healthReport = await _networkAnalytics!.analyzeNetworkHealth();
        final connectionsOverview = await _connectionMonitor!.getActiveConnectionsOverview();
        final realTimeMetrics = await _networkAnalytics!.collectRealTimeMetrics();
        
        setState(() {
          _healthReport = healthReport;
          _connectionsOverview = connectionsOverview;
          _realTimeMetrics = realTimeMetrics;
          _lastUpdate = DateTime.now();
          _isRefreshing = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing dashboard: $e');
      setState(() {
        _errorMessage = 'Error refreshing: $e';
        _isRefreshing = false;
      });
    }
  }

  @override
  void dispose() {
    _healthReportSubscription?.cancel();
    _connectionsSubscription?.cancel();
    _realTimeMetricsSubscription?.cancel();
    _connectionMonitor?.disposeStreams();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI2AI Network Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        actions: [
          // Stream connection status indicator
          if (_isStreamConnected)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Live',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshDashboard,
            tooltip: 'Refresh Dashboard',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _healthReport == null && _connectionsOverview == null && _realTimeMetrics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _healthReport == null && _connectionsOverview == null && _realTimeMetrics == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Error Loading Dashboard',
              style: TextStyle(fontSize: 18, color: AppColors.error),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshDashboard,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshDashboard,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Last update timestamp
            if (_lastUpdate != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Last update: ${_formatTime(_lastUpdate!)}',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            // Error banner if partial error
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: AppColors.error, fontSize: 12),
                      ),
                    ),
                    TextButton(
                      onPressed: _refreshDashboard,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),

            // Network Health Gauge
            if (_healthReport != null)
              NetworkHealthGauge(healthReport: _healthReport!)
            else if (!_isLoading)
              _buildEmptyState('Network Health', 'No network health data available'),

            const SizedBox(height: 24),

            // Connections List
            if (_connectionsOverview != null)
              ConnectionsList(overview: _connectionsOverview!)
            else if (!_isLoading)
              _buildEmptyState('Active Connections', 'No connection data available'),

            const SizedBox(height: 24),

            // Learning Metrics Chart
            if (_realTimeMetrics != null)
              LearningMetricsChart(metrics: _realTimeMetrics!)
            else if (!_isLoading)
              _buildEmptyState('Learning Metrics', 'No metrics data available'),

            const SizedBox(height: 24),

            // Privacy Compliance Card
            if (_healthReport != null)
              PrivacyComplianceCard(
                privacyMetrics: _healthReport!.privacyMetrics,
              ),

            const SizedBox(height: 24),

            // Performance Issues List
            if (_healthReport != null)
              PerformanceIssuesList(
                issues: _healthReport!.performanceIssues,
                recommendations: _healthReport!.optimizationRecommendations,
              ),

            const SizedBox(height: 24),

            // Collaborative Activity Analytics Section
            _buildCollaborativeActivitySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildCollaborativeActivitySection() {
    // Try to get god mode service if available
    AdminGodModeService? godModeService;
    try {
      godModeService = GetIt.instance<AdminGodModeService>();
    } catch (e) {
      debugPrint('AdminGodModeService not available: $e');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Collaborative Activity Analytics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Privacy-safe aggregate metrics on AI2AI collaborative patterns',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 16),
        AdminCollaborativeActivityWidget(
          godModeService: godModeService,
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
    } else {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }
}

