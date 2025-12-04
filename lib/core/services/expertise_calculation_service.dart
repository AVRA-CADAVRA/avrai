import 'package:spots/core/models/expertise_requirements.dart';
import 'package:spots/core/models/platform_phase.dart';
import 'package:spots/core/models/saturation_metrics.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/geographic_expansion.dart';
import 'package:spots/core/models/partnership_expertise_boost.dart';
import 'package:spots/core/services/saturation_algorithm_service.dart';
import 'package:spots/core/services/multi_path_expertise_service.dart';
import 'package:spots/core/services/partnership_profile_service.dart';
import 'package:spots/core/services/dynamic_threshold_service.dart';
import 'package:spots/core/services/logger.dart';

/// Expertise Calculation Service
/// 
/// Main service for calculating expertise using multi-path scoring
/// and dynamic thresholds that scale with platform growth.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to expertise recognition
/// - Scales requirements as platform grows
/// - Maintains quality through dynamic thresholds
/// - Supports multiple paths to expertise
/// 
/// **Features:**
/// - Multi-path scoring (6 paths, weighted)
/// - Dynamic threshold calculation (phase + saturation)
/// - Expertise level calculation
/// - Category expertise calculation
class ExpertiseCalculationService {
  static const String _logName = 'ExpertiseCalculationService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final SaturationAlgorithmService _saturationService;
  final MultiPathExpertiseService _multiPathService;
  final PartnershipProfileService? _partnershipProfileService;
  final DynamicThresholdService? _dynamicThresholdService;

  ExpertiseCalculationService({
    required SaturationAlgorithmService saturationService,
    required MultiPathExpertiseService multiPathService,
    PartnershipProfileService? partnershipProfileService,
    DynamicThresholdService? dynamicThresholdService,
  })  : _saturationService = saturationService,
        _multiPathService = multiPathService,
        _partnershipProfileService = partnershipProfileService,
        _dynamicThresholdService = dynamicThresholdService;

