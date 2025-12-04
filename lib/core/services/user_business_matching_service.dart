import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/business_patron_preferences.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/logger.dart';

/// User Business Matching Service
/// Matches users with businesses based on business patron preferences
/// Helps users discover businesses that want patrons like them
class UserBusinessMatchingService {
  static const String _logName = 'UserBusinessMatchingService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  /// Find businesses that match a user's profile
  /// Uses business patron preferences to determine good matches
  Future<List<UserBusinessMatch>> findBusinessesForUser(
    UnifiedUser user, {
    int maxResults = 20,
  }) async {
    try {
      _logger.info('Finding businesses for user: ${user.id}', tag: _logName);

      final allBusinesses = await _getAllBusinessAccounts();
      final matches = <UserBusinessMatch>[];

      for (final business in allBusinesses) {
        if (!business.isActive) continue;
        if (business.patronPreferences == null) continue;

        final matchScore = _calculateMatchScore(user, business, business.patronPreferences!);
        
        if (matchScore > 0.3) {
          // Minimum threshold
          matches.add(UserBusinessMatch(
            business: business,
            user: user,
            matchScore: matchScore,
            matchReason: _getMatchReason(user, business.patronPreferences!),
            matchedCriteria: _getMatchedCriteria(user, business.patronPreferences!),
          ));
        }
      }

      // Sort by match score
      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      _logger.info('Found ${matches.length} business matches', tag: _logName);
      return matches.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error finding businesses for user', error: e, tag: _logName);
      return [];
    }
  }

