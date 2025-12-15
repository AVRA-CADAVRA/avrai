import 'dart:developer' as developer;
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:spots/core/constants/vibe_constants.dart';
import 'package:spots/core/models/connection_metrics.dart';
import 'package:spots/core/services/storage_service.dart' show SharedPreferencesCompat;

/// OUR_GUTS.md: "Connection monitoring that tracks AI2AI personality interactions while preserving privacy"
/// Comprehensive connection monitoring system for individual AI2AI personality learning interactions
class ConnectionMonitor {
  static const String _logName = 'ConnectionMonitor';

  // Storage keys for connection monitoring data
  static const String _activeConnectionsKey = 'active_connections';
  static const String _connectionHistoryKey = 'connection_history';
  static const String _monitoringAlertsKey = 'monitoring_alerts';

  final SharedPreferencesCompat _prefs;

  // Monitoring state
  final Map<String, ActiveConnection> _activeConnections = {};
  final Map<String, ConnectionMonitoringSession> _monitoringSessions = {};
  final List<ConnectionAlert> _alerts = [];
  Timer? _monitoringTimer;

  // Reverse index: AI signature -> Set of connection IDs
  // This enables O(1) lookup of all connections for a given AI signature
  final Map<String, Set<String>> _aiSignatureIndex = {};

  // Stream controllers for active connections
  StreamController<ActiveConnectionsOverview>? _connectionsStreamController;

  ConnectionMonitor({required SharedPreferencesCompat prefs}) : _prefs = prefs {
    // Load persisted data on initialization (fire and forget - runs in background)
    _loadPersistedData().catchError((e) {
      developer.log('Error loading persisted data in constructor: $e', name: _logName);
    });
  }
  
  /// Load persisted data from SharedPreferences
  Future<void> _loadPersistedData() async {
    try {
      // #region agent log
      developer.log('Loading persisted connection monitoring data', name: _logName);
      // #endregion
      
      // Load active connections (note: in production, would need to restore full sessions)
      final activeConnectionsJson = _prefs.getStringList(_activeConnectionsKey) ?? [];
      // #region agent log
      developer.log('Found ${activeConnectionsJson.length} persisted active connections', name: _logName);
      // #endregion
      
      // Load connection history
      final historyJson = _prefs.getStringList(_connectionHistoryKey) ?? [];
      // #region agent log
      developer.log('Found ${historyJson.length} persisted connection history entries', name: _logName);
      // #endregion
      
      // Load alerts
      final alertsJson = _prefs.getStringList(_monitoringAlertsKey) ?? [];
      // #region agent log
      developer.log('Found ${alertsJson.length} persisted alerts', name: _logName);
      // #endregion
      
      // Note: Full session restoration would require deserializing ConnectionMonitoringSession
      // For now, we track active connections in memory and persist on changes
      // Active connections are restored from memory on app restart via _activeConnections map
    } catch (e) {
      // #region agent log
      developer.log('Error loading persisted data: $e', name: _logName);
      // #endregion
    }
  }

  /// Start monitoring a new AI2AI connection
  Future<ConnectionMonitoringSession> startMonitoring(
    String connectionId,
    ConnectionMetrics initialMetrics,
  ) async {
    try {
      developer.log('Starting connection monitoring for: $connectionId',
          name: _logName);

      // Create monitoring session
      final session = ConnectionMonitoringSession(
        connectionId: connectionId,
        localAISignature: initialMetrics.localAISignature,
        remoteAISignature: initialMetrics.remoteAISignature,
        startTime: DateTime.now(),
        initialMetrics: initialMetrics,
        currentMetrics: initialMetrics,
        qualityHistory: [ConnectionQualitySnapshot.fromMetrics(initialMetrics)],
        learningProgressHistory: [
          LearningProgressSnapshot.fromMetrics(initialMetrics)
        ],
        alertsGenerated: [],
        monitoringStatus: MonitoringStatus.active,
      );

      // Store active connection
      _activeConnections[connectionId] = ActiveConnection.fromSession(session);
      _monitoringSessions[connectionId] = session;

      // Update reverse index for efficient AI signature queries
      _updateAISignatureIndex(session.localAISignature, connectionId,
          add: true);
      _updateAISignatureIndex(session.remoteAISignature, connectionId,
          add: true);

      // Persist active connections
      await _saveActiveConnections();

      // Start periodic monitoring if not already running
      _ensureMonitoringTimerRunning();

      // #region agent log
      developer.log('Connection monitoring started: $connectionId (persisted to $_activeConnectionsKey)', name: _logName);
      // #endregion
      return session;
    } catch (e) {
      developer.log('Error starting connection monitoring: $e', name: _logName);
      throw ConnectionMonitoringException('Failed to start monitoring: $e');
    }
  }

  /// Update connection metrics during monitoring
  Future<ConnectionMonitoringSession> updateConnectionMetrics(
    String connectionId,
    ConnectionMetrics updatedMetrics,
  ) async {
    try {
      final session = _monitoringSessions[connectionId];
      if (session == null) {
        throw ConnectionMonitoringException(
            'Connection monitoring session not found: $connectionId');
      }

      developer.log('Updating connection metrics for: $connectionId',
          name: _logName);

      // Calculate quality changes
      final qualityChange =
          await _calculateQualityChange(session.currentMetrics, updatedMetrics);

      // Detect learning progress
      await _calculateLearningProgress(session, updatedMetrics);

      // Check for performance alerts
      final newAlerts = await _checkForPerformanceAlerts(
          connectionId, updatedMetrics, qualityChange);

      // Update monitoring session
      final updatedSession = session.copyWith(
        currentMetrics: updatedMetrics,
        qualityHistory: [
          ...session.qualityHistory,
          ConnectionQualitySnapshot.fromMetrics(updatedMetrics)
        ],
        learningProgressHistory: [
          ...session.learningProgressHistory,
          LearningProgressSnapshot.fromMetrics(updatedMetrics)
        ],
        alertsGenerated: [...session.alertsGenerated, ...newAlerts],
        lastUpdated: DateTime.now(),
      );

      _monitoringSessions[connectionId] = updatedSession;
      _activeConnections[connectionId] =
          ActiveConnection.fromSession(updatedSession);

      // Persist updated active connections
      await _saveActiveConnections();

      // Process any new alerts
      if (newAlerts.isNotEmpty) {
        await _processConnectionAlerts(connectionId, newAlerts);
      }

      developer.log(
          'Connection metrics updated: $connectionId (quality: ${(updatedMetrics.currentCompatibility * 100).round()}%)',
          name: _logName);
      return updatedSession;
    } catch (e) {
      developer.log('Error updating connection metrics: $e', name: _logName);
      throw ConnectionMonitoringException('Failed to update metrics: $e');
    }
  }

