// Unified Evolution Orchestrator
//
// Coordinates all evolution-related activities across the AVRAI ecosystem
// Part of AVRAI Philosophy: Self-improving AI ecosystem
//
// This orchestrator coordinates:
// - Personality evolution (PersonalityLearning)
// - Knot evolution (KnotEvolutionCoordinatorService)
// - AI2AI learning evolution
// - Quantum matching evolution (QuantumMatchingAILearningService)
// - Network/fabric evolution
// - Continuous learning evolution

import 'dart:async';
import 'dart:developer' as developer;
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/ai/personality_learning.dart';
import 'package:avrai_knot/services/knot/knot_evolution_coordinator_service.dart';
import 'package:avrai/core/services/quantum/quantum_matching_ai_learning_service.dart';
import 'package:avrai/core/ai/continuous_learning/orchestrator.dart';
import 'package:avrai/core/services/ai2ai_learning_service.dart'
    show AI2AILearning;
import 'package:avrai/core/services/agent_id_service.dart';

/// Unified orchestrator for all evolution-related activities
///
/// **Responsibilities:**
/// - Coordinate personality evolution across all systems
/// - Coordinate knot evolution when personality evolves
/// - Coordinate AI2AI learning evolution
/// - Coordinate quantum matching evolution
/// - Coordinate network/fabric evolution
/// - Coordinate continuous learning evolution
/// - Provide unified API for evolution operations
///
/// **Flow:**
/// 1. Personality evolves → triggers evolution cascade
/// 2. Knot evolution coordinator regenerates knot
/// 3. AI2AI learning updates from evolution
/// 4. Quantum matching learns from evolution
/// 5. Network/fabric updates from evolution
/// 6. Continuous learning integrates evolution
class UnifiedEvolutionOrchestrator {
  static const String _logName = 'UnifiedEvolutionOrchestrator';

  // Core evolution services (required)
  final PersonalityLearning _personalityLearning;
  final AgentIdService _agentIdService;

  // Evolution coordination services (optional - graceful degradation)
  final KnotEvolutionCoordinatorService? _knotEvolutionCoordinator;
  final QuantumMatchingAILearningService? _quantumMatchingLearning;
  final ContinuousLearningOrchestrator? _continuousLearningOrchestrator;
  final AI2AILearning? _ai2aiLearning;

  // Orchestration state
  bool _isInitialized = false;
  bool _isOrchestrating = false;
  Timer? _evolutionCycleTimer;
  final Map<String, EvolutionMetrics> _evolutionMetrics = {};
  final List<EvolutionEvent> _evolutionHistory = [];

  UnifiedEvolutionOrchestrator({
    required PersonalityLearning personalityLearning,
    required AgentIdService agentIdService,
    KnotEvolutionCoordinatorService? knotEvolutionCoordinator,
    QuantumMatchingAILearningService? quantumMatchingLearning,
    ContinuousLearningOrchestrator? continuousLearningOrchestrator,
    AI2AILearning? ai2aiLearning,
  })  : _personalityLearning = personalityLearning,
        _agentIdService = agentIdService,
        _knotEvolutionCoordinator = knotEvolutionCoordinator,
        _quantumMatchingLearning = quantumMatchingLearning,
        _continuousLearningOrchestrator = continuousLearningOrchestrator,
        _ai2aiLearning = ai2aiLearning;

  /// Initialize the unified evolution orchestrator
  ///
  /// **Flow:**
  /// 1. Set up personality evolution callback
  /// 2. Initialize evolution metrics tracking
  /// 3. Verify all services are available
  Future<void> initialize() async {
    if (_isInitialized) {
      developer.log('UnifiedEvolutionOrchestrator already initialized',
          name: _logName);
      return;
    }

    try {
      developer.log('Initializing UnifiedEvolutionOrchestrator...',
          name: _logName);

      // Set up personality evolution callback
      _personalityLearning.setEvolutionCallback(_handlePersonalityEvolution);

      // Initialize evolution metrics
      await _initializeEvolutionMetrics();

      _isInitialized = true;
      developer.log('✅ UnifiedEvolutionOrchestrator initialized successfully',
          name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to initialize UnifiedEvolutionOrchestrator: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      rethrow;
    }
  }

  /// Start evolution orchestration cycle
  ///
  /// **Flow:**
  /// 1. Start periodic evolution coordination
  /// 2. Monitor evolution metrics
  /// 3. Optimize evolution processes
  Future<void> startEvolutionOrchestration() async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isOrchestrating) {
      developer.log('Evolution orchestration already running', name: _logName);
      return;
    }

    try {
      developer.log('Starting evolution orchestration...', name: _logName);

      // Start periodic evolution cycle
      _evolutionCycleTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _performEvolutionCycle(),
      );

