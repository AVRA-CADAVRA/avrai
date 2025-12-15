import 'package:spots/core/constants/vibe_constants.dart';
import 'package:spots/core/models/contextual_personality.dart';

/// OUR_GUTS.md: "AI personality that evolves and learns while preserving privacy"
/// Represents a complete AI personality profile with 12 core dimensions and evolution tracking
/// Phase 2: Expanded from 8 to 12 dimensions for more precise matching
/// Phase 3: Added contextual personality system (core + contexts + timeline)
class PersonalityProfile {
  final String userId;
  final Map<String, double> dimensions; // Current active dimensions
  final Map<String, double> dimensionConfidence;
  final String archetype;
  final double authenticity;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final int evolutionGeneration;
  final Map<String, dynamic> learningHistory;

  // NEW: Phase 3 - Contextual Personality System
  final Map<String, double> corePersonality; // Stable baseline (resists drift)
  final Map<String, ContextualPersonality>
      contexts; // Context-specific adaptations
  final List<LifePhase> evolutionTimeline; // Preserved life phases
  final String? currentPhaseId; // Current life phase
  final bool isInTransition; // Currently transitioning phases?
  final TransitionMetrics? activeTransition; // Active transition metrics

  PersonalityProfile({
    required this.userId,
    required this.dimensions,
    required this.dimensionConfidence,
    required this.archetype,
    required this.authenticity,
    required this.createdAt,
    required this.lastUpdated,
    required this.evolutionGeneration,
    required this.learningHistory,
    // Phase 3: Contextual personality (backward compatible)
    Map<String, double>? corePersonality,
    this.contexts = const {},
    this.evolutionTimeline = const [],
    this.currentPhaseId,
    this.isInTransition = false,
    this.activeTransition,
  }) : corePersonality = corePersonality ??
            dimensions; // Default to dimensions for backward compat

  /// Create initial personality profile with default values
  /// Phase 3: Now includes core personality and initial life phase
  factory PersonalityProfile.initial(String userId) {
    final initialDimensions = <String, double>{};
    final initialConfidence = <String, double>{};

    for (final dimension in VibeConstants.coreDimensions) {
      initialDimensions[dimension] = VibeConstants.defaultDimensionValue;
      initialConfidence[dimension] = 0.0; // No confidence initially
    }

    // Create initial life phase
    final initialPhase = LifePhase.initial(
      userId: userId,
      initialPersonality: Map<String, double>.from(initialDimensions),
    );

    return PersonalityProfile(
      userId: userId,
      dimensions: initialDimensions,
      dimensionConfidence: initialConfidence,
      archetype: 'developing', // Not yet classified
      authenticity: 0.5, // Starting authenticity
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
      evolutionGeneration: 1,
      learningHistory: {
        'total_interactions': 0,
        'successful_ai2ai_connections': 0,
        'learning_sources': <String>[],
        'evolution_milestones': <DateTime>[],
      },
      // Phase 3: Contextual personality
      corePersonality: Map<String, double>.from(initialDimensions),
      contexts: {},
      evolutionTimeline: [initialPhase],
      currentPhaseId: initialPhase.phaseId,
      isInTransition: false,
      activeTransition: null,
    );
  }

