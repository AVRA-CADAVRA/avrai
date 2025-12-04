import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_pin.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/expertise_requirements.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/expertise_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/widgets/expertise/locality_threshold_widget.dart';
import 'package:go_router/go_router.dart';

/// Expertise Display Widget
/// Displays user's expertise levels and category expertise
/// OUR_GUTS.md: "Pins, Not Badges" - Visual recognition without gamification
/// 
/// **Usage Example:**
/// ```dart
/// ExpertiseDisplayWidget(
///   user: currentUser,
///   showProgress: true,
/// )
/// ```
class ExpertiseDisplayWidget extends StatefulWidget {
  final UnifiedUser user;
  final bool showProgress;
  final VoidCallback? onTap;

  const ExpertiseDisplayWidget({
    super.key,
    required this.user,
    this.showProgress = true,
    this.onTap,
  });

  @override
  State<ExpertiseDisplayWidget> createState() => _ExpertiseDisplayWidgetState();
}

class _ExpertiseDisplayWidgetState extends State<ExpertiseDisplayWidget> {
  final ExpertiseService _expertiseService = ExpertiseService();
  List<ExpertisePin>? _pins;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExpertise();
  }

  @override
  void didUpdateWidget(ExpertiseDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _loadExpertise();
    }
  }

  Future<void> _loadExpertise() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pins = _expertiseService.getUserPins(widget.user);
      setState(() {
        _pins = pins;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _pins = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.stars,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Your Expertise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Content
            if (_isLoading)
              _buildLoadingState()
            else if (_pins == null || _pins!.isEmpty)
              _buildEmptyState()
            else
              _buildExpertiseContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Start contributing to earn expertise pins!',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpertiseContent() {
    // Group pins by level
    final levelGroups = <ExpertiseLevel, List<ExpertisePin>>{};
    for (final pin in _pins!) {
      levelGroups.putIfAbsent(pin.level, () => []).add(pin);
    }

    // Filter to show Local level and above (as per requirements)
    final displayLevels = [
      ExpertiseLevel.local,
      ExpertiseLevel.city,
      ExpertiseLevel.regional,
      ExpertiseLevel.national,
      ExpertiseLevel.global,
      ExpertiseLevel.universal,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Expertise Levels Summary
        _buildLevelsSummary(levelGroups, displayLevels),
        const SizedBox(height: 16),
        
        // Category Expertise
        _buildCategoryExpertise(),
        
        // Locality Threshold Indicators (Week 25)
        _buildLocalityThresholdIndicators(),
        
        // Partnership Boost Indicator (Phase 4.5)
        _buildPartnershipBoostIndicator(),
        
        // Progress Indicators (if enabled)
        if (widget.showProgress) ...[
          const SizedBox(height: 16),
          _buildProgressIndicators(),
        ],
      ],
    );
  }

  Widget _buildLevelsSummary(
    Map<ExpertiseLevel, List<ExpertisePin>> levelGroups,
    List<ExpertiseLevel> displayLevels,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expertise Levels',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: displayLevels.map((level) {
            final pinsAtLevel = levelGroups[level] ?? [];
            return _buildLevelBadge(level, pinsAtLevel.length);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLevelBadge(ExpertiseLevel level, int count) {
    final hasLevel = count > 0;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasLevel
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasLevel
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : AppColors.grey300,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 6),
          Text(
            level.displayName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: hasLevel ? FontWeight.w600 : FontWeight.w400,
              color: hasLevel ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
          if (hasLevel && count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryExpertise() {
    if (_pins == null || _pins!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Sort pins by level (highest first)
    final sortedPins = List<ExpertisePin>.from(_pins!)
      ..sort((a, b) => b.level.index.compareTo(a.level.index));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Expertise',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...sortedPins.map((pin) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildCategoryPin(pin),
            )),
      ],
    );
  }

  Widget _buildCategoryPin(ExpertisePin pin) {
    final pinColor = pin.getPinColor();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          // Pin Icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: pinColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              pin.getPinIcon(),
              size: 20,
              color: pinColor,
            ),
          ),
          const SizedBox(width: 12),
          // Category Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pin.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      pin.level.emoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pin.level.displayName} Level',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (pin.location != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${pin.location}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Level Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              pin.level.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalityThresholdIndicators() {
    if (_pins == null || _pins!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show locality thresholds for Local level expertise (or below)
    final localPins = _pins!.where((pin) => 
      pin.level == ExpertiseLevel.local || 
      (pin.location != null && pin.level.index < ExpertiseLevel.city.index)
    ).toList();

    if (localPins.isEmpty) {
      return const SizedBox.shrink();
    }

    // Show threshold for first local pin (or user's primary locality)
    final pinToShow = localPins.first;
    final userLocality = widget.user.location;

    // Extract locality from location string (format: "Locality, City, State")
    String? extractLocality(String? location) {
      if (location == null || location.isEmpty) return null;
      final parts = location.split(',').map((s) => s.trim()).toList();
      return parts.isNotEmpty ? parts.first : null;
    }

    final locality = extractLocality(pinToShow.location ?? userLocality);
    if (locality == null) {
      return const SizedBox.shrink();
    }

    // Get base thresholds (would come from ExpertiseRequirements in production)
    // For now, use placeholder - in production would get from service
    final baseThresholds = ThresholdValues(
      minVisits: 10,
      minRatings: 5,
      minAvgRating: 4.0,
      minTimeInCategory: const Duration(days: 30),
      minCommunityEngagement: 3,
      minListCuration: 1,
      minEventHosting: null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        LocalityThresholdWidget(
          user: widget.user,
          category: pinToShow.category,
          locality: locality,
          baseThresholds: baseThresholds,
        ),
      ],
    );
  }

  Widget _buildProgressIndicators() {
    if (_pins == null || _pins!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress to Next Level',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ..._pins!.take(3).map((pin) {
          // Calculate progress (simplified - in real implementation, get from service)
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildProgressBar(pin),
          );
        }),
      ],
    );
  }

  Widget _buildProgressBar(ExpertisePin pin) {
    // Simplified progress calculation
    // In real implementation, would call ExpertiseService.calculateProgress()
    final nextLevel = pin.level.nextLevel;
    final progressPercentage = nextLevel != null ? 45.0 : 100.0; // Placeholder

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              pin.category,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (nextLevel != null)
              Text(
                '→ ${nextLevel.displayName}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              )
            else
              Text(
                'Max Level',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progressPercentage / 100.0,
            minHeight: 6,
            backgroundColor: AppColors.grey200,
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${progressPercentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPartnershipBoostIndicator() {
    // TODO: Replace with actual service calls once Agent 1 completes services
    // For now, return a compact indicator that will be populated when services are available
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadPartnershipBoost(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data ?? {};
        final totalBoost = (data['totalBoost'] as num?)?.toDouble() ?? 0.0;
        final activePartnerships = (data['activePartnerships'] as int?) ?? 0;
        final completedPartnerships = (data['completedPartnerships'] as int?) ?? 0;

        if (totalBoost <= 0 && activePartnerships == 0 && completedPartnerships == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.handshake,
                size: 16,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '+${(totalBoost * 100).toStringAsFixed(1)}% from partnerships',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.go('/profile/partnerships');
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'View',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadPartnershipBoost() async {
    // TODO: Replace with actual service calls once Agent 1 completes services
    // Example:
    // final profileService = sl<PartnershipProfileService>();
    // final expertiseService = sl<ExpertiseCalculationService>();
    // final userId = widget.user.id;
    // final partnerships = await profileService.getUserPartnerships(userId);
    // final boost = await expertiseService.calculatePartnershipBoost(
    //   userId: userId,
    //   category: null,
    // );
    // return {
    //   'totalBoost': boost.totalBoost,
    //   'activePartnerships': partnerships.where((p) => p.isActive).length,
    //   'completedPartnerships': partnerships.where((p) => p.isCompleted).length,
    // };
    
    // For now, return empty data
    return {
      'totalBoost': 0.0,
      'activePartnerships': 0,
      'completedPartnerships': 0,
    };
  }
}
