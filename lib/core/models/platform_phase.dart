import 'package:equatable/equatable.dart';

/// Platform Phase Model
/// 
/// Represents the current growth phase of the platform.
/// Expertise requirements scale based on platform phase.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to expertise recognition
/// - Scales requirements as platform grows
/// - Maintains quality through dynamic thresholds
/// 
/// **Platform Phases:**
/// - Bootstrap: <1K users (lower thresholds)
/// - Growth: 1K-10K users (moderate thresholds)
/// - Scale: 10K-100K users (higher thresholds)
/// - Mature: 100K+ users (highest thresholds)
class PlatformPhase extends Equatable {
  /// Phase ID
  final String id;
  
  /// Phase name
  final PhaseName name;
  
  /// User count threshold (minimum users to be in this phase)
  final int userCountThreshold;
  
  /// Category multipliers (category-specific adjustments)
  final Map<String, double> categoryMultipliers;
  
  /// Saturation factors (how saturation affects requirements)
  final SaturationFactors saturationFactors;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const PlatformPhase({
    required this.id,
    required this.name,
    required this.userCountThreshold,
    this.categoryMultipliers = const {},
    required this.saturationFactors,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Get multiplier for a specific category
  double getCategoryMultiplier(String category) {
    return categoryMultipliers[category] ?? 1.0;
  }

  /// Check if user count qualifies for this phase
  bool qualifiesForPhase(int userCount) {
    return userCount >= userCountThreshold;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name.name,
      'userCountThreshold': userCountThreshold,
      'categoryMultipliers': categoryMultipliers,
      'saturationFactors': saturationFactors.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory PlatformPhase.fromJson(Map<String, dynamic> json) {
    return PlatformPhase(
      id: json['id'] as String,
      name: PhaseNameExtension.fromString(
        json['name'] as String? ?? 'bootstrap',
      ),
      userCountThreshold: json['userCountThreshold'] as int,
      categoryMultipliers: Map<String, double>.from(
        json['categoryMultipliers'] ?? {},
      ),
      saturationFactors: SaturationFactors.fromJson(
        json['saturationFactors'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Copy with method
  PlatformPhase copyWith({
    String? id,
    PhaseName? name,
    int? userCountThreshold,
    Map<String, double>? categoryMultipliers,
    SaturationFactors? saturationFactors,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PlatformPhase(
      id: id ?? this.id,
      name: name ?? this.name,
      userCountThreshold: userCountThreshold ?? this.userCountThreshold,
      categoryMultipliers: categoryMultipliers ?? this.categoryMultipliers,
      saturationFactors: saturationFactors ?? this.saturationFactors,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        userCountThreshold,
        categoryMultipliers,
        saturationFactors,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Platform Phase Name
enum PhaseName {
  bootstrap,  // <1K users
  growth,     // 1K-10K users
  scale,      // 10K-100K users
  mature,     // 100K+ users
}

extension PhaseNameExtension on PhaseName {
  String get displayName {
    switch (this) {
      case PhaseName.bootstrap:
        return 'Bootstrap';
      case PhaseName.growth:
        return 'Growth';
      case PhaseName.scale:
        return 'Scale';
      case PhaseName.mature:
        return 'Mature';
    }
  }

  String get description {
    switch (this) {
      case PhaseName.bootstrap:
        return 'Early platform (<1K users) - Lower thresholds';
      case PhaseName.growth:
        return 'Growing platform (1K-10K users) - Moderate thresholds';
      case PhaseName.scale:
        return 'Scaling platform (10K-100K users) - Higher thresholds';
      case PhaseName.mature:
        return 'Mature platform (100K+ users) - Highest thresholds';
    }
  }

  static PhaseName fromString(String? value) {
    if (value == null) return PhaseName.bootstrap;
    switch (value.toLowerCase()) {
      case 'bootstrap':
        return PhaseName.bootstrap;
      case 'growth':
        return PhaseName.growth;
      case 'scale':
        return PhaseName.scale;
      case 'mature':
        return PhaseName.mature;
      default:
        return PhaseName.bootstrap;
    }
  }
}

/// Saturation Factors
/// How saturation affects expertise requirements
class SaturationFactors extends Equatable {
  /// Base multiplier (1.0 = no change)
  final double baseMultiplier;
  
  /// Low saturation multiplier (<1% experts)
  final double lowSaturationMultiplier;
  
  /// Medium saturation multiplier (1-2% experts)
  final double mediumSaturationMultiplier;
  
  /// High saturation multiplier (2-3% experts)
  final double highSaturationMultiplier;
  
  /// Very high saturation multiplier (>3% experts)
  final double veryHighSaturationMultiplier;

  const SaturationFactors({
    this.baseMultiplier = 1.0,
    this.lowSaturationMultiplier = 0.8,
    this.mediumSaturationMultiplier = 1.0,
    this.highSaturationMultiplier = 1.5,
    this.veryHighSaturationMultiplier = 2.0,
  });

  /// Get multiplier based on saturation ratio
  double getMultiplierForSaturation(double saturationRatio) {
    if (saturationRatio < 0.01) {
      return lowSaturationMultiplier;
    } else if (saturationRatio < 0.02) {
      return mediumSaturationMultiplier;
    } else if (saturationRatio < 0.03) {
      return highSaturationMultiplier;
    } else {
      return veryHighSaturationMultiplier;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'baseMultiplier': baseMultiplier,
      'lowSaturationMultiplier': lowSaturationMultiplier,
      'mediumSaturationMultiplier': mediumSaturationMultiplier,
      'highSaturationMultiplier': highSaturationMultiplier,
      'veryHighSaturationMultiplier': veryHighSaturationMultiplier,
    };
  }

  factory SaturationFactors.fromJson(Map<String, dynamic> json) {
    return SaturationFactors(
      baseMultiplier: (json['baseMultiplier'] as num?)?.toDouble() ?? 1.0,
      lowSaturationMultiplier:
          (json['lowSaturationMultiplier'] as num?)?.toDouble() ?? 0.8,
      mediumSaturationMultiplier:
          (json['mediumSaturationMultiplier'] as num?)?.toDouble() ?? 1.0,
      highSaturationMultiplier:
          (json['highSaturationMultiplier'] as num?)?.toDouble() ?? 1.5,
      veryHighSaturationMultiplier:
          (json['veryHighSaturationMultiplier'] as num?)?.toDouble() ?? 2.0,
    );
  }

  @override
  List<Object?> get props => [
        baseMultiplier,
        lowSaturationMultiplier,
        mediumSaturationMultiplier,
        highSaturationMultiplier,
        veryHighSaturationMultiplier,
      ];
}