  /// Create evolved personality with updated dimensions
  PersonalityProfile evolve({
    Map<String, double>? newDimensions,
    Map<String, double>? newConfidence,
    String? newArchetype,
    double? newAuthenticity,
    Map<String, dynamic>? additionalLearning,
  }) {
    final updatedDimensions = Map<String, double>.from(dimensions);
    final updatedConfidence = Map<String, double>.from(dimensionConfidence);
    final updatedLearning = Map<String, dynamic>.from(learningHistory);

    // Apply new dimensions with bounds checking
    newDimensions?.forEach((dimension, value) {
      updatedDimensions[dimension] = value.clamp(
        VibeConstants.minDimensionValue,
        VibeConstants.maxDimensionValue,
      );
    });

    // Apply new confidence levels
    newConfidence?.forEach((dimension, confidence) {
      updatedConfidence[dimension] = confidence.clamp(0.0, 1.0);
    });

    // Merge additional learning data
    if (additionalLearning != null) {
      additionalLearning.forEach((key, value) {
        if (updatedLearning.containsKey(key) && value is List) {
          // Append to existing lists
          (updatedLearning[key] as List).addAll(value);
        } else if (updatedLearning.containsKey(key) && value is num) {
          // Increment numeric values
          updatedLearning[key] = (updatedLearning[key] as num) + value;
        } else {
          // Replace or add new values
          updatedLearning[key] = value;
        }
      });
    }

    // Add evolution milestone
    (updatedLearning['evolution_milestones'] as List<DateTime>)
        .add(DateTime.now());

    return PersonalityProfile(
      userId: userId,
      dimensions: updatedDimensions,
      dimensionConfidence: updatedConfidence,
      archetype: newArchetype ?? _determineArchetype(updatedDimensions),
      authenticity: newAuthenticity ?? authenticity,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
      evolutionGeneration: evolutionGeneration + 1,
      learningHistory: updatedLearning,
      // Phase 3: Preserve contextual personality state
      corePersonality: corePersonality,
      contexts: contexts,
      evolutionTimeline: evolutionTimeline,
      currentPhaseId: currentPhaseId,
      isInTransition: isInTransition,
      activeTransition: activeTransition,
    );
  }

  // ========================================================================
  // PHASE 3: CONTEXTUAL PERSONALITY METHODS
  // Philosophy: "Your doors stay yours" while allowing contextual adaptation
  // ========================================================================

  /// Get effective personality for a given context
  /// Blends core personality with contextual adaptations
  Map<String, double> getEffectivePersonality([String? contextId]) {
    if (contextId == null || !contexts.containsKey(contextId)) {
      return Map<String, double>.from(corePersonality);
    }

    final context = contexts[contextId]!;
    return _blendPersonalities(
      corePersonality,
      context.adaptedDimensions,
      context.adaptationWeight,
    );
  }

  /// Blend core personality with contextual adaptations
  Map<String, double> _blendPersonalities(
    Map<String, double> core,
    Map<String, double> adaptation,
    double weight,
  ) {
    final blended = Map<String, double>.from(core);

    adaptation.forEach((dimension, adaptedValue) {
      final coreValue = core[dimension] ?? 0.5;
      // Blend: core * (1-weight) + adapted * weight
      blended[dimension] =
          (coreValue * (1 - weight) + adaptedValue * weight).clamp(0.0, 1.0);
    });

    return blended;
  }

  /// Get historical personality from a specific life phase
  Map<String, double>? getHistoricalPersonality(String phaseId) {
    try {
      final phase = evolutionTimeline.firstWhere((p) => p.phaseId == phaseId);
      return Map<String, double>.from(phase.corePersonality);
    } catch (e) {
      return null; // Phase not found
    }
  }

  /// Get current life phase
  LifePhase? getCurrentPhase() {
    if (currentPhaseId == null) return null;
    try {
      return evolutionTimeline.firstWhere((p) => p.phaseId == currentPhaseId);
    } catch (e) {
      return null;
    }
  }

  /// Update context-specific personality
  PersonalityProfile updateContext({
    required String contextId,
    required PersonalityContextType contextType,
    required Map<String, double> adaptations,
    double? adaptationWeight,
  }) {
    final updatedContexts = Map<String, ContextualPersonality>.from(contexts);

    if (updatedContexts.containsKey(contextId)) {
      // Update existing context
      updatedContexts[contextId] = updatedContexts[contextId]!.adapt(
        newAdaptations: adaptations,
        newWeight: adaptationWeight,
      );
    } else {
      // Create new context
      updatedContexts[contextId] = ContextualPersonality(
        contextId: contextId,
        contextType: contextType,
        adaptedDimensions: adaptations,
        adaptationWeight: adaptationWeight ?? 0.3,
        lastUpdated: DateTime.now(),
        updateCount: 1,
      );
    }

    return PersonalityProfile(
      userId: userId,
      dimensions: dimensions,
      dimensionConfidence: dimensionConfidence,
      archetype: archetype,
      authenticity: authenticity,
      createdAt: createdAt,
      lastUpdated: DateTime.now(),
      evolutionGeneration: evolutionGeneration,
      learningHistory: learningHistory,
      corePersonality: corePersonality,
      contexts: updatedContexts,
      evolutionTimeline: evolutionTimeline,
      currentPhaseId: currentPhaseId,
      isInTransition: isInTransition,
      activeTransition: activeTransition,
    );
  }

