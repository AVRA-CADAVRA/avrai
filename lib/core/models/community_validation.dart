
/// Community Validation System for Expert Curator Validation
/// OUR_GUTS.md: "Community, Not Just Places" - Community-driven quality assurance
class CommunityValidation {
  final String id;
  final String spotId;
  final String validatorId;
  final ValidationStatus status;
  final ValidationLevel level;
  final String? feedback;
  final DateTime validatedAt;
  final List<ValidationCriteria> criteriaChecked;
  final double confidenceScore;
  final Map<String, dynamic> metadata;

  CommunityValidation({
    required this.id,
    required this.spotId,
    required this.validatorId,
    required this.status,
    required this.level,
    this.feedback,
    required this.validatedAt,
    required this.criteriaChecked,
    required this.confidenceScore,
    this.metadata = const {},
  });

  /// Create validation from expert curator
  factory CommunityValidation.fromExpertCurator({
    required String spotId,
    required String curatorId,
    required ValidationStatus status,
    String? feedback,
    required List<ValidationCriteria> criteria,
  }) {
    return CommunityValidation(
      id: 'validation_${DateTime.now().millisecondsSinceEpoch}',
      spotId: spotId,
      validatorId: curatorId,
      status: status,
      level: ValidationLevel.expert,
      feedback: feedback,
      validatedAt: DateTime.now(),
      criteriaChecked: criteria,
      confidenceScore: _calculateExpertConfidence(criteria),
      metadata: {
        'validator_type': 'expert_curator',
        'validation_source': 'community',
      },
    );
  }

  /// Create validation from community member
  factory CommunityValidation.fromCommunityMember({
    required String spotId,
    required String memberId,
    required ValidationStatus status,
    String? feedback,
    required List<ValidationCriteria> criteria,
  }) {
    return CommunityValidation(
      id: 'validation_${DateTime.now().millisecondsSinceEpoch}',
      spotId: spotId,
      validatorId: memberId,
      status: status,
      level: ValidationLevel.community,
      feedback: feedback,
      validatedAt: DateTime.now(),
      criteriaChecked: criteria,
      confidenceScore: _calculateCommunityConfidence(criteria),
      metadata: {
        'validator_type': 'community_member',
        'validation_source': 'community',
      },
    );
  }

  /// Calculate confidence score for expert validation
  static double _calculateExpertConfidence(List<ValidationCriteria> criteria) {
    if (criteria.isEmpty) return 0.5;
    
    double score = 0.8; // Base expert confidence
    
    // Bonus for comprehensive validation
    if (criteria.length >= 5) score += 0.1;
    
    // Check for key criteria
    if (criteria.contains(ValidationCriteria.locationAccuracy)) score += 0.05;
    if (criteria.contains(ValidationCriteria.informationCompleteness)) score += 0.05;
    
    return score.clamp(0.0, 1.0);
  }

  /// Calculate confidence score for community validation
  static double _calculateCommunityConfidence(List<ValidationCriteria> criteria) {
    if (criteria.isEmpty) return 0.3;
    
    double score = 0.6; // Base community confidence
    
    // Bonus for thorough validation
    if (criteria.length >= 3) score += 0.1;
    
    return score.clamp(0.0, 1.0);
  }

  /// Check if validation is recent and reliable
  bool get isCurrentlyValid {
    final age = DateTime.now().difference(validatedAt);
    
    // Expert validations last longer
    final validityPeriod = level == ValidationLevel.expert 
        ? const Duration(days: 90)
        : const Duration(days: 30);
    
    return status == ValidationStatus.validated && age < validityPeriod;
  }

  /// Get validation trust score
  double get trustScore {
    double score = confidenceScore;
    
    // Level bonus
    switch (level) {
      case ValidationLevel.expert:
        score += 0.2;
        break;
      case ValidationLevel.community:
        score += 0.1;
        break;
      case ValidationLevel.automated:
        // No bonus for automated
        break;
    }
    
    // Status adjustment
    switch (status) {
      case ValidationStatus.validated:
        // No adjustment
        break;
      case ValidationStatus.needsReview:
        score *= 0.7;
        break;
      case ValidationStatus.rejected:
        score = 0.0;
        break;
      case ValidationStatus.pending:
        score *= 0.5;
        break;
    }
    
    // Recency bonus
    final age = DateTime.now().difference(validatedAt);
    if (age.inDays < 7) score += 0.05;
    if (age.inDays > 60) score -= 0.1;
    
    return score.clamp(0.0, 1.0);
  }
}

