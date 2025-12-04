import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/category_colors.dart';
import 'package:spots/presentation/blocs/lists/lists_bloc.dart';
import 'package:spots/presentation/pages/spots/edit_spot_page.dart';
import 'package:spots/presentation/widgets/validation/community_validation_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

class SpotDetailsPage extends StatelessWidget {
  final Spot spot;

  const SpotDetailsPage({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(spot.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              _navigateToEdit(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _showShareDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Spot Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                            color: _getCategoryColor(spot.category),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            spot.category,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (spot.rating > 0)
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.grey600, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                spot.rating.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      spot.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (spot.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                           Text(
                        spot.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                               color: AppColors.grey600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Location Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on,
                            color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (spot.address != null) ...[
                      Text(
                        spot.address!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Latitude: ${spot.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      'Longitude: ${spot.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _openInMaps(context, spot);
                      },
                      icon: const Icon(Icons.directions),
                      label: const Text('Get Directions'),
                      // Use global ElevatedButtonTheme (light grey with black text)
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Created', _formatDate(spot.createdAt)),
                    _buildDetailRow('Updated', _formatDate(spot.updatedAt)),
                    if (spot.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tags: ${spot.tags.join(', ')}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showAddToListDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add to List'),
                    // Use global ElevatedButtonTheme
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showShareDialog(context);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Community Validation (Phase 3: For external data spots)
                CommunityValidationWidget(
              spot: spot,
              onValidationComplete: () {
                // Optionally refresh spot data or show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Thank you for helping validate community data!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditSpotPage(spot: spot),
      ),
    );

    // If spot was updated, the result will contain the updated spot
    if (result != null && result is Spot) {
      // The spot details will be automatically updated via BLoC
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Spot updated successfully'),
        backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Spot'),
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
                _copySpotLink(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Share Location'),
              subtitle: const Text('Share coordinates'),
              onTap: () {
                Navigator.pop(context);
                _shareLocation();
              },
            ),
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
    final shareText = '''${spot.name}

${spot.description.isNotEmpty ? '${spot.description}\n' : ''}${spot.address != null ? 'Address: ${spot.address}\n' : ''}Category: ${spot.category}
Location: ${spot.latitude.toStringAsFixed(6)}, ${spot.longitude.toStringAsFixed(6)}

Shared from SPOTS - know you belong.''';

    Share.share(shareText, subject: 'Check out this spot: ${spot.name}');
  }

  void _copySpotLink(BuildContext context) {
    // Generate a shareable link (this would normally be a deep link to the app)
    final spotLink = 'https://spots.app/spot/${spot.id}?lat=${spot.latitude}&lng=${spot.longitude}';
    
    Clipboard.setData(ClipboardData(text: spotLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spot link copied to clipboard'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _shareLocation() {
    final locationText = '''📍 ${spot.name}
${spot.address ?? 'Coordinates: ${spot.latitude.toStringAsFixed(6)}, ${spot.longitude.toStringAsFixed(6)}'}

Shared from SPOTS''';

    Share.share(locationText);
  }

  void _openInMaps(BuildContext context, Spot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Open in Maps'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Google Maps'),
              onTap: () {
                Navigator.pop(context);
                _openGoogleMaps(spot);
              },
            ),
            ListTile(
              leading: const Icon(Icons.apple),
              title: const Text('Apple Maps'),
              onTap: () {
                Navigator.pop(context);
                _openAppleMaps(spot);
              },
            ),
            ListTile(
              leading: const Icon(Icons.web),
              title: const Text('Web Browser'),
              onTap: () {
                Navigator.pop(context);
                _openInBrowser(spot);
              },
            ),
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

  Future<void> _openGoogleMaps(Spot spot) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${spot.latitude},${spot.longitude}';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to web version
      await _openInBrowser(spot);
    }
  }

  Future<void> _openAppleMaps(Spot spot) async {
    final url = 'https://maps.apple.com/?q=${spot.latitude},${spot.longitude}';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to Google Maps web
      await _openInBrowser(spot);
    }
  }

  Future<void> _openInBrowser(Spot spot) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=${spot.latitude},${spot.longitude}';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  void _showAddToListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => BlocBuilder<ListsBloc, ListsState>(
        builder: (context, state) {
          if (state is ListsLoaded) {
            if (state.lists.isEmpty) {
              return AlertDialog(
                title: const Text('No Lists Available'),
                content: const Text('Create a list first to add spots to it.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              );
            }

            return AlertDialog(
              title: const Text('Add to List'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.lists.length,
                  itemBuilder: (context, index) {
                    final list = state.lists[index];
                    final isInList = list.spotIds.contains(spot.id);

                    return ListTile(
                      leading: Icon(
                        isInList
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isInList ? AppTheme.successColor : null,
                      ),
                      title: Text(list.title),
                      subtitle: Text(list.description),
                      onTap: () {
                        if (!isInList) {
                          _addSpotToList(context, list);
                        }
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          }

          return const AlertDialog(
            title: Text('Loading Lists'),
            content: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  void _addSpotToList(BuildContext context, SpotList list) {
    final updatedList = list.copyWith(
      spotIds: [...list.spotIds, spot.id],
      updatedAt: DateTime.now(),
    );

    context.read<ListsBloc>().add(UpdateList(updatedList));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${spot.name} to ${list.title}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.grey600,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Color _getCategoryColor(String category) => CategoryStyles.colorFor(category);
}
