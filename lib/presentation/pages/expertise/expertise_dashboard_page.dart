import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/expertise_pin.dart';
import 'package:spots/core/models/expertise_progress.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/expertise_service.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/widgets/expertise/expertise_display_widget.dart';
import 'package:spots/presentation/widgets/expertise/expertise_progress_widget.dart';
import 'package:spots/presentation/widgets/expertise/partnership_expertise_boost_widget.dart';
import 'package:spots/presentation/blocs/auth/auth_bloc.dart';
import 'package:go_router/go_router.dart';

/// Expertise Dashboard Page
/// Shows user's complete expertise profile with all categories and progress
/// OUR_GUTS.md: "Pins, Not Badges" - Visual recognition without gamification
/// 
/// **Usage Example:**
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => const ExpertiseDashboardPage(),
///   ),
/// );
/// ```
class ExpertiseDashboardPage extends StatefulWidget {
  final UnifiedUser? user; // Optional - will get from AuthBloc if not provided

  const ExpertiseDashboardPage({
    super.key,
    this.user,
  });

  @override
  State<ExpertiseDashboardPage> createState() => _ExpertiseDashboardPageState();
}

class _ExpertiseDashboardPageState extends State<ExpertiseDashboardPage> {
  final ExpertiseService _expertiseService = ExpertiseService();
  List<ExpertisePin>? _pins;
  Map<String, ExpertiseProgress>? _progressMap;
  bool _isLoading = true;
  UnifiedUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadExpertise();
  }

  Future<void> _loadExpertise() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get user from widget parameter or AuthBloc
      final authState = context.read<AuthBloc>().state;
      UnifiedUser? user = widget.user;

      if (user == null && authState is Authenticated) {
        // Convert User to UnifiedUser for expertise service
        // Note: This is a simplified conversion - in production, you'd want a proper conversion service
        user = UnifiedUser(
          id: authState.user.id,
          email: authState.user.email,
          displayName: authState.user.displayName ?? authState.user.name,
          photoUrl: null, // User model doesn't have avatarUrl - would need to get from profile
          location: null, // User model doesn't have location - would need to get from profile
          createdAt: authState.user.createdAt,
          updatedAt: authState.user.updatedAt,
          isOnline: authState.user.isOnline ?? false,
          expertiseMap: {}, // Empty for now - would be populated from user data
        );
      }

      if (user != null) {
        _currentUser = user;
        final pins = _expertiseService.getUserPins(user);
        
        // Calculate progress for each category
        final progressMap = <String, ExpertiseProgress>{};
        for (final pin in pins) {
          // Simplified progress calculation - in production, would get contribution counts
          final progress = _expertiseService.calculateProgress(
            category: pin.category,
            location: pin.location,
            currentLevel: pin.level,
            respectedListsCount: pin.contributionCount,
            thoughtfulReviewsCount: pin.contributionCount,
            spotsReviewedCount: 0,
            communityTrustScore: pin.communityTrustScore,
          );
          progressMap[pin.category] = progress;
        }

        setState(() {
          _pins = pins;
          _progressMap = progressMap;
          _isLoading = false;
        });
      } else {
        setState(() {
          _pins = [];
          _progressMap = {};
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _pins = [];
        _progressMap = {};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expertise Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppColors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? _buildNotAuthenticatedState()
              : _pins == null || _pins!.isEmpty
                  ? _buildEmptyState()
                  : _buildDashboardContent(),
    );
  }

  Widget _buildNotAuthenticatedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Please sign in to view your expertise',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.stars_outlined,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Expertise Yet',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start contributing to earn expertise pins! Create lists, review spots, and share your knowledge.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    if (_pins == null || _currentUser == null) {
      return const SizedBox.shrink();
    }

    // Group pins by category
    final categoryGroups = <String, List<ExpertisePin>>{};
    for (final pin in _pins!) {
      categoryGroups.putIfAbsent(pin.category, () => []).add(pin);
    }

    // Sort categories by highest level
    final sortedCategories = categoryGroups.keys.toList()
      ..sort((a, b) {
        final aMaxLevel = categoryGroups[a]!
            .map((p) => p.level.index)
            .reduce((a, b) => a > b ? a : b);
        final bMaxLevel = categoryGroups[b]!
            .map((p) => p.level.index)
            .reduce((a, b) => a > b ? a : b);
        return bMaxLevel.compareTo(aMaxLevel);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary Card
          ExpertiseDisplayWidget(
            user: _currentUser!,
            showProgress: false, // We'll show detailed progress below
          ),
          const SizedBox(height: 24),

          // Partnership Boost Section (Phase 4.5)
          _buildPartnershipBoostSection(),
          const SizedBox(height: 24),

          // Category Breakdown
          Text(
            'Expertise by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Category Cards
          ...sortedCategories.map((category) {
            final categoryPins = categoryGroups[category]!;
            final highestPin = categoryPins
              ..sort((a, b) => b.level.index.compareTo(a.level.index));
            final primaryPin = highestPin.first;
            final progress = _progressMap?[category];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildCategoryCard(primaryPin, categoryPins, progress),
            );
          }),

          // Progress Section
          if (_progressMap != null && _progressMap!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Progress to Next Level',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            ..._progressMap!.values.map((progress) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ExpertiseProgressWidget(progress: progress),
              );
            }),
          ],

          // Requirements Section
          const SizedBox(height: 24),
          _buildRequirementsSection(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    ExpertisePin primaryPin,
    List<ExpertisePin> allPins,
    ExpertiseProgress? progress,
  ) {
    final pinColor = primaryPin.getPinColor();
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pinColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    primaryPin.getPinIcon(),
                    size: 24,
                    color: pinColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        primaryPin.category,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            primaryPin.level.emoji,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${primaryPin.level.displayName} Level',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (primaryPin.location != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '• ${primaryPin.location}',
                              style: TextStyle(
                                fontSize: 14,
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    primaryPin.level.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),

            // Progress (if available)
            if (progress != null) ...[
              const SizedBox(height: 16),
              ExpertiseProgressWidget(progress: progress, showDetails: true),
            ],

            // Unlocked Features
            if (primaryPin.unlockedFeatures.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Unlocked Features',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: primaryPin.unlockedFeatures.map((feature) {
                  return Chip(
                    label: Text(
                      feature.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: AppColors.grey100,
                    side: BorderSide(color: AppColors.grey300),
                  );
                }).toList(),
              ),
            ],

            // Earned Date
            const SizedBox(height: 12),
            Text(
              'Earned: ${_formatDate(primaryPin.earnedAt)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartnershipBoostSection() {
    // TODO: Replace with actual PartnershipProfileService and ExpertiseCalculationService
    // once Agent 1 completes them
    // Example:
    // final profileService = sl<PartnershipProfileService>();
    // final expertiseService = sl<ExpertiseCalculationService>();
    // final userId = _currentUser?.id ?? '';
    // final partnerships = await profileService.getUserPartnerships(userId);
    // final boost = await expertiseService.calculatePartnershipBoost(
    //   userId: userId,
    //   category: null, // or specific category
    // );
    
    // For now, return empty widget or placeholder
    // This will be populated when services are available
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadPartnershipBoost(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data ?? {};
        final totalBoost = (data['totalBoost'] as num?)?.toDouble() ?? 0.0;
        final boostByCategory = Map<String, double>.from(
          data['boostByCategory'] as Map? ?? {},
        );
        final activePartnerships = (data['activePartnerships'] as int?) ?? 0;
        final completedPartnerships = (data['completedPartnerships'] as int?) ?? 0;

        if (totalBoost <= 0 && activePartnerships == 0 && completedPartnerships == 0) {
          return const SizedBox.shrink();
        }

        return PartnershipExpertiseBoostWidget(
          totalBoost: totalBoost,
          boostByCategory: boostByCategory,
          activePartnerships: activePartnerships,
          completedPartnerships: completedPartnerships,
          onViewPartnerships: () {
            context.go('/profile/partnerships');
          },
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadPartnershipBoost() async {
    // TODO: Replace with actual service calls once Agent 1 completes services
    // For now, return empty data
    return {
      'totalBoost': 0.0,
      'boostByCategory': <String, double>{},
      'activePartnerships': 0,
      'completedPartnerships': 0,
    };
  }

  Widget _buildRequirementsSection() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'How Expertise Works',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Expertise is earned through authentic contributions:',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            _buildRequirementItem('Create respected lists in categories'),
            _buildRequirementItem('Write thoughtful reviews'),
            _buildRequirementItem('Build community trust'),
            _buildRequirementItem('Share quality recommendations'),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementItem(String text) {
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
              text,
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

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

