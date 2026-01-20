// Event Logger for Phase 11: User-AI Interaction Update
// Service for logging user interaction events with context enrichment

import 'dart:async';
import 'dart:developer' as developer;
import 'package:geolocator/geolocator.dart';
import 'package:avrai/core/ai/interaction_events.dart';
import 'package:avrai/core/ai/event_queue.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:avrai/core/ai/continuous_learning_system.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';

/// Event logger service for tracking user interactions
/// 
/// Features:
/// - Context enrichment (location, weather, time, social, app state)
/// - Automatic agent ID resolution
/// - Offline-capable event queuing
/// - Batch submission to database
class EventLogger {
  static const String _logName = 'EventLogger';
  
  final AgentIdService _agentIdService;
  final SupabaseService _supabaseService;
  final EventQueue _eventQueue;
  final ContinuousLearningSystem? _learningSystem;
  
  String? _currentAgentId;
  String? _currentScreen;
  String? _previousScreen;
  final List<String> _recentActions = [];
  static const int _maxRecentActions = 5;

  EventLogger({
    AgentIdService? agentIdService,
    SupabaseService? supabaseService,
    EventQueue? eventQueue,
    ContinuousLearningSystem? learningSystem,
  })  : _agentIdService = agentIdService ?? 
        di.sl<AgentIdService>(),
        _supabaseService = supabaseService ?? SupabaseService(),
        _eventQueue = eventQueue ?? EventQueue(),
        _learningSystem = learningSystem;

