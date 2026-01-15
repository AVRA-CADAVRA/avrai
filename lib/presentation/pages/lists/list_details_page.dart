import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/services/social_media_sharing_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/models/list.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/widgets/lists/spot_picker_dialog.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/presentation/widgets/common/source_indicator_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/ai/event_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ListDetailsPage extends StatefulWidget {
  final SpotList list;

  const ListDetailsPage({super.key, required this.list});

  @override
  State<ListDetailsPage> createState() => _ListDetailsPageState();
}

class _ListDetailsPageState extends State<ListDetailsPage> {
  late EventLogger _eventLogger;
  DateTime? _viewStartTime;
  final ScrollController _scrollController = ScrollController();
  double _maxScrollDepth = 0.0;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeEventLogger();
    _viewStartTime = DateTime.now();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _initializeEventLogger() async {
    try {
      _eventLogger = di.sl<EventLogger>();
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await _eventLogger.initialize(userId: currentUser.id);
        _eventLogger.updateScreen('list_details');

        // Log list view started
        await _eventLogger.logListViewStarted(
          listId: widget.list.id,
          category: widget.list.category,
          source: 'navigation',
        );
      }
      _isInitialized = true;
    } catch (e) {
      // Event logging is non-critical, continue without it
      _isInitialized = false;
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final currentDepth = _scrollController.position.pixels /
          (_scrollController.position.maxScrollExtent > 0
              ? _scrollController.position.maxScrollExtent
              : 1.0);
      if (currentDepth > _maxScrollDepth) {
        _maxScrollDepth = currentDepth;
        // Log scroll depth periodically (every 25% increase)
        if (_isInitialized && (_maxScrollDepth * 100).round() % 25 == 0) {
          _eventLogger.logScrollDepth(
            listId: widget.list.id,
            depthPercentage: _maxScrollDepth * 100,
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    // Log list view duration
    if (_isInitialized && _viewStartTime != null) {
      final duration = DateTime.now().difference(_viewStartTime!);
      _eventLogger.logListViewDuration(
        listId: widget.list.id,
        durationMs: duration.inMilliseconds,
      );
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.title),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              _handleMenuAction(context, value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('Edit List'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share),
                    SizedBox(width: 8),
                    Text('Share List'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete,
                        color: Theme.of(context).colorScheme.error),
                    const SizedBox(width: 8),
                    Text('Delete List',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // List Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.list.category ?? 'Uncategorized',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      widget.list.isPublic ? Icons.public : Icons.lock,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  widget.list.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.list.spotIds.length} spots',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.favorite_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.list.respectCount} respects',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Spots List
          Expanded(
            child: BlocBuilder<SpotsBloc, SpotsState>(
              builder: (context, state) {
                if (state is SpotsLoaded) {
                  final spotsInList = state.spots
                      .where((spot) => widget.list.spotIds.contains(spot.id))
                      .toList();

                  if (spotsInList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No spots in this list',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add some spots to get started',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              _showAddSpotsDialog(context);
                            },
                            icon: const Icon(Icons.add_location),
                            label: const Text('Add Spots'),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: spotsInList.length,
                    itemBuilder: (context, index) {
                      final spot = spotsInList[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.location_on,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          title: Text(
                            spot.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                spot.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              SourceIndicatorWidget(
                                indicator: spot.getSourceIndicator(),
                                compact: true,
                                showWarning: false,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      spot.category,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.star_outline,
                                    size: 16,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${spot.rating}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove_circle_outline,
                                    color: Theme.of(context).colorScheme.error),
                                onPressed: () {
                                  _showRemoveSpotConfirmation(context, spot);
                                },
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ],
                          ),
                          onTap: () {
                            // Log spot tap (navigating to spot details)
                            if (_isInitialized) {
                              _eventLogger.logEvent(
                                eventType: 'spot_tap',
                                parameters: {
                                  'spot_id': spot.id,
                                  'list_id': widget.list.id,
                                  'source': 'list_details',
                                },
                              );
                            }
                            context.go('/spot/${spot.id}');
                          },
                        ),
                      );
                    },
                  );
                }

                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddSpotsDialog(context);
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.add_location),
      ),
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _navigateToEdit(context);
        break;
      case 'share':
        _showShareDialog(context);
        break;
      case 'delete':
        _showDeleteConfirmation(context);
        break;
    }
  }

  SpotList get list => widget.list;

  void _navigateToEdit(BuildContext context) {
    context.go('/list/${widget.list.id}/edit');
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share List'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Social Media Sharing Section
              FutureBuilder<List<String>>(
                future: _getAvailableSocialPlatforms(context),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Share to Social Media',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...snapshot.data!.map((platform) => ListTile(
                              leading: _getPlatformIcon(platform),
                              title: Text(
                                  'Share to ${platform[0].toUpperCase()}${platform.substring(1)}'),
                              onTap: () {
                                Navigator.pop(context);
                                _shareToSocialMedia(context, platform);
                              },
                            )),
                        const Divider(),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              // Standard Sharing Options
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share via...'),
                subtitle: const Text('Share to other apps'),
                onTap: () {
                  Navigator.pop(context);
                  _shareToOtherApps();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Copy Link'),
                subtitle: const Text('Copy shareable link'),
                onTap: () {
                  Navigator.pop(context);
                  _copyListLink(context);
                },
              ),
              if (widget.list.isPublic) ...[
                ListTile(
                  leading: const Icon(Icons.public),
                  title: const Text('Public List'),
                  subtitle: const Text('Anyone can view this list'),
                  onTap: () {
                    Navigator.pop(context);
                    _sharePublicList();
                  },
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _getAvailableSocialPlatforms(
      BuildContext context) async {
    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        return [];
      }

      final userId = authState.user.id;
      final sharingService = di.sl<SocialMediaSharingService>();
      return await sharingService.getAvailablePlatforms(userId);
    } catch (e) {
      return [];
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
      case 'tumblr':
        icon = Icons.auto_stories;
        color = Colors.blue.shade900;
        break;
      case 'pinterest':
        icon = Icons.push_pin;
        color = Colors.red.shade700;
        break;
      default:
        icon = Icons.link;
        color = AppTheme.primaryColor;
    }
    return Icon(icon, color: color);
  }

  Future<void> _shareToSocialMedia(
      BuildContext context, String platform) async {
    try {
      final authBloc = context.read<AuthBloc>();
      final authState = authBloc.state;
      if (authState is! Authenticated) {
        throw Exception('User not authenticated');
      }

      final userId = authState.user.id;
      final agentIdService = di.sl<AgentIdService>();
      final agentId = await agentIdService.getUserAgentId(userId);
      final sharingService = di.sl<SocialMediaSharingService>();

      // Show loading
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sharing to $platform...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Share list
      final results = await sharingService.shareList(
        agentId: agentId,
        userId: userId,
        listId: widget.list.id,
        listName: widget.list.title,
        listDescription: widget.list.description,
        spotCount: widget.list.spotIds.length,
        platforms: [platform],
      );

      if (context.mounted) {
        if (results[platform] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Shared to $platform successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to share to $platform'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _shareToOtherApps() {
    final shareText = '''📝 ${widget.list.title}

${widget.list.description.isNotEmpty ? '${widget.list.description}\n' : ''}Category: ${widget.list.category ?? 'Uncategorized'}
Spots: ${widget.list.spotIds.length}
Respects: ${widget.list.respectCount}

${widget.list.isPublic ? 'This is a public list on avrai' : 'Shared from avrai'}

avrai - know you belong.''';

    SharePlus.instance.share(ShareParams(
      text: shareText,
      subject: 'Check out this list: ${widget.list.title}',
    ));
  }

  void _copyListLink(BuildContext context) {
    // Generate a shareable link (this would normally be a deep link to the app)
    final listLink = 'https://avrai.app/list/${widget.list.id}';

    Clipboard.setData(ClipboardData(text: listLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('List link copied to clipboard'),
      ),
    );
  }

  void _sharePublicList() {
    final publicText = '''🌟 Public List: ${widget.list.title}

${widget.list.description}

This curated list has ${widget.list.respectCount} respects from the community and features ${widget.list.spotIds.length} amazing spots.

View on avrai: https://avrai.app/list/${widget.list.id}

avrai - know you belong.''';

    SharePlus.instance.share(ShareParams(text: publicText));
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
            'Are you sure you want to delete "${widget.list.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ListsBloc>().add(DeleteList(widget.list.id));
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${widget.list.title} deleted')),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddSpotsDialog(BuildContext context) async {
    final selectedSpotIds = await showDialog<List<String>>(
      context: context,
      builder: (context) => SpotPickerDialog(
        list: list,
        excludedSpotIds: widget.list.spotIds,
      ),
    );

    if (selectedSpotIds != null && selectedSpotIds.isNotEmpty) {
      // Add selected spots to the list
      final updatedSpotIds = List<String>.from(widget.list.spotIds);
      updatedSpotIds.addAll(selectedSpotIds);

      final updatedList = widget.list.copyWith(
        spotIds: updatedSpotIds,
        updatedAt: DateTime.now(),
      );

      if (!mounted || !context.mounted) return;
      context.read<ListsBloc>().add(UpdateList(updatedList));
      if (!mounted || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${selectedSpotIds.length} spot${selectedSpotIds.length > 1 ? 's' : ''} to ${widget.list.title}',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showRemoveSpotConfirmation(BuildContext context, Spot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Spot'),
        content: Text(
            'Are you sure you want to remove "${spot.name}" from this list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Actually remove the spot from the list
              final updatedSpotIds = List<String>.from(widget.list.spotIds);
              updatedSpotIds.remove(spot.id);

              final updatedList = widget.list.copyWith(
                spotIds: updatedSpotIds,
                updatedAt: DateTime.now(),
              );

              context.read<ListsBloc>().add(UpdateList(updatedList));

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${spot.name} removed from list'),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
