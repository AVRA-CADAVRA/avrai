import 'dart:convert';
import 'dart:typed_data';
import 'package:avrai/core/constants/vibe_constants.dart';

/// OUR_GUTS.md: "AI2AI connection tracking that measures learning effectiveness and AI pleasure"
/// Tracks the quality and effectiveness of AI2AI personality connections
class ConnectionMetrics {
  final String connectionId;
  final String localAISignature;
  final String remoteAISignature;
  final double initialCompatibility;
  final double currentCompatibility;
  final double learningEffectiveness;
  final double aiPleasureScore;
  final Duration connectionDuration;
  final DateTime startTime;
  final DateTime? endTime;
  final ConnectionStatus status;
  final Map<String, dynamic> learningOutcomes;
  final List<InteractionEvent> interactionHistory;
  final Map<String, double> dimensionEvolution;

  // Channel binding (Security enhancement)
  /// Handshake hash from Signal Protocol key exchange (X3DH + PQXDH)
  /// Used to verify channel binding and prevent man-in-the-middle attacks
  final Uint8List? handshakeHash;

  // AI Agent Identity Verification (Security enhancement)
  /// Local AI agent fingerprint (from Signal Protocol identity key)
  /// Used for identity verification and trust establishment
  final String? localAgentFingerprint;

  /// Remote AI agent fingerprint (from Signal Protocol identity key)
  /// Used for identity verification and trust establishment
  final String? remoteAgentFingerprint;

  ConnectionMetrics({
    required this.connectionId,
    required this.localAISignature,
    required this.remoteAISignature,
    required this.initialCompatibility,
    required this.currentCompatibility,
    required this.learningEffectiveness,
    required this.aiPleasureScore,
    required this.connectionDuration,
    required this.startTime,
    this.endTime,
    required this.status,
    required this.learningOutcomes,
    required this.interactionHistory,
    required this.dimensionEvolution,
    this.handshakeHash,
    this.localAgentFingerprint,
    this.remoteAgentFingerprint,
  });

  /// Create initial connection metrics when AI2AI connection starts
  factory ConnectionMetrics.initial({
    required String localAISignature,
    required String remoteAISignature,
    required double compatibility,
  }) {
    final connectionId =
        _generateConnectionId(localAISignature, remoteAISignature);

    return ConnectionMetrics(
      connectionId: connectionId,
      localAISignature: localAISignature,
      remoteAISignature: remoteAISignature,
      initialCompatibility: compatibility,
      currentCompatibility: compatibility,
      learningEffectiveness: 0.0, // Will grow during interaction
      aiPleasureScore: 0.5, // Starting neutral
      connectionDuration: Duration.zero,
      startTime: DateTime.now(),
      status: ConnectionStatus.establishing,
      learningOutcomes: {
        'insights_gained': 0,
        'dimensions_evolved': <String>[],
        'new_patterns_discovered': 0,
        'successful_exchanges': 0,
        'failed_exchanges': 0,
      },
      interactionHistory: [],
      dimensionEvolution: {},
      handshakeHash: null, // Will be set during Signal Protocol key exchange
      localAgentFingerprint:
          null, // Will be set during connection establishment
      remoteAgentFingerprint:
          null, // Will be set during connection establishment
    );
  }

  /// Update connection metrics during active AI2AI interaction
  ConnectionMetrics updateDuringInteraction({
    double? newCompatibility,
    double? learningEffectiveness,
    double? aiPleasureScore,
    Map<String, dynamic>? additionalOutcomes,
    InteractionEvent? newInteraction,
    Map<String, double>? dimensionChanges,
    Uint8List? handshakeHash,
    String? localAgentFingerprint,
    String? remoteAgentFingerprint,
  }) {
    final updatedHistory = List<InteractionEvent>.from(interactionHistory);
    if (newInteraction != null) {
      updatedHistory.add(newInteraction);
    }

    final updatedOutcomes = Map<String, dynamic>.from(learningOutcomes);
    additionalOutcomes?.forEach((key, value) {
      if (updatedOutcomes.containsKey(key) && value is num) {
        updatedOutcomes[key] = (updatedOutcomes[key] as num) + value;
      } else if (updatedOutcomes.containsKey(key) && value is List) {
        (updatedOutcomes[key] as List).addAll(value);
      } else {
        updatedOutcomes[key] = value;
      }
    });

    final updatedDimensionEvolution =
        Map<String, double>.from(dimensionEvolution);
    dimensionChanges?.forEach((dimension, change) {
      updatedDimensionEvolution[dimension] =
          (updatedDimensionEvolution[dimension] ?? 0.0) + change;
    });

    return ConnectionMetrics(
      connectionId: connectionId,
      localAISignature: localAISignature,
      remoteAISignature: remoteAISignature,
      initialCompatibility: initialCompatibility,
      currentCompatibility: newCompatibility ?? currentCompatibility,
      learningEffectiveness:
          learningEffectiveness ?? this.learningEffectiveness,
      aiPleasureScore: aiPleasureScore ?? this.aiPleasureScore,
      connectionDuration: DateTime.now().difference(startTime),
      startTime: startTime,
      endTime: endTime,
      status: status,
      learningOutcomes: updatedOutcomes,
      interactionHistory: updatedHistory,
      dimensionEvolution: updatedDimensionEvolution,
      handshakeHash: handshakeHash ?? this.handshakeHash,
      localAgentFingerprint:
          localAgentFingerprint ?? this.localAgentFingerprint,
      remoteAgentFingerprint:
          remoteAgentFingerprint ?? this.remoteAgentFingerprint,
    );
  }

