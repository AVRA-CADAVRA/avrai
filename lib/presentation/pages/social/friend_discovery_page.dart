import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/services/social_media_discovery_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:go_router/go_router.dart';

/// Friend Discovery Page
///
/// Shows friends who use SPOTS and allows users to connect with them.
/// Privacy-preserving: Uses hashed friend IDs for matching.
class FriendDiscoveryPage extends StatefulWidget {
  const FriendDiscoveryPage({super.key});

  @override
  State<FriendDiscoveryPage> createState() => _FriendDiscoveryPageState();
}

class _FriendDiscoveryPageState extends State<FriendDiscoveryPage> {
  final SocialMediaDiscoveryService _discoveryService =
      di.sl<SocialMediaDiscoveryService>();
  final AgentIdService _agentIdService = di.sl<AgentIdService>();

  List<FriendSuggestion> _friendSuggestions = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadCachedSuggestions();
  }

  Future<void> _loadCachedSuggestions() async {
    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) return;

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);
      final cached =
          await _discoveryService.getCachedFriendSuggestions(agentId);

      if (mounted) {
        setState(() {
          _friendSuggestions = cached;
        });
      }
    } catch (e) {
      // Ignore errors when loading cached suggestions
    }
  }

  Future<void> _findFriends() async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);

      final suggestions = await _discoveryService.findFriendsWhoUseSpots(
        agentId: agentId,
        userId: userId,
      );

      if (mounted) {
        setState(() {
          _friendSuggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding friends: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _connectWithFriend(FriendSuggestion friend) async {
    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentId = await _agentIdService.getUserAgentId(userId);

      final success = await _discoveryService.sendFriendConnectionRequest(
        agentId: agentId,
        friendAgentId: friend.agentId,
        userId: userId,
      );

      if (mounted) {
        if (success) {
          // Update friend status
          setState(() {
            final index = _friendSuggestions.indexOf(friend);
            if (index != -1) {
              _friendSuggestions[index] = friend.copyWith(
                status: FriendConnectionStatus.requestSent,
              );
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Connection request sent!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send connection request'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error connecting: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Widget _getPlatformIcon(String platform) {
    IconData icon;
    Color color;
    switch (platform.toLowerCase()) {
      case 'instagram':
        icon = Icons.camera_alt;
        color = Colors.purple;
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = Colors.blue;
        break;
      case 'twitter':
        icon = Icons.chat_bubble_outline;
        color = Colors.lightBlue;
        break;
      case 'reddit':
        icon = Icons.forum;
        color = Colors.orange;
        break;
      default:
        icon = Icons.person;
        color = AppTheme.primaryColor;
    }
    return Icon(icon, color: color);
  }

  String _getStatusText(FriendConnectionStatus status) {
    switch (status) {
      case FriendConnectionStatus.notConnected:
        return 'Not connected';
      case FriendConnectionStatus.requestSent:
        return 'Request sent';
      case FriendConnectionStatus.requestReceived:
        return 'Request received';
      case FriendConnectionStatus.connected:
        return 'Connected';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Friends'),
        actions: [
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              context.go('/group/formation');
            },
            tooltip: 'Start Group Search',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _findFriends,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.people, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Find Friends on avrai',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connect your social media accounts to find friends who use avrai. We use privacy-preserving matching (hashed IDs) to protect your privacy.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.grey600,
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _findFriends,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                          _isLoading ? 'Finding friends...' : 'Find Friends'),
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

          // Results
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _friendSuggestions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasSearched
                                  ? Icons.people_outline
                                  : Icons.search,
                              size: 64,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _hasSearched
                                  ? 'No friends found'
                                  : 'Tap "Find Friends" to discover friends who use avrai',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: AppColors.grey600,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _friendSuggestions.length,
                        itemBuilder: (context, index) {
                          final friend = _friendSuggestions[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor
                                    .withValues(alpha: 0.1),
                                child: friend.profileImageUrl != null
                                    ? ClipOval(
                                        child: Image.network(
                                          friend.profileImageUrl!,
                                          width: 40,
                                          height: 40,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return _getPlatformIcon(
                                                friend.platform);
                                          },
                                        ),
                                      )
                                    : _getPlatformIcon(friend.platform),
                              ),
                              title: Text(
                                friend.displayName ??
                                    friend.username ??
                                    'Friend',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (friend.username != null)
                                    Text('@${friend.username}'),
                                  Row(
                                    children: [
                                      _getPlatformIcon(friend.platform),
                                      const SizedBox(width: 4),
                                      Text(
                                        friend.platform[0].toUpperCase() +
                                            friend.platform.substring(1),
                                        style: const TextStyle(
                                          color: AppColors.grey600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (friend.mutualFriendsCount !=
                                          null) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${friend.mutualFriendsCount} mutual',
                                          style: const TextStyle(
                                            color: AppColors.grey600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    _getStatusText(friend.status),
                                    style: TextStyle(
                                      color: friend.status ==
                                              FriendConnectionStatus.connected
                                          ? Colors.green
                                          : friend.status ==
                                                  FriendConnectionStatus
                                                      .requestSent
                                              ? Colors.orange
                                              : AppColors.grey600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: friend.status ==
                                      FriendConnectionStatus.notConnected
                                  ? TextButton(
                                      onPressed: () =>
                                          _connectWithFriend(friend),
                                      child: const Text('Connect'),
                                    )
                                  : friend.status ==
                                          FriendConnectionStatus.requestReceived
                                      ? TextButton(
                                          onPressed: () {
                                            // TODO: Implement accept request
                                          },
                                          child: const Text('Accept'),
                                        )
                                      : null,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// Extension to add copyWith method to FriendSuggestion
extension FriendSuggestionExtension on FriendSuggestion {
  FriendSuggestion copyWith({
    String? agentId,
    String? platform,
    String? username,
    String? displayName,
    String? profileImageUrl,
    int? mutualFriendsCount,
    FriendConnectionStatus? status,
  }) {
    return FriendSuggestion(
      agentId: agentId ?? this.agentId,
      platform: platform ?? this.platform,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
      status: status ?? this.status,
    );
  }
}
