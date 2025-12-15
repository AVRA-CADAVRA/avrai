import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';

class _CopyWithSentinel {
  const _CopyWithSentinel();
}

/// Business Expert Preferences Model
/// Defines detailed preferences for the types of experts a business wants to connect with
/// Used by AI/ML models to filter and rank expert matches
class BusinessExpertPreferences extends Equatable {
  // Expertise Preferences
  final List<String> requiredExpertiseCategories; // Must-have expertise
  final List<String> preferredExpertiseCategories; // Nice-to-have expertise
  final int? minExpertLevel; // Minimum expertise level (0-5)
  final int? preferredExpertLevel; // Preferred expertise level
  
  // Location Preferences
  final String? preferredLocation; // Specific location (e.g., "Brooklyn", "NYC")
  final List<String>? preferredLocations; // Multiple preferred locations
  final int? maxDistanceKm; // Maximum distance in kilometers
  final bool allowRemote; // Allow remote experts
  
  // Demographics Preferences
  final AgeRange? preferredAgeRange;
  final List<String>? preferredLanguages; // e.g., ["English", "Spanish"]
  
  // Experience & Background Preferences
  final int? minYearsExperience;
  final List<String>? preferredBackgrounds; // e.g., ["Restaurant", "Hospitality", "Retail"]
  final List<String>? preferredCertifications; // e.g., ["Food Safety", "Sommelier"]
  final List<String>? preferredSkills; // Specific skills beyond expertise
  
  // Personality & Work Style Preferences
  final List<String>? preferredPersonalityTraits; // e.g., ["Outgoing", "Detail-oriented", "Creative"]
  final List<String>? preferredWorkStyles; // e.g., ["Collaborative", "Independent", "Leadership"]
  final List<String>? preferredCommunicationStyles; // e.g., ["Direct", "Diplomatic", "Enthusiastic"]
  
  // Availability Preferences
  final List<String>? preferredAvailability; // e.g., ["Weekdays", "Evenings", "Weekends"]
  final bool requireFlexibleSchedule;
  
  // Engagement Preferences
  final List<String>? preferredEngagementTypes; // e.g., ["Consulting", "Partnership", "Mentorship"]
  final int? preferredCommitmentLevel; // 1-5 scale
  final bool preferLongTermRelationships;
  
  // Community & Network Preferences
  final List<String>? preferredCommunities; // Community IDs
  final bool preferCommunityLeaders; // Prefer experts who lead communities
  final int? minCommunityConnections; // Minimum number of community connections
  
  // AI/ML Specific Preferences
  final Map<String, dynamic> aiMatchingCriteria; // Custom criteria for AI matching
  final double? minMatchScore; // Minimum match score threshold (0.0-1.0)
  final List<String>? aiKeywords; // Keywords for AI to consider
  final String? aiMatchingPrompt; // Custom prompt for AI matching
  
  // Exclusion Criteria
  final List<String>? excludedExpertise; // Expertise to avoid
  final List<String>? excludedLocations; // Locations to exclude
  
  const BusinessExpertPreferences({
    this.requiredExpertiseCategories = const [],
    this.preferredExpertiseCategories = const [],
    this.minExpertLevel,
    this.preferredExpertLevel,
    this.preferredLocation,
    this.preferredLocations,
    this.maxDistanceKm,
    this.allowRemote = false,
    this.preferredAgeRange,
    this.preferredLanguages,
    this.minYearsExperience,
    this.preferredBackgrounds,
    this.preferredCertifications,
    this.preferredSkills,
    this.preferredPersonalityTraits,
    this.preferredWorkStyles,
    this.preferredCommunicationStyles,
    this.preferredAvailability,
    this.requireFlexibleSchedule = false,
    this.preferredEngagementTypes,
    this.preferredCommitmentLevel,
    this.preferLongTermRelationships = false,
    this.preferredCommunities,
    this.preferCommunityLeaders = false,
    this.minCommunityConnections,
    this.aiMatchingCriteria = const {},
    this.minMatchScore,
    this.aiKeywords,
    this.aiMatchingPrompt,
    this.excludedExpertise,
    this.excludedLocations,
  });

