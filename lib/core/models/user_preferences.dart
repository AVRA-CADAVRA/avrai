import 'package:equatable/equatable.dart';
import 'package:spots/core/models/expertise_event.dart';

/// User Preferences Model
/// 
/// Represents learned user preferences for event discovery.
/// Preferences are learned from user event attendance patterns and behavior.
/// 
/// **Philosophy:** The AI learns which doors resonate with the user and adapts
/// recommendations accordingly, while also suggesting exploration opportunities.
class UserPreferences extends Equatable {
  /// User ID
  final String userId;
  
  /// Local vs city expert preference weight (0.0 to 1.0)
  /// 0.0 = prefers city/state experts, 1.0 = prefers local experts
  final double localExpertPreferenceWeight;
  
  /// Category preferences (category -> weight 0.0 to 1.0)
  /// Higher weight = user prefers this category more
  final Map<String, double> categoryPreferences;
  
  /// Locality preferences (locality -> weight 0.0 to 1.0)
  /// Higher weight = user prefers events in this locality
  final Map<String, double> localityPreferences;
  
  /// Scope preferences (scope -> weight 0.0 to 1.0)
  /// Higher weight = user prefers events at this scope level
  final Map<EventScope, double> scopePreferences;
  
  /// Event type preferences (event type -> weight 0.0 to 1.0)
  /// Higher weight = user prefers this event type
  final Map<ExpertiseEventType, double> eventTypePreferences;
  
  /// Exploration willingness (0.0 to 1.0)
  /// 0.0 = prefers familiar, 1.0 = highly open to exploration
  final double explorationWillingness;
  
  /// Timestamp when preferences were last updated
  final DateTime lastUpdated;
  
  /// Number of events analyzed to learn preferences
  final int eventsAnalyzed;

  const UserPreferences({
    required this.userId,
    this.localExpertPreferenceWeight = 0.5,
    this.categoryPreferences = const {},
    this.localityPreferences = const {},
    this.scopePreferences = const {},
    this.eventTypePreferences = const {},
    this.explorationWillingness = 0.3,
    required this.lastUpdated,
    this.eventsAnalyzed = 0,
  });

  /// Get top N category preferences
  List<MapEntry<String, double>> getTopCategories({int n = 5}) {
    final sorted = categoryPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// Get top N locality preferences
  List<MapEntry<String, double>> getTopLocalities({int n = 5}) {
    final sorted = localityPreferences.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(n).toList();
  }

  /// Get top scope preference
  EventScope? get topScope {
    if (scopePreferences.isEmpty) return null;
    return scopePreferences.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get top event type preference
  ExpertiseEventType? get topEventType {
    if (eventTypePreferences.isEmpty) return null;
    return eventTypePreferences.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Check if user prefers local experts
  bool get prefersLocalExperts => localExpertPreferenceWeight > 0.6;

  /// Check if user prefers city/state experts
  bool get prefersCityExperts => localExpertPreferenceWeight < 0.4;

  /// Check if user is open to exploration
  bool get isOpenToExploration => explorationWillingness > 0.5;

  /// Get preference strength for a category
  double getCategoryPreference(String category) {
    return categoryPreferences[category] ?? 0.0;
  }

  /// Get preference strength for a locality
  double getLocalityPreference(String locality) {
    return localityPreferences[locality] ?? 0.0;
  }

  /// Get preference strength for a scope
  double getScopePreference(EventScope scope) {
    return scopePreferences[scope] ?? 0.0;
  }

  /// Get preference strength for an event type
  double getEventTypePreference(ExpertiseEventType eventType) {
    return eventTypePreferences[eventType] ?? 0.0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'localExpertPreferenceWeight': localExpertPreferenceWeight,
      'categoryPreferences': categoryPreferences,
      'localityPreferences': localityPreferences,
      'scopePreferences': scopePreferences.map((k, v) => MapEntry(k.name, v)),
      'eventTypePreferences': eventTypePreferences.map((k, v) => MapEntry(k.name, v)),
      'explorationWillingness': explorationWillingness,
      'lastUpdated': lastUpdated.toIso8601String(),
      'eventsAnalyzed': eventsAnalyzed,
    };
  }

  /// Create from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['userId'] as String,
      localExpertPreferenceWeight: (json['localExpertPreferenceWeight'] as num?)?.toDouble() ?? 0.5,
      categoryPreferences: Map<String, double>.from(
        (json['categoryPreferences'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      localityPreferences: Map<String, double>.from(
        (json['localityPreferences'] as Map?)?.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())) ?? {},
      ),
      scopePreferences: Map<EventScope, double>.from(
        (json['scopePreferences'] as Map?)?.map((k, v) => MapEntry(
          EventScope.values.firstWhere(
            (e) => e.name == k.toString(),
            orElse: () => EventScope.locality,
          ),
          (v as num).toDouble(),
        )) ?? {},
      ),
      eventTypePreferences: Map<ExpertiseEventType, double>.from(
        (json['eventTypePreferences'] as Map?)?.map((k, v) => MapEntry(
          ExpertiseEventType.values.firstWhere(
            (e) => e.name == k.toString(),
            orElse: () => ExpertiseEventType.meetup,
          ),
          (v as num).toDouble(),
        )) ?? {},
      ),
      explorationWillingness: (json['explorationWillingness'] as num?)?.toDouble() ?? 0.3,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      eventsAnalyzed: json['eventsAnalyzed'] as int? ?? 0,
    );
  }

  /// Copy with method
  UserPreferences copyWith({
    String? userId,
    double? localExpertPreferenceWeight,
    Map<String, double>? categoryPreferences,
    Map<String, double>? localityPreferences,
    Map<EventScope, double>? scopePreferences,
    Map<ExpertiseEventType, double>? eventTypePreferences,
    double? explorationWillingness,
    DateTime? lastUpdated,
    int? eventsAnalyzed,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      localExpertPreferenceWeight: localExpertPreferenceWeight ?? this.localExpertPreferenceWeight,
      categoryPreferences: categoryPreferences ?? this.categoryPreferences,
      localityPreferences: localityPreferences ?? this.localityPreferences,
      scopePreferences: scopePreferences ?? this.scopePreferences,
      eventTypePreferences: eventTypePreferences ?? this.eventTypePreferences,
      explorationWillingness: explorationWillingness ?? this.explorationWillingness,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      eventsAnalyzed: eventsAnalyzed ?? this.eventsAnalyzed,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        localExpertPreferenceWeight,
        categoryPreferences,
        localityPreferences,
        scopePreferences,
        eventTypePreferences,
        explorationWillingness,
        lastUpdated,
        eventsAnalyzed,
      ];
}

/// Event Scope Enum
/// 
/// Represents the geographic scope of events.
enum EventScope {
  /// Community events (non-expert events)
  community,
  
  /// Locality events (local expert events)
  locality,
  
  /// City events (city expert events)
  city,
  
  /// State events (regional expert events)
  state,
  
  /// Nation events (national expert events)
  nation,
  
  /// Globe events (global expert events)
  globe,
  
  /// Universe events (universal expert events)
  universe,
  
  /// Clubs/Communities events
  clubs,
}

