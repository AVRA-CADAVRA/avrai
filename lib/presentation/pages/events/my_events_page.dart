import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/widgets/expertise/expertise_event_widget.dart';
import 'package:spots/presentation/pages/events/event_details_page.dart';
import 'package:spots/presentation/pages/events/cancellation_flow_page.dart';
import 'package:spots/presentation/pages/feedback/event_feedback_page.dart';
import 'package:spots/presentation/widgets/common/page_transitions.dart';

/// My Events Page
/// Agent 2: Event Discovery & Hosting UI (Phase 1, Section 1)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Tab 1: Hosting (events user is hosting)
/// - Tab 2: Attending (events user is registered for)
/// - Tab 3: Past (past events - hosted or attended)
class MyEventsPage extends StatefulWidget {
  const MyEventsPage({super.key});

  @override
  State<MyEventsPage> createState() => _MyEventsPageState();
}

class _MyEventsPageState extends State<MyEventsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ExpertiseEventService _eventService = ExpertiseEventService();
  
  List<ExpertiseEvent> _hostedEvents = [];
  List<ExpertiseEvent> _attendingEvents = [];
  List<ExpertiseEvent> _pastEvents = [];
  
  bool _isLoading = false;
  String? _error;
  UnifiedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      setState(() {
        _error = 'Please sign in to view your events';
      });
      return;
    }

    final user = authState.user;
    
    // Convert User to UnifiedUser
    _currentUser = UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
    );

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load hosted events
      final hosted = await _eventService.getEventsByHost(_currentUser!);
      
      // Load attending events
      final attending = await _eventService.getEventsByAttendee(_currentUser!);
      
      // Separate past events
      final now = DateTime.now();
      final pastHosted = hosted.where((e) => e.endTime.isBefore(now)).toList();
      final pastAttending = attending.where((e) => e.endTime.isBefore(now)).toList();
      final allPastEvents = [...pastHosted, ...pastAttending];
      
      // Remove duplicates (if user hosted and attended same event)
      final uniquePastEvents = <String, ExpertiseEvent>{};
      for (final event in allPastEvents) {
        uniquePastEvents[event.id] = event;
      }
      
      // Filter out past events from hosted and attending
      final upcomingHosted = hosted.where((e) => e.endTime.isAfter(now)).toList();
      final upcomingAttending = attending.where((e) => e.endTime.isAfter(now)).toList();
      
      setState(() {
        _hostedEvents = upcomingHosted;
        _attendingEvents = upcomingAttending;
        _pastEvents = uniquePastEvents.values.toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime)); // Most recent first
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load events: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'My Events',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.white,
          unselectedLabelColor: AppColors.white.withValues(alpha: 0.7),
          indicatorColor: AppColors.white,
          tabs: [
            const Tab(text: 'Hosting', icon: Icon(Icons.event)),
            const Tab(text: 'Attending', icon: Icon(Icons.event_available)),
            const Tab(text: 'Past', icon: Icon(Icons.history)),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadEvents,
        color: AppColors.electricGreen,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvents,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildHostedEventsTab(),
        _buildAttendingEventsTab(),
        _buildPastEventsTab(),
      ],
    );
  }

  Widget _buildHostedEventsTab() {
    if (_hostedEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_busy,
        title: 'No Hosted Events',
        message: 'You haven\'t hosted any upcoming events yet.\nCreate your first event to get started!',
        actionLabel: 'Create Event',
        onAction: () {
          // TODO: Navigate to create event page (Week 3)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event creation coming soon'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hostedEvents.length,
      itemBuilder: (context, index) {
        final event = _hostedEvents[index];
        return ExpertiseEventWidget(
          event: event,
          currentUser: _currentUser,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailsPage(event: event),
              ),
            );
          },
          onCancel: () {
            // Navigate to cancellation flow for host
            Navigator.push(
              context,
              PageTransitions.slideFromRight(
                CancellationFlowPage(
                  event: event,
                  isHost: true,
                ),
              ),
            ).then((_) => _loadEvents());
          },
        );
      },
    );
  }

  Widget _buildAttendingEventsTab() {
    if (_attendingEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.event_available,
        title: 'No Upcoming Events',
        message: 'You\'re not registered for any upcoming events.\nBrowse events to find something interesting!',
        actionLabel: 'Browse Events',
        onAction: () {
          Navigator.pop(context); // Go back to browse page
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _attendingEvents.length,
      itemBuilder: (context, index) {
        final event = _attendingEvents[index];
        return ExpertiseEventWidget(
          event: event,
          currentUser: _currentUser,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EventDetailsPage(event: event),
              ),
            );
          },
          onCancel: () {
            // Navigate to cancellation flow
            Navigator.push(
              context,
              PageTransitions.slideFromRight(
                CancellationFlowPage(
                  event: event,
                  isHost: false,
                ),
              ),
            ).then((_) => _loadEvents());
          },
        );
      },
    );
  }

  Widget _buildPastEventsTab() {
    if (_pastEvents.isEmpty) {
      return _buildEmptyState(
        icon: Icons.history,
        title: 'No Past Events',
        message: 'You haven\'t hosted or attended any events yet.\nYour event history will appear here!',
        actionLabel: null,
        onAction: null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pastEvents.length,
      itemBuilder: (context, index) {
        final event = _pastEvents[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailsPage(event: event),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_formatPastDate(event.startTime)} • ${event.category}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.grey400.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          event.host.id == _currentUser?.id ? 'Hosted' : 'Attended',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        '${event.attendeeCount} ${event.attendeeCount == 1 ? 'attendee' : 'attendees'}',
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
                  // Feedback button for past events
                  if (event.status == EventStatus.completed) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          PageTransitions.slideFromRight(
                            EventFeedbackPage(event: event),
                          ),
                        );
                      },
                      icon: const Icon(Icons.feedback),
                      label: const Text('Leave Feedback'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(color: AppTheme.primaryColor),
                        minimumSize: const Size(double.infinity, 40),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatPastDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}

