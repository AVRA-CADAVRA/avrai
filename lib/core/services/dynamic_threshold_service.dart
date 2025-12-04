import 'package:spots/core/models/expertise_requirements.dart';
import 'package:spots/core/services/locality_value_analysis_service.dart';
import 'package:spots/core/services/logger.dart';

/// Dynamic Threshold Service
/// 
/// Calculates locality-specific thresholds for local expert qualification.
/// Thresholds adapt to what each locality actually values, enabling lower
/// thresholds for activities valued by the locality and higher thresholds
/// for activities less valued by the locality.
/// 
/// **Philosophy:** Local experts shouldn't have to expand past their locality
/// to be qualified. Thresholds ebb and flow based on locality data, adapting
/// to what the community actually values.
/// 
/// **How This Works:**
/// - Gets base thresholds from ExpertiseRequirements
/// - Gets activity weights from LocalityValueAnalysisService
/// - Applies locality-specific adjustments based on activity weights
/// - Lower thresholds for activities valued by locality
/// - Higher thresholds for activities less valued by locality
/// - Thresholds update dynamically as locality behavior changes
class DynamicThresholdService {
  static const String _logName = 'DynamicThresholdService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final LocalityValueAnalysisService _localityValueService;

  DynamicThresholdService({
    LocalityValueAnalysisService? localityValueService,
  }) : _localityValueService =
            localityValueService ?? LocalityValueAnalysisService();

  /// Calculate locality-specific threshold for local expert qualification
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// - `category`: Expertise category
  /// - `baseThresholds`: Base threshold values (after phase + saturation adjustments)
  /// 
  /// **Returns:**
  /// ThresholdValues adjusted for locality-specific values
  /// 
  /// **Adjustment Logic:**
  /// - Activities valued by locality (high weight) → Lower threshold (easier)
  /// - Activities less valued by locality (low weight) → Higher threshold (harder)
  /// - Adjustment range: 0.7x to 1.3x multiplier (30% reduction to 30% increase)
  Future<ThresholdValues> calculateLocalThreshold({
    required String locality,
    required String category,
    required ThresholdValues baseThresholds,
  }) async {
    try {
      _logger.info(
        'Calculating local threshold: locality=$locality, category=$category',
        tag: _logName,
      );

      // Get locality-specific activity weights
      final activityWeights = await _localityValueService.getCategoryPreferences(
        locality,
        category,
      );

      // Calculate adjustments for each threshold based on activity weights
      final adjustedThresholds = _applyLocalityAdjustments(
        baseThresholds: baseThresholds,
        activityWeights: activityWeights,
      );

      _logger.info(
        'Calculated local threshold for $locality/$category',
        tag: _logName,
      );

      return adjustedThresholds;
    } catch (e) {
      _logger.error(
        'Error calculating local threshold',
        error: e,
        tag: _logName,
      );
      // Return base thresholds on error (no locality adjustment)
      return baseThresholds;
    }
  }

  /// Get threshold for a specific activity in a locality
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// - `activity`: Activity type (events_hosted, lists_created, reviews_written, etc.)
  /// - `baseThreshold`: Base threshold value for the activity
  /// 
  /// **Returns:**
  /// Adjusted threshold value based on locality's value for this activity
  /// 
  /// **Example:**
  /// - If locality values "events_hosted" highly (0.3 weight), threshold is 0.7x (30% lower)
  /// - If locality values "events_hosted" low (0.1 weight), threshold is 1.3x (30% higher)
  Future<double> getThresholdForActivity({
    required String locality,
    required String activity,
    required double baseThreshold,
  }) async {
    try {
      _logger.info(
        'Getting threshold for activity: locality=$locality, activity=$activity',
        tag: _logName,
      );

      // Get activity weights for locality
      final activityWeights = await _localityValueService.getActivityWeights(locality);

      // Get weight for this activity (default to 0.167 if not found - equal weight)
      final activityWeight = activityWeights[activity] ?? 0.167;

      // Calculate adjustment multiplier
      // Higher weight (more valued) → Lower threshold (easier)
      // Lower weight (less valued) → Higher threshold (harder)
      // Adjustment range: 0.7x to 1.3x (30% reduction to 30% increase)
      final adjustment = _calculateActivityAdjustment(activityWeight);

      final adjustedThreshold = baseThreshold * adjustment;

      _logger.info(
        'Activity threshold: base=$baseThreshold, weight=$activityWeight, adjustment=$adjustment, adjusted=$adjustedThreshold',
        tag: _logName,
      );

      return adjustedThreshold;
    } catch (e) {
      _logger.error(
        'Error getting threshold for activity',
        error: e,
        tag: _logName,
      );
      // Return base threshold on error
      return baseThreshold;
    }
  }

