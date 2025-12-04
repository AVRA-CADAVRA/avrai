import 'dart:developer' as developer;
import 'package:spots/core/models/saturation_metrics.dart';
import 'package:spots/core/models/platform_phase.dart';
import 'package:spots/core/services/logger.dart';

/// Saturation Algorithm Service
/// 
/// Implements sophisticated 6-factor saturation analysis to determine
/// if expertise requirements should be adjusted for a category.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to expertise recognition
/// - Maintains quality through sophisticated analysis
/// - Prevents oversaturation while allowing growth
/// 
/// **Six Factors:**
/// 1. Supply Ratio (25%): How many experts exist
/// 2. Quality Distribution (20%): Are experts actually good?
/// 3. Utilization Rate (20%): Are experts being used?
/// 4. Demand Signal (15%): Do users want more?
/// 5. Growth Velocity (10%): Is growth healthy?
/// 6. Geographic Distribution (10%): Are experts clustered or spread?
class SaturationAlgorithmService {
  static const String _logName = 'SaturationAlgorithmService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  /// Analyze saturation for a category using 6-factor model
  /// 
  /// **Flow:**
  /// 1. Calculate supply ratio (experts / users)
  /// 2. Analyze quality distribution
  /// 3. Calculate utilization rate
  /// 4. Analyze demand signal
  /// 5. Calculate growth velocity
  /// 6. Analyze geographic distribution
  /// 7. Combine into saturation score
  /// 8. Generate recommendation
  /// 
  /// **Parameters:**
  /// - `category`: Category to analyze
  /// - `currentExpertCount`: Current number of experts
  /// - `totalUserCount`: Total number of users
  /// - `qualityMetrics`: Quality metrics for experts
  /// - `utilizationMetrics`: Utilization metrics
  /// - `demandMetrics`: Demand signal metrics
  /// - `growthMetrics`: Growth velocity metrics
  /// - `geographicMetrics`: Geographic distribution metrics
  /// 
  /// **Returns:**
  /// SaturationMetrics with 6-factor analysis
  Future<SaturationMetrics> analyzeCategorySaturation({
    required String category,
    required int currentExpertCount,
    required int totalUserCount,
    required QualityMetrics qualityMetrics,
    required UtilizationMetrics utilizationMetrics,
    required DemandMetrics demandMetrics,
    required GrowthMetrics growthMetrics,
    required GeographicMetrics geographicMetrics,
  }) async {
    try {
      _logger.info('Analyzing saturation for category: $category', tag: _logName);

      // Step 1: Calculate supply ratio
      final supplyRatio = _calculateSupplyRatio(
        currentExpertCount,
        totalUserCount,
      );

      // Step 2: Analyze quality distribution
      final qualityDistribution = _analyzeQualityDistribution(qualityMetrics);

      // Step 3: Calculate utilization rate
      final utilizationRate = _calculateUtilizationRate(utilizationMetrics);

      // Step 4: Analyze demand signal
      final demandSignal = _analyzeDemandSignal(demandMetrics);

      // Step 5: Calculate growth velocity
      final growthVelocity = _calculateGrowthVelocity(growthMetrics);

      // Step 6: Analyze geographic distribution
      final geographicDistribution =
          _analyzeGeographicDistribution(geographicMetrics);

      // Step 7: Create saturation factors
      final factors = SaturationFactors(
        supplyRatio: supplyRatio,
        qualityDistribution: qualityDistribution,
        utilizationRate: utilizationRate,
        demandSignal: demandSignal,
        growthVelocity: growthVelocity,
        geographicDistribution: geographicDistribution,
      );

      // Step 8: Calculate overall saturation score
      final saturationScore = factors.calculateSaturationScore();

      // Step 9: Calculate quality score (average of quality metrics)
      final qualityScore = qualityDistribution;

      // Step 10: Calculate growth rate (experts per month)
      final growthRate = growthMetrics.expertsPerMonth.toDouble();

      // Step 11: Calculate competition level (inverse of demand)
      final competitionLevel = 1.0 - demandSignal;

      // Step 12: Generate recommendation
      final recommendation = _generateRecommendation(saturationScore);

      final metrics = SaturationMetrics(
        category: category,
        currentExpertCount: currentExpertCount,
        totalUserCount: totalUserCount,
        saturationRatio: supplyRatio,
        qualityScore: qualityScore,
        growthRate: growthRate,
        competitionLevel: competitionLevel,
        marketDemand: demandSignal,
        factors: factors,
        saturationScore: saturationScore,
        recommendation: recommendation,
        calculatedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _logger.info(
        'Saturation analysis complete: score=${saturationScore.toStringAsFixed(2)}, recommendation=${recommendation.name}',
        tag: _logName,
      );

      return metrics;
    } catch (e) {
      _logger.error('Error analyzing saturation', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate supply ratio (Factor 1: 25% weight)
  /// 
  /// Formula: experts / users
  /// Target: 2% (0.02)
  /// Score: 0.0 (low) to 1.0 (high saturation)
  double _calculateSupplyRatio(int expertCount, int userCount) {
    if (userCount == 0) return 0.0;

    final ratio = expertCount / userCount;
    // Normalize to 0-1 scale (2% = 1.0, 0% = 0.0)
    return (ratio / 0.02).clamp(0.0, 1.0);
  }

  /// Analyze quality distribution (Factor 2: 20% weight)
  /// 
  /// Measures if experts are actually good.
  /// Based on average ratings, engagement, verification status.
  /// 
  /// Score: 0.0 (low quality) to 1.0 (high quality)
  double _analyzeQualityDistribution(QualityMetrics metrics) {
    // Weighted average of quality indicators
    final ratingScore = metrics.averageExpertRating / 5.0; // Normalize to 0-1
    final engagementScore = metrics.averageEngagementRate;
    final verificationScore = metrics.verifiedExpertRatio;

    return (ratingScore * 0.4) +
        (engagementScore * 0.4) +
        (verificationScore * 0.2);
  }

  /// Calculate utilization rate (Factor 3: 20% weight)
  /// 
  /// Measures if experts are being used.
  /// Based on event hosting, consultation requests, engagement.
  /// 
  /// Score: 0.0 (low utilization) to 1.0 (high utilization)
  double _calculateUtilizationRate(UtilizationMetrics metrics) {
    if (metrics.totalExperts == 0) return 0.0;

    final activeExpertRatio = metrics.activeExperts / metrics.totalExperts;
    final averageEventsPerExpert = metrics.totalEvents / metrics.totalExperts;
    final averageConsultationsPerExpert =
        metrics.totalConsultations / metrics.totalExperts;

    // Normalize events and consultations (target: 5 events, 10 consultations)
    final eventsScore = (averageEventsPerExpert / 5.0).clamp(0.0, 1.0);
    final consultationsScore =
        (averageConsultationsPerExpert / 10.0).clamp(0.0, 1.0);

    return (activeExpertRatio * 0.5) +
        (eventsScore * 0.3) +
        (consultationsScore * 0.2);
  }

  /// Analyze demand signal (Factor 4: 15% weight)
  /// 
  /// Measures if users want more experts.
  /// Based on search queries, consultation requests, wait times.
  /// 
  /// Score: 0.0 (low demand) to 1.0 (high demand)
  double _analyzeDemandSignal(DemandMetrics metrics) {
    // Normalize metrics to 0-1 scale
    final searchQueryScore =
        (metrics.expertSearchQueries / metrics.totalSearchQueries)
            .clamp(0.0, 1.0);
    final consultationRequestScore =
        (metrics.consultationRequests / metrics.totalUsers).clamp(0.0, 1.0);
    final waitTimeScore = 1.0 -
        (metrics.averageWaitTimeDays / 30.0).clamp(0.0, 1.0); // Inverse

    return (searchQueryScore * 0.4) +
        (consultationRequestScore * 0.4) +
        (waitTimeScore * 0.2);
  }

  /// Calculate growth velocity (Factor 5: 10% weight)
  /// 
  /// Measures if expert growth is healthy.
  /// Based on rate of expert creation, stability.
  /// 
  /// Score: 0.0 (stable) to 1.0 (unstable/rapid growth)
  double _calculateGrowthVelocity(GrowthMetrics metrics) {
    // High growth rate = potential oversaturation risk
    final growthRate = metrics.expertsPerMonth / metrics.totalExperts;
    // Normalize (target: 5% per month = 0.5 score)
    return (growthRate / 0.10).clamp(0.0, 1.0);
  }

  /// Analyze geographic distribution (Factor 6: 10% weight)
  /// 
  /// Measures if experts are clustered or spread.
  /// Based on geographic spread, city coverage.
  /// 
  /// Score: 0.0 (well-distributed) to 1.0 (clustered)
  double _analyzeGeographicDistribution(GeographicMetrics metrics) {
    if (metrics.totalCities == 0) return 0.0;

    // Calculate clustering score (higher = more clustered)
    final expertsPerCity = metrics.totalExperts / metrics.totalCities;
    final averageCityCoverage = metrics.citiesWithExperts / metrics.totalCities;

    // More experts per city = more clustered
    final clusteringScore = (expertsPerCity / 10.0).clamp(0.0, 1.0);
    // Lower coverage = more clustered
    final coverageScore = 1.0 - averageCityCoverage;

    return (clusteringScore * 0.6) + (coverageScore * 0.4);
  }

  /// Generate recommendation based on saturation score
  SaturationRecommendation _generateRecommendation(double saturationScore) {
    if (saturationScore < 0.3) {
      return SaturationRecommendation.decrease; // Low saturation
    } else if (saturationScore < 0.5) {
      return SaturationRecommendation.maintain; // Healthy saturation
    } else if (saturationScore < 0.7) {
      return SaturationRecommendation.increase; // High saturation
    } else {
      return SaturationRecommendation.significantIncrease; // Very high saturation
    }
  }

  /// Get saturation multiplier for requirements
  /// 
  /// Returns multiplier to apply to base requirements based on saturation.
  double getSaturationMultiplier(SaturationMetrics metrics) {
    return metrics.getSaturationMultiplier();
  }
}

/// Quality Metrics
/// Metrics for analyzing expert quality
class QualityMetrics {
  final double averageExpertRating; // 0-5
  final double averageEngagementRate; // 0-1
  final double verifiedExpertRatio; // 0-1

  const QualityMetrics({
    required this.averageExpertRating,
    required this.averageEngagementRate,
    required this.verifiedExpertRatio,
  });
}

/// Utilization Metrics
/// Metrics for analyzing expert utilization
class UtilizationMetrics {
  final int totalExperts;
  final int activeExperts; // Active in last 30 days
  final int totalEvents; // Events hosted by experts
  final int totalConsultations; // Consultation requests fulfilled

  const UtilizationMetrics({
    required this.totalExperts,
    required this.activeExperts,
    required this.totalEvents,
    required this.totalConsultations,
  });
}

/// Demand Metrics
/// Metrics for analyzing user demand
class DemandMetrics {
  final int expertSearchQueries; // Searches for experts
  final int totalSearchQueries; // Total searches
  final int consultationRequests; // Requests for expert consultations
  final int totalUsers;
  final double averageWaitTimeDays; // Average wait time for consultations

  const DemandMetrics({
    required this.expertSearchQueries,
    required this.totalSearchQueries,
    required this.consultationRequests,
    required this.totalUsers,
    required this.averageWaitTimeDays,
  });
}

/// Growth Metrics
/// Metrics for analyzing expert growth
class GrowthMetrics {
  final int expertsPerMonth; // New experts per month
  final int totalExperts; // Total experts

  const GrowthMetrics({
    required this.expertsPerMonth,
    required this.totalExperts,
  });
}

/// Geographic Metrics
/// Metrics for analyzing geographic distribution
class GeographicMetrics {
  final int totalExperts;
  final int totalCities; // Total cities in platform
  final int citiesWithExperts; // Cities with at least one expert

  const GeographicMetrics({
    required this.totalExperts,
    required this.totalCities,
    required this.citiesWithExperts,
  });
}


