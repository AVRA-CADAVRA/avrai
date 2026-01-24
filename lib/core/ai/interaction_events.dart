// Interaction Events for Phase 11: User-AI Interaction Update
// Structured event system for tracking user interactions with context enrichment

import 'package:geolocator/geolocator.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

/// Interaction event model for tracking user actions
/// 
/// Represents a single user interaction with the app, including:
/// - Event type (list_view_started, respect_tap, scroll_depth, etc.)
/// - Event parameters (list_id, category, dwell_time, etc.)
/// - Rich context (time, location, weather, social, app state)
/// - Timestamp and privacy-protected agent ID
class InteractionEvent {
  final String eventType;
  final Map<String, dynamic> parameters;
  final InteractionContext context;
  final DateTime timestamp;
  final AtomicTimestamp? atomicTimestamp; // Phase 11 Enhancement: Atomic time for quantum formulas
  final String? agentId;

  InteractionEvent({
    required this.eventType,
    required this.parameters,
    required this.context,
    DateTime? timestamp,
    this.atomicTimestamp,
    this.agentId,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create event from JSON (for database retrieval)
  factory InteractionEvent.fromJson(Map<String, dynamic> json) {
    AtomicTimestamp? atomicTimestamp;
    if (json['atomic_timestamp'] != null) {
      if (json['atomic_timestamp'] is Map) {
        atomicTimestamp = AtomicTimestamp.fromJson(
          json['atomic_timestamp'] as Map<String, dynamic>,
        );
      } else if (json['atomic_timestamp'] is String) {
        // Fallback: parse as ISO string and create AtomicTimestamp using now() factory
        final dt = DateTime.parse(json['atomic_timestamp'] as String);
        atomicTimestamp = AtomicTimestamp.now(
          precision: TimePrecision.millisecond,
          serverTime: dt,
          localTime: dt.toLocal(),
          timezoneId: 'UTC',
          offset: Duration.zero,
          isSynchronized: false,
        );
      }
    }
    
    return InteractionEvent(
      eventType: json['event_type'] as String,
      parameters: Map<String, dynamic>.from(json['parameters'] as Map? ?? {}),
      context: json['context'] != null
          ? InteractionContext.fromJson(json['context'] as Map<String, dynamic>)
          : InteractionContext.empty(),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
      atomicTimestamp: atomicTimestamp,
      agentId: json['agent_id'] as String?,
    );
  }

  /// Convert event to JSON (for database storage)
  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'parameters': parameters,
      'context': context.toJson(),
      'timestamp': timestamp.toIso8601String(),
      if (atomicTimestamp != null) 'atomic_timestamp': atomicTimestamp!.toJson(),
      'agent_id': agentId,
    };
  }

  /// Create a copy with modified fields
  InteractionEvent copyWith({
    String? eventType,
    Map<String, dynamic>? parameters,
    InteractionContext? context,
    DateTime? timestamp,
    AtomicTimestamp? atomicTimestamp,
    String? agentId,
  }) {
    return InteractionEvent(
      eventType: eventType ?? this.eventType,
      parameters: parameters ?? this.parameters,
      context: context ?? this.context,
      timestamp: timestamp ?? this.timestamp,
      atomicTimestamp: atomicTimestamp ?? this.atomicTimestamp,
      agentId: agentId ?? this.agentId,
    );
  }
}

/// Rich context for interaction events
/// 
/// Captures environmental and app state at the time of interaction:
/// - Time of day, day of week, etc.
/// - Location data (if available)
/// - Weather data (if available)
/// - Social context (nearby users, AI2AI connections)
/// - App context (current screen, previous actions)
class InteractionContext {
  final DateTime timeOfDay;
  final LocationData? location;
  final WeatherData? weather;
  final SocialContext? social;
  final AppContext? app;

  InteractionContext({
    required this.timeOfDay,
    this.location,
    this.weather,
    this.social,
    this.app,
  });

  /// Create empty context (fallback)
  factory InteractionContext.empty() {
    return InteractionContext(
      timeOfDay: DateTime.now(),
    );
  }

