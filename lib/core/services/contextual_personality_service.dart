import 'dart:developer' as developer;
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/contextual_personality.dart';

/// OUR_GUTS.md: "Your doors stay yours"
/// Phase 3: Contextual Personality Service
/// Philosophy: Resist homogenization while allowing authentic transformation
class ContextualPersonalityService {
  static const String _logName = 'ContextualPersonalityService';
  
  // Thresholds for transition detection
  static const double _significantChangeThreshold = 0.15;
  static const double _authenticTransitionThreshold = 0.7;
  static const double _consistencyThreshold = 0.6;
  static const double _velocityThreshold = 0.5;
  
  // Time windows for transition detection
  static const Duration _shortTermWindow = Duration(days: 7);
  static const Duration _mediumTermWindow = Duration(days: 30);
  static const Duration _longTermWindow = Duration(days: 90);
  
  /// Determine if personality change should update core or just context
  /// Returns: 'core' | 'context' | 'resist'
  Future<String> classifyChange({
    required PersonalityProfile currentProfile,
    required Map<String, double> proposedChanges,
    required String? activeContext,
    required String changeSource, // 'user_action' | 'ai2ai' | 'cloud'
  }) async {
    try {
      developer.log(
        'Classifying change: source=$changeSource, context=$activeContext',
        name: _logName,
      );
      
      // Calculate change magnitude
      final changeMagnitude = _calculateChangeMagnitude(proposedChanges);
      
      // Small changes always go to current layer (context or core)
      if (changeMagnitude < _significantChangeThreshold) {
        return activeContext != null ? 'context' : 'core';
      }
      
      // Large AI2AI changes are suspicious (potential homogenization)
      if (changeSource == 'ai2ai' && changeMagnitude > _velocityThreshold) {
        developer.log('Large AI2AI change detected, resisting', name: _logName);
        return 'resist';
      }
      
      // User actions are authentic, update based on context
      if (changeSource == 'user_action') {
        // If in specific context, update that context
        if (activeContext != null && activeContext != 'general') {
          return 'context';
        }
        // Otherwise update core (this is authentic user behavior)
        return 'core';
      }
      
      // For AI2AI and cloud learning, check if in transition
      if (currentProfile.isInTransition) {
        final transition = currentProfile.activeTransition!;
        
        // If change aligns with transition direction, it's authentic
        if (_isChangeConsistentWithTransition(proposedChanges, transition)) {
          return 'core'; // Authentic transformation
        }
      }
      
      // Default: context-specific change
      return activeContext != null ? 'context' : 'resist';
      
    } catch (e) {
      developer.log('Error classifying change: $e', name: _logName);
      return 'resist'; // Safety: resist on error
    }
  }
  
  /// Detect if personality is undergoing authentic transformation
  Future<TransitionMetrics?> detectTransition({
    required PersonalityProfile profile,
    required List<Map<String, double>> recentChanges,
    required Duration window,
  }) async {
    try {
      if (recentChanges.length < 5) {
        return null; // Not enough data
      }
      
      developer.log(
        'Detecting transition: ${recentChanges.length} recent changes',
        name: _logName,
      );
      
      // Calculate aggregate changes
      final aggregateChanges = _aggregateChanges(recentChanges);
      
      // Calculate change velocity
      final velocity = _calculateChangeVelocity(
        aggregateChanges,
        window,
      );
      
      // Calculate consistency (are changes moving in same direction?)
      final consistency = _calculateConsistency(recentChanges);
      
      // Calculate authenticity score
      final authenticityScore = _calculateAuthenticityScore(
        profile: profile,
        changes: aggregateChanges,
        velocity: velocity,
        consistency: consistency,
      );
      
      // Only create transition if metrics meet thresholds
      if (authenticityScore >= _authenticTransitionThreshold &&
          consistency >= _consistencyThreshold) {
        
        developer.log(
          'Authentic transition detected: authenticity=$authenticityScore, consistency=$consistency',
          name: _logName,
        );
        
        final currentPhase = profile.getCurrentPhase();
        
        return TransitionMetrics(
          transitionId: '${profile.userId}_trans_${DateTime.now().millisecondsSinceEpoch}',
          startDate: DateTime.now().subtract(window),
          fromPhaseId: currentPhase?.phaseId ?? 'unknown',
          dimensionChanges: aggregateChanges,
          changeVelocity: velocity,
          consistency: consistency,
          authenticityScore: authenticityScore,
          triggers: _identifyTriggers(aggregateChanges),
        );
      }
      
      return null; // No transition detected
      
    } catch (e) {
      developer.log('Error detecting transition: $e', name: _logName);
      return null;
    }
  }
  
