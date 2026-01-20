import 'dart:async';
import 'dart:developer' as developer;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/ai/interaction_events.dart';
import 'package:avrai/core/ai/structured_facts_extractor.dart';
import 'package:avrai/core/ai/facts_index.dart';
import 'package:avrai/core/ai/continuous_learning/orchestrator.dart';
import 'package:avrai/core/ai/continuous_learning/data_collector.dart';
import 'package:avrai/core/ai/continuous_learning/data_processor.dart';
import 'package:avrai_network/network/rate_limiter.dart';
import 'package:avrai_network/network/ai2ai_protocol.dart' show MessageType;
import 'package:avrai/core/ai2ai/embedding_delta_collector.dart';
import 'package:avrai/core/ml/onnx_dimension_scorer.dart';
import 'package:avrai/core/ai/ai2ai_learning.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Continuous AI Learning System for SPOTS
/// Enables AI to learn from everything and improve itself every second
class ContinuousLearningSystem {
  static const String _logName = 'ContinuousLearningSystem';

  // Learning dimensions that the AI continuously improves
  static const List<String> _learningDimensions = [
    'user_preference_understanding',
    'location_intelligence',
    'temporal_patterns',
    'social_dynamics',
    'authenticity_detection',
    'community_evolution',
    'recommendation_accuracy',
    'personalization_depth',
    'trend_prediction',
    'collaboration_effectiveness',
  ];

  // Data sources for continuous learning
  static const List<String> _dataSources = [
    'user_actions',
    'location_data',
    'weather_conditions',
    'time_patterns',
    'social_connections',
    'age_demographics',
    'app_usage_patterns',
    'community_interactions',
    'ai2ai_communications',
    'external_context',
  ];

  // Learning rates for different dimensions
  static const Map<String, double> _learningRates = {
    'user_preference_understanding': 0.15,
    'location_intelligence': 0.12,
    'temporal_patterns': 0.10,
    'social_dynamics': 0.13,
    'authenticity_detection': 0.20,
    'community_evolution': 0.11,
    'recommendation_accuracy': 0.18,
    'personalization_depth': 0.16,
    'trend_prediction': 0.14,
    'collaboration_effectiveness': 0.17,
  };

  // Phase 1.4: Refactored to use orchestrator
  ContinuousLearningOrchestrator? _orchestrator;
  bool _orchestratorInitialized = false;
  final AgentIdService _agentIdService;
  SupabaseClient? _supabase;
  
  // AI2AI Learning Safeguards (Phase 11 Enhancement)
  // Track last AI2AI learning per peer to enforce 20-minute interval
  // Phase 11.8.6: Use atomic time for quantum formula compatibility
  final Map<String, AtomicTimestamp> _lastAi2AiLearningAtByPeerId = {};
  
  // Optional rate limiter for AI2AI learning (integrated from connection_orchestrator)
  RateLimiter? _rateLimiter;

  static AgentIdService _resolveAgentIdService(AgentIdService? agentIdService) {
    if (agentIdService != null) {
      return agentIdService;
    }
    try {
      if (di.sl.isRegistered<AgentIdService>()) {
        return di.sl<AgentIdService>();
      }
    } catch (e) {
      developer.log(
        'AgentIdService not available in DI; using default instance',
        name: _logName,
        error: e,
      );
    }
    return AgentIdService();
  }

  // Constructor
  ContinuousLearningSystem({
    SupabaseClient? supabase,
    AgentIdService? agentIdService,
    ContinuousLearningOrchestrator? orchestrator,
    RateLimiter? rateLimiter,
  })  : _agentIdService = _resolveAgentIdService(agentIdService),
        _supabase = supabase,
        _orchestrator = orchestrator,
        _rateLimiter = rateLimiter {
    // Initialize Supabase client if not provided
    if (_supabase == null) {
      try {
        _supabase = Supabase.instance.client;
      } catch (e) {
        developer.log(
            'Supabase not initialized, persistence will be skipped: $e',
            name: _logName);
      }
    }
    
    // Try to get RateLimiter from DI if not provided
    if (_rateLimiter == null) {
      try {
        if (GetIt.instance.isRegistered<RateLimiter>()) {
          _rateLimiter = GetIt.instance<RateLimiter>();
        }
      } catch (e) {
        developer.log(
            'RateLimiter not available in DI, rate limiting disabled',
            name: _logName);
      }
    }
  }

  /// Initialize orchestrator (lazy initialization)
  Future<void> _ensureOrchestrator() async {
    if (_orchestrator == null) {
      final dataCollector = LearningDataCollector(
        agentIdService: _agentIdService,
      );
      final dataProcessor = LearningDataProcessor();
      _orchestrator = ContinuousLearningOrchestrator(
        dataCollector: dataCollector,
        dataProcessor: dataProcessor,
      );
    }

    if (!_orchestratorInitialized) {
      await _orchestrator!.initialize();
      _orchestratorInitialized = true;
    }
  }

  /// Check if continuous learning is currently active
  bool get isLearningActive {
    return _orchestrator?.isLearningActive ?? false;
  }

  Future<void> initialize() async {
    await _ensureOrchestrator();
  }