  /// Calculate how well a user matches a business's patron preferences
  double _calculateMatchScore(
    UnifiedUser user,
    BusinessAccount business,
    BusinessPatronPreferences preferences,
  ) {
    double score = 0.0;
    int criteriaCount = 0;

    // Age range match (if user has age data)
    if (preferences.preferredAgeRange != null) {
      // Note: Age data would need to be in UnifiedUser model
      // For now, skip this check
      criteriaCount++;
    }

    // Location match
    if (preferences.preferLocalPatrons && user.location != null && business.location != null) {
      if (user.location!.toLowerCase().contains(business.location!.toLowerCase()) ||
          business.location!.toLowerCase().contains(user.location!.toLowerCase())) {
        score += 0.15;
      }
    }
    if (preferences.preferTourists && user.location != null && business.location != null) {
      if (!user.location!.toLowerCase().contains(business.location!.toLowerCase())) {
        score += 0.1;
      }
    }
    criteriaCount++;

    // Community membership match
    if (preferences.preferCommunityMembers) {
      // Check if user is active in communities
      // This would require checking user's community memberships
      // For now, give partial credit if user has expertise (suggests community involvement)
      if (user.expertiseMap.isNotEmpty) {
        score += 0.1;
      }
      criteriaCount++;
    }

    // Expertise/knowledge match
    if (preferences.preferredKnowledgeAreas?.isNotEmpty == true) {
      final matchingAreas = preferences.preferredKnowledgeAreas!
          .where((area) => user.hasExpertiseIn(area))
          .length;
      if (matchingAreas > 0) {
        score += (matchingAreas / preferences.preferredKnowledgeAreas!.length) * 0.2;
      }
      criteriaCount++;
    }

    // Educated patrons preference
    if (preferences.preferEducatedPatrons) {
      // Check if user has expertise (suggests knowledge/education)
      if (user.expertiseMap.isNotEmpty) {
        score += 0.1;
      }
      criteriaCount++;
    }

    // Visit frequency preferences
    if (preferences.preferLoyalCustomers || preferences.preferNewCustomers) {
      // This would require visit history data
      // For now, give neutral score
      criteriaCount++;
    }

    // Normalize score based on criteria count
    if (criteriaCount > 0) {
      score = score / (criteriaCount * 0.15); // Normalize to 0-1 range
    }

    // Apply exclusion filters
    if (preferences.excludedInterests?.isNotEmpty == true) {
      // Check if user has excluded interests
      // This would require user interest data
    }

    if (preferences.excludedLocations?.isNotEmpty == true && user.location != null) {
      final isExcluded = preferences.excludedLocations!.any(
        (loc) => user.location!.toLowerCase().contains(loc.toLowerCase()),
      );
      if (isExcluded) {
        score *= 0.3; // Heavy penalty for excluded locations
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// Get match reason for display
  String _getMatchReason(UnifiedUser user, BusinessPatronPreferences preferences) {
    final reasons = <String>[];

    if (preferences.preferLocalPatrons && user.location != null) {
      reasons.add('Local patron');
    }

    if (preferences.preferCommunityMembers && user.expertiseMap.isNotEmpty) {
      reasons.add('Community member');
    }

    if (preferences.preferredKnowledgeAreas?.isNotEmpty == true) {
      final matchingAreas = preferences.preferredKnowledgeAreas!
          .where((area) => user.hasExpertiseIn(area))
          .toList();
      if (matchingAreas.isNotEmpty) {
        reasons.add('Knowledge in ${matchingAreas.first}');
      }
    }

    if (preferences.preferEducatedPatrons && user.expertiseMap.isNotEmpty) {
      reasons.add('Educated patron');
    }

    return reasons.isEmpty ? 'Good match' : reasons.join(', ');
  }

  /// Get matched criteria for detailed display
  List<String> _getMatchedCriteria(UnifiedUser user, BusinessPatronPreferences preferences) {
    final criteria = <String>[];

    if (preferences.preferLocalPatrons && user.location != null) {
      criteria.add('Local');
    }

    if (preferences.preferCommunityMembers) {
      criteria.add('Community Member');
    }

    if (preferences.preferredKnowledgeAreas?.isNotEmpty == true) {
      final matchingAreas = preferences.preferredKnowledgeAreas!
          .where((area) => user.hasExpertiseIn(area))
          .toList();
      criteria.addAll(matchingAreas.map((area) => 'Knowledge: $area'));
    }

    if (preferences.preferEducatedPatrons) {
      criteria.add('Educated');
    }

    if (preferences.preferredVibePreferences?.isNotEmpty == true) {
      criteria.add('Vibe Match');
    }

    return criteria;
  }

  /// Get user's compatibility score with a specific business
  Future<BusinessCompatibilityScore> getUserCompatibilityScore(
    UnifiedUser user,
    BusinessAccount business,
  ) async {
    if (business.patronPreferences == null) {
      return BusinessCompatibilityScore(
        business: business,
        user: user,
        overallScore: 0.5,
        matchedCriteria: [],
        missingCriteria: [],
        reason: 'No patron preferences set',
      );
    }

    final matchScore = _calculateMatchScore(user, business, business.patronPreferences!);
    final matchedCriteria = _getMatchedCriteria(user, business.patronPreferences!);
    final missingCriteria = _getMissingCriteria(user, business.patronPreferences!);

    return BusinessCompatibilityScore(
      business: business,
      user: user,
      overallScore: matchScore,
      matchedCriteria: matchedCriteria,
      missingCriteria: missingCriteria,
      reason: _getMatchReason(user, business.patronPreferences!),
    );
  }

  /// Get criteria that user doesn't match
  List<String> _getMissingCriteria(UnifiedUser user, BusinessPatronPreferences preferences) {
    final missing = <String>[];

    if (preferences.preferLocalPatrons && user.location == null) {
      missing.add('Location not specified');
    }

    if (preferences.preferCommunityMembers && user.expertiseMap.isEmpty) {
      missing.add('Not in communities');
    }

    if (preferences.preferredKnowledgeAreas?.isNotEmpty == true) {
      final unmatchedAreas = preferences.preferredKnowledgeAreas!
          .where((area) => !user.hasExpertiseIn(area))
          .toList();
      if (unmatchedAreas.isNotEmpty) {
        missing.addAll(unmatchedAreas.map((area) => 'Knowledge: $area'));
      }
    }

    return missing;
  }

  // Private helper methods

  Future<List<BusinessAccount>> _getAllBusinessAccounts() async {
    // In production, query database
    return [];
  }
}

/// User Business Match Result
class UserBusinessMatch {
  final BusinessAccount business;
  final UnifiedUser user;
  final double matchScore; // 0.0 to 1.0
  final String matchReason;
  final List<String> matchedCriteria;

  const UserBusinessMatch({
    required this.business,
    required this.user,
    required this.matchScore,
    required this.matchReason,
    required this.matchedCriteria,
  });
}

/// Business Compatibility Score
/// Detailed breakdown of how a user matches a business's patron preferences
class BusinessCompatibilityScore {
  final BusinessAccount business;
  final UnifiedUser user;
  final double overallScore; // 0.0 to 1.0
  final List<String> matchedCriteria;
  final List<String> missingCriteria;
  final String reason;

  const BusinessCompatibilityScore({
    required this.business,
    required this.user,
    required this.overallScore,
    required this.matchedCriteria,
    required this.missingCriteria,
    required this.reason,
  });

  /// Get percentage score for display
  int get percentageScore => (overallScore * 100).round();

  /// Check if user is a good match
  bool get isGoodMatch => overallScore >= 0.6;

  /// Get summary of why user matches or doesn't match
  String get summary {
    if (matchedCriteria.isEmpty && missingCriteria.isEmpty) {
      return reason;
    }
    
    final parts = <String>[];
    if (matchedCriteria.isNotEmpty) {
      parts.add('Matches: ${matchedCriteria.take(3).join(', ')}');
    }
    if (missingCriteria.isNotEmpty) {
      parts.add('Missing: ${missingCriteria.take(2).join(', ')}');
    }
    return parts.join(' • ');
  }
}

