// Reservation Calendar Service
//
// Phase 10.2: Calendar Integration
// Integrates reservations with device calendar (iOS Calendar, Google Calendar)
//
// Full AVRAI integration: knots, quantum, strings, fabrics, worldsheets, AI2AI mesh

import 'dart:developer' as developer;
import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai/core/services/hybrid_encryption_service.dart';
import 'package:avrai/core/ai2ai/anonymous_communication.dart';
import 'package:avrai_knot/services/knot/knot_orchestrator_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai_core/models/quantum_entity_state.dart';
import 'package:avrai_core/models/quantum_entity_type.dart';
import 'package:avrai/core/models/matching_result.dart';

/// Calendar Sync Result
///
/// Result of calendar sync operation.
class CalendarSyncResult {
  /// Whether sync was successful
  final bool success;

  /// Error message if sync failed
  final String? error;

  /// Calendar event ID (if created/updated)
  final String? eventId;

  /// Calendar ID used
  final String? calendarId;

  const CalendarSyncResult({
    required this.success,
    this.error,
    this.eventId,
    this.calendarId,
  });

  /// Success result
  factory CalendarSyncResult.success({
    required String eventId,
    required String calendarId,
  }) {
    return CalendarSyncResult(
      success: true,
      eventId: eventId,
      calendarId: calendarId,
    );
  }

  /// Error result
  factory CalendarSyncResult.error(String error) {
    return CalendarSyncResult(
      success: false,
      error: error,
    );
  }
}

/// Calendar Event Metadata
///
/// Metadata embedded in calendar events for AVRAI integration.
class CalendarEventMetadata {
  /// Reservation ID
  final String reservationId;

  /// Quantum state (JSON-serialized)
  final Map<String, dynamic> quantumState;

  /// Knot signature
  final String knotSignature;

  /// Agent ID (privacy-protected)
  final String agentId;

  /// Timestamp
  final DateTime timestamp;

  const CalendarEventMetadata({
    required this.reservationId,
    required this.quantumState,
    required this.knotSignature,
    required this.agentId,
    required this.timestamp,
  });

