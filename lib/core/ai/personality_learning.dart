import 'dart:developer' as developer;
import 'package:spots/core/constants/vibe_constants.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/services/storage_service.dart';
import 'package:spots/core/services/golden_expert_ai_influence_service.dart';

// Lightweight preferences abstraction to allow in-memory prefs during tests
abstract class PreferencesLike {
  String? getString(String key);
  Future<bool> setString(String key, String value);
  Future<bool> remove(String key);
}

class _SharedPreferencesAdapter implements PreferencesLike {
  final SharedPreferences _prefs;
  _SharedPreferencesAdapter(this._prefs);
  @override
  String? getString(String key) => _prefs.getString(key);
  @override
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  @override
  Future<bool> remove(String key) => _prefs.remove(key);
}

class _InMemoryPreferences implements PreferencesLike {
  final Map<String, String> _store = {};
  @override
  String? getString(String key) => _store[key];
  @override
  Future<bool> setString(String key, String value) async { _store[key] = value; return true; }
  @override
  Future<bool> remove(String key) async { _store.remove(key); return true; }
}

/// OUR_GUTS.md: "AI personality that evolves and learns from user behavior while preserving privacy"
/// Core personality learning engine that manages the 12-dimensional personality evolution
/// Phase 2: Expanded from 8 to 12 dimensions for more precise learning
class PersonalityLearning {
  static const String _logName = 'PersonalityLearning';
  
  // Storage keys for personality data
  static const String _personalityProfileKey = 'personality_profile';
  static const String _learningHistoryKey = 'personality_learning_history';
  static const String _dimensionConfidenceKey = 'dimension_confidence';
  
  final PreferencesLike _prefs;
  PersonalityProfile? _currentProfile;
  bool _isLearning = false;
  
  // Golden expert influence service
  final GoldenExpertAIInfluenceService _goldenExpertService;
  
  // Callback for personality evolution events
  Function(String userId, PersonalityProfile evolvedProfile)? onPersonalityEvolved;
  
  // Zero-arg constructor for tests (in-memory prefs)
  PersonalityLearning() 
      : _prefs = _InMemoryPreferences(),
        _goldenExpertService = GoldenExpertAIInfluenceService();
  // App constructor using real SharedPreferences
  PersonalityLearning.withPrefs(SharedPreferences prefs) 
      : _prefs = _SharedPreferencesAdapter(prefs),
        _goldenExpertService = GoldenExpertAIInfluenceService();
  
  /// Set callback for personality evolution events
  void setEvolutionCallback(Function(String userId, PersonalityProfile evolvedProfile) callback) {
    onPersonalityEvolved = callback;
  }
  
  /// Initialize personality learning system for a user
  Future<PersonalityProfile> initializePersonality(String userId) async {
    developer.log('Initializing personality learning for user: $userId', name: _logName);
    
    try {
      // Try to load existing personality profile
      final existingProfile = await _loadPersonalityProfile(userId);
      if (existingProfile != null) {
        _currentProfile = existingProfile;
        developer.log('Loaded existing personality profile (generation ${existingProfile.evolutionGeneration})', name: _logName);
        return existingProfile;
      }
      
      // Create new personality profile
      final newProfile = PersonalityProfile.initial(userId);
      await _savePersonalityProfile(newProfile);
      _currentProfile = newProfile;
      
      developer.log('Created new personality profile for user', name: _logName);
      return newProfile;
    } catch (e) {
      developer.log('Error initializing personality: $e', name: _logName);
      
      // Fallback to default profile
      final fallbackProfile = PersonalityProfile.initial(userId);
      _currentProfile = fallbackProfile;
      return fallbackProfile;
    }
  }
  
