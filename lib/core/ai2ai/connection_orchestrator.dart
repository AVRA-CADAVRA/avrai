import 'dart:async';
import 'package:spots/core/constants/vibe_constants.dart';
import 'package:spots/core/models/user_vibe.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/core/ai/vibe_analysis_engine.dart';
import 'package:spots/core/ai/personality_learning.dart';
import 'package:spots/core/ai/privacy_protection.dart';
import 'package:spots/core/services/ai2ai_realtime_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spots/core/ai2ai/aipersonality_node.dart';
import 'package:spots/core/ai2ai/orchestrator_components.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/network/device_discovery.dart';
import 'package:spots/core/network/ai2ai_protocol.dart';
import 'package:spots/core/network/personality_advertising_service.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/anonymous_user.dart';
import 'package:spots/core/services/user_anonymization_service.dart';
import 'package:spots_network/spots_network.dart';

/// OUR_GUTS.md: "AI2AI vibe-based connections that enable cross-personality learning while preserving privacy"
/// Comprehensive connection orchestrator that manages AI2AI personality matching and learning
/// Enhanced with Supabase Realtime for live AI2AI communication
class VibeConnectionOrchestrator {
  static const String _logName = 'VibeConnectionOrchestrator';

  final UserVibeAnalyzer _vibeAnalyzer;
  final Connectivity _connectivity;
  AI2AIRealtimeService? _realtimeService;
  final DiscoveryManager _discoveryManager;
  final ConnectionManager _connectionManager;
  final RealtimeCoordinator? _realtimeCoordinator;
  final DeviceDiscoveryService? _deviceDiscovery;
  final AI2AIProtocol? _protocol;
  final PersonalityAdvertisingService? _advertisingService;
  final UserAnonymizationService? _anonymizationService;
  final AppLogger _logger =
      const AppLogger(defaultTag: 'AI2AI', minimumLevel: LogLevel.debug);

  // Connection state management
  final Map<String, ConnectionMetrics> _activeConnections = {};
  final Map<String, DateTime> _connectionCooldowns = {};
  final List<PendingConnection> _pendingConnections = [];

  // Connection discovery and matching
  final Map<String, UserVibe> _nearbyVibes = {};
  final Map<String, AIPersonalityNode> _discoveredNodes = {};

  // Connection orchestration state
  bool _isDiscovering = false;
  bool _isConnecting = false;
  bool _isInitialized = false;
  Timer? _discoveryTimer;
  Timer? _connectionMaintenanceTimer;

  // Realtime event streams (managed by RealtimeCoordinator)
  // Note: Subscriptions are created and managed by _realtimeCoordinator.setup()
  // These fields are reserved for future direct stream access if needed
  // ignore: unused_field
  StreamSubscription<RealtimeMessage>? _personalityDiscoverySubscription;
  // ignore: unused_field
  StreamSubscription<RealtimeMessage>? _vibeLearningSubscription;
  // ignore: unused_field
  StreamSubscription<RealtimeMessage>? _anonymousCommunicationSubscription;

  VibeConnectionOrchestrator({
    required UserVibeAnalyzer vibeAnalyzer,
    required Connectivity connectivity,
    AI2AIRealtimeService? realtimeService,
    DeviceDiscoveryService? deviceDiscovery,
    AI2AIProtocol? protocol,
    PersonalityAdvertisingService? advertisingService,
    UserAnonymizationService? anonymizationService,
    PersonalityLearning? personalityLearning, // NEW: For offline AI2AI learning
  })  : _vibeAnalyzer = vibeAnalyzer,
        _connectivity = connectivity,
        _realtimeService = realtimeService,
        _deviceDiscovery = deviceDiscovery,
        _protocol = protocol,
        _advertisingService = advertisingService,
        _anonymizationService = anonymizationService,
        _discoveryManager = DiscoveryManager(
            connectivity: connectivity, vibeAnalyzer: vibeAnalyzer),
        _connectionManager = ConnectionManager(
          vibeAnalyzer: vibeAnalyzer,
          personalityLearning:
              personalityLearning, // NEW: Pass to ConnectionManager
          ai2aiProtocol: protocol, // NEW: Pass to ConnectionManager
        ),
        _realtimeCoordinator = realtimeService != null
            ? RealtimeCoordinator(realtimeService)
            : null;

  /// Inject or update the realtime service after construction to avoid DI cycles
  void setRealtimeService(AI2AIRealtimeService service) {
    _realtimeService = service;
  }