  /// Start tracking a new life phase transition
  Future<PersonalityProfile> startTransition({
    required PersonalityProfile profile,
    required TransitionMetrics metrics,
  }) async {
    developer.log(
      'Starting transition: ${metrics.transitionId}',
      name: _logName,
    );
    
    // Create new profile with transition active
    return PersonalityProfile(
      userId: profile.userId,
      dimensions: profile.dimensions,
      dimensionConfidence: profile.dimensionConfidence,
      archetype: profile.archetype,
      authenticity: profile.authenticity,
      createdAt: profile.createdAt,
      lastUpdated: DateTime.now(),
      evolutionGeneration: profile.evolutionGeneration,
      learningHistory: profile.learningHistory,
      corePersonality: profile.corePersonality,
      contexts: profile.contexts,
      evolutionTimeline: profile.evolutionTimeline,
      currentPhaseId: profile.currentPhaseId,
      isInTransition: true,
      activeTransition: metrics,
    );
  }
  
  /// Complete a life phase transition, create new phase
  Future<PersonalityProfile> completeTransition({
    required PersonalityProfile profile,
    required Map<String, double> newCorePersonality,
    required String newPhaseName,
  }) async {
    if (!profile.isInTransition || profile.activeTransition == null) {
      throw Exception('No active transition to complete');
    }
    
    developer.log(
      'Completing transition: ${profile.activeTransition!.transitionId}',
      name: _logName,
    );
    
    final currentPhase = profile.getCurrentPhase();
    if (currentPhase == null) {
      throw Exception('No current phase found');
    }
    
    // End current phase
    final endedPhase = currentPhase.end(
      reason: profile.activeTransition!.triggers.join(', '),
    );
    
    // Create new phase
    final newPhase = LifePhase(
      phaseId: '${profile.userId}_phase_${profile.evolutionTimeline.length + 1}',
      name: newPhaseName,
      corePersonality: newCorePersonality,
      authenticity: profile.authenticity,
      startDate: DateTime.now(),
      endDate: null, // Current phase
      milestones: {
        'transition_from': currentPhase.phaseId,
        'created': DateTime.now().toIso8601String(),
      },
      interactionCount: 0,
      dominantTraits: _identifyDominantTraits(newCorePersonality),
    );
    
    // Update timeline
    final updatedTimeline = List<LifePhase>.from(profile.evolutionTimeline);
    // Replace old current phase with ended version
    final currentIndex = updatedTimeline.indexWhere((p) => p.phaseId == currentPhase.phaseId);
    if (currentIndex >= 0) {
      updatedTimeline[currentIndex] = endedPhase;
    }
    // Add new phase
    updatedTimeline.add(newPhase);
    
    // Complete the transition
    final completedTransition = profile.activeTransition!.complete(
      toPhaseId: newPhase.phaseId,
      finalAuthenticityScore: profile.activeTransition!.authenticityScore,
    );
    
    return PersonalityProfile(
      userId: profile.userId,
      dimensions: newCorePersonality, // New dimensions
      dimensionConfidence: profile.dimensionConfidence,
      archetype: profile.archetype,
      authenticity: profile.authenticity,
      createdAt: profile.createdAt,
      lastUpdated: DateTime.now(),
      evolutionGeneration: profile.evolutionGeneration + 1,
      learningHistory: {
        ...profile.learningHistory,
        'phase_transitions': (profile.learningHistory['phase_transitions'] as int? ?? 0) + 1,
      },
      corePersonality: newCorePersonality, // New core
      contexts: {}, // Reset contexts for new phase
      evolutionTimeline: updatedTimeline,
      currentPhaseId: newPhase.phaseId,
      isInTransition: false,
      activeTransition: completedTransition,
    );
  }
  
