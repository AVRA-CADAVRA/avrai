import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/expertise_matching_service.dart';
import 'package:spots/core/services/golden_expert_ai_influence_service.dart';

/// Expert Recommendations Service
/// Provides recommendations based on expert preferences and validations
class ExpertRecommendationsService {
  static const String _logName = 'ExpertRecommendationsService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);
  
  final ExpertiseMatchingService _matchingService = ExpertiseMatchingService();
  final GoldenExpertAIInfluenceService _goldenExpertService = GoldenExpertAIInfluenceService();

  /// Get spot recommendations from experts
  Future<List<ExpertRecommendation>> getExpertRecommendations(
    UnifiedUser user, {
    String? category,
    int maxResults = 20,
  }) async {
    try {
      _logger.info('Getting expert recommendations for: ${user.id}', tag: _logName);

      // Find similar experts
      final categories = category != null 
          ? [category] 
          : user.getExpertiseCategories();
      
      if (categories.isEmpty) {
        // No expertise yet - use general recommendations
        return await _getGeneralExpertRecommendations(user, maxResults: maxResults);
      }

      // Use a Map to accumulate scores and experts before creating recommendations
      final recommendationData = <String, Map<String, dynamic>>{};

      for (final cat in categories) {
        final similarExperts = await _matchingService.findSimilarExperts(
          user,
          cat,
          maxResults: 5,
        );

        for (final expertMatch in similarExperts) {
          // Get golden expert weight if applicable
          final localExpertise = await _getLocalExpertiseForUser(expertMatch.user.id, cat);
          final goldenExpertWeight = _goldenExpertService.calculateInfluenceWeight(localExpertise);
          
          // Get spots recommended by this expert
          final expertSpots = await _getExpertRecommendedSpots(expertMatch.user, cat);
          
          for (final spot in expertSpots) {
            final spotId = spot.id;
            // Apply golden expert weight to match score
            final weightedScore = expertMatch.matchScore * goldenExpertWeight;
            
            if (recommendationData.containsKey(spotId)) {
              // Update existing recommendation
              final existing = recommendationData[spotId]!;
              (existing['experts'] as List<UnifiedUser>).add(expertMatch.user);
              existing['score'] = (existing['score'] as double) + weightedScore * 0.2;
            } else {
              // Create new recommendation entry
              recommendationData[spotId] = {
                'spot': spot,
                'category': cat,
                'score': weightedScore * 0.5,
                'experts': <UnifiedUser>[expertMatch.user],
                'reason': 'Recommended by ${expertMatch.user.displayName ?? expertMatch.user.id}',
              };
            }
          }
        }
      }

      // Convert map to list of ExpertRecommendation objects
      final recommendations = recommendationData.values.map((entry) {
        return ExpertRecommendation(
          spot: entry['spot'] as Spot,
          category: entry['category'] as String,
          recommendationScore: entry['score'] as double,
          recommendingExperts: entry['experts'] as List<UnifiedUser>,
          recommendationReason: entry['reason'] as String,
        );
      }).toList();

      // Sort by recommendation score
      recommendations.sort((a, b) => b.recommendationScore.compareTo(a.recommendationScore));

      _logger.info('Generated ${recommendations.length} expert recommendations', tag: _logName);
      return recommendations.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error getting expert recommendations', error: e, tag: _logName);
      return [];
    }
  }

  /// Get expert-curated lists
  Future<List<ExpertCuratedList>> getExpertCuratedLists(
    UnifiedUser user, {
    String? category,
    int maxResults = 10,
  }) async {
    try {
      _logger.info('Getting expert-curated lists for: ${user.id}', tag: _logName);

      final categories = category != null 
          ? [category] 
          : user.getExpertiseCategories();
      
      if (categories.isEmpty) {
        return [];
      }

      final curatedLists = <ExpertCuratedList>[];

      for (final cat in categories) {
        final experts = await _matchingService.findSimilarExperts(
          user,
          cat,
          maxResults: 10,
        );

        for (final expertMatch in experts) {
          // Get golden expert weight if applicable
          final localExpertise = await _getLocalExpertiseForUser(expertMatch.user.id, cat);
          final goldenExpertWeight = _goldenExpertService.calculateInfluenceWeight(localExpertise);
          
          // Get lists curated by this expert
          final expertLists = await _getExpertCuratedListsForCategory(
            expertMatch.user,
            cat,
          );

          for (final list in expertLists) {
            // Apply golden expert weight to respect count for sorting
            final weightedRespectCount = (list.respectCount * goldenExpertWeight).round();
            
            curatedLists.add(ExpertCuratedList(
              list: list,
              curator: expertMatch.user,
              category: cat,
              curatorExpertise: expertMatch.user.getExpertiseLevel(cat),
              respectCount: weightedRespectCount,
              originalRespectCount: list.respectCount, // Keep original for display
            ));
          }
        }
      }

      // Sort by respect count and expertise level
      curatedLists.sort((a, b) {
        final respectCompare = b.respectCount.compareTo(a.respectCount);
        if (respectCompare != 0) return respectCompare;
        
        final aLevel = a.curatorExpertise?.index ?? 0;
        final bLevel = b.curatorExpertise?.index ?? 0;
        return bLevel.compareTo(aLevel);
      });

      return curatedLists.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error getting expert-curated lists', error: e, tag: _logName);
      return [];
    }
  }

