import 'package:equatable/equatable.dart';
import 'package:spots/core/models/platform_phase.dart';
import 'package:spots/core/models/saturation_metrics.dart';

/// Expertise Requirements Model
/// 
/// Defines the requirements for achieving expertise in a category.
/// Requirements scale based on platform phase and saturation metrics.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to expertise recognition
/// - Scales requirements as platform grows
/// - Maintains quality through dynamic thresholds
/// - Supports multiple paths to expertise
/// 
/// **Multi-Path Requirements:**
/// - Exploration (40%): Visits, reviews, check-ins
/// - Credentials (25%): Degrees, certifications
/// - Influence (20%): Followers, shares, lists
/// - Professional (25%): Proof of work
/// - Community (15%): Contributions, endorsements
/// - Local (varies): Locality-based expertise
class ExpertiseRequirements extends Equatable {
  /// Category this requirement is for
  final String category;
  
  /// Platform phase
  final String? platformPhaseId;
  final PlatformPhase? platformPhase;
  
  /// Threshold values
  final ThresholdValues thresholdValues;
  
  /// Saturation metrics reference
  final String? saturationMetricsId;
  final SaturationMetrics? saturationMetrics;
  
  /// Multi-path requirements
  final MultiPathRequirements multiPathRequirements;
  
  /// Metadata
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata;

