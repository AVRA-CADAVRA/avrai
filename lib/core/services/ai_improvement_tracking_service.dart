import 'dart:async';
import 'dart:developer' as developer;
import 'package:get_storage/get_storage.dart';
import 'package:spots/core/services/storage_service.dart';

/// Service for tracking and aggregating AI improvement metrics
/// Provides data for AI Self-Improvement Visibility UI
class AIImprovementTrackingService {
  static const String _logName = 'AIImprovementTrackingService';
  static const String _storageKey = 'ai_improvement_metrics';
  static const String _historyKey = 'ai_improvement_history';

  final GetStorage _storage;

  /// Constructor with dependency injection for storage
  ///
  /// [storage] - Optional GetStorage instance. If not provided, uses StorageService singleton.
  /// This allows for testability by injecting mock storage in tests.
  AIImprovementTrackingService({GetStorage? storage})
      : _storage = storage ?? StorageService.instance.defaultStorage;
  final StreamController<AIImprovementMetrics> _metricsController =
      StreamController<AIImprovementMetrics>.broadcast();

  Timer? _trackingTimer;
  AIImprovementMetrics? _currentMetrics;
  final List<AIImprovementSnapshot> _historySnapshots = [];

  /// Stream of improvement metrics updates
  Stream<AIImprovementMetrics> get metricsStream => _metricsController.stream;

  /// Initialize improvement tracking
  Future<void> initialize() async {
    try {
      // #region agent log
      developer.log('Initializing AI improvement tracking', name: _logName);
      // #endregion

      // Load stored history
      await _loadStoredHistory();

      // Start periodic tracking (every 5 minutes)
      _trackingTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => _captureImprovementSnapshot(),
      );

      // #region agent log
      developer.log('Started periodic tracking timer (5 minute intervals)', name: _logName);
      // #endregion

      // Capture initial snapshot
      await _captureImprovementSnapshot();

      // #region agent log
      developer.log('AI improvement tracking initialized: ${_historySnapshots.length} history snapshots loaded', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error initializing tracking: $e', name: _logName);
      // #endregion
    }
  }

  /// Get current improvement metrics
  Future<AIImprovementMetrics> getCurrentMetrics(String userId) async {
    // Check in-memory cache first
    if (_currentMetrics != null && _currentMetrics!.userId == userId) {
      // #region agent log
      developer.log('Returning cached metrics for user: $userId', name: _logName);
      // #endregion
      return _currentMetrics!;
    }

    // Try to load from storage
    try {
      final stored = _storage.read<Map<String, dynamic>>(_storageKey);
      if (stored != null && stored['userId'] == userId) {
        // #region agent log
        developer.log('Loaded metrics from storage for user: $userId', name: _logName);
        // #endregion
        _currentMetrics = AIImprovementMetrics(
          userId: stored['userId'] as String,
          dimensionScores: Map<String, double>.from(stored['dimensionScores'] as Map),
          performanceScores: Map<String, double>.from(stored['performanceScores'] as Map),
          overallScore: (stored['overallScore'] as num).toDouble(),
          improvementRate: (stored['improvementRate'] as num).toDouble(),
          totalImprovements: stored['totalImprovements'] as int,
          lastUpdated: DateTime.parse(stored['lastUpdated'] as String),
        );
        return _currentMetrics!;
      }
    } catch (e) {
      // #region agent log
      developer.log('Error loading metrics from storage: $e, calculating new metrics', name: _logName);
      // #endregion
    }

    // Calculate new metrics if not found
    final metrics = await _calculateMetrics(userId);
    
    // Save to storage for future access
    await _saveCurrentMetrics(metrics);
    
    return metrics;
  }