  /// Create context from JSON
  factory InteractionContext.fromJson(Map<String, dynamic> json) {
    return InteractionContext(
      timeOfDay: json['time_of_day'] != null
          ? DateTime.parse(json['time_of_day'] as String)
          : DateTime.now(),
      location: json['location'] != null
          ? LocationData.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      weather: json['weather'] != null
          ? WeatherData.fromJson(json['weather'] as Map<String, dynamic>)
          : null,
      social: json['social'] != null
          ? SocialContext.fromJson(json['social'] as Map<String, dynamic>)
          : null,
      app: json['app'] != null
          ? AppContext.fromJson(json['app'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Convert context to JSON
  Map<String, dynamic> toJson() {
    return {
      'time_of_day': timeOfDay.toIso8601String(),
      'location': location?.toJson(),
      'weather': weather?.toJson(),
      'social': social?.toJson(),
      'app': app?.toJson(),
    };
  }

  /// Create a copy with modified fields
  InteractionContext copyWith({
    DateTime? timeOfDay,
    LocationData? location,
    WeatherData? weather,
    SocialContext? social,
    AppContext? app,
  }) {
    return InteractionContext(
      timeOfDay: timeOfDay ?? this.timeOfDay,
      location: location ?? this.location,
      weather: weather ?? this.weather,
      social: social ?? this.social,
      app: app ?? this.app,
    );
  }
}

/// Location data for context
class LocationData {
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime timestamp;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from Geolocator Position
  factory LocationData.fromPosition(Position position) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      altitude: position.altitude,
      speed: position.speed,
      heading: position.heading,
      timestamp: position.timestamp,
    );
  }

  /// Create from JSON
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: json['accuracy'] != null ? (json['accuracy'] as num).toDouble() : null,
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      speed: json['speed'] != null ? (json['speed'] as num).toDouble() : null,
      heading: json['heading'] != null ? (json['heading'] as num).toDouble() : null,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'heading': heading,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Weather data for context
class WeatherData {
  final double? temperature;
  final double? feelsLike;
  final int? humidity;
  final int? pressure;
  final String? conditions;
  final String? description;
  final double? windSpeed;
  final int? cloudiness;
  final DateTime timestamp;

  WeatherData({
    this.temperature,
    this.feelsLike,
    this.humidity,
    this.pressure,
    this.conditions,
    this.description,
    this.windSpeed,
    this.cloudiness,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create from JSON
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: json['temperature'] != null ? (json['temperature'] as num).toDouble() : null,
      feelsLike: json['feels_like'] != null ? (json['feels_like'] as num).toDouble() : null,
      humidity: json['humidity'] as int?,
      pressure: json['pressure'] as int?,
      conditions: json['conditions'] as String?,
      description: json['description'] as String?,
      windSpeed: json['wind_speed'] != null ? (json['wind_speed'] as num).toDouble() : null,
      cloudiness: json['cloudiness'] as int?,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feels_like': feelsLike,
      'humidity': humidity,
      'pressure': pressure,
      'conditions': conditions,
      'description': description,
      'wind_speed': windSpeed,
      'cloudiness': cloudiness,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Social context (who's nearby, AI2AI connections)
class SocialContext {
  final List<String>? nearbyAgentIds; // Privacy-protected agent IDs
  final List<String>? activeConnections; // Active AI2AI connections
  final int? nearbyUserCount; // Approximate count (privacy-preserving)

  SocialContext({
    this.nearbyAgentIds,
    this.activeConnections,
    this.nearbyUserCount,
  });

  /// Create from JSON
  factory SocialContext.fromJson(Map<String, dynamic> json) {
    return SocialContext(
      nearbyAgentIds: json['nearby_agent_ids'] != null
          ? List<String>.from(json['nearby_agent_ids'] as List)
          : null,
      activeConnections: json['active_connections'] != null
          ? List<String>.from(json['active_connections'] as List)
          : null,
      nearbyUserCount: json['nearby_user_count'] as int?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'nearby_agent_ids': nearbyAgentIds,
      'active_connections': activeConnections,
      'nearby_user_count': nearbyUserCount,
    };
  }
}

/// App context (current screen, previous actions)
class AppContext {
  final String? currentScreen;
  final String? previousScreen;
  final List<String>? recentActions; // Last 5 action types
  final Map<String, dynamic>? screenState; // Screen-specific state

  AppContext({
    this.currentScreen,
    this.previousScreen,
    this.recentActions,
    this.screenState,
  });

  /// Create from JSON
  factory AppContext.fromJson(Map<String, dynamic> json) {
    return AppContext(
      currentScreen: json['current_screen'] as String?,
      previousScreen: json['previous_screen'] as String?,
      recentActions: json['recent_actions'] != null
          ? List<String>.from(json['recent_actions'] as List)
          : null,
      screenState: json['screen_state'] != null
          ? Map<String, dynamic>.from(json['screen_state'] as Map)
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'current_screen': currentScreen,
      'previous_screen': previousScreen,
      'recent_actions': recentActions,
      'screen_state': screenState,
    };
  }
}