  /// Complete the connection and calculate final metrics
  ConnectionMetrics complete({
    required ConnectionStatus finalStatus,
    String? completionReason,
  }) {
    final totalDuration = DateTime.now().difference(startTime);
    final finalLearningEffectiveness = _calculateFinalLearningEffectiveness();
    final finalAIPleasureScore = _calculateFinalAIPleasureScore();

    final completionOutcomes = Map<String, dynamic>.from(learningOutcomes);
    completionOutcomes['completion_reason'] =
        completionReason ?? 'normal_completion';
    completionOutcomes['total_duration_seconds'] = totalDuration.inSeconds;
    completionOutcomes['final_learning_effectiveness'] =
        finalLearningEffectiveness;
    completionOutcomes['final_ai_pleasure'] = finalAIPleasureScore;

    return ConnectionMetrics(
      connectionId: connectionId,
      localAISignature: localAISignature,
      remoteAISignature: remoteAISignature,
      initialCompatibility: initialCompatibility,
      currentCompatibility: currentCompatibility,
      learningEffectiveness: finalLearningEffectiveness,
      aiPleasureScore: finalAIPleasureScore,
      connectionDuration: totalDuration,
      startTime: startTime,
      endTime: DateTime.now(),
      status: finalStatus,
      learningOutcomes: completionOutcomes,
      interactionHistory: interactionHistory,
      dimensionEvolution: dimensionEvolution,
      handshakeHash: handshakeHash,
      localAgentFingerprint: localAgentFingerprint,
      remoteAgentFingerprint: remoteAgentFingerprint,
    );
  }

  /// Get quality score (average of learning effectiveness and AI pleasure)
  ///
  /// Used for quality-based session management and key rotation decisions.
  double get qualityScore => (learningEffectiveness + aiPleasureScore) / 2.0;

  /// Check if connection should continue based on quality metrics
  bool get shouldContinue {
    // Connection should continue if it's providing value
    if (learningEffectiveness >= VibeConstants.minLearningEffectiveness &&
        aiPleasureScore >= VibeConstants.minAIPleasureScore) {
      return true;
    }

    // Even low-quality connections should run for minimum duration
    if (connectionDuration.inSeconds <
        VibeConstants.minInteractionDurationSeconds) {
      return true;
    }

    // Stop if connection quality is very poor
    return false;
  }

  /// Check if connection has reached maximum duration
  bool get hasReachedMaxDuration {
    return connectionDuration.inSeconds >=
        VibeConstants.maxInteractionDurationSeconds;
  }

  /// Calculate compatibility evolution during the connection
  double get compatibilityEvolution {
    return currentCompatibility - initialCompatibility;
  }

  /// Get connection quality rating (poor, fair, good, excellent)
  String get qualityRating {
    final averageScore = (learningEffectiveness + aiPleasureScore) / 2.0;

    if (averageScore >= 0.8) return 'excellent';
    if (averageScore >= 0.6) return 'good';
    if (averageScore >= 0.4) return 'fair';
    return 'poor';
  }

  /// Get most impactful learning outcomes
  List<String> getMostImpactfulLearnings() {
    final impactfulLearnings = <String>[];

    // Check for significant dimension evolution
    dimensionEvolution.forEach((dimension, change) {
      if (change.abs() >= 0.1) {
        impactfulLearnings
            .add('$dimension evolved by ${(change * 100).toStringAsFixed(1)}%');
      }
    });

    // Check for other significant outcomes
    final insightsGained = learningOutcomes['insights_gained'] as int? ?? 0;
    if (insightsGained > 0) {
      impactfulLearnings.add('$insightsGained new insights gained');
    }

    final patternsDiscovered =
        learningOutcomes['new_patterns_discovered'] as int? ?? 0;
    if (patternsDiscovered > 0) {
      impactfulLearnings.add('$patternsDiscovered new patterns discovered');
    }

    return impactfulLearnings.take(3).toList();
  }

