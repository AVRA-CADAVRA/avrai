/// Device Discovery Status Page
///
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI
///
/// Shows device discovery status and lists discovered devices nearby.
/// Users can see what SPOTS-enabled devices are in their proximity.
///
/// Features:
/// - Discovery status (on/off)
/// - List of discovered devices
/// - Connection status indicators
/// - Real-time updates
/// - Privacy-preserving device info
///
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:get_it/get_it.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';

/// Page displaying device discovery status and discovered devices
class DeviceDiscoveryPage extends StatefulWidget {
  const DeviceDiscoveryPage({super.key});

  @override
  State<DeviceDiscoveryPage> createState() => _DeviceDiscoveryPageState();
}

class _DeviceDiscoveryPageState extends State<DeviceDiscoveryPage> {
  DeviceDiscoveryService? _discoveryService;
  List<DiscoveredDevice> _discoveredDevices = [];
  bool _isScanning = false;
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeDiscovery();
  }

  Future<void> _initializeDiscovery() async {
    try {
      _discoveryService = GetIt.instance<DeviceDiscoveryService>();
      await _refreshDevices();
      _startAutoRefresh();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing discovery: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startAutoRefresh() {
    // Refresh device list every 3 seconds while page is active
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

    setState(() {
      _isScanning = !_isScanning;
    });

    if (_isScanning) {
      await _discoveryService!.startDiscovery();
    } else {
      _discoveryService!.stopDiscovery();
    }

    await _refreshDevices();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Device Discovery'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Discovery'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        actions: [
          if (_discoveredDevices.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.group),
              onPressed: () {
                context.go('/group/formation');
              },
              tooltip: 'Form Group',
            ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
            tooltip: 'About Discovery',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildDiscoveryStatusCard(),
            _buildDevicesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryStatusCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isScanning
                        ? AppColors.electricGreen.withValues(alpha: 0.1)
                        : AppColors.grey200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isScanning ? Icons.radar : Icons.radar_outlined,
                    color: _isScanning
                        ? AppColors.electricGreen
                        : AppColors.textSecondary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isScanning ? 'Discovery Active' : 'Discovery Inactive',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isScanning
                            ? 'Scanning for nearby avrai devices...'
                            : 'Tap to start discovering nearby devices',
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
            const SizedBox(height: 16),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            if (_isScanning) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.devices,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_discoveredDevices.length} device${_discoveredDevices.length == 1 ? '' : 's'} found',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDevicesList() {
    if (!_isScanning) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.radar_outlined,
                size: 64,
                color: AppColors.grey300,
              ),
              SizedBox(height: 16),
              Text(
                'Start discovery to find nearby devices',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_discoveredDevices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Searching for nearby avrai devices...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Discovered Devices',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _discoveredDevices.length,
          itemBuilder: (context, index) {
            return _buildDeviceCard(_discoveredDevices[index]);
          },
        ),
      ],
    );
  }

  Widget _buildDeviceCard(DiscoveredDevice device) {
    final proximityScore = device.proximityScore;
    final proximityColor = _getProximityColor(proximityScore);
    final proximityLabel = _getProximityLabel(proximityScore);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: proximityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getDeviceIcon(device.type),
                color: proximityColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.deviceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: proximityColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        proximityLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: proximityColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (device.signalStrength != null) ...[
                        const Icon(
                          Icons.signal_cellular_alt,
                          size: 14,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${device.signalStrength} dBm',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (device.personalityData != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.psychology,
                      size: 14,
                      color: AppColors.electricGreen,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.electricGreen,
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

  IconData _getDeviceIcon(DeviceType type) {
    switch (type) {
      case DeviceType.wifi:
        return Icons.wifi;
      case DeviceType.bluetooth:
        return Icons.bluetooth;
      case DeviceType.wifiDirect:
        return Icons.wifi_tethering;
      case DeviceType.multpeerConnectivity:
        return Icons.devices;
      case DeviceType.webrtc:
        return Icons.web;
    }
  }

  Color _getProximityColor(double score) {
    if (score >= 0.7) return AppColors.success;
    if (score >= 0.4) return AppColors.warning;
    return AppColors.error;
  }

  String _getProximityLabel(double score) {
    if (score >= 0.7) return 'Very Close';
    if (score >= 0.4) return 'Nearby';
    return 'Far';
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Device Discovery'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Device Discovery finds nearby avrai-enabled devices using:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Text('• WiFi Direct (Android)'),
              Text('• Multipeer Connectivity (iOS)'),
              Text('• Bluetooth Low Energy'),
              Text('• WebRTC (Web)'),
              SizedBox(height: 12),
              Text(
                'Privacy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('✓ Only anonymized personality data is shared'),
              Text('✓ No personal information exchanged'),
              Text('✓ You control discovery on/off'),
              Text('✓ Devices must both have discovery enabled'),
              SizedBox(height: 12),
              Text(
                'Note: Discovery uses device radios and may affect battery life.',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
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
}