  /// Get improvement history for a time period
  List<AIImprovementSnapshot> getHistory({
    required String userId,
    Duration? timeWindow,
  }) {
    var filtered = _historySnapshots.where((s) => s.userId == userId).toList();

    if (timeWindow != null) {
      final cutoff = DateTime.now().subtract(timeWindow);
      filtered = filtered.where((s) => s.timestamp.isAfter(cutoff)).toList();
    }

    return filtered..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Get improvement milestones
  List<ImprovementMilestone> getMilestones(String userId) {
    // #region agent log
    developer.log('Getting milestones for user: $userId', name: _logName);
    // #endregion
    
    final milestones = <ImprovementMilestone>[];
    final history = getHistory(userId: userId);

    if (history.isEmpty) {
      // #region agent log
      developer.log('No history found for user: $userId, returning empty milestones', name: _logName);
      // #endregion
      return milestones;
    }

    // Detect significant improvements
    for (int i = 1; i < history.length; i++) {
      final current = history[i - 1];
      final previous = history[i];

      // Check each dimension for significant improvement (>10%)
      current.dimensions.forEach((dimension, score) {
        final prevScore = previous.dimensions[dimension] ?? 0.0;
        final improvement = score - prevScore;

        if (improvement > 0.1) {
          milestones.add(ImprovementMilestone(
            dimension: dimension,
            improvement: improvement,
            fromScore: prevScore,
            toScore: score,
            timestamp: current.timestamp,
            description: _generateMilestoneDescription(dimension, improvement),
          ));
        }
      });
    }

    // #region agent log
    developer.log('Found ${milestones.length} milestones for user: $userId', name: _logName);
    // #endregion

    return milestones..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// Calculate accuracy metrics
  Future<AccuracyMetrics> getAccuracyMetrics(String userId) async {
    // Mock data for now - would integrate with actual recommendation tracking
    return AccuracyMetrics(
      recommendationAcceptanceRate: 0.78,
      predictionAccuracy: 0.85,
      userSatisfactionScore: 0.82,
      averageConfidence: 0.88,
      totalRecommendations: 245,
      acceptedRecommendations: 191,
      timestamp: DateTime.now(),
    );
  }

  /// Capture current state as a snapshot
  Future<void> _captureImprovementSnapshot() async {
    try {
      // Would integrate with actual user context
      // For now, using a default user ID
      final userId = 'current_user';

      // #region agent log
      developer.log('Capturing improvement snapshot for user: $userId', name: _logName);
      // #endregion

      final metrics = await _calculateMetrics(userId);

      final snapshot = AIImprovementSnapshot(
        userId: userId,
        dimensions: metrics.dimensionScores,
        overallScore: metrics.overallScore,
        timestamp: DateTime.now(),
      );

      _historySnapshots.add(snapshot);

      // Keep only last 1000 snapshots
      final beforeTrim = _historySnapshots.length;
      if (_historySnapshots.length > 1000) {
        _historySnapshots.removeAt(0);
      }

      // #region agent log
      developer.log('Snapshot captured: overallScore=${snapshot.overallScore.toStringAsFixed(2)}, dimensions=${snapshot.dimensions.length}, historySize: $beforeTrim -> ${_historySnapshots.length}', name: _logName);
      // #endregion

      // Save to storage
      await _saveHistory();

      // Notify listeners
      _metricsController.add(metrics);
      
      // #region agent log
      developer.log('Snapshot saved and metrics broadcast to ${_metricsController.hasListener ? "listeners" : "no listeners"}', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error capturing snapshot: $e', name: _logName);
      // #endregion
    }
  }

  /// Calculate current improvement metrics
  Future<AIImprovementMetrics> _calculateMetrics(String userId) async {
    try {
      // Mock implementation - would integrate with actual systems
      final dimensionScores = <String, double>{
        'algorithm_efficiency': 0.85,
        'learning_rate_optimization': 0.82,
        'pattern_recognition_accuracy': 0.88,
        'prediction_precision': 0.85,
        'collaboration_effectiveness': 0.79,
        'adaptation_speed': 0.83,
        'creativity_level': 0.76,
        'problem_solving_capability': 0.81,
        'user_preference_understanding': 0.87,
        'recommendation_accuracy': 0.84,
      };

      final performanceScores = <String, double>{
        'accuracy': 0.85,
        'speed': 0.88,
        'efficiency': 0.83,
        'adaptability': 0.81,
        'creativity': 0.76,
        'collaboration': 0.79,
      };

      final overallScore =
          dimensionScores.values.fold(0.0, (sum, score) => sum + score) /
              dimensionScores.length;

      final metrics = AIImprovementMetrics(
        userId: userId,
        dimensionScores: dimensionScores,
        performanceScores: performanceScores,
        overallScore: overallScore,
        improvementRate: 0.05, // 5% improvement rate
        totalImprovements:
            _historySnapshots.where((s) => s.userId == userId).length,
        lastUpdated: DateTime.now(),
      );

      _currentMetrics = metrics;
      
      // Save to storage
      await _saveCurrentMetrics(metrics);
      
      // #region agent log
      developer.log('Calculated metrics for user: $userId, overallScore: ${metrics.overallScore.toStringAsFixed(2)}, dimensions: ${metrics.dimensionScores.length}', name: _logName);
      // #endregion
      
      return metrics;
    } catch (e) {
      // #region agent log
      developer.log('Error calculating metrics: $e', name: _logName);
      // #endregion
      return AIImprovementMetrics.empty(userId);
    }
  }
  
  /// Save current metrics to storage
  Future<void> _saveCurrentMetrics(AIImprovementMetrics metrics) async {
    try {
      await _storage.write(_storageKey, {
        'userId': metrics.userId,
        'dimensionScores': metrics.dimensionScores,
        'performanceScores': metrics.performanceScores,
        'overallScore': metrics.overallScore,
        'improvementRate': metrics.improvementRate,
        'totalImprovements': metrics.totalImprovements,
        'lastUpdated': metrics.lastUpdated.toIso8601String(),
      });
      // #region agent log
      developer.log('Saved current metrics to storage for user: ${metrics.userId}', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error saving current metrics: $e', name: _logName);
      // #endregion
    }
  }

  /// Load stored history from storage
  Future<void> _loadStoredHistory() async {
    try {
      // #region agent log
      developer.log('Loading stored history from storage key: $_historyKey', name: _logName);
      // #endregion
      
      final stored = _storage.read<List>(_historyKey);
      if (stored != null) {
        _historySnapshots.clear();
        for (final item in stored) {
          if (item is Map<String, dynamic>) {
            _historySnapshots.add(AIImprovementSnapshot.fromJson(item));
          }
        }
        // #region agent log
        developer.log('Loaded ${_historySnapshots.length} history snapshots from storage', name: _logName);
        // #endregion
      } else {
        // #region agent log
        developer.log('No stored history found, starting with empty history', name: _logName);
        // #endregion
      }
    } catch (e) {
      // #region agent log
      developer.log('Error loading history: $e', name: _logName);
      // #endregion
    }
  }

  /// Save history to storage
  Future<void> _saveHistory() async {
    try {
      final data = _historySnapshots.map((s) => s.toJson()).toList();
      await _storage.write(_historyKey, data);
      // #region agent log
      developer.log('Saved ${data.length} history snapshots to storage key: $_historyKey', name: _logName);
      // #endregion
    } catch (e) {
      // #region agent log
      developer.log('Error saving history: $e', name: _logName);
      // #endregion
    }
  }

  /// Generate milestone description
  String _generateMilestoneDescription(String dimension, double improvement) {
    final percentage = (improvement * 100).toStringAsFixed(0);
    final dimensionName = dimension.replaceAll('_', ' ').toUpperCase();
    return 'Improved $dimensionName by $percentage%';
  }

  /// Dispose resources
  void dispose() {
    _trackingTimer?.cancel();
    _metricsController.close();
  }
}

/// AI improvement metrics
class AIImprovementMetrics {
  final String userId;
  final Map<String, double> dimensionScores;
  final Map<String, double> performanceScores;
  final double overallScore;
  final double improvementRate;
  final int totalImprovements;
  final DateTime lastUpdated;

  AIImprovementMetrics({
    required this.userId,
    required this.dimensionScores,
    required this.performanceScores,
    required this.overallScore,
    required this.improvementRate,
    required this.totalImprovements,
    required this.lastUpdated,
  });

  static AIImprovementMetrics empty(String userId) {
    return AIImprovementMetrics(
      userId: userId,
      dimensionScores: {},
      performanceScores: {},
      overallScore: 0.5,
      improvementRate: 0.0,
      totalImprovements: 0,
      lastUpdated: DateTime.now(),
    );
  }
}

/// Snapshot of AI improvement state at a point in time
class AIImprovementSnapshot {
  final String userId;
  final Map<String, double> dimensions;
  final double overallScore;
  final DateTime timestamp;

  AIImprovementSnapshot({
    required this.userId,
    required this.dimensions,
    required this.overallScore,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'dimensions': dimensions,
      'overallScore': overallScore,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static AIImprovementSnapshot fromJson(Map<String, dynamic> json) {
    return AIImprovementSnapshot(
      userId: json['userId'] as String,
      dimensions: Map<String, double>.from(json['dimensions'] as Map),
      overallScore: (json['overallScore'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

/// Improvement milestone
class ImprovementMilestone {
  final String dimension;
  final double improvement;
  final double fromScore;
  final double toScore;
  final DateTime timestamp;
  final String description;

  ImprovementMilestone({
    required this.dimension,
    required this.improvement,
    required this.fromScore,
    required this.toScore,
    required this.timestamp,
    required this.description,
  });
}

/// Accuracy metrics for recommendation tracking
class AccuracyMetrics {
  final double recommendationAcceptanceRate;
  final double predictionAccuracy;
  final double userSatisfactionScore;
  final double averageConfidence;
  final int totalRecommendations;
  final int acceptedRecommendations;
  final DateTime timestamp;

  AccuracyMetrics({
    required this.recommendationAcceptanceRate,
    required this.predictionAccuracy,
    required this.userSatisfactionScore,
    required this.averageConfidence,
    required this.totalRecommendations,
    required this.acceptedRecommendations,
    required this.timestamp,
  });

  double get overallAccuracy =>
      (recommendationAcceptanceRate +
          predictionAccuracy +
          userSatisfactionScore) /
      3;
}