  const ExpertiseRequirements({
    required this.category,
    this.platformPhaseId,
    this.platformPhase,
    required this.thresholdValues,
    this.saturationMetricsId,
    this.saturationMetrics,
    required this.multiPathRequirements,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  /// Get effective requirements (adjusted for phase and saturation)
  ThresholdValues getEffectiveRequirements() {
    final phaseMultiplier = platformPhase?.getCategoryMultiplier(category) ?? 1.0;
    final saturationMultiplier = saturationMetrics?.getSaturationMultiplier() ?? 1.0;
    final totalMultiplier = phaseMultiplier * saturationMultiplier;

    return thresholdValues.applyMultiplier(totalMultiplier);
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'platformPhaseId': platformPhaseId,
      'thresholdValues': thresholdValues.toJson(),
      'saturationMetricsId': saturationMetricsId,
      'multiPathRequirements': multiPathRequirements.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ExpertiseRequirements.fromJson(Map<String, dynamic> json) {
    return ExpertiseRequirements(
      category: json['category'] as String,
      platformPhaseId: json['platformPhaseId'] as String?,
      thresholdValues: ThresholdValues.fromJson(
        json['thresholdValues'] as Map<String, dynamic>,
      ),
      saturationMetricsId: json['saturationMetricsId'] as String?,
      multiPathRequirements: MultiPathRequirements.fromJson(
        json['multiPathRequirements'] as Map<String, dynamic>,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  /// Copy with method
  ExpertiseRequirements copyWith({
    String? category,
    String? platformPhaseId,
    PlatformPhase? platformPhase,
    ThresholdValues? thresholdValues,
    String? saturationMetricsId,
    SaturationMetrics? saturationMetrics,
    MultiPathRequirements? multiPathRequirements,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ExpertiseRequirements(
      category: category ?? this.category,
      platformPhaseId: platformPhaseId ?? this.platformPhaseId,
      platformPhase: platformPhase ?? this.platformPhase,
      thresholdValues: thresholdValues ?? this.thresholdValues,
      saturationMetricsId: saturationMetricsId ?? this.saturationMetricsId,
      saturationMetrics: saturationMetrics ?? this.saturationMetrics,
      multiPathRequirements: multiPathRequirements ?? this.multiPathRequirements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        category,
        platformPhaseId,
        platformPhase,
        thresholdValues,
        saturationMetricsId,
        saturationMetrics,
        multiPathRequirements,
        createdAt,
        updatedAt,
        metadata,
      ];
}

/// Threshold Values
/// Specific numeric requirements for expertise
class ThresholdValues extends Equatable {
  /// Minimum visits required
  final int minVisits;
  
  /// Minimum ratings/reviews required
  final int minRatings;
  
  /// Minimum average rating
  final double minAvgRating;
  
  /// Minimum time in category
  final Duration minTimeInCategory;
  
  /// Minimum community engagement
  final int? minCommunityEngagement;
  
  /// Minimum list curation
  final int? minListCuration;
  
  /// Minimum event hosting
  final int? minEventHosting;

  const ThresholdValues({
    required this.minVisits,
    required this.minRatings,
    required this.minAvgRating,
    required this.minTimeInCategory,
    this.minCommunityEngagement,
    this.minListCuration,
    this.minEventHosting,
  });

  /// Apply multiplier to all thresholds
  ThresholdValues applyMultiplier(double multiplier) {
    return ThresholdValues(
      minVisits: (minVisits * multiplier).ceil(),
      minRatings: (minRatings * multiplier).ceil(),
      minAvgRating: minAvgRating, // Rating doesn't scale
      minTimeInCategory: minTimeInCategory, // Time doesn't scale
      minCommunityEngagement: minCommunityEngagement != null
          ? (minCommunityEngagement! * multiplier).ceil()
          : null,
      minListCuration: minListCuration != null
          ? (minListCuration! * multiplier).ceil()
          : null,
      minEventHosting: minEventHosting != null
          ? (minEventHosting! * multiplier).ceil()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minVisits': minVisits,
      'minRatings': minRatings,
      'minAvgRating': minAvgRating,
      'minTimeInCategory': minTimeInCategory.inDays,
      'minCommunityEngagement': minCommunityEngagement,
      'minListCuration': minListCuration,
      'minEventHosting': minEventHosting,
    };
  }

  factory ThresholdValues.fromJson(Map<String, dynamic> json) {
    return ThresholdValues(
      minVisits: json['minVisits'] as int,
      minRatings: json['minRatings'] as int,
      minAvgRating: (json['minAvgRating'] as num).toDouble(),
      minTimeInCategory: Duration(
        days: json['minTimeInCategory'] as int? ?? 0,
      ),
      minCommunityEngagement: json['minCommunityEngagement'] as int?,
      minListCuration: json['minListCuration'] as int?,
      minEventHosting: json['minEventHosting'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        minVisits,
        minRatings,
        minAvgRating,
        minTimeInCategory,
        minCommunityEngagement,
        minListCuration,
        minEventHosting,
      ];
}

/// Multi-Path Requirements
/// Requirements for each expertise path
class MultiPathRequirements extends Equatable {
  /// Exploration path (40% weight)
  final ExplorationPathRequirements? exploration;
  
  /// Credential path (25% weight)
  final CredentialPathRequirements? credential;
  
  /// Influence path (20% weight)
  final InfluencePathRequirements? influence;
  
  /// Professional path (25% weight)
  final ProfessionalPathRequirements? professional;
  
  /// Community path (15% weight)
  final CommunityPathRequirements? community;
  
  /// Local path (varies)
  final LocalPathRequirements? local;

  const MultiPathRequirements({
    this.exploration,
    this.credential,
    this.influence,
    this.professional,
    this.community,
    this.local,
  });

  Map<String, dynamic> toJson() {
    return {
      'exploration': exploration?.toJson(),
      'credential': credential?.toJson(),
      'influence': influence?.toJson(),
      'professional': professional?.toJson(),
      'community': community?.toJson(),
      'local': local?.toJson(),
    };
  }

  factory MultiPathRequirements.fromJson(Map<String, dynamic> json) {
    return MultiPathRequirements(
      exploration: json['exploration'] != null
          ? ExplorationPathRequirements.fromJson(
              json['exploration'] as Map<String, dynamic>,
            )
          : null,
      credential: json['credential'] != null
          ? CredentialPathRequirements.fromJson(
              json['credential'] as Map<String, dynamic>,
            )
          : null,
      influence: json['influence'] != null
          ? InfluencePathRequirements.fromJson(
              json['influence'] as Map<String, dynamic>,
            )
          : null,
      professional: json['professional'] != null
          ? ProfessionalPathRequirements.fromJson(
              json['professional'] as Map<String, dynamic>,
            )
          : null,
      community: json['community'] != null
          ? CommunityPathRequirements.fromJson(
              json['community'] as Map<String, dynamic>,
            )
          : null,
      local: json['local'] != null
          ? LocalPathRequirements.fromJson(
              json['local'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
        exploration,
        credential,
        influence,
        professional,
        community,
        local,
      ];
}

/// Base class for path requirements
abstract class PathRequirements extends Equatable {
  Map<String, dynamic> toJson();
}

/// Exploration Path Requirements (40% weight)
class ExplorationPathRequirements extends PathRequirements {
  final int minVisits;
  final int minReviews;
  final double minAvgRating;
  final int minRepeatVisits;

  ExplorationPathRequirements({
    required this.minVisits,
    required this.minReviews,
    required this.minAvgRating,
    required this.minRepeatVisits,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'minVisits': minVisits,
      'minReviews': minReviews,
      'minAvgRating': minAvgRating,
      'minRepeatVisits': minRepeatVisits,
    };
  }

  factory ExplorationPathRequirements.fromJson(Map<String, dynamic> json) {
    return ExplorationPathRequirements(
      minVisits: json['minVisits'] as int,
      minReviews: json['minReviews'] as int,
      minAvgRating: (json['minAvgRating'] as num).toDouble(),
      minRepeatVisits: json['minRepeatVisits'] as int,
    );
  }

  @override
  List<Object?> get props => [minVisits, minReviews, minAvgRating, minRepeatVisits];
}

/// Credential Path Requirements (25% weight)
class CredentialPathRequirements extends PathRequirements {
  final List<String> acceptedDegrees;
  final List<String> acceptedCertifications;
  final int? minYearsExperience;
  final bool requiresVerification;

  CredentialPathRequirements({
    this.acceptedDegrees = const [],
    this.acceptedCertifications = const [],
    this.minYearsExperience,
    this.requiresVerification = true,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'acceptedDegrees': acceptedDegrees,
      'acceptedCertifications': acceptedCertifications,
      'minYearsExperience': minYearsExperience,
      'requiresVerification': requiresVerification,
    };
  }

  factory CredentialPathRequirements.fromJson(Map<String, dynamic> json) {
    return CredentialPathRequirements(
      acceptedDegrees: List<String>.from(json['acceptedDegrees'] ?? []),
      acceptedCertifications:
          List<String>.from(json['acceptedCertifications'] ?? []),
      minYearsExperience: json['minYearsExperience'] as int?,
      requiresVerification: json['requiresVerification'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        acceptedDegrees,
        acceptedCertifications,
        minYearsExperience,
        requiresVerification,
      ];
}

/// Influence Path Requirements (20% weight)
class InfluencePathRequirements extends PathRequirements {
  final int minFollowers;
  final int minListSaves;
  final int minListShares;
  final double minEngagementRate;
  final bool requiresVerified;

  InfluencePathRequirements({
    required this.minFollowers,
    required this.minListSaves,
    required this.minListShares,
    required this.minEngagementRate,
    this.requiresVerified = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'minFollowers': minFollowers,
      'minListSaves': minListSaves,
      'minListShares': minListShares,
      'minEngagementRate': minEngagementRate,
      'requiresVerified': requiresVerified,
    };
  }

  factory InfluencePathRequirements.fromJson(Map<String, dynamic> json) {
    return InfluencePathRequirements(
      minFollowers: json['minFollowers'] as int,
      minListSaves: json['minListSaves'] as int,
      minListShares: json['minListShares'] as int,
      minEngagementRate: (json['minEngagementRate'] as num).toDouble(),
      requiresVerified: json['requiresVerified'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        minFollowers,
        minListSaves,
        minListShares,
        minEngagementRate,
        requiresVerified,
      ];
}

/// Professional Path Requirements (25% weight)
class ProfessionalPathRequirements extends PathRequirements {
  final List<String> acceptedRoles;
  final bool requiresProofOfWork;
  final int? minYearsExperience;
  final int? minPeerEndorsements;

  ProfessionalPathRequirements({
    this.acceptedRoles = const [],
    this.requiresProofOfWork = true,
    this.minYearsExperience,
    this.minPeerEndorsements,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'acceptedRoles': acceptedRoles,
      'requiresProofOfWork': requiresProofOfWork,
      'minYearsExperience': minYearsExperience,
      'minPeerEndorsements': minPeerEndorsements,
    };
  }

  factory ProfessionalPathRequirements.fromJson(Map<String, dynamic> json) {
    return ProfessionalPathRequirements(
      acceptedRoles: List<String>.from(json['acceptedRoles'] ?? []),
      requiresProofOfWork: json['requiresProofOfWork'] as bool? ?? true,
      minYearsExperience: json['minYearsExperience'] as int?,
      minPeerEndorsements: json['minPeerEndorsements'] as int?,
    );
  }

  @override
  List<Object?> get props => [
        acceptedRoles,
        requiresProofOfWork,
        minYearsExperience,
        minPeerEndorsements,
      ];
}

/// Community Path Requirements (15% weight)
class CommunityPathRequirements extends PathRequirements {
  final int minQuestionsAnswered;
  final int minListCuration;
  final int minEventsHosted;
  final int minPeerEndorsements;
  final int minCommunityContributions;

  CommunityPathRequirements({
    required this.minQuestionsAnswered,
    required this.minListCuration,
    required this.minEventsHosted,
    required this.minPeerEndorsements,
    required this.minCommunityContributions,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'minQuestionsAnswered': minQuestionsAnswered,
      'minListCuration': minListCuration,
      'minEventsHosted': minEventsHosted,
      'minPeerEndorsements': minPeerEndorsements,
      'minCommunityContributions': minCommunityContributions,
    };
  }

  factory CommunityPathRequirements.fromJson(Map<String, dynamic> json) {
    return CommunityPathRequirements(
      minQuestionsAnswered: json['minQuestionsAnswered'] as int,
      minListCuration: json['minListCuration'] as int,
      minEventsHosted: json['minEventsHosted'] as int,
      minPeerEndorsements: json['minPeerEndorsements'] as int,
      minCommunityContributions: json['minCommunityContributions'] as int,
    );
  }

  @override
  List<Object?> get props => [
        minQuestionsAnswered,
        minListCuration,
        minEventsHosted,
        minPeerEndorsements,
        minCommunityContributions,
      ];
}

/// Local Path Requirements (varies)
class LocalPathRequirements extends PathRequirements {
  final int minLocalVisits;
  final Duration minTimeInLocation;
  final double minLocalRating;
  final bool requiresContinuousResidency;

  LocalPathRequirements({
    required this.minLocalVisits,
    required this.minTimeInLocation,
    required this.minLocalRating,
    this.requiresContinuousResidency = false,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'minLocalVisits': minLocalVisits,
      'minTimeInLocation': minTimeInLocation.inDays,
      'minLocalRating': minLocalRating,
      'requiresContinuousResidency': requiresContinuousResidency,
    };
  }

  factory LocalPathRequirements.fromJson(Map<String, dynamic> json) {
    return LocalPathRequirements(
      minLocalVisits: json['minLocalVisits'] as int,
      minTimeInLocation: Duration(
        days: json['minTimeInLocation'] as int? ?? 0,
      ),
      minLocalRating: (json['minLocalRating'] as num).toDouble(),
      requiresContinuousResidency:
          json['requiresContinuousResidency'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        minLocalVisits,
        minTimeInLocation,
        minLocalRating,
        requiresContinuousResidency,
      ];
}

