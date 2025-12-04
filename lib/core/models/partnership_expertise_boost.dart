import 'package:equatable/equatable.dart';

/// Partnership Expertise Boost Model
/// 
/// Represents the expertise boost calculation from partnerships.
/// Contains breakdown of boost by status, quality, category alignment, and count multiplier.
/// 
/// **Philosophy Alignment:**
/// - Recognizes authentic professional collaborations
/// - Rewards successful partnerships with expertise recognition
/// - Opens doors to expertise growth through partnerships
class PartnershipExpertiseBoost extends Equatable {
  /// Total boost amount (0.0 to 0.50 max)
  final double totalBoost;
  
  /// Breakdown by status
  final double activeBoost;      // From active partnerships
  final double completedBoost;     // From completed partnerships
  final double ongoingBoost;      // From ongoing partnerships
  
  /// Breakdown by quality factors
  final double vibeCompatibilityBoost;  // High vibe compatibility bonus
  final double revenueSuccessBoost;     // Successful revenue share bonus
  final double feedbackBoost;          // Positive feedback bonus
  
  /// Breakdown by category alignment
  final double sameCategoryBoost;       // Same category partnerships
  final double relatedCategoryBoost;    // Related category partnerships
  final double unrelatedCategoryBoost;  // Unrelated category partnerships
  
  /// Partnership count multiplier applied
  final double countMultiplier;
  
  /// Number of partnerships contributing to boost
  final int partnershipCount;

  const PartnershipExpertiseBoost({
    required this.totalBoost,
    this.activeBoost = 0.0,
    this.completedBoost = 0.0,
    this.ongoingBoost = 0.0,
    this.vibeCompatibilityBoost = 0.0,
    this.revenueSuccessBoost = 0.0,
    this.feedbackBoost = 0.0,
    this.sameCategoryBoost = 0.0,
    this.relatedCategoryBoost = 0.0,
    this.unrelatedCategoryBoost = 0.0,
    this.countMultiplier = 1.0,
    this.partnershipCount = 0,
  });

  /// Check if boost is zero
  bool get hasBoost => totalBoost > 0.0;

  /// Get boost percentage (0-50%)
  double get boostPercentage => totalBoost * 100;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'totalBoost': totalBoost,
      'activeBoost': activeBoost,
      'completedBoost': completedBoost,
      'ongoingBoost': ongoingBoost,
      'vibeCompatibilityBoost': vibeCompatibilityBoost,
      'revenueSuccessBoost': revenueSuccessBoost,
      'feedbackBoost': feedbackBoost,
      'sameCategoryBoost': sameCategoryBoost,
      'relatedCategoryBoost': relatedCategoryBoost,
      'unrelatedCategoryBoost': unrelatedCategoryBoost,
      'countMultiplier': countMultiplier,
      'partnershipCount': partnershipCount,
    };
  }

  /// Create from JSON
  factory PartnershipExpertiseBoost.fromJson(Map<String, dynamic> json) {
    return PartnershipExpertiseBoost(
      totalBoost: (json['totalBoost'] as num?)?.toDouble() ?? 0.0,
      activeBoost: (json['activeBoost'] as num?)?.toDouble() ?? 0.0,
      completedBoost: (json['completedBoost'] as num?)?.toDouble() ?? 0.0,
      ongoingBoost: (json['ongoingBoost'] as num?)?.toDouble() ?? 0.0,
      vibeCompatibilityBoost: (json['vibeCompatibilityBoost'] as num?)?.toDouble() ?? 0.0,
      revenueSuccessBoost: (json['revenueSuccessBoost'] as num?)?.toDouble() ?? 0.0,
      feedbackBoost: (json['feedbackBoost'] as num?)?.toDouble() ?? 0.0,
      sameCategoryBoost: (json['sameCategoryBoost'] as num?)?.toDouble() ?? 0.0,
      relatedCategoryBoost: (json['relatedCategoryBoost'] as num?)?.toDouble() ?? 0.0,
      unrelatedCategoryBoost: (json['unrelatedCategoryBoost'] as num?)?.toDouble() ?? 0.0,
      countMultiplier: (json['countMultiplier'] as num?)?.toDouble() ?? 1.0,
      partnershipCount: json['partnershipCount'] as int? ?? 0,
    );
  }

  /// Create a copy with updated fields
  PartnershipExpertiseBoost copyWith({
    double? totalBoost,
    double? activeBoost,
    double? completedBoost,
    double? ongoingBoost,
    double? vibeCompatibilityBoost,
    double? revenueSuccessBoost,
    double? feedbackBoost,
    double? sameCategoryBoost,
    double? relatedCategoryBoost,
    double? unrelatedCategoryBoost,
    double? countMultiplier,
    int? partnershipCount,
  }) {
    return PartnershipExpertiseBoost(
      totalBoost: totalBoost ?? this.totalBoost,
      activeBoost: activeBoost ?? this.activeBoost,
      completedBoost: completedBoost ?? this.completedBoost,
      ongoingBoost: ongoingBoost ?? this.ongoingBoost,
      vibeCompatibilityBoost: vibeCompatibilityBoost ?? this.vibeCompatibilityBoost,
      revenueSuccessBoost: revenueSuccessBoost ?? this.revenueSuccessBoost,
      feedbackBoost: feedbackBoost ?? this.feedbackBoost,
      sameCategoryBoost: sameCategoryBoost ?? this.sameCategoryBoost,
      relatedCategoryBoost: relatedCategoryBoost ?? this.relatedCategoryBoost,
      unrelatedCategoryBoost: unrelatedCategoryBoost ?? this.unrelatedCategoryBoost,
      countMultiplier: countMultiplier ?? this.countMultiplier,
      partnershipCount: partnershipCount ?? this.partnershipCount,
    );
  }

  @override
  List<Object?> get props => [
        totalBoost,
        activeBoost,
        completedBoost,
        ongoingBoost,
        vibeCompatibilityBoost,
        revenueSuccessBoost,
        feedbackBoost,
        sameCategoryBoost,
        relatedCategoryBoost,
        unrelatedCategoryBoost,
        countMultiplier,
        partnershipCount,
      ];
}