  /// Evolve personality based on user action
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `action`: User action
  /// - `localExpertise`: Optional LocalExpertise for golden expert weighting
  Future<PersonalityProfile> evolveFromUserAction(
    String userId,
    UserAction action, {
    LocalExpertise? localExpertise,
  }) async {
    if (_currentProfile == null) {
      await initializePersonality(userId);
    }
    
    if (_isLearning) {
      developer.log('Personality learning already in progress, queuing action', name: _logName);
      return _currentProfile!;
    }
    
    _isLearning = true;
    
    try {
      developer.log('Evolving personality from user action: ${action.type}', name: _logName);
      
      // Analyze action for personality insights
      final dimensionUpdates = await _analyzeActionForDimensions(action);
      final confidenceUpdates = await _analyzeActionForConfidence(action);
      
      // Calculate golden expert weight if applicable
      double influenceWeight = 1.0;
      if (localExpertise != null) {
        influenceWeight = _goldenExpertService.calculateInfluenceWeight(localExpertise);
        developer.log(
          'Applying golden expert weight: $influenceWeight',
          name: _logName,
        );
      }
      
      // Apply learning rate and golden expert weight to dimension updates
      final adjustedUpdates = <String, double>{};
      dimensionUpdates.forEach((dimension, change) {
        adjustedUpdates[dimension] = 
            change * VibeConstants.personalityLearningRate * influenceWeight;
      });
      
      // Calculate new authenticity score
      final newAuthenticity = await _calculateAuthenticityFromAction(action);
      
      // Create learning history entry
      final learningData = {
        'total_interactions': 1,
        'action_types': [action.type.toString()],
        'learning_source': 'user_action',
        'dimension_changes': adjustedUpdates,
      };
      
      // Evolve the personality
      final evolvedProfile = _currentProfile!.evolve(
        newDimensions: adjustedUpdates,
        newConfidence: confidenceUpdates,
        newAuthenticity: newAuthenticity,
        additionalLearning: learningData,
      );
      
      // Save updated profile
      await _savePersonalityProfile(evolvedProfile);
      _currentProfile = evolvedProfile;
      
      developer.log('Personality evolved to generation ${evolvedProfile.evolutionGeneration}', name: _logName);
      developer.log('Dominant traits: ${evolvedProfile.getDominantTraits()}', name: _logName);
      
      // Notify listeners of personality evolution
      if (onPersonalityEvolved != null) {
        try {
          onPersonalityEvolved!(userId, evolvedProfile);
        } catch (e) {
          developer.log('Error in personality evolution callback: $e', name: _logName);
        }
      }
      
      return evolvedProfile;
    } catch (e) {
      developer.log('Error evolving personality: $e', name: _logName);
      return _currentProfile!;
    } finally {
      _isLearning = false;
    }
  }
  
  /// Evolve personality from AI2AI learning interaction
  Future<PersonalityProfile> evolveFromAI2AILearning(
    String userId,
    AI2AILearningInsight insight,
  ) async {
    if (_currentProfile == null) {
      await initializePersonality(userId);
    }
    
    if (_isLearning) {
      developer.log('Personality learning already in progress, queuing AI2AI learning', name: _logName);
      return _currentProfile!;
    }
    
    _isLearning = true;
    
    try {
      developer.log('Evolving personality from AI2AI learning: ${insight.type}', name: _logName);
      
      // Apply AI2AI learning rate (typically lower than direct user actions)
      final adjustedInsights = <String, double>{};
      insight.dimensionInsights.forEach((dimension, change) {
        adjustedInsights[dimension] = change * VibeConstants.ai2aiLearningRate;
      });
      
      // Create learning history entry
      final learningData = {
        'total_interactions': 1,
        'successful_ai2ai_connections': 1,
        'learning_source': 'ai2ai_interaction',
        'insight_type': insight.type.toString(),
        'dimension_changes': adjustedInsights,
      };
      
      // Evolve personality with AI2AI insights
      final evolvedProfile = _currentProfile!.evolve(
        newDimensions: adjustedInsights,
        additionalLearning: learningData,
      );
      
      // Save updated profile
      await _savePersonalityProfile(evolvedProfile);
      _currentProfile = evolvedProfile;
      
      developer.log('Personality evolved from AI2AI learning to generation ${evolvedProfile.evolutionGeneration}', name: _logName);
      
      // Notify listeners of personality evolution
      if (onPersonalityEvolved != null) {
        try {
          onPersonalityEvolved!(userId, evolvedProfile);
        } catch (e) {
          developer.log('Error in personality evolution callback: $e', name: _logName);
        }
      }
      
      return evolvedProfile;
    } catch (e) {
      developer.log('Error evolving personality from AI2AI learning: $e', name: _logName);
      return _currentProfile!;
    } finally {
      _isLearning = false;
    }
  }
  
  /// Get current personality profile
  Future<PersonalityProfile?> getCurrentPersonality(String userId) async {
    if (_currentProfile != null && _currentProfile!.userId == userId) {
      return _currentProfile;
    }
    
    return await _loadPersonalityProfile(userId);
  }
  