/// Validation status for spots
enum ValidationStatus {
  validated,    // Community/expert approved
  needsReview,  // Requires expert review
  rejected,     // Community/expert rejected
  pending,      // Awaiting validation
}

/// Validation level based on validator expertise
enum ValidationLevel {
  expert,       // Expert curator validation
  community,    // Community member validation
  automated,    // Automated system validation
}

/// Criteria checked during validation
enum ValidationCriteria {
  locationAccuracy,      // Location is correct
  informationCompleteness, // All required info present
  categoryAccuracy,      // Category is correct
  descriptionQuality,    // Description is helpful
  photosQuality,         // Photos are relevant and good quality
  operatingHours,        // Hours are accurate
  contactInformation,    // Contact info is correct
  accessibility,         // Accessibility info is accurate
  communityRelevance,    // Relevant to local community
  safetyInformation,     // Safety/security info is accurate
}

/// Aggregated validation result for a spot
class SpotValidationSummary {
  final String spotId;
  final List<CommunityValidation> validations;
  final ValidationStatus overallStatus;
  final double trustScore;
  final int expertValidations;
  final int communityValidations;
  final DateTime lastValidated;
  final List<String> validationIssues;

  SpotValidationSummary({
    required this.spotId,
    required this.validations,
    required this.overallStatus,
    required this.trustScore,
    required this.expertValidations,
    required this.communityValidations,
    required this.lastValidated,
    required this.validationIssues,
  });

  /// Create summary from list of validations
  factory SpotValidationSummary.fromValidations(
    String spotId,
    List<CommunityValidation> validations,
  ) {
    if (validations.isEmpty) {
      return SpotValidationSummary.unvalidated(spotId);
    }

    // Sort by validation date (newest first)
    final sortedValidations = List<CommunityValidation>.from(validations)
      ..sort((a, b) => b.validatedAt.compareTo(a.validatedAt));

    // Count validation types
    final expertCount = validations
        .where((v) => v.level == ValidationLevel.expert)
        .length;
    final communityCount = validations
        .where((v) => v.level == ValidationLevel.community)
        .length;

    // Calculate overall status
    final overallStatus = _calculateOverallStatus(sortedValidations);
    
    // Calculate trust score
    final trustScore = _calculateOverallTrustScore(sortedValidations);
    
    // Identify issues
    final issues = _identifyValidationIssues(sortedValidations);

    return SpotValidationSummary(
      spotId: spotId,
      validations: sortedValidations,
      overallStatus: overallStatus,
      trustScore: trustScore,
      expertValidations: expertCount,
      communityValidations: communityCount,
      lastValidated: sortedValidations.first.validatedAt,
      validationIssues: issues,
    );
  }

  /// Create summary for unvalidated spot
  factory SpotValidationSummary.unvalidated(String spotId) {
    return SpotValidationSummary(
      spotId: spotId,
      validations: [],
      overallStatus: ValidationStatus.pending,
      trustScore: 0.0,
      expertValidations: 0,
      communityValidations: 0,
      lastValidated: DateTime.now(),
      validationIssues: ['No community validation'],
    );
  }

  /// Calculate overall validation status
  static ValidationStatus _calculateOverallStatus(
    List<CommunityValidation> validations,
  ) {
    if (validations.isEmpty) return ValidationStatus.pending;

    // Check most recent expert validation
    final recentExpert = validations
        .where((v) => v.level == ValidationLevel.expert)
        .where((v) => v.isCurrentlyValid)
        .firstOrNull;

    if (recentExpert != null) {
      return recentExpert.status;
    }

    // Check community consensus
    final recentCommunity = validations
        .where((v) => v.level == ValidationLevel.community)
        .where((v) => v.isCurrentlyValid)
        .toList();

    if (recentCommunity.length >= 3) {
      final validatedCount = recentCommunity
          .where((v) => v.status == ValidationStatus.validated)
          .length;
      
      if (validatedCount >= 2) return ValidationStatus.validated;
      if (validatedCount == 0) return ValidationStatus.needsReview;
    }

    return ValidationStatus.pending;
  }