  /// Calculate overall expertise for a user in a category
  /// 
  /// **Flow:**
  /// 1. Get platform phase
  /// 2. Get saturation metrics for category
  /// 3. Calculate effective requirements (phase + saturation adjusted)
  /// 4. Apply locality-specific adjustments (if DynamicThresholdService available and locality provided)
  /// 5. Calculate all path scores
  /// 6. Calculate weighted total score
  /// 7. Determine expertise level
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category
  /// - `requirements`: Expertise requirements for category
  /// - `platformPhase`: Current platform phase
  /// - `saturationMetrics`: Saturation metrics for category
  /// - `pathExpertise`: All path expertise scores
  /// - `locality`: Optional locality for locality-specific threshold adjustment
  /// 
  /// **Returns:**
  /// ExpertiseCalculationResult with level and score
  Future<ExpertiseCalculationResult> calculateExpertise({
    required String userId,
    required String category,
    required ExpertiseRequirements requirements,
    required PlatformPhase platformPhase,
    required SaturationMetrics saturationMetrics,
    required MultiPathExpertiseScores pathExpertise,
    String? locality,
  }) async {
    try {
      _logger.info(
        'Calculating expertise: user=$userId, category=$category, locality=$locality',
        tag: _logName,
      );

      // Step 1: Get effective requirements (adjusted for phase + saturation)
      var effectiveThresholds = _getEffectiveRequirements(
        requirements: requirements,
        platformPhase: platformPhase,
        saturationMetrics: saturationMetrics,
      );

      // Step 1.5: Apply locality-specific adjustments if DynamicThresholdService available
      if (_dynamicThresholdService != null && locality != null && locality.isNotEmpty) {
        try {
          effectiveThresholds = await _dynamicThresholdService!.calculateLocalThreshold(
            locality: locality,
            category: category,
            baseThresholds: effectiveThresholds,
          );
          _logger.info(
            'Applied locality-specific threshold adjustments for $locality',
            tag: _logName,
          );
        } catch (e) {
          _logger.warning(
            'Error applying locality-specific thresholds, using base thresholds: $e',
            tag: _logName,
          );
          // Continue with base thresholds if locality adjustment fails
        }
      }

      // Step 2: Calculate partnership boost (if available)
      PartnershipExpertiseBoost? partnershipBoost;
      if (_partnershipProfileService != null) {
        try {
          partnershipBoost = await _partnershipProfileService!
              .getPartnershipExpertiseBoost(userId, category);
        } catch (e) {
          _logger.warning(
            'Error calculating partnership boost: $e',
            tag: _logName,
          );
        }
      }

      // Step 3: Calculate weighted total score from all paths (with partnership boost)
      final totalScore = _calculateWeightedTotalScore(
        pathExpertise,
        partnershipBoost: partnershipBoost,
      );

      // Step 4: Check if user meets requirements
      final meetsRequirements = _checkMeetsRequirements(
        pathExpertise: pathExpertise,
        requirements: effectiveThresholds,
      );

      // Step 5: Determine expertise level
      final expertiseLevel = _determineExpertiseLevel(
        totalScore: totalScore,
        meetsRequirements: meetsRequirements,
        requirements: effectiveThresholds,
      );

      // Step 6: Calculate progress to next level
      final progress = _calculateProgress(
        currentLevel: expertiseLevel,
        totalScore: totalScore,
        requirements: effectiveThresholds,
      );

      return ExpertiseCalculationResult(
        userId: userId,
        category: category,
        expertiseLevel: expertiseLevel,
        totalScore: totalScore,
        pathScores: pathExpertise,
        meetsRequirements: meetsRequirements,
        effectiveRequirements: effectiveThresholds,
        progress: progress,
        calculatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error calculating expertise', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get effective requirements (adjusted for phase + saturation)
  ThresholdValues _getEffectiveRequirements({
    required ExpertiseRequirements requirements,
    required PlatformPhase platformPhase,
    required SaturationMetrics saturationMetrics,
  }) {
    // Get base threshold values
    final baseThresholds = requirements.thresholdValues;

    // Get phase multiplier for category
    final phaseMultiplier = platformPhase.getCategoryMultiplier(requirements.category);

    // Get saturation multiplier
    final saturationMultiplier = saturationMetrics.getSaturationMultiplier();

    // Calculate total multiplier
    final totalMultiplier = phaseMultiplier * saturationMultiplier;

    // Apply multiplier to thresholds
    return baseThresholds.applyMultiplier(totalMultiplier);
  }

  /// Calculate weighted total score from all paths
  /// 
  /// **Path Weights:**
  /// - Exploration: 40%
  /// - Credentials: 25%
  /// - Influence: 20%
  /// - Professional: 25%
  /// - Community: 15%
  /// - Local: Varies (added to total if applicable)
  /// 
  /// **Partnership Boost Integration:**
  /// - Community Path: 60% of partnership boost
  /// - Professional Path: 30% of partnership boost
  /// - Influence Path: 10% of partnership boost
  double _calculateWeightedTotalScore(
    MultiPathExpertiseScores pathExpertise, {
    PartnershipExpertiseBoost? partnershipBoost,
  }) {
    double total = 0.0;

    // Exploration (40%)
    if (pathExpertise.exploration != null) {
      total += pathExpertise.exploration!.score * 0.40;
    }

    // Credentials (25%)
    if (pathExpertise.credential != null) {
      total += pathExpertise.credential!.score * 0.25;
    }

    // Influence (20%) + Partnership boost (10% of boost)
    if (pathExpertise.influence != null) {
      double influenceScore = pathExpertise.influence!.score * 0.20;
      if (partnershipBoost != null && partnershipBoost.hasBoost) {
        influenceScore += partnershipBoost.totalBoost * 0.10;
      }
      total += influenceScore;
    } else if (partnershipBoost != null && partnershipBoost.hasBoost) {
      // Add partnership boost to influence even if no influence path exists
      total += partnershipBoost.totalBoost * 0.10;
    }

    // Professional (25%) + Partnership boost (30% of boost)
    if (pathExpertise.professional != null) {
      double professionalScore = pathExpertise.professional!.score * 0.25;
      if (partnershipBoost != null && partnershipBoost.hasBoost) {
        professionalScore += partnershipBoost.totalBoost * 0.30;
      }
      total += professionalScore;
    } else if (partnershipBoost != null && partnershipBoost.hasBoost) {
      // Add partnership boost to professional even if no professional path exists
      total += partnershipBoost.totalBoost * 0.30;
    }

    // Community (15%) + Partnership boost (60% of boost)
    if (pathExpertise.community != null) {
      double communityScore = pathExpertise.community!.score * 0.15;
      if (partnershipBoost != null && partnershipBoost.hasBoost) {
        communityScore += partnershipBoost.totalBoost * 0.60;
      }
      total += communityScore;
    } else if (partnershipBoost != null && partnershipBoost.hasBoost) {
      // Add partnership boost to community even if no community path exists
      total += partnershipBoost.totalBoost * 0.60;
    }

    // Local (varies, bonus if applicable)
    if (pathExpertise.local != null) {
      // Local expertise adds bonus (up to 0.1)
      total += pathExpertise.local!.score * 0.10;
    }

    // Cap at 1.0
    return total.clamp(0.0, 1.0);
  }

  /// Calculate partnership boost for a user and category
  /// 
  /// Calculates the expertise boost from partnerships for a specific user and category.
  /// The boost is calculated based on partnership status, quality, category alignment,
  /// and partnership count, with a maximum cap of 0.50 (50%).
  /// 
  /// **Flow:**
  /// 1. Check if PartnershipProfileService is available
  /// 2. Get partnership boost from PartnershipProfileService
  /// 3. Return boost breakdown (or zero boost if service unavailable)
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category to calculate boost for
  /// 
  /// **Returns:**
  /// PartnershipExpertiseBoost with breakdown including:
  /// - Total boost amount (0.0 to 0.50 max)
  /// - Breakdown by status (active, completed, ongoing)
  /// - Breakdown by quality factors
  /// - Breakdown by category alignment
  /// - Partnership count and multiplier
  /// 
  /// **Note:**
  /// Returns zero boost if PartnershipProfileService is not available.
  /// This allows the service to work without partnership integration.
  Future<PartnershipExpertiseBoost> calculatePartnershipBoost({
    required String userId,
    required String category,
  }) async {
    try {
      if (_partnershipProfileService == null) {
        _logger.warning(
          'PartnershipProfileService not available',
          tag: _logName,
        );
        return const PartnershipExpertiseBoost(totalBoost: 0.0);
      }

      return await _partnershipProfileService!
          .getPartnershipExpertiseBoost(userId, category);
    } catch (e) {
      _logger.error(
        'Error calculating partnership boost',
        error: e,
        tag: _logName,
      );
      return const PartnershipExpertiseBoost(totalBoost: 0.0);
    }
  }

  /// Check if user meets requirements
  bool _checkMeetsRequirements({
    required MultiPathExpertiseScores pathExpertise,
    required ThresholdValues requirements,
  }) {
    // Check exploration path requirements
    if (pathExpertise.exploration != null) {
      final exploration = pathExpertise.exploration!;
      if (exploration.totalVisits < requirements.minVisits) {
        return false;
      }
      if (exploration.reviewsGiven < requirements.minRatings) {
        return false;
      }
      if (exploration.averageRating < requirements.minAvgRating) {
        return false;
      }
    }

    // Check community requirements if specified
    if (requirements.minCommunityEngagement != null &&
        pathExpertise.community != null) {
      final community = pathExpertise.community!;
      if (community.questionsAnswered < requirements.minCommunityEngagement!) {
        return false;
      }
    }

    // Check list curation if specified
    if (requirements.minListCuration != null &&
        pathExpertise.community != null) {
      final community = pathExpertise.community!;
      if (community.curatedLists < requirements.minListCuration!) {
        return false;
      }
    }

    // Check event hosting if specified
    if (requirements.minEventHosting != null &&
        pathExpertise.community != null) {
      final community = pathExpertise.community!;
      if (community.eventsHosted < requirements.minEventHosting!) {
        return false;
      }
    }

    return true;
  }

  /// Determine expertise level based on score and requirements
  ExpertiseLevel _determineExpertiseLevel({
    required double totalScore,
    required bool meetsRequirements,
    required ThresholdValues requirements,
  }) {
    // Must meet requirements to achieve any level
    if (!meetsRequirements) {
      return ExpertiseLevel.local; // Default starting level
    }

    // Determine level based on score
    if (totalScore >= 0.90) {
      return ExpertiseLevel.global;
    } else if (totalScore >= 0.75) {
      return ExpertiseLevel.national;
    } else if (totalScore >= 0.60) {
      return ExpertiseLevel.regional;
    } else if (totalScore >= 0.45) {
      return ExpertiseLevel.city;
    } else {
      return ExpertiseLevel.local;
    }
  }

  /// Calculate progress to next level
  double _calculateProgress({
    required ExpertiseLevel currentLevel,
    required double totalScore,
    required ThresholdValues requirements,
  }) {
    final nextLevel = currentLevel.nextLevel;
    if (nextLevel == null) {
      return 100.0; // Already at highest level
    }

    // Calculate score thresholds for levels
    final currentThreshold = _getScoreThreshold(currentLevel);
    final nextThreshold = _getScoreThreshold(nextLevel);

    if (nextThreshold <= currentThreshold) {
      return 100.0;
    }

    // Calculate progress percentage
    final progress = ((totalScore - currentThreshold) /
            (nextThreshold - currentThreshold) *
            100.0)
        .clamp(0.0, 100.0);

    return progress;
  }

  /// Get score threshold for expertise level
  double _getScoreThreshold(ExpertiseLevel level) {
    switch (level) {
      case ExpertiseLevel.local:
        return 0.0;
      case ExpertiseLevel.city:
        return 0.45;
      case ExpertiseLevel.regional:
        return 0.60;
      case ExpertiseLevel.national:
        return 0.75;
      case ExpertiseLevel.global:
        return 0.90;
      case ExpertiseLevel.universal:
        return 1.0;
    }
  }

  /// Calculate expertise from geographic expansion
  /// 
  /// Calculates expertise level based on geographic expansion (75% coverage rule).
  /// 
  /// **Philosophy Alignment:**
  /// - Clubs/communities can expand naturally (doors open through growth)
  /// - 75% coverage rule enables expertise gain at each geographic level
  /// - Geographic expansion enabled (locality → universe)
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category for expertise
  /// - `expansion`: Geographic expansion to check
  /// 
  /// **Returns:**
  /// Expertise level based on expansion, or null if no expansion expertise
  /// 
  /// **Note:** This method is used by ExpansionExpertiseGainService to determine
  /// expertise level from expansion. It preserves existing expertise calculation
  /// logic while adding expansion-based expertise.
  Future<ExpertiseLevel?> calculateExpertiseFromExpansion({
    required String userId,
    required String category,
    required GeographicExpansion expansion,
  }) async {
    try {
      _logger.info(
        'Calculating expertise from expansion: user=$userId, category=$category, club=${expansion.clubId}',
        tag: _logName,
      );

      // Check expansion thresholds and determine expertise level
      // This integrates with ExpansionExpertiseGainService logic
      
      // Check global threshold first (highest level)
      if (expansion.hasReachedGlobalThreshold()) {
        // Check if expansion has coverage in multiple nations (universal check)
        if (expansion.expandedNations.length >= 3) {
          return ExpertiseLevel.universal;
        }
        return ExpertiseLevel.global;
      }

      // Check nation threshold
      for (final nation in expansion.expandedNations) {
        if (expansion.hasReachedNationThreshold(nation)) {
          return ExpertiseLevel.national;
        }
      }

      // Check state threshold
      for (final state in expansion.expandedStates) {
        if (expansion.hasReachedStateThreshold(state)) {
          return ExpertiseLevel.regional; // regional = state level
        }
      }

      // Check city threshold
      for (final city in expansion.expandedCities) {
        if (expansion.hasReachedCityThreshold(city)) {
          return ExpertiseLevel.city;
        }
      }

      // Check locality threshold
      if (expansion.hasReachedLocalityThreshold()) {
        return ExpertiseLevel.local;
      }

      // No expansion expertise
      return null;
    } catch (e) {
      _logger.error('Error calculating expertise from expansion', error: e, tag: _logName);
      return null;
    }
  }
}

/// Multi-Path Expertise Scores
/// Container for all path expertise scores
class MultiPathExpertiseScores {
  final ExplorationExpertise? exploration;
  final CredentialExpertise? credential;
  final InfluenceExpertise? influence;
  final ProfessionalExpertise? professional;
  final CommunityExpertise? community;
  final LocalExpertise? local;

  const MultiPathExpertiseScores({
    this.exploration,
    this.credential,
    this.influence,
    this.professional,
    this.community,
    this.local,
  });
}

/// Expertise Calculation Result
/// Result of expertise calculation
class ExpertiseCalculationResult {
  final String userId;
  final String category;
  final ExpertiseLevel expertiseLevel;
  final double totalScore;
  final MultiPathExpertiseScores pathScores;
  final bool meetsRequirements;
  final ThresholdValues effectiveRequirements;
  final double progress; // Progress to next level (0-100)
  final DateTime calculatedAt;

  const ExpertiseCalculationResult({
    required this.userId,
    required this.category,
    required this.expertiseLevel,
    required this.totalScore,
    required this.pathScores,
    required this.meetsRequirements,
    required this.effectiveRequirements,
    required this.progress,
    required this.calculatedAt,
  });
}

