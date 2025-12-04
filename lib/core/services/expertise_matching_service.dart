import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/logger.dart';

/// Expertise Matching Service
/// OUR_GUTS.md: "We help you connect with people" - Connect users based on expertise
class ExpertiseMatchingService {
  static const String _logName = 'ExpertiseMatchingService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  /// Find users with similar expertise
  /// Matches users who share expertise in the same categories
  Future<List<ExpertMatch>> findSimilarExperts(
    UnifiedUser user,
    String category, {
    String? location,
    int maxResults = 10,
  }) async {
    try {
      _logger.info('Finding similar experts for: ${user.id} in $category', tag: _logName);

      if (!user.hasExpertiseIn(category)) {
        _logger.warning('User does not have expertise in $category', tag: _logName);
        return [];
      }

      final userLevel = user.getExpertiseLevel(category);
      if (userLevel == null) return [];

      // Get all users (in production, this would be a database query)
      final allUsers = await _getAllUsers();
      final matches = <ExpertMatch>[];

      for (final otherUser in allUsers) {
        if (otherUser.id == user.id) continue;
        if (!otherUser.hasExpertiseIn(category)) continue;

        final otherLevel = otherUser.getExpertiseLevel(category);
        if (otherLevel == null) continue;

        // Calculate match score
        final matchScore = _calculateExpertiseMatchScore(
          userLevel: userLevel,
          otherLevel: otherLevel,
          userLocation: user.location,
          otherLocation: otherUser.location,
          requestedLocation: location,
        );

        if (matchScore > 0.3) {
          // Minimum threshold
          matches.add(ExpertMatch(
            user: otherUser,
            category: category,
            matchScore: matchScore,
            matchReason: _getMatchReason(userLevel, otherLevel, user.location, otherUser.location),
            commonExpertise: [category],
            complementaryExpertise: _findComplementaryExpertise(user, otherUser),
          ));
        }
      }

      // Sort by match score
      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));