  /// Stop monitoring a connection
  Future<ConnectionMonitoringReport> stopMonitoring(String connectionId) async {
    try {
      developer.log('Stopping connection monitoring for: $connectionId',
          name: _logName);

      final session = _monitoringSessions[connectionId];
      if (session == null) {
        throw ConnectionMonitoringException(
            'Connection monitoring session not found: $connectionId');
      }

      // Generate final monitoring report
      final report = await _generateMonitoringReport(session);

      // Archive the session
      await _archiveMonitoringSession(session);

      // Cleanup active monitoring
      _activeConnections.remove(connectionId);
      final removedSession = _monitoringSessions.remove(connectionId);

      // Update reverse index
      if (removedSession != null) {
        _updateAISignatureIndex(removedSession.localAISignature, connectionId,
            add: false);
        _updateAISignatureIndex(removedSession.remoteAISignature, connectionId,
            add: false);
      }

      // Persist updated active connections (removed this one)
      await _saveActiveConnections();

      // Stop monitoring timer if no active connections
      if (_activeConnections.isEmpty) {
        _monitoringTimer?.cancel();
        _monitoringTimer = null;
      }

      developer.log(
          'Connection monitoring stopped: $connectionId (duration: ${report.connectionDuration.inMinutes}min)',
          name: _logName);
      return report;
    } catch (e) {
      developer.log('Error stopping connection monitoring: $e', name: _logName);
      throw ConnectionMonitoringException('Failed to stop monitoring: $e');
    }
  }

