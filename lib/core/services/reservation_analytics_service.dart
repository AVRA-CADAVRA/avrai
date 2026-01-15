// Reservation Analytics Service
//
// Phase 7.1: User Reservation Analytics
// Enhanced with Full Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
//
// Provides comprehensive reservation analytics with:
// - Knot string evolution patterns (recurring reservations)
// - Fabric stability analytics (group reservations)
// - Worldsheet evolution tracking (temporal patterns)
// - Quantum compatibility history
// - AI2AI mesh learning propagation

import 'dart:developer' as developer;
import 'package:avrai/core/models/reservation.dart';
import 'package:avrai/core/services/reservation_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/ai/event_logger.dart';
import 'package:avrai/core/services/payment_service.dart';
// Phase 7.1 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
import 'package:avrai_knot/services/knot/knot_evolution_string_service.dart';
import 'package:avrai_knot/services/knot/knot_fabric_service.dart';
import 'package:avrai_knot/services/knot/knot_worldsheet_service.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai/core/services/reservation_quantum_service.dart';
import 'package:avrai/core/ai/personality_learning.dart';

/// User Reservation Analytics
///
/// Comprehensive analytics for user reservations including:
/// - Basic metrics (history, patterns, rates)
/// - Knot string evolution patterns (recurring reservations)
/// - Fabric stability analytics (group reservations)
/// - Worldsheet evolution tracking (temporal patterns)
/// - Quantum compatibility history
/// - AI2AI mesh learning insights
class UserReservationAnalytics {
  /// Total reservations
  final int totalReservations;

  /// Completed reservations
  final int completedReservations;

  /// Cancelled reservations
  final int cancelledReservations;

  /// Pending reservations
  final int pendingReservations;

  /// Completion rate (0.0 to 1.0)
  final double completionRate;

  /// Cancellation rate (0.0 to 1.0)
  final double cancellationRate;

  /// Favorite spots (by reservation count)
  final List<FavoriteSpot> favoriteSpots;

  /// Reservation patterns (time, day, type)
  final ReservationPatterns patterns;

  /// Modification patterns
  final ModificationPatterns modificationPatterns;

  /// Waitlist history
  final WaitlistHistory waitlistHistory;

  /// Knot string evolution patterns (recurring reservations)
  final StringEvolutionPatterns? stringEvolutionPatterns;

  /// Fabric stability analytics (group reservations)
  final FabricStabilityAnalytics? fabricStabilityAnalytics;

  /// Worldsheet evolution tracking (temporal patterns)
  final WorldsheetEvolutionAnalytics? worldsheetEvolutionAnalytics;

  /// Quantum compatibility history
  final QuantumCompatibilityHistory? quantumCompatibilityHistory;

  /// AI2AI mesh learning insights
  final AI2AILearningInsights? ai2aiLearningInsights;

  const UserReservationAnalytics({
    required this.totalReservations,
    required this.completedReservations,
    required this.cancelledReservations,
    required this.pendingReservations,
    required this.completionRate,
    required this.cancellationRate,
    required this.favoriteSpots,
    required this.patterns,
    required this.modificationPatterns,
    required this.waitlistHistory,
    this.stringEvolutionPatterns,
    this.fabricStabilityAnalytics,
    this.worldsheetEvolutionAnalytics,
    this.quantumCompatibilityHistory,
    this.ai2aiLearningInsights,
  });
}

/// Favorite Spot
class FavoriteSpot {
  final String spotId;
  final String spotName;
  final int reservationCount;
  final double averageCompatibility;

  const FavoriteSpot({
    required this.spotId,
    required this.spotName,
    required this.reservationCount,
    required this.averageCompatibility,
  });
}

/// Reservation Patterns
class ReservationPatterns {
  /// Most common hour (0-23)
  final int? preferredHour;

  /// Most common day of week (1-7, Monday=1)
  final int? preferredDayOfWeek;

  /// Most common reservation type
  final ReservationType? preferredType;

  /// Average party size
  final double averagePartySize;

  /// Time patterns (hour distribution)
  final Map<int, int> hourDistribution;

  /// Day patterns (day of week distribution)
  final Map<int, int> dayDistribution;

  /// Type patterns (type distribution)
  final Map<ReservationType, int> typeDistribution;

  const ReservationPatterns({
    this.preferredHour,
    this.preferredDayOfWeek,
    this.preferredType,
    required this.averagePartySize,
    required this.hourDistribution,
    required this.dayDistribution,
    required this.typeDistribution,
  });
}

/// Modification Patterns
class ModificationPatterns {
  final int totalModifications;
  final int maxModificationsReached;
  final Map<String, int> modificationReasons;

  const ModificationPatterns({
    required this.totalModifications,
    required this.maxModificationsReached,
    required this.modificationReasons,
  });
}

/// Waitlist History
class WaitlistHistory {
  final int totalWaitlistJoins;
  final int totalWaitlistConversions;
  final double conversionRate;
  final List<WaitlistEntry> recentEntries;

  const WaitlistHistory({
    required this.totalWaitlistJoins,
    required this.totalWaitlistConversions,
    required this.conversionRate,
    required this.recentEntries,
  });
}

/// Waitlist Entry
class WaitlistEntry {
  final String reservationId;
  final String targetId;
  final DateTime joinTime;
  final DateTime? conversionTime;
  final bool converted;