  factory BusinessExpertPreferences.fromJson(Map<String, dynamic> json) {
    return BusinessExpertPreferences(
      requiredExpertiseCategories: List<String>.from(json['requiredExpertiseCategories'] ?? []),
      preferredExpertiseCategories: List<String>.from(json['preferredExpertiseCategories'] ?? []),
      minExpertLevel: json['minExpertLevel'] as int?,
      preferredExpertLevel: json['preferredExpertLevel'] as int?,
      preferredLocation: json['preferredLocation'] as String?,
      preferredLocations: json['preferredLocations'] != null
          ? List<String>.from(json['preferredLocations'])
          : null,
      maxDistanceKm: json['maxDistanceKm'] as int?,
      allowRemote: json['allowRemote'] as bool? ?? false,
      preferredAgeRange: json['preferredAgeRange'] != null
          ? AgeRange.fromJson(json['preferredAgeRange'] as Map<String, dynamic>)
          : null,
      preferredLanguages: json['preferredLanguages'] != null
          ? List<String>.from(json['preferredLanguages'])
          : null,
      minYearsExperience: json['minYearsExperience'] as int?,
      preferredBackgrounds: json['preferredBackgrounds'] != null
          ? List<String>.from(json['preferredBackgrounds'])
          : null,
      preferredCertifications: json['preferredCertifications'] != null
          ? List<String>.from(json['preferredCertifications'])
          : null,
      preferredSkills: json['preferredSkills'] != null
          ? List<String>.from(json['preferredSkills'])
          : null,
      preferredPersonalityTraits: json['preferredPersonalityTraits'] != null
          ? List<String>.from(json['preferredPersonalityTraits'])
          : null,
      preferredWorkStyles: json['preferredWorkStyles'] != null
          ? List<String>.from(json['preferredWorkStyles'])
          : null,
      preferredCommunicationStyles: json['preferredCommunicationStyles'] != null
          ? List<String>.from(json['preferredCommunicationStyles'])
          : null,
      preferredAvailability: json['preferredAvailability'] != null
          ? List<String>.from(json['preferredAvailability'])
          : null,
      requireFlexibleSchedule: json['requireFlexibleSchedule'] as bool? ?? false,
      preferredEngagementTypes: json['preferredEngagementTypes'] != null
          ? List<String>.from(json['preferredEngagementTypes'])
          : null,
      preferredCommitmentLevel: json['preferredCommitmentLevel'] as int?,
      preferLongTermRelationships: json['preferLongTermRelationships'] as bool? ?? false,
      preferredCommunities: json['preferredCommunities'] != null
          ? List<String>.from(json['preferredCommunities'])
          : null,
      preferCommunityLeaders: json['preferCommunityLeaders'] as bool? ?? false,
      minCommunityConnections: json['minCommunityConnections'] as int?,
      aiMatchingCriteria: Map<String, dynamic>.from(json['aiMatchingCriteria'] ?? {}),
      minMatchScore: json['minMatchScore'] != null
          ? (json['minMatchScore'] as num).toDouble()
          : null,
      aiKeywords: json['aiKeywords'] != null
          ? List<String>.from(json['aiKeywords'])
          : null,
      aiMatchingPrompt: json['aiMatchingPrompt'] as String?,
      excludedExpertise: json['excludedExpertise'] != null
          ? List<String>.from(json['excludedExpertise'])
          : null,
      excludedLocations: json['excludedLocations'] != null
          ? List<String>.from(json['excludedLocations'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requiredExpertiseCategories': requiredExpertiseCategories,
      'preferredExpertiseCategories': preferredExpertiseCategories,
      'minExpertLevel': minExpertLevel,
      'preferredExpertLevel': preferredExpertLevel,
      'preferredLocation': preferredLocation,
      'preferredLocations': preferredLocations,
      'maxDistanceKm': maxDistanceKm,
      'allowRemote': allowRemote,
      'preferredAgeRange': preferredAgeRange?.toJson(),
      'preferredLanguages': preferredLanguages,
      'minYearsExperience': minYearsExperience,
      'preferredBackgrounds': preferredBackgrounds,
      'preferredCertifications': preferredCertifications,
      'preferredSkills': preferredSkills,
      'preferredPersonalityTraits': preferredPersonalityTraits,
      'preferredWorkStyles': preferredWorkStyles,
      'preferredCommunicationStyles': preferredCommunicationStyles,
      'preferredAvailability': preferredAvailability,
      'requireFlexibleSchedule': requireFlexibleSchedule,
      'preferredEngagementTypes': preferredEngagementTypes,
      'preferredCommitmentLevel': preferredCommitmentLevel,
      'preferLongTermRelationships': preferLongTermRelationships,
      'preferredCommunities': preferredCommunities,
      'preferCommunityLeaders': preferCommunityLeaders,
      'minCommunityConnections': minCommunityConnections,
      'aiMatchingCriteria': aiMatchingCriteria,
      'minMatchScore': minMatchScore,
      'aiKeywords': aiKeywords,
      'aiMatchingPrompt': aiMatchingPrompt,
      'excludedExpertise': excludedExpertise,
      'excludedLocations': excludedLocations,
    };
  }

  BusinessExpertPreferences copyWith({
    List<String>? requiredExpertiseCategories,
    List<String>? preferredExpertiseCategories,
    Object? minExpertLevel = const _CopyWithSentinel(),
    Object? preferredExpertLevel = const _CopyWithSentinel(),
    Object? preferredLocation = const _CopyWithSentinel(),
    Object? preferredLocations = const _CopyWithSentinel(),
    Object? maxDistanceKm = const _CopyWithSentinel(),
    bool? allowRemote,
    Object? preferredAgeRange = const _CopyWithSentinel(),
    Object? preferredLanguages = const _CopyWithSentinel(),
    Object? minYearsExperience = const _CopyWithSentinel(),
    Object? preferredBackgrounds = const _CopyWithSentinel(),
    Object? preferredCertifications = const _CopyWithSentinel(),
    Object? preferredSkills = const _CopyWithSentinel(),
    Object? preferredPersonalityTraits = const _CopyWithSentinel(),
    Object? preferredWorkStyles = const _CopyWithSentinel(),
    Object? preferredCommunicationStyles = const _CopyWithSentinel(),
    Object? preferredAvailability = const _CopyWithSentinel(),
    bool? requireFlexibleSchedule,
    Object? preferredEngagementTypes = const _CopyWithSentinel(),
    Object? preferredCommitmentLevel = const _CopyWithSentinel(),
    bool? preferLongTermRelationships,
    Object? preferredCommunities = const _CopyWithSentinel(),
    bool? preferCommunityLeaders,
    Object? minCommunityConnections = const _CopyWithSentinel(),
    Map<String, dynamic>? aiMatchingCriteria,
    Object? minMatchScore = const _CopyWithSentinel(),
    Object? aiKeywords = const _CopyWithSentinel(),
    Object? aiMatchingPrompt = const _CopyWithSentinel(),
    Object? excludedExpertise = const _CopyWithSentinel(),
    Object? excludedLocations = const _CopyWithSentinel(),
  }) {
    assert(() {
      // #region agent log
      try {
        const debugLogPath = '/Users/reisgordon/SPOTS/.cursor/debug.log';
        final payload = <String, dynamic>{
          'sessionId': 'debug-session',
          'runId': 'pre-fix',
          'hypothesisId': 'H-copyWith-null',
          'location': 'business_expert_preferences.dart:copyWith',
          'message': 'copyWith called',
          'data': {
            'preferredLocation_isSentinel': preferredLocation is _CopyWithSentinel,
            'preferredLocation_value': preferredLocation is _CopyWithSentinel ? null : preferredLocation,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        File(debugLogPath).writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      return true;
    }());

    return BusinessExpertPreferences(
      requiredExpertiseCategories: requiredExpertiseCategories ?? this.requiredExpertiseCategories,
      preferredExpertiseCategories: preferredExpertiseCategories ?? this.preferredExpertiseCategories,
      minExpertLevel: minExpertLevel is _CopyWithSentinel ? this.minExpertLevel : minExpertLevel as int?,
      preferredExpertLevel: preferredExpertLevel is _CopyWithSentinel ? this.preferredExpertLevel : preferredExpertLevel as int?,
      preferredLocation: preferredLocation is _CopyWithSentinel ? this.preferredLocation : preferredLocation as String?,
      preferredLocations: preferredLocations is _CopyWithSentinel ? this.preferredLocations : preferredLocations as List<String>?,
      maxDistanceKm: maxDistanceKm is _CopyWithSentinel ? this.maxDistanceKm : maxDistanceKm as int?,
      allowRemote: allowRemote ?? this.allowRemote,
      preferredAgeRange: preferredAgeRange is _CopyWithSentinel ? this.preferredAgeRange : preferredAgeRange as AgeRange?,
      preferredLanguages: preferredLanguages is _CopyWithSentinel ? this.preferredLanguages : preferredLanguages as List<String>?,
      minYearsExperience: minYearsExperience is _CopyWithSentinel ? this.minYearsExperience : minYearsExperience as int?,
      preferredBackgrounds: preferredBackgrounds is _CopyWithSentinel ? this.preferredBackgrounds : preferredBackgrounds as List<String>?,
      preferredCertifications: preferredCertifications is _CopyWithSentinel ? this.preferredCertifications : preferredCertifications as List<String>?,
      preferredSkills: preferredSkills is _CopyWithSentinel ? this.preferredSkills : preferredSkills as List<String>?,
      preferredPersonalityTraits: preferredPersonalityTraits is _CopyWithSentinel ? this.preferredPersonalityTraits : preferredPersonalityTraits as List<String>?,
      preferredWorkStyles: preferredWorkStyles is _CopyWithSentinel ? this.preferredWorkStyles : preferredWorkStyles as List<String>?,
      preferredCommunicationStyles: preferredCommunicationStyles is _CopyWithSentinel ? this.preferredCommunicationStyles : preferredCommunicationStyles as List<String>?,
      preferredAvailability: preferredAvailability is _CopyWithSentinel ? this.preferredAvailability : preferredAvailability as List<String>?,
      requireFlexibleSchedule: requireFlexibleSchedule ?? this.requireFlexibleSchedule,
      preferredEngagementTypes: preferredEngagementTypes is _CopyWithSentinel ? this.preferredEngagementTypes : preferredEngagementTypes as List<String>?,
      preferredCommitmentLevel: preferredCommitmentLevel is _CopyWithSentinel ? this.preferredCommitmentLevel : preferredCommitmentLevel as int?,
      preferLongTermRelationships: preferLongTermRelationships ?? this.preferLongTermRelationships,
      preferredCommunities: preferredCommunities is _CopyWithSentinel ? this.preferredCommunities : preferredCommunities as List<String>?,
      preferCommunityLeaders: preferCommunityLeaders ?? this.preferCommunityLeaders,
      minCommunityConnections: minCommunityConnections is _CopyWithSentinel ? this.minCommunityConnections : minCommunityConnections as int?,
      aiMatchingCriteria: aiMatchingCriteria ?? this.aiMatchingCriteria,
      minMatchScore: minMatchScore is _CopyWithSentinel ? this.minMatchScore : minMatchScore as double?,
      aiKeywords: aiKeywords is _CopyWithSentinel ? this.aiKeywords : aiKeywords as List<String>?,
      aiMatchingPrompt: aiMatchingPrompt is _CopyWithSentinel ? this.aiMatchingPrompt : aiMatchingPrompt as String?,
      excludedExpertise: excludedExpertise is _CopyWithSentinel ? this.excludedExpertise : excludedExpertise as List<String>?,
      excludedLocations: excludedLocations is _CopyWithSentinel ? this.excludedLocations : excludedLocations as List<String>?,
    );
  }

  /// Check if preferences are empty/minimal
  bool get isEmpty {
    return requiredExpertiseCategories.isEmpty &&
        preferredExpertiseCategories.isEmpty &&
        minExpertLevel == null &&
        preferredLocation == null &&
        preferredLocations == null;
  }

  /// Get a summary description for display
  String getSummary() {
    final parts = <String>[];
    
    if (requiredExpertiseCategories.isNotEmpty) {
      parts.add('Required: ${requiredExpertiseCategories.join(', ')}');
    }
    if (preferredExpertiseCategories.isNotEmpty) {
      parts.add('Preferred: ${preferredExpertiseCategories.join(', ')}');
    }
    if (preferredLocation != null) {
      parts.add('Location: $preferredLocation');
    }
    if (minExpertLevel != null) {
      parts.add('Min Level: $minExpertLevel');
    }
    
    return parts.isEmpty ? 'No preferences set' : parts.join(' • ');
  }

  @override
  List<Object?> get props => [
        requiredExpertiseCategories,
        preferredExpertiseCategories,
        minExpertLevel,
        preferredExpertLevel,
        preferredLocation,
        preferredLocations,
        maxDistanceKm,
        allowRemote,
        preferredAgeRange,
        preferredLanguages,
        minYearsExperience,
        preferredBackgrounds,
        preferredCertifications,
        preferredSkills,
        preferredPersonalityTraits,
        preferredWorkStyles,
        preferredCommunicationStyles,
        preferredAvailability,
        requireFlexibleSchedule,
        preferredEngagementTypes,
        preferredCommitmentLevel,
        preferLongTermRelationships,
        preferredCommunities,
        preferCommunityLeaders,
        minCommunityConnections,
        aiMatchingCriteria,
        minMatchScore,
        aiKeywords,
        aiMatchingPrompt,
        excludedExpertise,
        excludedLocations,
      ];
}

/// Age Range Model
class AgeRange extends Equatable {
  final int? minAge;
  final int? maxAge;

  const AgeRange({
    this.minAge,
    this.maxAge,
  });

  factory AgeRange.fromJson(Map<String, dynamic> json) {
    return AgeRange(
      minAge: json['minAge'] as int?,
      maxAge: json['maxAge'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minAge': minAge,
      'maxAge': maxAge,
    };
  }

  String get displayText {
    if (minAge == null && maxAge == null) return 'Any age';
    if (minAge == null) return 'Under ${maxAge!}';
    if (maxAge == null) return '${minAge!}+';
    return '${minAge!}-${maxAge!}';
  }

  bool matches(int age) {
    if (minAge != null && age < minAge!) return false;
    if (maxAge != null && age > maxAge!) return false;
    return true;
  }

  @override
  List<Object?> get props => [minAge, maxAge];
}