  /// Get expert-validated spots
  Future<List<Spot>> getExpertValidatedSpots({
    String? category,
    String? location,
    int maxResults = 20,
  }) async {
    try {
      _logger.info('Getting expert-validated spots', tag: _logName);

      // In production, this would query spots that have been validated by experts
      // For now, return empty list as placeholder
      return [];
    } catch (e) {
      _logger.error('Error getting expert-validated spots', error: e, tag: _logName);
      return [];
    }
  }

  // Private helper methods

  Future<List<ExpertRecommendation>> _getGeneralExpertRecommendations(
    UnifiedUser user, {
    int maxResults = 20,
  }) async {
    // Get recommendations from top experts in popular categories
    final popularCategories = ['Coffee', 'Restaurants', 'Parks', 'Museums'];
    final recommendations = <ExpertRecommendation>[];

    for (final category in popularCategories) {
      final expertSpots = await _getTopExpertSpots(category);
      for (final spot in expertSpots) {
        recommendations.add(ExpertRecommendation(
          spot: spot,
          category: category,
          recommendationScore: 0.5,
          recommendingExperts: [],
          recommendationReason: 'Popular in $category',
        ));
      }
    }

    return recommendations.take(maxResults).toList();
  }

  /// Get spots recommended by an expert in a category
  /// 
  /// **Flow:**
  /// 1. Get all lists curated by the expert
  /// 2. Filter lists by category
  /// 3. Extract spots from those lists
  /// 4. Get spots from expert's reviews in category
  /// 5. Combine and deduplicate spots
  /// 
  /// **Note:** Requires ListsRepository and SpotsRepository to be injected.
  /// Currently returns empty list - repositories need to be added to service.
  Future<List<Spot>> _getExpertRecommendedSpots(
    UnifiedUser expert,
    String category,
  ) async {
    try {
      _logger.info(
        'Getting expert recommended spots: expert=${expert.id}, category=$category',
        tag: _logName,
      );
      
      // In production, this would:
      // 1. Query lists curated by expert: ListsRepository.getListsByUser(expert.id)
      // 2. Filter lists by category
      // 3. Get spots from those lists: ListsRepository.getSpotsInList(listId)
      // 4. Filter spots by category
      // 5. Query spots from expert reviews: SpotsRepository.getSpotsReviewedByUser(expert.id, category)
      // 6. Combine and deduplicate
      
      // Example query structure:
      // SELECT DISTINCT s.* FROM spots s
      // INNER JOIN spot_list_items sli ON s.id = sli.spot_id
      // INNER JOIN spot_lists sl ON sli.list_id = sl.id
      // WHERE sl.created_by = $expertId AND s.category = $category
      // UNION
      // SELECT DISTINCT s.* FROM spots s
      // INNER JOIN reviews r ON s.id = r.spot_id
      // WHERE r.user_id = $expertId AND s.category = $category AND r.rating >= 4
      
      _logger.warn(
        'Expert spots query requires ListsRepository and SpotsRepository injection. '
        'Expert: ${expert.id}, Category: $category - returning empty list.',
        tag: _logName,
      );
      
      return [];
    } catch (e) {
      _logger.error('Error getting expert recommended spots', error: e, tag: _logName);
      return [];
    }
  }

