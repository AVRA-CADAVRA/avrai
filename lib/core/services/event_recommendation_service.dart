import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/event_matching_service.dart';
import 'package:spots/core/services/user_preference_learning_service.dart';
import 'package:spots/core/services/cross_locality_connection_service.dart';
import 'package:spots/core/services/logger.dart';

/// Event Recommendation Service
/// 
/// Generates personalized event recommendations by combining:
/// - User preferences (learned from attendance patterns)
/// - Event matching scores (from EventMatchingService)
/// - Cross-locality connections (from CrossLocalityConnectionService)
/// 
/// **Philosophy:** "Doors, not badges" - Opens doors to events users will enjoy
/// 
/// **What Doors Does This Open?**
/// - Discovery Doors: Users find events matching their preferences
/// - Exploration Doors: Users discover events outside typical behavior
/// - Connection Doors: Users find events in connected localities
/// - Preference Doors: System learns and adapts to user preferences
/// 
/// **Recommendation Strategy:**
/// - Balance familiar preferences with exploration (70% familiar, 30% exploration)
/// - Show local expert events to users who prefer local events
/// - Show city/state events to users who prefer broader scope
/// - Include cross-locality events for users with movement patterns
class EventRecommendationService {
  static const String _logName = 'EventRecommendationService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final ExpertiseEventService _eventService;
  final EventMatchingService _matchingService;
  final UserPreferenceLearningService _preferenceService;
  final CrossLocalityConnectionService _crossLocalityService;

  EventRecommendationService({
    ExpertiseEventService? eventService,
    EventMatchingService? matchingService,
    UserPreferenceLearningService? preferenceService,
    CrossLocalityConnectionService? crossLocalityService,
  })  : _eventService = eventService ?? ExpertiseEventService(),
        _matchingService =
            matchingService ?? EventMatchingService(),
        _preferenceService =
            preferenceService ?? UserPreferenceLearningService(),
        _crossLocalityService =
            crossLocalityService ?? CrossLocalityConnectionService();

  /// Get personalized event recommendations
  /// 
  /// **Parameters:**
  /// - `user`: User to get recommendations for
  /// - `category`: Optional category filter
  /// - `location`: Optional location filter
  /// - `maxResults`: Maximum number of recommendations
  /// - `explorationRatio`: Ratio of exploration events (0.0 to 1.0, default 0.3)
  /// 
  /// **Returns:**
  /// List of event recommendations sorted by relevance score
  /// 
  /// **Recommendation Process:**
  /// 1. Get user preferences
  /// 2. Get matching scores for events
  /// 3. Combine preferences with matching scores
  /// 4. Balance familiar preferences with exploration
  /// 5. Sort by relevance score
  Future<List<EventRecommendation>> getPersonalizedRecommendations({
    required UnifiedUser user,
    String? category,
    String? location,
    int maxResults = 20,
    double explorationRatio = 0.3,
  }) async {
    try {
      _logger.info(
        'Getting personalized recommendations for user: ${user.id}',
        tag: _logName,
      );

      // Get user preferences
      final preferences = await _preferenceService.getUserPreferences(user: user);

      // Get all available events
      final allEvents = await _eventService.searchEvents(
        category: category,
        location: location,
        maxResults: 100, // Get more events to filter from
      );

      // Calculate relevance scores for each event
      final recommendations = <EventRecommendation>[];

      for (final event in allEvents) {
        final relevanceScore = await _calculateRelevanceScore(
          event: event,
          user: user,
          preferences: preferences,
          category: category,
          location: location,
        );

        recommendations.add(EventRecommendation(
          event: event,
          relevanceScore: relevanceScore,
          recommendationReason: _generateRecommendationReason(
            event: event,
            preferences: preferences,
            relevanceScore: relevanceScore,
          ),
        ));
      }

      // Separate familiar and exploration recommendations
      final familiarRecommendations = recommendations
          .where((r) => r.relevanceScore >= 0.6)
          .toList();
      final explorationRecommendations = recommendations
          .where((r) => r.relevanceScore < 0.6 && r.relevanceScore >= 0.3)
          .toList();

      // Balance familiar with exploration
      final familiarCount = ((1.0 - explorationRatio) * maxResults).round();
      final explorationCount = (explorationRatio * maxResults).round();

      // Sort by relevance score
      familiarRecommendations.sort((a, b) =>
          b.relevanceScore.compareTo(a.relevanceScore));
      explorationRecommendations.sort((a, b) =>
          b.relevanceScore.compareTo(a.relevanceScore));

      // Combine recommendations
      final combined = <EventRecommendation>[
        ...familiarRecommendations.take(familiarCount),
        ...explorationRecommendations.take(explorationCount),
      ];

      // Final sort by relevance score
      combined.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));