  /// Calculate threshold adjustment based on activity weight
  /// 
  /// **Formula:**
  /// - Weight 0.0-0.1 (low value) → 1.3x multiplier (30% higher threshold)
  /// - Weight 0.1-0.2 (medium-low) → 1.15x multiplier (15% higher threshold)
  /// - Weight 0.2-0.25 (medium) → 1.0x multiplier (no change)
  /// - Weight 0.25-0.3 (medium-high) → 0.85x multiplier (15% lower threshold)
  /// - Weight 0.3+ (high value) → 0.7x multiplier (30% lower threshold)
  /// 
  /// **Parameters:**
  /// - `activityWeight`: Weight of activity (0.0 to 1.0)
  /// 
  /// **Returns:**
  /// Adjustment multiplier (0.7 to 1.3)
  double _calculateActivityAdjustment(double activityWeight) {
    if (activityWeight >= 0.3) {
      // High value → Lower threshold (easier)
      return 0.7;
    } else if (activityWeight >= 0.25) {
      // Medium-high value → Slightly lower threshold
      return 0.85;
    } else if (activityWeight >= 0.2) {
      // Medium value → No change
      return 1.0;
    } else if (activityWeight >= 0.1) {
      // Medium-low value → Slightly higher threshold
      return 1.15;
    } else {
      // Low value → Higher threshold (harder)
      return 1.3;
    }
  }

  /// Apply locality adjustments to threshold values
  /// 
  /// Adjusts each threshold component based on locality's activity weights.
  /// 
  /// **Adjustments:**
  /// - `minVisits`: Based on "event_attendance" weight
  /// - `minRatings`: Based on "reviews_written" weight
  /// - `minEventHosting`: Based on "events_hosted" weight
  /// - `minListCuration`: Based on "lists_created" weight
  /// - `minCommunityEngagement`: Based on "positive_trends" weight
  /// 
  /// **Parameters:**
  /// - `baseThresholds`: Base threshold values
  /// - `activityWeights`: Activity weights from locality analysis
  /// 
  /// **Returns:**
  /// Adjusted threshold values
  ThresholdValues _applyLocalityAdjustments({
    required ThresholdValues baseThresholds,
    required Map<String, double> activityWeights,
  }) {
    // Calculate adjustments for each component
    final visitsAdjustment = _calculateActivityAdjustment(
      activityWeights['event_attendance'] ?? 0.167,
    );
    final ratingsAdjustment = _calculateActivityAdjustment(
      activityWeights['reviews_written'] ?? 0.167,
    );
    final eventHostingAdjustment = _calculateActivityAdjustment(
      activityWeights['events_hosted'] ?? 0.167,
    );
    final listCurationAdjustment = _calculateActivityAdjustment(
      activityWeights['lists_created'] ?? 0.167,
    );
    final communityEngagementAdjustment = _calculateActivityAdjustment(
      activityWeights['positive_trends'] ?? 0.167,
    );

    // Apply adjustments to thresholds
    // Note: minAvgRating and minTimeInCategory don't scale (quality/time don't change)
    return ThresholdValues(
      minVisits: (baseThresholds.minVisits * visitsAdjustment).ceil(),
      minRatings: (baseThresholds.minRatings * ratingsAdjustment).ceil(),
      minAvgRating: baseThresholds.minAvgRating, // Rating doesn't scale
      minTimeInCategory: baseThresholds.minTimeInCategory, // Time doesn't scale
      minCommunityEngagement: baseThresholds.minCommunityEngagement != null
          ? (baseThresholds.minCommunityEngagement! * communityEngagementAdjustment).ceil()
          : null,
      minListCuration: baseThresholds.minListCuration != null
          ? (baseThresholds.minListCuration! * listCurationAdjustment).ceil()
          : null,
      minEventHosting: baseThresholds.minEventHosting != null
          ? (baseThresholds.minEventHosting! * eventHostingAdjustment).ceil()
          : null,
    );
  }

  /// Get locality-specific threshold multiplier
  /// 
  /// Returns a multiplier that can be applied to base thresholds to get
  /// locality-specific thresholds. This is useful for integration with
  /// existing threshold calculation systems.
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// - `category`: Expertise category
  /// 
  /// **Returns:**
  /// Multiplier (0.7 to 1.3) to apply to base thresholds
  /// 
  /// **Note:** This is a simplified version. For full threshold calculation,
  /// use `calculateLocalThreshold()` which adjusts each component individually.
  Future<double> getLocalityMultiplier({
    required String locality,
    required String category,
  }) async {
    try {
      final activityWeights = await _localityValueService.getCategoryPreferences(
        locality,
        category,
      );

      // Calculate average weight
      final averageWeight = activityWeights.values.isEmpty
          ? 0.167
          : activityWeights.values.reduce((a, b) => a + b) / activityWeights.length;

      // Return adjustment multiplier
      return _calculateActivityAdjustment(averageWeight);
    } catch (e) {
      _logger.error(
        'Error getting locality multiplier',
        error: e,
        tag: _logName,
      );
      // Return 1.0 (no adjustment) on error
      return 1.0;
    }
  }
}
