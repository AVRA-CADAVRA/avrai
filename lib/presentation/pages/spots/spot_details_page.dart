import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/models/list.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/category_colors.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/presentation/widgets/validation/community_validation_widget.dart';
import 'package:go_router/go_router.dart';
import 'package:avrai/presentation/widgets/common/source_indicator_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:avrai/core/services/social_media_sharing_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/ai/event_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_availability_service.dart';
import 'package:avrai/presentation/pages/reservations/create_reservation_page.dart';
import 'package:avrai/presentation/widgets/reservations/spot_reservation_badge_widget.dart';

class SpotDetailsPage extends StatefulWidget {
  final Spot spot;

  const SpotDetailsPage({super.key, required this.spot});

  @override
  State<SpotDetailsPage> createState() => _SpotDetailsPageState();
}

class _SpotDetailsPageState extends State<SpotDetailsPage> {
  late EventLogger _eventLogger;
  DateTime? _viewStartTime;
  bool _isInitialized = false;

  // Reservation state
  bool _isCheckingReservation = false;
  bool _hasExistingReservation = false;
  bool _isReservationAvailable = true;
  int? _availableCapacity;

  @override
  void initState() {
    super.initState();
    _initializeEventLogger();
    _viewStartTime = DateTime.now();
    _checkReservationStatus();
  }