  /// Update personality advertising when personality evolves
  /// Call this after personality profile is updated
  /// This method is automatically called via PersonalityLearning callback
  Future<void> updatePersonalityAdvertising(
    String userId,
    PersonalityProfile updatedPersonality,
  ) async {
    if (_advertisingService == null) {
      return;
    }

    try {
      _logger.info(
          'Updating personality advertising after evolution (generation ${updatedPersonality.evolutionGeneration})',
          tag: _logName);

      final success = await _advertisingService!.updatePersonalityData(
        userId,
        updatedPersonality,
        _vibeAnalyzer,
      );

      if (success) {
        _logger.info('Personality advertising updated successfully',
            tag: _logName);
      } else {
        _logger.warn('Failed to update personality advertising', tag: _logName);
      }
    } catch (e) {
      _logger.error('Error updating personality advertising',
          error: e, tag: _logName);
    }
  }

  /// Set up automatic personality advertising updates
  /// Call this to enable automatic updates when personality evolves
  void setupAutomaticAdvertisingUpdates() {
    // This will be called from injection container after PersonalityLearning is created
    // The callback will be set up there to avoid circular dependencies
  }

  /// Initialize the AI2AI connection orchestration system
  Future<void> initializeOrchestration(
      String userId, PersonalityProfile personality) async {
    if (_isInitialized) {
      _logger.debug(
          'Orchestration already initialized; skipping reinitialization',
          tag: _logName);
      return;
    }
    try {
      _logger.info('Initializing orchestration for user: $userId',
          tag: _logName);

      // Initialize realtime service if available
      if (_realtimeService != null) {
        final realtimeInitialized = await _realtimeService!.initialize();
        if (realtimeInitialized) {
          _logger.info('Realtime Service initialized', tag: _logName);
          await _setupRealtimeListeners();
        } else {
          _logger.warn('Realtime Service failed to initialize', tag: _logName);
        }
      }

      // Start personality advertising (make this device discoverable)
      if (_advertisingService != null) {
        final advertisingStarted = await _advertisingService!.startAdvertising(
          userId,
          personality,
          _vibeAnalyzer,
        );
        if (advertisingStarted) {
          _logger.info('Personality advertising started', tag: _logName);
        } else {
          _logger.warn('Personality advertising failed to start',
              tag: _logName);
        }
      }

      // Start device discovery (find other devices)
      if (_deviceDiscovery != null) {
        await _deviceDiscovery!.startDiscovery();
        _logger.info('Device discovery started', tag: _logName);
      }

      // Start AI2AI discovery process
      await _startAI2AIDiscovery(userId, personality);

      // Begin connection maintenance
      await _startConnectionMaintenance();

      _isInitialized = true;
      _logger.info('Orchestration initialized successfully', tag: _logName);
    } catch (e) {
      _logger.error('Error initializing AI2AI orchestration',
          error: e, tag: _logName);
      throw AI2AIConnectionException('Failed to initialize orchestration: $e');
    }
  }

  /// Discover nearby AI personalities for potential connections
  Future<List<AIPersonalityNode>> discoverNearbyAIPersonalities(
      String userId, PersonalityProfile personality,
      {bool throwOnError = false}) async {
    if (_isDiscovering) {
      _logger.debug('Discovery already in progress, returning cached results',
          tag: _logName);
      return _discoveredNodes.values.toList();
    }

    // Check connectivity before discovery
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      if (!_isConnected(connectivityResults)) {
        // #region agent log
        _logger.warn('No connectivity available, skipping discovery',
            tag: _logName);
        // #endregion
        return [];
      }
    } catch (e) {
      // #region agent log
      _logger.warn('Error checking connectivity: $e, proceeding with discovery',
          tag: _logName);
      // #endregion
    }

    _isDiscovering = true;

