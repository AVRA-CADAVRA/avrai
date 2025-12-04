import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/expertise_pin.dart';
import 'package:spots/core/models/expertise_progress.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/logger.dart';

/// Expertise Service
/// OUR_GUTS.md: "Pins, Not Badges" - Calculates expertise based on authentic contributions
class ExpertiseService {
  static const String _logName = 'ExpertiseService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  /// Calculate expertise level based on contributions
  /// OUR_GUTS.md: Based on real contributions, trusted feedback, and curation quality
  ExpertiseLevel calculateExpertiseLevel({
    required int respectedListsCount,
    required int thoughtfulReviewsCount,
    required int spotsReviewedCount,
    required double communityTrustScore,
    String? location,
  }) {
    // Base requirements for each level
    // Local: 1-2 respected lists OR 10+ thoughtful reviews
    // City: 3-5 respected lists OR 25+ thoughtful reviews
    // Regional: 6-10 respected lists OR 50+ thoughtful reviews
    // National: 11-20 respected lists OR 100+ thoughtful reviews
    // Global: 21+ respected lists OR 200+ thoughtful reviews
    // Universal: Exceptional contributions + high community trust

    final totalContributions = respectedListsCount * 5 + thoughtfulReviewsCount;
    final hasHighTrust = communityTrustScore >= 0.8;

    if (respectedListsCount >= 21 && hasHighTrust) {
      return ExpertiseLevel.global;
    } else if (respectedListsCount >= 11 || thoughtfulReviewsCount >= 100) {
      return ExpertiseLevel.national;
    } else if (respectedListsCount >= 6 || thoughtfulReviewsCount >= 50) {
      return ExpertiseLevel.regional;
    } else if (respectedListsCount >= 3 || thoughtfulReviewsCount >= 25) {
      return ExpertiseLevel.city;
    } else if (respectedListsCount >= 1 || thoughtfulReviewsCount >= 10) {
      return ExpertiseLevel.local;
    }

    return ExpertiseLevel.local; // Default starting level
  }

  /// Get expertise pins from user's expertise map
  List<ExpertisePin> getUserPins(UnifiedUser user) {
    final pins = <ExpertisePin>[];

    for (final entry in user.expertiseMap.entries) {
      final category = entry.key;
      final levelString = entry.value;
      final level = ExpertiseLevel.fromString(levelString);

      if (level != null) {
        pins.add(ExpertisePin.fromMapEntry(
          userId: user.id,
          category: category,
          levelString: levelString,
          location: user.location,
          earnedAt: user.updatedAt,
          earnedReason: 'Earned through community contributions',
        ));
      }
    }

    return pins;
  }