  /// Get lists curated by an expert in a category
  /// 
  /// **Flow:**
  /// 1. Query lists created by expert
  /// 2. Filter lists that contain spots in the category
  /// 3. Return list of lists
  /// 
  /// **Note:** Requires ListsRepository to be injected.
  /// Currently returns empty list - repository needs to be added to service.
  Future<List<dynamic>> _getExpertCuratedListsForCategory(
    UnifiedUser expert,
    String category,
  ) async {
    try {
      _logger.info(
        'Getting expert curated lists: expert=${expert.id}, category=$category',
        tag: _logName,
      );
      
      // In production, this would:
      // 1. Query lists by expert: ListsRepository.getListsByUser(expert.id)
      // 2. For each list, check if it contains spots in category
      // 3. Filter and return lists that have spots in the category
      
      // Example query structure:
      // SELECT DISTINCT sl.* FROM spot_lists sl
      // INNER JOIN spot_list_items sli ON sl.id = sli.list_id
      // INNER JOIN spots s ON sli.spot_id = s.id
      // WHERE sl.created_by = $expertId AND s.category = $category
      
      _logger.warn(
        'Expert lists query requires ListsRepository injection. '
        'Expert: ${expert.id}, Category: $category - returning empty list.',
        tag: _logName,
      );
      
      return [];
    } catch (e) {
      _logger.error('Error getting expert curated lists', error: e, tag: _logName);
      return [];
    }
  }

  /// Get top-rated spots in a category
  /// 
  /// **Flow:**
  /// 1. Query spots in category
  /// 2. Sort by rating/respect count
  /// 3. Return top spots
  /// 
  /// **Note:** Requires SpotsRepository to be injected.
  /// Currently returns empty list - repository needs to be added to service.
  Future<List<Spot>> _getTopExpertSpots(String category) async {
    try {
      _logger.info('Getting top expert spots in category: $category', tag: _logName);
      
      // In production, this would:
      // 1. Query spots by category: SpotsRepository.getSpotsByCategory(category)
      // 2. Sort by respect count, rating, or combined score
      // 3. Return top N spots
      
      // Example query structure:
      // SELECT * FROM spots
      // WHERE category = $category
      // ORDER BY respect_count DESC, average_rating DESC
      // LIMIT 20
      
      _logger.warn(
        'Top spots query requires SpotsRepository injection. '
        'Category: $category - returning empty list.',
        tag: _logName,
      );
      
      return [];
    } catch (e) {
      _logger.error('Error getting top expert spots', error: e, tag: _logName);
      return [];
    }
  }

  /// Get LocalExpertise for a user in a category
  /// 
  /// **Flow:**
  /// 1. Query database for LocalExpertise records for user and category
  /// 2. If multiple localities exist, return the highest-scoring one
  /// 3. Return LocalExpertise if found, null otherwise
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `category`: Category
  /// 
  /// **Returns:**
  /// LocalExpertise with highest score for the user in the category, null if none found
  /// 
  /// **Note:** In production, this would query the database for stored LocalExpertise.
  /// Currently returns null - requires database integration or LocalExpertise storage service.
  Future<LocalExpertise?> _getLocalExpertiseForUser(
    String userId,
    String category,
  ) async {
    try {
      _logger.info(
        'Getting local expertise for user: user=$userId, category=$category',
        tag: _logName,
      );
      
      // In production, this would query the database for LocalExpertise:
      // SELECT * FROM local_expertise
      // WHERE user_id = $userId AND category = $category
      // ORDER BY score DESC
      // LIMIT 1
      
      // Alternatively, if LocalExpertise is stored in MultiPathExpertiseService's cache,
      // we could query from there. However, the service currently only calculates expertise
      // and doesn't store/query existing records.
      
      // For now, return null as placeholder
      // TODO: Implement database query or LocalExpertise storage service
      // TODO: Or integrate with MultiPathExpertiseService if it stores calculated expertise
      
      _logger.warn(
        'LocalExpertise query requires database integration. '
        'User: $userId, Category: $category - returning null.',
        tag: _logName,
      );
      
      return null;
    } catch (e) {
      _logger.error(
        'Error getting local expertise for user',
        error: e,
        tag: _logName,
      );
      return null;
    }
  }
}

/// Expert Recommendation
class ExpertRecommendation {
  final Spot spot;
  final String category;
  final double recommendationScore;
  final List<UnifiedUser> recommendingExperts;
  final String recommendationReason;

  ExpertRecommendation({
    required this.spot,
    required this.category,
    required this.recommendationScore,
    required this.recommendingExperts,
    required this.recommendationReason,
  });
}

/// Expert Curated List
class ExpertCuratedList {
  final dynamic list; // UnifiedList
  final UnifiedUser curator;
  final String category;
  final ExpertiseLevel? curatorExpertise;
  final int respectCount; // Weighted respect count for sorting
  final int? originalRespectCount; // Original respect count for display

  ExpertCuratedList({
    required this.list,
    required this.curator,
    required this.category,
    this.curatorExpertise,
    required this.respectCount,
    this.originalRespectCount,
  });
}

