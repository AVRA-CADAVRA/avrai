import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/social_media_connection_service.dart';
import 'package:avrai/injection_container.dart' as di;

/// Social Media Connection Page for Onboarding
/// Allows users to optionally connect their social media accounts
/// This enhances AI personality learning and enables friend discovery
///
/// **Batch Connection:** During onboarding, users can connect all platforms at once
/// **Individual Connection:** After onboarding, users connect platforms one at a time
class SocialMediaConnectionPage extends StatefulWidget {
  final Map<String, bool> connectedPlatforms;
  final Function(Map<String, bool>) onConnectionsChanged;
  final bool isOnboarding; // If true, shows batch connection option

  const SocialMediaConnectionPage({
    super.key,
    required this.connectedPlatforms,
    required this.onConnectionsChanged,
    this.isOnboarding = true, // Default to onboarding mode
  });

  @override
  State<SocialMediaConnectionPage> createState() =>
      _SocialMediaConnectionPageState();
}

class _SocialMediaConnectionPageState extends State<SocialMediaConnectionPage> {
  late Map<String, bool> _connectedPlatforms;
  final Set<String> _selectedForBatch =
      {}; // Platforms selected for batch connection

  bool _isConnecting = false;
  bool _isBatchConnecting = false;
  String? _connectingPlatform;