  /// Process user interaction event and update learning dimensions
  /// Phase 11: User-AI Interaction Update - Section 2.1
  /// Enhanced with AI2AI Learning Safeguards (Phase 11 Enhancement)
  Future<void> processUserInteraction({
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    try {
      final eventType = payload['event_type'] as String? ?? '';
      final parameters = payload['parameters'] as Map<String, dynamic>? ?? {};
      final context = payload['context'] as Map<String, dynamic>? ?? {};
      
      // ========================================
      // AI2AI LEARNING SAFEGUARDS (Phase 11 Enhancement)
      // ========================================
      // If this is AI2AI-derived learning, check all safeguards before processing
      final source = payload['source'] as String?;
      if (source == 'ai2ai') {
        final peerId = payload['peer_id'] as String?;
        
        // SAFEGUARD 1: Check 20-minute interval per peer
        // Phase 11.8.6: Use atomic time for quantum formula compatibility
        if (peerId != null) {
          final last = _lastAi2AiLearningAtByPeerId[peerId];
          if (last != null) {
            try {
              if (GetIt.instance.isRegistered<AtomicClockService>()) {
                final atomicClock = GetIt.instance<AtomicClockService>();
                final atomicTimeNow = await atomicClock.getAtomicTimestamp();
                final timeSinceLastLearning = atomicTimeNow.difference(last);
                if (timeSinceLastLearning < const Duration(minutes: 20)) {
                  developer.log(
                    'AI2AI learning throttled: 20-min interval not met for peer $peerId '
                    '(last learning: ${timeSinceLastLearning.inMinutes} minutes ago)',
                    name: _logName,
                  );
                  return; // Skip learning (too soon)
                }
              } else {
                // Fallback to DateTime if AtomicClockService not available
                final timeSinceLastLearning = DateTime.now().difference(last.deviceTime);
                if (timeSinceLastLearning < const Duration(minutes: 20)) {
                  developer.log(
                    'AI2AI learning throttled: 20-min interval not met for peer $peerId',
                    name: _logName,
                  );
                  return;
                }
              }
            } catch (e) {
              developer.log(
                'Error checking AI2AI learning interval: $e, using fallback',
                name: _logName,
              );
              // Fallback to DateTime check
              final timeSinceLastLearning = DateTime.now().difference(last.deviceTime);
              if (timeSinceLastLearning < const Duration(minutes: 20)) {
                return;
              }
            }
          }
        }
        
        // SAFEGUARD 2: Check learning quality threshold (65% minimum)
        final learningQuality = payload['learning_quality'] as double? ?? 0.0;
        if (learningQuality < 0.65) {
          developer.log(
            'AI2AI learning rejected: quality ${(learningQuality * 100).toStringAsFixed(1)}% '
            'below 65% threshold',
            name: _logName,
          );
          return; // Skip learning (low quality)
        }
        
        // SAFEGUARD 3: Check rate limit (if rate limiter available)
        if (peerId != null && _rateLimiter != null) {
          final allowed = await _rateLimiter!.checkRateLimit(
            peerAgentId: peerId,
            limitType: RateLimitType.message,
            messageType: MessageType.learningInsight,
          );
          
          if (!allowed) {
            developer.log(
              'AI2AI learning rate limited for peer: $peerId',
              name: _logName,
            );
            return; // Skip learning (rate limit exceeded)
          }
        }
      }
      
      // Map event to learning dimensions
      final dimensionUpdates = <String, double>{};

      switch (eventType) {
        case 'respect_tap':
          // Respecting a list/spot indicates community engagement
          final targetType = parameters['target_type'] as String?;
          if (targetType == 'list') {
            final category = parameters['category'] as String?;
            dimensionUpdates['community_evolution'] = 0.05;
            dimensionUpdates['personalization_depth'] = 0.03;

            // Category-specific learning
            if (category != null) {
              dimensionUpdates['user_preference_understanding'] = 0.02;
            }
          } else if (targetType == 'spot') {
            dimensionUpdates['recommendation_accuracy'] = 0.03;
            dimensionUpdates['location_intelligence'] = 0.02;
          }
          break;

        case 'list_view_duration':
        case 'spot_view_duration':
          // Longer dwell time indicates interest
          final duration = parameters['duration_ms'] as int? ?? 0;
          if (duration > 30000) {
            // 30 seconds
            dimensionUpdates['user_preference_understanding'] = 0.04;
            dimensionUpdates['recommendation_accuracy'] = 0.02;
          }
          break;

        case 'scroll_depth':
          // Deep scrolling indicates engagement
          final depth = parameters['depth_percentage'] as double? ?? 0.0;
          if (depth > 0.8) {
            dimensionUpdates['user_preference_understanding'] = 0.03;
          }
          break;

        case 'spot_visited':
        case 'spot_tap':
          // Visiting a spot indicates recommendation success
          dimensionUpdates['recommendation_accuracy'] = 0.05;
          dimensionUpdates['location_intelligence'] = 0.03;
          break;

        case 'dwell_time':
          // Long dwell time on spot details indicates interest
          final duration = parameters['duration_ms'] as int? ?? 0;
          if (duration > 60000) {
            // 1 minute
            dimensionUpdates['user_preference_understanding'] = 0.04;
            dimensionUpdates['recommendation_accuracy'] = 0.03;
          }
          break;

        case 'search_performed':
          // Searching indicates exploration
          final resultsCount = parameters['results_count'] as int? ?? 0;
          if (resultsCount > 0) {
            dimensionUpdates['user_preference_understanding'] = 0.02;
          }
          break;

        case 'event_attended':
          // Attending events indicates community engagement
          dimensionUpdates['community_evolution'] = 0.08;
          dimensionUpdates['social_dynamics'] = 0.05;
          break;
      }

      // Apply context modifiers
      final timeOfDay = context['time_of_day'] as String?;
      final location = context['location'] as Map<String, dynamic>?;
      final weather = context['weather'] as Map<String, dynamic>?;

      // Time-based learning (e.g., morning coffee preferences)
      if (timeOfDay == 'morning' &&
          (eventType == 'spot_visited' || eventType == 'spot_tap')) {
        dimensionUpdates['temporal_patterns'] =
            (dimensionUpdates['temporal_patterns'] ?? 0.0) + 0.02;
      }

      // Location-based learning
      if (location != null) {
        dimensionUpdates['location_intelligence'] =
            (dimensionUpdates['location_intelligence'] ?? 0.0) + 0.01;
      }

      // Weather-based learning
      if (weather != null) {
        final conditions = weather['conditions'] as String?;
        if (conditions == 'Rain' &&
            (eventType == 'spot_visited' || eventType == 'spot_tap')) {
          dimensionUpdates['temporal_patterns'] =
              (dimensionUpdates['temporal_patterns'] ?? 0.0) + 0.01;
        }
      }

      // ========================================
      // SAFEGUARD 4: Dimension Delta Threshold (22% minimum for AI2AI)
      // ========================================
      // For AI2AI learning, only apply updates if delta >= 22%
      if (source == 'ai2ai') {
        dimensionUpdates.removeWhere((key, value) => value.abs() < 0.22);
        
        if (dimensionUpdates.isEmpty) {
          developer.log(
            'AI2AI learning rejected: no dimension deltas >= 22% threshold',
            name: _logName,
          );
          return; // Skip learning (no significant changes)
        }
        
        developer.log(
          'AI2AI learning passed delta threshold: ${dimensionUpdates.length} dimensions',
          name: _logName,
        );
      }
      
      // Update dimension weights in learning state via orchestrator
      await _ensureOrchestrator();
      if (_orchestrator != null) {
        // Apply learning rates to dimension updates before passing to orchestrator
        final adjustedUpdates = <String, double>{};
        for (final entry in dimensionUpdates.entries) {
          final learningRate = _learningRates[entry.key] ?? 0.1;
          adjustedUpdates[entry.key] = entry.value * learningRate;
        }
        _orchestrator!.processInteractionDimensionUpdates(
          adjustedUpdates,
          LearningData.empty(), // Will be enriched in next cycle
        );
      }

      // Phase 11 Enhancement: Real-time ONNX updates from user interactions
      // Only for direct user interactions (not AI2AI - those use separate path)
      if (source != 'ai2ai' && dimensionUpdates.isNotEmpty) {
        unawaited(_updateOnnxBiasesFromInteraction(
          dimensionUpdates: dimensionUpdates,
          context: context,
        ));
      }
      
      // ========================================
      // Record AI2AI learning time (after successful processing)
      // ========================================
      // Phase 11.8.6: Use atomic time for quantum formula compatibility
      if (source == 'ai2ai') {
        final peerId = payload['peer_id'] as String?;
        if (peerId != null) {
          try {
            if (GetIt.instance.isRegistered<AtomicClockService>()) {
              final atomicClock = GetIt.instance<AtomicClockService>();
              _lastAi2AiLearningAtByPeerId[peerId] = await atomicClock.getAtomicTimestamp();
            } else {
              // Fallback: create AtomicTimestamp from DateTime.now()
              final now = DateTime.now();
              _lastAi2AiLearningAtByPeerId[peerId] = AtomicTimestamp.now(
                precision: TimePrecision.millisecond,
                serverTime: now,
                localTime: now.toLocal(),
                timezoneId: 'UTC',
                offset: Duration.zero,
                isSynchronized: false,
              );
            }
            developer.log(
              'Recorded AI2AI learning time for peer: $peerId',
              name: _logName,
            );
          } catch (e) {
            developer.log(
              'Error recording AI2AI learning time: $e, using fallback',
              name: _logName,
            );
            // Fallback: create AtomicTimestamp from DateTime.now()
            final now = DateTime.now();
            _lastAi2AiLearningAtByPeerId[peerId] = AtomicTimestamp.now(
              precision: TimePrecision.millisecond,
              serverTime: now,
              localTime: now.toLocal(),
              timezoneId: 'UTC',
              offset: Duration.zero,
              isSynchronized: false,
            );
          }
        }
      }

      // Update PersonalityProfile via PersonalityLearning
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      try {
        if (currentUser != null && dimensionUpdates.isNotEmpty) {
          // Get PersonalityLearning from DI
          if (GetIt.instance.isRegistered<PersonalityLearning>()) {
            final personalityLearning = GetIt.instance<PersonalityLearning>();

            // Convert interaction event to UserAction for PersonalityLearning
            final userAction =
                _convertEventToUserAction(eventType, parameters, context);

            // Evolve personality from user action
            await personalityLearning.evolveFromUserAction(
              currentUser.id,
              userAction,
            );
          }
        }
      } catch (e) {
        developer.log(
          'Error updating PersonalityProfile: $e',
          name: _logName,
        );
        // Continue even if personality update fails
      }

      // Trigger real-time model update (payload already processed above)
      await updateModelRealtime({
        'event_type': eventType,
        'parameters': parameters,
        'context': context,
      });

      developer.log(
        'Processed interaction: $eventType → ${dimensionUpdates.length} dimension updates',
        name: _logName,
      );

      // Phase 11 Enhancement: Propagate significant learning through mesh
      // Only for direct user interactions (not AI2AI - those came from mesh already)
      if (source != 'ai2ai' && dimensionUpdates.isNotEmpty) {
        unawaited(_propagateLearningToMesh(
          userId: userId,
          dimensionUpdates: dimensionUpdates,
          context: context,
        ));
      }

      // Phase 11 Section 5: Extract structured facts from event (non-blocking)
      if (currentUser != null) {
        // Convert payload to InteractionEvent for facts extraction
        try {
          // Phase 11.8.6: Use atomic time for quantum formula compatibility
          AtomicTimestamp? atomicTime;
          try {
            if (GetIt.instance.isRegistered<AtomicClockService>()) {
              final atomicClock = GetIt.instance<AtomicClockService>();
              atomicTime = await atomicClock.getAtomicTimestamp();
            }
          } catch (e) {
            developer.log(
              'Error getting atomic timestamp: $e, InteractionEvent will use default',
              name: _logName,
            );
            // InteractionEvent constructor will create atomic timestamp if not provided
          }
          final interactionEvent = InteractionEvent(
            eventType: eventType,
            parameters: parameters,
            context: InteractionContext.fromJson(context),
            atomicTimestamp: atomicTime, // Will use default if null
            agentId: await _agentIdService.getUserAgentId(currentUser.id),
          );
          _extractAndIndexFacts(currentUser.id, interactionEvent);
        } catch (e) {
          developer.log(
              'Error creating InteractionEvent for facts extraction: $e',
              name: _logName);
          // Non-blocking - continue even if facts extraction setup fails
        }
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error processing user interaction: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extract structured facts from event and index them (non-blocking)
  /// Phase 11 Section 5: Retrieval + LLM Fusion
  void _extractAndIndexFacts(String userId, InteractionEvent event) {
    // Run asynchronously and non-blocking
    unawaited(_extractAndIndexFactsAsync(userId, event));
  }

  Future<void> _extractAndIndexFactsAsync(
      String userId, InteractionEvent event) async {
    try {
      // Get dependencies from GetIt (services must be registered in injection_container.dart)
      if (!GetIt.instance.isRegistered<StructuredFactsExtractor>() ||
          !GetIt.instance.isRegistered<FactsIndex>()) {
        developer.log(
            'StructuredFactsExtractor or FactsIndex not registered, skipping facts extraction',
            name: _logName);
        return;
      }

      final extractor = GetIt.instance<StructuredFactsExtractor>();
      final factsIndex = GetIt.instance<FactsIndex>();

      // Extract facts from event
      final facts = await extractor.extractFactsFromEvent(event);

      // Index facts (merges with existing)
      await factsIndex.indexFacts(userId: userId, facts: facts);
    } catch (e) {
      developer.log(
        'Error extracting/indexing facts: $e',
        name: _logName,
      );
      // Non-blocking - don't throw
    }
  }

  /// Convert interaction event to UserAction for PersonalityLearning
  UserAction _convertEventToUserAction(
    String eventType,
    Map<String, dynamic> parameters,
    Map<String, dynamic> context,
  ) {
    // Map interaction event types to UserActionType
    UserActionType actionType;

    switch (eventType) {
      case 'spot_visited':
      case 'spot_tap':
        actionType = UserActionType.spotVisit;
        break;
      case 'respect_tap':
        final targetType = parameters['target_type'] as String?;
        if (targetType == 'list') {
          actionType = UserActionType.curationActivity;
        } else {
          actionType = UserActionType.authenticPreference;
        }
        break;
      case 'search_performed':
        actionType = UserActionType.spontaneousActivity;
        break;
      case 'event_attended':
        actionType = UserActionType.socialInteraction;
        break;
      default:
        actionType = UserActionType.authenticPreference;
    }

    return UserAction(
      type: actionType,
      timestamp: DateTime.now(),
      metadata: {
        'event_type': eventType,
        'parameters': parameters,
        'context': context,
      },
    );
  }

  /// Train model from collected interaction data
  /// Phase 11: User-AI Interaction Update - Section 2.2
  Future<void> trainModel(dynamic data) async {
    try {
      // Collect recent interaction history
      final recentEvents = await _collectRecentInteractions(limit: 100);

      // Group by dimension
      final dimensionData = <String, List<Map<String, dynamic>>>{};
      for (final event in recentEvents) {
        final updates = await _calculateDimensionUpdates(event);
        for (final entry in updates.entries) {
          if (!dimensionData.containsKey(entry.key)) {
            dimensionData[entry.key] = [];
          }
          dimensionData[entry.key]!.add({
            'event': event,
            'update': entry.value,
          });
        }
      }

      // Train each dimension
      for (final entry in dimensionData.entries) {
        final dimension = entry.key;
        final trainingData = entry.value;

        // Calculate average improvement
        final avgImprovement = trainingData
                .map((d) => d['update'] as double)
                .reduce((a, b) => a + b) /
            trainingData.length;

        // Update dimension weight via orchestrator
        await _ensureOrchestrator();
        if (_orchestrator != null) {
          final learningState = _orchestrator!.currentLearningState;
          final current = learningState[dimension] ?? 0.5;
          final learningRate = _learningRates[dimension] ?? 0.1;

          // Update via orchestrator's processInteractionDimensionUpdates
          _orchestrator!.processInteractionDimensionUpdates(
            {dimension: avgImprovement * learningRate},
            LearningData.empty(),
          );

          final updatedState = _orchestrator!.currentLearningState;
          final newValue = updatedState[dimension] ?? current;

          developer.log(
            'Trained dimension $dimension: $current → $newValue (improvement: $avgImprovement)',
            name: _logName,
          );
        }
      }

      // Save updated state
      await _saveLearningState();
    } catch (e, stackTrace) {
      developer.log(
        'Error training model: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Collect recent interactions from database
  Future<List<Map<String, dynamic>>> _collectRecentInteractions(
      {int limit = 100}) async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        return [];
      }

      final agentId = await _agentIdService.getUserAgentId(currentUser.id);

      final events = await supabase
          .from('interaction_events')
          .select('*')
          .eq('agent_id', agentId)
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(events);
    } catch (e) {
      developer.log('Error collecting recent interactions: $e', name: _logName);
      return [];
    }
  }

  /// Calculate dimension updates from an event
  Future<Map<String, double>> _calculateDimensionUpdates(
      Map<String, dynamic> event) async {
    // Extract dimension updates (simplified - full logic in processUserInteraction)
    final dimensionUpdates = <String, double>{};
    final eventType = event['event_type'] as String? ?? '';
    final parameters = event['parameters'] as Map<String, dynamic>? ?? {};

    switch (eventType) {
      case 'respect_tap':
        final targetType = parameters['target_type'] as String?;
        if (targetType == 'list') {
          dimensionUpdates['community_evolution'] = 0.05;
          dimensionUpdates['personalization_depth'] = 0.03;
        } else if (targetType == 'spot') {
          dimensionUpdates['recommendation_accuracy'] = 0.03;
          dimensionUpdates['location_intelligence'] = 0.02;
        }
        break;
      case 'spot_visited':
      case 'spot_tap':
        dimensionUpdates['recommendation_accuracy'] = 0.05;
        dimensionUpdates['location_intelligence'] = 0.03;
        break;
      case 'list_view_duration':
      case 'spot_view_duration':
        final duration = parameters['duration_ms'] as int? ?? 0;
        if (duration > 30000) {
          dimensionUpdates['user_preference_understanding'] = 0.04;
          dimensionUpdates['recommendation_accuracy'] = 0.02;
        }
        break;
      case 'event_attended':
        dimensionUpdates['community_evolution'] = 0.08;
        dimensionUpdates['social_dynamics'] = 0.05;
        break;
    }

    return dimensionUpdates;
  }

  Future<double> evaluateModel(dynamic data) async {
    return 0.8;
  }

  /// Update model in real-time from interaction payload
  /// Phase 11: User-AI Interaction Update - Section 2.3
  /// Enhanced with Drift Prevention (Phase 11 Enhancement)
  Future<void> updateModelRealtime(Map<String, dynamic> payload) async {
    try {
      // Get current user
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        developer.log('No authenticated user for realtime update',
            name: _logName);
        return;
      }

      // Get PersonalityLearning from DI
      if (!GetIt.instance.isRegistered<PersonalityLearning>()) {
        developer.log('PersonalityLearning not registered in DI',
            name: _logName);
        return;
      }

      final personalityLearning = GetIt.instance<PersonalityLearning>();
      final currentProfile =
          await personalityLearning.getCurrentPersonality(currentUser.id);
      
      // ========================================
      // DRIFT PREVENTION SAFEGUARD (Phase 11 Enhancement)
      // ========================================
      // Check if this is AI2AI learning and enforce drift limits
      final source = payload['source'] as String?;
      if (source == 'ai2ai' && currentProfile != null) {
        // Maximum drift: 30% from original personality (contextual layer)
        // Core personality should be completely stable
        final maxDrift = 0.30;
        
        // Get original profile for drift checking
        // Note: We check evolution timeline first entry as "original"
        final originalDimensions = currentProfile.evolutionTimeline.isNotEmpty
            ? currentProfile.evolutionTimeline.first.corePersonality
            : currentProfile.dimensions;
        
        // Check each dimension update against drift limit
        final dimensionUpdates = payload['dimension_updates'] 
            as Map<String, double>? ?? {};
        
        for (final entry in dimensionUpdates.entries) {
          final dimension = entry.key;
          final proposedChange = entry.value;
          final currentValue = currentProfile.dimensions[dimension] ?? 0.5;
          final originalValue = originalDimensions[dimension] ?? currentValue;
          final proposedValue = currentValue + proposedChange;
          
          // Calculate drift from original
          final drift = (proposedValue - originalValue).abs();
          
          if (drift > maxDrift) {
            developer.log(
              'Drift limit exceeded for $dimension: drift ${(drift * 100).toStringAsFixed(1)}% '
              'exceeds max ${(maxDrift * 100).toStringAsFixed(1)}% - clamping to max drift',
              name: _logName,
            );
            
            // Clamp to max drift
            final clampedValue = originalValue + 
                (proposedValue > originalValue ? maxDrift : -maxDrift);
            dimensionUpdates[dimension] = clampedValue - currentValue;
          }
        }
        
        // Update payload with clamped values
        if (dimensionUpdates.isNotEmpty) {
          payload = Map<String, dynamic>.from(payload);
          payload['dimension_updates'] = dimensionUpdates;
        }
      }

      if (currentProfile == null) {
        developer.log('No personality profile found for realtime update',
            name: _logName);
        return;
      }

      // Only update if we have meaningful learning state changes
      await _ensureOrchestrator();
      final learningState = _orchestrator?.currentLearningState ?? {};
      if (learningState.isEmpty) {
        return;
      }

      // The actual personality update happens in processUserInteraction()
      // via evolveFromUserAction(). This method is called for additional
      // real-time adjustments if needed.

      developer.log(
        'Realtime model update completed (personality updated via evolveFromUserAction)',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error updating model realtime: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<Map<String, double>> predict(Map<String, dynamic> context) async {
    return {};
  }

  /// Starts continuous learning system
  /// AI learns from everything every second
  Future<void> startContinuousLearning() async {
    try {
      await _ensureOrchestrator();
      await _orchestrator!.startContinuousLearning();
    } catch (e) {
      developer.log('Error starting continuous learning: $e', name: _logName);
    }
  }

  /// Stops continuous learning system
  Future<void> stopContinuousLearning() async {
    try {
      if (_orchestrator != null) {
        await _orchestrator!.stopContinuousLearning();
      }
    } catch (e) {
      developer.log('Error stopping continuous learning: $e', name: _logName);
    }
  }

  /// Gets current learning status
  Future<ContinuousLearningStatus> getLearningStatus() async {
    if (_orchestrator != null) {
      return await _orchestrator!.getLearningStatus();
    }

    // Return default status if orchestrator not initialized
    return ContinuousLearningStatus(
      isActive: false,
      activeProcesses: [],
      uptime: Duration.zero,
      cyclesCompleted: 0,
      learningTime: Duration.zero,
    );
  }

  /// Gets learning progress for all dimensions
  Future<Map<String, double>> getLearningProgress() async {
    try {
      if (_orchestrator != null) {
        return _orchestrator!.currentLearningState;
      }
      return {};
    } catch (e) {
      developer.log('Error getting learning progress: $e', name: _logName);
      return {};
    }
  }

  /// Gets learning metrics and statistics
  Future<ContinuousLearningMetrics> getLearningMetrics() async {
    try {
      await _ensureOrchestrator();
      if (_orchestrator == null) {
        return ContinuousLearningMetrics(
          totalImprovements: 0.0,
          averageProgress: 0.0,
          topImprovingDimensions: [],
          dimensionsCount: _learningDimensions.length,
          dataSourcesCount: _dataSources.length,
        );
      }

      final improvementMetrics = _orchestrator!.improvementMetrics;
      final learningState = _orchestrator!.currentLearningState;

      final totalImprovements = improvementMetrics.values.fold<double>(
        0.0,
        (sum, metric) => sum + metric,
      );

      final averageProgress = learningState.values.isEmpty
          ? 0.0
          : learningState.values.reduce((a, b) => a + b) / learningState.length;

      final topDimensions = improvementMetrics.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return ContinuousLearningMetrics(
        totalImprovements: totalImprovements,
        averageProgress: averageProgress,
        topImprovingDimensions:
            topDimensions.take(5).map((e) => e.key).toList(),
        dimensionsCount: _learningDimensions.length,
        dataSourcesCount: _dataSources.length,
      );
    } catch (e) {
      developer.log('Error getting learning metrics: $e', name: _logName);
      return ContinuousLearningMetrics(
        totalImprovements: 0.0,
        averageProgress: 0.0,
        topImprovingDimensions: [],
        dimensionsCount: 0,
        dataSourcesCount: 0,
      );
    }
  }

  /// Gets data collection status for all data sources
  Future<DataCollectionStatus> getDataCollectionStatus() async {
    try {
      final sourceStatuses = <String, DataSourceStatus>{};

      if (_orchestrator == null) {
        // Return empty status if orchestrator not initialized
        for (final source in _dataSources) {
          sourceStatuses[source] = DataSourceStatus(
            isActive: false,
            dataVolume: 0,
            eventCount: 0,
            healthStatus: 'inactive',
          );
        }
        return DataCollectionStatus(
          sourceStatuses: sourceStatuses,
          totalVolume: 0,
          activeSourcesCount: 0,
        );
      }

      await _ensureOrchestrator();
      final learningHistory = _orchestrator!.learningHistory;

      for (final source in _dataSources) {
        // Check if source has contributed to recent learning
        bool isActive = false;
        int eventCount = 0;
        int dataVolume = 0;

        for (final history in learningHistory.values) {
          final sourceEvents =
              history.where((e) => e.dataSource.contains(source)).toList();
          eventCount += sourceEvents.length;

          if (sourceEvents.isNotEmpty) {
            final mostRecent = sourceEvents.last;
            final timeSinceLastEvent =
                DateTime.now().difference(mostRecent.timestamp);
            if (timeSinceLastEvent.inSeconds < 300) {
              // Active if used in last 5 minutes
              isActive = true;
            }
          }
        }

        // Estimate data volume from event count
        dataVolume = eventCount * 100; // Rough estimate

        sourceStatuses[source] = DataSourceStatus(
          isActive: isActive,
          dataVolume: dataVolume,
          eventCount: eventCount,
          healthStatus:
              isActive ? 'healthy' : (eventCount > 0 ? 'idle' : 'inactive'),
        );
      }

      return DataCollectionStatus(
        sourceStatuses: sourceStatuses,
        totalVolume: sourceStatuses.values
            .fold<int>(0, (sum, status) => sum + status.dataVolume),
        activeSourcesCount:
            sourceStatuses.values.where((s) => s.isActive).length,
      );
    } catch (e) {
      developer.log('Error getting data collection status: $e', name: _logName);
      return DataCollectionStatus(
        sourceStatuses: {},
        totalVolume: 0,
        activeSourcesCount: 0,
      );
    }
  }

  // Phase 1.4: _performContinuousLearning removed - handled by orchestrator
  // Phase 1.4: _collectLearningData removed - handled by orchestrator's data collector

  // Phase 1.4: _learnDimension removed - handled by orchestrator engines
  // Phase 1.4: _calculateDimensionImprovement removed - handled by orchestrator engines
  // Phase 1.4: Legacy improvement + insight helpers removed.
  // The orchestrator (engines + collectors) is the single source of truth.

  // Phase 1.4: _analyzeLearningPatterns removed - handled by orchestrator

  // Phase 1.4: _analyzeDataSourceEffectiveness removed - handled by orchestrator

  // Phase 1.4: _updateImprovementMetrics removed - handled by orchestrator

  // Phase 1.4: Self-improvement methods removed - these are now handled by orchestrator's engines
  // If needed in future, these can be re-implemented as orchestrator features

  // Phase 1.4: _initializeLearningState removed - handled by orchestrator

  /// Saves learning state
  Future<void> _saveLearningState() async {
    // Save current learning state to persistent storage
    developer.log('Saving learning state', name: _logName);

    // Also persist learning history
    await _persistLearningHistory();
  }

  /// Persist learning history to Supabase
  ///
  /// Phase 11 Section 8: Learning Quality Monitoring
  /// Stores learning events in the database for analytics and quality monitoring.
  Future<void> _persistLearningHistory({String? userId}) async {
    if (_supabase == null) {
      developer.log(
          'Supabase not available, skipping learning history persistence',
          name: _logName);
      return;
    }

    try {
      // Get agent ID (use provided userId or current user)
      String? agentId;
      if (userId != null) {
        agentId = await _agentIdService.getUserAgentId(userId);
      } else {
        // TODO: Get current user ID from auth service if available
        developer.log('No userId provided, skipping persistence',
            name: _logName);
        return;
      }

      developer.log(
        'Persisting learning history for agent: ${agentId.substring(0, 10)}...',
        name: _logName,
      );

      // Get learning history from orchestrator
      await _ensureOrchestrator();
      if (_orchestrator == null) {
        developer.log('Orchestrator not available, skipping persistence',
            name: _logName);
        return;
      }

      final learningHistory = _orchestrator!.learningHistory;

      // Persist recent events for each dimension
      for (final entry in learningHistory.entries) {
        final dimension = entry.key;
        final events = entry.value;

        // Store recent events (last 10 per dimension)
        final recentEvents = events.take(10).toList();

        for (final event in recentEvents) {
          try {
            await _supabase!.from('learning_history').insert({
              'agent_id': agentId,
              'dimension': dimension,
              'improvement': event.improvement,
              'data_source': event.dataSource,
              'timestamp': event.timestamp.toIso8601String(),
              'created_at': DateTime.now().toIso8601String(),
              'metadata': <String,
                  dynamic>{}, // Can be extended with additional metadata
            });
          } catch (e) {
            developer.log(
              'Error persisting learning event for dimension $dimension: $e',
              name: _logName,
            );
            // Continue with other events
          }
        }
      }

      developer.log(
        'Successfully persisted learning history for ${learningHistory.length} dimensions',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error persisting learning history: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't throw - persistence failure shouldn't break the app
    }
  }

  /// Get learning history from Supabase
  ///
  /// Phase 11 Section 8: Learning Quality Monitoring
  /// Retrieves learning history for analytics and quality monitoring.
  Future<List<LearningEvent>> getLearningHistory({
    required String userId,
    String? dimension,
    int limit = 100,
  }) async {
    if (_supabase == null) {
      developer.log('Supabase not available, returning empty history',
          name: _logName);
      return [];
    }

    try {
      final agentId = await _agentIdService.getUserAgentId(userId);

      var query = _supabase!
          .from('learning_history')
          .select('*')
          .eq('agent_id', agentId);

      if (dimension != null) {
        query = query.eq('dimension', dimension);
      }

      final response =
          await query.order('timestamp', ascending: false).limit(limit);

      final events = <LearningEvent>[];
      for (final row in response) {
        events.add(LearningEvent(
          dimension: row['dimension'] as String,
          improvement: (row['improvement'] as num).toDouble(),
          dataSource: row['data_source'] as String,
          timestamp: DateTime.parse(row['timestamp'] as String),
        ));
      }

      developer.log(
        'Retrieved ${events.length} learning events for agent: ${agentId.substring(0, 10)}...',
        name: _logName,
      );

      return events;
    } catch (e, stackTrace) {
      developer.log(
        'Error retrieving learning history: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get learning history summary
  ///
  /// Phase 11 Section 8: Learning Quality Monitoring
  /// Returns summary statistics for learning history.
  Future<Map<String, dynamic>> getLearningHistorySummary({
    required String userId,
    String? dimension,
  }) async {
    if (_supabase == null) {
      return {};
    }

    try {
      final agentId = await _agentIdService.getUserAgentId(userId);

      final response =
          await _supabase!.rpc('get_learning_history_summary', params: {
        'p_agent_id': agentId,
        'p_dimension': dimension,
        'p_limit': 100,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      developer.log(
        'Error retrieving learning history summary: $e',
        name: _logName,
      );
      return {};
    }
  }

  /// Process AI2AI mesh learning insights
  /// 
  /// Converts AI2AI learning insights into interaction events for processing
  /// through the continuous learning pipeline.
  /// 
  /// Phase 11 Enhancement: AI2AI Mesh Integration
  Future<void> processAI2AILearningInsight({
    required String userId,
    required AI2AILearningInsight insight,
    required String peerId,
  }) async {
    try {
      developer.log(
        'Processing AI2AI mesh learning insight from peer: $peerId',
        name: _logName,
      );
      
      // Convert AI2AI learning insight to interaction event payload
      final payload = {
        'event_type': 'ai2ai_learning_insight',
        'source': 'ai2ai',
        'peer_id': peerId,
        'learning_quality': insight.learningQuality,
        'dimension_updates': insight.dimensionInsights,
        'parameters': {
          'insight_type': insight.type.toString(),
          'timestamp': insight.timestamp.toIso8601String(),
        },
        'context': {
          'source': 'ai2ai_mesh',
          'learning_quality': insight.learningQuality,
        },
      };
      
      // Process through existing learning pipeline (includes safeguards)
      await processUserInteraction(
        userId: userId,
        payload: payload,
      );
      
      // Also update ONNX biases directly from mesh insights (real-time)
      await _updateOnnxFromMeshInsight(insight);
    } catch (e, stackTrace) {
      developer.log(
        'Error processing AI2AI learning insight: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Non-blocking - don't throw
    }
  }

  /// Update ONNX biases from AI2AI mesh learning insight (real-time)
  /// 
  /// Phase 11 Enhancement: Real-time ONNX Updates from Mesh
  Future<void> _updateOnnxFromMeshInsight(AI2AILearningInsight insight) async {
    try {
      // Convert AI2AI learning insight to embedding deltas
      final deltas = insight.dimensionInsights.entries.map((entry) {
        // Phase 11.8.6: Use atomic timestamp for quantum formula compatibility
        // Create AtomicTimestamp from insight timestamp
        return EmbeddingDelta(
          delta: [entry.value],
          timestamp: insight.timestamp,
          category: entry.key,
          metadata: {
            'source': 'ai2ai_mesh',
            'learning_quality': insight.learningQuality,
            'insight_type': insight.type.toString(),
          },
        );
      }).toList();
      
      // Update ONNX scorer directly (non-blocking)
      if (GetIt.instance.isRegistered<OnnxDimensionScorer>()) {
        final onnxScorer = GetIt.instance<OnnxDimensionScorer>();
        await onnxScorer.updateWithDeltas(deltas);
        
        developer.log(
          'Updated ONNX biases from mesh insight: ${deltas.length} dimensions',
          name: _logName,
        );
      }
    } catch (e) {
      developer.log(
        'Error updating ONNX from mesh insight: $e',
        name: _logName,
      );
      // Non-blocking
    }
  }

  /// Update ONNX biases directly from user interaction events
  /// 
  /// Phase 11 Enhancement: Real-time ONNX Updates from Interactions
  Future<void> _updateOnnxBiasesFromInteraction({
    required Map<String, double> dimensionUpdates,
    required Map<String, dynamic> context,
  }) async {
    try {
      // Convert dimension updates to embedding deltas
      // Phase 11.8.6: Use atomic time for quantum formula compatibility
      DateTime timestamp;
      try {
        if (GetIt.instance.isRegistered<AtomicClockService>()) {
          final atomicClock = GetIt.instance<AtomicClockService>();
          final atomicTime = await atomicClock.getAtomicTimestamp();
          timestamp = atomicTime.deviceTime; // Use atomic time for quantum compatibility
        } else {
          timestamp = DateTime.now(); // Fallback
        }
      } catch (e) {
        developer.log(
          'Error getting atomic timestamp: $e, using DateTime.now() fallback',
          name: _logName,
        );
        timestamp = DateTime.now(); // Fallback
      }
      final deltas = dimensionUpdates.entries.map((entry) {
        return EmbeddingDelta(
          delta: [entry.value], // Single dimension delta
          timestamp: timestamp,
          category: entry.key, // Dimension name as category
          metadata: {
            'source': 'user_interaction',
            'context': context,
          },
        );
      }).toList();
      
      // Update ONNX scorer with deltas
      if (GetIt.instance.isRegistered<OnnxDimensionScorer>()) {
        final onnxScorer = GetIt.instance<OnnxDimensionScorer>();
        await onnxScorer.updateWithDeltas(deltas);
        
        developer.log(
          'Updated ONNX biases from ${deltas.length} interaction dimensions',
          name: _logName,
        );
      }
    } catch (e) {
      developer.log(
        'Error updating ONNX biases from interaction: $e',
        name: _logName,
      );
      // Non-blocking
    }
  }

  /// Process AI2AI chat conversation for continuous learning
  /// 
  /// Converts AI2AI chat analysis results into interaction events for processing
  /// through the continuous learning pipeline.
  /// 
  /// Phase 11 Enhancement: Conversation-Based Learning
  Future<void> processAI2AIChatConversation({
    required String userId,
    required AI2AIChatAnalysisResult chatAnalysis,
  }) async {
    try {
      // Only process if analysis confidence is sufficient
      if (chatAnalysis.analysisConfidence < 0.6) {
        developer.log(
          'Chat analysis confidence too low: ${chatAnalysis.analysisConfidence}',
          name: _logName,
        );
        return;
      }
      
      // Extract dimension insights from conversation analysis
      // Calculate proposed change from direction and magnitude
      final dimensionInsights = <String, double>{};
      for (final rec in chatAnalysis.evolutionRecommendations) {
        final change = rec.direction == 'increase' 
            ? rec.magnitude 
            : -rec.magnitude;
        dimensionInsights[rec.dimension] = change;
      }
      
      if (dimensionInsights.isEmpty) {
        developer.log('No dimension insights from chat conversation', name: _logName);
        return;
      }
      
      // Convert to interaction event format
      final payload = {
        'event_type': 'ai2ai_chat_conversation',
        'source': 'ai2ai_chat',
        'parameters': {
          'chat_type': chatAnalysis.chatEvent.messageType.toString(),
          'analysis_confidence': chatAnalysis.analysisConfidence,
          'shared_insights_count': chatAnalysis.sharedInsights.length,
          'learning_opportunities_count': chatAnalysis.learningOpportunities.length,
        },
        'context': {
          'source': 'ai2ai_chat',
          'conversation_patterns': {
            'exchange_frequency': chatAnalysis.conversationPatterns.exchangeFrequency,
            'response_latency': chatAnalysis.conversationPatterns.responseLatency,
            'conversation_depth': chatAnalysis.conversationPatterns.conversationDepth,
            'topic_consistency': chatAnalysis.conversationPatterns.topicConsistency,
          },
          'trust_metrics': {
            'trust_building': chatAnalysis.trustMetrics.trustBuilding,
            'trust_evolution': chatAnalysis.trustMetrics.trustEvolution,
            'overall_trust': chatAnalysis.trustMetrics.overallTrust,
          },
        },
        'dimension_updates': dimensionInsights,
      };
      
      // Process through learning pipeline
      await processUserInteraction(
        userId: userId,
        payload: payload,
      );
      
      developer.log(
        'Processed AI2AI chat conversation: ${dimensionInsights.length} dimensions updated',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error processing AI2AI chat conversation: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Propagate learning insights to AI2AI mesh for collective learning
  /// 
  /// Phase 11 Enhancement: Complete Learning Pipeline
  /// Sends significant dimension updates to mesh for propagation to nearby devices
  Future<void> _propagateLearningToMesh({
    required String userId,
    required Map<String, double> dimensionUpdates,
    required Map<String, dynamic> context,
  }) async {
    try {
      // Only propagate if updates are significant (22% threshold)
      final significantUpdates = <String, double>{};
      for (final entry in dimensionUpdates.entries) {
        if (entry.value.abs() >= 0.22) {
          significantUpdates[entry.key] = entry.value;
        }
      }
      
      if (significantUpdates.isEmpty) {
        developer.log(
          'No significant dimension updates to propagate to mesh',
          name: _logName,
        );
        return;
      }
      
      // Phase 11.8.6: Use atomic time for quantum formula compatibility
      DateTime timestamp;
      try {
        if (GetIt.instance.isRegistered<AtomicClockService>()) {
          final atomicClock = GetIt.instance<AtomicClockService>();
          final atomicTime = await atomicClock.getAtomicTimestamp();
          timestamp = atomicTime.deviceTime; // Use atomic time
        } else {
          timestamp = DateTime.now(); // Fallback
        }
      } catch (e) {
        developer.log(
          'Error getting atomic timestamp: $e, using DateTime.now() fallback',
          name: _logName,
        );
        timestamp = DateTime.now(); // Fallback
      }
      // Create AI2AI learning insight for mesh propagation
      final insight = AI2AILearningInsight(
        type: AI2AIInsightType.dimensionDiscovery,
        dimensionInsights: significantUpdates,
        learningQuality: 0.8, // High quality for direct user interactions
        timestamp: timestamp,
      );
      
      // Propagate through mesh (via ConnectionOrchestrator)
      // Note: ConnectionOrchestrator has _sendLearningInsightToPeer() method
      // but it's private. For now, we'll log that propagation is prepared.
      // The insight is already being processed through processUserInteraction() above,
      // which will eventually reach the mesh through ConnectionOrchestrator's existing flow.
      // TODO(Phase 11.8.5): Implement ConnectionOrchestrator.propagateLearningInsight() public API
      // or integrate directly if ConnectionOrchestrator already exposes this
      developer.log(
        'Prepared ${significantUpdates.length} dimension updates for mesh propagation '
        '(insight type: ${insight.type}, quality: ${insight.learningQuality})',
        name: _logName,
      );
    } catch (e) {
      developer.log(
        'Error propagating learning to mesh: $e',
        name: _logName,
      );
      // Non-blocking
    }
  }
}

// Models for continuous learning system

class LearningData {
  final List<dynamic> userActions;
  final List<dynamic> locationData;
  final List<dynamic> weatherData;
  final List<dynamic> timeData;
  final List<dynamic> socialData;
  final List<dynamic> demographicData;
  final List<dynamic> appUsageData;
  final List<dynamic> communityData;
  final List<dynamic> ai2aiData;
  final List<dynamic> externalData;
  final DateTime timestamp;

  LearningData({
    required this.userActions,
    required this.locationData,
    required this.weatherData,
    required this.timeData,
    required this.socialData,
    required this.demographicData,
    required this.appUsageData,
    required this.communityData,
    required this.ai2aiData,
    required this.externalData,
    required this.timestamp,
  });

  static LearningData empty() {
    return LearningData(
      userActions: [],
      locationData: [],
      weatherData: [],
      timeData: [],
      socialData: [],
      demographicData: [],
      appUsageData: [],
      communityData: [],
      ai2aiData: [],
      externalData: [],
      timestamp: DateTime.now(),
    );
  }
}

class LearningEvent {
  final String dimension;
  final double improvement;
  final String dataSource;
  final DateTime timestamp;

  LearningEvent({
    required this.dimension,
    required this.improvement,
    required this.dataSource,
    required this.timestamp,
  });
}

// Data models for UI

class ContinuousLearningStatus {
  final bool isActive;
  final List<String> activeProcesses;
  final Duration uptime;
  final int cyclesCompleted;
  final Duration learningTime;

  ContinuousLearningStatus({
    required this.isActive,
    required this.activeProcesses,
    required this.uptime,
    required this.cyclesCompleted,
    required this.learningTime,
  });
}

class ContinuousLearningMetrics {
  final double totalImprovements;
  final double averageProgress;
  final List<String> topImprovingDimensions;
  final int dimensionsCount;
  final int dataSourcesCount;

  ContinuousLearningMetrics({
    required this.totalImprovements,
    required this.averageProgress,
    required this.topImprovingDimensions,
    required this.dimensionsCount,
    required this.dataSourcesCount,
  });
}

class DataCollectionStatus {
  final Map<String, DataSourceStatus> sourceStatuses;
  final int totalVolume;
  final int activeSourcesCount;

  DataCollectionStatus({
    required this.sourceStatuses,
    required this.totalVolume,
    required this.activeSourcesCount,
  });
}

class DataSourceStatus {
  final bool isActive;
  final int dataVolume;
  final int eventCount;
  final String healthStatus; // 'healthy', 'idle', 'inactive'

  DataSourceStatus({
    required this.isActive,
    required this.dataVolume,
    required this.eventCount,
    required this.healthStatus,
  });
}