      _logger.info('Found ${matches.length} similar experts', tag: _logName);
      return matches.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error finding similar experts', error: e, tag: _logName);
      return [];
    }
  }

  /// Find complementary experts (different but related expertise)
  /// e.g., Coffee Expert + Pastry Expert
  Future<List<ExpertMatch>> findComplementaryExperts(
    UnifiedUser user, {
    int maxResults = 10,
  }) async {
    try {
      _logger.info('Finding complementary experts for: ${user.id}', tag: _logName);

      final userCategories = user.getExpertiseCategories();
      if (userCategories.isEmpty) return [];

      // Define complementary categories
      final complementaryMap = _getComplementaryCategories();
      final allUsers = await _getAllUsers();
      final matches = <ExpertMatch>[];

      for (final category in userCategories) {
        final complementaryCategories = complementaryMap[category] ?? [];
        
        for (final compCategory in complementaryCategories) {
          for (final otherUser in allUsers) {
            if (otherUser.id == user.id) continue;
            if (!otherUser.hasExpertiseIn(compCategory)) continue;

            // Check if already matched
            if (matches.any((m) => m.user.id == otherUser.id)) continue;

            final matchScore = _calculateComplementaryScore(
              userCategory: category,
              userLevel: user.getExpertiseLevel(category),
              otherCategory: compCategory,
              otherLevel: otherUser.getExpertiseLevel(compCategory),
            );

            if (matchScore > 0.4) {
              matches.add(ExpertMatch(
                user: otherUser,
                category: compCategory,
                matchScore: matchScore,
                matchReason: 'Complementary expertise: $category + $compCategory',
                commonExpertise: [],
                complementaryExpertise: [category, compCategory],
              ));
            }
          }
        }
      }

      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return matches.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error finding complementary experts', error: e, tag: _logName);
      return [];
    }
  }

  /// Find mentors (higher level experts in same category)
  Future<List<ExpertMatch>> findMentors(
    UnifiedUser user,
    String category, {
    int maxResults = 5,
  }) async {
    try {
      final userLevel = user.getExpertiseLevel(category);
      if (userLevel == null) return [];

      final allUsers = await _getAllUsers();
      final mentors = <ExpertMatch>[];

      for (final otherUser in allUsers) {
        if (otherUser.id == user.id) continue;
        if (!otherUser.hasExpertiseIn(category)) continue;

        final otherLevel = otherUser.getExpertiseLevel(category);
        if (otherLevel == null) continue;

        // Must be higher level
        if (!otherLevel.isHigherThan(userLevel)) continue;

        final matchScore = _calculateMentorScore(userLevel, otherLevel);
        
        mentors.add(ExpertMatch(
          user: otherUser,
          category: category,
          matchScore: matchScore,
          matchReason: 'Mentor: ${otherLevel.displayName} Level in $category',
          commonExpertise: [category],
          complementaryExpertise: [],
        ));
      }

      mentors.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return mentors.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error finding mentors', error: e, tag: _logName);
      return [];
    }
  }

  /// Find mentees (lower level, same category)
  Future<List<ExpertMatch>> findMentees(
    UnifiedUser user,
    String category, {
    int maxResults = 10,
  }) async {
    try {
      final userLevel = user.getExpertiseLevel(category);
      if (userLevel == null) return [];

      final allUsers = await _getAllUsers();
      final mentees = <ExpertMatch>[];

      for (final otherUser in allUsers) {
        if (otherUser.id == user.id) continue;
        if (!otherUser.hasExpertiseIn(category)) continue;

        final otherLevel = otherUser.getExpertiseLevel(category);
        if (otherLevel == null) continue;

        // Must be lower level
        if (!otherLevel.isLowerThan(userLevel)) continue;

        final matchScore = _calculateMentorScore(otherLevel, userLevel);
        
        mentees.add(ExpertMatch(
          user: otherUser,
          category: category,
          matchScore: matchScore,
          matchReason: 'Mentee: ${otherLevel.displayName} Level in $category',
          commonExpertise: [category],
          complementaryExpertise: [],
        ));
      }

      mentees.sort((a, b) => b.matchScore.compareTo(a.matchScore));
      return mentees.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error finding mentees', error: e, tag: _logName);
      return [];
    }
  }

  // Private helper methods

  double _calculateExpertiseMatchScore({
    required ExpertiseLevel userLevel,
    required ExpertiseLevel otherLevel,
    String? userLocation,
    String? otherLocation,
    String? requestedLocation,
  }) {
    double score = 0.0;

    // Level similarity (closer levels = higher score)
    final levelDiff = (userLevel.index - otherLevel.index).abs();
    score += (1.0 - (levelDiff / ExpertiseLevel.values.length)) * 0.5;

    // Location match bonus
    if (requestedLocation != null) {
      if (otherLocation?.toLowerCase().contains(requestedLocation.toLowerCase()) ?? false) {
        score += 0.3;
      }
    } else if (userLocation != null && otherLocation != null) {
      if (userLocation.toLowerCase() == otherLocation.toLowerCase()) {
        score += 0.3;
      }
    }

    // Higher level bonus (prefer experts)
    if (otherLevel.isHigherThan(userLevel)) {
      score += 0.2;
    }

    return score.clamp(0.0, 1.0);
  }

  double _calculateComplementaryScore({
    required String userCategory,
    required ExpertiseLevel? userLevel,
    required String otherCategory,
    required ExpertiseLevel? otherLevel,
  }) {
    if (userLevel == null || otherLevel == null) return 0.0;

    // Both should have meaningful expertise (Local level or higher)
    if (userLevel.index < ExpertiseLevel.local.index ||
        otherLevel.index < ExpertiseLevel.local.index) {
      return 0.0;
    }

    // Higher levels = better complementary match
    return ((userLevel.index + otherLevel.index) / (ExpertiseLevel.values.length * 2)).clamp(0.0, 1.0);
  }

  double _calculateMentorScore(ExpertiseLevel menteeLevel, ExpertiseLevel mentorLevel) {
    final levelDiff = mentorLevel.index - menteeLevel.index;
    if (levelDiff <= 0) return 0.0;

    // Prefer mentors 1-2 levels above
    if (levelDiff == 1) return 1.0;
    if (levelDiff == 2) return 0.8;
    return 0.6; // Further apart, lower score
  }

  String _getMatchReason(
    ExpertiseLevel userLevel,
    ExpertiseLevel otherLevel,
    String? userLocation,
    String? otherLocation,
  ) {
    final levelText = userLevel == otherLevel
        ? 'Same level'
        : otherLevel.isHigherThan(userLevel)
            ? 'Higher level'
            : 'Lower level';
    
    final locationText = (userLocation != null && otherLocation != null && 
                          userLocation == otherLocation)
        ? ' in $userLocation'
        : '';
    
    return '$levelText expert$locationText';
  }

  List<String> _findComplementaryExpertise(UnifiedUser user1, UnifiedUser user2) {
    final user1Categories = user1.getExpertiseCategories();
    final user2Categories = user2.getExpertiseCategories();
    
    // Find categories where one has expertise and the other doesn't
    final complementary = <String>[];
    for (final cat in user1Categories) {
      if (!user2Categories.contains(cat)) {
        complementary.add(cat);
      }
    }
    for (final cat in user2Categories) {
      if (!user1Categories.contains(cat)) {
        complementary.add(cat);
      }
    }
    
    return complementary;
  }

  Map<String, List<String>> _getComplementaryCategories() {
    return {
      'Coffee': ['Pastry', 'Breakfast', 'Dessert'],
      'Restaurants': ['Bars', 'Wine', 'Dessert'],
      'Bookstores': ['Libraries', 'Cafes', 'Museums'],
      'Parks': ['Outdoor Activities', 'Hiking', 'Picnic Spots'],
      'Museums': ['Art Galleries', 'Historical Sites', 'Cultural Centers'],
      'Shopping': ['Fashion', 'Vintage', 'Markets'],
      'Bars': ['Restaurants', 'Live Music', 'Nightlife'],
    };
  }

  Future<List<UnifiedUser>> _getAllUsers() async {
    // Placeholder - in production, this would query the database
    return [];
  }
}

/// Expert Match Result
class ExpertMatch {
  final UnifiedUser user;
  final String category;
  final double matchScore; // 0.0 to 1.0
  final String matchReason;
  final List<String> commonExpertise;
  final List<String> complementaryExpertise;

  const ExpertMatch({
    required this.user,
    required this.category,
    required this.matchScore,
    required this.matchReason,
    required this.commonExpertise,
    required this.complementaryExpertise,
  });
}