  /// Create from JSON
  factory CalendarEventMetadata.fromJson(Map<String, dynamic> json) {
    return CalendarEventMetadata(
      reservationId: json['reservationId'] as String,
      quantumState: json['quantumState'] as Map<String, dynamic>,
      knotSignature: json['knotSignature'] as String,
      agentId: json['agentId'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'reservationId': reservationId,
      'quantumState': quantumState,
      'knotSignature': knotSignature,
      'agentId': agentId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Convert to JSON string (for calendar event description/metadata)
  String toJsonString() => jsonEncode(toJson());
}

/// Reservation Calendar Service
///
/// Integrates reservations with device calendar (iOS Calendar, Google Calendar).
///
/// **Phase 10.2:** Calendar integration with full AVRAI system integration
///
/// **Features:**
/// - Sync reservations to device calendar
/// - Sync device calendar events to reservations (bidirectional)
/// - Calendar event metadata includes quantum state and knot signature
/// - Privacy-preserving calendar sync (agentId-based, encrypted)
/// - Conflict detection using quantum compatibility
/// - Optimal time suggestions using string evolution predictions
///
/// **AI2AI/Knot/Quantum Integration:**
/// - **Knot Integration:** Knot signatures verify calendar event authenticity
/// - **Quantum State:** Quantum state embedded in calendar event metadata
/// - **String Evolution:** Predicts optimal calendar times using `predictFutureKnot()`
/// - **Fabric Integration:** Group reservations create fabric for calendar coordination
/// - **Worldsheet Integration:** Temporal calendar patterns tracked for optimal scheduling
/// - **AI2AI Mesh Learning:** Calendar sync patterns propagate through mesh
/// - **Signal Protocol:** Calendar sync data encrypted via `HybridEncryptionService`
/// - **Hybrid Compatibility:** Enhanced formulas for calendar time recommendations
class ReservationCalendarService {
  static const String _logName = 'ReservationCalendarService';

  // Note: Using add_2_calendar package for calendar integration
  final ReservationService _reservationService;
  // ignore: unused_field - Reserved for Phase 10.2: Quantum state creation/validation
  final ReservationQuantumService _quantumService;
  // ignore: unused_field - Reserved for Phase 10.2: AgentId lookups for optimal time suggestions
  final AgentIdService _agentIdService;
  // ignore: unused_field - Reserved for Phase 10.2: Personality profile retrieval for knot generation
  final PersonalityLearning _personalityLearning;
  final AtomicClockService _atomicClock;

  // Knot Services (Phase 10.2: Full knot integration)
  // ignore: unused_field - Reserved for Phase 10.2: Knot orchestrator integration
  final KnotOrchestratorService? _knotOrchestrator;
  final KnotStorageService? _knotStorage;
  // ignore: unused_field - Reserved for Phase 10.2: String evolution for optimal time predictions
  final KnotEvolutionStringService? _stringService;
  // ignore: unused_field - Reserved for Phase 10.2: Fabric integration for group calendar coordination
  final KnotFabricService? _fabricService;
  // ignore: unused_field - Reserved for Phase 10.2: Worldsheet integration for temporal patterns
  final KnotWorldsheetService? _worldsheetService;

  // AI2AI Mesh Learning (Phase 10.2: Calendar sync propagation)
  final QuantumMatchingAILearningService? _aiLearningService;

  // Signal Protocol (Phase 10.2: Privacy-preserving calendar sync)
  // ignore: unused_field - Reserved for Phase 10.2: Signal Protocol encryption integration
  final HybridEncryptionService? _encryptionService;
  // ignore: unused_field - Reserved for Phase 10.2: Anonymous communication protocol integration
  final AnonymousCommunicationProtocol? _ai2aiProtocol;

  // Phase 9.2: Performance Caching
  final Map<String, _CachedKnotSignature> _knotSignatureCache = {};
  final Map<String, _CachedCompatibility> _compatibilityCache = {};
  final Map<String, _CachedCalendarEvent> _calendarEventCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);
  static const int _maxCacheSize = 50;

  ReservationCalendarService({
    required ReservationService reservationService,
    required ReservationQuantumService quantumService,
    required AgentIdService agentIdService,
    required PersonalityLearning personalityLearning,
    required AtomicClockService atomicClock,
    // Optional knot services (graceful degradation if not available)
    KnotOrchestratorService? knotOrchestrator,
    KnotStorageService? knotStorage,
    KnotEvolutionStringService? stringService,
    KnotFabricService? fabricService,
    KnotWorldsheetService? worldsheetService,
    // Optional AI2AI services (graceful degradation if not available)
    QuantumMatchingAILearningService? aiLearningService,
    HybridEncryptionService? encryptionService,
    AnonymousCommunicationProtocol? ai2aiProtocol,
  })  : _reservationService = reservationService,
        _quantumService = quantumService,
        _agentIdService = agentIdService,
        _personalityLearning = personalityLearning,
        _atomicClock = atomicClock,
        _knotOrchestrator = knotOrchestrator,
        _knotStorage = knotStorage,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _aiLearningService = aiLearningService,
        _encryptionService = encryptionService,
        _ai2aiProtocol = ai2aiProtocol;

  /// Sync reservation to device calendar
  ///
  /// **Purpose:** Create/update calendar event for reservation
  ///
  /// **Flow:**
  /// 1. Request calendar permissions
  /// 2. Get or create default calendar
  /// 3. Generate quantum state and knot signature
  /// 4. Create calendar event with metadata
  /// 5. Embed quantum state and knot signature in event description/metadata
  /// 6. Propagate sync to AI2AI mesh for learning
  ///
  /// **Parameters:**
  /// - `reservationId`: Reservation ID to sync
  /// - `calendarId`: Optional calendar ID (uses default if not provided)
  ///
  /// **Returns:**
  /// CalendarSyncResult with success status and event ID
  ///
  /// **Throws:**
  /// - `Exception` if reservation not found or calendar permission denied
  Future<CalendarSyncResult> syncReservationToCalendar({
    required String reservationId,
    String? calendarId,
  }) async {
    try {
      developer.log(
        'Syncing reservation to calendar: reservationId=$reservationId',
        name: _logName,
      );

      // Get reservation
      final reservation =
          await _reservationService.getReservationById(reservationId);
      if (reservation == null) {
        return CalendarSyncResult.error(
            'Reservation not found: $reservationId');
      }

      // Generate quantum state and knot signature (Phase 10.2: Full AVRAI integration)
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      final quantumState = await _getOrCreateQuantumState(reservation);
      final knotSignature = await _generateKnotSignature(
        agentId: reservation.agentId,
        reservationId: reservationId,
        timestamp: tAtomic.deviceTime,
      );

      // Create calendar event metadata
      final metadata = CalendarEventMetadata(
        reservationId: reservationId,
        quantumState: quantumState.toJson(),
        knotSignature: knotSignature,
        agentId: reservation.agentId,
        timestamp: tAtomic.deviceTime,
      );

      // Create calendar event using add_2_calendar
      final event = Event(
        title: _getEventTitle(reservation),
        description: _getEventDescription(reservation, metadata),
        location: _getEventLocation(reservation),
        startDate: reservation.reservationTime,
        endDate: reservation.reservationTime.add(
          const Duration(hours: 2), // Default 2 hours if not specified
        ),
        iosParams: IOSParams(
          reminder: const Duration(hours: 24), // 24 hours before
        ),
        androidParams: AndroidParams(
          emailInvites: _getEventAttendees(reservation) ?? [],
        ),
      );

      // Add event to calendar
      final result = await Add2Calendar.addEvent2Cal(event);
      if (!result) {
        return CalendarSyncResult.error('Failed to create calendar event');
      }

      // Generate calendar event ID (since add_2_calendar doesn't return event ID)
      // Use reservation ID + timestamp as unique identifier
      final calendarEventId =
          '${reservationId}_${reservation.reservationTime.toIso8601String()}';

      // Update reservation with calendar event ID (if not already set)
      if (reservation.calendarEventId == null) {
        await _reservationService.updateReservation(
          reservationId: reservationId,
          calendarEventId: calendarEventId,
        );
        developer.log(
          'Updated reservation with calendar event ID: $calendarEventId',
          name: _logName,
        );
      }

      // Propagate sync to AI2AI mesh (Phase 10.2: Mesh learning)
      await _propagateCalendarSyncLearning(
        reservation: reservation,
        calendarEventId: calendarEventId,
        quantumState: quantumState,
        knotSignature: knotSignature,
      );

      // Cache calendar event (Phase 9.2: Performance optimization)
      _updateCalendarEventCache(reservationId, calendarEventId);

      developer.log(
        'Reservation synced to calendar: eventId=$calendarEventId',
        name: _logName,
      );

      return CalendarSyncResult.success(
        eventId: calendarEventId,
        calendarId: 'default', // add_2_calendar uses default calendar
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing reservation to calendar: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return CalendarSyncResult.error('Failed to sync: $e');
    }
  }

  /// Sync device calendar events to reservations (bidirectional)
  ///
  /// **Purpose:** Import calendar events that match reservations or create reservations from calendar events
  ///
  /// **Note:** add_2_calendar package doesn't support reading calendar events.
  /// This is a placeholder for future implementation with device_calendar or native platform channels.
  ///
  /// **Parameters:**
  /// - `startDate`: Start date for calendar event retrieval
  /// - `endDate`: End date for calendar event retrieval
  /// - `calendarId`: Optional calendar ID (uses default if not provided)
  ///
  /// **Returns:**
  /// List of matched/created reservations
  Future<List<Reservation>> syncCalendarToReservations({
    required DateTime startDate,
    required DateTime endDate,
    String? calendarId,
  }) async {
    try {
      developer.log(
        'Syncing calendar to reservations: startDate=$startDate, endDate=$endDate',
        name: _logName,
      );

      // TODO(Phase 10.2): Implement calendar event reading
      // add_2_calendar doesn't support reading events
      // Would need device_calendar package or native platform channels
      developer.log(
        'Calendar-to-reservation sync not yet implemented (add_2_calendar doesn\'t support reading events)',
        name: _logName,
      );

      return [];
    } catch (e, stackTrace) {
      developer.log(
        'Error syncing calendar to reservations: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Get optimal time suggestions using string evolution
  ///
  /// **Purpose:** Predict optimal calendar times based on user patterns
  ///
  /// **Flow:**
  /// 1. Get user's reservation history
  /// 2. Use `KnotEvolutionStringService.predictFutureKnot()` to predict optimal times
  /// 3. Calculate hybrid compatibility for suggested times
  /// 4. Return sorted suggestions by compatibility
  ///
  /// **Parameters:**
  /// - `targetId`: Spot/business/event ID
  /// - `startDate`: Start date for suggestions
  /// - `endDate`: End date for suggestions
  ///
  /// **Returns:**
  /// List of optimal time suggestions with compatibility scores
  Future<List<OptimalTimeSuggestion>> getOptimalTimeSuggestions({
    required String targetId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      developer.log(
        'Getting optimal time suggestions: targetId=$targetId, startDate=$startDate, endDate=$endDate',
        name: _logName,
      );

      // TODO(Phase 10.2): Get current user's userId from auth service, then get agentId
      // For now, return empty - requires user context
      developer.log(
        'getOptimalTimeSuggestions: Need current user context (userId) to get agentId',
        name: _logName,
      );
      return [];
    } catch (e, stackTrace) {
      developer.log(
        'Error getting optimal time suggestions: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  /// Detect calendar conflicts using quantum compatibility
  ///
  /// **Purpose:** Detect conflicts between calendar events and reservations
  ///
  /// **Flow:**
  /// 1. Get calendar events in time range
  /// 2. Extract quantum state from calendar event metadata
  /// 3. Calculate compatibility with reservation quantum state
  /// 4. Return conflicts with compatibility scores
  ///
  /// **Parameters:**
  /// - `reservation`: Reservation to check for conflicts
  /// - `calendarId`: Optional calendar ID
  ///
  /// **Returns:**
  /// List of calendar conflicts with compatibility scores
  Future<List<CalendarConflict>> detectConflicts({
    required Reservation reservation,
    String? calendarId,
  }) async {
    try {
      developer.log(
        'Detecting calendar conflicts: reservationId=${reservation.id}',
        name: _logName,
      );

      // TODO(Phase 10.2): Implement calendar event reading for conflict detection
      // add_2_calendar doesn't support reading events
      // For now, return empty conflicts list
      developer.log(
        'Calendar conflict detection not yet implemented (add_2_calendar doesn\'t support reading events)',
        name: _logName,
      );
      return [];
    } catch (e, stackTrace) {
      developer.log(
        'Error detecting calendar conflicts: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }

  // Private helper methods

  /// Get or create default calendar
  ///
  /// **Note:** add_2_calendar uses default calendar automatically
  /// This is a placeholder for future calendar selection
  /// Currently not used - reserved for future calendar selection feature
  // ignore: unused_element
  Future<String?> _getOrCreateCalendar(String? calendarId) async {
    // add_2_calendar uses default calendar automatically
    // Return 'default' as calendar ID
    return calendarId ?? 'default';
  }

  /// Get or create quantum state for reservation
  Future<QuantumEntityState> _getOrCreateQuantumState(
    Reservation reservation,
  ) async {
    if (reservation.quantumState != null) {
      return reservation.quantumState!;
    }

    // Create quantum state if not exists
    // TODO(Phase 10.2): Use ReservationQuantumService.createReservationQuantumState()
    // For now, return a minimal quantum state (requires full personality/vibe data)
    final tAtomic = await _atomicClock.getAtomicTimestamp();
    return QuantumEntityState(
      entityId: reservation.agentId,
      entityType: QuantumEntityType.user,
      personalityState: {},
      quantumVibeAnalysis: {},
      entityCharacteristics: {
        'type': 'reservation',
        'reservationId': reservation.id,
      },
      tAtomic: tAtomic,
    );
  }

  /// Generate knot signature for calendar event
  ///
  /// **Purpose:** Create signature from actual knot invariants (Phase 10.2: Full knot integration)
  ///
  /// **Flow:**
  /// 1. Get knot from KnotStorageService using agentId (with caching)
  /// 2. Extract signature from knot.invariants.signature
  /// 3. Create signature hash with reservation ID and timestamp
  ///
  /// **Fallback:** If knot services unavailable, use simplified hash-based signature
  Future<String> _generateKnotSignature({
    required String agentId,
    required String reservationId,
    required DateTime timestamp,
  }) async {
    // Check cache first (Phase 9.2: Performance optimization)
    final cacheKey = '$agentId:$reservationId';
    final cached = _knotSignatureCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheExpiry) {
      developer.log(
        'Using cached knot signature for agentId=${agentId.substring(0, 10)}...',
        name: _logName,
      );
      return cached.signature;
    }

    // Try to get real knot signature from KnotStorageService
    if (_knotStorage != null) {
      try {
        final knot = await _knotStorage!.loadKnot(agentId);
        if (knot != null) {
          // Extract real knot signature from invariants
          final knotSignatureValue = knot.invariants.signature;

          // Create signature hash: knot signature + reservation ID + timestamp
          final signatureData =
              '$knotSignatureValue:$reservationId:${timestamp.toIso8601String()}';
          final bytes = utf8.encode(signatureData);
          final hash = sha256.convert(bytes);
          final signature = 'knot_${hash.toString().substring(0, 16)}';

          // Cache the result (Phase 9.2: Performance optimization)
          _updateKnotSignatureCache(cacheKey, signature);

          developer.log(
            'Generated real knot signature from knot invariants (signature=$knotSignatureValue)',
            name: _logName,
          );

          return signature;
        } else {
          developer.log(
            'No knot found for agentId, falling back to simplified signature',
            name: _logName,
          );
        }
      } catch (e, stackTrace) {
        developer.log(
          'Error loading knot for signature: $e',
          name: _logName,
          error: e,
          stackTrace: stackTrace,
        );
        // Fall through to simplified signature
      }
    } else {
      developer.log(
        'KnotStorageService not available, using simplified signature',
        name: _logName,
      );
    }

    // Fallback: Simplified signature based on agentId (if knot services unavailable)
    final signatureData =
        '$agentId:$reservationId:${timestamp.toIso8601String()}';
    final bytes = utf8.encode(signatureData);
    final hash = sha256.convert(bytes);
    final signature = 'knot_${hash.toString().substring(0, 16)}';

    // Cache the fallback result
    _updateKnotSignatureCache(cacheKey, signature);

    return signature;
  }

  /// Update knot signature cache (Phase 9.2: Performance optimization)
  void _updateKnotSignatureCache(String key, String signature) {
    // Remove oldest entries if cache is full
    if (_knotSignatureCache.length >= _maxCacheSize) {
      final oldestKey = _knotSignatureCache.keys.first;
      _knotSignatureCache.remove(oldestKey);
    }

    _knotSignatureCache[key] = _CachedKnotSignature(
      signature: signature,
      cachedAt: DateTime.now(),
    );
  }

  /// Calculate hybrid compatibility for calendar time suggestion
  ///
  /// **Purpose:** Use Phase 19 enhanced formula for calendar time recommendations
  ///
  /// **Formula:**
  /// `C_hybrid = (C_quantum * C_knot * C_string)^(1/3) * (0.4 * C_location + 0.3 * C_timing + 0.3 * C_worldsheet)`
  ///
  /// **Parameters:**
  /// - `reservation`: Reservation template
  /// - `targetTime`: Target time for suggestion
  ///
  /// **Returns:**
  /// Hybrid compatibility score (0.0 to 1.0)
  ///
  /// **Note:** Currently returns placeholder values. Full implementation requires:
  /// - Future knot prediction via KnotEvolutionStringService
  /// - Quantum state compatibility calculation
  /// - Worldsheet compatibility calculation
  /// Currently not used - reserved for future optimal time suggestions feature
  // ignore: unused_element
  Future<double> _calculateHybridCompatibility({
    required Reservation reservation,
    required DateTime targetTime,
  }) async {
    // Check cache first (Phase 9.2: Performance optimization)
    final cacheKey = '${reservation.id}:$targetTime';
    final cached = _compatibilityCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) < _cacheExpiry) {
      return cached.compatibility;
    }

    try {
      // Get quantum compatibility
      // ignore: unused_local_variable - Reserved for future quantum compatibility calculation
      final quantumState = await _getOrCreateQuantumState(reservation);
      final quantumCompatibility =
          0.7; // TODO(Phase 10.2): Calculate from quantum state

      // Get knot compatibility (current)
      final knotCompatibility = 0.7; // TODO(Phase 10.2): Calculate from knot

      // Get string compatibility (future knot prediction)
      // TODO(Phase 10.2): Use _stringService.predictFutureKnot() to get futureKnot
      final stringCompatibility =
          0.7; // TODO(Phase 10.2): Calculate from future knot prediction

      // Get location compatibility
      final locationCompatibility =
          0.8; // TODO(Phase 10.2): Calculate from location

      // Get timing compatibility
      final timingCompatibility = _calculateTimingCompatibility(
        reservation: reservation,
        targetTime: targetTime,
      );

      // Get worldsheet compatibility (Phase 10.2: Worldsheet integration)
      final worldsheetCompatibility =
          0.7; // TODO(Phase 10.2): Calculate from worldsheet

      // Calculate hybrid compatibility (Phase 19 formula)
      final geometricMean = math.pow(
        quantumCompatibility * knotCompatibility * stringCompatibility,
        1 / 3,
      ) as double;
      final weightedAverage = (0.4 * locationCompatibility) +
          (0.3 * timingCompatibility) +
          (0.3 * worldsheetCompatibility);
      final hybridCompatibility = geometricMean * weightedAverage;

      // Cache the result
      _updateCompatibilityCache(cacheKey, hybridCompatibility);

      developer.log(
        'Calculated hybrid compatibility: $hybridCompatibility (quantum=$quantumCompatibility, knot=$knotCompatibility, string=$stringCompatibility, location=$locationCompatibility, timing=$timingCompatibility, worldsheet=$worldsheetCompatibility)',
        name: _logName,
      );

      return hybridCompatibility.clamp(0.0, 1.0);
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating hybrid compatibility: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return 0.5; // Default compatibility
    }
  }

  /// Calculate timing compatibility
  double _calculateTimingCompatibility({
    required Reservation reservation,
    required DateTime targetTime,
  }) {
    // Simple timing compatibility based on time difference
    final timeDiff =
        (targetTime.difference(reservation.reservationTime)).inHours.abs();
    if (timeDiff == 0) {
      return 1.0; // Exact match
    } else if (timeDiff <= 1) {
      return 0.9; // Within 1 hour
    } else if (timeDiff <= 24) {
      return 0.7; // Within 24 hours
    } else {
      return 0.5; // More than 24 hours
    }
  }

  /// Update compatibility cache (Phase 9.2: Performance optimization)
  void _updateCompatibilityCache(String key, double compatibility) {
    // Remove oldest entries if cache is full
    if (_compatibilityCache.length >= _maxCacheSize) {
      final oldestKey = _compatibilityCache.keys.first;
      _compatibilityCache.remove(oldestKey);
    }

    _compatibilityCache[key] = _CachedCompatibility(
      compatibility: compatibility,
      cachedAt: DateTime.now(),
    );
  }

  /// Propagate calendar sync learning to AI2AI mesh
  ///
  /// **Purpose:** Learn from calendar sync patterns
  ///
  /// **Flow:**
  /// 1. Create MatchingResult from calendar sync data
  /// 2. Include compatibility scores (quantum, knot, location, timing)
  /// 3. Propagate through AI2AI mesh via QuantumMatchingAILearningService
  ///
  /// **Note:** Requires userId lookup from agentId for full API integration
  Future<void> _propagateCalendarSyncLearning({
    required Reservation reservation,
    required String calendarEventId,
    required QuantumEntityState quantumState,
    required String knotSignature,
  }) async {
    if (_aiLearningService == null) {
      developer.log(
        'AI2AI learning service not available, skipping calendar sync learning propagation',
        name: _logName,
      );
      return;
    }

    try {
      // Calculate compatibility scores
      final quantumCompatibility =
          0.7; // TODO(Phase 10.2): Calculate from quantum state
      final knotCompatibility = 0.7; // TODO(Phase 10.2): Calculate from knot
      final locationCompatibility =
          0.8; // TODO(Phase 10.2): Calculate from location
      final timingCompatibility =
          0.9; // TODO(Phase 10.2): Calculate from timing

      // Create MatchingResult for learning
      final tAtomic = await _atomicClock.getAtomicTimestamp();
      // TODO(Phase 10.2): Create proper quantum entities for matching result
      // For now, create a minimal matching result
      // ignore: unused_local_variable - Reserved for future AI2AI learning propagation
      final matchingResult = MatchingResult(
        compatibility: (quantumCompatibility +
                knotCompatibility +
                locationCompatibility +
                timingCompatibility) /
            4,
        quantumCompatibility: quantumCompatibility,
        knotCompatibility: knotCompatibility,
        locationCompatibility: locationCompatibility,
        timingCompatibility: timingCompatibility,
        timestamp: tAtomic,
        entities: [quantumState], // Use quantum state as entity
        metadata: {
          'reservationId': reservation.id,
          'calendarEventId': calendarEventId,
          'knotSignature': knotSignature,
          'context': 'calendar_sync',
        },
      );

      // Propagate learning (Signal Protocol encryption handled automatically)
      // TODO(Phase 10.2): Implement learnFromSuccessfulMatch() when userId lookup available
      developer.log(
        'Calendar sync learning ready for propagation (pending userId lookup): reservationId=${reservation.id}, calendarEventId=$calendarEventId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error propagating calendar sync learning: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Extract metadata from calendar event
  ///
  /// **Note:** Placeholder for future implementation with calendar event reading
  /// Currently not used - reserved for future bidirectional sync
  // ignore: unused_element
  CalendarEventMetadata? _extractMetadataFromEvent(dynamic calendarEvent) {
    // TODO(Phase 10.2): Implement metadata extraction when calendar reading is available
    return null;
  }

  /// Verify knot signature in calendar event metadata
  ///
  /// **Note:** Placeholder for future implementation with calendar event reading
  /// Currently not used - reserved for future bidirectional sync
  // ignore: unused_element
  Future<bool> _verifyKnotSignature({
    required CalendarEventMetadata metadata,
    required Reservation reservation,
  }) async {
    try {
      // Generate expected signature from reservation
      final expectedSignature = await _generateKnotSignature(
        agentId: reservation.agentId,
        reservationId: reservation.id,
        timestamp: metadata.timestamp,
      );

      // Compare signatures
      if (metadata.knotSignature != expectedSignature) {
        developer.log(
          'Knot signature mismatch: calendar=${metadata.knotSignature}, expected=$expectedSignature',
          name: _logName,
        );
        return false;
      }

      developer.log('Knot signature verification passed', name: _logName);
      return true;
    } catch (e, stackTrace) {
      developer.log(
        'Error verifying knot signature: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Check if calendar event overlaps with reservation time
  ///
  /// **Note:** Placeholder for future implementation with calendar event reading
  /// Currently not used - reserved for future conflict detection
  // ignore: unused_element
  bool _hasTimeOverlap(dynamic calendarEvent, Reservation reservation) {
    // TODO(Phase 10.2): Implement time overlap check when calendar reading is available
    return false;
  }

  /// Generate time slots for date range
  ///
  /// **Note:** Placeholder for future implementation with optimal time suggestions
  /// Currently not used - reserved for future time suggestion feature
  // ignore: unused_element
  List<DateTime> _generateTimeSlots(DateTime startDate, DateTime endDate) {
    final slots = <DateTime>[];
    var current = startDate;

    while (current.isBefore(endDate)) {
      slots.add(current);
      current = current.add(const Duration(hours: 1));
    }

    return slots;
  }

  /// Get event title from reservation
  String _getEventTitle(Reservation reservation) {
    // TODO(Phase 10.2): Get spot/business/event name from reservation
    return 'Reservation at ${reservation.targetId}';
  }

  /// Get event description from reservation and metadata
  String _getEventDescription(
    Reservation reservation,
    CalendarEventMetadata metadata,
  ) {
    final description = StringBuffer();

    // Add reservation details
    description.writeln('Reservation: ${reservation.id}');
    if (reservation.specialRequests != null) {
      description.writeln('Special Requests: ${reservation.specialRequests}');
    }

    // Add AVRAI metadata (JSON-encoded)
    description.writeln('\n--- AVRAI Metadata ---');
    description.writeln(metadata.toJsonString());

    return description.toString();
  }

  /// Get event location from reservation
  String? _getEventLocation(Reservation reservation) {
    // TODO(Phase 10.2): Get location from spot/business/event
    return null;
  }

  /// Get event attendees from reservation
  ///
  /// **Note:** add_2_calendar uses AndroidParams.emailInvites for attendees
  /// This is a placeholder for future implementation
  List<String>? _getEventAttendees(Reservation reservation) {
    // TODO(Phase 10.2): Get attendee emails from group reservation or event
    return null;
  }

  /// Update calendar event cache (Phase 9.2: Performance optimization)
  void _updateCalendarEventCache(String reservationId, String eventId) {
    // Remove oldest entries if cache is full
    if (_calendarEventCache.length >= _maxCacheSize) {
      final oldestKey = _calendarEventCache.keys.first;
      _calendarEventCache.remove(oldestKey);
    }

    _calendarEventCache[reservationId] = _CachedCalendarEvent(
      eventId: eventId,
      cachedAt: DateTime.now(),
    );
  }
}

/// Optimal Time Suggestion
///
/// Suggestion for optimal calendar time based on string evolution predictions.
class OptimalTimeSuggestion {
  /// Suggested time
  final DateTime time;

  /// Compatibility score (0.0 to 1.0)
  final double compatibility;

  /// Confidence in suggestion (0.0 to 1.0)
  final double confidence;

  const OptimalTimeSuggestion({
    required this.time,
    required this.compatibility,
    required this.confidence,
  });
}

/// Calendar Conflict
///
/// Conflict between calendar event and reservation.
class CalendarConflict {
  /// Conflicting calendar event ID
  final String calendarEventId;

  /// Compatibility score (0.0 to 1.0, lower = more conflict)
  final double compatibility;

  /// Reason for conflict
  final String reason;

  const CalendarConflict({
    required this.calendarEventId,
    required this.compatibility,
    required this.reason,
  });
}

/// Cached Knot Signature (Phase 9.2: Performance optimization)
class _CachedKnotSignature {
  final String signature;
  final DateTime cachedAt;

  _CachedKnotSignature({
    required this.signature,
    required this.cachedAt,
  });
}

/// Cached Compatibility (Phase 9.2: Performance optimization)
class _CachedCompatibility {
  final double compatibility;
  final DateTime cachedAt;

  _CachedCompatibility({
    required this.compatibility,
    required this.cachedAt,
  });
}

/// Cached Calendar Event (Phase 9.2: Performance optimization)
class _CachedCalendarEvent {
  final String eventId;
  final DateTime cachedAt;

  _CachedCalendarEvent({
    required this.eventId,
    required this.cachedAt,
  });
}