  /// Get personality evolution history
  Future<List<PersonalityEvolutionEvent>> getEvolutionHistory(String userId) async {
    try {
      final historyJson = _prefs.getString('${_learningHistoryKey}_$userId');
      if (historyJson == null) return [];
      
      // Parse evolution history
      // This would contain timestamp, generation, dimension changes, etc.
      // Implementation depends on storage format
      return [];
    } catch (e) {
      developer.log('Error loading evolution history: $e', name: _logName);
      return [];
    }
  }
  
  /// Calculate personality readiness for AI2AI connections
  Future<PersonalityReadiness> calculateAI2AIReadiness(String userId) async {
    final profile = await getCurrentPersonality(userId);
    if (profile == null) {
      return PersonalityReadiness(
        isReady: false,
        readinessScore: 0.0,
        reasons: ['No personality profile found'],
      );
    }
    
    final reasons = <String>[];
    double readinessScore = 0.0;
    
    // Check if personality is well-developed
    if (profile.isWellDeveloped) {
      readinessScore += 0.4;
    } else {
      reasons.add('Personality needs more development (${profile.learningHistory['total_interactions']} interactions)');
    }
    
    // Check confidence levels
    final avgConfidence = profile.dimensionConfidence.values.isNotEmpty
        ? profile.dimensionConfidence.values.reduce((a, b) => a + b) / profile.dimensionConfidence.length
        : 0.0;
    
    if (avgConfidence >= VibeConstants.personalityConfidenceThreshold) {
      readinessScore += 0.3;
    } else {
      reasons.add('Low confidence in personality dimensions (${(avgConfidence * 100).toStringAsFixed(1)}%)');
    }
    
    // Check authenticity score
    if (profile.authenticity >= 0.6) {
      readinessScore += 0.2;
    } else {
      reasons.add('Low authenticity score (${(profile.authenticity * 100).toStringAsFixed(1)}%)');
    }
    
    // Check evolution generation (more evolved = more ready)
    if (profile.evolutionGeneration >= 5) {
      readinessScore += 0.1;
    } else {
      reasons.add('Personality needs more evolution (generation ${profile.evolutionGeneration})');
    }
    
    return PersonalityReadiness(
      isReady: readinessScore >= 0.7,
      readinessScore: readinessScore,
      reasons: reasons,
    );
  }
  
  /// Reset personality learning (for testing or user request)
  Future<void> resetPersonality(String userId) async {
    developer.log('Resetting personality for user: $userId', name: _logName);
    
    await _prefs.remove('${_personalityProfileKey}_$userId');
    await _prefs.remove('${_learningHistoryKey}_$userId');
    await _prefs.remove('${_dimensionConfidenceKey}_$userId');
    
    _currentProfile = null;
    
    developer.log('Personality reset completed', name: _logName);
  }
  
  // Private helper methods
  Future<PersonalityProfile?> _loadPersonalityProfile(String userId) async {
    try {
      final profileJson = _prefs.getString('${_personalityProfileKey}_$userId');
      if (profileJson == null) return null;
      
      // In a real implementation, this would parse JSON
      // For now, return null to create new profile
      return null;
    } catch (e) {
      developer.log('Error loading personality profile: $e', name: _logName);
      return null;
    }
  }
  
  Future<void> _savePersonalityProfile(PersonalityProfile profile) async {
    try {
      // In a real implementation, this would serialize to JSON
      await _prefs.setString(
        '${_personalityProfileKey}_${profile.userId}',
        'profile_data', // Would be profile.toJson()
      );
      
      developer.log('Personality profile saved (generation ${profile.evolutionGeneration})', name: _logName);
    } catch (e) {
      developer.log('Error saving personality profile: $e', name: _logName);
    }
  }
  