  /// Get connection summary for analytics
  Map<String, dynamic> getSummary() {
    return {
      'connection_id': connectionId.substring(0, 8),
      'duration_seconds': connectionDuration.inSeconds,
      'initial_compatibility': (initialCompatibility * 100).round(),
      'final_compatibility': (currentCompatibility * 100).round(),
      'compatibility_evolution': (compatibilityEvolution * 100).round(),
      'learning_effectiveness': (learningEffectiveness * 100).round(),
      'ai_pleasure_score': (aiPleasureScore * 100).round(),
      'quality_rating': qualityRating,
      'status': status.toString().split('.').last,
      'interactions_count': interactionHistory.length,
      'dimensions_evolved': dimensionEvolution.keys.length,
      'impactful_learnings': getMostImpactfulLearnings(),
      'successful_exchanges': learningOutcomes['successful_exchanges'],
      'failed_exchanges': learningOutcomes['failed_exchanges'],
    };
  }

  /// Validate connection metrics integrity
  bool validateIntegrity() {
    // Check basic constraints
    if (initialCompatibility < 0.0 || initialCompatibility > 1.0) return false;
    if (currentCompatibility < 0.0 || currentCompatibility > 1.0) return false;
    if (learningEffectiveness < 0.0 || learningEffectiveness > 1.0) {
      return false;
    }
    if (aiPleasureScore < 0.0 || aiPleasureScore > 1.0) return false;

    // Check temporal consistency
    if (endTime != null && endTime!.isBefore(startTime)) return false;

    // Check that successful + failed exchanges = total interactions
    final successfulExchanges =
        learningOutcomes['successful_exchanges'] as int? ?? 0;
    final failedExchanges = learningOutcomes['failed_exchanges'] as int? ?? 0;
    final totalExchanges = successfulExchanges + failedExchanges;

    // Allow some tolerance for ongoing connections
    if (status == ConnectionStatus.completed &&
        totalExchanges != interactionHistory.length) {
      return false;
    }

    return true;
  }

  // Private helper methods
  double _calculateFinalLearningEffectiveness() {
    final successfulExchanges =
        learningOutcomes['successful_exchanges'] as int? ?? 0;
    final totalExchanges = interactionHistory.length;

    if (totalExchanges == 0) return 0.0;

    final successRate = successfulExchanges / totalExchanges;
    final dimensionEvolutionScore = dimensionEvolution.values.isNotEmpty
        ? dimensionEvolution.values
                .map((v) => v.abs())
                .reduce((a, b) => a + b) /
            dimensionEvolution.length
        : 0.0;

    // Combine success rate with actual learning outcomes
    return ((successRate * 0.6) +
            (dimensionEvolutionScore.clamp(0.0, 1.0) * 0.4))
        .clamp(0.0, 1.0);
  }

  double _calculateFinalAIPleasureScore() {
    // AI pleasure is based on learning quality and compatibility growth
    final compatibilityGrowth =
        (compatibilityEvolution + 1.0) / 2.0; // Normalize to 0-1
    final learningQuality = learningEffectiveness;
    final durationBonus = connectionDuration.inSeconds >=
            VibeConstants.minInteractionDurationSeconds
        ? 0.1
        : 0.0;

    return ((compatibilityGrowth * 0.4) +
            (learningQuality * 0.5) +
            durationBonus)
        .clamp(0.0, 1.0);
  }