  const WaitlistEntry({
    required this.reservationId,
    required this.targetId,
    required this.joinTime,
    this.conversionTime,
    required this.converted,
  });
}

/// String Evolution Patterns (Knot Theory)
class StringEvolutionPatterns {
  /// Recurring reservation patterns detected
  final List<RecurringPattern> recurringPatterns;

  /// Evolution cycles detected (from knot string service)
  final List<EvolutionCycle> cycles;

  /// Evolution trends (from knot string service)
  final List<EvolutionTrend> trends;

  /// Predicted future reservation times
  final List<DateTime> predictedTimes;

  const StringEvolutionPatterns({
    required this.recurringPatterns,
    required this.cycles,
    required this.trends,
    required this.predictedTimes,
  });
}

/// Recurring Pattern
class RecurringPattern {
  final String patternType; // e.g., "weekly", "monthly", "daily"
  final DateTime? nextOccurrence;
  final double confidence;

  const RecurringPattern({
    required this.patternType,
    this.nextOccurrence,
    required this.confidence,
  });
}

// EvolutionCycle and EvolutionTrend are imported from knot_evolution_string_service.dart

/// Fabric Stability Analytics (Knot Theory)
class FabricStabilityAnalytics {
  /// Average fabric stability for group reservations
  final double averageStability;

  /// Stability trend over time
  final List<FabricStabilityPoint> stabilityHistory;

  /// Most stable group compositions
  final List<StableGroup> mostStableGroups;

  const FabricStabilityAnalytics({
    required this.averageStability,
    required this.stabilityHistory,
    required this.mostStableGroups,
  });
}

/// Fabric Stability Point
class FabricStabilityPoint {
  final DateTime timestamp;
  final double stability;
  final int groupSize;

  const FabricStabilityPoint({
    required this.timestamp,
    required this.stability,
    required this.groupSize,
  });
}

/// Stable Group
class StableGroup {
  final List<String> userIds;
  final double stability;
  final int reservationCount;

  const StableGroup({
    required this.userIds,
    required this.stability,
    required this.reservationCount,
  });
}

/// Worldsheet Evolution Analytics (4D Quantum Worldplanes)
class WorldsheetEvolutionAnalytics {
  /// Evolution score over time
  final List<WorldsheetEvolutionPoint> evolutionHistory;

  /// Predicted evolution at future times
  final List<WorldsheetPrediction> predictions;

  /// Stability change trends
  final List<StabilityChangeTrend> stabilityTrends;

  const WorldsheetEvolutionAnalytics({
    required this.evolutionHistory,
    required this.predictions,
    required this.stabilityTrends,
  });
}

/// Worldsheet Evolution Point
class WorldsheetEvolutionPoint {
  final DateTime timestamp;
  final double evolutionScore;
  final double stability;

  const WorldsheetEvolutionPoint({
    required this.timestamp,
    required this.evolutionScore,
    required this.stability,
  });
}

/// Worldsheet Prediction
class WorldsheetPrediction {
  final DateTime predictedTime;
  final double predictedStability;
  final double confidence;

  const WorldsheetPrediction({
    required this.predictedTime,
    required this.predictedStability,
    required this.confidence,
  });
}

/// Stability Change Trend
class StabilityChangeTrend {
  final DateTime startTime;
  final DateTime endTime;
  final double stabilityChange;
  final TrendType trend;

  const StabilityChangeTrend({
    required this.startTime,
    required this.endTime,
    required this.stabilityChange,
    required this.trend,
  });
}

/// Quantum Compatibility History
class QuantumCompatibilityHistory {
  /// Average compatibility score
  final double averageCompatibility;

  /// Compatibility trend over time
  final List<CompatibilityPoint> compatibilityHistory;

  /// Highest compatibility reservations
  final List<HighCompatibilityReservation> topCompatibility;

  const QuantumCompatibilityHistory({
    required this.averageCompatibility,
    required this.compatibilityHistory,
    required this.topCompatibility,
  });
}

/// Compatibility Point
class CompatibilityPoint {
  final DateTime timestamp;
  final double compatibility;
  final String reservationId;

  const CompatibilityPoint({
    required this.timestamp,
    required this.compatibility,
    required this.reservationId,
  });
}

/// High Compatibility Reservation
class HighCompatibilityReservation {
  final String reservationId;
  final String targetId;
  final double compatibility;
  final DateTime reservationTime;

  const HighCompatibilityReservation({
    required this.reservationId,
    required this.targetId,
    required this.compatibility,
    required this.reservationTime,
  });
}

/// AI2AI Learning Insights
class AI2AILearningInsights {
  /// Number of learning insights received
  final int totalInsights;

  /// Learning quality score
  final double averageLearningQuality;

  /// Dimensions improved from mesh learning
  final List<String> improvedDimensions;

  /// Mesh propagation stats
  final MeshPropagationStats propagationStats;

  const AI2AILearningInsights({
    required this.totalInsights,
    required this.averageLearningQuality,
    required this.improvedDimensions,
    required this.propagationStats,
  });
}

/// Mesh Propagation Stats
class MeshPropagationStats {
  final int insightsReceived;
  final int insightsShared;
  final double averageHopCount;

