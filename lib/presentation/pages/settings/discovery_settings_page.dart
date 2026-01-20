/// Discovery Settings Page
///
/// Part of Feature Matrix Phase 1: Critical UI/UX
/// Section 1.2: Device Discovery UI
///
/// Allows users to control device discovery settings and privacy preferences.
///
/// Features:
/// - Enable/disable discovery toggle
/// - Discovery method preferences (WiFi, Bluetooth, etc.)
/// - Privacy settings (personality data sharing)
/// - Auto-discovery options
/// - Discovery range settings
/// - Privacy explanations
///
/// Uses AppColors and AppTheme for consistent styling per design token requirements.
library;

import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai2ai/connection_orchestrator.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:get_it/get_it.dart';

/// Settings page for device discovery configuration
class DiscoverySettingsPage extends StatefulWidget {
  const DiscoverySettingsPage({super.key});

  @override
  State<DiscoverySettingsPage> createState() => _DiscoverySettingsPageState();
}

class _DiscoverySettingsPageState extends State<DiscoverySettingsPage> {
  final _storageService = StorageService.instance;
  static const String _logName = 'DiscoverySettingsPage';

  // Discovery settings
  bool _discoveryEnabled = false;
  bool _autoDiscovery = false;
  bool _sharePersonalityData = true;
  bool _discoverWiFi = true;
  bool _discoverBluetooth = true;
  bool _discoverMultipeer = true;
  bool _eventModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _discoveryEnabled = _storageService.getBool('discovery_enabled') ?? false;
      _autoDiscovery = _storageService.getBool('auto_discovery') ?? false;
      _sharePersonalityData =
          _storageService.getBool('share_personality_data') ?? true;
      _discoverWiFi = _storageService.getBool('discover_wifi') ?? true;
      _discoverBluetooth =
          _storageService.getBool('discover_bluetooth') ?? true;
      _discoverMultipeer =
          _storageService.getBool('discover_multipeer') ?? true;
      _eventModeEnabled =
          _storageService.getBool('event_mode_enabled') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    await _storageService.setBool(key, value);
  }

  Future<void> _applyDiscoveryRuntime(bool enabled) async {
    try {
      final orchestrator = GetIt.instance<VibeConnectionOrchestrator>();
      if (!enabled) {
        await orchestrator.shutdown();
        return;
      }

      final authState = context.read<AuthBloc>().state;
      if (authState is! Authenticated) return;

      final userId = authState.user.id;
      final personalityLearning = GetIt.instance<PersonalityLearning>();
      final profile = await personalityLearning.getCurrentPersonality(userId) ??
          await personalityLearning.initializePersonality(userId);
      await orchestrator.initializeOrchestration(userId, profile);
    } catch (e, st) {
      developer.log(
        'Failed to apply discovery runtime',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),
      body: ListView(
        children: [
          _buildHeaderSection(),
          _buildMainToggle(),
          if (_discoveryEnabled) ...[
            _buildEventModeToggle(),
            _buildDiscoveryMethodsSection(),
            _buildPrivacySection(),
            _buildAdvancedSection(),
          ],
          _buildInfoSection(),
        ],
      ),
    );
  }

  Widget _buildEventModeToggle() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: const Text(
          'Event Mode (Broadcast-First)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _eventModeEnabled
              ? 'Uses connectionless room sensing; deep sync only in short check-in windows'
              : 'Normal discovery behavior',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        value: _eventModeEnabled,
        onChanged: (value) async {
          setState(() {
            _eventModeEnabled = value;
          });
          await _saveSetting('event_mode_enabled', value);
        },
        activeThumbColor: AppColors.electricGreen,
        secondary: Icon(
          _eventModeEnabled
              ? Icons.local_activity
              : Icons.local_activity_outlined,
          color:
              _eventModeEnabled ? AppColors.electricGreen : AppColors.grey300,
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricGreen.withValues(alpha: 0.1),
            AppColors.electricGreen.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.radar,
              size: 32,
              color: AppColors.electricGreen,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device Discovery',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Find nearby avrai-enabled devices',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainToggle() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        title: const Text(
          'Enable Discovery',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _discoveryEnabled
              ? 'Actively discovering nearby devices'
              : 'Discovery is turned off',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        value: _discoveryEnabled,
        onChanged: (value) async {
          setState(() {
            _discoveryEnabled = value;
          });
          await _saveSetting('discovery_enabled', value);
          await _applyDiscoveryRuntime(value);
        },
        activeThumbColor: AppColors.electricGreen,
        secondary: Icon(
          _discoveryEnabled ? Icons.radar : Icons.radar_outlined,
          color:
              _discoveryEnabled ? AppColors.electricGreen : AppColors.grey300,
        ),
      ),
    );
  }

  Widget _buildDiscoveryMethodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 12),
          child: Text(
            'Discovery Methods',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('WiFi Direct'),
                subtitle: const Text('Discover devices over WiFi'),
                value: _discoverWiFi,
                onChanged: (value) async {
                  setState(() {
                    _discoverWiFi = value;
                  });
                  await _saveSetting('discover_wifi', value);
                },
                activeThumbColor: AppColors.electricGreen,
                secondary: const Icon(Icons.wifi, color: AppColors.primary),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Bluetooth'),
                subtitle: const Text('Discover devices via Bluetooth'),
                value: _discoverBluetooth,
                onChanged: (value) async {
                  setState(() {
                    _discoverBluetooth = value;
                  });
                  await _saveSetting('discover_bluetooth', value);
                },
                activeThumbColor: AppColors.electricGreen,
                secondary:
                    const Icon(Icons.bluetooth, color: AppColors.primary),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Multipeer'),
                subtitle: const Text('iOS Multipeer Connectivity'),
                value: _discoverMultipeer,
                onChanged: (value) async {
                  setState(() {
                    _discoverMultipeer = value;
                  });
                  await _saveSetting('discover_multipeer', value);
                },
                activeThumbColor: AppColors.electricGreen,
                secondary: const Icon(Icons.devices, color: AppColors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 12),
          child: Row(
            children: [
              Text(
                'Privacy Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: 8),
              Icon(
                Icons.lock_outline,
                size: 20,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SwitchListTile(
                title: const Text('Share Personality Data'),
                subtitle: const Text(
                  'Allow AI personality data to be discoverable (anonymized)',
                ),
                value: _sharePersonalityData,
                onChanged: (value) async {
                  setState(() {
                    _sharePersonalityData = value;
                  });
                  await _saveSetting('share_personality_data', value);
                },
                activeThumbColor: AppColors.electricGreen,
                secondary: const Icon(
                  Icons.psychology,
                  color: AppColors.primary,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                ),
                title: const Text('Privacy Information'),
                subtitle: const Text('Learn about data sharing and privacy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showPrivacyInfoDialog,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(32, 24, 32, 12),
          child: Text(
            'Advanced',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile(
            title: const Text('Auto-Discovery'),
            subtitle: const Text(
              'Automatically start discovery when app opens',
            ),
            value: _autoDiscovery,
            onChanged: (value) async {
              setState(() {
                _autoDiscovery = value;
              });
              await _saveSetting('auto_discovery', value);
            },
            activeThumbColor: AppColors.electricGreen,
            secondary: const Icon(
              Icons.autorenew,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 20,
                color: AppColors.warning,
              ),
              SizedBox(width: 8),
              Text(
                'About Discovery',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Discovery uses device radios (WiFi/Bluetooth) and may affect battery life\n'
            '• Only avrai-enabled devices can be discovered\n'
            '• All data shared is anonymized and encrypted\n'
            '• You can stop discovery at any time\n'
            '• Discovery requires location permissions on some platforms',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacyInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 12),
            Text('Privacy & Security'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'How Discovery Protects Your Privacy:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                Icons.shield_outlined,
                'Anonymization',
                'No personal information (name, email, phone) is ever shared during discovery.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                Icons.lock,
                'Encryption',
                'All discovery data is encrypted using end-to-end encryption.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                Icons.psychology,
                'AI Personality Only',
                'Only anonymized AI personality patterns are shared - never your actual conversations or data.',
              ),
              const SizedBox(height: 12),
              _buildPrivacyPoint(
                Icons.verified_user,
                'You Control Discovery',
                'Discovery can be turned on/off anytime. When off, your device is invisible to others.',
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
                      Icons.check_circle,
                      color: AppColors.electricGreen,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All discovery follows ai2ai privacy principles from OUR_GUTS.md',
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

  Widget _buildPrivacyPoint(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