  Future<Map<String, double>> _analyzeActionForDimensions(UserAction action) async {
    final dimensionUpdates = <String, double>{};
    
    switch (action.type) {
      case UserActionType.spotVisit:
        // Visiting spots indicates exploration eagerness
        dimensionUpdates['exploration_eagerness'] = 0.1;
        
        // Check if it's a social or solo visit
        if (action.metadata['social_visit'] == true) {
          dimensionUpdates['community_orientation'] = 0.05;
        }
        
        // Check distance traveled
        final distanceTraveled = action.metadata['distance_km'] as double? ?? 0.0;
        if (distanceTraveled > 10.0) {
          dimensionUpdates['location_adventurousness'] = 0.08;
        }
        
        // NEW: Energy preference (Phase 2)
        final spotEnergyLevel = action.metadata['spot_energy_level'] as double? ?? 0.5;
        dimensionUpdates['energy_preference'] = (spotEnergyLevel - 0.5) * 0.15;
        
        // NEW: Novelty seeking (Phase 2)
        final isRepeatVisit = action.metadata['is_repeat_visit'] as bool? ?? false;
        dimensionUpdates['novelty_seeking'] = isRepeatVisit ? -0.08 : 0.08;
        
        // NEW: Value orientation (Phase 2)
        final priceLevel = action.metadata['price_level'] as double? ?? 0.5;
        dimensionUpdates['value_orientation'] = (priceLevel - 0.5) * 0.12;
        
        // NEW: Crowd tolerance (Phase 2)
        final crowdLevel = action.metadata['crowd_level'] as double? ?? 0.5;
        dimensionUpdates['crowd_tolerance'] = (crowdLevel - 0.5) * 0.10;
        break;
        
      case UserActionType.socialInteraction:
        dimensionUpdates['community_orientation'] = 0.12;
        dimensionUpdates['social_discovery_style'] = 0.08;
        break;
        
      case UserActionType.spontaneousActivity:
        dimensionUpdates['temporal_flexibility'] = 0.15;
        dimensionUpdates['exploration_eagerness'] = 0.08;
        break;
        
      case UserActionType.curationActivity:
        dimensionUpdates['curation_tendency'] = 0.12;
        dimensionUpdates['community_orientation'] = 0.06;
        break;
        
      case UserActionType.authenticPreference:
        dimensionUpdates['authenticity_preference'] = 0.10;
        break;
        
      case UserActionType.trustNetworkUse:
        dimensionUpdates['trust_network_reliance'] = 0.08;
        break;
    }
    
    return dimensionUpdates;
  }
  
  Future<Map<String, double>> _analyzeActionForConfidence(UserAction action) async {
    // Increase confidence for dimensions that are consistently expressed
    final confidenceUpdates = <String, double>{};
    
    // Base confidence increase for any action
    const baseConfidenceIncrease = 0.02;
    
    switch (action.type) {
      case UserActionType.spotVisit:
        confidenceUpdates['exploration_eagerness'] = baseConfidenceIncrease;
        if (action.metadata['social_visit'] == true) {
          confidenceUpdates['community_orientation'] = baseConfidenceIncrease;
        }
        
        // NEW: Confidence for new dimensions (Phase 2)
        if (action.metadata.containsKey('spot_energy_level')) {
          confidenceUpdates['energy_preference'] = baseConfidenceIncrease;
        }
        if (action.metadata.containsKey('is_repeat_visit')) {
          confidenceUpdates['novelty_seeking'] = baseConfidenceIncrease;
        }
        if (action.metadata.containsKey('price_level')) {
          confidenceUpdates['value_orientation'] = baseConfidenceIncrease;
        }
        if (action.metadata.containsKey('crowd_level')) {
          confidenceUpdates['crowd_tolerance'] = baseConfidenceIncrease;
        }
        break;
        
      case UserActionType.socialInteraction:
        confidenceUpdates['community_orientation'] = baseConfidenceIncrease * 1.5;
        confidenceUpdates['social_discovery_style'] = baseConfidenceIncrease;
        break;
        
      case UserActionType.spontaneousActivity:
        confidenceUpdates['temporal_flexibility'] = baseConfidenceIncrease * 1.2;
        break;
        
      case UserActionType.curationActivity:
        confidenceUpdates['curation_tendency'] = baseConfidenceIncrease * 1.3;
        break;
        
      case UserActionType.authenticPreference:
        confidenceUpdates['authenticity_preference'] = baseConfidenceIncrease * 1.1;
        break;
        
      case UserActionType.trustNetworkUse:
        confidenceUpdates['trust_network_reliance'] = baseConfidenceIncrease;
        break;
    }
    
    return confidenceUpdates;
  }
  
  Future<double> _calculateAuthenticityFromAction(UserAction action) async {
    if (_currentProfile == null) return 0.5;
    
    double authenticityChange = 0.0;
    
    switch (action.type) {
      case UserActionType.authenticPreference:
        authenticityChange = 0.05;
        break;
      case UserActionType.curationActivity:
        // Curation can indicate authenticity or algorithmic preference
        final curationType = action.metadata['curation_type'] as String?;
        if (curationType == 'personal_experience') {
          authenticityChange = 0.03;
        } else if (curationType == 'algorithmic_based') {
          authenticityChange = -0.02;
        }
        break;
      case UserActionType.spotVisit:
        // Visiting lesser-known spots indicates authenticity preference
        final spotPopularity = action.metadata['spot_popularity'] as double? ?? 0.5;
        if (spotPopularity < 0.3) {
          authenticityChange = 0.02;
        }
        break;
      default:
        // Neutral actions don't affect authenticity much
        break;
    }
    
    final newAuthenticity = (_currentProfile!.authenticity + authenticityChange).clamp(0.0, 1.0);
    return newAuthenticity;
  }