  /// Initialize event logger
  /// Sets up event queue and resolves agent ID for current user
  Future<void> initialize({String? userId}) async {
    try {
      // Resolve agent ID if user is available
      if (userId != null) {
        _currentAgentId = await _agentIdService.getUserAgentId(userId);
      }
      
      // Set up event queue submit callback
      _eventQueue.onSubmitEvents = _submitEventsToDatabase;
      
      // Initialize event queue
      await _eventQueue.initialize();
      
      developer.log('✅ EventLogger initialized', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing EventLogger: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update current user (call when user logs in/out)
  Future<void> updateUser(String? userId) async {
    if (userId != null) {
      _currentAgentId = await _agentIdService.getUserAgentId(userId);
    } else {
      _currentAgentId = null;
    }
  }

  /// Update current screen (call on navigation)
  void updateScreen(String screenName) {
    _previousScreen = _currentScreen;
    _currentScreen = screenName;
  }

  /// Log an interaction event
  /// 
  /// Automatically enriches event with context (location, weather, time, etc.)
  Future<void> logEvent({
    required String eventType,
    required Map<String, dynamic> parameters,
    InteractionContext? context,
    String? agentId,
  }) async {
    try {
      // Use provided agent ID or resolve from current user
      final eventAgentId = agentId ?? _currentAgentId;
      
      if (eventAgentId == null) {
        developer.log(
          '⚠️ No agent ID available, skipping event: $eventType',
          name: _logName,
        );
        return;
      }
      
      // Build enriched context
      final enrichedContext = context ?? await _buildContext();
      
      // Phase 11.8.6: Use atomic time for quantum formula compatibility
      // Create event with atomic timestamp
      AtomicTimestamp? atomicTimestamp;
      try {
        if (di.sl.isRegistered<AtomicClockService>()) {
          final atomicClock = di.sl<AtomicClockService>();
          atomicTimestamp = await atomicClock.getAtomicTimestamp();
        }
      } catch (e) {
        developer.log(
          'Error getting atomic timestamp: $e, event will use default timestamp',
          name: _logName,
        );
        // Continue without atomic timestamp - InteractionEvent will use DateTime
      }
      final event = InteractionEvent(
        eventType: eventType,
        parameters: parameters,
        context: enrichedContext,
        atomicTimestamp: atomicTimestamp, // Explicit atomic time if available
        agentId: eventAgentId,
      );
      
      // Add to recent actions
      _recentActions.add(eventType);
      if (_recentActions.length > _maxRecentActions) {
        _recentActions.removeAt(0);
      }
      
      // Enqueue event (handles offline storage and batch submission)
      await _eventQueue.enqueue(event);
      
      developer.log(
        'Event logged: $eventType',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error logging event: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Build enriched context for event
  Future<InteractionContext> _buildContext() async {
    final now = DateTime.now();
    
    // Collect location data (non-blocking, may be null)
    LocationData? locationData;
    try {
      final hasPermission = await _checkLocationPermission();
      if (hasPermission) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
          ),
        ).timeout(
          const Duration(seconds: 2),
          onTimeout: () => throw TimeoutException('Location timeout'),
        );
        locationData = LocationData.fromPosition(position);
      }
    } catch (e) {
      // Location unavailable, continue without it
      developer.log('Location unavailable for context: $e', name: _logName);
    }
    
    // Collect weather data (non-blocking, may be null)
    WeatherData? weatherData;
    if (locationData != null) {
      try {
        weatherData = await _collectWeatherData(locationData);
      } catch (e) {
        // Weather unavailable, continue without it
        developer.log('Weather unavailable for context: $e', name: _logName);
      }
    }
    
    // Build app context
    final appContext = AppContext(
      currentScreen: _currentScreen,
      previousScreen: _previousScreen,
      recentActions: List<String>.from(_recentActions),
    );
    
    // Build social context (if learning system available)
    SocialContext? socialContext;
    if (_learningSystem != null) {
      try {
        socialContext = await _buildSocialContext();
      } catch (e) {
        // Social context unavailable, continue without it
        developer.log('Social context unavailable: $e', name: _logName);
      }
    }
    
    return InteractionContext(
      timeOfDay: now,
      location: locationData,
      weather: weatherData,
      social: socialContext,
      app: appContext,
    );
  }

  /// Check location permission
  Future<bool> _checkLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final requested = await Geolocator.requestPermission();
        return requested != LocationPermission.denied &&
            requested != LocationPermission.deniedForever;
      }
      return permission != LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }

  /// Collect weather data for location
  Future<WeatherData?> _collectWeatherData(LocationData location) async {
    // Use ContinuousLearningSystem's weather collection if available
    if (_learningSystem != null) {
      try {
        // Access private method via reflection or make it public
        // For now, return null and let the learning system handle it
        return null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Build social context
  Future<SocialContext?> _buildSocialContext() async {
    // TODO: Query for nearby users, active AI2AI connections
    // For now, return null
    return null;
  }

  /// Submit events to database (callback for EventQueue)
  Future<bool> _submitEventsToDatabase(List<InteractionEvent> events) async {
    try {
      if (!_supabaseService.isAvailable) {
        developer.log('Supabase not available, cannot submit events', name: _logName);
        return false;
      }

      final userId = _supabaseService.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        developer.log(
          'No authenticated user; cannot submit interaction_events under user_id-based RLS',
          name: _logName,
        );
        return false;
      }
      
      final client = _supabaseService.client;
      
      // Prepare events for database insertion
      final eventsData = events.map((event) {
        return {
          'user_id': userId,
          'agent_id': event.agentId,
          'event_type': event.eventType,
          'parameters': event.parameters,
          'context': event.context.toJson(),
          'timestamp': event.timestamp.toIso8601String(),
        };
      }).toList();
      
      // Insert events in batch
      await client
          .from('interaction_events')
          .insert(eventsData);
      
      developer.log(
        '✅ Submitted ${events.length} events to database',
        name: _logName,
      );
      
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error submitting events to database: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Convenience methods for common event types
  
  /// Log list view started
  Future<void> logListViewStarted({
    required String listId,
    String? category,
    String? source,
  }) async {
    await logEvent(
      eventType: 'list_view_started',
      parameters: {
        'list_id': listId,
        if (category != null) 'category': category,
        if (source != null) 'source': source,
      },
    );
  }

  /// Log list view duration
  Future<void> logListViewDuration({
    required String listId,
    required int durationMs,
  }) async {
    await logEvent(
      eventType: 'list_view_duration',
      parameters: {
        'list_id': listId,
        'duration_ms': durationMs,
      },
    );
  }

  /// Log respect tap
  Future<void> logRespectTap({
    required String targetType,
    required String targetId,
  }) async {
    await logEvent(
      eventType: 'respect_tap',
      parameters: {
        'target_type': targetType,
        'target_id': targetId,
      },
    );
  }

  /// Log scroll depth
  Future<void> logScrollDepth({
    required String listId,
    required double depthPercentage,
    double? scrollVelocity,
  }) async {
    await logEvent(
      eventType: 'scroll_depth',
      parameters: {
        'list_id': listId,
        'depth_percentage': depthPercentage,
        if (scrollVelocity != null) 'scroll_velocity': scrollVelocity,
      },
    );
  }

  /// Log dwell time
  Future<void> logDwellTime({
    required String spotId,
    required int durationMs,
    String? interactionType,
  }) async {
    await logEvent(
      eventType: 'dwell_time',
      parameters: {
        'spot_id': spotId,
        'duration_ms': durationMs,
        if (interactionType != null) 'interaction_type': interactionType,
      },
    );
  }

  /// Log search performed
  Future<void> logSearchPerformed({
    required String query,
    required int resultsCount,
    String? selectedResult,
  }) async {
    await logEvent(
      eventType: 'search_performed',
      parameters: {
        'query': query,
        'results_count': resultsCount,
        if (selectedResult != null) 'selected_result': selectedResult,
      },
    );
  }

  /// Log spot visited
  Future<void> logSpotVisited({
    required String spotId,
    int? visitDuration,
    bool? checkIn,
  }) async {
    await logEvent(
      eventType: 'spot_visited',
      parameters: {
        'spot_id': spotId,
        if (visitDuration != null) 'visit_duration': visitDuration,
        if (checkIn != null) 'check_in': checkIn,
      },
    );
  }

  /// Log event attended
  Future<void> logEventAttended({
    required String eventId,
    int? attendanceDuration,
  }) async {
    await logEvent(
      eventType: 'event_attended',
      parameters: {
        'event_id': eventId,
        if (attendanceDuration != null) 'attendance_duration': attendanceDuration,
      },
    );
  }

  /// Dispose resources
  void dispose() {
    _eventQueue.dispose();
  }
}
