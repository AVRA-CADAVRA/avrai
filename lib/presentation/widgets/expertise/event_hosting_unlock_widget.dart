import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/expertise_progress.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/expertise_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';

/// Event Hosting Unlock Widget
/// Shows when user unlocks event hosting (Local level+ required)
/// OUR_GUTS.md: "The key opens doors to events"
/// 
/// **Usage Example:**
/// ```dart
/// EventHostingUnlockWidget(
///   user: currentUser,
///   onUnlockTap: () {
///     Navigator.push(context, MaterialPageRoute(
///       builder: (context) => CreateEventPage(),
///     ));
///   },
/// )
/// ```
class EventHostingUnlockWidget extends StatefulWidget {
  final UnifiedUser user;
  final VoidCallback? onUnlockTap;
  final VoidCallback? onProgressTap;

  const EventHostingUnlockWidget({
    super.key,
    required this.user,
    this.onUnlockTap,
    this.onProgressTap,
  });

  @override
  State<EventHostingUnlockWidget> createState() => _EventHostingUnlockWidgetState();
}

class _EventHostingUnlockWidgetState extends State<EventHostingUnlockWidget>
    with SingleTickerProviderStateMixin {
  final ExpertiseService _expertiseService = ExpertiseService();
  bool _isUnlocked = false;
  bool _wasUnlockedBefore = false;
  ExpertiseLevel? _currentHighestLevel;
  ExpertiseProgress? _progressToCity;
  
  late AnimationController _unlockAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkUnlockStatus();
  }

  void _initAnimations() {
    _unlockAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _unlockAnimationController,
      curve: Curves.easeIn,
    ));

    _unlockAnimationController.forward();
  }

  @override
  void dispose() {
    _unlockAnimationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EventHostingUnlockWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _checkUnlockStatus();
    }
  }

  void _checkUnlockStatus() {
    // Check if user can host events (Local level+ required)
    final wasUnlocked = _isUnlocked;
    _isUnlocked = widget.user.canHostEvents();
    
    // Trigger unlock animation if just unlocked
    if (!wasUnlocked && _isUnlocked) {
      _wasUnlockedBefore = false;
      _unlockAnimationController.reset();
      _unlockAnimationController.forward();
    }

    // Get highest expertise level
    final pins = _expertiseService.getUserPins(widget.user);
    if (pins.isNotEmpty) {
      pins.sort((a, b) => b.level.index.compareTo(a.level.index));
      _currentHighestLevel = pins.first.level;
    } else {
      _currentHighestLevel = ExpertiseLevel.local;
    }

    // Calculate progress to Local level if not unlocked
    if (!_isUnlocked) {
      // Find highest category to calculate progress
      if (pins.isNotEmpty) {
        final highestPin = pins.first;
        // Simplified progress calculation - in production, would get contribution counts
        _progressToCity = _expertiseService.calculateProgress(
          category: highestPin.category,
          location: highestPin.location,
          currentLevel: highestPin.level,
          respectedListsCount: highestPin.contributionCount,
          thoughtfulReviewsCount: highestPin.contributionCount,
          spotsReviewedCount: 0,
          communityTrustScore: highestPin.communityTrustScore,
        );
      } else {
        // No expertise yet - show progress to Local level
        _progressToCity = _expertiseService.calculateProgress(
          category: 'General',
          location: widget.user.location,
          currentLevel: ExpertiseLevel.local,
          respectedListsCount: 0,
          thoughtfulReviewsCount: 0,
          spotsReviewedCount: 0,
          communityTrustScore: 0.0,
        );
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _isUnlocked ? widget.onUnlockTap : widget.onProgressTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _isUnlocked
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isUnlocked
                ? AppTheme.primaryColor.withValues(alpha: 0.3)
                : AppColors.grey300,
            width: 2,
          ),
        ),
        child: _isUnlocked
            ? _buildUnlockedState()
            : _buildLockedState(),
      ),
    );
  }

  Widget _buildUnlockedState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unlocked Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Event Hosting Unlocked!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can now create and host events',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Current Level Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Row(
            children: [
              if (_currentHighestLevel != null) ...[
                Text(
                  _currentHighestLevel!.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_currentHighestLevel!.displayName} Level',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.onUnlockTap,
                icon: const Icon(Icons.event, size: 20),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedState() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Locked Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock,
                color: AppColors.textSecondary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Event Hosting',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reach Local level expertise to host events',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Requirement Display
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.grey50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Requirement: ${ExpertiseLevel.local.emoji} ${ExpertiseLevel.local.displayName} Level or higher',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Current Level
        if (_currentHighestLevel != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current Level',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Row(
                children: [
                  Text(
                    _currentHighestLevel!.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _currentHighestLevel!.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Progress to Local Level
        if (_progressToCity != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progress to ${ExpertiseLevel.local.displayName}',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                '${_progressToCity!.progressPercentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(
              begin: 0.0,
              end: _progressToCity!.progressPercentage / 100.0,
            ),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.grey200,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            _progressToCity!.getFormattedProgress(),
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],

        const SizedBox(height: 16),

        // Next Steps
        if (_progressToCity != null && _progressToCity!.nextSteps.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Steps:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ..._progressToCity!.nextSteps.take(2).map((step) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            step,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Event Hosting Unlock Notification Widget
/// Shows celebration when user unlocks event hosting
class EventHostingUnlockNotification extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const EventHostingUnlockNotification({
    super.key,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Celebration Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🎉',
                style: const TextStyle(fontSize: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Event Hosting Unlocked!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve reached Local level expertise. You can now create and host events!',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: onDismiss,
                  child: Text(
                    'Dismiss',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: AppColors.white,
                  ),
                  child: const Text('Create Event'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

