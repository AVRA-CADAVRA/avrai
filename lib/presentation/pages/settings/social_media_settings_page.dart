import 'package:flutter/material.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:go_router/go_router.dart';

/// Social Media Settings Page
/// Allows users to manage their social media connections
/// Users can connect, disconnect, and view connection status
class SocialMediaSettingsPage extends StatefulWidget {
  const SocialMediaSettingsPage({super.key});

  @override
  State<SocialMediaSettingsPage> createState() =>
      _SocialMediaSettingsPageState();
}

class _SocialMediaSettingsPageState extends State<SocialMediaSettingsPage> {
  // TODO: Replace with actual service call when Phase 12 backend is ready
  final Map<String, bool> _connectedPlatforms = {
    'Instagram': false,
    'Facebook': false,
    'Twitter': false,
    'Google': false,
    'Reddit': false,
    'TikTok': false,
    'Tumblr': false,
    'YouTube': false,
    'Pinterest': false,
    'Are.na': false,
    'LinkedIn': false,
  };

  bool _isConnecting = false;
  String? _connectingPlatform;

  @override
  void initState() {
    super.initState();
    _loadConnections();
  }

  Future<void> _loadConnections() async {
    // TODO: Load actual connections from SocialMediaConnectionService
    // For now, this is a placeholder
    setState(() {
      // In real implementation, this would fetch from service
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Media Connections'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage Social Media Connections',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your social accounts to enhance your AI personality and discover friends who use avrai.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 16),
            // Friend Discovery Link
            Card(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: InkWell(
                onTap: () => context.go('/friends/discover'),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Find Friends on avrai',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Discover friends who use avrai from your social connections',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: AppColors.grey700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: _connectedPlatforms.entries.map((entry) {
                  final platform = entry.key;
                  final isConnected = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: _getPlatformIcon(platform),
                      title: Text(platform),
                      subtitle: Text(
                        isConnected
                            ? 'Connected • Enhancing your AI personality'
                            : 'Not connected • Tap to connect',
                        style: TextStyle(
                          color: isConnected ? Colors.green : AppColors.grey600,
                        ),
                      ),
                      trailing: _isConnecting && _connectingPlatform == platform
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Switch(
                              value: isConnected,
                              onChanged: _isConnecting
                                  ? null
                                  : (value) {
                                      if (value) {
                                        _connectPlatform(platform);
                                      } else {
                                        _disconnectPlatform(platform);
                                      }
                                    },
                            ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'Privacy & Data Usage',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• We only use your social data to enhance your AI personality\n'
                    '• Your data is stored locally and encrypted\n'
                    '• You can disconnect anytime\n'
                    '• We never share your social data with third parties',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
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

  Widget _getPlatformIcon(String platform) {
    IconData icon;
    Color color;
    switch (platform) {
      case 'Instagram':
        icon = Icons.camera_alt;
        color = Colors.purple;
        break;
      case 'Facebook':
        icon = Icons.facebook;
        color = Colors.blue;
        break;
      case 'Twitter':
        icon = Icons.chat_bubble_outline;
        color = Colors.lightBlue;
        break;
      case 'TikTok':
        icon = Icons.music_note;
        color = Colors.black;
        break;
      case 'LinkedIn':
        icon = Icons.business;
        color = Colors.blue.shade700;
        break;
      case 'Google':
        icon = Icons.search;
        color = Colors.blue;
        break;
      case 'Reddit':
        icon = Icons.forum;
        color = Colors.orange;
        break;
      case 'Tumblr':
        icon = Icons.auto_stories;
        color = Colors.blue.shade900;
        break;
      case 'YouTube':
        icon = Icons.play_circle;
        color = Colors.red;
        break;
      case 'Pinterest':
        icon = Icons.push_pin;
        color = Colors.red.shade700;
        break;
      case 'Are.na':
        icon = Icons.grid_view;
        color = Colors.black;
        break;
      default:
        icon = Icons.link;
        color = AppTheme.primaryColor;
    }
    return Icon(icon, color: color, size: 32);
  }

  Future<void> _connectPlatform(String platform) async {
    setState(() {
      _isConnecting = true;
      _connectingPlatform = platform;
    });

    try {
      // TODO: Implement actual OAuth connection when Phase 12 backend is ready
      // This will use SocialMediaConnectionService.connectPlatform()
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        setState(() {
          _connectedPlatforms[platform] = true;
          _isConnecting = false;
          _connectingPlatform = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$platform connected successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _connectingPlatform = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect $platform: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _disconnectPlatform(String platform) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Disconnect $platform?'),
        content: Text(
          'Disconnecting $platform will stop using your social data to enhance your AI personality. You can reconnect anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // TODO: Call SocialMediaConnectionService.disconnectPlatform()
      setState(() {
        _connectedPlatforms[platform] = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform disconnected'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}
