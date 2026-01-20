import 'dart:convert';
import 'dart:developer' as developer;

import 'package:get_it/get_it.dart';
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai_core/models/personality_profile.dart';
import 'package:avrai/core/models/multi_path_expertise.dart';
import 'package:avrai/core/models/outcome_result.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/golden_expert_ai_influence_service.dart';
import 'package:avrai/core/services/onboarding_dimension_mapper.dart';
import 'package:avrai/core/services/personality_sync_service.dart';
import 'package:avrai/core/services/agent_id_service.dart';
import 'package:avrai/core/services/social_media_vibe_analyzer.dart';
import 'package:avrai/core/ai/quantum/quantum_vibe_engine.dart';
import 'package:avrai/core/ai/vibe_analysis_engine.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  @override
  Future<bool> remove(String key) => _prefs.remove(key);
}

class _InMemoryPreferences implements PreferencesLike {
  final Map<String, String> _store = {};
  @override
  String? getString(String key) => _store[key];
  @override
  Future<bool> setString(String key, String value) async {
    _store[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _store.remove(key);
    return true;
  }
}

/// OUR_GUTS.md: "AI personality that evolves and learns from user behavior while preserving privacy"
/// Core personality learning engine that manages the 12-dimensional personality evolution
/// Phase 2: Expanded from 8 to 12 dimensions for more precise learning
class PersonalityLearning {
  static const String _logName = 'PersonalityLearning';

  // Storage keys for personality data
  static const String _personalityProfileKey = 'personality_profile';

  /// Phase 8.3: Migrate existing profiles from userId to agentId
  /// This method should be called once during app initialization to migrate legacy profiles
  Future<void> migrateProfilesToAgentId() async {
    developer.log('Starting personality profile migration to agentId',
        name: _logName);

    try {
      // Note: This migration relies on the fact that _loadPersonalityProfile
      // already handles migration when loading by userId. The migration happens
      // automatically when profiles are loaded.

      developer.log(
          'Profile migration completed (migration happens on-demand during load)',
          name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error during profile migration: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  static const String _learningHistoryKey = 'personality_learning_history';
  static const String _dimensionConfidenceKey = 'dimension_confidence';

  final PreferencesLike _prefs;
  PersonalityProfile? _currentProfile;
  bool _isLearning = false;

  // Golden expert influence service
  final GoldenExpertAIInfluenceService _goldenExpertService;

  // Callback for personality evolution events
  Function(String userId, PersonalityProfile evolvedProfile)?
      onPersonalityEvolved;

  // Zero-arg constructor for tests (in-memory prefs)
  PersonalityLearning()
      : _prefs = _InMemoryPreferences(),
        _goldenExpertService = GoldenExpertAIInfluenceService();
  // App constructor using real SharedPreferences
  PersonalityLearning.withPrefs(SharedPreferences prefs)
      : _prefs = _SharedPreferencesAdapter(prefs),
        _goldenExpertService = GoldenExpertAIInfluenceService();

  AgentIdService _resolveAgentIdService() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<AgentIdService>()) {
        return sl<AgentIdService>();
      }
    } catch (_) {}
    return AgentIdService();
  }

