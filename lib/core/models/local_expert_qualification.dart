import 'package:equatable/equatable.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/expertise_requirements.dart';

/// Local Expert Qualification Model
/// 
/// Represents a user's qualification status for local expert in a specific
/// category and locality. Tracks progress toward local expert qualification
/// and stores qualification factors.
/// 
/// **Philosophy:** Local experts shouldn't have to expand past their locality
/// to be qualified. They can be experts in their neighborhood without needing
/// city-wide expertise.
/// 
/// **Qualification Factors:**
/// 1. Lists that others follow (locality-focused)
/// 2. Event attendance and hosting
/// 3. Professional background
/// 4. Peer-reviewed reviews
/// 5. Positive activity trends (category + locality)
class LocalExpertQualification extends Equatable {
  final String id;
  final String userId;
  final String category;
  final String locality;
  final ExpertiseLevel currentLevel;
  final ThresholdValues baseThresholds; // Base thresholds (before locality adjustment)
  final ThresholdValues localityThresholds; // Locality-adjusted thresholds
  final QualificationProgress progress;
  final QualificationFactors factors;
  final bool isQualified;
  final DateTime? qualifiedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LocalExpertQualification({
    required this.id,
    required this.userId,
    required this.category,
    required this.locality,
    required this.currentLevel,
    required this.baseThresholds,
    required this.localityThresholds,
    required this.progress,
    required this.factors,
    this.isQualified = false,
    this.qualifiedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get progress percentage toward qualification
  double get progressPercentage {
    if (isQualified) return 1.0;

    // Calculate progress based on which thresholds are met
    int thresholdsMet = 0;
    int totalThresholds = 0;

    // Check each threshold component
    if (progress.visits >= localityThresholds.minVisits) thresholdsMet++;
    totalThresholds++;

    if (progress.ratings >= localityThresholds.minRatings) thresholdsMet++;
    totalThresholds++;

    if (progress.avgRating >= localityThresholds.minAvgRating) thresholdsMet++;
    totalThresholds++;

    if (localityThresholds.minCommunityEngagement != null) {
      totalThresholds++;
      if (progress.communityEngagement >=
          localityThresholds.minCommunityEngagement!) {
        thresholdsMet++;
      }
    }

    if (localityThresholds.minListCuration != null) {
      totalThresholds++;
      if (progress.listCuration >= localityThresholds.minListCuration!) {
        thresholdsMet++;
      }
    }

    if (localityThresholds.minEventHosting != null) {
      totalThresholds++;
      if (progress.eventHosting >= localityThresholds.minEventHosting!) {
        thresholdsMet++;
      }
    }

    return totalThresholds > 0 ? thresholdsMet / totalThresholds : 0.0;
  }

  /// Get remaining requirements for qualification
  Map<String, int> get remainingRequirements {
    final remaining = <String, int>{};

    if (progress.visits < localityThresholds.minVisits) {
      remaining['visits'] = localityThresholds.minVisits - progress.visits;
    }

    if (progress.ratings < localityThresholds.minRatings) {
      remaining['ratings'] = localityThresholds.minRatings - progress.ratings;
    }

    if (localityThresholds.minCommunityEngagement != null &&
        progress.communityEngagement <
            localityThresholds.minCommunityEngagement!) {
      remaining['communityEngagement'] =
          localityThresholds.minCommunityEngagement! -
              progress.communityEngagement;
    }

    if (localityThresholds.minListCuration != null &&
        progress.listCuration < localityThresholds.minListCuration!) {
      remaining['listCuration'] =
          localityThresholds.minListCuration! - progress.listCuration;
    }

    if (localityThresholds.minEventHosting != null &&
        progress.eventHosting < localityThresholds.minEventHosting!) {
      remaining['eventHosting'] =
          localityThresholds.minEventHosting! - progress.eventHosting;
    }

    return remaining;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'locality': locality,
      'currentLevel': currentLevel.name,
      'baseThresholds': baseThresholds.toJson(),
      'localityThresholds': localityThresholds.toJson(),
      'progress': progress.toJson(),
      'factors': factors.toJson(),
      'isQualified': isQualified,
      'qualifiedAt': qualifiedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory LocalExpertQualification.fromJson(Map<String, dynamic> json) {
    return LocalExpertQualification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      locality: json['locality'] as String,
      currentLevel: ExpertiseLevel.fromString(json['currentLevel'] as String) ??
          ExpertiseLevel.local,
      baseThresholds: ThresholdValues.fromJson(
        json['baseThresholds'] as Map<String, dynamic>,
      ),
      localityThresholds: ThresholdValues.fromJson(
        json['localityThresholds'] as Map<String, dynamic>,
      ),
      progress: QualificationProgress.fromJson(
        json['progress'] as Map<String, dynamic>,
      ),
      factors: QualificationFactors.fromJson(
        json['factors'] as Map<String, dynamic>,
      ),
      isQualified: json['isQualified'] as bool? ?? false,
      qualifiedAt: json['qualifiedAt'] != null
          ? DateTime.parse(json['qualifiedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with method
  LocalExpertQualification copyWith({
    String? id,
    String? userId,
    String? category,
    String? locality,
    ExpertiseLevel? currentLevel,
    ThresholdValues? baseThresholds,
    ThresholdValues? localityThresholds,
    QualificationProgress? progress,
    QualificationFactors? factors,
    bool? isQualified,
    DateTime? qualifiedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LocalExpertQualification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      locality: locality ?? this.locality,
      currentLevel: currentLevel ?? this.currentLevel,
      baseThresholds: baseThresholds ?? this.baseThresholds,
      localityThresholds: localityThresholds ?? this.localityThresholds,
      progress: progress ?? this.progress,
      factors: factors ?? this.factors,
      isQualified: isQualified ?? this.isQualified,
      qualifiedAt: qualifiedAt ?? this.qualifiedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        locality,
        currentLevel,
        baseThresholds,
        localityThresholds,
        progress,
        factors,
        isQualified,
        qualifiedAt,
        createdAt,
        updatedAt,
      ];
}

/// Qualification Progress
/// Tracks user's progress toward local expert qualification
class QualificationProgress extends Equatable {
  final int visits;
  final int ratings;
  final double avgRating;
  final int communityEngagement;
  final int listCuration;
  final int eventHosting;
  final int eventAttendance;

  const QualificationProgress({
    this.visits = 0,
    this.ratings = 0,
    this.avgRating = 0.0,
    this.communityEngagement = 0,
    this.listCuration = 0,
    this.eventHosting = 0,
    this.eventAttendance = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'visits': visits,
      'ratings': ratings,
      'avgRating': avgRating,
      'communityEngagement': communityEngagement,
      'listCuration': listCuration,
      'eventHosting': eventHosting,
      'eventAttendance': eventAttendance,
    };
  }

  factory QualificationProgress.fromJson(Map<String, dynamic> json) {
    return QualificationProgress(
      visits: json['visits'] as int? ?? 0,
      ratings: json['ratings'] as int? ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      communityEngagement: json['communityEngagement'] as int? ?? 0,
      listCuration: json['listCuration'] as int? ?? 0,
      eventHosting: json['eventHosting'] as int? ?? 0,
      eventAttendance: json['eventAttendance'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        visits,
        ratings,
        avgRating,
        communityEngagement,
        listCuration,
        eventHosting,
        eventAttendance,
      ];
}

/// Qualification Factors
/// Tracks the factors that contribute to local expert qualification
class QualificationFactors extends Equatable {
  final int listsWithFollowers; // Lists that others follow
  final int peerReviewedReviews; // Reviews with peer endorsements
  final bool hasProfessionalBackground; // Professional credentials/experience
  final bool hasPositiveTrends; // Positive activity trends (category + locality)
  final double listRespectRate; // Rate of list respects (active engagement)
  final double eventGrowthRate; // Event size growth rate

  const QualificationFactors({
    this.listsWithFollowers = 0,
    this.peerReviewedReviews = 0,
    this.hasProfessionalBackground = false,
    this.hasPositiveTrends = false,
    this.listRespectRate = 0.0,
    this.eventGrowthRate = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'listsWithFollowers': listsWithFollowers,
      'peerReviewedReviews': peerReviewedReviews,
      'hasProfessionalBackground': hasProfessionalBackground,
      'hasPositiveTrends': hasPositiveTrends,
      'listRespectRate': listRespectRate,
      'eventGrowthRate': eventGrowthRate,
    };
  }

  factory QualificationFactors.fromJson(Map<String, dynamic> json) {
    return QualificationFactors(
      listsWithFollowers: json['listsWithFollowers'] as int? ?? 0,
      peerReviewedReviews: json['peerReviewedReviews'] as int? ?? 0,
      hasProfessionalBackground:
          json['hasProfessionalBackground'] as bool? ?? false,
      hasPositiveTrends: json['hasPositiveTrends'] as bool? ?? false,
      listRespectRate: (json['listRespectRate'] as num?)?.toDouble() ?? 0.0,
      eventGrowthRate: (json['eventGrowthRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  List<Object?> get props => [
        listsWithFollowers,
        peerReviewedReviews,
        hasProfessionalBackground,
        hasPositiveTrends,
        listRespectRate,
        eventGrowthRate,
      ];
}