  /// Calculate overall trust score
  static double _calculateOverallTrustScore(
    List<CommunityValidation> validations,
  ) {
    if (validations.isEmpty) return 0.0;

    // Weight expert validations more heavily
    double totalScore = 0.0;
    double totalWeight = 0.0;

    for (final validation in validations) {
      if (!validation.isCurrentlyValid) continue;

      final weight = validation.level == ValidationLevel.expert ? 3.0 : 1.0;
      totalScore += validation.trustScore * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? totalScore / totalWeight : 0.0;
  }

  /// Identify validation issues
  static List<String> _identifyValidationIssues(
    List<CommunityValidation> validations,
  ) {
    final issues = <String>[];

    if (validations.isEmpty) {
      issues.add('No community validation');
      return issues;
    }

    final recentValidations = validations
        .where((v) => v.isCurrentlyValid)
        .toList();

    if (recentValidations.isEmpty) {
      issues.add('Validation expired - needs re-validation');
    }

    final rejectedCount = recentValidations
        .where((v) => v.status == ValidationStatus.rejected)
        .length;

    if (rejectedCount > 0) {
      issues.add('$rejectedCount validation(s) rejected this spot');
    }

    final needsReviewCount = recentValidations
        .where((v) => v.status == ValidationStatus.needsReview)
        .length;

    if (needsReviewCount > 0) {
      issues.add('$needsReviewCount validation(s) flagged for review');
    }

    // Check for expert validation if high-stakes spot
    final hasExpertValidation = recentValidations
        .any((v) => v.level == ValidationLevel.expert);

    if (!hasExpertValidation && recentValidations.length < 2) {
      issues.add('Limited community validation - could benefit from expert review');
    }

    return issues;
  }

  /// Check if spot is well-validated
  bool get isWellValidated {
    return overallStatus == ValidationStatus.validated &&
           trustScore >= 0.7 &&
           validationIssues.isEmpty;
  }

  /// Get validation quality grade
  String get validationGrade {
    if (expertValidations > 0 && trustScore >= 0.8) return 'A';
    if (communityValidations >= 3 && trustScore >= 0.7) return 'B';
    if (communityValidations >= 2 && trustScore >= 0.6) return 'C';
    if (validations.isNotEmpty && trustScore >= 0.5) return 'D';
    return 'F';
  }
}

/// Expert curator system for high-quality validations
class ExpertCurator {
  final String userId;
  final String name;
  final List<String> expertiseAreas;
  final int validationCount;
  final double accuracyScore;
  final DateTime certifiedAt;
  final bool isActive;

  ExpertCurator({
    required this.userId,
    required this.name,
    required this.expertiseAreas,
    required this.validationCount,
    required this.accuracyScore,
    required this.certifiedAt,
    required this.isActive,
  });

  /// Check if curator can validate in specific area
  bool canValidateInArea(String area) {
    return isActive && expertiseAreas.contains(area);
  }

  /// Get curator trust level
  CuratorTrustLevel get trustLevel {
    if (accuracyScore >= 0.9 && validationCount >= 50) {
      return CuratorTrustLevel.platinum;
    }
    if (accuracyScore >= 0.8 && validationCount >= 20) {
      return CuratorTrustLevel.gold;
    }
    if (accuracyScore >= 0.7 && validationCount >= 10) {
      return CuratorTrustLevel.silver;
    }
    return CuratorTrustLevel.bronze;
  }
}

/// Trust levels for expert curators
enum CuratorTrustLevel {
  platinum, // Highest trust - 90%+ accuracy, 50+ validations
  gold,     // High trust - 80%+ accuracy, 20+ validations  
  silver,   // Medium trust - 70%+ accuracy, 10+ validations
  bronze,   // Basic trust - New or lower accuracy curators
}

/// Extension to get first element or null
extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}