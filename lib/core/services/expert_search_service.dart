import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/logger.dart';

/// Expert Search Service
/// Enables finding experts by category, location, and level
class ExpertSearchService {
  static const String _logName = 'ExpertSearchService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  /// Search for experts
  Future<List<ExpertSearchResult>> searchExperts({
    String? category,
    String? location,
    ExpertiseLevel? minLevel,
    int maxResults = 20,
  }) async {
    try {
      _logger.info('Searching experts: category=$category, location=$location', tag: _logName);

      final allUsers = await _getAllUsers();
      final results = <ExpertSearchResult>[];

      for (final user in allUsers) {
        // Filter by category
        if (category != null && !user.hasExpertiseIn(category)) {
          continue;
        }

        // Filter by location
        if (location != null && user.location != null) {
          if (!user.location!.toLowerCase().contains(location.toLowerCase())) {
            continue;
          }
        }

        // Filter by minimum level
        if (category != null && minLevel != null) {
          final userLevel = user.getExpertiseLevel(category);
          if (userLevel == null || userLevel.index < minLevel.index) {
            continue;
          }
        }

        // Calculate relevance score
        final relevanceScore = _calculateRelevanceScore(
          user: user,
          category: category,
          location: location,
          minLevel: minLevel,
        );

        if (relevanceScore > 0.0) {
          results.add(ExpertSearchResult(
            user: user,
            relevanceScore: relevanceScore,
            matchingCategories: category != null ? [category] : user.getExpertiseCategories(),
            location: user.location,
          ));
        }
      }

      // Sort by relevance
      results.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      _logger.info('Found ${results.length} experts', tag: _logName);
      return results.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error searching experts', error: e, tag: _logName);
      return [];
    }
  }

  /// Get top experts in a category
  /// Includes Local level experts and above
  Future<List<ExpertSearchResult>> getTopExperts(
    String category, {
    String? location,
    int maxResults = 10,
  }) async {
    return searchExperts(
      category: category,
      location: location,
      minLevel: ExpertiseLevel.local, // Include Local level experts
      maxResults: maxResults,
    );
  }

  /// Get experts near a location
  Future<List<ExpertSearchResult>> getExpertsNearLocation(
    String location, {
    int maxResults = 20,
  }) async {
    return searchExperts(
      location: location,
      maxResults: maxResults,
    );
  }

  /// Get experts by level
  Future<List<ExpertSearchResult>> getExpertsByLevel(
    ExpertiseLevel level, {
    String? category,
    int maxResults = 20,
  }) async {
    return searchExperts(
      category: category,
      minLevel: level,
      maxResults: maxResults,
    );
  }

  // Private helper methods

  double _calculateRelevanceScore({
    required UnifiedUser user,
    String? category,
    String? location,
    ExpertiseLevel? minLevel,
  }) {
    double score = 0.0;

    if (category != null) {
      final level = user.getExpertiseLevel(category);
      if (level != null) {
        // Higher level = higher score
        score += (level.index + 1) / ExpertiseLevel.values.length;
      }
    } else {
      // No specific category - score based on highest expertise
      final categories = user.getExpertiseCategories();
      if (categories.isNotEmpty) {
        final highestLevel = categories
            .map((cat) => user.getExpertiseLevel(cat))
            .whereType<ExpertiseLevel>()
            .fold<ExpertiseLevel>(
              ExpertiseLevel.local,
              (prev, curr) => curr.isHigherThan(prev) ? curr : prev,
            );
        score += (highestLevel.index + 1) / ExpertiseLevel.values.length;
      }
    }

    // Location match bonus
    if (location != null && user.location != null) {
      if (user.location!.toLowerCase().contains(location.toLowerCase())) {
        score += 0.3;
      }
    }

    // Community engagement bonus
    score += (user.totalListInvolvement / 100.0).clamp(0.0, 0.2);

    return score.clamp(0.0, 1.0);
  }

  Future<List<UnifiedUser>> _getAllUsers() async {
    // Placeholder - in production, this would query the database
    return [];
  }
}

/// Expert Search Result
class ExpertSearchResult {
  final UnifiedUser user;
  final double relevanceScore;
  final List<String> matchingCategories;
  final String? location;

  const ExpertSearchResult({
    required this.user,
    required this.relevanceScore,
    required this.matchingCategories,
    this.location,
  });
}