    try {
      // #region agent log
      _logger.info('Discovering nearby AI personalities', tag: _logName);
      // #endregion

      final nodes = await _discoveryManager.discover(
          userId, personality, _performAI2AIDiscovery);

      // DiscoveryManager already handles compatibility analysis and prioritization
      // Additional filtering: ensure all nodes are connection-worthy
      if (nodes.isNotEmpty) {
        final localVibe =
            await _vibeAnalyzer.compileUserVibe(userId, personality);
        final compatibilityResults =
            await _analyzeNodeCompatibility(localVibe, nodes);

        // Filter to only connection-worthy nodes (DiscoveryManager already prioritized)
        final worthyNodes = nodes.where((node) {
          final compatibility = compatibilityResults[node.nodeId];
          return compatibility != null && _isConnectionWorthy(compatibility);
        }).toList();

        // #region agent log
        _logger.info(
            'Discovered ${nodes.length} nodes, ${worthyNodes.length} connection-worthy after filtering',
            tag: _logName);
        // #endregion

        _updateDiscoveredNodes(worthyNodes);
        return worthyNodes;
      }

      _updateDiscoveredNodes(nodes);
      // #region agent log
      _logger.info('Discovered ${nodes.length} compatible AI personalities',
          tag: _logName);
      // #endregion
      return nodes;
    } catch (e) {
      // #region agent log
      _logger.error('Error discovering AI personalities',
          error: e, tag: _logName);
      // #endregion
      if (throwOnError) {
        throw AI2AIConnectionException('Discovery failed: $e');
      }
      return [];
    } finally {
      _isDiscovering = false;
    }
  }

  /// Establish AI2AI connection based on vibe compatibility
  Future<ConnectionMetrics?> establishAI2AIConnection(
    String localUserId,
    PersonalityProfile localPersonality,
    AIPersonalityNode remoteNode,
  ) async {
    if (_isConnecting) {
      _logger.debug('Connection establishment already in progress',
          tag: _logName);
      return null;
    }

    // Check connection cooldown
    if (_isInCooldown(remoteNode.nodeId)) {
      _logger.debug('Connection to ${remoteNode.nodeId} is in cooldown period',
          tag: _logName);
      return null;
    }

    // Check active connection limits
    if (_activeConnections.length >= VibeConstants.maxSimultaneousConnections) {
      _logger.warn('Maximum simultaneous connections reached', tag: _logName);
      return null;
    }

    // Verify connection is worthy before attempting
    try {
      final localVibe =
          await _vibeAnalyzer.compileUserVibe(localUserId, localPersonality);
      final compatibility = await _vibeAnalyzer.analyzeVibeCompatibility(
        localVibe,
        remoteNode.vibe,
      );

      if (!_isConnectionWorthy(compatibility)) {
        // #region agent log
        _logger.debug(
            'Connection to ${remoteNode.nodeId} not worthy (compatibility: ${(compatibility.basicCompatibility * 100).round()}%, pleasure: ${(compatibility.aiPleasurePotential * 100).round()}%)',
            tag: _logName);
        // #endregion
        _setCooldown(remoteNode.nodeId);
        return null;
      }
    } catch (e) {
      // #region agent log
      _logger.warn(
          'Error checking connection worthiness: $e, proceeding anyway',
          tag: _logName);
      // #endregion
    }

    _isConnecting = true;

    try {
      // #region agent log
      _logger.info('Establishing connection with node: ${remoteNode.nodeId}',
          tag: _logName);
      // #endregion

      final establishedConnection = await _connectionManager.establish(
        localUserId,
        localPersonality,
        remoteNode,
        (localVibe, remote, comp, metrics) =>
            _performConnectionEstablishment(localVibe, remote, comp, metrics),
      );

      if (establishedConnection != null) {
        // Store active connection
        _activeConnections[establishedConnection.connectionId] =
            establishedConnection;

        // Schedule connection management
        _scheduleConnectionManagement(establishedConnection);

        // #region agent log
        _logger.info(
            'Connection established (ID: ${establishedConnection.connectionId})',
            tag: _logName);
        // #endregion
        return establishedConnection;
      } else {
        _logger.warn('Failed to establish connection', tag: _logName);
        _setCooldown(remoteNode.nodeId);
        return null;
      }
    } catch (e) {
      // #region agent log
      _logger.error('Error establishing connection', error: e, tag: _logName);
      // #endregion
      _setCooldown(remoteNode.nodeId);
      return null;
    } finally {
      _isConnecting = false;
    }
  }

  /// Manage active AI2AI connections for learning and quality
  Future<void> manageActiveConnections() async {
    if (_activeConnections.isEmpty) return;

    _logger.debug('Managing ${_activeConnections.length} active connections',
        tag: _logName);

    final completedConnections = <String>[];

    for (final connection in _activeConnections.values) {
      try {
        // Check if connection should continue
        if (!connection.shouldContinue || connection.hasReachedMaxDuration) {
          // Complete the connection
          final completedConnection = await _completeConnection(connection);
          if (completedConnection != null) {
            completedConnections.add(completedConnection.connectionId);
          }
          continue;
        }

        // Update connection with new learning interactions
        await _updateConnectionLearning(connection);

        // Monitor connection health
        await _monitorConnectionHealth(connection);
      } catch (e) {
        _logger.error('Error managing connection ${connection.connectionId}',
            error: e, tag: _logName);
        completedConnections.add(connection.connectionId);
      }
    }

    // Remove completed connections
    for (final connectionId in completedConnections) {
      _activeConnections.remove(connectionId);
    }

    _logger.debug(
        'Connection management completed. Active: ${_activeConnections.length}',
        tag: _logName);
  }

  /// Get count of active connections
  int getActiveConnectionCount() {
    return _activeConnections.length;
  }

  /// Calculate AI pleasure score for connection quality
  Future<double> calculateAIPleasureScore(ConnectionMetrics connection) async {
    try {
      _logger.debug(
          'Calculating AI pleasure score for ${connection.connectionId}',
          tag: _logName);

      // Base pleasure from compatibility
      var pleasureScore = connection.currentCompatibility * 0.4;

      // Add pleasure from learning effectiveness
      pleasureScore += connection.learningEffectiveness * 0.3;

      // Add pleasure from successful interactions
      final successfulExchanges =
          connection.learningOutcomes['successful_exchanges'] as int? ?? 0;
      final totalExchanges = connection.interactionHistory.length;
      final successRate =
          totalExchanges > 0 ? successfulExchanges / totalExchanges : 0.0;
      pleasureScore += successRate * 0.2;

      // Add pleasure from dimension evolution
      final dimensionEvolutionCount = connection.dimensionEvolution.keys.length;
      final evolutionBonus =
          (dimensionEvolutionCount / VibeConstants.coreDimensions.length) * 0.1;
      pleasureScore += evolutionBonus;

      final finalScore = pleasureScore.clamp(0.0, 1.0);

      _logger.debug('AI pleasure score: ${(finalScore * 100).round()}%',
          tag: _logName);
      return finalScore;
    } catch (e) {
      _logger.error('Error calculating AI pleasure score',
          error: e, tag: _logName);
      return 0.5; // Neutral pleasure on error
    }
  }

  /// Get active connection summaries for monitoring
  List<ConnectionSummary> getActiveConnectionSummaries() {
    return _activeConnections.values.map((connection) {
      return ConnectionSummary(
        connectionId: connection.connectionId,
        duration: connection.connectionDuration,
        compatibility: connection.currentCompatibility,
        learningEffectiveness: connection.learningEffectiveness,
        aiPleasureScore: connection.aiPleasureScore,
        qualityRating: connection.qualityRating,
        status: connection.status,
        interactionCount: connection.interactionHistory.length,
        dimensionsEvolved: connection.dimensionEvolution.keys.length,
      );
    }).toList();
  }

  /// Get active connections for UI display
  /// Returns list of ConnectionMetrics for active connections
  List<ConnectionMetrics> getActiveConnections() {
    return _activeConnections.values.toList();
  }

  /// Cleanup and shutdown orchestration
  Future<void> shutdown() async {
    _logger.info('Shutting down orchestration', tag: _logName);
    _isInitialized = false;

    // Cancel timers
    _discoveryTimer?.cancel();
    _connectionMaintenanceTimer?.cancel();

    // Complete all active connections
    final activeConnectionIds = _activeConnections.keys.toList();
    for (final connectionId in activeConnectionIds) {
      final connection = _activeConnections[connectionId];
      if (connection != null) {
        await _completeConnection(connection, reason: 'system_shutdown');
      }
    }

    // Clear all state
    _activeConnections.clear();
    _connectionCooldowns.clear();
    _pendingConnections.clear();
    _nearbyVibes.clear();
    _discoveredNodes.clear();

    _logger.info('Shutdown completed', tag: _logName);
  }

  // Private helper methods
  Future<void> _startAI2AIDiscovery(
      String userId, PersonalityProfile personality) async {
    _logger.info('Starting AI2AI discovery process', tag: _logName);

    // Start periodic discovery
    _discoveryTimer = Timer.periodic(Duration(minutes: 2), (timer) async {
      try {
        await discoverNearbyAIPersonalities(userId, personality);
      } catch (e) {
        _logger.error('Error in periodic discovery', error: e, tag: _logName);
      }
    });

    // Perform initial discovery
    await discoverNearbyAIPersonalities(userId, personality,
        throwOnError: true);
  }

  Future<void> _startConnectionMaintenance() async {
    _logger.info('Starting connection maintenance process', tag: _logName);

    _connectionMaintenanceTimer =
        Timer.periodic(Duration(seconds: 30), (timer) async {
      try {
        await manageActiveConnections();
      } catch (e) {
        _logger.error('Error in connection maintenance',
            error: e, tag: _logName);
      }
    });
  }

  /// Check if device has active connectivity
  bool _isConnected(List<ConnectivityResult> result) {
    return result
        .any((connectivity) => connectivity != ConnectivityResult.none);
  }

  Future<List<AIPersonalityNode>> _performAI2AIDiscovery(
      AnonymizedVibeData localVibe) async {
    // Phase 6: Use physical layer device discovery if available
    if (_deviceDiscovery != null) {
      try {
        _logger.info('Using physical layer device discovery', tag: _logName);

        // Get discovered devices from physical layer
        final devices = _deviceDiscovery!.getDiscoveredDevices();

        // Convert discovered devices to AI personality nodes
        final nodes = <AIPersonalityNode>[];
        for (final device in devices) {
          // Extract personality data from device
          final personalityData =
              await _deviceDiscovery!.extractPersonalityData(device);
          if (personalityData == null) continue;

          // Create vibe from anonymized data
          final vibe = _createVibeFromAnonymizedData(personalityData);

          // Calculate trust score based on proximity and signal strength
          final proximityScore = _deviceDiscovery!.calculateProximity(device);
          final trustScore =
              proximityScore * 0.7 + 0.3; // Base trust + proximity

          final node = AIPersonalityNode(
            nodeId: device.deviceId,
            vibe: vibe,
            lastSeen: device.discoveredAt,
            trustScore: trustScore,
            learningHistory: {},
          );

          nodes.add(node);
        }

        if (nodes.isNotEmpty) {
          _logger.info(
              'Discovered ${nodes.length} AI personalities via physical layer',
              tag: _logName);
          return nodes;
        }
      } catch (e) {
        _logger.error('Error in physical layer discovery: $e', tag: _logName);
        // Fall through to realtime discovery
      }
    }

    // Fallback to realtime discovery (Supabase Realtime)
    // This is the existing implementation
    if (_realtimeService != null) {
      try {
        _logger.info('Using realtime discovery', tag: _logName);
        // Realtime discovery would happen here
        // For now, return empty list if physical layer fails
        return [];
      } catch (e) {
        _logger.error('Error in realtime discovery: $e', tag: _logName);
      }
    }

    // Final fallback: return empty list
    _logger.warn('No discovery method available, returning empty list',
        tag: _logName);
    return [];
  }

  /// Create UserVibe from AnonymizedVibeData
  UserVibe _createVibeFromAnonymizedData(AnonymizedVibeData anonymizedData) {
    // Extract metrics from anonymized data
    final metrics = anonymizedData.anonymizedMetrics;

    // Create UserVibe using anonymized dimensions and metrics
    return UserVibe(
      hashedSignature: anonymizedData.vibeSignature,
      anonymizedDimensions: anonymizedData.noisyDimensions,
      overallEnergy: metrics.energy,
      socialPreference: metrics.social,
      explorationTendency: metrics.exploration,
      createdAt: anonymizedData.createdAt,
      expiresAt: anonymizedData.expiresAt,
      privacyLevel: anonymizedData.anonymizationQuality,
      temporalContext: anonymizedData.temporalContextHash,
    );
  }

  void _updateDiscoveredNodes(List<AIPersonalityNode> nodes) {
    for (final node in nodes) {
      _discoveredNodes[node.nodeId] = node;
      _nearbyVibes[node.nodeId] = node.vibe;
    }

    // Clean up old discovered nodes (older than 10 minutes)
    final cutoff = DateTime.now().subtract(Duration(minutes: 10));
    final expiredNodes = _discoveredNodes.entries
        .where((entry) => entry.value.lastSeen.isBefore(cutoff))
        .map((entry) => entry.key)
        .toList();

    for (final nodeId in expiredNodes) {
      _discoveredNodes.remove(nodeId);
      _nearbyVibes.remove(nodeId);
    }
  }

  /// Analyze compatibility for all discovered nodes
  Future<Map<String, VibeCompatibilityResult>> _analyzeNodeCompatibility(
    UserVibe localVibe,
    List<AIPersonalityNode> nodes,
  ) async {
    final compatibilityResults = <String, VibeCompatibilityResult>{};

    for (final node in nodes) {
      final compatibility = await _vibeAnalyzer.analyzeVibeCompatibility(
        localVibe,
        node.vibe,
      );
      compatibilityResults[node.nodeId] = compatibility;
    }

    // #region agent log
    _logger.debug('Analyzed compatibility for ${nodes.length} nodes',
        tag: _logName);
    // #endregion

    return compatibilityResults;
  }

  /// Prioritize discovered nodes based on compatibility and trust
  /// Note: DiscoveryManager already handles prioritization, this is reserved for future use
  // ignore: unused_element
  Future<List<AIPersonalityNode>> _prioritizeConnections(
    List<AIPersonalityNode> nodes,
    Map<String, VibeCompatibilityResult> compatibilityResults,
  ) async {
    // Sort nodes by connection priority
    nodes.sort((a, b) {
      final aResult = compatibilityResults[a.nodeId];
      final bResult = compatibilityResults[b.nodeId];

      if (aResult == null || bResult == null) return 0;

      final aPriority = _calculateConnectionPriority(aResult, a.trustScore);
      final bPriority = _calculateConnectionPriority(bResult, b.trustScore);

      return bPriority.compareTo(aPriority); // Descending order
    });

    final prioritized =
        nodes.take(5).toList(); // Return top 5 prioritized nodes

    // #region agent log
    _logger.debug(
        'Prioritized ${nodes.length} nodes to top ${prioritized.length} connections',
        tag: _logName);
    // #endregion

    return prioritized;
  }

  double _calculateConnectionPriority(
      VibeCompatibilityResult compatibility, double trustScore) {
    return (compatibility.basicCompatibility * 0.4) +
        (compatibility.aiPleasurePotential * 0.3) +
        (compatibility.learningOpportunities.length / 8.0 * 0.2) +
        (trustScore * 0.1);
  }

  bool _isInCooldown(String nodeId) {
    final cooldownEnd = _connectionCooldowns[nodeId];
    if (cooldownEnd == null) return false;

    return DateTime.now().isBefore(cooldownEnd);
  }

  void _setCooldown(String nodeId) {
    _connectionCooldowns[nodeId] = DateTime.now()
        .add(Duration(seconds: VibeConstants.connectionCooldownSeconds));
  }

  /// Determine if a connection is worthy based on compatibility thresholds
  bool _isConnectionWorthy(VibeCompatibilityResult compatibility) {
    final isWorthy = compatibility.basicCompatibility >=
            VibeConstants.minimumCompatibilityThreshold &&
        compatibility.aiPleasurePotential >= VibeConstants.minAIPleasureScore &&
        compatibility.learningOpportunities.isNotEmpty;

    // #region agent log
    if (!isWorthy) {
      _logger.debug(
          'Connection not worthy: compat=${(compatibility.basicCompatibility * 100).round()}% (min=${(VibeConstants.minimumCompatibilityThreshold * 100).round()}%), pleasure=${(compatibility.aiPleasurePotential * 100).round()}% (min=${(VibeConstants.minAIPleasureScore * 100).round()}%), opportunities=${compatibility.learningOpportunities.length}',
          tag: _logName);
    }
    // #endregion

    return isWorthy;
  }

  Future<ConnectionMetrics?> _performConnectionEstablishment(
    UserVibe localVibe,
    AIPersonalityNode remoteNode,
    VibeCompatibilityResult compatibility,
    ConnectionMetrics initialMetrics,
  ) async {
    try {
      // Use protocol to encode initial connection message if available
      if (_protocol != null) {
        try {
          // Encode connection establishment message via protocol
          final connectionMessage = _protocol!.encodeMessage(
            type: MessageType.connectionRequest,
            payload: {
              'local_vibe_archetype': localVibe.getVibeArchetype(),
              'remote_vibe_archetype': remoteNode.vibe.getVibeArchetype(),
              'initial_compatibility': compatibility.basicCompatibility,
              'connection_id': initialMetrics.connectionId,
            },
            senderNodeId: initialMetrics.localAISignature,
            recipientNodeId: remoteNode.nodeId,
          );
          // #region agent log
          _logger.debug(
              'Encoded connection message via protocol: type=${connectionMessage.type.name}, sender=${connectionMessage.senderId}',
              tag: _logName);
          // #endregion
        } catch (e) {
          // #region agent log
          _logger.warn(
              'Error encoding protocol message: $e, continuing without protocol',
              tag: _logName);
          // #endregion
        }
      }

      // Simulate connection establishment process
      await Future.delayed(Duration(milliseconds: 200));

      // Create initial interaction event
      final initialInteraction = InteractionEvent.success(
        type: InteractionType.vibeExchange,
        data: {
          'local_vibe_archetype': localVibe.getVibeArchetype(),
          'remote_vibe_archetype': remoteNode.vibe.getVibeArchetype(),
          'initial_compatibility': compatibility.basicCompatibility,
        },
      );

      // Update connection with initial interaction
      return initialMetrics.updateDuringInteraction(
        newInteraction: initialInteraction,
        additionalOutcomes: {
          'successful_exchanges': 1,
        },
      );
    } catch (e) {
      // #region agent log
      _logger.error('Error in connection establishment',
          error: e, tag: _logName);
      // #endregion
      return null;
    }
  }

  void _scheduleConnectionManagement(ConnectionMetrics connection) {
    // Connection-specific management would be handled by the main maintenance timer
    _logger.debug(
        'Scheduled management for connection: ${connection.connectionId}',
        tag: _logName);
  }

  Future<ConnectionMetrics?> _completeConnection(ConnectionMetrics connection,
      {String? reason}) async {
    try {
      _logger.info('Completing AI2AI connection: ${connection.connectionId}',
          tag: _logName);

      final completedConnection = connection.complete(
        finalStatus: ConnectionStatus.completed,
        completionReason: reason ?? 'natural_completion',
      );

      // Log connection summary
      final summary = completedConnection.getSummary();
      _logger.info('Connection completed: ${summary}', tag: _logName);

      return completedConnection;
    } catch (e) {
      _logger.error('Error completing connection', error: e, tag: _logName);
      return null;
    }
  }

  Future<void> _updateConnectionLearning(ConnectionMetrics connection) async {
    // Simulate learning interactions
    if (connection.interactionHistory.length < 10) {
      final learningInteraction = InteractionEvent.success(
        type: InteractionType.learningInsight,
        data: {
          'insight_type': 'dimension_evolution',
          'learning_quality': 0.8,
        },
      );

      _activeConnections[connection.connectionId] =
          connection.updateDuringInteraction(
        newInteraction: learningInteraction,
        learningEffectiveness: 0.7,
        additionalOutcomes: {
          'successful_exchanges': 1,
          'insights_gained': 1,
        },
      );
    }
  }

  Future<void> _monitorConnectionHealth(ConnectionMetrics connection) async {
    // Monitor connection health and update AI pleasure score
    final currentPleasure = await calculateAIPleasureScore(connection);

    _activeConnections[connection.connectionId] =
        connection.updateDuringInteraction(
      aiPleasureScore: currentPleasure,
    );
  }

  /// Get current user vibe for AI2AI matching (stub; can be wired to cache)
  UserVibe? getCurrentVibe() {
    return null;
  }

  /// Convert UnifiedUser to AnonymousUser for AI2AI transmission
  ///
  /// **CRITICAL:** This method ensures no personal data is transmitted in AI2AI network.
  /// All user data must be converted to AnonymousUser before transmission.
  ///
  /// **Throws:**
  /// - Exception if anonymizationService is not available
  /// - Exception if conversion fails
  Future<AnonymousUser> anonymizeUserForTransmission(
    UnifiedUser user,
    String agentId,
    PersonalityProfile? personalityProfile, {
    bool isAdmin = false,
  }) async {
    if (_anonymizationService == null) {
      throw Exception(
          'UserAnonymizationService not available. Cannot anonymize user for transmission.');
    }

    _logger.info(
        'Anonymizing user for AI2AI transmission: ${user.id} -> $agentId',
        tag: _logName);

    try {
      final anonymousUser = await _anonymizationService!.anonymizeUser(
        user,
        agentId,
        personalityProfile,
        isAdmin: isAdmin,
      );

      _logger.info('User anonymized successfully for transmission',
          tag: _logName);
      return anonymousUser;
    } catch (e) {
      _logger.error('Failed to anonymize user for transmission',
          error: e, tag: _logName);
      rethrow;
    }
  }

  /// Validate that no UnifiedUser is being sent directly in AI2AI network
  ///
  /// This is a safety check to prevent accidental personal data leaks.
  /// All user data must be converted to AnonymousUser before transmission.
  void validateNoUnifiedUserInPayload(Map<String, dynamic> payload) {
    // Check for common UnifiedUser fields that should never appear in AI2AI payloads
    final forbiddenFields = [
      'id',
      'email',
      'displayName',
      'photoUrl',
      'userId'
    ];

    for (final field in forbiddenFields) {
      if (payload.containsKey(field)) {
        throw Exception(
            'CRITICAL: UnifiedUser field "$field" detected in AI2AI payload. '
            'All user data must be converted to AnonymousUser before transmission. '
            'Use anonymizeUserForTransmission() method.');
      }
    }

    // Recursively check nested objects
    for (final value in payload.values) {
      if (value is Map<String, dynamic>) {
        validateNoUnifiedUserInPayload(value);
      } else if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            validateNoUnifiedUserInPayload(item);
          }
        }
      }
    }
  }

  /// Set up realtime listeners for AI2AI communication (safe no-op if unavailable)
  Future<void> _setupRealtimeListeners() async {
    final coordinator = _realtimeCoordinator;
    if (coordinator == null) return;
    try {
      coordinator.setup(
        onPersonality: (message) {
          // #region agent log
          _logger.debug(
              'Received personality discovery message: ${message.type}, nodeId: ${message.metadata['node_id']}',
              tag: _logName);
          // #endregion
          // Handle personality discovery messages - update discovered nodes cache
          // In production, would process message and update _discoveredNodes
          if (message.metadata.containsKey('node_id')) {
            // Would create AIPersonalityNode from message metadata
            // _updateDiscoveredNodes([nodeFromMessage]);
          }
        },
        onLearning: (message) {
          // #region agent log
          _logger.debug(
              'Received vibe learning message: ${message.type}, dimensions: ${message.metadata['dimension_updates']?.keys.length ?? 0}',
              tag: _logName);
          // #endregion
          // Handle vibe learning messages - update active connections with learning insights
          // In production, would process learning insights and update connection metrics
          if (message.metadata.containsKey('dimension_updates')) {
            // Would update active connections with new learning data
          }
        },
        onAnonymous: (message) {
          // #region agent log
          _logger.debug(
              'Received anonymous communication message: ${message.type}, payload_size: ${message.metadata.length}',
              tag: _logName);
          // #endregion
          // Handle anonymous communication messages - process AI2AI network messages
          // In production, would process anonymous messages and route to appropriate handlers
          // Would validate payload doesn't contain UnifiedUser data
          validateNoUnifiedUserInPayload(message.metadata);
        },
      );
      // #region agent log
      _logger.debug('Realtime listeners setup with active subscriptions',
          tag: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      _logger.warn('Failed to setup realtime listeners: $e', tag: _logName);
      // #endregion
    }
  }
}

