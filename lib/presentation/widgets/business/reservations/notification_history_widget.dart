// Notification History Widget
//
// Phase 15: Reservation System Implementation
// Section 15.3.3: Business Reservation Notifications
//
// Widget for viewing business reservation notification history

import 'package:flutter/material.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:get_it/get_it.dart';

/// Notification History Widget
///
/// **Purpose:** Display notification history for business reservations
///
/// **Features:**
/// - List of past notifications
/// - Filter by notification type
/// - Date-based filtering
/// - Notification details
class NotificationHistoryWidget extends StatefulWidget {
  final String businessId;

  const NotificationHistoryWidget({
    super.key,
    required this.businessId,
  });

  @override
  State<NotificationHistoryWidget> createState() =>
      _NotificationHistoryWidgetState();
}

class _NotificationHistoryWidgetState extends State<NotificationHistoryWidget> {
  final SupabaseService _supabaseService = GetIt.instance<SupabaseService>();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_supabaseService.isAvailable) {
        final client = _supabaseService.client;
        // Query notifications where data contains businessId matching this business
        // Note: In production, this would query notifications sent to business owners
        // For now, we'll query reservation notifications and filter client-side
        final response = await client
            .from('notifications')
            .select()
            .like('type', 'reservation_%')
            .order('created_at', ascending: false)
            .limit(100);

        // Filter notifications client-side by businessId from data.targetId
        // In production, notifications would be sent to business owner user ID
        final filteredNotifications = <Map<String, dynamic>>[];
        for (final notification in response) {
          final data = notification['data'] as Map<String, dynamic>?;
          if (data != null) {
            final targetId = data['targetId'] as String?;
            final reservationType = data['type'] as String?;
            // For business reservations, targetId should match businessId
            // Include reservations where type is 'business' and targetId matches
            if (targetId == widget.businessId &&
                reservationType == 'business') {
              filteredNotifications.add(notification);
            }
          }
        }

        if (mounted) {
          setState(() {
            _notifications = filteredNotifications;
            _isLoading = false;
          });
        }
      } else {
        // Offline: No notifications available
        if (mounted) {
          setState(() {
            _notifications = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load notifications: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (_error != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: AppTheme.errorColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNotifications,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notifications.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none,
                  size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'No notifications yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'You\'ll see reservation notifications here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Notification History',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadNotifications,
                  tooltip: 'Refresh',
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return _buildNotificationItem(context, notification);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(
      BuildContext context, Map<String, dynamic> notification) {
    final title = notification['title'] as String? ?? 'Notification';
    final body = notification['body'] as String? ?? '';
    final createdAt = notification['created_at'] as String?;
    final type = notification['type'] as String? ?? '';

    DateTime? dateTime;
    if (createdAt != null) {
      try {
        dateTime = DateTime.parse(createdAt);
      } catch (e) {
        // Invalid date format
      }
    }

    IconData icon;
    Color iconColor;
    if (type.contains('new') || type.contains('confirmation')) {
      icon = Icons.event_available;
      iconColor = AppColors.success;
    } else if (type.contains('modification')) {
      icon = Icons.edit;
      iconColor = AppTheme.primaryColor;
    } else if (type.contains('cancellation')) {
      icon = Icons.cancel;
      iconColor = AppTheme.errorColor;
    } else if (type.contains('no_show')) {
      icon = Icons.warning;
      iconColor = AppTheme.errorColor;
    } else if (type.contains('summary')) {
      icon = Icons.calendar_today;
      iconColor = AppTheme.primaryColor;
    } else {
      icon = Icons.notifications;
      iconColor = AppColors.textSecondary;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: iconColor.withValues(alpha: 0.1),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(body),
          if (dateTime != null) ...[
            const SizedBox(height: 4),
            Text(
              _formatDateTime(dateTime),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ],
      ),
      isThreeLine: true,
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        }
        return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
      }
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