  @override
  void initState() {
    super.initState();
    // Initialize from parent
    _connectedPlatforms = Map<String, bool>.from(widget.connectedPlatforms);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect Social Media (Optional)',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Connect your social accounts to enhance your AI personality and discover friends who use avrai. You can skip this step and connect later in settings.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 24),
          // Batch connection option (only during onboarding)
          if (widget.isOnboarding) ...[
            Card(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Quick Connect',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select multiple platforms and connect them all at once. This is only available during onboarding.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.grey600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _connectedPlatforms.keys.map((platform) {
                        final isSelected = _selectedForBatch.contains(platform);
                        final isConnected =
                            _connectedPlatforms[platform] == true;
                        return FilterChip(
                          label: Text(platform),
                          selected: isSelected,
                          onSelected: isConnected
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedForBatch.add(platform);
                                    } else {
                                      _selectedForBatch.remove(platform);
                                    }
                                  });
                                },
                          avatar: isSelected
                              ? const Icon(Icons.check, size: 18)
                              : _getPlatformIcon(platform),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isBatchConnecting || _selectedForBatch.isEmpty
                                ? null
                                : _connectBatch,
                        icon: _isBatchConnecting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.bolt),
                        label: Text(
                          _isBatchConnecting
                              ? 'Connecting...'
                              : 'Connect ${_selectedForBatch.length} Selected',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
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
                          ? 'Connected'
                          : 'Connect to enhance your AI personality',
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
          // Add custom account option
          OutlinedButton.icon(
            onPressed: _showAddCustomAccountDialog,
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Add Custom Account'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Privacy Note: We only use your social data to enhance your AI personality and help you discover friends. You can disconnect anytime in settings.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.grey600,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddCustomAccountDialog() async {
    final platformNameController = TextEditingController();
    final clientIdController = TextEditingController();
    final discoveryUrlController = TextEditingController();
    final profileEndpointController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Custom Account'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: platformNameController,
                decoration: const InputDecoration(
                  labelText: 'Platform Name',
                  hintText: 'e.g., Uber Eats, Lyft, Airbnb',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: clientIdController,
                decoration: const InputDecoration(
                  labelText: 'OAuth Client ID',
                  hintText: 'Your OAuth client ID',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: discoveryUrlController,
                decoration: const InputDecoration(
                  labelText: 'Discovery URL',
                  hintText:
                      'https://example.com/.well-known/openid_configuration',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: profileEndpointController,
                decoration: const InputDecoration(
                  labelText: 'Profile Endpoint (Optional)',
                  hintText: 'https://api.example.com/user/me',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (platformNameController.text.isNotEmpty &&
                  clientIdController.text.isNotEmpty &&
                  discoveryUrlController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'platform': platformNameController.text
                      .toLowerCase()
                      .replaceAll(' ', '_'),
                  'platform_display': platformNameController.text,
                  'client_id': clientIdController.text,
                  'discovery_url': discoveryUrlController.text,
                  'profile_endpoint': profileEndpointController.text.isNotEmpty
                      ? profileEndpointController.text
                      : null,
                });
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _connectCustomPlatform(result);
    }
  }

  Future<void> _connectCustomPlatform(Map<String, dynamic> config) async {
    setState(() {
      _isConnecting = true;
      _connectingPlatform = config['platform_display'] as String;
    });

    try {
      // Get current user
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;

      // Get agentId for privacy
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId(userId);

      // Prepare custom OAuth config
      final customOAuthConfig = {
        'client_id': config['client_id'],
        'discovery_url': config['discovery_url'],
        'profile_endpoint': config['profile_endpoint'],
        'scopes': ['openid', 'profile', 'email'], // Default scopes
      };

      // Call service to run OAuth flow
      final socialMediaService = di.sl<SocialMediaConnectionService>();
      await socialMediaService.connectPlatform(
        platform: config['platform'] as String,
        agentId: agentId,
        userId: userId,
        customOAuthConfig: customOAuthConfig,
      );

      if (!mounted) return;

      final platformDisplay = config['platform_display'] as String;
      setState(() {
        _connectedPlatforms[platformDisplay] = true;
        _isConnecting = false;
        _connectingPlatform = null;
      });

      // Report changes to parent
      widget.onConnectionsChanged(Map<String, bool>.from(_connectedPlatforms));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$platformDisplay connected successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isConnecting = false;
        _connectingPlatform = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
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
        color = Colors.purple;
        break;
      default:
        icon = Icons.link;
        color = AppTheme.primaryColor;
    }
    return Icon(icon, color: color, size: 32);
  }

  Future<void> _connectBatch() async {
    if (_selectedForBatch.isEmpty) return;

    setState(() {
      _isBatchConnecting = true;
    });

    try {
      // Get current user
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;

      // Get agentId for privacy
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId(userId);

      // Call service to batch connect
      final socialMediaService = di.sl<SocialMediaConnectionService>();
      final platforms = _selectedForBatch.map((p) => p.toLowerCase()).toList();
      final connections = await socialMediaService.connectPlatformsBatch(
        platforms: platforms,
        agentId: agentId,
        userId: userId,
      );

      if (mounted) {
        // Update UI with successful connections
        for (final connection in connections) {
          final platformName = connection.platform[0].toUpperCase() +
              connection.platform.substring(1);
          _connectedPlatforms[platformName] = true;
        }

        setState(() {
          _isBatchConnecting = false;
          _selectedForBatch.clear();
        });

        // Report changes to parent
        widget
            .onConnectionsChanged(Map<String, bool>.from(_connectedPlatforms));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Connected ${connections.length} platform(s) successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isBatchConnecting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect platforms: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _connectPlatform(String platform) async {
    setState(() {
      _isConnecting = true;
      _connectingPlatform = platform;
    });

    try {
      // Get current user
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;

      // Get agentId for privacy
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId(userId);

      // Call service to run OAuth flow and store tokens
      final socialMediaService = di.sl<SocialMediaConnectionService>();
      await socialMediaService.connectPlatform(
        platform: platform.toLowerCase(), // 'instagram', 'facebook', etc.
        agentId: agentId, // Use agentId for privacy
        userId: userId, // For service lookup
      );

      if (mounted) {
        setState(() {
          _connectedPlatforms[platform] = true;
          _isConnecting = false;
          _connectingPlatform = null;
        });

        // Report changes to parent with real connection status
        widget
            .onConnectionsChanged(Map<String, bool>.from(_connectedPlatforms));

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
          'Disconnecting $platform will stop using your social data to enhance your AI personality. You can reconnect anytime in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        // Get current user
        final authBloc = context.read<AuthBloc>();
        final authState = authBloc.state;
        if (authState is! Authenticated) {
          throw Exception('User not authenticated');
        }

        final userId = authState.user.id;

        // Get agentId for privacy
        final agentIdService = di.sl<AgentIdService>();
        final agentId = await agentIdService.getUserAgentId(userId);

        // Call service to disconnect and remove tokens
        final socialMediaService = di.sl<SocialMediaConnectionService>();
        await socialMediaService.disconnectPlatform(
          platform: platform.toLowerCase(),
          agentId: agentId,
        );

        if (!mounted) return;
        setState(() {
          _connectedPlatforms[platform] = false;
        });

        // Report changes to parent
        widget
            .onConnectionsChanged(Map<String, bool>.from(_connectedPlatforms));
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$platform disconnected'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to disconnect $platform: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