// Supporting classes for AI2AI connection orchestration
// moved to core/ai2ai/aipersonality_node.dart

class PendingConnection {
  final String localUserId;
  final AIPersonalityNode remoteNode;
  final VibeCompatibilityResult compatibility;
  final DateTime requestedAt;

  PendingConnection({
    required this.localUserId,
    required this.remoteNode,
    required this.compatibility,
    required this.requestedAt,
  });

  bool get isExpired => DateTime.now().difference(requestedAt).inMinutes > 2;
}

class ConnectionSummary {
  final String connectionId;
  final Duration duration;
  final double compatibility;
  final double learningEffectiveness;
  final double aiPleasureScore;
  final String qualityRating;
  final ConnectionStatus status;
  final int interactionCount;
  final int dimensionsEvolved;

  ConnectionSummary({
    required this.connectionId,
    required this.duration,
    required this.compatibility,
    required this.learningEffectiveness,
    required this.aiPleasureScore,
    required this.qualityRating,
    required this.status,
    required this.interactionCount,
    required this.dimensionsEvolved,
  });

  Map<String, dynamic> toJson() {
    return {
      'connection_id': connectionId.substring(0, 8),
      'duration_seconds': duration.inSeconds,
      'compatibility': (compatibility * 100).round(),
      'learning_effectiveness': (learningEffectiveness * 100).round(),
      'ai_pleasure_score': (aiPleasureScore * 100).round(),
      'quality_rating': qualityRating,
      'status': status.toString().split('.').last,
      'interaction_count': interactionCount,
      'dimensions_evolved': dimensionsEvolved,
    };
  }
}

class AI2AIConnectionException implements Exception {
  final String message;

  AI2AIConnectionException(this.message);

  @override
  String toString() => 'AI2AIConnectionException: $message';
}