  /// Calculate compatibility score with another personality (0.0 to 1.0)
  double calculateCompatibility(PersonalityProfile other) {
    // Self-compatibility should always be perfect, regardless of confidence calibration.
    if (identical(this, other)) return 1.0;

    double totalSimilarity = 0.0;
    int validDimensions = 0;

    for (final dimension in VibeConstants.coreDimensions) {
      final myValue = dimensions[dimension];
      final otherValue = other.dimensions[dimension];
      final myConfidence = dimensionConfidence[dimension] ?? 0.0;
      final otherConfidence = other.dimensionConfidence[dimension] ?? 0.0;

      if (myValue != null &&
          otherValue != null &&
          myConfidence >= VibeConstants.personalityConfidenceThreshold &&
          otherConfidence >= VibeConstants.personalityConfidenceThreshold) {
        // Calculate similarity (1.0 - absolute difference)
        final similarity = 1.0 - (myValue - otherValue).abs();

        // Weight by average confidence
        final weight = (myConfidence + otherConfidence) / 2.0;
        totalSimilarity += similarity * weight;
        validDimensions++;
      }
    }

    if (validDimensions == 0) return 0.0;

    return (totalSimilarity / validDimensions).clamp(0.0, 1.0);
  }

  /// Get dominant personality traits (top 3 dimensions)
  List<String> getDominantTraits() {
    final sortedDimensions = dimensions.entries
        .where((entry) =>
            (dimensionConfidence[entry.key] ?? 0.0) >=
            VibeConstants.personalityConfidenceThreshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sortedDimensions.take(3).map((entry) => entry.key).toList();
  }

  /// Calculate learning potential with another AI
  double calculateLearningPotential(PersonalityProfile other) {
    final compatibility = calculateCompatibility(other);

    // High compatibility AIs can learn deeply from each other
    if (compatibility >= VibeConstants.highCompatibilityThreshold) {
      return 0.9;
    }

    // Medium compatibility allows moderate learning
    if (compatibility >= VibeConstants.mediumCompatibilityThreshold) {
      return 0.6;
    }

    // Low compatibility still allows some learning (inclusive network)
    if (compatibility >= VibeConstants.lowCompatibilityThreshold) {
      return 0.3;
    }

    // Even very different AIs can provide minimal learning
    return 0.1;
  }

  /// Check if personality has enough data for reliable analysis
  bool get isWellDeveloped {
    final confidenceSum = dimensionConfidence.values
        .fold(0.0, (sum, confidence) => sum + confidence);
    final avgConfidence = confidenceSum / VibeConstants.coreDimensions.length;

    return avgConfidence >= VibeConstants.personalityConfidenceThreshold &&
        (learningHistory['total_interactions'] as int) >=
            VibeConstants.minActionsForAnalysis;
  }

  /// Get personality summary for debugging/monitoring
  Map<String, dynamic> getSummary() {
    return {
      'archetype': archetype,
      'authenticity': authenticity,
      'generation': evolutionGeneration,
      'dominant_traits': getDominantTraits(),
      'avg_confidence': dimensionConfidence.values.isNotEmpty
          ? dimensionConfidence.values.reduce((a, b) => a + b) /
              dimensionConfidence.length
          : 0.0,
      'well_developed': isWellDeveloped,
      'total_interactions': learningHistory['total_interactions'],
      'ai2ai_connections': learningHistory['successful_ai2ai_connections'],
    };
  }

  /// Determine personality archetype based on dimension values
  String _determineArchetype(Map<String, double> dims) {
    double bestMatch = 0.0;
    String bestArchetype = 'balanced';

    for (final archetype in VibeConstants.personalityArchetypes.entries) {
      double match = 0.0;
      int validDimensions = 0;

      for (final dimension in archetype.value.entries) {
        final myValue = dims[dimension.key];
        if (myValue != null) {
          // Calculate how closely this dimension matches the archetype
          final similarity = 1.0 - (myValue - dimension.value).abs();
          match += similarity;
          validDimensions++;
        }
      }

      if (validDimensions > 0) {
        final avgMatch = match / validDimensions;
        if (avgMatch > bestMatch) {
          bestMatch = avgMatch;
          bestArchetype = archetype.key;
        }
      }
    }

    // Require a high-confidence match for archetype classification.
    // Otherwise, fall back to 'balanced' for unclear/neutral patterns.
    return bestMatch >= 0.85 ? bestArchetype : 'balanced';
  }

  /// Convert to JSON for storage (privacy-preserving)
  Map<String, dynamic> toJson() {
    // Serialize learning_history, handling DateTime objects
    final serializedLearningHistory = <String, dynamic>{};
    learningHistory.forEach((key, value) {
      if (value is List<DateTime>) {
        // Serialize DateTime list to ISO8601 strings
        serializedLearningHistory[key] =
            value.map((dt) => dt.toIso8601String()).toList();
      } else {
        serializedLearningHistory[key] = value;
      }
    });

    return {
      'user_id': userId,
      'dimensions': dimensions,
      'dimension_confidence': dimensionConfidence,
      'archetype': archetype,
      'authenticity': authenticity,
      'created_at': createdAt.toIso8601String(),
      'last_updated': lastUpdated.toIso8601String(),
      'evolution_generation': evolutionGeneration,
      'learning_history': serializedLearningHistory,
    };
  }

  /// Create from JSON storage
  factory PersonalityProfile.fromJson(Map<String, dynamic> json) {
    // Deserialize learning_history, handling DateTime lists
    final rawLearningHistory =
        Map<String, dynamic>.from(json['learning_history'] ?? {});
    final deserializedLearningHistory = <String, dynamic>{};

    rawLearningHistory.forEach((key, value) {
      if (key == 'evolution_milestones' && value is List) {
        // Deserialize DateTime list from ISO8601 strings
        deserializedLearningHistory[key] =
            value.map((item) => DateTime.parse(item as String)).toList();
      } else {
        deserializedLearningHistory[key] = value;
      }
    });

    return PersonalityProfile(
      userId: json['user_id'] as String,
      dimensions: Map<String, double>.from(json['dimensions']),
      dimensionConfidence:
          Map<String, double>.from(json['dimension_confidence']),
      archetype: json['archetype'] as String,
      authenticity: (json['authenticity'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      evolutionGeneration: json['evolution_generation'] as int,
      learningHistory: deserializedLearningHistory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PersonalityProfile &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          evolutionGeneration == other.evolutionGeneration;

  @override
  int get hashCode => userId.hashCode ^ evolutionGeneration.hashCode;

  @override
  String toString() {
    return 'PersonalityProfile(userId: $userId, archetype: $archetype, '
        'generation: $evolutionGeneration, authenticity: ${authenticity.toStringAsFixed(2)})';
  }
}

/// Represents a discovered AI personality
class DiscoveredPersonality {
  final String nodeId;
  final Map<String, double> vibe;
  final double compatibility;
  final double trustScore;

  DiscoveredPersonality({
    required this.nodeId,
    required this.vibe,
    required this.compatibility,
    required this.trustScore,
  });
}

/// User personality representation
class UserPersonality {
  final String userId;
  final PersonalityProfile profile;
  final Map<String, dynamic> metadata;
  final double communityAlignment = 0.5;

  UserPersonality({
    required this.userId,
    required this.profile,
    this.metadata = const {},
  });
  static UserPersonality defaultPersonality() {
    final profile = PersonalityProfile.initial('user_default');
    return UserPersonality(userId: 'user_default', profile: profile);
  }
}
