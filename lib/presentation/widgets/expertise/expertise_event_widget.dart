import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/widgets/expertise/expertise_pin_widget.dart';

/// Expertise Event Widget
/// Displays expert-led events
class ExpertiseEventWidget extends StatelessWidget {
  final ExpertiseEvent event;
  final UnifiedUser? currentUser;
  final VoidCallback? onRegister;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  const ExpertiseEventWidget({
    super.key,
    required this.event,
    this.currentUser,
    this.onRegister,
    this.onCancel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRegistered = currentUser != null && event.attendeeIds.contains(currentUser!.id);
    final canRegister = currentUser != null && event.canUserAttend(currentUser!.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Event Type Icon
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.getEventTypeEmoji(),
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title and Type
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.getEventTypeDisplayName(),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  _buildStatusBadge(),
                ],
              ),
              const SizedBox(height: 12),
              // Host Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.grey200,
                    child: event.host.photoUrl != null
                        ? Image.network(event.host.photoUrl!)
                        : Text(
                            (event.host.displayName ?? event.host.email)[0].toUpperCase(),
                            style: const TextStyle(fontSize: 12),
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hosted by ${event.host.displayName ?? event.host.email}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (event.host.hasExpertiseIn(event.category)) ...[
                          const SizedBox(height: 2),
                          ExpertisePinWidget(
                            pin: event.host.getExpertisePins()
                                .firstWhere((p) => p.category == event.category),
                            showDetails: false,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                event.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              // Event Details
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(event.startTime),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    '${event.attendeeCount}/${event.maxAttendees}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (event.location != null) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location!,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              if (event.spots.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.place, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${event.spots.length} ${event.spots.length == 1 ? 'spot' : 'spots'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
              // Action Buttons
              if (currentUser != null) ...[
                const SizedBox(height: 16),
                if (isRegistered)
                  OutlinedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel Registration'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                  )
                else if (canRegister)
                  ElevatedButton.icon(
                    onPressed: onRegister,
                    icon: const Icon(Icons.event_available),
                    label: const Text('Register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricGreen,
                      foregroundColor: AppColors.white,
                    ),
                  )
                else
                  Text(
                    event.isFull ? 'Event Full' : 'Registration Closed',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    Color badgeColor;
    String badgeText;

    switch (event.status) {
      case EventStatus.upcoming:
        badgeColor = AppColors.electricGreen;
        badgeText = 'Upcoming';
        break;
      case EventStatus.ongoing:
        badgeColor = AppColors.warning;
        badgeText = 'Ongoing';
        break;
      case EventStatus.completed:
        badgeColor = AppColors.grey400;
        badgeText = 'Completed';
        break;
      case EventStatus.cancelled:
        badgeColor = AppColors.error;
        badgeText = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        badgeText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: badgeColor,
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.inDays == 0) {
      return 'Today at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}/${dateTime.day} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// Expertise Event List Widget
class ExpertiseEventListWidget extends StatelessWidget {
  final List<ExpertiseEvent> events;
  final UnifiedUser? currentUser;
  final Function(ExpertiseEvent)? onEventTap;
  final Function(ExpertiseEvent)? onRegister;
  final Function(ExpertiseEvent)? onCancel;

  const ExpertiseEventListWidget({
    super.key,
    required this.events,
    this.currentUser,
    this.onEventTap,
    this.onRegister,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.event_busy, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: 16),
            Text(
              'No events found',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return ExpertiseEventWidget(
          event: event,
          currentUser: currentUser,
          onTap: () => onEventTap?.call(event),
          onRegister: () => onRegister?.call(event),
          onCancel: () => onCancel?.call(event),
        );
      },
    );
  }
}

