import 'package:equatable/equatable.dart';

/// Saturation Metrics Model
/// 
/// Represents the saturation analysis for a category using a sophisticated
/// 6-factor model to determine if expertise requirements should be adjusted.
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
class SaturationMetrics extends Equatable {
  /// Category this metric is for
  final String category;
  
  /// Current expert count
  final int currentExpertCount;
  
  /// Total user count
  final int totalUserCount;
  
  /// Saturation ratio (experts / users)
  final double saturationRatio;
  
  /// Quality score (0.0 to 1.0)
  final double qualityScore;
  
  /// Growth rate (experts per month)
  final double growthRate;
  
  /// Competition level (0.0 to 1.0)
  final double competitionLevel;
  
  /// Market demand (0.0 to 1.0)
  final double marketDemand;
  
  /// Six-factor breakdown
  final SaturationFactors factors;
  
  /// Overall saturation score (0.0 to 1.0)
  final double saturationScore;
  
  /// Recommendation (increase/decrease/maintain requirements)
  final SaturationRecommendation recommendation;
  
  /// Metadata
  final DateTime calculatedAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const SaturationMetrics({
    required this.category,
    required this.currentExpertCount,
    required this.totalUserCount,
    required this.saturationRatio,
    required this.qualityScore,
    required this.growthRate,
    required this.competitionLevel,
    required this.marketDemand,
    required this.factors,
    required this.saturationScore,
    required this.recommendation,
    required this.calculatedAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Get saturation multiplier for requirements
  /// Returns multiplier to apply to base requirements
  double getSaturationMultiplier() {
    // Low saturation (<1%): Reduce requirements (0.8x)
    if (saturationRatio < 0.01) {
      return 0.8;
    }
    // Medium saturation (1-2%): Normal requirements (1.0x)
    else if (saturationRatio < 0.02) {
      return 1.0;
    }
    // High saturation (2-3%): Increase requirements (1.5x)
    else if (saturationRatio < 0.03) {
      return 1.5;
    }
    // Very high saturation (>3%): Significantly increase (2.0x)
    else {
      return 2.0;
    }
  }

  /// Check if category is oversaturated
  bool get isOversaturated => saturationScore > 0.7;

  /// Check if category needs more experts
  bool get needsMoreExperts => saturationScore < 0.3 && marketDemand > 0.5;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'currentExpertCount': currentExpertCount,
      'totalUserCount': totalUserCount,
      'saturationRatio': saturationRatio,
      'qualityScore': qualityScore,
      'growthRate': growthRate,
      'competitionLevel': competitionLevel,
      'marketDemand': marketDemand,
      'factors': factors.toJson(),
      'saturationScore': saturationScore,
      'recommendation': recommendation.name,
      'calculatedAt': calculatedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory SaturationMetrics.fromJson(Map<String, dynamic> json) {
    return SaturationMetrics(
      category: json['category'] as String,
      currentExpertCount: json['currentExpertCount'] as int,
      totalUserCount: json['totalUserCount'] as int,
      saturationRatio: (json['saturationRatio'] as num).toDouble(),
      qualityScore: (json['qualityScore'] as num).toDouble(),
      growthRate: (json['growthRate'] as num).toDouble(),
      competitionLevel: (json['competitionLevel'] as num).toDouble(),
      marketDemand: (json['marketDemand'] as num).toDouble(),
      factors: SaturationFactors.fromJson(
        json['factors'] as Map<String, dynamic>,
      ),
      saturationScore: (json['saturationScore'] as num).toDouble(),
      recommendation: SaturationRecommendationExtension.fromString(
        json['recommendation'] as String? ?? 'maintain',
      ),
      calculatedAt: DateTime.parse(json['calculatedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Copy with method
  SaturationMetrics copyWith({
    String? category,
    int? currentExpertCount,
    int? totalUserCount,
    double? saturationRatio,
    double? qualityScore,
    double? growthRate,
    double? competitionLevel,
    double? marketDemand,
    SaturationFactors? factors,
    double? saturationScore,
    SaturationRecommendation? recommendation,
    DateTime? calculatedAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return SaturationMetrics(
      category: category ?? this.category,
      currentExpertCount: currentExpertCount ?? this.currentExpertCount,
      totalUserCount: totalUserCount ?? this.totalUserCount,
      saturationRatio: saturationRatio ?? this.saturationRatio,
      qualityScore: qualityScore ?? this.qualityScore,
      growthRate: growthRate ?? this.growthRate,
      competitionLevel: competitionLevel ?? this.competitionLevel,
      marketDemand: marketDemand ?? this.marketDemand,
      factors: factors ?? this.factors,
      saturationScore: saturationScore ?? this.saturationScore,
      recommendation: recommendation ?? this.recommendation,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        category,
        currentExpertCount,
        totalUserCount,
        saturationRatio,
        qualityScore,
        growthRate,
        competitionLevel,
        marketDemand,
        factors,
        saturationScore,
        recommendation,
        calculatedAt,
        updatedAt,
        metadata,
      ];
}

/// Saturation Factors (6-factor breakdown)
class SaturationFactors extends Equatable {
  /// Factor 1: Supply Ratio (25% weight)
  final double supplyRatio;
  
  /// Factor 2: Quality Distribution (20% weight)
  final double qualityDistribution;
  
  /// Factor 3: Utilization Rate (20% weight)
  final double utilizationRate;
  
  /// Factor 4: Demand Signal (15% weight)
  final double demandSignal;
  
  /// Factor 5: Growth Velocity (10% weight)
  final double growthVelocity;
  
  /// Factor 6: Geographic Distribution (10% weight)
  final double geographicDistribution;

  const SaturationFactors({
    required this.supplyRatio,
    required this.qualityDistribution,
    required this.utilizationRate,
    required this.demandSignal,
    required this.growthVelocity,
    required this.geographicDistribution,
  });

  /// Calculate overall saturation score from factors
  double calculateSaturationScore() {
    return (supplyRatio * 0.25) +
        ((1 - qualityDistribution) * 0.20) +
        ((1 - utilizationRate) * 0.20) +
        ((1 - demandSignal) * 0.15) +
        (growthVelocity * 0.10) +
        (geographicDistribution * 0.10);
  }

  Map<String, dynamic> toJson() {
    return {
      'supplyRatio': supplyRatio,
      'qualityDistribution': qualityDistribution,
      'utilizationRate': utilizationRate,
      'demandSignal': demandSignal,
      'growthVelocity': growthVelocity,
      'geographicDistribution': geographicDistribution,
    };
  }

  factory SaturationFactors.fromJson(Map<String, dynamic> json) {
    return SaturationFactors(
      supplyRatio: (json['supplyRatio'] as num).toDouble(),
      qualityDistribution: (json['qualityDistribution'] as num).toDouble(),
      utilizationRate: (json['utilizationRate'] as num).toDouble(),
      demandSignal: (json['demandSignal'] as num).toDouble(),
      growthVelocity: (json['growthVelocity'] as num).toDouble(),
      geographicDistribution:
          (json['geographicDistribution'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        supplyRatio,
        qualityDistribution,
        utilizationRate,
        demandSignal,
        growthVelocity,
        geographicDistribution,
      ];
}

/// Saturation Recommendation
enum SaturationRecommendation {
  decrease,  // Reduce requirements (low saturation)
  maintain,  // Keep current requirements
  increase,  // Increase requirements (high saturation)
  significantIncrease, // Significantly increase (very high saturation)
}

extension SaturationRecommendationExtension on SaturationRecommendation {
  String get displayName {
    switch (this) {
      case SaturationRecommendation.decrease:
        return 'Decrease Requirements';
      case SaturationRecommendation.maintain:
        return 'Maintain Requirements';
      case SaturationRecommendation.increase:
        return 'Increase Requirements';
      case SaturationRecommendation.significantIncrease:
        return 'Significantly Increase Requirements';
    }
  }

  static SaturationRecommendation fromString(String? value) {
    if (value == null) return SaturationRecommendation.maintain;
    switch (value.toLowerCase()) {
      case 'decrease':
        return SaturationRecommendation.decrease;
      case 'maintain':
        return SaturationRecommendation.maintain;
      case 'increase':
        return SaturationRecommendation.increase;
      case 'significantincrease':
      case 'significant_increase':
        return SaturationRecommendation.significantIncrease;
      default:
        return SaturationRecommendation.maintain;
    }
  }
}

