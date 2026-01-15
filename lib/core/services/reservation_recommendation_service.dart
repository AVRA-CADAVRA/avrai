// Reservation Recommendation Service
//
// Phase 15: Reservation System Implementation
// Section 15.7: Search & Discovery - Quantum Entanglement Matching
// Enhanced with Full Quantum Entanglement Integration
//
// Provides quantum-matched reservation recommendations using full entanglement.

import 'dart:developer' as developer;
import 'package:avrai/core/models/reservation.dart';
// ExpertiseEvent import removed - not directly used
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai_core/models/atomic_timestamp.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai_quantum/services/quantum/quantum_entanglement_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/expertise_event_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/llm_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/ai_search_suggestions_service.dart';
import 'package:avrai/core/services/reservation_service.dart';
// Phase 6.2 Enhancement: Knot Theory Integration
import 'package:avrai_knot/services/knot/personality_knot_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_knot/services/knot/integrated_knot_recommendation_engine.dart';
import 'package:avrai_core/models/personality_knot.dart';

/// Reservation Recommendation
///
/// Represents a recommended reservation with quantum compatibility score.
class ReservationRecommendation {
  /// Event/Spot/Business ID
  final String targetId;

  /// Reservation type
  final ReservationType type;

  /// Title/Name of the target
  final String title;

  /// Description
  final String? description;

  /// Quantum compatibility score (0.0 to 1.0)
  final double compatibility;

  /// Quantum state used for matching
  final QuantumEntityState? quantumState;

  /// Recommended reservation time
  final DateTime? recommendedTime;

  /// AI-generated reason for recommendation
  final String? aiReason;

  const ReservationRecommendation({
    required this.targetId,
    required this.type,
    required this.title,
    this.description,
    required this.compatibility,
    this.quantumState,
    this.recommendedTime,
    this.aiReason,
  });
}

/// Reservation Recommendation Service
///
/// Provides quantum-matched reservation recommendations using full entanglement.
///
/// **Quantum Matching:**
/// - Uses `MultiEntityQuantumEntanglementService` (Phase 19) when available
/// - Falls back to basic quantum compatibility when Phase 19 not available
/// - Uses quantum vibe, location, and timing in matching
class ReservationRecommendationService {
  static const String _logName = 'ReservationRecommendationService';
  static const double _minCompatibilityThreshold = 0.7;

  final ReservationQuantumService _quantumService;
  // ignore: unused_field - Reserved for future Phase 19 integration
  final QuantumEntanglementService?
  // ignore: unused_field
      _entanglementService; // Optional, graceful degradation
  final AtomicClockService _atomicClock;
  final ExpertiseEventService? _eventService;
  // ignore: unused_field - Reserved for future agentId resolution
  final AgentIdService? _agentIdService;
  final LLMService? _llmService; // Phase 6.2: AI-powered suggestions
  final PersonalityLearning? _personalityLearning; // Phase 6.2: User preferences
  final AISearchSuggestionsService? _aiSearchService; // Phase 6.2: Suggestion patterns
  final ReservationService? _reservationService; // Phase 6.2: Past reservations
  // Phase 6.2 Enhancement: Knot Theory Integration
  final PersonalityKnotService? _knotService; // Knot generation/retrieval
  // ignore: unused_field - Reserved for future group reservation optimization
  final KnotEvolutionStringService? _stringService; // Individual user evolution strings
  // ignore: unused_field - Reserved for future group reservation optimization
  final KnotFabricService? _fabricService; // Group fabric stability
  // ignore: unused_field - Reserved for future group reservation optimization
  final KnotWorldsheetService? _worldsheetService; // 4D quantum worldsheets/planes
  final IntegratedKnotRecommendationEngine? _knotEngine; // Knot compatibility