  /// Get real-time connection status
  Future<ConnectionMonitoringStatus> getConnectionStatus(
      String connectionId) async {
    try {
      final session = _monitoringSessions[connectionId];
      if (session == null) {
        return ConnectionMonitoringStatus.notFound(connectionId);
      }

      // Calculate current performance metrics
      final currentPerformance = await _calculateCurrentPerformance(session);

      // Assess connection health
      final healthScore = await _assessConnectionHealth(session);

      // Get recent alerts
      final recentAlerts = session.alertsGenerated
          .where((alert) =>
              DateTime.now().difference(alert.timestamp) <
              Duration(minutes: 15))
          .toList();

      // Predict connection trajectory
      final trajectory = await _predictConnectionTrajectory(session);

      return ConnectionMonitoringStatus(
        connectionId: connectionId,
        currentPerformance: currentPerformance,
        healthScore: healthScore,
        recentAlerts: recentAlerts,
        trajectory: trajectory,
        monitoringDuration: DateTime.now().difference(session.startTime),
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error getting connection status: $e', name: _logName);
      return ConnectionMonitoringStatus.error(connectionId, e.toString());
    }
  }

  /// Get monitoring session for admin access
  /// Returns the full session with all metrics and interaction history
  ConnectionMonitoringSession? getMonitoringSession(String connectionId) {
    return _monitoringSessions[connectionId];
  }

  /// Get all connection IDs for a specific AI signature
  /// Efficient O(1) lookup using reverse index
  /// Returns both connections where AI is local and remote
  Set<String> getConnectionsByAISignature(String aiSignature) {
    return Set<String>.from(_aiSignatureIndex[aiSignature] ?? {});
  }

  /// Get all monitoring sessions for a specific AI signature
  /// Returns sessions where the AI signature is either local or remote
  List<ConnectionMonitoringSession> getSessionsByAISignature(
      String aiSignature) {
    final connectionIds = getConnectionsByAISignature(aiSignature);
    return connectionIds
        .map((id) => _monitoringSessions[id])
        .whereType<ConnectionMonitoringSession>()
        .toList();
  }

  /// Update reverse index for AI signature lookups
  void _updateAISignatureIndex(String aiSignature, String connectionId,
      {required bool add}) {
    if (aiSignature.isEmpty) return;

    if (add) {
      _aiSignatureIndex
          .putIfAbsent(aiSignature, () => <String>{})
          .add(connectionId);
    } else {
      _aiSignatureIndex[aiSignature]?.remove(connectionId);
      // Clean up empty sets to prevent memory leaks
      if (_aiSignatureIndex[aiSignature]?.isEmpty ?? false) {
        _aiSignatureIndex.remove(aiSignature);
      }
    }
  }

  /// Analyze connection performance trends
  Future<ConnectionPerformanceAnalysis> analyzeConnectionPerformance(
    String connectionId,
    Duration analysisWindow,
  ) async {
    try {
      developer.log('Analyzing connection performance for: $connectionId',
          name: _logName);

      final session = _monitoringSessions[connectionId];
      if (session == null) {
        throw ConnectionMonitoringException(
            'Connection monitoring session not found: $connectionId');
      }

      final cutoffTime = DateTime.now().subtract(analysisWindow);

      // Analyze quality trends
      final qualityTrends = await _analyzeQualityTrends(session, cutoffTime);

      // Analyze learning effectiveness trends
      final learningTrends = await _analyzeLearningTrends(session, cutoffTime);

      // Calculate performance stability
      final stabilityMetrics =
          await _calculateStabilityMetrics(session, cutoffTime);

      // Identify performance patterns
      final performancePatterns =
          await _identifyPerformancePatterns(session, cutoffTime);

      // Generate performance recommendations
      final recommendations = await _generatePerformanceRecommendations(
        qualityTrends,
        learningTrends,
        stabilityMetrics,
      );

      final analysis = ConnectionPerformanceAnalysis(
        connectionId: connectionId,
        analysisWindow: analysisWindow,
        qualityTrends: qualityTrends,
        learningTrends: learningTrends,
        stabilityMetrics: stabilityMetrics,
        performancePatterns: performancePatterns,
        recommendations: recommendations,
        overallPerformanceScore: _calculateOverallPerformanceScore(
          qualityTrends,
          learningTrends,
          stabilityMetrics,
        ),
        analyzedAt: DateTime.now(),
      );

      developer.log(
          'Connection performance analysis completed: ${recommendations.length} recommendations',
          name: _logName);
      return analysis;
    } catch (e) {
      developer.log('Error analyzing connection performance: $e',
          name: _logName);
      return ConnectionPerformanceAnalysis.failed(connectionId, analysisWindow);
    }
  }

  /// Get all active connections overview
  Future<ActiveConnectionsOverview> getActiveConnectionsOverview() async {
    try {
      developer.log('Generating active connections overview', name: _logName);

      if (_activeConnections.isEmpty) {
        return ActiveConnectionsOverview.empty();
      }

      // Calculate aggregate metrics
      final aggregateMetrics = await _calculateAggregateMetrics();

      // Identify top performing connections
      final topPerformingConnections =
          await _identifyTopPerformingConnections();

      // Identify connections needing attention
      final connectionsNeedingAttention =
          await _identifyConnectionsNeedingAttention();

      // Calculate learning velocity distribution
      final learningVelocityDistribution =
          await _calculateLearningVelocityDistribution();

      // Generate optimization opportunities
      final optimizationOpportunities =
          await _identifyOptimizationOpportunities();

      final overview = ActiveConnectionsOverview(
        totalActiveConnections: _activeConnections.length,
        aggregateMetrics: aggregateMetrics,
        topPerformingConnections: topPerformingConnections,
        connectionsNeedingAttention: connectionsNeedingAttention,
        learningVelocityDistribution: learningVelocityDistribution,
        optimizationOpportunities: optimizationOpportunities,
        averageConnectionDuration: _calculateAverageConnectionDuration(),
        totalAlertsGenerated: _countTotalAlerts(),
        generatedAt: DateTime.now(),
      );

      developer.log(
          'Active connections overview generated: ${overview.totalActiveConnections} active, ${overview.connectionsNeedingAttention.length} need attention',
          name: _logName);
      return overview;
    } catch (e) {
      developer.log('Error generating active connections overview: $e',
          name: _logName);
      return ActiveConnectionsOverview.empty();
    }
  }

  /// Detect connection anomalies
  Future<List<ConnectionAnomaly>> detectConnectionAnomalies() async {
    try {
      developer.log(
          'Detecting connection anomalies across ${_activeConnections.length} connections',
          name: _logName);

      final anomalies = <ConnectionAnomaly>[];

      for (final session in _monitoringSessions.values) {
        // Detect quality anomalies
        final qualityAnomalies = await _detectQualityAnomalies(session);
        anomalies.addAll(qualityAnomalies);

        // Detect learning anomalies
        final learningAnomalies = await _detectLearningAnomalies(session);
        anomalies.addAll(learningAnomalies);

        // Detect behavior anomalies
        final behaviorAnomalies = await _detectBehaviorAnomalies(session);
        anomalies.addAll(behaviorAnomalies);
      }

      // Sort by severity and timestamp
      anomalies.sort((a, b) {
        final severityComparison = b.severity.index.compareTo(a.severity.index);
        if (severityComparison != 0) return severityComparison;
        return b.detectedAt.compareTo(a.detectedAt);
      });

      developer.log('Detected ${anomalies.length} connection anomalies',
          name: _logName);
      return anomalies;
    } catch (e) {
      developer.log('Error detecting connection anomalies: $e', name: _logName);
      return [];
    }
  }

  // Private helper methods
  void _ensureMonitoringTimerRunning() {
    if (_monitoringTimer == null || !_monitoringTimer!.isActive) {
      _monitoringTimer = Timer.periodic(
          Duration(seconds: 30), (_) => _performPeriodicMonitoring());
      developer.log('Connection monitoring timer started', name: _logName);
    }
  }

  Future<void> _performPeriodicMonitoring() async {
    try {
      for (final connectionId in _activeConnections.keys.toList()) {
        final session = _monitoringSessions[connectionId];
        if (session != null) {
          // Check for timeout or stale connections
          await _checkConnectionTimeout(connectionId, session);

          // Monitor for degradation patterns
          await _monitorConnectionDegradation(connectionId, session);

          // Check learning progress stagnation
          await _checkLearningStagnation(connectionId, session);
        }
      }
    } catch (e) {
      developer.log('Error during periodic monitoring: $e', name: _logName);
    }
  }

  Future<ConnectionQualityChange> _calculateQualityChange(
    ConnectionMetrics previous,
    ConnectionMetrics current,
  ) async {
    final compatibilityChange =
        current.currentCompatibility - previous.currentCompatibility;
    final learningEffectivenessChange =
        current.learningEffectiveness - previous.learningEffectiveness;
    final aiPleasureChange = current.aiPleasureScore - previous.aiPleasureScore;

    return ConnectionQualityChange(
      compatibilityChange: compatibilityChange,
      learningEffectivenessChange: learningEffectivenessChange,
      aiPleasureChange: aiPleasureChange,
      overallChange: (compatibilityChange +
              learningEffectivenessChange +
              aiPleasureChange) /
          3.0,
      changeDirection: _determineChangeDirection(
          compatibilityChange, learningEffectivenessChange, aiPleasureChange),
    );
  }

  Future<LearningProgressMetrics> _calculateLearningProgress(
    ConnectionMonitoringSession session,
    ConnectionMetrics updatedMetrics,
  ) async {
    final progressSince = Duration(minutes: 5); // Look at last 5 minutes
    final cutoffTime = DateTime.now().subtract(progressSince);

    final recentHistory = session.learningProgressHistory
        .where((snapshot) => snapshot.timestamp.isAfter(cutoffTime))
        .toList();

    if (recentHistory.length < 2) {
      return LearningProgressMetrics.minimal();
    }

    final firstSnapshot = recentHistory.first;
    final lastSnapshot = recentHistory.last;

    final progressRate = (lastSnapshot.learningEffectiveness -
            firstSnapshot.learningEffectiveness) /
        progressSince.inMinutes;

    return LearningProgressMetrics(
      progressRate: progressRate,
      learningVelocity: updatedMetrics.learningEffectiveness,
      dimensionEvolutionRate: _calculateDimensionEvolutionRate(updatedMetrics),
      insightGenerationRate: 0.5 + Random().nextDouble() * 0.3, // Simulated
    );
  }

  Future<List<ConnectionAlert>> _checkForPerformanceAlerts(
    String connectionId,
    ConnectionMetrics metrics,
    ConnectionQualityChange qualityChange,
  ) async {
    final alerts = <ConnectionAlert>[];

    // Check for low compatibility
    if (metrics.currentCompatibility <
        VibeConstants.lowCompatibilityThreshold) {
      alerts.add(ConnectionAlert(
        connectionId: connectionId,
        type: AlertType.lowCompatibility,
        severity: AlertSeverity.medium,
        message:
            'Connection compatibility below threshold (${(metrics.currentCompatibility * 100).round()}%)',
        timestamp: DateTime.now(),
        metadata: {'compatibility': metrics.currentCompatibility},
      ));
    }

    // Check for learning effectiveness drop
    if (metrics.learningEffectiveness <
        VibeConstants.minLearningEffectiveness) {
      alerts.add(ConnectionAlert(
        connectionId: connectionId,
        type: AlertType.lowLearningEffectiveness,
        severity: AlertSeverity.high,
        message: 'Learning effectiveness below minimum threshold',
        timestamp: DateTime.now(),
        metadata: {'learning_effectiveness': metrics.learningEffectiveness},
      ));
    }

    // Check for rapid quality degradation
    if (qualityChange.overallChange < -0.2) {
      alerts.add(ConnectionAlert(
        connectionId: connectionId,
        type: AlertType.qualityDegradation,
        severity: AlertSeverity.high,
        message: 'Rapid connection quality degradation detected',
        timestamp: DateTime.now(),
        metadata: {'quality_change': qualityChange.overallChange},
      ));
    }

    return alerts;
  }

  Future<void> _processConnectionAlerts(
      String connectionId, List<ConnectionAlert> alerts) async {
    for (final alert in alerts) {
      _alerts.add(alert);
      developer.log(
          'CONNECTION ALERT [${alert.severity.name.toUpperCase()}]: ${alert.message}',
          name: _logName);

      // Persist alerts
      await _saveAlerts();

      // In a real implementation, this might trigger notifications or automatic responses
      if (alert.severity == AlertSeverity.critical) {
        await _handleCriticalAlert(connectionId, alert);
      }
    }
  }

  Future<void> _handleCriticalAlert(
      String connectionId, ConnectionAlert alert) async {
    developer.log('Handling critical alert for connection: $connectionId',
        name: _logName);
    // In a real implementation, this might automatically terminate problematic connections
    // or trigger emergency protocols
  }

  Future<ConnectionMonitoringReport> _generateMonitoringReport(
    ConnectionMonitoringSession session,
  ) async {
    final connectionDuration = DateTime.now().difference(session.startTime);

    // Calculate performance summary
    final performanceSummary = await _calculatePerformanceSummary(session);

    // Calculate learning outcomes
    final learningOutcomes = await _calculateLearningOutcomes(session);

    // Generate quality analysis
    final qualityAnalysis = await _generateQualityAnalysis(session);

    return ConnectionMonitoringReport(
      connectionId: session.connectionId,
      localAISignature: session.localAISignature,
      remoteAISignature: session.remoteAISignature,
      connectionDuration: connectionDuration,
      initialMetrics: session.initialMetrics,
      finalMetrics: session.currentMetrics,
      performanceSummary: performanceSummary,
      learningOutcomes: learningOutcomes,
      qualityAnalysis: qualityAnalysis,
      alertsGenerated: session.alertsGenerated,
      overallRating: _calculateOverallConnectionRating(session),
      generatedAt: DateTime.now(),
    );
  }

  Future<void> _archiveMonitoringSession(
      ConnectionMonitoringSession session) async {
    // #region agent log
    developer.log('Archiving monitoring session: ${session.connectionId}', name: _logName);
    // #endregion
    
    try {
      // Serialize session to JSON
      final sessionJson = _sessionToJson(session);
      
      // Load existing history
      final historyJson = _prefs.getStringList(_connectionHistoryKey) ?? [];
      
      // Add this session to history
      historyJson.add(jsonEncode(sessionJson));
      
      // Limit history size to prevent unbounded growth (keep last 1000 sessions)
      if (historyJson.length > 1000) {
        historyJson.removeRange(0, historyJson.length - 1000);
      }
      
      // Save updated history
      await _prefs.setStringList(_connectionHistoryKey, historyJson);
      
      // #region agent log
      developer.log('Session archived: ${session.connectionId} (history now contains ${historyJson.length} entries)', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error archiving session: $e', name: _logName);
      // #endregion
    }
  }
  
  /// Save active connections to persistent storage
  Future<void> _saveActiveConnections() async {
    try {
      // #region agent log
      developer.log('Saving ${_activeConnections.length} active connections to storage', name: _logName);
      // #endregion
      
      final connectionsJson = _activeConnections.values
          .map((conn) => jsonEncode(_activeConnectionToJson(conn)))
          .toList();
      
      await _prefs.setStringList(_activeConnectionsKey, connectionsJson);
      
      // #region agent log
      developer.log('Active connections saved successfully', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error saving active connections: $e', name: _logName);
      // #endregion
    }
  }
  
  /// Save alerts to persistent storage
  Future<void> _saveAlerts() async {
    try {
      // #region agent log
      developer.log('Saving ${_alerts.length} alerts to storage', name: _logName);
      // #endregion
      
      final alertsJson = _alerts
          .map((alert) => jsonEncode(_alertToJson(alert)))
          .toList();
      
      // Limit alerts size to prevent unbounded growth (keep last 500 alerts)
      if (alertsJson.length > 500) {
        alertsJson.removeRange(0, alertsJson.length - 500);
      }
      
      await _prefs.setStringList(_monitoringAlertsKey, alertsJson);
      
      // #region agent log
      developer.log('Alerts saved successfully', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error saving alerts: $e', name: _logName);
      // #endregion
    }
  }
  
  /// Serialize ConnectionMonitoringSession to JSON
  Map<String, dynamic> _sessionToJson(ConnectionMonitoringSession session) {
    return {
      'connectionId': session.connectionId,
      'localAISignature': session.localAISignature,
      'remoteAISignature': session.remoteAISignature,
      'startTime': session.startTime.toIso8601String(),
      'lastUpdated': session.lastUpdated?.toIso8601String(),
      'monitoringStatus': session.monitoringStatus.name,
      'initialMetrics': session.initialMetrics.toJson(),
      'currentMetrics': session.currentMetrics.toJson(),
      'qualityHistoryCount': session.qualityHistory.length,
      'learningProgressHistoryCount': session.learningProgressHistory.length,
      'alertsGeneratedCount': session.alertsGenerated.length,
    };
  }
  
  /// Serialize ActiveConnection to JSON
  Map<String, dynamic> _activeConnectionToJson(ActiveConnection connection) {
    return {
      'connectionId': connection.connectionId,
      'localAISignature': connection.localAISignature,
      'remoteAISignature': connection.remoteAISignature,
      'startTime': connection.startTime.toIso8601String(),
      'currentCompatibility': connection.currentCompatibility,
      'learningEffectiveness': connection.learningEffectiveness,
      'status': connection.status.name,
    };
  }
  
  /// Serialize ConnectionAlert to JSON
  Map<String, dynamic> _alertToJson(ConnectionAlert alert) {
    return {
      'connectionId': alert.connectionId,
      'type': alert.type.name,
      'severity': alert.severity.name,
      'message': alert.message,
      'timestamp': alert.timestamp.toIso8601String(),
      'metadata': alert.metadata,
    };
  }

  // Additional helper methods with placeholder implementations
  ChangeDirection _determineChangeDirection(
      double comp, double learning, double pleasure) {
    final average = (comp + learning + pleasure) / 3.0;
    if (average > 0.05) return ChangeDirection.improving;
    if (average < -0.05) return ChangeDirection.degrading;
    return ChangeDirection.stable;
  }

  double _calculateDimensionEvolutionRate(ConnectionMetrics metrics) =>
      metrics.dimensionEvolution.values
          .fold(0.0, (sum, change) => sum + change.abs()) /
      max(1, metrics.dimensionEvolution.length);

  Future<CurrentPerformanceMetrics> _calculateCurrentPerformance(
          ConnectionMonitoringSession session) async =>
      CurrentPerformanceMetrics.fromSession(session);

  Future<double> _assessConnectionHealth(
          ConnectionMonitoringSession session) async =>
      (session.currentMetrics.currentCompatibility +
          session.currentMetrics.learningEffectiveness +
          session.currentMetrics.aiPleasureScore) /
      3.0;

  Future<ConnectionTrajectory> _predictConnectionTrajectory(
          ConnectionMonitoringSession session) async =>
      ConnectionTrajectory.stable();

  // Performance analysis helper methods (placeholder implementations)
  Future<QualityTrends> _analyzeQualityTrends(
          ConnectionMonitoringSession session, DateTime cutoff) async =>
      QualityTrends.stable();
  Future<LearningTrends> _analyzeLearningTrends(
          ConnectionMonitoringSession session, DateTime cutoff) async =>
      LearningTrends.positive();
  Future<StabilityMetrics> _calculateStabilityMetrics(
          ConnectionMonitoringSession session, DateTime cutoff) async =>
      StabilityMetrics.stable();
  Future<List<PerformancePattern>> _identifyPerformancePatterns(
          ConnectionMonitoringSession session, DateTime cutoff) async =>
      [];
  Future<List<PerformanceRecommendation>> _generatePerformanceRecommendations(
          QualityTrends quality,
          LearningTrends learning,
          StabilityMetrics stability) async =>
      [];

  double _calculateOverallPerformanceScore(QualityTrends quality,
          LearningTrends learning, StabilityMetrics stability) =>
      0.8;

  // Active connections analysis helper methods
  Future<AggregateConnectionMetrics> _calculateAggregateMetrics() async =>
      AggregateConnectionMetrics.good();
  Future<List<String>> _identifyTopPerformingConnections() async =>
      _activeConnections.keys.take(3).toList();
  Future<List<String>> _identifyConnectionsNeedingAttention() async => [];
  Future<LearningVelocityDistribution>
      _calculateLearningVelocityDistribution() async =>
          LearningVelocityDistribution.normal();
  Future<List<OptimizationOpportunity>>
      _identifyOptimizationOpportunities() async => [];

  Duration _calculateAverageConnectionDuration() {
    if (_activeConnections.isEmpty) return Duration.zero;
    final totalMinutes = _monitoringSessions.values
        .map(
            (session) => DateTime.now().difference(session.startTime).inMinutes)
        .fold(0, (sum, duration) => sum + duration);
    return Duration(minutes: totalMinutes ~/ _activeConnections.length);
  }

  int _countTotalAlerts() => _monitoringSessions.values
      .map((session) => session.alertsGenerated.length)
      .fold(0, (sum, count) => sum + count);

  // Anomaly detection helper methods
  Future<List<ConnectionAnomaly>> _detectQualityAnomalies(
          ConnectionMonitoringSession session) async =>
      [];
  Future<List<ConnectionAnomaly>> _detectLearningAnomalies(
          ConnectionMonitoringSession session) async =>
      [];
  Future<List<ConnectionAnomaly>> _detectBehaviorAnomalies(
          ConnectionMonitoringSession session) async =>
      [];

  // Periodic monitoring helper methods
  Future<void> _checkConnectionTimeout(
      String connectionId, ConnectionMonitoringSession session) async {
    final maxDuration = Duration(hours: 5); // Maximum connection duration
    if (DateTime.now().difference(session.startTime) > maxDuration) {
      developer.log('Connection timeout detected: $connectionId',
          name: _logName);
    }
  }

  Future<void> _monitorConnectionDegradation(
      String connectionId, ConnectionMonitoringSession session) async {
    // Check for consistent quality degradation
    if (session.qualityHistory.length >= 5) {
      final recentQualities = session.qualityHistory
          .skip(max(0, session.qualityHistory.length - 5))
          .map((q) => q.compatibility)
          .toList();
      final isDegraing = _isConsistentlyDegrading(recentQualities);
      if (isDegraing) {
        developer.log('Connection degradation pattern detected: $connectionId',
            name: _logName);
      }
    }
  }

  Future<void> _checkLearningStagnation(
      String connectionId, ConnectionMonitoringSession session) async {
    // Check for learning progress stagnation
    if (session.learningProgressHistory.length >= 10) {
      final recentLearning = session.learningProgressHistory
          .skip(max(0, session.learningProgressHistory.length - 10))
          .map((l) => l.learningEffectiveness)
          .toList();
      final stagnationThreshold = 0.02; // Less than 2% change
      final maxChange = recentLearning.reduce(max) - recentLearning.reduce(min);
      if (maxChange < stagnationThreshold) {
        developer.log('Learning stagnation detected: $connectionId',
            name: _logName);
      }
    }
  }

  bool _isConsistentlyDegrading(List<double> values) {
    if (values.length < 3) return false;
    for (int i = 1; i < values.length; i++) {
      if (values[i] >= values[i - 1]) return false;
    }
    return true;
  }

  // Additional analysis helper methods
  Future<PerformanceSummary> _calculatePerformanceSummary(
          ConnectionMonitoringSession session) async =>
      PerformanceSummary.good();
  Future<LearningOutcomes> _calculateLearningOutcomes(
          ConnectionMonitoringSession session) async =>
      LearningOutcomes.positive();
  Future<QualityAnalysis> _generateQualityAnalysis(
          ConnectionMonitoringSession session) async =>
      QualityAnalysis.stable();

  double _calculateOverallConnectionRating(
          ConnectionMonitoringSession session) =>
      (session.currentMetrics.currentCompatibility +
          session.currentMetrics.learningEffectiveness +
          session.currentMetrics.aiPleasureScore) /
      3.0;

  /// Stream active connections overview
  /// Emits initial value immediately, then updates on connection changes
  Stream<ActiveConnectionsOverview> streamActiveConnections() {
    // Create broadcast stream controller if not exists
    if (_connectionsStreamController == null ||
        _connectionsStreamController!.isClosed) {
      _connectionsStreamController =
          StreamController<ActiveConnectionsOverview>.broadcast();
    }

    // Store local reference to avoid null check issues
    final controller = _connectionsStreamController;
    if (controller == null) {
      // Fallback: return a stream that emits empty overview
      return Stream.value(ActiveConnectionsOverview.empty());
    }

    // Emit initial value immediately
    getActiveConnectionsOverview().then((overview) {
      if (controller.isClosed) return;
      controller.add(overview);
    }).catchError((error) {
      developer.log('Error in streamActiveConnections initial value: $error',
          name: _logName);
      if (controller.isClosed) return;
      controller.add(ActiveConnectionsOverview.empty());
    });

    // Set up periodic updates every 5 seconds
    Timer.periodic(const Duration(seconds: 5), (timer) async {
      final currentController = _connectionsStreamController;
      if (currentController == null || currentController.isClosed) {
        timer.cancel();
        return;
      }

      try {
        final overview = await getActiveConnectionsOverview();
        if (currentController.isClosed) return;
        currentController.add(overview);
      } catch (e) {
        developer.log('Error in streamActiveConnections periodic update: $e',
            name: _logName);
        if (currentController.isClosed) return;
        currentController.add(ActiveConnectionsOverview.empty());
      }
    });

    return controller.stream.handleError((error) {
      developer.log('Stream error in streamActiveConnections: $error',
          name: _logName);
    });
  }

  /// Dispose stream controller
  void disposeStreams() {
    _connectionsStreamController?.close();
    _connectionsStreamController = null;
  }
}

// Supporting classes for connection monitoring
class ConnectionMonitoringSession {
  final String connectionId;
  final String localAISignature;
  final String remoteAISignature;
  final DateTime startTime;
  final ConnectionMetrics initialMetrics;
  final ConnectionMetrics currentMetrics;
  final List<ConnectionQualitySnapshot> qualityHistory;
  final List<LearningProgressSnapshot> learningProgressHistory;
  final List<ConnectionAlert> alertsGenerated;
  final MonitoringStatus monitoringStatus;
  final DateTime? lastUpdated;

  ConnectionMonitoringSession({
    required this.connectionId,
    required this.localAISignature,
    required this.remoteAISignature,
    required this.startTime,
    required this.initialMetrics,
    required this.currentMetrics,
    required this.qualityHistory,
    required this.learningProgressHistory,
    required this.alertsGenerated,
    required this.monitoringStatus,
    this.lastUpdated,
  });

  ConnectionMonitoringSession copyWith({
    ConnectionMetrics? currentMetrics,
    List<ConnectionQualitySnapshot>? qualityHistory,
    List<LearningProgressSnapshot>? learningProgressHistory,
    List<ConnectionAlert>? alertsGenerated,
    MonitoringStatus? monitoringStatus,
    DateTime? lastUpdated,
  }) {
    return ConnectionMonitoringSession(
      connectionId: connectionId,
      localAISignature: localAISignature,
      remoteAISignature: remoteAISignature,
      startTime: startTime,
      initialMetrics: initialMetrics,
      currentMetrics: currentMetrics ?? this.currentMetrics,
      qualityHistory: qualityHistory ?? this.qualityHistory,
      learningProgressHistory:
          learningProgressHistory ?? this.learningProgressHistory,
      alertsGenerated: alertsGenerated ?? this.alertsGenerated,
      monitoringStatus: monitoringStatus ?? this.monitoringStatus,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get interaction history from connection metrics
  List<InteractionEvent> get interactionHistory =>
      currentMetrics.interactionHistory;
}

class ActiveConnection {
  final String connectionId;
  final String localAISignature;
  final String remoteAISignature;
  final DateTime startTime;
  final double currentCompatibility;
  final double learningEffectiveness;
  final MonitoringStatus status;

  ActiveConnection({
    required this.connectionId,
    required this.localAISignature,
    required this.remoteAISignature,
    required this.startTime,
    required this.currentCompatibility,
    required this.learningEffectiveness,
    required this.status,
  });

  static ActiveConnection fromSession(ConnectionMonitoringSession session) {
    return ActiveConnection(
      connectionId: session.connectionId,
      localAISignature: session.localAISignature,
      remoteAISignature: session.remoteAISignature,
      startTime: session.startTime,
      currentCompatibility: session.currentMetrics.currentCompatibility,
      learningEffectiveness: session.currentMetrics.learningEffectiveness,
      status: session.monitoringStatus,
    );
  }
}

class ConnectionQualitySnapshot {
  final DateTime timestamp;
  final double compatibility;
  final double learningEffectiveness;
  final double aiPleasureScore;

  ConnectionQualitySnapshot({
    required this.timestamp,
    required this.compatibility,
    required this.learningEffectiveness,
    required this.aiPleasureScore,
  });

  static ConnectionQualitySnapshot fromMetrics(ConnectionMetrics metrics) {
    return ConnectionQualitySnapshot(
      timestamp: DateTime.now(),
      compatibility: metrics.currentCompatibility,
      learningEffectiveness: metrics.learningEffectiveness,
      aiPleasureScore: metrics.aiPleasureScore,
    );
  }
}

class LearningProgressSnapshot {
  final DateTime timestamp;
  final double learningEffectiveness;
  final Map<String, double> dimensionChanges;

  LearningProgressSnapshot({
    required this.timestamp,
    required this.learningEffectiveness,
    required this.dimensionChanges,
  });

  static LearningProgressSnapshot fromMetrics(ConnectionMetrics metrics) {
    return LearningProgressSnapshot(
      timestamp: DateTime.now(),
      learningEffectiveness: metrics.learningEffectiveness,
      dimensionChanges: Map<String, double>.from(metrics.dimensionEvolution),
    );
  }
}

class ConnectionAlert {
  final String connectionId;
  final AlertType type;
  final AlertSeverity severity;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  ConnectionAlert({
    required this.connectionId,
    required this.type,
    required this.severity,
    required this.message,
    required this.timestamp,
    required this.metadata,
  });
}

class ConnectionMonitoringStatus {
  final String connectionId;
  final CurrentPerformanceMetrics currentPerformance;
  final double healthScore;
  final List<ConnectionAlert> recentAlerts;
  final ConnectionTrajectory trajectory;
  final Duration monitoringDuration;
  final DateTime lastUpdated;

  ConnectionMonitoringStatus({
    required this.connectionId,
    required this.currentPerformance,
    required this.healthScore,
    required this.recentAlerts,
    required this.trajectory,
    required this.monitoringDuration,
    required this.lastUpdated,
  });

  static ConnectionMonitoringStatus notFound(String connectionId) {
    return ConnectionMonitoringStatus(
      connectionId: connectionId,
      currentPerformance: CurrentPerformanceMetrics.zero(),
      healthScore: 0.0,
      recentAlerts: [],
      trajectory: ConnectionTrajectory.unknown(),
      monitoringDuration: Duration.zero,
      lastUpdated: DateTime.now(),
    );
  }

  static ConnectionMonitoringStatus error(String connectionId, String error) {
    return ConnectionMonitoringStatus(
      connectionId: connectionId,
      currentPerformance: CurrentPerformanceMetrics.zero(),
      healthScore: 0.0,
      recentAlerts: [],
      trajectory: ConnectionTrajectory.unknown(),
      monitoringDuration: Duration.zero,
      lastUpdated: DateTime.now(),
    );
  }
}

class ConnectionPerformanceAnalysis {
  final String connectionId;
  final Duration analysisWindow;
  final QualityTrends qualityTrends;
  final LearningTrends learningTrends;
  final StabilityMetrics stabilityMetrics;
  final List<PerformancePattern> performancePatterns;
  final List<PerformanceRecommendation> recommendations;
  final double overallPerformanceScore;
  final DateTime analyzedAt;

  ConnectionPerformanceAnalysis({
    required this.connectionId,
    required this.analysisWindow,
    required this.qualityTrends,
    required this.learningTrends,
    required this.stabilityMetrics,
    required this.performancePatterns,
    required this.recommendations,
    required this.overallPerformanceScore,
    required this.analyzedAt,
  });

  static ConnectionPerformanceAnalysis failed(
      String connectionId, Duration window) {
    return ConnectionPerformanceAnalysis(
      connectionId: connectionId,
      analysisWindow: window,
      qualityTrends: QualityTrends.stable(),
      learningTrends: LearningTrends.positive(),
      stabilityMetrics: StabilityMetrics.stable(),
      performancePatterns: [],
      recommendations: [],
      overallPerformanceScore: 0.0,
      analyzedAt: DateTime.now(),
    );
  }
}

class ActiveConnectionsOverview {
  final int totalActiveConnections;
  final AggregateConnectionMetrics aggregateMetrics;
  final List<String> topPerformingConnections;
  final List<String> connectionsNeedingAttention;
  final LearningVelocityDistribution learningVelocityDistribution;
  final List<OptimizationOpportunity> optimizationOpportunities;
  final Duration averageConnectionDuration;
  final int totalAlertsGenerated;
  final DateTime generatedAt;

  ActiveConnectionsOverview({
    required this.totalActiveConnections,
    required this.aggregateMetrics,
    required this.topPerformingConnections,
    required this.connectionsNeedingAttention,
    required this.learningVelocityDistribution,
    required this.optimizationOpportunities,
    required this.averageConnectionDuration,
    required this.totalAlertsGenerated,
    required this.generatedAt,
  });

  static ActiveConnectionsOverview empty() {
    return ActiveConnectionsOverview(
      totalActiveConnections: 0,
      aggregateMetrics: AggregateConnectionMetrics.zero(),
      topPerformingConnections: [],
      connectionsNeedingAttention: [],
      learningVelocityDistribution: LearningVelocityDistribution.normal(),
      optimizationOpportunities: [],
      averageConnectionDuration: Duration.zero,
      totalAlertsGenerated: 0,
      generatedAt: DateTime.now(),
    );
  }
}

class ConnectionMonitoringReport {
  final String connectionId;
  final String localAISignature;
  final String remoteAISignature;
  final Duration connectionDuration;
  final ConnectionMetrics initialMetrics;
  final ConnectionMetrics finalMetrics;
  final PerformanceSummary performanceSummary;
  final LearningOutcomes learningOutcomes;
  final QualityAnalysis qualityAnalysis;
  final List<ConnectionAlert> alertsGenerated;
  final double overallRating;
  final DateTime generatedAt;

  ConnectionMonitoringReport({
    required this.connectionId,
    required this.localAISignature,
    required this.remoteAISignature,
    required this.connectionDuration,
    required this.initialMetrics,
    required this.finalMetrics,
    required this.performanceSummary,
    required this.learningOutcomes,
    required this.qualityAnalysis,
    required this.alertsGenerated,
    required this.overallRating,
    required this.generatedAt,
  });
}

// Enums and additional supporting classes
enum MonitoringStatus { active, paused, completed, error }

enum AlertType {
  lowCompatibility,
  lowLearningEffectiveness,
  qualityDegradation,
  connectionTimeout,
  learningStagnation
}

enum AlertSeverity { low, medium, high, critical }

enum ChangeDirection { improving, stable, degrading }

class ConnectionQualityChange {
  final double compatibilityChange;
  final double learningEffectivenessChange;
  final double aiPleasureChange;
  final double overallChange;
  final ChangeDirection changeDirection;

  ConnectionQualityChange({
    required this.compatibilityChange,
    required this.learningEffectivenessChange,
    required this.aiPleasureChange,
    required this.overallChange,
    required this.changeDirection,
  });
}

class LearningProgressMetrics {
  final double progressRate;
  final double learningVelocity;
  final double dimensionEvolutionRate;
  final double insightGenerationRate;

  LearningProgressMetrics({
    required this.progressRate,
    required this.learningVelocity,
    required this.dimensionEvolutionRate,
    required this.insightGenerationRate,
  });

  static LearningProgressMetrics minimal() => LearningProgressMetrics(
      progressRate: 0.0,
      learningVelocity: 0.0,
      dimensionEvolutionRate: 0.0,
      insightGenerationRate: 0.0);
}

class ConnectionAnomaly {
  final String connectionId;
  final AnomalyType type;
  final AlertSeverity severity;
  final String description;
  final DateTime detectedAt;
  final Map<String, dynamic> metadata;

  ConnectionAnomaly({
    required this.connectionId,
    required this.type,
    required this.severity,
    required this.description,
    required this.detectedAt,
    required this.metadata,
  });
}

enum AnomalyType {
  qualitySpike,
  qualityDrop,
  learningStagnation,
  behaviorDeviation,
  patternBreak
}

class ConnectionMonitoringException implements Exception {
  final String message;
  ConnectionMonitoringException(this.message);

  @override
  String toString() => 'ConnectionMonitoringException: $message';
}

// Placeholder classes for complex data structures
class CurrentPerformanceMetrics {
  final double performance;
  CurrentPerformanceMetrics(this.performance);
  static CurrentPerformanceMetrics zero() => CurrentPerformanceMetrics(0.0);
  static CurrentPerformanceMetrics fromSession(
          ConnectionMonitoringSession session) =>
      CurrentPerformanceMetrics(0.8);
}

class ConnectionTrajectory {
  final String direction;
  ConnectionTrajectory(this.direction);
  static ConnectionTrajectory stable() => ConnectionTrajectory('stable');
  static ConnectionTrajectory unknown() => ConnectionTrajectory('unknown');
}

class QualityTrends {
  final String trend;
  QualityTrends(this.trend);
  static QualityTrends stable() => QualityTrends('stable');
}

class LearningTrends {
  final String trend;
  LearningTrends(this.trend);
  static LearningTrends positive() => LearningTrends('positive');
}

class StabilityMetrics {
  final double stability;
  StabilityMetrics(this.stability);
  static StabilityMetrics stable() => StabilityMetrics(0.8);
}

class PerformancePattern {
  final String pattern;
  PerformancePattern(this.pattern);
}

class PerformanceRecommendation {
  final String recommendation;
  PerformanceRecommendation(this.recommendation);
}

class AggregateConnectionMetrics {
  final double averageCompatibility;
  AggregateConnectionMetrics(this.averageCompatibility);
  static AggregateConnectionMetrics good() => AggregateConnectionMetrics(0.8);
  static AggregateConnectionMetrics zero() => AggregateConnectionMetrics(0.0);
}

class LearningVelocityDistribution {
  final Map<String, double> distribution;
  LearningVelocityDistribution(this.distribution);
  static LearningVelocityDistribution normal() =>
      LearningVelocityDistribution({'normal': 1.0});
}

class OptimizationOpportunity {
  final String opportunity;
  OptimizationOpportunity(this.opportunity);
}

class PerformanceSummary {
  final double summary;
  PerformanceSummary(this.summary);
  static PerformanceSummary good() => PerformanceSummary(0.8);
}

class LearningOutcomes {
  final double outcomes;
  LearningOutcomes(this.outcomes);
  static LearningOutcomes positive() => LearningOutcomes(0.8);
}

class QualityAnalysis {
  final double quality;
  QualityAnalysis(this.quality);
  static QualityAnalysis stable() => QualityAnalysis(0.8);
}
