import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:spots/presentation/pages/events/event_published_page.dart';

/// Event Review Page
/// Agent 2: Event Discovery & Hosting UI (Week 3, Task 2.11)
/// 
/// CRITICAL: Uses AppColors/AppTheme (100% adherence required)
/// 
/// Features:
/// - Display all event details for review
/// - Allow editing before publishing
/// - Show expertise requirements
/// - Publish confirmation
class EventReviewPage extends StatefulWidget {
  final String title;
  final String description;
  final String category;
  final ExpertiseEventType eventType;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final int maxAttendees;
  final double? price;
  final bool isPublic;

  const EventReviewPage({
    super.key,
    required this.title,
    required this.description,
    required this.category,
    required this.eventType,
    required this.startTime,
    required this.endTime,
    required this.location,
    required this.maxAttendees,
    required this.price,
    required this.isPublic,
  });

  @override
  State<EventReviewPage> createState() => _EventReviewPageState();
}

class _EventReviewPageState extends State<EventReviewPage> {
  final _eventService = ExpertiseEventService();
  bool _isLoading = false;
  String? _error;
  UnifiedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) return;

    final user = authState.user;
    _currentUser = UnifiedUser(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? user.name,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      isOnline: user.isOnline ?? false,
    );
  }

  Future<void> _publishEvent() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.background,
        title: Text(
          'Publish Event?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to publish "${widget.title}"? The event will be visible to others.',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Publish'),
          ),
        ],
      ),
    );

    if (confirmed != true || _currentUser == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final event = await _eventService.createEvent(
        host: _currentUser!,
        title: widget.title,
        description: widget.description,
        category: widget.category,
        eventType: widget.eventType,
        startTime: widget.startTime,
        endTime: widget.endTime,
        location: widget.location,
        maxAttendees: widget.maxAttendees,
        price: widget.price,
        isPublic: widget.isPublic,
      );

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        // Navigate to success page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => EventPublishedPage(event: event),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to publish event: $e';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _getEventTypeDisplayName(ExpertiseEventType type) {
    switch (type) {
      case ExpertiseEventType.tour:
        return 'Expert Tour';
      case ExpertiseEventType.workshop:
        return 'Workshop';
      case ExpertiseEventType.tasting:
        return 'Tasting';
      case ExpertiseEventType.meetup:
        return 'Meetup';
      case ExpertiseEventType.walk:
        return 'Curated Walk';
      case ExpertiseEventType.lecture:
        return 'Lecture';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${_formatTime(dateTime)}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $period';
  }

  String _formatDuration(DateTime start, DateTime end) {
    final duration = end.difference(start);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0 && minutes > 0) {
      return '$hours hour${hours > 1 ? 's' : ''} $minutes minute${minutes > 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours > 1 ? 's' : ''}';
    } else {
      return '$minutes minute${minutes > 1 ? 's' : ''}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final expertiseLevel = _currentUser?.getExpertiseLevel(widget.category);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Review Event',
          style: TextStyle(color: AppColors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Your Event',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review all details before publishing',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Event Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  _buildReviewRow('Title', widget.title),
                  const SizedBox(height: 16),

                  // Description
                  _buildReviewRow('Description', widget.description),
                  const SizedBox(height: 16),

                  // Category & Type
                  Row(
                    children: [
                      Expanded(
                        child: _buildReviewRow('Category', widget.category),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildReviewRow('Type', _getEventTypeDisplayName(widget.eventType)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Date & Time
                  _buildReviewRow(
                    'Date & Time',
                    '${_formatDateTime(widget.startTime)} - ${_formatTime(widget.endTime)}\nDuration: ${_formatDuration(widget.startTime, widget.endTime)}',
                  ),
                  const SizedBox(height: 16),

                  // Location
                  _buildReviewRow('Location', widget.location),
                  const SizedBox(height: 16),

                  // Max Attendees
                  _buildReviewRow('Max Attendees', widget.maxAttendees.toString()),
                  const SizedBox(height: 16),

                  // Price
                  _buildReviewRow(
                    'Price',
                    widget.price != null && widget.price! > 0
                        ? '\$${widget.price!.toStringAsFixed(2)}'
                        : 'Free',
                  ),
                  const SizedBox(height: 16),

                  // Public/Private
                  _buildReviewRow('Visibility', widget.isPublic ? 'Public' : 'Private'),
                  const SizedBox(height: 24),

                  // Expertise Requirements
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.electricGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.electricGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.verified, color: AppColors.electricGreen, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Expertise Verified',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.electricGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          expertiseLevel != null
                              ? 'You have ${expertiseLevel.displayName} level expertise in ${widget.category} (Required: Local level+)'
                              : 'Expertise level will be verified before publishing',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Error Display
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _publishEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: AppColors.white)
                          : const Text(
                              'Publish Event',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: AppColors.grey300),
                      ),
                      child: const Text('Edit Details'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

