import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Community Event Widget
/// Displays non-expert community events
/// Agent 2: Frontend & UX Specialist (Phase 6, Week 28)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
class CommunityEventWidget extends StatelessWidget {
  final ExpertiseEvent event; // TODO: Replace with CommunityEvent when Agent 1 creates it
  final UnifiedUser? currentUser;
  final VoidCallback? onRegister;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;
  final bool isEligibleForUpgrade; // TODO: Get from CommunityEvent when Agent 1 creates it

  const CommunityEventWidget({
    super.key,
    required this.event,
    this.currentUser,
    this.onRegister,
    this.onCancel,
    this.onTap,
    this.isEligibleForUpgrade = false,
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
              // Header with Community Event Badge
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
                  // Community Event Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.electricGreen.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 12,
                          color: AppColors.electricGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Community',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.electricGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Upgrade Eligibility Indicator
              if (isEligibleForUpgrade)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.warningColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.warningColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: AppTheme.warningColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Eligible for upgrade to Local Expert Event',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.warningColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Host Info (Non-Expert Indicator)
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
                        const SizedBox(height: 2),
                        Text(
                          'Community Host',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
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
              
              // Free Event Indicator
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.attach_money,
                    size: 16,
                    color: AppColors.electricGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Free (cash at door OK)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.electricGreen,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              
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
                    label: const Text('Join Event'),
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

/// Community Event List Widget
class CommunityEventListWidget extends StatelessWidget {
  final List<ExpertiseEvent> events; // TODO: Replace with List<CommunityEvent> when Agent 1 creates it
  final UnifiedUser? currentUser;
  final Function(ExpertiseEvent)? onEventTap;
  final Function(ExpertiseEvent)? onRegister;
  final Function(ExpertiseEvent)? onCancel;
  final Map<String, bool>? upgradeEligibility; // TODO: Get from CommunityEvent when Agent 1 creates it

  const CommunityEventListWidget({
    super.key,
    required this.events,
    this.currentUser,
    this.onEventTap,
    this.onRegister,
    this.onCancel,
    this.upgradeEligibility,
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
              'No community events found',
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
        final isEligible = upgradeEligibility?[event.id] ?? false;
        return CommunityEventWidget(
          event: event,
          currentUser: currentUser,
          isEligibleForUpgrade: isEligible,
          onTap: () => onEventTap?.call(event),
          onRegister: () => onRegister?.call(event),
          onCancel: () => onCancel?.call(event),
        );
      },
    );
  }
}

