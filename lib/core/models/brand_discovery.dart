import 'package:equatable/equatable.dart';

/// Brand Discovery Model
/// 
/// Represents brand search and matching results for event sponsorship discovery.
/// Supports vibe matching with 70%+ compatibility threshold.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to brand discovery
/// - Enables vibe-based brand matching
/// - Supports compatibility scoring
/// - Creates pathways for brand-event connections
/// 
/// **Usage:**
/// ```dart
/// final discovery = BrandDiscovery(
///   id: 'discovery-123',
///   eventId: 'event-456',
///   searchCriteria: {'category': 'Food & Beverage', 'minContribution': 500.0},
///   matchingResults: [brandMatch1, brandMatch2],
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```
class BrandDiscovery extends Equatable {
  /// Discovery ID
  final String id;
  
  /// Event reference (the event seeking sponsors)
  final String eventId;
  
  /// Search criteria (flexible JSON structure)
  final Map<String, dynamic> searchCriteria;
  
  /// Matching results (list of brand matches)
  final List<BrandMatch> matchingResults;
  
  /// Total number of matches found
  int get matchCount => matchingResults.length;
  
  /// Number of matches above 70% compatibility threshold
  int get highCompatibilityMatches {
    return matchingResults
        .where((match) => match.compatibilityScore >= 70.0)
        .length;
  }
  
  /// Metadata for additional information
  final Map<String, dynamic> metadata;
  
  /// Created timestamp
  final DateTime createdAt;
  
  /// Updated timestamp
  final DateTime updatedAt;

  const BrandDiscovery({
    required this.id,
    required this.eventId,
    required this.searchCriteria,
    this.matchingResults = const [],
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get matches above 70% compatibility threshold
  List<BrandMatch> get viableMatches {
    return matchingResults
        .where((match) => match.compatibilityScore >= 70.0)
        .toList()
      ..sort((a, b) => b.compatibilityScore.compareTo(a.compatibilityScore));
  }

  /// Check if discovery has viable matches
  bool get hasViableMatches => viableMatches.isNotEmpty;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'searchCriteria': searchCriteria,
      'matchingResults': matchingResults.map((m) => m.toJson()).toList(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory BrandDiscovery.fromJson(Map<String, dynamic> json) {
    return BrandDiscovery(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      searchCriteria: Map<String, dynamic>.from(json['searchCriteria'] ?? {}),
      matchingResults: (json['matchingResults'] as List?)
              ?.map((m) => BrandMatch.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Create a copy with updated fields
  BrandDiscovery copyWith({
    String? id,
    String? eventId,
    Map<String, dynamic>? searchCriteria,
    List<BrandMatch>? matchingResults,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandDiscovery(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      searchCriteria: searchCriteria ?? this.searchCriteria,
      matchingResults: matchingResults ?? this.matchingResults,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        eventId,
        searchCriteria,
        matchingResults,
        metadata,
        createdAt,
        updatedAt,
      ];
}

/// Brand Match
/// 
/// Represents a single brand match result with compatibility scoring.
class BrandMatch extends Equatable {
  /// Brand ID
  final String brandId;
  
  /// Brand name (for display)
  final String brandName;
  
  /// Compatibility score (0-100, 70%+ required for suggestions)
  final double compatibilityScore;
  
  /// Vibe matching details
  final VibeCompatibility vibeCompatibility;
  
  /// Match reasons (why this brand matches)
  final List<String> matchReasons;
  
  /// Brand type/category
  final String? brandType;
  
  /// Brand categories
  final List<String> brandCategories;
  
  /// Estimated contribution range (optional)
  final ContributionRange? estimatedContribution;
  
  /// Metadata for additional information
  final Map<String, dynamic> metadata;

  const BrandMatch({
    required this.brandId,
    required this.brandName,
    required this.compatibilityScore,
    required this.vibeCompatibility,
    this.matchReasons = const [],
    this.brandType,
    this.brandCategories = const [],
    this.estimatedContribution,
    this.metadata = const {},
  });

  /// Check if match meets 70%+ threshold
  bool get meetsThreshold => compatibilityScore >= 70.0;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'brandId': brandId,
      'brandName': brandName,
      'compatibilityScore': compatibilityScore,
      'vibeCompatibility': vibeCompatibility.toJson(),
      'matchReasons': matchReasons,
      'brandType': brandType,
      'brandCategories': brandCategories,
      'estimatedContribution': estimatedContribution?.toJson(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory BrandMatch.fromJson(Map<String, dynamic> json) {
    return BrandMatch(
      brandId: json['brandId'] as String,
      brandName: json['brandName'] as String,
      compatibilityScore: (json['compatibilityScore'] as num).toDouble(),
      vibeCompatibility: VibeCompatibility.fromJson(
        json['vibeCompatibility'] as Map<String, dynamic>,
      ),
      matchReasons: List<String>.from(json['matchReasons'] ?? []),
      brandType: json['brandType'] as String?,
      brandCategories: List<String>.from(json['brandCategories'] ?? []),
      estimatedContribution: json['estimatedContribution'] != null
          ? ContributionRange.fromJson(
              json['estimatedContribution'] as Map<String, dynamic>,
            )
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Create a copy with updated fields
  BrandMatch copyWith({
    String? brandId,
    String? brandName,
    double? compatibilityScore,
    VibeCompatibility? vibeCompatibility,
    List<String>? matchReasons,
    String? brandType,
    List<String>? brandCategories,
    ContributionRange? estimatedContribution,
    Map<String, dynamic>? metadata,
  }) {
    return BrandMatch(
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      compatibilityScore: compatibilityScore ?? this.compatibilityScore,
      vibeCompatibility: vibeCompatibility ?? this.vibeCompatibility,
      matchReasons: matchReasons ?? this.matchReasons,
      brandType: brandType ?? this.brandType,
      brandCategories: brandCategories ?? this.brandCategories,
      estimatedContribution:
          estimatedContribution ?? this.estimatedContribution,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        brandId,
        brandName,
        compatibilityScore,
        vibeCompatibility,
        matchReasons,
        brandType,
        brandCategories,
        estimatedContribution,
        metadata,
      ];
}

/// Vibe Compatibility
/// 
/// Represents vibe matching details between event and brand.
class VibeCompatibility extends Equatable {
  /// Overall compatibility score (0-100)
  final double overallScore;
  
  /// Value alignment score
  final double valueAlignment;
  
  /// Style compatibility score
  final double styleCompatibility;
  
  /// Quality focus alignment
  final double qualityFocus;
  
  /// Audience alignment
  final double audienceAlignment;
  
  /// Compatibility breakdown (detailed scores by dimension)
  final Map<String, double> breakdown;

  const VibeCompatibility({
    required this.overallScore,
    required this.valueAlignment,
    required this.styleCompatibility,
    required this.qualityFocus,
    required this.audienceAlignment,
    this.breakdown = const {},
  });

  /// Check if vibe match meets 70%+ threshold
  bool get meetsThreshold => overallScore >= 70.0;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'overallScore': overallScore,
      'valueAlignment': valueAlignment,
      'styleCompatibility': styleCompatibility,
      'qualityFocus': qualityFocus,
      'audienceAlignment': audienceAlignment,
      'breakdown': breakdown,
    };
  }

  /// Create from JSON
  factory VibeCompatibility.fromJson(Map<String, dynamic> json) {
    return VibeCompatibility(
      overallScore: (json['overallScore'] as num).toDouble(),
      valueAlignment: (json['valueAlignment'] as num).toDouble(),
      styleCompatibility: (json['styleCompatibility'] as num).toDouble(),
      qualityFocus: (json['qualityFocus'] as num).toDouble(),
      audienceAlignment: (json['audienceAlignment'] as num).toDouble(),
      breakdown: json['breakdown'] != null
          ? Map<String, double>.from(
              (json['breakdown'] as Map).map(
                (key, value) => MapEntry(key as String, (value as num).toDouble()),
              ),
            )
          : {},
    );
  }

  /// Create a copy with updated fields
  VibeCompatibility copyWith({
    double? overallScore,
    double? valueAlignment,
    double? styleCompatibility,
    double? qualityFocus,
    double? audienceAlignment,
    Map<String, double>? breakdown,
  }) {
    return VibeCompatibility(
      overallScore: overallScore ?? this.overallScore,
      valueAlignment: valueAlignment ?? this.valueAlignment,
      styleCompatibility: styleCompatibility ?? this.styleCompatibility,
      qualityFocus: qualityFocus ?? this.qualityFocus,
      audienceAlignment: audienceAlignment ?? this.audienceAlignment,
      breakdown: breakdown ?? this.breakdown,
    );
  }

  @override
  List<Object?> get props => [
        overallScore,
        valueAlignment,
        styleCompatibility,
        qualityFocus,
        audienceAlignment,
        breakdown,
      ];
}

/// Contribution Range
/// 
/// Represents an estimated contribution range for a brand.
class ContributionRange extends Equatable {
  /// Minimum contribution amount
  final double minAmount;
  
  /// Maximum contribution amount
  final double maxAmount;
  
  /// Preferred contribution amount (if known)
  final double? preferredAmount;

  const ContributionRange({
    required this.minAmount,
    required this.maxAmount,
    this.preferredAmount,
  });

  /// Get average contribution amount
  double get averageAmount => (minAmount + maxAmount) / 2.0;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'minAmount': minAmount,
      'maxAmount': maxAmount,
      'preferredAmount': preferredAmount,
    };
  }

  /// Create from JSON
  factory ContributionRange.fromJson(Map<String, dynamic> json) {
    return ContributionRange(
      minAmount: (json['minAmount'] as num).toDouble(),
      maxAmount: (json['maxAmount'] as num).toDouble(),
      preferredAmount: (json['preferredAmount'] as num?)?.toDouble(),
    );
  }

  /// Create a copy with updated fields
  ContributionRange copyWith({
    double? minAmount,
    double? maxAmount,
    double? preferredAmount,
  }) {
    return ContributionRange(
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      preferredAmount: preferredAmount ?? this.preferredAmount,
    );
  }

  @override
  List<Object?> get props => [
        minAmount,
        maxAmount,
        preferredAmount,
      ];
}