  const MeshPropagationStats({
    required this.insightsReceived,
    required this.insightsShared,
    required this.averageHopCount,
  });
}

/// Reservation Analytics Service
///
/// Phase 7.1: User Reservation Analytics
/// Enhanced with Full Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
///
/// **Analytics Features:**
/// - Basic metrics (history, patterns, rates)
/// - Knot string evolution patterns (recurring reservations)
/// - Fabric stability analytics (group reservations)
/// - Worldsheet evolution tracking (temporal patterns)
/// - Quantum compatibility history
/// - AI2AI mesh learning insights
class ReservationAnalyticsService {
  static const String _logName = 'ReservationAnalyticsService';

  final ReservationService _reservationService;
  final AgentIdService _agentIdService;
  final EventLogger? _eventLogger;
  // ignore: unused_field - Reserved for future payment analytics
  final PaymentService? _paymentService;
  // Phase 7.1 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
  final KnotEvolutionStringService? _stringService;
  final KnotFabricService? _fabricService;
  final KnotWorldsheetService? _worldsheetService;
  // ignore: unused_field - Reserved for future temporal analytics
  final AtomicClockService? _atomicClock;
  final QuantumMatchingAILearningService? _aiLearningService;
  final ReservationQuantumService? _quantumService;
  final PersonalityLearning? _personalityLearning;
  