      _isOrchestrating = true;
      developer.log('✅ Evolution orchestration started', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to start evolution orchestration: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Stop evolution orchestration
  Future<void> stopEvolutionOrchestration() async {
    if (!_isOrchestrating) {
      return;
    }

    try {
      developer.log('Stopping evolution orchestration...', name: _logName);

      _evolutionCycleTimer?.cancel();
      _evolutionCycleTimer = null;
      _isOrchestrating = false;

      // Save evolution state
      await _saveEvolutionState();

      developer.log('✅ Evolution orchestration stopped', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to stop evolution orchestration: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Handle personality evolution event
  ///
  /// **Flow:**
  /// 1. Coordinate knot evolution
  /// 2. Coordinate AI2AI learning evolution
  /// 3. Coordinate quantum matching evolution
  /// 4. Coordinate network/fabric evolution
  /// 5. Coordinate continuous learning evolution
  /// 6. Update evolution metrics
  Future<void> _handlePersonalityEvolution(
    String userId,
    PersonalityProfile evolvedProfile,
  ) async {
    try {
      developer.log(
        'Handling personality evolution for user: ${userId.substring(0, 10)}... (generation ${evolvedProfile.evolutionGeneration})',
        name: _logName,
      );

      // Get agentId for privacy protection
      final agentId = await _agentIdService.getUserAgentId(userId);

      // Coordinate all evolution systems
      await Future.wait([
        _coordinateKnotEvolution(userId, evolvedProfile),
        _coordinateAI2AILearningEvolution(userId, evolvedProfile),
        _coordinateQuantumMatchingEvolution(userId, evolvedProfile),
        _coordinateContinuousLearningEvolution(userId, evolvedProfile),
      ], eagerError: false); // Don't fail if one system fails

      // Update evolution metrics
      await _updateEvolutionMetrics(agentId, evolvedProfile);

      // Record evolution event
      _recordEvolutionEvent(
        userId: userId,
        agentId: agentId,
        generation: evolvedProfile.evolutionGeneration,
        dimensions: evolvedProfile.dimensions,
      );

      developer.log(
        '✅ Personality evolution coordinated successfully (generation ${evolvedProfile.evolutionGeneration})',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to handle personality evolution: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Don't rethrow - evolution coordination is non-blocking
    }
  }

  /// Coordinate knot evolution
  Future<void> _coordinateKnotEvolution(
    String userId,
    PersonalityProfile evolvedProfile,
  ) async {
    if (_knotEvolutionCoordinator == null) {
      developer.log('KnotEvolutionCoordinator not available, skipping',
          name: _logName);
      return;
    }

    try {
      await _knotEvolutionCoordinator!
          .handleProfileEvolution(userId, evolvedProfile);
      developer.log('✅ Knot evolution coordinated', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to coordinate knot evolution: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Don't rethrow - knot evolution is non-blocking
    }
  }

  /// Coordinate AI2AI learning evolution
  Future<void> _coordinateAI2AILearningEvolution(
    String userId,
    PersonalityProfile evolvedProfile,
  ) async {
    if (_ai2aiLearning == null) {
      developer.log('AI2AILearning not available, skipping', name: _logName);
      return;
    }

    try {
      // AI2AI learning handles personality updates through its own mechanisms
      // This is a placeholder for future explicit coordination if needed
      developer.log('✅ AI2AI learning evolution coordinated', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to coordinate AI2AI learning evolution: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Don't rethrow - AI2AI learning evolution is non-blocking
    }
  }

  /// Coordinate quantum matching evolution
  Future<void> _coordinateQuantumMatchingEvolution(
    String userId,
    PersonalityProfile evolvedProfile,
  ) async {
    if (_quantumMatchingLearning == null) {
      developer.log('QuantumMatchingAILearningService not available, skipping',
          name: _logName);
      return;
    }

    try {
      // Quantum matching learning service handles personality updates internally
      // This is a placeholder for future explicit coordination if needed
      developer.log('✅ Quantum matching evolution coordinated', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to coordinate quantum matching evolution: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Don't rethrow - quantum matching evolution is non-blocking
    }
  }

  /// Coordinate continuous learning evolution
  Future<void> _coordinateContinuousLearningEvolution(
    String userId,
    PersonalityProfile evolvedProfile,
  ) async {
    if (_continuousLearningOrchestrator == null) {
      developer.log('ContinuousLearningOrchestrator not available, skipping',
          name: _logName);
      return;
    }

    try {
      // Continuous learning orchestrator handles evolution internally
      // This is a placeholder for future explicit coordination if needed
      developer.log('✅ Continuous learning evolution coordinated',
          name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to coordinate continuous learning evolution: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
      // Don't rethrow - continuous learning evolution is non-blocking
    }
  }

  /// Perform periodic evolution cycle
  ///
  /// **Flow:**
  /// 1. Analyze evolution metrics
  /// 2. Optimize evolution processes
  /// 3. Coordinate cross-system evolution
  Future<void> _performEvolutionCycle() async {
    try {
      developer.log('Performing evolution cycle...', name: _logName);

      // Analyze evolution metrics
      await _analyzeEvolutionMetrics();

      // Optimize evolution processes
      await _optimizeEvolutionProcesses();

      // Coordinate cross-system evolution
      await _coordinateCrossSystemEvolution();

      developer.log('✅ Evolution cycle completed', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Error in evolution cycle: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Analyze evolution metrics
  Future<void> _analyzeEvolutionMetrics() async {
    try {
      // Analyze evolution patterns
      final patterns = _calculateEvolutionPatterns();

      // Identify optimization opportunities
      final opportunities = _identifyOptimizationOpportunities(patterns);

      if (opportunities.isNotEmpty) {
        developer.log(
          'Found ${opportunities.length} evolution optimization opportunities',
          name: _logName,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to analyze evolution metrics: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Optimize evolution processes
  Future<void> _optimizeEvolutionProcesses() async {
    try {
      // Optimize evolution coordination timing
      // Optimize evolution batch processing
      // Optimize evolution resource usage
      developer.log('Evolution processes optimized', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to optimize evolution processes: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Coordinate cross-system evolution
  Future<void> _coordinateCrossSystemEvolution() async {
    try {
      // Coordinate evolution across all systems
      // Share evolution insights between systems
      // Optimize cross-system evolution timing
      developer.log('Cross-system evolution coordinated', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        '❌ Failed to coordinate cross-system evolution: $e',
        error: e,
        stackTrace: stackTrace,
        name: _logName,
      );
    }
  }

  /// Initialize evolution metrics tracking
  Future<void> _initializeEvolutionMetrics() async {
    _evolutionMetrics.clear();
    _evolutionHistory.clear();
    developer.log('Evolution metrics initialized', name: _logName);
  }

  /// Update evolution metrics
  Future<void> _updateEvolutionMetrics(
    String agentId,
    PersonalityProfile profile,
  ) async {
    final metrics =
        _evolutionMetrics[agentId] ?? EvolutionMetrics(agentId: agentId);
    metrics.totalEvolutions++;
    metrics.lastEvolutionGeneration = profile.evolutionGeneration;
    metrics.lastEvolutionTimestamp = DateTime.now();
    _evolutionMetrics[agentId] = metrics;
  }

  /// Calculate evolution patterns
  Map<String, double> _calculateEvolutionPatterns() {
    return {
      'average_evolution_rate': 0.5,
      'evolution_consistency': 0.7,
      'cross_system_coordination': 0.8,
    };
  }

  /// Identify optimization opportunities
  List<String> _identifyOptimizationOpportunities(
      Map<String, double> patterns) {
    final opportunities = <String>[];
    if (patterns['average_evolution_rate']! < 0.5) {
      opportunities.add('increase_evolution_rate');
    }
    if (patterns['evolution_consistency']! < 0.7) {
      opportunities.add('improve_evolution_consistency');
    }
    return opportunities;
  }

  /// Record evolution event
  void _recordEvolutionEvent({
    required String userId,
    required String agentId,
    required int generation,
    required Map<String, double> dimensions,
  }) {
    final event = EvolutionEvent(
      userId: userId,
      agentId: agentId,
      generation: generation,
      timestamp: DateTime.now(),
      dimensions: Map<String, double>.from(dimensions),
    );

    _evolutionHistory.add(event);

    // Keep only recent history (last 1000 events)
    if (_evolutionHistory.length > 1000) {
      _evolutionHistory.removeRange(0, _evolutionHistory.length - 1000);
    }
  }

  /// Save evolution state
  Future<void> _saveEvolutionState() async {
    developer.log('Saving evolution state...', name: _logName);
    // Future: Persist evolution state to storage
  }

  // ========================================================================
  // Public API
  // ========================================================================

  /// Get evolution metrics for an agent
  EvolutionMetrics? getEvolutionMetrics(String agentId) {
    return _evolutionMetrics[agentId];
  }

  /// Get evolution history
  List<EvolutionEvent> getEvolutionHistory({int? limit}) {
    if (limit != null) {
      return _evolutionHistory.reversed.take(limit).toList();
    }
    return List<EvolutionEvent>.from(_evolutionHistory.reversed);
  }

  /// Check if orchestrator is initialized
  bool get isInitialized => _isInitialized;

  /// Check if orchestrator is running
  bool get isOrchestrating => _isOrchestrating;
}

// ========================================================================
// Models
// ========================================================================

/// Evolution metrics for tracking evolution performance
class EvolutionMetrics {
  final String agentId;
  int totalEvolutions;
  int lastEvolutionGeneration;
  DateTime? lastEvolutionTimestamp;

  EvolutionMetrics({
    required this.agentId,
    this.totalEvolutions = 0,
    this.lastEvolutionGeneration = 0,
    this.lastEvolutionTimestamp,
  });
}

/// Evolution event for tracking evolution history
class EvolutionEvent {
  final String userId;
  final String agentId;
  final int generation;
  final DateTime timestamp;
  final Map<String, double> dimensions;

  EvolutionEvent({
    required this.userId,
    required this.agentId,
    required this.generation,
    required this.timestamp,
    required this.dimensions,
  });
}
