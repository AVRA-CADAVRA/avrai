import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/expertise_event_service.dart';
import 'package:spots/core/services/logger.dart';

/// User Preference Learning Service
/// 
/// Learns user preferences from event attendance patterns and behavior.
/// Balances familiar preferences with exploration opportunities.
/// 
/// **Philosophy:** "Doors, not badges" - Opens doors to events users will enjoy
/// 
/// **What Doors Does This Open?**
/// - Discovery Doors: Users find events matching their preferences
/// - Exploration Doors: Users discover events outside typical behavior
/// - Preference Doors: System learns and adapts to user preferences
/// 
/// **Learning Areas:**
/// - Local vs city experts (preference weight)
/// - Category preferences (which categories user prefers)
/// - Locality preferences (which localities user prefers)
/// - Scope preferences (local vs city vs state events)
/// - Event type preferences (workshop vs tour vs tasting)
class UserPreferenceLearningService {
  static const String _logName = 'UserPreferenceLearningService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final ExpertiseEventService _eventService;

  UserPreferenceLearningService({
    ExpertiseEventService? eventService,
  }) : _eventService = eventService ?? ExpertiseEventService();

  /// Learn user preferences from event history
  /// 
  /// **Parameters:**
  /// - `user`: User to learn preferences for
  /// 
  /// **Returns:**
  /// UserPreferences object with learned preferences
  /// 
  /// **Process:**
  /// 1. Analyze user event attendance history
  /// 2. Calculate preference weights for each area
  /// 3. Update user preference profile
  /// 4. Return learned preferences
  Future<UserPreferences> learnUserPreferences({
    required UnifiedUser user,
  }) async {
    try {
      _logger.info('Learning preferences for user: ${user.id}', tag: _logName);

      // Get user's event attendance history
      final attendedEvents = await _eventService.getEventsByAttendee(user);

      // Learn preferences from attendance patterns
      final localVsCityPreference = _learnLocalVsCityPreference(
        user: user,
        events: attendedEvents,
      );

      final categoryPreferences = _learnCategoryPreferences(
        events: attendedEvents,
      );

      final localityPreferences = _learnLocalityPreferences(
        user: user,
        events: attendedEvents,
      );

      final scopePreferences = _learnScopePreferences(
        user: user,
        events: attendedEvents,
      );

      final eventTypePreferences = _learnEventTypePreferences(
        events: attendedEvents,
      );

      return UserPreferences(
        userId: user.id,
        localVsCityPreference: localVsCityPreference,
        categoryPreferences: categoryPreferences,
        localityPreferences: localityPreferences,
        scopePreferences: scopePreferences,
        eventTypePreferences: eventTypePreferences,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Error learning user preferences', error: e, tag: _logName);
      return UserPreferences.empty(userId: user.id);
    }
  }

  /// Get current user preferences
  /// 
  /// **Parameters:**
  /// - `user`: User to get preferences for
  /// 
  /// **Returns:**
  /// Current UserPreferences object with preference weights
  /// 
  /// **Note:**
  /// If preferences haven't been learned yet, calls learnUserPreferences()
  Future<UserPreferences> getUserPreferences({
    required UnifiedUser user,
  }) async {
    try {
      // In production, this would load from cache/database
      // For now, always learn from current data
      return await learnUserPreferences(user: user);
    } catch (e) {
      _logger.error('Error getting user preferences', error: e, tag: _logName);
      return UserPreferences.empty(userId: user.id);
    }
  }

  /// Suggest events outside typical behavior (exploration)
  /// 
  /// **Parameters:**
  /// - `user`: User to suggest exploration events for
  /// - `maxSuggestions`: Maximum number of suggestions to return
  /// 
  /// **Returns:**
  /// List of exploration opportunities (events in new categories/localities)
  /// 
  /// **Philosophy:**
  /// Balance familiar preferences with exploration
  /// Suggest events that are different but still potentially interesting
  Future<List<ExplorationOpportunity>> suggestExplorationEvents({
    required UnifiedUser user,
    int maxSuggestions = 5,
  }) async {
    try {
      _logger.info(
        'Suggesting exploration events for user: ${user.id}',
        tag: _logName,
      );

      final preferences = await getUserPreferences(user: user);
      final attendedEvents = await _eventService.getEventsByAttendee(user);

      // Identify exploration opportunities
      final opportunities = <ExplorationOpportunity>[];

      // Find categories user hasn't explored
      final exploredCategories = attendedEvents
          .map((e) => e.category)
          .toSet();
      final allCategories = await _getAllCategories();
      final unexploredCategories = allCategories
          .where((cat) => !exploredCategories.contains(cat))
          .toList();

      // Find localities user hasn't explored
      final exploredLocalities = attendedEvents
          .map((e) => _extractLocality(e.location))
          .where((loc) => loc != null)
          .toSet();
      final allLocalities = await _getAllLocalities();
      final unexploredLocalities = allLocalities
          .where((loc) => !exploredLocalities.contains(loc))
          .toList();

      // Create exploration opportunities
      for (final category in unexploredCategories.take(3)) {
        opportunities.add(ExplorationOpportunity(
          type: ExplorationType.newCategory,
          category: category,
          reason: 'You haven\'t explored $category events yet',
          confidence: 0.7,
        ));
      }

      for (final locality in unexploredLocalities.take(2)) {
        opportunities.add(ExplorationOpportunity(
          type: ExplorationType.newLocality,
          locality: locality,
          reason: 'Discover events in $locality',
          confidence: 0.6,
        ));
      }

      // Sort by confidence (highest first)
      opportunities.sort((a, b) => b.confidence.compareTo(a.confidence));

      return opportunities.take(maxSuggestions).toList();
    } catch (e) {
      _logger.error(
        'Error suggesting exploration events',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  // Private helper methods

  /// Learn local vs city expert preference
  /// 
  /// **Returns:**
  /// Preference weight (0.0 to 1.0)
  /// - 0.0-0.4: Prefers city/state/national experts
  /// - 0.5: Neutral
  /// - 0.6-1.0: Prefers local experts
  double _learnLocalVsCityPreference({
    required UnifiedUser user,
    required List<ExpertiseEvent> events,
  }) {
    if (events.isEmpty) return 0.5; // Neutral if no data

    int localExpertEvents = 0;
    int cityExpertEvents = 0;
    int totalEvents = 0;

    for (final event in events) {
      final hostLevel = event.host.getExpertiseLevel(event.category);
      if (hostLevel == null) continue;

      totalEvents++;
      if (hostLevel == ExpertiseLevel.local) {
        localExpertEvents++;
      } else if (hostLevel == ExpertiseLevel.city ||
          hostLevel == ExpertiseLevel.regional ||
          hostLevel == ExpertiseLevel.national) {
        cityExpertEvents++;
      }
    }

    if (totalEvents == 0) return 0.5;

    // Calculate preference: more local events = higher preference
    final localRatio = localExpertEvents / totalEvents;
    return localRatio.clamp(0.0, 1.0);
  }

  /// Learn category preferences
  /// 
  /// **Returns:**
  /// Map of category -> preference weight (0.0 to 1.0)
  Map<String, double> _learnCategoryPreferences({
    required List<ExpertiseEvent> events,
  }) {
    if (events.isEmpty) return {};

    // Count events per category
    final categoryCounts = <String, int>{};
    for (final event in events) {
      categoryCounts[event.category] =
          (categoryCounts[event.category] ?? 0) + 1;
    }

    // Calculate preference weights (normalized)
    final totalEvents = events.length;
    final preferences = <String, double>{};

    for (final entry in categoryCounts.entries) {
      final weight = entry.value / totalEvents;
      preferences[entry.key] = weight.clamp(0.0, 1.0);
    }

    return preferences;
  }

  /// Learn locality preferences
  /// 
  /// **Returns:**
  /// Map of locality -> preference weight (0.0 to 1.0)
  Map<String, double> _learnLocalityPreferences({
    required UnifiedUser user,
    required List<ExpertiseEvent> events,
  }) {
    if (events.isEmpty) return {};

    // Count events per locality
    final localityCounts = <String, int>{};
    for (final event in events) {
      final locality = _extractLocality(event.location);
      if (locality != null) {
        localityCounts[locality] = (localityCounts[locality] ?? 0) + 1;
      }
    }

    // Calculate preference weights (normalized)
    final totalEvents = events.length;
    final preferences = <String, double>{};

    for (final entry in localityCounts.entries) {
      final weight = entry.value / totalEvents;
      preferences[entry.key] = weight.clamp(0.0, 1.0);
    }

    return preferences;
  }

  /// Learn scope preferences
  /// 
  /// **Returns:**
  /// Map of scope -> preference weight (0.0 to 1.0)
  /// Scopes: local, city, state, national, global, universal
  Map<String, double> _learnScopePreferences({
    required UnifiedUser user,
    required List<ExpertiseEvent> events,
  }) {
    if (events.isEmpty) return {};

    // Count events by scope (based on host expertise level)
    final scopeCounts = <String, int>{};
    for (final event in events) {
      final hostLevel = event.host.getExpertiseLevel(event.category);
      if (hostLevel == null) continue;

      final scope = _getScopeFromLevel(hostLevel);
      scopeCounts[scope] = (scopeCounts[scope] ?? 0) + 1;
    }

    // Calculate preference weights (normalized)
    final totalEvents = events.length;
    final preferences = <String, double>{};

    for (final entry in scopeCounts.entries) {
      final weight = entry.value / totalEvents;
      preferences[entry.key] = weight.clamp(0.0, 1.0);
    }

    return preferences;
  }

  /// Learn event type preferences
  /// 
  /// **Returns:**
  /// Map of event type -> preference weight (0.0 to 1.0)
  Map<ExpertiseEventType, double> _learnEventTypePreferences({
    required List<ExpertiseEvent> events,
  }) {
    if (events.isEmpty) return {};

    // Count events per type
    final typeCounts = <ExpertiseEventType, int>{};
    for (final event in events) {
      typeCounts[event.eventType] =
          (typeCounts[event.eventType] ?? 0) + 1;
    }

    // Calculate preference weights (normalized)
    final totalEvents = events.length;
    final preferences = <ExpertiseEventType, double>{};

    for (final entry in typeCounts.entries) {
      final weight = entry.value / totalEvents;
      preferences[entry.key] = weight.clamp(0.0, 1.0);
    }

    return preferences;
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

  /// Extract locality from location string
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }

  /// Get all available categories
  /// 
  /// **Note:** In production, this would query database
  Future<List<String>> _getAllCategories() async {
    // Placeholder: Return common categories
    return [
      'Coffee',
      'Food',
      'Art',
      'Music',
      'Outdoor',
      'Fitness',
      'Books',
      'Tech',
      'Wellness',
      'Travel',
    ];
  }

  /// Get all available localities
  /// 
  /// **Note:** In production, this would query database
  Future<List<String>> _getAllLocalities() async {
    // Placeholder: Return empty list
    // In production, query localities from database
    return [];
  }
}

/// User Preferences Model
class UserPreferences {
  final String userId;
  final double localVsCityPreference; // 0.0-1.0 (higher = prefers local)
  final Map<String, double> categoryPreferences; // category -> weight
  final Map<String, double> localityPreferences; // locality -> weight
  final Map<String, double> scopePreferences; // scope -> weight
  final Map<ExpertiseEventType, double> eventTypePreferences; // type -> weight
  final DateTime lastUpdated;

  const UserPreferences({
    required this.userId,
    this.localVsCityPreference = 0.5,
    this.categoryPreferences = const {},
    this.localityPreferences = const {},
    this.scopePreferences = const {},
    this.eventTypePreferences = const {},
    required this.lastUpdated,
  });

  factory UserPreferences.empty({required String userId}) {
    return UserPreferences(
      userId: userId,
      localVsCityPreference: 0.5,
      categoryPreferences: {},
      localityPreferences: {},
      scopePreferences: {},
      eventTypePreferences: {},
      lastUpdated: DateTime.now(),
    );
  }

  /// Check if user prefers local experts
  bool get prefersLocalExperts => localVsCityPreference >= 0.6;

  /// Check if user prefers city/state/national experts
  bool get prefersCityExperts => localVsCityPreference <= 0.4;

  /// Get top preferred categories
  List<String> get topCategories {
    final sorted = categoryPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }

  /// Get top preferred localities
  List<String> get topLocalities {
    final sorted = localityPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(3).map((e) => e.key).toList();
  }
}

/// Exploration Opportunity Model
class ExplorationOpportunity {
  final ExplorationType type;
  final String? category;
  final String? locality;
  final String reason;
  final double confidence; // 0.0 to 1.0

  const ExplorationOpportunity({
    required this.type,
    this.category,
    this.locality,
    required this.reason,
    required this.confidence,
  });
}

/// Exploration Type
enum ExplorationType {
  newCategory, // New category to explore
  newLocality, // New locality to explore
  newEventType, // New event type to explore
}

