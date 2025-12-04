import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:get_it/get_it.dart';

/// OUR_GUTS.md: "Make hosting incredibly easy"
/// Easy Event Hosting - Phase 3: Copy & Repeat
/// One-click button to duplicate past events
class EventHostAgainButton extends StatelessWidget {
  final ExpertiseEvent originalEvent;
  final VoidCallback? onSuccess;
  
  const EventHostAgainButton({
    Key? key,
    required this.originalEvent,
    this.onSuccess,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _hostAgain(context),
      icon: const Icon(Icons.replay),
      label: const Text('Host Again'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  
  Future<void> _hostAgain(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
      
      // Duplicate the event
      final eventService = GetIt.I<ExpertiseEventService>();
      final newEvent = await eventService.duplicateEvent(
        originalEvent: originalEvent,
      );
      
      // Close loading
      Navigator.pop(context);
      
      // Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Event "${newEvent.title}" created for next weekend! 🎉'),
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'View',
            textColor: AppColors.white,
            onPressed: () {
              // Navigate to event detail page
              // Navigator.push(...);
            },
          ),
        ),
      );
      
      onSuccess?.call();
    } catch (e) {
      // Close loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to duplicate event: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

/// Compact version for list items
class EventHostAgainIconButton extends StatelessWidget {
  final ExpertiseEvent originalEvent;
  final VoidCallback? onSuccess;
  
  const EventHostAgainIconButton({
    Key? key,
    required this.originalEvent,
    this.onSuccess,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.replay, color: AppColors.primary),
      tooltip: 'Host Again',
      onPressed: () => _hostAgain(context),
    );
  }
  
  Future<void> _hostAgain(BuildContext context) async {
    // Same logic as button version
    final button = EventHostAgainButton(
      originalEvent: originalEvent,
      onSuccess: onSuccess,
    );
    await button._hostAgain(context);
  }
}