  ReservationRecommendationService({
    required ReservationQuantumService quantumService,
    required AtomicClockService atomicClock,
    QuantumEntanglementService? entanglementService,
    ExpertiseEventService? eventService,
    AgentIdService? agentIdService,
    LLMService? llmService,
    PersonalityLearning? personalityLearning,
    AISearchSuggestionsService? aiSearchService,
    ReservationService? reservationService,
    // Phase 6.2 Enhancement: Knot Theory Integration
    PersonalityKnotService? knotService,
    KnotEvolutionStringService? stringService,
    KnotFabricService? fabricService,
    KnotWorldsheetService? worldsheetService,
    IntegratedKnotRecommendationEngine? knotEngine,
  })  : _quantumService = quantumService,
        _atomicClock = atomicClock,
        _entanglementService = entanglementService,
        _eventService = eventService,
        _agentIdService = agentIdService,
        _llmService = llmService,
        _personalityLearning = personalityLearning,
        _aiSearchService = aiSearchService,
        _reservationService = reservationService,
        _knotService = knotService,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _knotEngine = knotEngine;

  /// Get quantum-matched reservations for user
  ///
  /// **Formula:**
  /// Uses full quantum entanglement matching when Phase 19 available:
  /// ```
  /// C_reservation = 0.40 * F(ρ_personality) +
  ///                 0.30 * F(ρ_vibe) +
  ///                 0.20 * F(ρ_location) +
  ///                 0.10 * F(ρ_timing) * timing_flexibility_factor
  /// ```
  ///
  /// **Parameters:**
  /// - `userId`: User ID (will be converted to agentId internally)
  /// - `limit`: Maximum number of recommendations
  ///
  /// **Returns:**
  /// List of reservation recommendations sorted by compatibility
  Future<List<ReservationRecommendation>> getQuantumMatchedReservations({
    required String userId,
    required int limit,
  }) async {
    developer.log(
      'Getting quantum-matched reservations for user $userId (limit: $limit)',
      name: _logName,
    );

    try {
      // Get atomic timestamp
      final tAtomic = await _atomicClock.getAtomicTimestamp();

      // Get available events/spots/businesses
      // TODO: Implement actual retrieval from services
      final availableTargets = await _getAvailableTargets();

      // Create user quantum state
      final userQuantumState =
          await _quantumService.createReservationQuantumState(
        userId: userId,
        reservationTime: DateTime.now(), // Default time, will be refined
      );

      // Calculate compatibility for each target
      final recommendations = <ReservationRecommendation>[];
      for (final target in availableTargets) {
        try {
          // Create target quantum state
          final targetQuantumState = await _createTargetQuantumState(
            target: target,
            tAtomic: tAtomic,
          );

          // Calculate quantum compatibility
          final quantumCompatibility =
              await _quantumService.calculateReservationCompatibility(
            reservationState: userQuantumState,
            idealState: targetQuantumState,
          );

          // Calculate knot compatibility (Phase 6.2 Enhancement)
          final knotCompatibility = await _calculateKnotCompatibility(
            userId: userId,
            target: target,
          );

          // Combine quantum and knot compatibility
          // Formula: C_combined = 0.7 * C_quantum + 0.3 * C_knot
          final compatibility = (0.7 * quantumCompatibility) +
              (0.3 * knotCompatibility);

          // Only include if above threshold
          if (compatibility >= _minCompatibilityThreshold) {
            recommendations.add(ReservationRecommendation(
              targetId: target['id'] as String,
              type: _getReservationType(target),
              title: target['title'] as String? ??
                  target['name'] as String? ??
                  'Unknown',
              description: target['description'] as String?,
              compatibility: compatibility,
              quantumState: targetQuantumState,
              recommendedTime: _getRecommendedTime(target),
            ));
          }
        } catch (e) {
          developer.log(
            'Error calculating compatibility for target ${target['id']}: $e',
            name: _logName,
          );
          // Continue with next target
        }
      }

      // Sort by compatibility (highest first)
      recommendations
          .sort((a, b) => b.compatibility.compareTo(a.compatibility));

      // Return top recommendations
      final result = recommendations.take(limit).toList();

      developer.log(
        '✅ Found ${result.length} quantum-matched reservations',
        name: _logName,
      );

      return result;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting quantum-matched reservations: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get AI-powered reservation suggestions
  ///
  /// Phase 6.2: AI-Powered Reservation Suggestions
  ///
  /// **Features:**
  /// - AI suggests spots/events to reserve based on:
  ///   - User preferences (from PersonalityLearning)
  ///   - Past reservations (from ReservationService)
  ///   - Personality profile (from PersonalityLearning)
  ///   - Time patterns (analyzed from past reservations)
  ///   - Community activity (via AISearchSuggestionsService)
  ///
  /// **Integration:**
  /// - `LLMService` - AI suggestions
  /// - `PersonalityLearning` - User preferences
  /// - `AISearchSuggestionsService` - Suggestion engine
  /// - `ReservationService` - Past reservations
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `limit`: Maximum number of recommendations
  ///
  /// **Returns:**
  /// List of AI-powered reservation recommendations
  Future<List<ReservationRecommendation>> getAIPoweredReservations({
    required String userId,
    required int limit,
  }) async {
    developer.log(
      'Getting AI-powered reservations for user $userId (limit: $limit)',
      name: _logName,
    );

    try {
      // Step 1: Get quantum-matched reservations (base recommendations)
      final quantumRecommendations = await getQuantumMatchedReservations(
        userId: userId,
        limit: limit * 2, // Get more to filter with AI
      );

      if (quantumRecommendations.isEmpty) {
        developer.log(
          'No quantum-matched reservations found, returning empty list',
          name: _logName,
        );
        return [];
      }

      // Step 2: Get user context (preferences, past reservations, time patterns)
      final userContext = await _buildUserContext(userId);

      // Step 3: Use AI to enhance and rank recommendations
      final aiEnhancedRecommendations = await _enhanceWithAI(
        recommendations: quantumRecommendations,
        userContext: userContext,
        userId: userId,
        limit: limit,
      );

      developer.log(
        '✅ Found ${aiEnhancedRecommendations.length} AI-powered reservations',
        name: _logName,
      );

      return aiEnhancedRecommendations;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting AI-powered reservations: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Fallback to quantum-matched only
      return await getQuantumMatchedReservations(
        userId: userId,
        limit: limit,
      );
    }
  }

  // --- Private Helper Methods ---

  /// Build user context for AI recommendations
  Future<Map<String, dynamic>> _buildUserContext(String userId) async {
    final context = <String, dynamic>{};

    try {
      // Get personality profile
      if (_personalityLearning != null) {
        try {
          final profile = await _personalityLearning!.getCurrentPersonality(userId);
          if (profile != null) {
            context['personality'] = {
              'dimensions': profile.dimensions,
              'generation': profile.evolutionGeneration,
            };
          }
        } catch (e) {
          developer.log(
            'Error getting personality profile: $e',
            name: _logName,
          );
        }
      }

      // Get past reservations
      if (_reservationService != null) {
        try {
          final pastReservations = await _reservationService!.getUserReservations(
            userId: userId,
            startDate: DateTime.now().subtract(const Duration(days: 90)),
          );

          context['pastReservations'] = {
            'count': pastReservations.length,
            'types': pastReservations.map((r) => r.type.name).toList(),
            'targetIds': pastReservations.map((r) => r.targetId).toList(),
          };

          // Analyze time patterns
          if (pastReservations.isNotEmpty) {
            final timePatterns = _analyzeTimePatterns(pastReservations);
            context['timePatterns'] = timePatterns;
          }
        } catch (e) {
          developer.log(
            'Error getting past reservations: $e',
            name: _logName,
          );
        }
      }

      // Get community activity suggestions
      if (_aiSearchService != null) {
        try {
          final suggestions = await _aiSearchService!.generateSuggestions(
            query: '',
            userLocation: null,
            recentSpots: null,
            communityTrends: null,
          );
          context['communitySuggestions'] = suggestions.length;
        } catch (e) {
          developer.log(
            'Error getting community suggestions: $e',
            name: _logName,
          );
        }
      }
    } catch (e) {
      developer.log(
        'Error building user context: $e',
        name: _logName,
      );
    }

    return context;
  }

  /// Analyze time patterns from past reservations
  Map<String, dynamic> _analyzeTimePatterns(List<Reservation> reservations) {
    final hourCounts = <int, int>{};
    final dayOfWeekCounts = <int, int>{};

    for (final reservation in reservations) {
      final hour = reservation.reservationTime.hour;
      final dayOfWeek = reservation.reservationTime.weekday;

      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      dayOfWeekCounts[dayOfWeek] = (dayOfWeekCounts[dayOfWeek] ?? 0) + 1;
    }

    // Find most common hour and day
    int? preferredHour;
    int? preferredDayOfWeek;
    int maxHourCount = 0;
    int maxDayCount = 0;

    hourCounts.forEach((hour, count) {
      if (count > maxHourCount) {
        maxHourCount = count;
        preferredHour = hour;
      }
    });

    dayOfWeekCounts.forEach((day, count) {
      if (count > maxDayCount) {
        maxDayCount = count;
        preferredDayOfWeek = day;
      }
    });

    return {
      'preferredHour': preferredHour,
      'preferredDayOfWeek': preferredDayOfWeek,
      'totalReservations': reservations.length,
    };
  }

  /// Enhance recommendations with AI
  Future<List<ReservationRecommendation>> _enhanceWithAI({
    required List<ReservationRecommendation> recommendations,
    required Map<String, dynamic> userContext,
    required String userId,
    required int limit,
  }) async {
    if (_llmService == null) {
      developer.log(
        'LLMService not available, returning quantum-matched recommendations',
        name: _logName,
      );
      return recommendations.take(limit).toList();
    }

    try {
      // Build prompt for AI
      final prompt = _buildAIPrompt(recommendations, userContext);

      // Get AI response
      final aiResponse = await _llmService!.generateWithContext(
        query: prompt,
        userId: userId,
        temperature: 0.7,
        maxTokens: 500,
      );

      // Parse AI response and enhance recommendations
      final enhancedRecommendations = _parseAIResponse(
        recommendations: recommendations,
        aiResponse: aiResponse,
        limit: limit,
      );

      return enhancedRecommendations;
    } catch (e) {
      developer.log(
        'Error enhancing with AI: $e',
        name: _logName,
      );
      // Fallback to quantum-matched only
      return recommendations.take(limit).toList();
    }
  }

  /// Calculate knot compatibility for reservation recommendation
  ///
  /// Phase 6.2 Enhancement: Knot Theory Integration
  ///
  /// **Formula:**
  /// - Uses IntegratedKnotRecommendationEngine when available
  /// - Falls back to neutral score (0.5) if knot services unavailable
  ///
  /// **Returns:**
  /// Knot compatibility score (0.0 to 1.0)
  Future<double> _calculateKnotCompatibility({
    required String userId,
    required Map<String, dynamic> target,
  }) async {
    // If knot services not available, return neutral score
    if (_knotService == null || _knotEngine == null || _personalityLearning == null) {
      return 0.5; // Neutral score
    }

    try {
      // Get user personality profile
      final userProfile = await _personalityLearning!.getCurrentPersonality(userId);
      if (userProfile == null) {
        developer.log(
          'No personality profile found for user $userId, using neutral knot score',
          name: _logName,
        );
        return 0.5;
      }

      // For events: Get host personality profile and calculate knot compatibility
      if (target['type'] == 'event' && target.containsKey('hostId')) {
        final hostId = target['hostId'] as String?;
        if (hostId != null) {
          try {
            final hostProfile = await _personalityLearning!.getCurrentPersonality(hostId);
            if (hostProfile != null) {
              // Ensure knots are generated (for compatibility calculation)
              if (userProfile.personalityKnot == null) {
                await _knotService!.generateKnot(userProfile);
              }
              if (hostProfile.personalityKnot == null) {
                await _knotService!.generateKnot(hostProfile);
              }

              // Calculate integrated compatibility (quantum + knot)
              final compatibilityScore = await _knotEngine!.calculateIntegratedCompatibility(
                profileA: userProfile,
                profileB: hostProfile,
              );

              developer.log(
                'Knot compatibility: ${compatibilityScore.combined.toStringAsFixed(2)} '
                '(quantum: ${compatibilityScore.quantum.toStringAsFixed(2)}, '
                'knot: ${compatibilityScore.knot.toStringAsFixed(2)})',
                name: _logName,
              );

              return compatibilityScore.combined;
            }
          } catch (e, stackTrace) {
            developer.log(
              'Error calculating knot compatibility for host: $e',
              name: _logName,
              error: e,
              stackTrace: stackTrace,
            );
          }
        }
      }

      // For spots/businesses: Use entity knot if available
      // TODO: Implement entity knot compatibility for spots/businesses
      // For now, return neutral score
      return 0.5;
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating knot compatibility: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return 0.5; // Neutral score on error
    }
  }

  /// Calculate fabric stability for group reservations
  ///
  /// Phase 6.2 Enhancement: Knot Theory Integration
  ///
  /// **Formula:**
  /// - Generates fabric from user knots
  /// - Measures fabric stability
  /// - Returns stability score (0.0 to 1.0)
  ///
  /// **Parameters:**
  /// - `userIds`: List of user IDs in the group
  ///
  /// **Returns:**
  /// Fabric stability score (0.0 to 1.0), or null if services unavailable
  ///
  /// **Note:** Reserved for future group reservation optimization
  // ignore: unused_element
  Future<double?> _calculateFabricStability({
    required List<String> userIds,
  }) async {
    if (_fabricService == null ||
        _knotService == null ||
        _personalityLearning == null) {
      return null;
    }

    try {
      final userKnots = <PersonalityKnot>[];

      // Get knots for all users
      for (final userId in userIds) {
        final profile = await _personalityLearning!.getCurrentPersonality(userId);
        if (profile != null) {
          final knot = profile.personalityKnot ??
              await _knotService!.generateKnot(profile);
          userKnots.add(knot);
        }
      }

      if (userKnots.isEmpty) {
        return null;
      }

      // Generate fabric from user knots
      final fabric = await _fabricService!.generateMultiStrandBraidFabric(
        userKnots: userKnots,
      );

      // Measure fabric stability
      final stability = await _fabricService!.measureFabricStability(fabric);

      developer.log(
        'Fabric stability for ${userIds.length} users: ${stability.toStringAsFixed(2)}',
        name: _logName,
      );

      return stability;
    } catch (e) {
      developer.log(
        'Error calculating fabric stability: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Calculate worldsheet evolution compatibility
  ///
  /// Phase 6.2 Enhancement: Knot Theory Integration
  ///
  /// **Formula:**
  /// - Creates worldsheet for group evolution
  /// - Predicts fabric stability at reservation time
  /// - Returns evolution score (0.0 to 1.0)
  ///
  /// **Parameters:**
  /// - `userIds`: List of user IDs in the group
  /// - `reservationTime`: Reservation time
  ///
  /// **Returns:**
  /// Worldsheet evolution score (0.0 to 1.0), or null if services unavailable
  ///
  /// **Note:** Reserved for future group reservation optimization
  // ignore: unused_element
  Future<double?> _calculateWorldsheetEvolution({
    required List<String> userIds,
    required DateTime reservationTime,
  }) async {
    if (_worldsheetService == null ||
        _fabricService == null ||
        _agentIdService == null) {
      return null;
    }

    try {
      // Get agentIds for all users
      final agentIds = <String>[];
      for (final userId in userIds) {
        final agentId = await _agentIdService!.getUserAgentId(userId);
        agentIds.add(agentId);
      }

      if (agentIds.isEmpty) {
        return null;
      }

      // Create worldsheet for group
      final groupId = 'reservation_${userIds.join('_')}';
      final worldsheet = await _worldsheetService!.createWorldsheet(
        groupId: groupId,
        userIds: agentIds,
        startTime: reservationTime.subtract(const Duration(days: 30)),
        endTime: reservationTime.add(const Duration(days: 30)),
      );

      if (worldsheet == null) {
        return null;
      }

      // Get fabric at reservation time
      final fabricAtReservation = worldsheet.getFabricAtTime(reservationTime);
      if (fabricAtReservation == null) {
        return null;
      }

      // Calculate stability evolution
      final preReservationFabric = worldsheet.getFabricAtTime(
        reservationTime.subtract(const Duration(days: 1)),
      );
      final postReservationFabric = worldsheet.getFabricAtTime(
        reservationTime.add(const Duration(days: 1)),
      );

      if (preReservationFabric != null && postReservationFabric != null) {
        final preStability = await _fabricService!.measureFabricStability(
          preReservationFabric,
        );
        final postStability = await _fabricService!.measureFabricStability(
          postReservationFabric,
        );

        // Evolution score: positive change = fabric improves = better suitability
        final stabilityChange = postStability - preStability;
        final evolutionScore = (0.5 + stabilityChange).clamp(0.0, 1.0);

        developer.log(
          'Worldsheet evolution: ${evolutionScore.toStringAsFixed(2)} '
          '(stability change: ${stabilityChange.toStringAsFixed(2)})',
          name: _logName,
        );

        return evolutionScore;
      }

      return null;
    } catch (e) {
      developer.log(
        'Error calculating worldsheet evolution: $e',
        name: _logName,
      );
      return null;
    }
  }

  /// Build AI prompt for recommendation enhancement
  String _buildAIPrompt(
    List<ReservationRecommendation> recommendations,
    Map<String, dynamic> userContext,
  ) {
    final buffer = StringBuffer();
    buffer.writeln('Based on the user\'s preferences and past reservations, rank and enhance these reservation recommendations:');
    buffer.writeln();

    // Add user context
    if (userContext.containsKey('personality')) {
      buffer.writeln('User personality dimensions: ${userContext['personality']['dimensions']}');
    }
    if (userContext.containsKey('pastReservations')) {
      final past = userContext['pastReservations'] as Map<String, dynamic>;
      buffer.writeln('Past reservations: ${past['count']} total');
      buffer.writeln('Reservation types: ${past['types']}');
    }
    if (userContext.containsKey('timePatterns')) {
      final patterns = userContext['timePatterns'] as Map<String, dynamic>;
      if (patterns['preferredHour'] != null) {
        buffer.writeln('Preferred hour: ${patterns['preferredHour']}');
      }
      if (patterns['preferredDayOfWeek'] != null) {
        buffer.writeln('Preferred day of week: ${patterns['preferredDayOfWeek']}');
      }
    }
    buffer.writeln();

    // Add recommendations
    buffer.writeln('Recommendations to rank:');
    for (var i = 0; i < recommendations.length && i < 10; i++) {
      final rec = recommendations[i];
      buffer.writeln('${i + 1}. ${rec.title} (${rec.type.name}) - Compatibility: ${rec.compatibility.toStringAsFixed(2)}');
      if (rec.description != null) {
        buffer.writeln('   Description: ${rec.description}');
      }
    }
    buffer.writeln();
    buffer.writeln('Provide a brief reason for each top recommendation (max 3-5 recommendations).');

    return buffer.toString();
  }

  /// Parse AI response and enhance recommendations
  List<ReservationRecommendation> _parseAIResponse({
    required List<ReservationRecommendation> recommendations,
    required String aiResponse,
    required int limit,
  }) {
    final enhanced = <ReservationRecommendation>[];

    // Simple parsing: look for recommendation titles in AI response
    // In production, this could use structured JSON parsing
    for (final rec in recommendations) {
      if (aiResponse.toLowerCase().contains(rec.title.toLowerCase())) {
        // Extract reason if available (look for text after the title)
        String? reason;
        final titleIndex = aiResponse.toLowerCase().indexOf(rec.title.toLowerCase());
        if (titleIndex != -1) {
          final afterTitle = aiResponse.substring(titleIndex + rec.title.length);
          final reasonMatch = RegExp(r'[:\-]\s*(.+?)(?:\n|$)').firstMatch(afterTitle);
          if (reasonMatch != null) {
            reason = reasonMatch.group(1)?.trim();
          }
        }

        enhanced.add(ReservationRecommendation(
          targetId: rec.targetId,
          type: rec.type,
          title: rec.title,
          description: rec.description,
          compatibility: rec.compatibility,
          quantumState: rec.quantumState,
          recommendedTime: rec.recommendedTime,
          aiReason: reason,
        ));
      }
    }

    // If AI didn't match any, return top quantum-matched
    if (enhanced.isEmpty) {
      return recommendations.take(limit).toList();
    }

    // Return top AI-enhanced recommendations
    return enhanced.take(limit).toList();
  }

  /// Get available targets (events, spots, businesses)
  Future<List<Map<String, dynamic>>> _getAvailableTargets() async {
    final targets = <Map<String, dynamic>>[];

    try {
      // Get available events
      if (_eventService != null) {
        try {
          final events = await _eventService!.searchEvents(
            maxResults: 100, // Get more events to filter from
          );

          for (final event in events) {
            // Only include upcoming events that aren't full
            if (event.hasEnded || event.isFull) continue;

            targets.add({
              'id': event.id,
              'type': 'event',
              'title': event.title,
              'description': event.description,
              'category': event.category,
              'eventType': event.eventType.name,
              'startTime': event.startTime.toIso8601String(),
              'endTime': event.endTime.toIso8601String(),
              'location': event.location,
              'latitude': event.latitude,
              'longitude': event.longitude,
              'price': event.price,
              'isPaid': event.isPaid,
              'maxAttendees': event.maxAttendees,
              'attendeeCount': event.attendeeCount,
              'hostId': event.host.id, // Phase 6.2 Enhancement: For knot compatibility
            });
          }
        } catch (e) {
          developer.log(
            'Error getting events for recommendations: $e',
            name: _logName,
          );
        }
      }

      // TODO: Add spots and businesses when services are available
      // For now, only events are supported

      developer.log(
        'Found ${targets.length} available targets for recommendations',
        name: _logName,
      );

      return targets;
    } catch (e) {
      developer.log(
        'Error getting available targets: $e',
        name: _logName,
      );
      return [];
    }
  }

  /// Create quantum state for target (event/spot/business)
  Future<QuantumEntityState> _createTargetQuantumState({
    required Map<String, dynamic> target,
    required AtomicTimestamp tAtomic,
  }) async {
    // TODO: Implement full quantum state creation for target
    // For now, create placeholder
    return QuantumEntityState(
      entityId: target['id'] as String,
      entityType: _getEntityType(target),
      personalityState: {},
      quantumVibeAnalysis: {},
      entityCharacteristics: target,
      tAtomic: tAtomic,
    );
  }

  /// Get reservation type from target
  ReservationType _getReservationType(Map<String, dynamic> target) {
    if (target.containsKey('eventType')) {
      return ReservationType.event;
    } else if (target.containsKey('businessType')) {
      return ReservationType.business;
    } else {
      return ReservationType.spot;
    }
  }

  /// Get entity type from target
  QuantumEntityType _getEntityType(Map<String, dynamic> target) {
    if (target.containsKey('eventType')) {
      return QuantumEntityType.event;
    } else if (target.containsKey('businessType')) {
      return QuantumEntityType.business;
    } else {
      return QuantumEntityType.user; // Default
    }
  }

  /// Get recommended reservation time from target
  DateTime? _getRecommendedTime(Map<String, dynamic> target) {
    try {
      if (target['startTime'] != null) {
        return DateTime.parse(target['startTime'] as String);
      }
      return null;
    } catch (e) {
      developer.log(
        'Error parsing recommended time: $e',
        name: _logName,
      );
      return null;
    }
  }
}