  // ========================================================================
  // HELPER METHODS
  // ========================================================================
  
  double _calculateChangeMagnitude(Map<String, double> changes) {
    if (changes.isEmpty) return 0.0;
    
    final totalChange = changes.values.fold<double>(
      0.0,
      (sum, change) => sum + change.abs(),
    );
    
    return totalChange / changes.length;
  }
  
  Map<String, double> _aggregateChanges(List<Map<String, double>> changes) {
    final aggregated = <String, double>{};
    
    for (final change in changes) {
      change.forEach((dimension, value) {
        aggregated[dimension] = (aggregated[dimension] ?? 0.0) + value;
      });
    }
    
    // Average
    aggregated.forEach((dimension, total) {
      aggregated[dimension] = total / changes.length;
    });
    
    return aggregated;
  }
  
  double _calculateChangeVelocity(
    Map<String, double> changes,
    Duration window,
  ) {
    final magnitude = _calculateChangeMagnitude(changes);
    final daysInWindow = window.inDays.toDouble();
    
    return magnitude / daysInWindow; // Change per day
  }
  
  double _calculateConsistency(List<Map<String, double>> changes) {
    if (changes.length < 2) return 0.0;
    
    // Calculate if changes move in same direction consistently
    final dimensionDirections = <String, List<double>>{};
    
    for (final change in changes) {
      change.forEach((dimension, value) {
        dimensionDirections.putIfAbsent(dimension, () => []).add(value);
      });
    }
    
    // Calculate consistency per dimension
    final consistencyScores = <double>[];
    
    dimensionDirections.forEach((dimension, values) {
      final positiveCount = values.where((v) => v > 0).length;
      final negativeCount = values.where((v) => v < 0).length;
      final total = values.length;
      
      // Consistency = max(positive%, negative%)
      final consistency = (positiveCount > negativeCount
          ? positiveCount / total
          : negativeCount / total);
      
      consistencyScores.add(consistency);
    });
    
    if (consistencyScores.isEmpty) return 0.0;
    
    // Average consistency across dimensions
    return consistencyScores.reduce((a, b) => a + b) / consistencyScores.length;
  }
  
  double _calculateAuthenticityScore({
    required PersonalityProfile profile,
    required Map<String, double> changes,
    required double velocity,
    required double consistency,
  }) {
    // Slow, consistent change = authentic
    // Fast, inconsistent change = drift
    
    final velocityScore = (1.0 - velocity).clamp(0.0, 1.0);
    final consistencyScore = consistency;
    final authenticityBase = profile.authenticity;
    
    return (velocityScore * 0.4 + consistencyScore * 0.4 + authenticityBase * 0.2)
        .clamp(0.0, 1.0);
  }
  
  bool _isChangeConsistentWithTransition(
    Map<String, double> proposedChanges,
    TransitionMetrics transition,
  ) {
    // Check if proposed changes align with transition direction
    int alignedDimensions = 0;
    int totalDimensions = 0;
    
    proposedChanges.forEach((dimension, proposedChange) {
      final transitionChange = transition.dimensionChanges[dimension];
      if (transitionChange != null) {
        totalDimensions++;
        // Check if signs match (both positive or both negative)
        if ((proposedChange > 0 && transitionChange > 0) ||
            (proposedChange < 0 && transitionChange < 0)) {
          alignedDimensions++;
        }
      }
    });
    
    if (totalDimensions == 0) return false;
    
    // At least 60% alignment required
    return (alignedDimensions / totalDimensions) >= 0.6;
  }
  
  List<String> _identifyTriggers(Map<String, double> changes) {
    final triggers = <String>[];
    
    changes.forEach((dimension, change) {
      if (change.abs() > _significantChangeThreshold) {
        triggers.add('$dimension: ${change > 0 ? '+' : ''}${change.toStringAsFixed(2)}');
      }
    });
    
    return triggers;
  }
  
  List<String> _identifyDominantTraits(Map<String, double> personality) {
    final sorted = personality.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(3).map((e) => e.key).toList();
  }
}