  PersonalitySyncService? _tryResolvePersonalitySyncService() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<PersonalitySyncService>()) {
        return sl<PersonalitySyncService>();
      }
    } catch (_) {}
    return null;
  }

  QuantumVibeEngine _resolveQuantumVibeEngine() {
    try {
      final sl = GetIt.instance;
      if (sl.isRegistered<QuantumVibeEngine>()) {
        return sl<QuantumVibeEngine>();
      }
    } catch (_) {}
    return QuantumVibeEngine();
  }

  /// Set callback for personality evolution events
  void setEvolutionCallback(
      Function(String userId, PersonalityProfile evolvedProfile) callback) {
    onPersonalityEvolved = callback;
  }

  /// Initialize personality learning system for a user
  ///
  /// [password] is optional and only used for cloud sync operations.
  /// If provided and cloud sync is enabled, will attempt to load profile from cloud.
  /// Phase 8.3: Uses agentId internally for privacy protection
  Future<PersonalityProfile> initializePersonality(String userId,
      {String? password}) async {
    developer.log('Initializing personality learning for user: $userId',
        name: _logName);

    try {
      // Phase 8.3: Get agentId for privacy protection
      final agentIdService = _resolveAgentIdService();
      final agentId = await agentIdService.getUserAgentId(userId);

      // Try to load existing personality profile from local storage (by agentId)
      final existingProfile = await _loadPersonalityProfile(agentId);
      if (existingProfile != null) {
        _currentProfile = existingProfile;
        developer.log(
            'Loaded existing personality profile (generation ${existingProfile.evolutionGeneration})',
            name: _logName);
        return existingProfile;
      }

      // If not found locally and password provided, try loading from cloud
      if (password != null && password.isNotEmpty) {
        try {
          // Import here to avoid circular dependency
          final syncService = _tryResolvePersonalitySyncService();
          if (syncService == null) {
            developer.log(
              'PersonalitySyncService not registered; skipping cloud sync',
              name: _logName,
            );
          } else {
            final syncEnabled = await syncService.isCloudSyncEnabled(userId);

            if (syncEnabled) {
              developer.log(
                  'Cloud sync enabled, attempting to load from cloud...',
                  name: _logName);
              final cloudProfile =
                  await syncService.loadFromCloud(userId, password);

              if (cloudProfile != null) {
                // Ensure cloud profile has correct agentId
                final migratedProfile = cloudProfile.agentId == agentId
                    ? cloudProfile
                    : PersonalityProfile(
                        agentId: agentId,
                        userId: userId,
                        dimensions: cloudProfile.dimensions,
                        dimensionConfidence: cloudProfile.dimensionConfidence,
                        archetype: cloudProfile.archetype,
                        authenticity: cloudProfile.authenticity,
                        createdAt: cloudProfile.createdAt,
                        lastUpdated: cloudProfile.lastUpdated,
                        evolutionGeneration: cloudProfile.evolutionGeneration,
                        learningHistory: cloudProfile.learningHistory,
                        corePersonality: cloudProfile.corePersonality,
                        contexts: cloudProfile.contexts,
                        evolutionTimeline: cloudProfile.evolutionTimeline,
                        currentPhaseId: cloudProfile.currentPhaseId,
                        isInTransition: cloudProfile.isInTransition,
                        activeTransition: cloudProfile.activeTransition,
                      );

                // Save cloud profile locally
                await _savePersonalityProfile(migratedProfile);
                _currentProfile = migratedProfile;
                developer.log(
                    'Loaded personality profile from cloud (generation ${migratedProfile.evolutionGeneration})',
                    name: _logName);
                return migratedProfile;
              } else {
                developer.log('No cloud profile found or decryption failed',
                    name: _logName);
              }
            }
          }
        } catch (e) {
          developer.log('Error loading from cloud: $e', name: _logName);
          // Continue to create new profile if cloud load fails
        }
      }

      // Create new personality profile using agentId
      final newProfile = PersonalityProfile.initial(agentId, userId: userId);
      await _savePersonalityProfile(newProfile);
      _currentProfile = newProfile;

      developer.log('Created new personality profile for user', name: _logName);
      return newProfile;
    } catch (e) {
      developer.log('Error initializing personality: $e', name: _logName);

      // Fallback to default profile
      final agentIdService = _resolveAgentIdService();
      final agentId = await agentIdService.getUserAgentId(userId);
      final fallbackProfile =
          PersonalityProfile.initial(agentId, userId: userId);
      _currentProfile = fallbackProfile;
      return fallbackProfile;
    }
  }

  /// Initialize personality from onboarding data including social media
  /// Accepts userId from UI layer, converts to agentId internally for privacy protection
  Future<PersonalityProfile> initializePersonalityFromOnboarding(
    String userId, {
    Map<String, dynamic>? onboardingData,
    Map<String, dynamic>? socialMediaData,
  }) async {
    // Convert userId → agentId for privacy protection
    final agentIdService = _resolveAgentIdService();
    final agentId = await agentIdService.getUserAgentId(userId);

    developer.log(
      'Initializing personality from onboarding for user: $userId (agentId: ${agentId.substring(0, 10)}...)',
      name: _logName,
    );

    try {
      // Phase 8.3: Check if profile already exists using agentId
      final existingProfile = await _loadPersonalityProfile(agentId);
      if (existingProfile != null && existingProfile.evolutionGeneration > 1) {
        // Profile already evolved, don't overwrite
        developer.log(
          'Profile already evolved (generation ${existingProfile.evolutionGeneration}), skipping initialization',
          name: _logName,
        );
        return existingProfile;
      }

      // Start with default initial profile using agentId
      final baseProfile = PersonalityProfile.initial(agentId, userId: userId);
      final initialDimensions =
          Map<String, double>.from(baseProfile.dimensions);
      final initialConfidence =
          Map<String, double>.from(baseProfile.dimensionConfidence);

      // 1. Apply onboarding data (if provided)
      if (onboardingData != null && onboardingData.isNotEmpty) {
        final onboardingInsights = _mapOnboardingToDimensions(onboardingData);

        // Apply insights to dimensions (60% onboarding, 40% default)
        onboardingInsights.forEach((dimension, value) {
          final currentValue = initialDimensions[dimension] ?? 0.5;
          initialDimensions[dimension] =
              (currentValue * 0.4 + value * 0.6).clamp(0.0, 1.0);
          initialConfidence[dimension] = 0.3; // Some confidence from onboarding
        });
      }

      // 2. Apply social media insights (if provided)
      if (socialMediaData != null && socialMediaData.isNotEmpty) {
        try {
          final analyzer = SocialMediaVibeAnalyzer();
          final allProfileData =
              socialMediaData['profile'] as Map<String, dynamic>? ?? {};
          final platform = socialMediaData['platform'] as String? ?? 'unknown';

          // Extract platform-specific profile data
          final platformProfileData =
              allProfileData[platform] as Map<String, dynamic>? ??
                  allProfileData;

          final socialInsights = await analyzer.analyzeProfileForVibe(
            profileData: platformProfileData,
            follows:
                socialMediaData['follows'] as List<Map<String, dynamic>>? ?? [],
            connections:
                socialMediaData['connections'] as List<Map<String, dynamic>>? ??
                    [],
            platform: platform,
          );

          // Blend social media insights (40% social, 60% existing)
          socialInsights.forEach((dimension, socialValue) {
            final existingValue = initialDimensions[dimension] ?? 0.5;
            initialDimensions[dimension] =
                (existingValue * 0.6 + socialValue * 0.4).clamp(0.0, 1.0);
            initialConfidence[dimension] =
                (initialConfidence[dimension] ?? 0.0) + 0.2;
          });
        } catch (e) {
          developer.log('Error analyzing social media: $e', name: _logName);
          // Continue without social media data
        }
      }

      // 3. Use quantum engine for final dimension calculation (Phase 4)
      try {
        final quantumEngine = _resolveQuantumVibeEngine();

        // Convert initial dimensions to insight types for quantum compilation
        final personalityInsights = PersonalityVibeInsights(
          dominantTraits: _extractDominantTraits(initialDimensions),
          personalityStrength: _calculateAverageDimension(initialDimensions),
          evolutionMomentum: 0.3, // Initial momentum
          authenticityLevel:
              _calculateInitialAuthenticity(initialDimensions, onboardingData),
          confidenceLevel: _calculateAverageConfidence(initialConfidence),
        );

        final behavioralInsights = BehavioralVibeInsights(
          activityLevel: 0.5, // Default for new users
          explorationTendency:
              initialDimensions['exploration_eagerness'] ?? 0.5,
          socialEngagement: initialDimensions['community_orientation'] ?? 0.5,
          spontaneityIndex: initialDimensions['temporal_flexibility'] ?? 0.5,
          consistencyScore: 0.5, // Default for new users
        );

        final socialInsights = SocialVibeInsights(
          communityEngagement:
              initialDimensions['community_orientation'] ?? 0.5,
          socialPreference: initialDimensions['social_discovery_style'] ?? 0.5,
          leadershipTendency: initialDimensions['curation_tendency'] ?? 0.5,
          collaborationStyle:
              (initialDimensions['community_orientation'] ?? 0.5) * 0.5 +
                  (initialDimensions['social_discovery_style'] ?? 0.5) * 0.5,
          trustNetworkStrength:
              initialDimensions['trust_network_reliance'] ?? 0.5,
        );

        final relationshipInsights = RelationshipVibeInsights(
          connectionDepth: 0.5, // Default for new users
          relationshipStability: 0.5, // Default for new users
          influenceReceptivity:
              initialDimensions['trust_network_reliance'] ?? 0.5,
          givingTendency: initialDimensions['community_orientation'] ?? 0.5,
          boundaryFlexibility: initialDimensions['temporal_flexibility'] ?? 0.5,
        );

        final temporalInsights = TemporalVibeInsights(
          currentEnergyLevel: _calculateAverageDimension(initialDimensions),
          timeOfDayInfluence: 0.5, // Default
          weekdayInfluence: 0.5, // Default
          seasonalInfluence: 0.5, // Default
          contextualModifier: 1.0, // No context yet
        );

        // Use quantum engine to compile final dimensions
        final quantumDimensions =
            await quantumEngine.compileVibeDimensionsQuantum(
          personalityInsights,
          behavioralInsights,
          socialInsights,
          relationshipInsights,
          temporalInsights,
        );

        // Blend quantum dimensions with onboarding dimensions (70% quantum, 30% onboarding)
        quantumDimensions.forEach((dimension, quantumValue) {
          final onboardingValue = initialDimensions[dimension] ?? 0.5;
          initialDimensions[dimension] =
              (onboardingValue * 0.3 + quantumValue * 0.7).clamp(0.0, 1.0);
          // Increase confidence from quantum compilation
          initialConfidence[dimension] =
              (initialConfidence[dimension] ?? 0.0) + 0.1;
        });

        developer.log(
            '✅ Quantum compilation applied to ${quantumDimensions.length} dimensions',
            name: _logName);
      } catch (e) {
        developer.log(
            '⚠️ Quantum compilation failed, using classical dimensions: $e',
            name: _logName);
        // Continue with classical dimensions
      }

      // 4. Determine archetype from dimensions
      final archetype = _determineArchetypeFromDimensions(initialDimensions);

      // 5. Calculate initial authenticity
      final authenticity = _calculateInitialAuthenticity(
        initialDimensions,
        onboardingData,
      );

      // 6. Create profile with initial dimensions
      // Phase 8.3: Use agentId for privacy protection
      final newProfile = PersonalityProfile(
        agentId: agentId, // ✅ Use agentId as primary key
        userId: userId, // Keep for backward compatibility
        dimensions: initialDimensions,
        dimensionConfidence: initialConfidence,
        archetype: archetype,
        authenticity: authenticity,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
        evolutionGeneration: 1,
        learningHistory: {
          'total_interactions': 0,
          'successful_ai2ai_connections': 0,
          // Phase 8.3: Record agentId for debugging/telemetry (privacy-safe).
          'agent_id': agentId,
          'learning_sources': [
            if (onboardingData != null) 'onboarding',
            if (socialMediaData != null) 'social_media',
          ],
          'evolution_milestones': [DateTime.now()],
          'onboarding_data_used': onboardingData != null,
          'social_media_data_used': socialMediaData != null,
        },
      );

      await _savePersonalityProfile(newProfile);
      _currentProfile = newProfile;

      developer.log(
          '✅ Personality initialized with agentId: ${agentId.substring(0, 10)}...',
          name: _logName);
      return newProfile;
    } catch (e, stackTrace) {
      developer.log('Error initializing from onboarding: $e',
          name: _logName, error: e, stackTrace: stackTrace);
      // Fallback to default
      final agentIdService = _resolveAgentIdService();
      final agentId = await agentIdService.getUserAgentId(userId);
      return PersonalityProfile.initial(agentId, userId: userId);
    }
  }

  /// Map onboarding data to personality dimensions
  Map<String, double> _mapOnboardingToDimensions(
    Map<String, dynamic> onboardingData,
  ) {
    final mapper = OnboardingDimensionMapper();
    return mapper.mapOnboardingToDimensions(onboardingData);
  }

  /// Determine archetype from initial dimensions
  String _determineArchetypeFromDimensions(Map<String, double> dimensions) {
    final exploration = dimensions['exploration_eagerness'] ?? 0.5;
    final social = dimensions['social_discovery_style'] ?? 0.5;
    final energy = (dimensions['exploration_eagerness'] ?? 0.5) +
        (dimensions['temporal_flexibility'] ?? 0.5) +
        (dimensions['location_adventurousness'] ?? 0.5);
    final avgEnergy = energy / 3.0;

    if (exploration >= 0.8 && avgEnergy >= 0.7) {
      return 'adventurous_explorer';
    }
    if (social >= 0.8 && avgEnergy >= 0.6) {
      return 'social_connector';
    }
    if (exploration <= 0.3 && social >= 0.7) {
      return 'community_curator';
    }
    if (exploration >= 0.7 && social <= 0.4) {
      return 'authentic_seeker';
    }
    if (avgEnergy >= 0.8) {
      return 'spontaneous_wanderer';
    }

    return 'balanced_explorer';
  }

  /// Calculate initial authenticity from dimensions and onboarding data
  double _calculateInitialAuthenticity(
    Map<String, double> dimensions,
    Map<String, dynamic>? onboardingData,
  ) {
    // Base authenticity from dimension consistency
    double consistency = 0.0;
    int count = 0;

    // Check consistency between related dimensions
    final exploration = dimensions['exploration_eagerness'] ?? 0.5;
    final location = dimensions['location_adventurousness'] ?? 0.5;
    final temporal = dimensions['temporal_flexibility'] ?? 0.5;

    // Exploration-related consistency
    final explorationConsistency = 1.0 - (exploration - location).abs();
    consistency += explorationConsistency;
    count++;

    // Temporal consistency
    final temporalConsistency = 1.0 - (temporal - exploration).abs();
    consistency += temporalConsistency;
    count++;

    final baseAuthenticity = count > 0 ? consistency / count : 0.5;

    // Boost from onboarding data completeness
    double completenessBoost = 0.0;
    if (onboardingData != null) {
      int completedFields = 0;
      int totalFields =
          7; // age, homebase, favoritePlaces, preferences, baselineLists, respectedFriends, socialMedia

      if (onboardingData['age'] != null) completedFields++;
      if (onboardingData['homebase'] != null &&
          (onboardingData['homebase'] as String).isNotEmpty) {
        completedFields++;
      }
      if ((onboardingData['favoritePlaces'] as List?)?.isNotEmpty ?? false) {
        completedFields++;
      }
      if ((onboardingData['preferences'] as Map?)?.isNotEmpty ?? false) {
        completedFields++;
      }
      if ((onboardingData['baselineLists'] as List?)?.isNotEmpty ?? false) {
        completedFields++;
      }
      if ((onboardingData['respectedFriends'] as List?)?.isNotEmpty ?? false) {
        completedFields++;
      }
      if ((onboardingData['socialMediaConnected'] as Map?)?.isNotEmpty ?? false) {
        completedFields++;
      }

      completenessBoost =
          (completedFields / totalFields) * 0.2; // Up to 0.2 boost
    }

    return (baseAuthenticity + completenessBoost).clamp(0.0, 1.0);
  }

  /// Extract dominant traits from dimensions
  List<String> _extractDominantTraits(Map<String, double> dimensions) {
    final traits = <String>[];
    dimensions.forEach((dimension, value) {
      if (value > 0.7) {
        traits.add(dimension);
      }
    });
    return traits;
  }

  /// Calculate average dimension value
  double _calculateAverageDimension(Map<String, double> dimensions) {
    if (dimensions.isEmpty) return 0.5;
    final sum = dimensions.values.fold(0.0, (a, b) => a + b);
    return (sum / dimensions.length).clamp(0.0, 1.0);
  }

  /// Calculate average confidence
  double _calculateAverageConfidence(Map<String, double> confidence) {
    if (confidence.isEmpty) return 0.5;
    final sum = confidence.values.fold(0.0, (a, b) => a + b);
    return (sum / confidence.length).clamp(0.0, 1.0);
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
    // Phase 8.3: Get agentId for privacy protection
    final agentIdService = _resolveAgentIdService();
    final agentId = await agentIdService.getUserAgentId(userId);

    // Load profile for this specific agentId (don't rely on shared _currentProfile)
    // This ensures correct behavior when called concurrently for different users
    PersonalityProfile profile;
    if (_currentProfile != null && _currentProfile!.agentId == agentId) {
      // Use cached profile if it matches the requested agentId
      profile = _currentProfile!;
    } else {
      // Load from storage to ensure we have the correct profile for this agentId
      final loadedProfile = await _loadPersonalityProfile(agentId);
      if (loadedProfile != null) {
        profile = loadedProfile;
        // Update cache only if it matches
        _currentProfile = profile;
      } else {
        // No profile exists, initialize new one
        profile = await initializePersonality(userId);
      }
    }

    // Note: _isLearning flag is intentionally not checked here
    // Concurrent evolution for different users should be allowed
    // The flag would prevent concurrent evolution even for different users, which is too restrictive

    try {
      developer.log('Evolving personality from user action: ${action.type}',
          name: _logName);

      // Analyze action for personality insights
      final dimensionUpdates = await _analyzeActionForDimensions(action);
      final confidenceUpdates = await _analyzeActionForConfidence(action);

      // Calculate golden expert weight if applicable
      double influenceWeight = 1.0;
      if (localExpertise != null) {
        influenceWeight =
            _goldenExpertService.calculateInfluenceWeight(localExpertise);
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
      final evolvedProfile = profile.evolve(
        newDimensions: adjustedUpdates,
        newConfidence: confidenceUpdates,
        newAuthenticity: newAuthenticity,
        additionalLearning: learningData,
      );

      // Save updated profile locally
      await _savePersonalityProfile(evolvedProfile);
      // Update cache only if it matches the userId we just evolved
      // Phase 8.3: Check by agentId
      final agentIdService = _resolveAgentIdService();
      final agentId = await agentIdService.getUserAgentId(userId);
      if (_currentProfile == null || _currentProfile!.agentId == agentId) {
        _currentProfile = evolvedProfile;
      }

      developer.log(
          'Personality evolved to generation ${evolvedProfile.evolutionGeneration}',
          name: _logName);
      developer.log('Dominant traits: ${evolvedProfile.getDominantTraits()}',
          name: _logName);

      // Sync to cloud if enabled (non-blocking)
      _syncProfileToCloud(userId, evolvedProfile);

      // Notify listeners of personality evolution
      if (onPersonalityEvolved != null) {
        try {
          onPersonalityEvolved!(userId, evolvedProfile);
        } catch (e) {
          developer.log('Error in personality evolution callback: $e',
              name: _logName);
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
  ///
  /// NEW: Supports outcome-based learning from real-world actions.
  Future<PersonalityProfile> evolveFromAI2AILearning(
    String userId,
    AI2AILearningInsight insight, {
    OutcomeResult? outcome, // NEW: Real-world action outcome
  }) async {
    if (_currentProfile == null) {
      await initializePersonality(userId);
    }

    if (_isLearning) {
      developer.log(
          'Personality learning already in progress, queuing AI2AI learning',
          name: _logName);
      return _currentProfile!;
    }

    _isLearning = true;

    try {
      developer.log('Evolving personality from AI2AI learning: ${insight.type}',
          name: _logName);

      // Apply AI2AI learning rate (typically lower than direct user actions)
      // Also apply age-based learning filter if user data is available
      final adjustedInsights = <String, double>{};
      
      // ========================================
      // DRIFT PREVENTION SAFEGUARD (Phase 11 Enhancement)
      // ========================================
      // Maximum drift: 30% from original personality (contextual layer)
      // Core personality should be completely stable
      final maxDrift = 0.30;
      final originalDimensions = _currentProfile!.evolutionTimeline.isNotEmpty
          ? _currentProfile!.evolutionTimeline.first.corePersonality
          : _currentProfile!.dimensions;
      
      insight.dimensionInsights.forEach((dimension, change) {
        double learningRate = VibeConstants.ai2aiLearningRate;
        final proposedChange = change * learningRate;
        
        // Check drift limit before applying change
        final currentValue = _currentProfile!.dimensions[dimension] ?? 0.5;
        final originalValue = originalDimensions[dimension] ?? currentValue;
        final proposedValue = currentValue + proposedChange;
        
        // Calculate drift from original
        final drift = (proposedValue - originalValue).abs();
        
        if (drift > maxDrift) {
          developer.log(
            'Drift limit exceeded for $dimension: drift ${(drift * 100).toStringAsFixed(1)}% '
            'exceeds max ${(maxDrift * 100).toStringAsFixed(1)}% - clamping to max drift',
            name: _logName,
          );
          
          // Clamp to max drift
          final clampedValue = originalValue + 
              (proposedValue > originalValue ? maxDrift : -maxDrift);
          adjustedInsights[dimension] = clampedValue - currentValue;
        } else {
          adjustedInsights[dimension] = proposedChange;
        }
      });

      // NEW: Apply outcome-based learning if outcome is available
      if (outcome != null) {
        final outcomeInsights = _calculateOutcomeInsights(
          outcome: outcome,
          baseInsights: adjustedInsights,
        );

        // Merge outcome insights with base insights
        outcomeInsights.forEach((dimension, outcomeChange) {
          adjustedInsights[dimension] =
              (adjustedInsights[dimension] ?? 0.0) + outcomeChange;
        });

        developer.log(
          'Applied outcome-based learning: ${outcome.outcomeType}, score: ${outcome.outcomeScore}',
          name: _logName,
        );
      }

      // Create learning history entry
      final learningData = {
        'total_interactions': 1,
        'successful_ai2ai_connections': 1,
        'learning_source': 'ai2ai_interaction',
        'insight_type': insight.type.toString(),
        'dimension_changes': adjustedInsights,
        'outcome_applied': outcome != null,
        'outcome_type': outcome?.outcomeType.toString(),
        'outcome_score': outcome?.outcomeScore,
      };

      // Evolve personality with AI2AI insights (including outcome-based)
      final evolvedProfile = _currentProfile!.evolve(
        newDimensions: adjustedInsights,
        additionalLearning: learningData,
      );

      // Save updated profile locally
      await _savePersonalityProfile(evolvedProfile);
      _currentProfile = evolvedProfile;

      developer.log(
          'Personality evolved from AI2AI learning to generation ${evolvedProfile.evolutionGeneration}',
          name: _logName);

      // Sync to cloud if enabled (non-blocking)
      _syncProfileToCloud(userId, evolvedProfile);

      // Notify listeners of personality evolution
      if (onPersonalityEvolved != null) {
        try {
          onPersonalityEvolved!(userId, evolvedProfile);
        } catch (e) {
          developer.log('Error in personality evolution callback: $e',
              name: _logName);
        }
      }

      return evolvedProfile;
    } catch (e) {
      developer.log('Error evolving personality from AI2AI learning: $e',
          name: _logName);
      return _currentProfile!;
    } finally {
      _isLearning = false;
    }
  }

  /// Get current personality profile
  /// Phase 8.3: Uses agentId internally for privacy protection
  Future<PersonalityProfile?> getCurrentPersonality(String userId) async {
    // Get agentId for privacy protection
    final agentIdService = _resolveAgentIdService();
    final agentId = await agentIdService.getUserAgentId(userId);

    if (_currentProfile != null && _currentProfile!.agentId == agentId) {
      return _currentProfile;
    }

    return await _loadPersonalityProfile(agentId);
  }

  /// Get personality evolution history
  /// Phase 8.3: Uses agentId internally for privacy protection
  Future<List<PersonalityEvolutionEvent>> getEvolutionHistory(
      String userId) async {
    try {
      // Get agentId for privacy protection
      final agentIdService = _resolveAgentIdService();
      final agentId = await agentIdService.getUserAgentId(userId);

      // Try agentId key first, then userId key for migration
      var historyJson = _prefs.getString('${_learningHistoryKey}_$agentId');
      if (historyJson == null && userId != agentId) {
        historyJson = _prefs.getString('${_learningHistoryKey}_$userId');
      }
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
      reasons.add(
          'Personality needs more development (${profile.learningHistory['total_interactions']} interactions)');
    }

    // Check confidence levels
    final avgConfidence = profile.dimensionConfidence.values.isNotEmpty
        ? profile.dimensionConfidence.values.reduce((a, b) => a + b) /
            profile.dimensionConfidence.length
        : 0.0;

    if (avgConfidence >= VibeConstants.personalityConfidenceThreshold) {
      readinessScore += 0.3;
    } else {
      reasons.add(
          'Low confidence in personality dimensions (${(avgConfidence * 100).toStringAsFixed(1)}%)');
    }

    // Check authenticity score
    if (profile.authenticity >= 0.6) {
      readinessScore += 0.2;
    } else {
      reasons.add(
          'Low authenticity score (${(profile.authenticity * 100).toStringAsFixed(1)}%)');
    }

    // Check evolution generation (more evolved = more ready)
    if (profile.evolutionGeneration >= 5) {
      readinessScore += 0.1;
    } else {
      reasons.add(
          'Personality needs more evolution (generation ${profile.evolutionGeneration})');
    }

    return PersonalityReadiness(
      isReady: readinessScore >= 0.7,
      readinessScore: readinessScore,
      reasons: reasons,
    );
  }

  /// Reset personality learning (for testing or user request)
  /// Phase 8.3: Uses agentId for privacy protection
  Future<void> resetPersonality(String userId) async {
    developer.log('Resetting personality for user: $userId', name: _logName);

    // Get agentId for privacy protection
    final agentIdService = _resolveAgentIdService();
    final agentId = await agentIdService.getUserAgentId(userId);

    // Remove both agentId and userId keys (for migration cleanup)
    await _prefs.remove('${_personalityProfileKey}_$agentId');
    if (userId != agentId) {
      await _prefs.remove('${_personalityProfileKey}_$userId');
    }
    await _prefs.remove('${_learningHistoryKey}_$agentId');
    if (userId != agentId) {
      await _prefs.remove('${_learningHistoryKey}_$userId');
    }
    await _prefs.remove('${_dimensionConfidenceKey}_$userId');

    _currentProfile = null;

    developer.log('Personality reset completed', name: _logName);
  }

  // Private helper methods
  /// Load personality profile by agentId (primary) or userId (fallback for migration)
  Future<PersonalityProfile?> _loadPersonalityProfile(String identifier) async {
    try {
      // Try agentId first (new format)
      var profileJson =
          _prefs.getString('${_personalityProfileKey}_$identifier');

      // If not found and identifier looks like userId, try legacy format
      if (profileJson == null && !identifier.startsWith('agent_')) {
        // This might be a userId - try legacy format
        profileJson = _prefs.getString('${_personalityProfileKey}_$identifier');
      }

      if (profileJson == null) return null;

      // Parse JSON and create profile
      try {
        final profileMap = jsonDecode(profileJson) as Map<String, dynamic>;
        final profile = PersonalityProfile.fromJson(profileMap);

        // Migration: If profile loaded with userId but has no agentId, migrate it
        if (profile.agentId == identifier &&
            profile.userId == null &&
            identifier.startsWith('agent_')) {
          // Already using agentId, good
          return profile;
        } else if (!identifier.startsWith('agent_')) {
          // This is a userId - need to get agentId and migrate
          try {
            final agentIdService = _resolveAgentIdService();
            final agentId = await agentIdService.getUserAgentId(identifier);

            // If profile doesn't have agentId, migrate it
            if (profile.agentId == identifier || profile.userId == identifier) {
              final migratedProfile = PersonalityProfile(
                agentId: agentId,
                userId: identifier, // Keep userId for reference
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
                isInTransition: profile.isInTransition,
                activeTransition: profile.activeTransition,
              );

              // Save migrated profile with agentId key
              await _savePersonalityProfile(migratedProfile);
              return migratedProfile;
            }
          } catch (e) {
            developer.log('Error migrating profile: $e', name: _logName);
            // Return original profile if migration fails
          }
        }

        return profile;
      } catch (e) {
        developer.log('Error parsing personality profile JSON: $e',
            name: _logName);
        return null;
      }
    } catch (e) {
      developer.log('Error loading personality profile: $e', name: _logName);
      return null;
    }
  }

  Future<void> _savePersonalityProfile(PersonalityProfile profile) async {
    try {
      // Serialize profile to JSON
      final profileJson = jsonEncode(profile.toJson());

      // Phase 8.3: Use agentId as storage key (primary)
      await _prefs.setString(
        '${_personalityProfileKey}_${profile.agentId}',
        profileJson,
      );

      // Also save with userId key if provided (for backward compatibility during migration)
      if (profile.userId != null && profile.userId != profile.agentId) {
        await _prefs.setString(
          '${_personalityProfileKey}_${profile.userId}',
          profileJson,
        );
      }

      developer.log(
          'Personality profile saved (generation ${profile.evolutionGeneration}, agentId: ${profile.agentId.substring(0, 10)}...)',
          name: _logName);
    } catch (e) {
      developer.log('Error saving personality profile: $e', name: _logName);
    }
  }

  /// Sync profile to cloud if enabled (non-blocking, fire-and-forget)
  /// Phase 8.3: Uses agentId internally, but syncService may still use userId
  void _syncProfileToCloud(String userId, PersonalityProfile profile) {
    // Run async without awaiting to avoid blocking evolution
    Future.microtask(() async {
      try {
        final syncService = _tryResolvePersonalitySyncService();
        if (syncService == null) {
          developer.log(
            'PersonalitySyncService not registered; skipping cloud sync',
            name: _logName,
          );
          return null;
        }
        // Note: syncService may still use userId for cloud sync (that's okay)
        final syncEnabled = await syncService.isCloudSyncEnabled(userId);

        if (!syncEnabled) {
          return; // Sync disabled, skip
        }

        // Get password from secure storage (stored during login)
        const secureStorage = FlutterSecureStorage();
        final password = await secureStorage.read(
          key: 'user_password_session_$userId',
        );

        if (password != null && password.isNotEmpty) {
          await syncService.syncToCloud(userId, profile, password);
          developer.log(
              'Profile synced to cloud (generation ${profile.evolutionGeneration})',
              name: _logName);
        } else {
          developer.log('Password not available for cloud sync',
              name: _logName);
        }
      } catch (e) {
        developer.log('Error syncing profile to cloud: $e', name: _logName);
        // Don't throw - sync failures shouldn't block evolution
      }
    });
  }

  Future<Map<String, double>> _analyzeActionForDimensions(
      UserAction action) async {
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
        final distanceTraveled =
            action.metadata['distance_km'] as double? ?? 0.0;
        if (distanceTraveled > 10.0) {
          dimensionUpdates['location_adventurousness'] = 0.08;
        }

        // NEW: Energy preference (Phase 2)
        final spotEnergyLevel =
            action.metadata['spot_energy_level'] as double? ?? 0.5;
        dimensionUpdates['energy_preference'] = (spotEnergyLevel - 0.5) * 0.15;

        // NEW: Novelty seeking (Phase 2)
        final isRepeatVisit =
            action.metadata['is_repeat_visit'] as bool? ?? false;
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

  Future<Map<String, double>> _analyzeActionForConfidence(
      UserAction action) async {
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
        confidenceUpdates['community_orientation'] =
            baseConfidenceIncrease * 1.5;
        confidenceUpdates['social_discovery_style'] = baseConfidenceIncrease;
        break;

      case UserActionType.spontaneousActivity:
        confidenceUpdates['temporal_flexibility'] =
            baseConfidenceIncrease * 1.2;
        break;

      case UserActionType.curationActivity:
        confidenceUpdates['curation_tendency'] = baseConfidenceIncrease * 1.3;
        break;

      case UserActionType.authenticPreference:
        confidenceUpdates['authenticity_preference'] =
            baseConfidenceIncrease * 1.1;
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
        final spotPopularity =
            action.metadata['spot_popularity'] as double? ?? 0.5;
        if (spotPopularity < 0.3) {
          authenticityChange = 0.02;
        }
        break;
      default:
        // Neutral actions don't affect authenticity much
        break;
    }

    final newAuthenticity =
        (_currentProfile!.authenticity + authenticityChange).clamp(0.0, 1.0);
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
      // Fallback - should not happen in normal flow
      final agentIdService = _resolveAgentIdService();
      const userId = 'user';
      final agentId = await agentIdService.getUserAgentId(userId);
      // Phase 8.3: Use agentId for privacy protection
      _currentProfile = PersonalityProfile.initial(agentId, userId: userId);
    }
    return _currentProfile!;
  }

  Future<List<BehavioralPattern>> recognizeBehavioralPatterns(
      List<UserAction> actions) async {
    return [];
  }

  Future<Map<String, double>> predictFuturePreferences() async {
    if (_currentProfile == null) return {};
    return Map<String, double>.from(_currentProfile!.dimensions);
  }

  Future<void> updatePersonalityProfile(
      Map<String, dynamic> personalityData) async {}

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
      hashedUserId: _currentProfile!.agentId.hashCode.toString(),
      hashedSignature: (_currentProfile!.agentId + _currentProfile!.archetype)
          .hashCode
          .toString(),
      anonymizedDimensions:
          Map<String, double>.from(_currentProfile!.dimensions),
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

/// Calculate outcome-based insights
///
/// NEW: Calculates personality dimension changes based on real-world action outcomes.
/// Positive outcomes boost similar opportunities, negative outcomes reduce them.
Map<String, double> _calculateOutcomeInsights({
  required OutcomeResult outcome,
  required Map<String, double> baseInsights,
}) {
  final outcomeInsights = <String, double>{};

  // Outcome learning rate (2x base convergence rate)
  const outcomeLearningRate = VibeConstants.ai2aiLearningRate * 2.0;

  // Calculate outcome vector based on outcome type and score
  double outcomeMultiplier;
  switch (outcome.outcomeType) {
    case OutcomeType.positive:
      // Positive outcome: boost dimensions that led to this opportunity
      outcomeMultiplier = outcome.outcomeScore; // 0.7 to 1.0
      break;
    case OutcomeType.negative:
      // Negative outcome: reduce dimensions that led to this opportunity
      outcomeMultiplier = -(1.0 - outcome.outcomeScore); // -0.3 to -0.0
      break;
    case OutcomeType.neutral:
      // Neutral outcome: minimal change
      outcomeMultiplier = (outcome.outcomeScore - 0.5) * 0.2; // -0.1 to +0.1
      break;
  }

  // Apply outcome to each dimension that was influenced
  baseInsights.forEach((dimension, baseChange) {
    // Outcome change = base change × outcome multiplier × outcome learning rate
    final outcomeChange = baseChange * outcomeMultiplier * outcomeLearningRate;
    outcomeInsights[dimension] = outcomeChange;
  });

  return outcomeInsights;
}
  // Remove duplicate methods below; keep single minimal versions
  