      return combined.take(maxResults).toList();
    } catch (e) {
      _logger.error(
        'Error getting personalized recommendations',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get recommendations for specific scope
  /// 
  /// **Parameters:**
  /// - `user`: User to get recommendations for
  /// - `scope`: Scope to filter by (local, city, state, national, global, universal)
  /// - `category`: Optional category filter
  /// - `maxResults`: Maximum number of recommendations
  /// 
  /// **Returns:**
  /// List of event recommendations for the specified scope
  /// 
  /// **Usage:**
  /// Used for tab-based filtering in EventsBrowsePage
  Future<List<EventRecommendation>> getRecommendationsForScope({
    required UnifiedUser user,
    required String scope,
    String? category,
    int maxResults = 20,
  }) async {
    try {
      _logger.info(
        'Getting recommendations for scope: $scope, user: ${user.id}',
        tag: _logName,
      );

      // Get user preferences
      final preferences = await _preferenceService.getUserPreferences(user: user);

      // Filter events by scope
      final scopeEvents = await _getEventsByScope(
        user: user,
        scope: scope,
        category: category,
      );

      // Calculate relevance scores
      final recommendations = <EventRecommendation>[];

      for (final event in scopeEvents) {
        final relevanceScore = await _calculateRelevanceScore(
          event: event,
          user: user,
          preferences: preferences,
          category: category,
          location: null,
        );

        recommendations.add(EventRecommendation(
          event: event,
          relevanceScore: relevanceScore,
          recommendationReason: _generateRecommendationReason(
            event: event,
            preferences: preferences,
            relevanceScore: relevanceScore,
          ),
        ));
      }

      // Sort by relevance score
      recommendations.sort((a, b) =>
          b.relevanceScore.compareTo(a.relevanceScore));

      return recommendations.take(maxResults).toList();
    } catch (e) {
      _logger.error(
        'Error getting recommendations for scope',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  // Private helper methods

  /// Calculate relevance score for an event
  /// 
  /// **Combines:**
  /// - Matching score (from EventMatchingService): 40%
  /// - Preference match: 40%
  /// - Cross-locality boost: 20%
  Future<double> _calculateRelevanceScore({
    required ExpertiseEvent event,
    required UnifiedUser user,
    required UserPreferences preferences,
    String? category,
    String? location,
  }) async {
    double score = 0.0;

    // 1. Matching score (40% weight)
    final matchingScore = await _matchingService.calculateMatchingScore(
      expert: event.host,
      user: user,
      category: event.category,
      locality: _extractLocality(event.location) ?? '',
    );
    score += matchingScore * 0.4;

    // 2. Preference match (40% weight)
    final preferenceScore = _calculatePreferenceScore(
      event: event,
      preferences: preferences,
    );
    score += preferenceScore * 0.4;

    // 3. Cross-locality boost (20% weight)
    final crossLocalityScore = await _calculateCrossLocalityScore(
      event: event,
      user: user,
    );
    score += crossLocalityScore * 0.2;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate preference match score
  double _calculatePreferenceScore({
    required ExpertiseEvent event,
    required UserPreferences preferences,
  }) {
    double score = 0.0;

    // Category preference
    final categoryWeight = preferences.categoryPreferences[event.category] ?? 0.0;
    score += categoryWeight * 0.3;

    // Locality preference
    final locality = _extractLocality(event.location);
    if (locality != null) {
      final localityWeight = preferences.localityPreferences[locality] ?? 0.0;
      score += localityWeight * 0.2;
    }

    // Scope preference (based on host expertise level)
    final hostLevel = event.host.getExpertiseLevel(event.category);
    if (hostLevel != null) {
      final scope = _getScopeFromLevel(hostLevel);
      final scopeWeight = preferences.scopePreferences[scope] ?? 0.0;
      score += scopeWeight * 0.2;
    }

    // Local vs city expert preference
    if (hostLevel == ExpertiseLevel.local && preferences.prefersLocalExperts) {
      score += 0.2; // Boost for local experts if user prefers them
    } else if (hostLevel != null &&
        hostLevel != ExpertiseLevel.local &&
        preferences.prefersCityExperts) {
      score += 0.1; // Boost for city experts if user prefers them
    }

    // Event type preference
    final typeWeight =
        preferences.eventTypePreferences[event.eventType] ?? 0.0;
    score += typeWeight * 0.1;

    return score.clamp(0.0, 1.0);
  }

  /// Calculate cross-locality connection score
  Future<double> _calculateCrossLocalityScore({
    required ExpertiseEvent event,
    required UnifiedUser user,
  }) async {
    final eventLocality = _extractLocality(event.location);
    if (eventLocality == null) return 0.0;

    // Get user's locality
    final userLocality = _extractLocality(user.location);
    if (userLocality == null) return 0.0;

    // If event is in user's locality, no cross-locality boost needed
    if (eventLocality.toLowerCase() == userLocality.toLowerCase()) {
      return 0.0;
    }

    // Get connected localities
    final connectedLocalities =
        await _crossLocalityService.getConnectedLocalities(
      user: user,
      locality: userLocality,
    );

    // Check if event locality is connected
    for (final connected in connectedLocalities) {
      if (connected.locality.toLowerCase() ==
          eventLocality.toLowerCase()) {
        return connected.connectionStrength;
      }
    }

    return 0.0; // Not in connected localities
  }

  /// Get events by scope
  Future<List<ExpertiseEvent>> _getEventsByScope({
    required UnifiedUser user,
    required String scope,
    String? category,
  }) async {
    // Get all events
    final allEvents = await _eventService.searchEvents(
      category: category,
      maxResults: 100,
    );

    // Filter by scope
    return allEvents.where((event) {
      final hostLevel = event.host.getExpertiseLevel(event.category);
      if (hostLevel == null) return false;

      final eventScope = _getScopeFromLevel(hostLevel);
      return eventScope.toLowerCase() == scope.toLowerCase();
    }).toList();
  }

  /// Get scope name from expertise level
  String _getScopeFromLevel(ExpertiseLevel level) {
    switch (level) {
      case ExpertiseLevel.local:
        return 'local';
      case ExpertiseLevel.city:
        return 'city';
      case ExpertiseLevel.regional:
        return 'state';
      case ExpertiseLevel.national:
        return 'national';
      case ExpertiseLevel.global:
        return 'global';
      case ExpertiseLevel.universal:
        return 'universal';
    }
  }

  /// Generate recommendation reason
  String _generateRecommendationReason({
    required ExpertiseEvent event,
    required UserPreferences preferences,
    required double relevanceScore,
  }) {
    final reasons = <String>[];

    // Category match
    if (preferences.categoryPreferences.containsKey(event.category)) {
      reasons.add('Matches your interest in ${event.category}');
    }

    // Locality match
    final locality = _extractLocality(event.location);
    if (locality != null &&
        preferences.localityPreferences.containsKey(locality)) {
      reasons.add('In ${locality}, which you frequent');
    }

    // Local expert preference
    final hostLevel = event.host.getExpertiseLevel(event.category);
    if (hostLevel == ExpertiseLevel.local && preferences.prefersLocalExperts) {
      reasons.add('Hosted by a local expert (you prefer local events)');
    }

    // High relevance
    if (relevanceScore >= 0.8) {
      reasons.add('Highly relevant to your preferences');
    }

    return reasons.isNotEmpty
        ? reasons.join(' • ')
        : 'Recommended based on your activity';
  }

  /// Extract locality from location string
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }
}

/// Event Recommendation Model
class EventRecommendation {
  final ExpertiseEvent event;
  final double relevanceScore; // 0.0 to 1.0
  final String recommendationReason;

  const EventRecommendation({
    required this.event,
    required this.relevanceScore,
    required this.recommendationReason,
  });
}