  /// Calculate progress toward next expertise level
  ExpertiseProgress calculateProgress({
    required String category,
    required String? location,
    required ExpertiseLevel currentLevel,
    required int respectedListsCount,
    required int thoughtfulReviewsCount,
    required int spotsReviewedCount,
    required double communityTrustScore,
  }) {
    final nextLevel = currentLevel.nextLevel;
    
    if (nextLevel == null) {
      // Already at highest level
      return ExpertiseProgress(
        category: category,
        location: location,
        currentLevel: currentLevel,
        nextLevel: null,
        progressPercentage: 100.0,
        nextSteps: [
          'Continue sharing your expertise',
          'Help others discover great spots',
          'Maintain community trust',
        ],
        contributionBreakdown: {
          'lists': respectedListsCount,
          'reviews': thoughtfulReviewsCount,
          'spots': spotsReviewedCount,
        },
        totalContributions: respectedListsCount + thoughtfulReviewsCount,
        requiredContributions: 0,
        lastUpdated: DateTime.now(),
      );
    }

    // Calculate requirements for next level
    final requirements = _getLevelRequirements(nextLevel);
    final currentContributions = respectedListsCount + thoughtfulReviewsCount;
    final progressPercentage = (currentContributions / requirements.totalContributions * 100.0).clamp(0.0, 100.0);

    // Generate next steps
    final nextSteps = _generateNextSteps(
      currentLevel: currentLevel,
      nextLevel: nextLevel,
      currentLists: respectedListsCount,
      currentReviews: thoughtfulReviewsCount,
      requirements: requirements,
    );

    return ExpertiseProgress(
      category: category,
      location: location,
      currentLevel: currentLevel,
      nextLevel: nextLevel,
      progressPercentage: progressPercentage,
      nextSteps: nextSteps,
      contributionBreakdown: {
        'lists': respectedListsCount,
        'reviews': thoughtfulReviewsCount,
        'spots': spotsReviewedCount,
      },
      totalContributions: currentContributions,
      requiredContributions: requirements.totalContributions,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get level requirements
  LevelRequirements _getLevelRequirements(ExpertiseLevel level) {
    switch (level) {
      case ExpertiseLevel.local:
        return LevelRequirements(lists: 1, reviews: 10, totalContributions: 10);
      case ExpertiseLevel.city:
        return LevelRequirements(lists: 3, reviews: 25, totalContributions: 25);
      case ExpertiseLevel.regional:
        return LevelRequirements(lists: 6, reviews: 50, totalContributions: 50);
      case ExpertiseLevel.national:
        return LevelRequirements(lists: 11, reviews: 100, totalContributions: 100);
      case ExpertiseLevel.global:
        return LevelRequirements(lists: 21, reviews: 200, totalContributions: 200);
      case ExpertiseLevel.universal:
        return LevelRequirements(lists: 50, reviews: 500, totalContributions: 500);
    }
  }

  /// Generate next steps for progress
  List<String> _generateNextSteps({
    required ExpertiseLevel currentLevel,
    required ExpertiseLevel nextLevel,
    required int currentLists,
    required int currentReviews,
    required LevelRequirements requirements,
  }) {
    final steps = <String>[];

    if (currentLists < requirements.lists) {
      final needed = requirements.lists - currentLists;
      steps.add('Create ${needed} more ${needed == 1 ? 'respected list' : 'respected lists'}');
    }

    if (currentReviews < requirements.reviews) {
      final needed = requirements.reviews - currentReviews;
      steps.add('Write ${needed} more ${needed == 1 ? 'thoughtful review' : 'thoughtful reviews'}');
    }

    if (steps.isEmpty) {
      steps.add('Build community trust through quality contributions');
      steps.add('Help others discover great spots');
    }

    return steps;
  }

  /// Check if user can earn pin for category
  bool canEarnPin({
    required String category,
    required int respectedListsCount,
    required int thoughtfulReviewsCount,
    required double communityTrustScore,
  }) {
    // Need at least 1 respected list OR 10 thoughtful reviews
    final hasMinimumContributions = respectedListsCount >= 1 || thoughtfulReviewsCount >= 10;
    final hasBasicTrust = communityTrustScore >= 0.5;

    return hasMinimumContributions && hasBasicTrust;
  }

  /// Get expertise story/narrative
  String getExpertiseStory({
    required String category,
    required ExpertiseLevel level,
    required int respectedListsCount,
    required int thoughtfulReviewsCount,
    String? location,
  }) {
    final locationText = location != null ? ' in $location' : '';
    
    if (respectedListsCount > 0 && thoughtfulReviewsCount > 0) {
      return 'Earned $category ${level.displayName} Level$locationText by creating $respectedListsCount respected lists and writing $thoughtfulReviewsCount thoughtful reviews.';
    } else if (respectedListsCount > 0) {
      return 'Earned $category ${level.displayName} Level$locationText by creating $respectedListsCount respected lists.';
    } else {
      return 'Earned $category ${level.displayName} Level$locationText by writing $thoughtfulReviewsCount thoughtful reviews.';
    }
  }

  /// Check if pin unlocks feature
  bool unlocksFeature(ExpertisePin pin, String feature) {
    return pin.unlockedFeatures.contains(feature);
  }

  /// Get unlocked features for level
  List<String> getUnlockedFeatures(ExpertiseLevel level) {
    final features = <String>[];

    if (level.index >= ExpertiseLevel.local.index) {
      features.add('event_hosting');
    }

    if (level.index >= ExpertiseLevel.regional.index) {
      features.add('expert_validation');
    }

    if (level.index >= ExpertiseLevel.national.index) {
      features.add('expert_curation');
    }

    if (level.index >= ExpertiseLevel.global.index) {
      features.add('community_leadership');
    }

    return features;
  }
}

/// Level requirements helper class
class LevelRequirements {
  final int lists;
  final int reviews;
  final int totalContributions;

  const LevelRequirements({
    required this.lists,
    required this.reviews,
    required this.totalContributions,
  });
}