  static String _generateConnectionId(String localSig, String remoteSig) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final combined = '$localSig:$remoteSig:$timestamp';
    return combined.hashCode.abs().toString();
  }

  /// Convert to JSON for storage and analytics
  Map<String, dynamic> toJson() {
    return {
      'connection_id': connectionId,
      'local_ai_signature': localAISignature,
      'remote_ai_signature': remoteAISignature,
      'initial_compatibility': initialCompatibility,
      'current_compatibility': currentCompatibility,
      'learning_effectiveness': learningEffectiveness,
      'ai_pleasure_score': aiPleasureScore,
      'connection_duration_seconds': connectionDuration.inSeconds,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'status': status.toString(),
      'learning_outcomes': learningOutcomes,
      'interaction_history': interactionHistory.map((e) => e.toJson()).toList(),
      'dimension_evolution': dimensionEvolution,
      'handshake_hash':
          handshakeHash != null ? base64Encode(handshakeHash!.toList()) : null,
      'local_agent_fingerprint': localAgentFingerprint,
      'remote_agent_fingerprint': remoteAgentFingerprint,
    };
  }

  /// Create from JSON storage
  factory ConnectionMetrics.fromJson(Map<String, dynamic> json) {
    return ConnectionMetrics(
      connectionId: json['connection_id'] as String,
      localAISignature: json['local_ai_signature'] as String,
      remoteAISignature: json['remote_ai_signature'] as String,
      initialCompatibility: (json['initial_compatibility'] as num).toDouble(),
      currentCompatibility: (json['current_compatibility'] as num).toDouble(),
      learningEffectiveness: (json['learning_effectiveness'] as num).toDouble(),
      aiPleasureScore: (json['ai_pleasure_score'] as num).toDouble(),
      connectionDuration:
          Duration(seconds: json['connection_duration_seconds'] as int),
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      status: ConnectionStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
        orElse: () => ConnectionStatus.failed,
      ),
      learningOutcomes: Map<String, dynamic>.from(json['learning_outcomes']),
      interactionHistory: (json['interaction_history'] as List)
          .map((e) => InteractionEvent.fromJson(e))
          .toList(),
      dimensionEvolution: Map<String, double>.from(json['dimension_evolution']),
      handshakeHash: json['handshake_hash'] != null
          ? Uint8List.fromList(
              base64Decode(json['handshake_hash'] as String).toList())
          : null,
      localAgentFingerprint: json['local_agent_fingerprint'] as String?,
      remoteAgentFingerprint: json['remote_agent_fingerprint'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConnectionMetrics &&
          runtimeType == other.runtimeType &&
          connectionId == other.connectionId;

  @override
  int get hashCode => connectionId.hashCode;

  @override
  String toString() {
    return 'ConnectionMetrics(id: ${connectionId.substring(0, 8)}, '
        'quality: $qualityRating, duration: ${connectionDuration.inMinutes}m)';
  }
}

/// Status of AI2AI connection
enum ConnectionStatus {
  establishing,
  active,
  learning,
  completing,
  completed,
  failed,
  timeout,
}

/// Individual interaction event within an AI2AI connection
class InteractionEvent {
  final String eventId;
  final InteractionType type;
  final DateTime timestamp;
  final Map<String, dynamic> data;
  final bool successful;
  final String? errorMessage;

  InteractionEvent({
    required this.eventId,
    required this.type,
    required this.timestamp,
    required this.data,
    required this.successful,
    this.errorMessage,
  });

  /// Create successful interaction event
  factory InteractionEvent.success({
    required InteractionType type,
    required Map<String, dynamic> data,
  }) {
    return InteractionEvent(
      eventId: _generateEventId(),
      type: type,
      timestamp: DateTime.now(),
      data: data,
      successful: true,
    );
  }

  /// Create failed interaction event
  factory InteractionEvent.failure({
    required InteractionType type,
    required String errorMessage,
    Map<String, dynamic>? data,
  }) {
    return InteractionEvent(
      eventId: _generateEventId(),
      type: type,
      timestamp: DateTime.now(),
      data: data ?? {},
      successful: false,
      errorMessage: errorMessage,
    );
  }

  static String _generateEventId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'event_id': eventId,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'data': data,
      'successful': successful,
      'error_message': errorMessage,
    };
  }

  factory InteractionEvent.fromJson(Map<String, dynamic> json) {
    return InteractionEvent(
      eventId: json['event_id'] as String,
      type: InteractionType.values.firstWhere(
        (t) => t.toString() == json['type'],
        orElse: () => InteractionType.unknown,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      data: Map<String, dynamic>.from(json['data']),
      successful: json['successful'] as bool,
      errorMessage: json['error_message'] as String?,
    );
  }
}

/// Types of AI2AI interactions
enum InteractionType {
  vibeExchange,
  personalitySharing,
  learningInsight,
  dimensionEvolution,
  patternDiscovery,
  trustBuilding,
  feedbackSharing,
  unknown,
}

/// Chat message in AI2AI communication
class ChatMessage {
  final String messageId;
  final String senderId;
  final String content;
  final ChatMessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.type,
    required this.timestamp,
  });
}

/// Chat message types
enum ChatMessageType { text, vibe, learning, insight }

/// AI2AI chat event types
enum AI2AIChatEventType {
  vibeExchange,
  learningShare,
  insightDiscovery,
  personalityEvolution
}

/// Shared insight types
enum SharedInsightType {
  behavioralPattern,
  preferenceDiscovery,
  compatibilityInsight,
  learningOpportunity
}

/// Shared insight data
class SharedInsight {
  final String insightId;
  final SharedInsightType type;
  final String description;
  final double confidence;
  final DateTime timestamp;

  SharedInsight({
    required this.insightId,
    required this.type,
    required this.description,
    required this.confidence,
    required this.timestamp,
  });
}