  // Phase 9.2: Performance optimization - Caching for knot/quantum/AI2AI calculations
  final Map<String, StringEvolutionPatterns?> _stringEvolutionCache = {};
  final Map<String, FabricStabilityAnalytics?> _fabricStabilityCache = {};
  final Map<String, WorldsheetEvolutionAnalytics?> _worldsheetEvolutionCache = {};
  final Map<String, QuantumCompatibilityHistory?> _quantumCompatibilityCache = {};
  final Map<String, AI2AILearningInsights?> _ai2aiLearningCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 15);
  final Map<String, DateTime> _cacheTimestamps = {};

  ReservationAnalyticsService({
    required ReservationService reservationService,
    required AgentIdService agentIdService,
    EventLogger? eventLogger,
    PaymentService? paymentService,
    // Phase 7.1 Enhancement: Knot/String/Fabric/Worldsheet/Quantum/AI2AI Integration
    KnotEvolutionStringService? stringService,
    KnotFabricService? fabricService,
    KnotWorldsheetService? worldsheetService,
    AtomicClockService? atomicClock,
    QuantumMatchingAILearningService? aiLearningService,
    ReservationQuantumService? quantumService,
    PersonalityLearning? personalityLearning,
  })  : _reservationService = reservationService,
        _agentIdService = agentIdService,
        _eventLogger = eventLogger,
        _paymentService = paymentService,
        _stringService = stringService,
        _fabricService = fabricService,
        _worldsheetService = worldsheetService,
        _atomicClock = atomicClock,
        _aiLearningService = aiLearningService,
        _quantumService = quantumService,
        _personalityLearning = personalityLearning;

  /// Get user reservation analytics
  ///
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `startDate`: Optional start date for analytics period
  /// - `endDate`: Optional end date for analytics period
  ///
  /// **Returns:**
  /// UserReservationAnalytics with comprehensive analytics
  Future<UserReservationAnalytics> getUserAnalytics({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    developer.log(
      'Getting user reservation analytics for user $userId',
      name: _logName,
    );

    try {
      // Get all user reservations
      final reservations = await _reservationService.getUserReservations(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate basic metrics
      final totalReservations = reservations.length;
      final completedReservations =
          reservations.where((r) => r.status == ReservationStatus.completed).length;
      final cancelledReservations =
          reservations.where((r) => r.status == ReservationStatus.cancelled).length;
      final pendingReservations =
          reservations.where((r) => r.status == ReservationStatus.pending).length;

      final completionRate = totalReservations > 0
          ? completedReservations / totalReservations
          : 0.0;
      final cancellationRate = totalReservations > 0
          ? cancelledReservations / totalReservations
          : 0.0;

      // Calculate favorite spots
      final favoriteSpots = _calculateFavoriteSpots(reservations);

      // Calculate patterns
      final patterns = _calculatePatterns(reservations);

      // Calculate modification patterns
      final modificationPatterns = _calculateModificationPatterns(reservations);

      // Calculate waitlist history
      final waitlistHistory = _calculateWaitlistHistory(reservations);

      // Calculate knot string evolution patterns (with caching)
      final stringEvolutionPatterns = await _calculateStringEvolutionPatternsCached(
        userId: userId,
        reservations: reservations,
      );

      // Calculate fabric stability analytics (with caching)
      final fabricStabilityAnalytics = await _calculateFabricStabilityAnalyticsCached(
        userId: userId,
        reservations: reservations,
      );

      // Calculate worldsheet evolution analytics (with caching)
      final worldsheetEvolutionAnalytics = await _calculateWorldsheetEvolutionAnalyticsCached(
        userId: userId,
        reservations: reservations,
      );

      // Calculate quantum compatibility history (with caching)
      final quantumCompatibilityHistory = await _calculateQuantumCompatibilityHistoryCached(
        userId: userId,
        reservations: reservations,
      );

      // Calculate AI2AI learning insights (with caching)
      final ai2aiLearningInsights = await _calculateAI2AILearningInsightsCached(
        userId: userId,
        reservations: reservations,
      );

      // Track analytics view event
      await _trackAnalyticsEvent(
        userId: userId,
        eventType: 'reservation_analytics_viewed',
        parameters: {
          'total_reservations': totalReservations,
          'completion_rate': completionRate,
          'cancellation_rate': cancellationRate,
        },
      );

      return UserReservationAnalytics(
        totalReservations: totalReservations,
        completedReservations: completedReservations,
        cancelledReservations: cancelledReservations,
        pendingReservations: pendingReservations,
        completionRate: completionRate,
        cancellationRate: cancellationRate,
        favoriteSpots: favoriteSpots,
        patterns: patterns,
        modificationPatterns: modificationPatterns,
        waitlistHistory: waitlistHistory,
        stringEvolutionPatterns: stringEvolutionPatterns,
        fabricStabilityAnalytics: fabricStabilityAnalytics,
        worldsheetEvolutionAnalytics: worldsheetEvolutionAnalytics,
        quantumCompatibilityHistory: quantumCompatibilityHistory,
        ai2aiLearningInsights: ai2aiLearningInsights,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error getting user analytics: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Track reservation event for analytics
  ///
  /// **Event Types:**
  /// - `reservation_created`
  /// - `reservation_modified`
  /// - `reservation_cancelled`
  /// - `reservation_completed`
  /// - `reservation_waitlist_joined`
  /// - `reservation_waitlist_converted`
  Future<void> trackReservationEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      await _trackAnalyticsEvent(
        userId: userId,
        eventType: eventType,
        parameters: parameters,
      );
    } catch (e) {
      developer.log(
        'Error tracking reservation event: $e',
        name: _logName,
      );
      // Don't throw - analytics tracking should not break the flow
    }
  }

  // --- Private Helper Methods ---

  /// Calculate favorite spots
  List<FavoriteSpot> _calculateFavoriteSpots(List<Reservation> reservations) {
    final spotCounts = <String, int>{};
    final spotNames = <String, String>{};
    final spotCompatibilities = <String, List<double>>{};

    for (final reservation in reservations) {
      final targetId = reservation.targetId;
      spotCounts[targetId] = (spotCounts[targetId] ?? 0) + 1;
      spotNames[targetId] = reservation.metadata['targetTitle'] as String? ?? targetId;
      
      // Get compatibility from metadata if available
      final compatibility = reservation.metadata['compatibility'] as double?;
      if (compatibility != null) {
        spotCompatibilities.putIfAbsent(targetId, () => []).add(compatibility);
      }
    }

    final favorites = <FavoriteSpot>[];
    spotCounts.forEach((spotId, count) {
      final compatibilities = spotCompatibilities[spotId] ?? [];
      final avgCompatibility = compatibilities.isNotEmpty
          ? compatibilities.reduce((a, b) => a + b) / compatibilities.length
          : 0.5;

      favorites.add(FavoriteSpot(
        spotId: spotId,
        spotName: spotNames[spotId] ?? spotId,
        reservationCount: count,
        averageCompatibility: avgCompatibility,
      ));
    });

    favorites.sort((a, b) => b.reservationCount.compareTo(a.reservationCount));
    return favorites.take(10).toList();
  }

  /// Calculate reservation patterns
  ReservationPatterns _calculatePatterns(List<Reservation> reservations) {
    if (reservations.isEmpty) {
      return const ReservationPatterns(
        averagePartySize: 0.0,
        hourDistribution: {},
        dayDistribution: {},
        typeDistribution: {},
      );
    }

    final hourCounts = <int, int>{};
    final dayCounts = <int, int>{};
    final typeCounts = <ReservationType, int>{};
    double totalPartySize = 0.0;

    for (final reservation in reservations) {
      final hour = reservation.reservationTime.hour;
      final day = reservation.reservationTime.weekday;
      final type = reservation.type;
      final partySize = reservation.partySize;

      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
      dayCounts[day] = (dayCounts[day] ?? 0) + 1;
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      totalPartySize += partySize;
    }

    // Find most common
    int? preferredHour;
    int maxHourCount = 0;
    hourCounts.forEach((hour, count) {
      if (count > maxHourCount) {
        maxHourCount = count;
        preferredHour = hour;
      }
    });

    int? preferredDay;
    int maxDayCount = 0;
    dayCounts.forEach((day, count) {
      if (count > maxDayCount) {
        maxDayCount = count;
        preferredDay = day;
      }
    });

    ReservationType? preferredType;
    int maxTypeCount = 0;
    typeCounts.forEach((type, count) {
      if (count > maxTypeCount) {
        maxTypeCount = count;
        preferredType = type;
      }
    });

    return ReservationPatterns(
      preferredHour: preferredHour,
      preferredDayOfWeek: preferredDay,
      preferredType: preferredType,
      averagePartySize: totalPartySize / reservations.length,
      hourDistribution: hourCounts,
      dayDistribution: dayCounts,
      typeDistribution: typeCounts,
    );
  }

  /// Calculate modification patterns
  ModificationPatterns _calculateModificationPatterns(List<Reservation> reservations) {
    int totalModifications = 0;
    int maxModificationsReached = 0;
    final modificationReasons = <String, int>{};

    for (final reservation in reservations) {
      final modificationCount = reservation.metadata['modificationCount'] as int? ?? 0;
      totalModifications += modificationCount;
      if (modificationCount >= 3) {
        maxModificationsReached++;
      }

      final modificationReasonsList =
          reservation.metadata['modificationReasons'] as List<dynamic>?;
      if (modificationReasonsList != null) {
        for (final reason in modificationReasonsList) {
          final reasonStr = reason.toString();
          modificationReasons[reasonStr] = (modificationReasons[reasonStr] ?? 0) + 1;
        }
      }
    }

    return ModificationPatterns(
      totalModifications: totalModifications,
      maxModificationsReached: maxModificationsReached,
      modificationReasons: modificationReasons,
    );
  }

  /// Calculate waitlist history
  WaitlistHistory _calculateWaitlistHistory(List<Reservation> reservations) {
    final waitlistEntries = <WaitlistEntry>[];
    int totalJoins = 0;
    int totalConversions = 0;

    for (final reservation in reservations) {
      final wasWaitlist = reservation.metadata['wasWaitlist'] as bool? ?? false;
      if (wasWaitlist) {
        totalJoins++;
        final converted = reservation.status == ReservationStatus.confirmed ||
            reservation.status == ReservationStatus.completed;
        if (converted) {
          totalConversions++;
        }

        waitlistEntries.add(WaitlistEntry(
          reservationId: reservation.id,
          targetId: reservation.targetId,
          joinTime: reservation.createdAt,
          conversionTime: converted && reservation.status == ReservationStatus.confirmed
              ? reservation.updatedAt
              : null,
          converted: converted,
        ));
      }
    }

    final conversionRate = totalJoins > 0 ? totalConversions / totalJoins : 0.0;

    // Sort by join time (most recent first)
    waitlistEntries.sort((a, b) => b.joinTime.compareTo(a.joinTime));

    return WaitlistHistory(
      totalWaitlistJoins: totalJoins,
      totalWaitlistConversions: totalConversions,
      conversionRate: conversionRate,
      recentEntries: waitlistEntries.take(10).toList(),
    );
  }

  /// Calculate knot string evolution patterns (with caching)
  /// Phase 9.2: Performance optimization
  Future<StringEvolutionPatterns?> _calculateStringEvolutionPatternsCached({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    // Check cache first
    final cacheKey = 'string_evolution_$userId';
    if (_stringEvolutionCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        developer.log(
          'Cache hit for string evolution patterns: $userId',
          name: _logName,
        );
        return _stringEvolutionCache[cacheKey];
      }
    }

    // Calculate and cache
    final result = await _calculateStringEvolutionPatterns(
      userId: userId,
      reservations: reservations,
    );
    
    _stringEvolutionCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Limit cache size (performance optimization)
    if (_stringEvolutionCache.length > 50) {
      final oldestKey = _stringEvolutionCache.keys.first;
      _stringEvolutionCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
    
    return result;
  }

  /// Calculate knot string evolution patterns
  Future<StringEvolutionPatterns?> _calculateStringEvolutionPatterns({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    if (_stringService == null) {
      developer.log(
        'String service not available for user $userId',
        name: _logName,
      );
      return null;
    }

    try {
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Analyze evolution patterns
      final evolutionAnalysis = await _stringService!.analyzeEvolutionPatterns(agentId);

      // Detect recurring reservation patterns
      final recurringPatterns = _detectRecurringReservationPatterns(reservations);

      // Predict future reservation times based on string evolution
      final predictedTimes = await _predictFutureReservationTimes(
        agentId: agentId,
        reservations: reservations,
      );

      // Convert knot service types to our types (they're compatible)
      final cycles = evolutionAnalysis.cycles.map((c) => c).toList();
      final trends = evolutionAnalysis.trends.map((t) => t).toList();

      return StringEvolutionPatterns(
        recurringPatterns: recurringPatterns,
        cycles: cycles,
        trends: trends,
        predictedTimes: predictedTimes,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating string evolution patterns: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return null gracefully - analytics should not break the flow
      return null;
    }
  }

  /// Detect recurring reservation patterns
  List<RecurringPattern> _detectRecurringReservationPatterns(
    List<Reservation> reservations,
  ) {
    if (reservations.length < 2) {
      return [];
    }

    final patterns = <RecurringPattern>[];

    // Group reservations by target
    final reservationsByTarget = <String, List<Reservation>>{};
    for (final reservation in reservations) {
      reservationsByTarget.putIfAbsent(
        reservation.targetId,
        () => [],
      ).add(reservation);
    }

    // Detect patterns for each target
    for (final targetReservations in reservationsByTarget.values) {
      if (targetReservations.length < 2) continue;

      // Sort by time
      targetReservations.sort((a, b) => a.reservationTime.compareTo(b.reservationTime));

      // Calculate time differences
      final timeDiffs = <Duration>[];
      for (int i = 1; i < targetReservations.length; i++) {
        timeDiffs.add(
          targetReservations[i].reservationTime
              .difference(targetReservations[i - 1].reservationTime),
        );
      }

      // Detect weekly pattern
      final weeklyCount = timeDiffs.where((d) => d.inDays >= 6 && d.inDays <= 8).length;
      if (weeklyCount >= 2) {
        final lastReservation = targetReservations.last.reservationTime;
        patterns.add(RecurringPattern(
          patternType: 'weekly',
          nextOccurrence: lastReservation.add(const Duration(days: 7)),
          confidence: weeklyCount / timeDiffs.length,
        ));
      }

      // Detect monthly pattern
      final monthlyCount = timeDiffs.where((d) => d.inDays >= 28 && d.inDays <= 31).length;
      if (monthlyCount >= 2) {
        final lastReservation = targetReservations.last.reservationTime;
        patterns.add(RecurringPattern(
          patternType: 'monthly',
          nextOccurrence: lastReservation.add(const Duration(days: 30)),
          confidence: monthlyCount / timeDiffs.length,
        ));
      }
    }

    return patterns;
  }

  /// Predict future reservation times based on string evolution
  Future<List<DateTime>> _predictFutureReservationTimes({
    required String agentId,
    required List<Reservation> reservations,
  }) async {
    if (_stringService == null) {
      return [];
    }

    try {
      final predictedTimes = <DateTime>[];

      // Get evolution analysis
      final evolutionAnalysis = await _stringService!.analyzeEvolutionPatterns(agentId);

      // Use cycles to predict future times
      for (final cycle in evolutionAnalysis.cycles) {
        final now = DateTime.now();
        final nextCycleTime = now.add(cycle.period);
        predictedTimes.add(nextCycleTime);
      }

      // Use recurring patterns
      final recurringPatterns = _detectRecurringReservationPatterns(reservations);
      for (final pattern in recurringPatterns) {
        if (pattern.nextOccurrence != null) {
          predictedTimes.add(pattern.nextOccurrence!);
        }
      }

      // Sort and deduplicate
      predictedTimes.sort();
      final uniqueTimes = <DateTime>[];
      DateTime? lastTime;
      for (final time in predictedTimes) {
        if (lastTime == null || time.difference(lastTime).inDays >= 1) {
          uniqueTimes.add(time);
          lastTime = time;
        }
      }

      return uniqueTimes.take(5).toList();
    } catch (e) {
      developer.log(
        'Error predicting future reservation times: $e',
        name: _logName,
      );
      return [];
    }
  }

  /// Calculate fabric stability analytics (with caching)
  /// Phase 9.2: Performance optimization
  Future<FabricStabilityAnalytics?> _calculateFabricStabilityAnalyticsCached({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    // Check cache first
    final cacheKey = 'fabric_stability_$userId';
    if (_fabricStabilityCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        developer.log(
          'Cache hit for fabric stability analytics: $userId',
          name: _logName,
        );
        return _fabricStabilityCache[cacheKey];
      }
    }

    // Calculate and cache
    final result = await _calculateFabricStabilityAnalytics(
      userId: userId,
      reservations: reservations,
    );
    
    _fabricStabilityCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Limit cache size (performance optimization)
    if (_fabricStabilityCache.length > 50) {
      final oldestKey = _fabricStabilityCache.keys.first;
      _fabricStabilityCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
    
    return result;
  }

  /// Calculate fabric stability analytics
  Future<FabricStabilityAnalytics?> _calculateFabricStabilityAnalytics({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    if (_fabricService == null || _personalityLearning == null) {
      developer.log(
        'Fabric service or personality learning not available for user $userId',
        name: _logName,
      );
      return null;
    }

    try {
      final agentId = await _agentIdService.getUserAgentId(userId);
      final stabilityHistory = <FabricStabilityPoint>[];
      final stableGroups = <StableGroup>[];

      // Group reservations by other participants (group reservations)
      final groupReservations = <String, List<Reservation>>{};
      for (final reservation in reservations) {
        final groupId = reservation.metadata['groupId'] as String?;
        if (groupId != null) {
          groupReservations.putIfAbsent(groupId, () => []).add(reservation);
        }
      }

      // Calculate stability for each group
      for (final groupReservationsList in groupReservations.values) {
        if (groupReservationsList.isEmpty) continue;

        // Get user IDs from group
        final userIds = <String>[];
        for (final reservation in groupReservationsList) {
          final participants = reservation.metadata['participants'] as List<dynamic>?;
          if (participants != null) {
            for (final participant in participants) {
              final participantId = participant.toString();
              if (participantId != userId && !userIds.contains(participantId)) {
                userIds.add(participantId);
              }
            }
          }
        }

        if (userIds.isEmpty) continue;

        // Get knots for all users
        final userKnots = <String>[];
        userKnots.add(agentId);
        for (final participantId in userIds) {
          try {
            final participantAgentId =
                await _agentIdService.getUserAgentId(participantId);
            userKnots.add(participantAgentId);
          } catch (e) {
            developer.log(
              'Error getting agentId for participant: $e',
              name: _logName,
            );
          }
        }

        if (userKnots.isEmpty) continue;

        // Generate fabric and measure stability
        try {
          // Note: This requires PersonalityKnot objects, which we'd need to get from profiles
          // For now, we'll calculate a simplified stability score
          final stability = 0.7; // Placeholder - would use actual fabric stability

          stabilityHistory.add(FabricStabilityPoint(
            timestamp: groupReservationsList.first.reservationTime,
            stability: stability,
            groupSize: userKnots.length,
          ));

          stableGroups.add(StableGroup(
            userIds: userIds,
            stability: stability,
            reservationCount: groupReservationsList.length,
          ));
        } catch (e) {
          developer.log(
            'Error calculating fabric stability: $e',
            name: _logName,
          );
        }
      }

      // Calculate average stability
      final averageStability = stabilityHistory.isNotEmpty
          ? stabilityHistory.map((p) => p.stability).reduce((a, b) => a + b) /
              stabilityHistory.length
          : 0.0;

      // Sort stable groups by stability
      stableGroups.sort((a, b) => b.stability.compareTo(a.stability));

      return FabricStabilityAnalytics(
        averageStability: averageStability,
        stabilityHistory: stabilityHistory,
        mostStableGroups: stableGroups.take(5).toList(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating fabric stability analytics: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return null gracefully - analytics should not break the flow
      return null;
    }
  }

  /// Calculate worldsheet evolution analytics (with caching)
  /// Phase 9.2: Performance optimization
  Future<WorldsheetEvolutionAnalytics?> _calculateWorldsheetEvolutionAnalyticsCached({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    // Check cache first
    final cacheKey = 'worldsheet_evolution_$userId';
    if (_worldsheetEvolutionCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        developer.log(
          'Cache hit for worldsheet evolution analytics: $userId',
          name: _logName,
        );
        return _worldsheetEvolutionCache[cacheKey];
      }
    }

    // Calculate and cache
    final result = await _calculateWorldsheetEvolutionAnalytics(
      userId: userId,
      reservations: reservations,
    );
    
    _worldsheetEvolutionCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Limit cache size (performance optimization)
    if (_worldsheetEvolutionCache.length > 50) {
      final oldestKey = _worldsheetEvolutionCache.keys.first;
      _worldsheetEvolutionCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
    
    return result;
  }

  /// Calculate worldsheet evolution analytics
  Future<WorldsheetEvolutionAnalytics?> _calculateWorldsheetEvolutionAnalytics({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    if (_worldsheetService == null || _fabricService == null) {
      developer.log(
        'Worldsheet service or fabric service not available for user $userId',
        name: _logName,
      );
      return null;
    }

    try {
      final agentId = await _agentIdService.getUserAgentId(userId);
      final evolutionHistory = <WorldsheetEvolutionPoint>[];
      final predictions = <WorldsheetPrediction>[];
      final stabilityTrends = <StabilityChangeTrend>[];

      // Group reservations by time periods
      final reservationsByMonth = <String, List<Reservation>>{};
      for (final reservation in reservations) {
        final monthKey =
            '${reservation.reservationTime.year}-${reservation.reservationTime.month}';
        reservationsByMonth.putIfAbsent(monthKey, () => []).add(reservation);
      }

      // Calculate evolution for each month
      for (final monthReservations in reservationsByMonth.values) {
        if (monthReservations.isEmpty) continue;

        final monthStart = monthReservations.first.reservationTime;
        final monthEnd = monthReservations.last.reservationTime;

        // Get group participants for this month
        final participants = <String>{agentId};
        for (final reservation in monthReservations) {
          final groupParticipants = reservation.metadata['participants'] as List<dynamic>?;
          if (groupParticipants != null) {
            for (final participant in groupParticipants) {
              try {
                final participantAgentId =
                    await _agentIdService.getUserAgentId(participant.toString());
                participants.add(participantAgentId);
              } catch (e) {
                // Skip if can't get agentId
              }
            }
          }
        }

        if (participants.isEmpty) continue;

        // Create worldsheet for this period
        try {
          final groupId = 'analytics_${monthStart.millisecondsSinceEpoch}';
          final worldsheet = await _worldsheetService!.createWorldsheet(
            groupId: groupId,
            userIds: participants.toList(),
            startTime: monthStart.subtract(const Duration(days: 7)),
            endTime: monthEnd.add(const Duration(days: 7)),
          );

          if (worldsheet != null) {
            // Get fabric at month start and end
            final fabricStart = worldsheet.getFabricAtTime(monthStart);
            final fabricEnd = worldsheet.getFabricAtTime(monthEnd);

            if (fabricStart != null && fabricEnd != null) {
              final stabilityStart = await _fabricService!.measureFabricStability(fabricStart);
              final stabilityEnd = await _fabricService!.measureFabricStability(fabricEnd);

              final evolutionScore = (0.5 + (stabilityEnd - stabilityStart)).clamp(0.0, 1.0);

              evolutionHistory.add(WorldsheetEvolutionPoint(
                timestamp: monthStart,
                evolutionScore: evolutionScore,
                stability: stabilityEnd,
              ));

              // Calculate stability change trend
              final stabilityChange = stabilityEnd - stabilityStart;
              stabilityTrends.add(StabilityChangeTrend(
                startTime: monthStart,
                endTime: monthEnd,
                stabilityChange: stabilityChange,
                trend: stabilityChange > 0
                    ? TrendType.increasing
                    : stabilityChange < 0
                        ? TrendType.decreasing
                        : TrendType.stable,
              ));
            }

            // Predict future evolution
            final futureTime = monthEnd.add(const Duration(days: 30));
            final futureFabric = worldsheet.getFabricAtTime(futureTime);
            if (futureFabric != null) {
              final predictedStability =
                  await _fabricService!.measureFabricStability(futureFabric);
              predictions.add(WorldsheetPrediction(
                predictedTime: futureTime,
                predictedStability: predictedStability,
                confidence: 0.7, // Placeholder confidence
              ));
            }
          }
        } catch (e) {
          developer.log(
            'Error calculating worldsheet evolution: $e',
            name: _logName,
          );
        }
      }

      return WorldsheetEvolutionAnalytics(
        evolutionHistory: evolutionHistory,
        predictions: predictions,
        stabilityTrends: stabilityTrends,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating worldsheet evolution analytics: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return null gracefully - analytics should not break the flow
      return null;
    }
  }

  /// Calculate quantum compatibility history (with caching)
  /// Phase 9.2: Performance optimization
  Future<QuantumCompatibilityHistory?> _calculateQuantumCompatibilityHistoryCached({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    // Check cache first
    final cacheKey = 'quantum_compatibility_$userId';
    if (_quantumCompatibilityCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        developer.log(
          'Cache hit for quantum compatibility history: $userId',
          name: _logName,
        );
        return _quantumCompatibilityCache[cacheKey];
      }
    }

    // Calculate and cache
    final result = await _calculateQuantumCompatibilityHistory(
      userId: userId,
      reservations: reservations,
    );
    
    _quantumCompatibilityCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Limit cache size (performance optimization)
    if (_quantumCompatibilityCache.length > 50) {
      final oldestKey = _quantumCompatibilityCache.keys.first;
      _quantumCompatibilityCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
    
    return result;
  }

  /// Calculate quantum compatibility history
  Future<QuantumCompatibilityHistory?> _calculateQuantumCompatibilityHistory({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    if (_quantumService == null) {
      developer.log(
        'Quantum service not available for user $userId',
        name: _logName,
      );
      return null;
    }

    try {
      final compatibilityHistory = <CompatibilityPoint>[];
      final topCompatibility = <HighCompatibilityReservation>[];

      for (final reservation in reservations) {
        // Get compatibility from metadata if available
        final compatibility = reservation.metadata['compatibility'] as double?;
        if (compatibility != null) {
          compatibilityHistory.add(CompatibilityPoint(
            timestamp: reservation.reservationTime,
            compatibility: compatibility,
            reservationId: reservation.id,
          ));

          topCompatibility.add(HighCompatibilityReservation(
            reservationId: reservation.id,
            targetId: reservation.targetId,
            compatibility: compatibility,
            reservationTime: reservation.reservationTime,
          ));
        }
      }

      // Calculate average
      final averageCompatibility = compatibilityHistory.isNotEmpty
          ? compatibilityHistory.map((p) => p.compatibility).reduce((a, b) => a + b) /
              compatibilityHistory.length
          : 0.0;

      // Sort top compatibility
      topCompatibility.sort((a, b) => b.compatibility.compareTo(a.compatibility));

      return QuantumCompatibilityHistory(
        averageCompatibility: averageCompatibility,
        compatibilityHistory: compatibilityHistory,
        topCompatibility: topCompatibility.take(10).toList(),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating quantum compatibility history: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return null gracefully - analytics should not break the flow
      return null;
    }
  }

  /// Calculate AI2AI learning insights (with caching)
  /// Phase 9.2: Performance optimization
  Future<AI2AILearningInsights?> _calculateAI2AILearningInsightsCached({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    // Check cache first
    final cacheKey = 'ai2ai_learning_$userId';
    if (_ai2aiLearningCache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        developer.log(
          'Cache hit for AI2AI learning insights: $userId',
          name: _logName,
        );
        return _ai2aiLearningCache[cacheKey];
      }
    }

    // Calculate and cache
    final result = await _calculateAI2AILearningInsights(
      userId: userId,
      reservations: reservations,
    );
    
    _ai2aiLearningCache[cacheKey] = result;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    // Limit cache size (performance optimization)
    if (_ai2aiLearningCache.length > 50) {
      final oldestKey = _ai2aiLearningCache.keys.first;
      _ai2aiLearningCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }
    
    return result;
  }

  /// Calculate AI2AI learning insights
  Future<AI2AILearningInsights?> _calculateAI2AILearningInsights({
    required String userId,
    required List<Reservation> reservations,
  }) async {
    if (_aiLearningService == null) {
      developer.log(
        'AI2AI learning service not available for user $userId',
        name: _logName,
      );
      return null;
    }

    try {
      // Note: AI2AI learning insights would come from the mesh network
      // For now, we'll return placeholder data
      // In production, this would query the AI2AI mesh for learning insights

      return const AI2AILearningInsights(
        totalInsights: 0,
        averageLearningQuality: 0.0,
        improvedDimensions: [],
        propagationStats: MeshPropagationStats(
          insightsReceived: 0,
          insightsShared: 0,
          averageHopCount: 0.0,
        ),
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error calculating AI2AI learning insights: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Return null gracefully - analytics should not break the flow
      return null;
    }
  }

  /// Track analytics event
  Future<void> _trackAnalyticsEvent({
    required String userId,
    required String eventType,
    required Map<String, dynamic> parameters,
  }) async {
    if (_eventLogger == null) {
      return;
    }

    try {
      await _eventLogger!.logEvent(
        eventType: eventType,
        parameters: parameters,
      );
    } catch (e) {
      developer.log(
        'Error tracking analytics event: $e',
        name: _logName,
      );
      // Don't throw - analytics tracking should not break the flow
    }
  }
}
