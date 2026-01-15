/// Discovery Settings Page
///
/// Part of Feature Matrix Phase 1: Critical UI/UX Features
///
/// Allows users to configure device discovery settings:
/// - Scan interval (how often to scan for devices)
/// - Device timeout (how long before removing stale devices)
///
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_network/network/device_discovery.dart';
import 'package:avrai/core/services/storage_service.dart';

/// Page for configuring device discovery settings
class DiscoverySettingsPage extends StatefulWidget {
  const DiscoverySettingsPage({super.key});

  @override
  State<DiscoverySettingsPage> createState() => _DiscoverySettingsPageState();
}

class _DiscoverySettingsPageState extends State<DiscoverySettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _scanIntervalController = TextEditingController();
  final _deviceTimeoutController = TextEditingController();
  final _storageService = StorageService.instance;

  static const String _scanIntervalKey = 'discovery_scan_interval';
  static const String _deviceTimeoutKey = 'discovery_device_timeout';

  // Default values
  static const int defaultScanInterval = 5; // seconds
  static const int defaultDeviceTimeout = 2; // minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _scanIntervalController.dispose();
    _deviceTimeoutController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final scanInterval =
        _storageService.getInt(_scanIntervalKey) ?? defaultScanInterval;
    final deviceTimeout =
        _storageService.getInt(_deviceTimeoutKey) ?? defaultDeviceTimeout;

    _scanIntervalController.text = scanInterval.toString();
    _deviceTimeoutController.text = deviceTimeout.toString();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      final scanInterval = int.parse(_scanIntervalController.text);
      final deviceTimeout = int.parse(_deviceTimeoutController.text);

      // Save to storage
      await _storageService.setInt(_scanIntervalKey, scanInterval);
      await _storageService.setInt(_deviceTimeoutKey, deviceTimeout);

      // Apply to discovery service if it's running
      try {
        final discoveryService = GetIt.instance<DeviceDiscoveryService>();
        // Stop and restart with new settings
        discoveryService.stopDiscovery();
        await discoveryService.startDiscovery(
          scanInterval: Duration(seconds: scanInterval),
          deviceTimeout: Duration(minutes: deviceTimeout),
        );
      } catch (e) {
        // Service not available or not running, that's okay
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppColors.electricGreen,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String? _validateScanInterval(String? value) {
    if (value == null || value.isEmpty) {
      return 'Scan interval is required';
    }
    final interval = int.tryParse(value);
    if (interval == null) {
      return 'Must be a valid number';
    }
    if (interval < 1) {
      return 'Must be at least 1 second';
    }
    if (interval > 300) {
      return 'Must be at most 300 seconds';
    }
    return null;
  }

  String? _validateDeviceTimeout(String? value) {
    if (value == null || value.isEmpty) {
      return 'Device timeout is required';
    }
    final timeout = int.tryParse(value);
    if (timeout == null) {
      return 'Must be a valid number';
    }
    if (timeout < 1) {
      return 'Must be at least 1 minute';
    }
    if (timeout > 60) {
      return 'Must be at most 60 minutes';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Settings'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Device Discovery Configuration',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Configure how often avrai scans for nearby devices and how long to keep discovered devices in the list.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Scan Interval',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'How often to scan for nearby devices (in seconds)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _scanIntervalController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Seconds',
                          hintText: '5',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColors.grey100,
                        ),
                        validator: _validateScanInterval,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Recommended: 5-10 seconds for active discovery',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Timeout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'How long to keep discovered devices before removing them (in minutes)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _deviceTimeoutController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Minutes',
                          hintText: '2',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: AppColors.grey100,
                        ),
                        validator: _validateDeviceTimeout,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Recommended: 2-5 minutes to balance freshness and stability',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textHint,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.electricGreen,
                    foregroundColor: AppColors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