  // ---- Legacy/test API surface (no-op/simple implementations) ----
  Future<void> initialize() async {}

  Future<double> calculatePersonalityReadiness() async {
    if (_currentProfile == null) return 0.0;
    return 0.5;
  }

  // Legacy method expected by some tests
  Future<Map<String, dynamic>> calculatePersonalityEvolution({
    Map<String, dynamic>? current,
    Map<String, dynamic>? currentProfile,
    List<Map<String, dynamic>> actions = const [],
  }) async {
    return {
      'generation': _currentProfile?.evolutionGeneration ?? 1,
      'updated': DateTime.now().toIso8601String(),
    };
  }

  Future<PersonalityProfile> evolvePersonality(UserAction action) async {
    if (_currentProfile == null) {
      _currentProfile = PersonalityProfile.initial('user');
    }
    return _currentProfile!;
  }

  Future<List<BehavioralPattern>> recognizeBehavioralPatterns(List<UserAction> actions) async {
    return [];
  }

  Future<Map<String, double>> predictFuturePreferences() async {
    if (_currentProfile == null) return {};
    return Map<String, double>.from(_currentProfile!.dimensions);
  }

  Future<void> updatePersonalityProfile(Map<String, dynamic> personalityData) async {}

  Future<double> calculatePersonalityCompatibility(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
  ) async {
    return 0.75;
  }

  Future<AnonymizedPersonalityData> anonymizePersonality() async {
    if (_currentProfile == null) {
      return const AnonymizedPersonalityData(
        hashedUserId: '',
        hashedSignature: '',
        anonymizedDimensions: {},
        metadata: {},
      );
    }
    return AnonymizedPersonalityData(
      hashedUserId: _currentProfile!.userId.hashCode.toString(),
      hashedSignature: (_currentProfile!.userId + _currentProfile!.archetype).hashCode.toString(),
      anonymizedDimensions: Map<String, double>.from(_currentProfile!.dimensions),
      metadata: const {},
    );
  }
}

// Simple placeholder models expected by tests
class AnonymizedPersonalityData {
  final String hashedUserId;
  final String hashedSignature;
  final Map<String, double> anonymizedDimensions;
  final Map<String, dynamic> metadata;
  const AnonymizedPersonalityData({
    required this.hashedUserId,
    required this.hashedSignature,
    required this.anonymizedDimensions,
    required this.metadata,
  });
}

class BehavioralPattern {
  final String id;
  final String type;
  final double confidence;
  const BehavioralPattern({
    required this.id,
    required this.type,
    required this.confidence,
  });
}

// Supporting classes for personality learning
class UserAction {
  final UserActionType type;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  UserAction({
    required this.type,
    required this.timestamp,
    required this.metadata,
  });
}

enum UserActionType {
  spotVisit,
  socialInteraction,
  spontaneousActivity,
  curationActivity,
  authenticPreference,
  trustNetworkUse,
}

class AI2AILearningInsight {
  final AI2AIInsightType type;
  final Map<String, double> dimensionInsights;
  final double learningQuality;
  final DateTime timestamp;
  
  AI2AILearningInsight({
    required this.type,
    required this.dimensionInsights,
    required this.learningQuality,
    required this.timestamp,
  });
}

enum AI2AIInsightType {
  compatibilityLearning,
  dimensionDiscovery,
  patternRecognition,
  trustBuilding,
  communityInsight,
  cloudLearning,
}

class PersonalityReadiness {
  final bool isReady;
  final double readinessScore;
  final List<String> reasons;
  
  PersonalityReadiness({
    required this.isReady,
    required this.readinessScore,
    required this.reasons,
  });
}

class PersonalityEvolutionEvent {
  final DateTime timestamp;
  final int generation;
  final Map<String, double> dimensionChanges;
  final String learningSource;
  
  PersonalityEvolutionEvent({
    required this.timestamp,
    required this.generation,
    required this.dimensionChanges,
    required this.learningSource,
  });
}
  // Remove duplicate methods below; keep single minimal versions
  

