import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import 'package:spots/presentation/pages/spots/spot_details_page.dart';
import 'package:spots/presentation/pages/lists/edit_list_page.dart';
import 'package:spots/presentation/widgets/lists/spot_picker_dialog.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:spots/core/theme/app_theme.dart';

class ListDetailsPage extends StatelessWidget {
  final SpotList list;

  const ListDetailsPage({super.key, required this.list});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(list.title),
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
                    Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                    SizedBox(width: 8),
                    Text('Delete List', style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
                        list.category ?? 'Uncategorized',
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
                      list.isPublic ? Icons.public : Icons.lock,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  list.description,
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
                      '${list.spotIds.length} spots',
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
                      '${list.respectCount} respects',
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
                      .where((spot) => list.spotIds.contains(spot.id))
                      .toList();

                  if (spotsInList.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_off_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
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
                                    '${spot.rating ?? 0}',
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
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    SpotDetailsPage(spot: spot),
                              ),
                            );
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

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditListPage(list: list),
      ),
    );

    // If list was updated, the result will contain the updated list
    if (result != null && result is SpotList) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('List updated successfully'),
        ),
      );
    }
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share List'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
            if (list.isPublic) ...[
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _shareToOtherApps() {
    final shareText = '''📝 ${list.title}

${list.description.isNotEmpty ? '${list.description}\n' : ''}Category: ${list.category ?? 'Uncategorized'}
Spots: ${list.spotIds.length}
Respects: ${list.respectCount}

${list.isPublic ? 'This is a public list on SPOTS' : 'Shared from SPOTS'}

SPOTS - know you belong.''';

    Share.share(shareText, subject: 'Check out this list: ${list.title}');
  }

  void _copyListLink(BuildContext context) {
    // Generate a shareable link (this would normally be a deep link to the app)
    final listLink = 'https://spots.app/list/${list.id}';
    
    Clipboard.setData(ClipboardData(text: listLink));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('List link copied to clipboard'),
        ),
      );
  }

  void _sharePublicList() {
    final publicText = '''🌟 Public List: ${list.title}

${list.description}

This curated list has ${list.respectCount} respects from the community and features ${list.spotIds.length} amazing spots.

View on SPOTS: https://spots.app/list/${list.id}

SPOTS - know you belong.''';

    Share.share(publicText);
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete List'),
        content: Text(
            'Are you sure you want to delete "${list.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<ListsBloc>().add(DeleteList(list.id));
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${list.title} deleted')),
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
        excludedSpotIds: list.spotIds,
      ),
    );

    if (selectedSpotIds != null && selectedSpotIds.isNotEmpty) {
      // Add selected spots to the list
      final updatedSpotIds = List<String>.from(list.spotIds);
      updatedSpotIds.addAll(selectedSpotIds);

      final updatedList = list.copyWith(
        spotIds: updatedSpotIds,
        updatedAt: DateTime.now(),
      );

      context.read<ListsBloc>().add(UpdateList(updatedList));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${selectedSpotIds.length} spot${selectedSpotIds.length > 1 ? 's' : ''} to ${list.title}',
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
              final updatedSpotIds = List<String>.from(list.spotIds);
              updatedSpotIds.remove(spot.id);
              
              final updatedList = list.copyWith(
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