  Future<void> _initializeEventLogger() async {
    try {
      _eventLogger = di.sl<EventLogger>();
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await _eventLogger.initialize(userId: currentUser.id);
        _eventLogger.updateScreen('spot_details');

        // Log spot visited
        await _eventLogger.logSpotVisited(
          spotId: widget.spot.id,
        );
      }
      _isInitialized = true;
    } catch (e) {
      // Event logging is non-critical, continue without it
      _isInitialized = false;
    }
  }

  Future<void> _checkReservationStatus() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return; // No user, can't check reservations
    }

    setState(() {
      _isCheckingReservation = true;
    });

    try {
      final reservationService = di.sl<ReservationService>();
      final availabilityService =
          di.sl.isRegistered<ReservationAvailabilityService>()
              ? di.sl<ReservationAvailabilityService>()
              : null;

      final userId = authState.user.id;
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      // Check for existing reservation
      final userReservations =
          await reservationService.getUserReservationsForTarget(
        userId: userId,
        type: ReservationType.spot,
        targetId: widget.spot.id,
      );

      final hasActiveReservation = userReservations.any((r) =>
          r.status != ReservationStatus.cancelled &&
          r.reservationTime.isAfter(DateTime.now()));

      // Check availability
      bool isAvailable = true;
      int? availableCapacity;

      if (availabilityService != null) {
        try {
          final availability = await availabilityService.checkAvailability(
            type: ReservationType.spot,
            targetId: widget.spot.id,
            reservationTime: tomorrow,
            partySize: 1,
          );

          isAvailable = availability.isAvailable;
          availableCapacity = availability.availableCapacity;
        } catch (e) {
          // If availability check fails, assume available
          isAvailable = true;
        }
      }

      if (mounted) {
        setState(() {
          _hasExistingReservation = hasActiveReservation;
          _isReservationAvailable = isAvailable;
          _availableCapacity = availableCapacity;
          _isCheckingReservation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isReservationAvailable = true; // Default to available on error
          _isCheckingReservation = false;
        });
      }
    }
  }

  void _navigateToCreateReservation() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CreateReservationPage(
          type: ReservationType.spot,
          targetId: widget.spot.id,
          targetTitle: widget.spot.name,
        ),
      ),
    )
        .then((_) {
      // Refresh reservation status after returning
      _checkReservationStatus();
    });
  }

  @override
  void dispose() {
    // Log dwell time
    if (_isInitialized && _viewStartTime != null) {
      final duration = DateTime.now().difference(_viewStartTime!);
      _eventLogger.logDwellTime(
        spotId: widget.spot.id,
        durationMs: duration.inMilliseconds,
        interactionType: 'view',
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.spot.name),
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
                            color: _getCategoryColor(widget.spot.category),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            widget.spot.category,
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (widget.spot.rating > 0)
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.grey600, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                widget.spot.rating.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.spot.name,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (widget.spot.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.spot.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.grey600,
                            ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    SourceIndicatorWidget(
                      indicator: widget.spot.getSourceIndicator(),
                      showWarning: true,
                      compact: false,
                    ),
                    const SizedBox(height: 12),
                    // Reservation Availability Badge
                    if (!_isCheckingReservation)
                      SpotReservationBadgeWidget(
                        isAvailable: _isReservationAvailable,
                        hasExistingReservation: _hasExistingReservation,
                        availableCapacity: _availableCapacity,
                        compact: false,
                        onTap: _hasExistingReservation
                            ? null
                            : _navigateToCreateReservation,
                      )
                    else
                      const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Location',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (widget.spot.address != null) ...[
                      Text(
                        widget.spot.address!,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'Latitude: ${widget.spot.latitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    Text(
                      'Longitude: ${widget.spot.longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        _openInMaps(context, widget.spot);
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
                    const Row(
                      children: [
                        Icon(Icons.info, color: AppTheme.primaryColor),
                        SizedBox(width: 8),
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        'Created', _formatDate(widget.spot.createdAt)),
                    _buildDetailRow(
                        'Updated', _formatDate(widget.spot.updatedAt)),
                    if (widget.spot.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tags: ${widget.spot.tags.join(', ')}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Column(
              children: [
                // Make Reservation Button (prominent if available)
                if (_isReservationAvailable && !_hasExistingReservation)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToCreateReservation,
                      icon: const Icon(Icons.event_available),
                      label: const Text('Make Reservation'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (_isReservationAvailable && !_hasExistingReservation)
                  const SizedBox(height: 12),
                // Other Actions
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
              ],
            ),
            const SizedBox(height: 16),

            // Community Validation (Phase 3: For external data spots)
            CommunityValidationWidget(
              spot: widget.spot,
              onValidationComplete: () {
                // Optionally refresh spot data or show confirmation
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Thank you for helping validate community data!'),
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

  void _navigateToEdit(BuildContext context) {
    context.go('/spot/${widget.spot.id}/edit');
  }

  void _showShareDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Spot'),
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

      // Share place
      final results = await sharingService.sharePlace(
        agentId: agentId,
        userId: userId,
        placeId: widget.spot.id,
        placeName: widget.spot.name,
        placeDescription: widget.spot.description,
        placeLocation: widget.spot.address,
        placeImageUrl: widget.spot.imageUrl,
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
    final shareText = '''${widget.spot.name}

${widget.spot.description.isNotEmpty ? '${widget.spot.description}\n' : ''}${widget.spot.address != null ? 'Address: ${widget.spot.address}\n' : ''}Category: ${widget.spot.category}
Location: ${widget.spot.latitude.toStringAsFixed(6)}, ${widget.spot.longitude.toStringAsFixed(6)}

Shared from avrai - know you belong.''';

    SharePlus.instance.share(ShareParams(
      text: shareText,
      subject: 'Check out this spot: ${widget.spot.name}',
    ));
  }

  void _copySpotLink(BuildContext context) {
    // Generate a shareable link (this would normally be a deep link to the app)
    final spotLink =
        'https://avrai.app/spot/${widget.spot.id}?lat=${widget.spot.latitude}&lng=${widget.spot.longitude}';

    Clipboard.setData(ClipboardData(text: spotLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Spot link copied to clipboard'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _shareLocation() {
    final locationText = '''📍 ${widget.spot.name}
${widget.spot.address ?? 'Coordinates: ${widget.spot.latitude.toStringAsFixed(6)}, ${widget.spot.longitude.toStringAsFixed(6)}'}

Shared from avrai''';

    SharePlus.instance.share(ShareParams(text: locationText));
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
    final url =
        'https://www.google.com/maps/search/?api=1&query=${spot.latitude},${spot.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to web version
      await _openInBrowser(spot);
    }
  }

  Future<void> _openAppleMaps(Spot spot) async {
    final url =
        'https://maps.apple.com/?q=${widget.spot.latitude},${widget.spot.longitude}';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback to Google Maps web
      await _openInBrowser(spot);
    }
  }

  Future<void> _openInBrowser(Spot spot) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${spot.latitude},${spot.longitude}';
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
                    final isInList = list.spotIds.contains(widget.spot.id);

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
      spotIds: [...list.spotIds, widget.spot.id],
      updatedAt: DateTime.now(),
    );

    context.read<ListsBloc>().add(UpdateList(updatedList));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${widget.spot.name} to ${list.title}'),
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
