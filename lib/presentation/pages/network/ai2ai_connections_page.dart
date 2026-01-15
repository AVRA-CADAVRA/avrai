/// AI2AI Connections Page
///
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI - Integration with Connection Orchestrator
///
/// Comprehensive page showing all AI2AI networking features:
/// - Device discovery status and controls
/// - Discovered devices list
/// - Active AI2AI connections
/// - Discovery settings access
///
/// Integrates with Connection Orchestrator for real-time status synchronization.
///
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/presentation/widgets/network/discovered_devices_widget.dart';
import 'package:avrai/presentation/widgets/network/ai2ai_connection_view_widget.dart';
import 'package:avrai/presentation/pages/settings/discovery_settings_page.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'dart:developer' as developer;

/// Comprehensive page for AI2AI networking and device discovery
class AI2AIConnectionsPage extends StatefulWidget {
  const AI2AIConnectionsPage({super.key});

  @override
  State<AI2AIConnectionsPage> createState() => _AI2AIConnectionsPageState();
}

class _AI2AIConnectionsPageState extends State<AI2AIConnectionsPage>
    with SingleTickerProviderStateMixin {
  DeviceDiscoveryService? _discoveryService;
  VibeConnectionOrchestrator? _orchestrator;

  List<DiscoveredDevice> _discoveredDevices = [];
  bool _isScanning = false;
  bool _isLoading = true;

  Timer? _refreshTimer;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      _discoveryService = GetIt.instance<DeviceDiscoveryService>();
      _orchestrator = GetIt.instance<VibeConnectionOrchestrator>();

      await _refreshDevices();
      _startAutoRefresh();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      developer.log('Error initializing services',
          name: 'AI2AIConnectionsPage', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoRefresh() {
    // Refresh every 3 seconds for real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        _refreshDevices();
      }
    });
  }

  Future<void> _refreshDevices() async {
    if (_discoveryService == null) return;

    final devices = _discoveryService!.getDiscoveredDevices();
    if (mounted) {
      setState(() {
        _discoveredDevices = devices;
      });
    }
  }

  Future<void> _toggleDiscovery() async {
    if (_discoveryService == null) return;

    final newState = !_isScanning;

    setState(() {
      _isScanning = newState;
    });

    if (newState) {
      await _discoveryService!.startDiscovery();
    } else {
      _discoveryService!.stopDiscovery();
    }

    await _refreshDevices();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('AI2AI Network'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI2AI Network'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _navigateToSettings,
            tooltip: 'Discovery Settings',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDevices,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.electricGreen,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          tabs: const [
            Tab(icon: Icon(Icons.radar), text: 'Discovery'),
            Tab(icon: Icon(Icons.devices), text: 'Devices'),
            Tab(icon: Icon(Icons.psychology), text: 'AI Connections'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDiscoveryTab(),
          _buildDevicesTab(),
          _buildConnectionsTab(),
        ],
      ),
    );
  }

  Widget _buildDiscoveryTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDiscoveryStatusCard(),
          _buildDiscoveryStatsCard(),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildDiscoveryStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: _isScanning
              ? LinearGradient(
                  colors: [
                    AppColors.electricGreen.withValues(alpha: 0.1),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isScanning
                        ? AppColors.electricGreen.withValues(alpha: 0.2)
                        : AppColors.grey200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isScanning ? Icons.radar : Icons.radar_outlined,
                    color: _isScanning
                        ? AppColors.electricGreen
                        : AppColors.textSecondary,
                    size: 36,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isScanning ? 'Discovery Active' : 'Discovery Inactive',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _isScanning
                            ? 'Scanning for nearby devices...'
                            : 'Start to discover nearby AI devices',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleDiscovery,
                icon: Icon(_isScanning ? Icons.stop : Icons.play_arrow),
                label: Text(_isScanning ? 'Stop Discovery' : 'Start Discovery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isScanning ? AppColors.error : AppColors.electricGreen,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryStatsCard() {
    final activeConnections = _orchestrator?.getActiveConnections() ?? [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Network Statistics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  Icons.devices,
                  '${_discoveredDevices.length}',
                  'Discovered',
                  AppColors.primary,
                ),
                _buildStatItem(
                  Icons.link,
                  '${activeConnections.length}',
                  'Connected',
                  AppColors.electricGreen,
                ),
                _buildStatItem(
                  Icons.psychology,
                  '${_discoveredDevices.where((d) => d.personalityData != null).length}',
                  'AI Enabled',
                  AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.settings,
                color: AppColors.primary,
              ),
            ),
            title: const Text('Discovery Settings'),
            subtitle: const Text('Configure discovery methods and privacy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _navigateToSettings,
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.electricGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.info_outline,
                color: AppColors.electricGreen,
              ),
            ),
            title: const Text('How Discovery Works'),
            subtitle: const Text('Learn about AI2AI networking'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showDiscoveryInfoDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildDevicesTab() {
    if (!_isScanning) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.radar_outlined,
                size: 80,
                color: AppColors.grey300,
              ),
              const SizedBox(height: 24),
              const Text(
                'Discovery is off',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Start discovery to find nearby avrai devices',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _toggleDiscovery,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Discovery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.electricGreen,
                  foregroundColor: AppColors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return DiscoveredDevicesWidget(
      devices: _discoveredDevices,
      onRefresh: _refreshDevices,
      showConnectionButton: true,
    );
  }

  Widget _buildConnectionsTab() {
    return AI2AIConnectionViewWidget(
      showHumanConnectionButton: true,
      onEnableHumanConnection: _handleHumanConnectionEnabled,
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DiscoverySettingsPage(),
      ),
    ).then((_) {
      // Refresh after returning from settings
      _refreshDevices();
    });
  }

  void _showDiscoveryInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.psychology,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 12),
            Text('AI2AI Discovery'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How It Works:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildInfoPoint(
                '1. Your AI broadcasts anonymized personality patterns',
              ),
              _buildInfoPoint(
                '2. Nearby AIs detect and analyze compatibility',
              ),
              _buildInfoPoint(
                '3. Compatible AIs connect automatically',
              ),
              _buildInfoPoint(
                '4. Learning exchanges happen between AI personalities',
              ),
              _buildInfoPoint(
                '5. At 100% compatibility, human conversation is enabled',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.verified_user,
                      color: AppColors.electricGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All interactions follow ai2ai principles from OUR_GUTS.md',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle,
            size: 18,
            color: AppColors.electricGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleHumanConnectionEnabled(dynamic connection) {
    // Handle navigation to human chat or other UI flow
    // This is where you'd integrate with your chat/messaging system
    debugPrint('Human connection enabled for: ${connection.connectionId}');
  }
}
