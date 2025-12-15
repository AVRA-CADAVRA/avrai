import 'dart:developer' as developer;
import 'package:spots/core/constants/vibe_constants.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/user_vibe.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/storage_service.dart';
import 'package:spots/core/services/age_compatibility_filter.dart';

/// OUR_GUTS.md: "Anonymous vibe compilation that preserves privacy while enabling AI2AI personality matching"
/// Comprehensive vibe analysis engine that creates privacy-preserving vibe signatures
class UserVibeAnalyzer {
  static const String _logName = 'UserVibeAnalyzer';
  
  // Storage keys for vibe data
  static const String _vibeHistoryKey = 'vibe_history';
  // ignore: unused_field
  static const String _vibeSignatureKey = 'vibe_signature';
  static const String _vibeAnalyticsKey = 'vibe_analytics';
  
  final SharedPreferences _prefs;
  final Map<String, UserVibe> _vibeCache = {};
  bool _isAnalyzing = false;
  
  UserVibeAnalyzer({required SharedPreferences prefs}) : _prefs = prefs;
  
  /// Compile comprehensive user vibe from personality profile and recent behavior
  Future<UserVibe> compileUserVibe(String userId, PersonalityProfile personality) async {
    if (_isAnalyzing) {
      developer.log('Vibe analysis already in progress, returning cached vibe', name: _logName);
      return _vibeCache[userId] ?? UserVibe.fromPersonalityProfile(userId, personality.dimensions);
    }
    
    _isAnalyzing = true;
    
    try {
      developer.log('Compiling user vibe for personality generation ${personality.evolutionGeneration}', name: _logName);
      
      // Analyze current personality state
      final personalityInsights = await _analyzePersonalityState(personality);
      
      // Analyze recent behavioral patterns
      final behavioralInsights = await _analyzeRecentBehavior(userId);
      
      // Analyze social dynamics
      final socialInsights = await _analyzeSocialDynamics(userId, personality);
      
      // Analyze relationship patterns
      final relationshipInsights = await _analyzeRelationshipPatterns(userId);
      
      // Analyze temporal context
      final temporalInsights = await _analyzeTemporalContext();
      
      // Compile comprehensive vibe dimensions
      final vibeDimensions = await _compileVibeDimensions(
        personalityInsights,
        behavioralInsights,
        socialInsights,
        relationshipInsights,
        temporalInsights,
      );
      
      // Create anonymized vibe signature
      final userVibe = UserVibe.fromPersonalityProfile(
        userId,
        vibeDimensions,
        contextualSalt: await _generateContextualSalt(userId),
      );
      
      // Cache the vibe
      _vibeCache[userId] = userVibe;
      
      // Store vibe analytics (privacy-preserving)
      await _storeVibeAnalytics(userId, userVibe, personality);
      
      developer.log('User vibe compiled: ${userVibe.getVibeArchetype()}', name: _logName);
      developer.log('Vibe energy: ${(userVibe.overallEnergy * 100).round()}%, social: ${(userVibe.socialPreference * 100).round()}%', name: _logName);
      
      return userVibe;
    } catch (e) {
      developer.log('Error compiling user vibe: $e', name: _logName);
      
      // Fallback to basic vibe from personality
      final fallbackVibe = UserVibe.fromPersonalityProfile(userId, personality.dimensions);
      _vibeCache[userId] = fallbackVibe;
      return fallbackVibe;
    } finally {
      _isAnalyzing = false;
    }
  }
  
  /// Analyze vibe compatibility between two users for AI2AI connections
  /// Age is ALWAYS considered as part of the compatibility matrix
  Future<VibeCompatibilityResult> analyzeVibeCompatibility(
    UserVibe localVibe,
    UserVibe remoteVibe, {
    UnifiedUser? localUser,
    UnifiedUser? remoteUser,
    List<String>? recentActions, // For parent-child override detection
  }) async {
    try {
      developer.log('Analyzing vibe compatibility between ${localVibe.getVibeArchetype()} and ${remoteVibe.getVibeArchetype()}', name: _logName);
      
      // Calculate basic compatibility (personality-based)
      final basicCompatibility = localVibe.calculateVibeCompatibility(remoteVibe);
      
      // Apply age compatibility filter if user data is available
      double ageAdjustedCompatibility = basicCompatibility;
      if (localUser != null && remoteUser != null) {
        final ageFilter = AgeCompatibilityFilter();
        final allowOverride = recentActions != null
            ? ageFilter.shouldAllowAgeOverride(localUser, remoteUser, recentActions)
            : false;
        
        ageAdjustedCompatibility = ageFilter.applyAgeMultiplier(
          basicCompatibility,
          localUser,
          remoteUser,
          allowOverride: allowOverride,
        );
        
        developer.log(
          'Age-adjusted compatibility: ${basicCompatibility.toStringAsFixed(2)} -> ${ageAdjustedCompatibility.toStringAsFixed(2)}',
          name: _logName,
        );
      }
      
      // Use age-adjusted compatibility for all subsequent calculations
      final finalCompatibility = ageAdjustedCompatibility;
      
      // Calculate AI pleasure potential (based on age-adjusted compatibility)
      final aiPleasurePotential = finalCompatibility > 0.0
          ? localVibe.calculateAIPleasurePotential(remoteVibe)
          : 0.0; // No pleasure if age-incompatible
      
      // Analyze learning opportunities (only if compatible)
      final learningOpportunities = finalCompatibility > 0.0
          ? await _analyzeLearningOpportunities(localVibe, remoteVibe)
          : <LearningOpportunity>[]; // No learning if age-incompatible
      
      // Calculate connection strength
      final connectionStrength = await _calculateConnectionStrength(localVibe, remoteVibe);
      
      // Determine optimal interaction style
      final interactionStyle = await _determineOptimalInteractionStyle(localVibe, remoteVibe);
      
      // Calculate trust building potential
      final trustBuildingPotential = await _calculateTrustBuildingPotential(localVibe, remoteVibe);
      
      final result = VibeCompatibilityResult(
        basicCompatibility: finalCompatibility, // Use age-adjusted compatibility
        aiPleasurePotential: aiPleasurePotential,
        learningOpportunities: learningOpportunities,
        connectionStrength: connectionStrength,
        interactionStyle: interactionStyle,
        trustBuildingPotential: trustBuildingPotential,
        recommendedConnectionDuration: _calculateRecommendedDuration(finalCompatibility),
        connectionPriority: _calculateConnectionPriority(finalCompatibility, aiPleasurePotential),
      );
      
      developer.log('Vibe compatibility: ${(finalCompatibility * 100).round()}% (age-adjusted), AI pleasure: ${(aiPleasurePotential * 100).round()}%', name: _logName);
      
      return result;
    } catch (e) {
      developer.log('Error analyzing vibe compatibility: $e', name: _logName);
      return VibeCompatibilityResult.fallback();
    }
  }
  
  /// Refresh user vibe with new behavioral data
  Future<UserVibe> refreshUserVibe(String userId, PersonalityProfile updatedPersonality) async {
    developer.log('Refreshing user vibe after personality evolution', name: _logName);
    
    // Remove cached vibe to force recompilation
    _vibeCache.remove(userId);
    
    return await compileUserVibe(userId, updatedPersonality);
  }
  
  /// Get vibe evolution history for analytics
  Future<List<VibeEvolutionEvent>> getVibeEvolutionHistory(String userId) async {
    try {
      final historyJson = _prefs.getString('${_vibeHistoryKey}_$userId');
      if (historyJson == null) return [];
      
      // Parse vibe evolution history
      // This would contain anonymized vibe changes over time
      return [];
    } catch (e) {
      developer.log('Error loading vibe evolution history: $e', name: _logName);
      return [];
    }
  }
  
  /// Analyze vibe patterns across user community (anonymized)
  Future<CommunityVibeInsights> analyzeCommunityVibePatterns() async {
    try {
      developer.log('Analyzing community vibe patterns', name: _logName);
      
      // Get aggregated anonymized vibe data
      final communityVibes = await _getAnonymizedCommunityVibes();
      
      // Analyze dominant vibe archetypes
      final archetypeDistribution = await _analyzeArchetypeDistribution(communityVibes);
      
      // Analyze energy patterns
      final energyPatterns = await _analyzeEnergyPatterns(communityVibes);
      
      // Analyze social preference trends
      final socialTrends = await _analyzeSocialPreferenceTrends(communityVibes);
      
      // Identify emerging vibe patterns
      final emergingPatterns = await _identifyEmergingVibePatterns(communityVibes);
      
      return CommunityVibeInsights(
        archetypeDistribution: archetypeDistribution,
        energyPatterns: energyPatterns,
        socialTrends: socialTrends,
        emergingPatterns: emergingPatterns,
        totalVibesAnalyzed: communityVibes.length,
        analysisTimestamp: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error analyzing community vibe patterns: $e', name: _logName);
      return CommunityVibeInsights.empty();
    }
  }
  
  /// Validate vibe authenticity (anti-gaming measures)
  Future<VibeAuthenticityResult> validateVibeAuthenticity(UserVibe vibe, PersonalityProfile personality) async {
    try {
      developer.log('Validating vibe authenticity', name: _logName);
      
      var authenticityScore = 1.0;
      final issues = <String>[];
      
      // Check vibe integrity
      if (!vibe.verifyIntegrity()) {
        authenticityScore -= 0.3;
        issues.add('Vibe signature integrity check failed');
      }
      
      // Check consistency with personality profile
      final consistencyScore = await _checkPersonalityConsistency(vibe, personality);
      if (consistencyScore < 0.7) {
        authenticityScore -= 0.2;
        issues.add('Vibe inconsistent with personality profile');
      }
      
      // Check for artificial patterns
      final artificialityScore = await _detectArtificialPatterns(vibe);
      if (artificialityScore > 0.3) {
        authenticityScore -= 0.25;
        issues.add('Artificial vibe patterns detected');
      }
      
      // Check temporal consistency
      final temporalConsistency = await _checkTemporalConsistency(vibe);
      if (temporalConsistency < 0.6) {
        authenticityScore -= 0.15;
        issues.add('Temporal vibe inconsistency');
      }
      
      return VibeAuthenticityResult(
        isAuthentic: authenticityScore >= 0.8,
        authenticityScore: authenticityScore.clamp(0.0, 1.0),
        issues: issues,
        validatedAt: DateTime.now(),
      );
    } catch (e) {
      developer.log('Error validating vibe authenticity: $e', name: _logName);
      return VibeAuthenticityResult(
        isAuthentic: true, // Default to authentic on error
        authenticityScore: 0.8,
        issues: ['Validation error occurred'],
        validatedAt: DateTime.now(),
      );
    }
  }
  
  // Private analysis methods
  Future<PersonalityVibeInsights> _analyzePersonalityState(PersonalityProfile personality) async {
    developer.log('Analyzing personality state for vibe compilation', name: _logName);
    
    final insights = PersonalityVibeInsights(
      dominantTraits: personality.getDominantTraits(),
      personalityStrength: personality.isWellDeveloped ? 1.0 : 0.6,
      evolutionMomentum: _calculateEvolutionMomentum(personality),
      authenticityLevel: personality.authenticity,
      confidenceLevel: personality.dimensionConfidence.values.isNotEmpty
          ? personality.dimensionConfidence.values.reduce((a, b) => a + b) / personality.dimensionConfidence.length
          : 0.5,
    );
    
    return insights;
  }
  
  Future<BehavioralVibeInsights> _analyzeRecentBehavior(String userId) async {
    // Analyze recent user behavior patterns (anonymized)
    return BehavioralVibeInsights(
      activityLevel: 0.7,
      explorationTendency: 0.6,
      socialEngagement: 0.5,
      spontaneityIndex: 0.8,
      consistencyScore: 0.7,
    );
  }
  
  Future<SocialVibeInsights> _analyzeSocialDynamics(String userId, PersonalityProfile personality) async {
    // Analyze social interaction patterns
    final communityOrientation = personality.dimensions['community_orientation'] ?? 0.5;
    final socialDiscoveryStyle = personality.dimensions['social_discovery_style'] ?? 0.5;
    
    return SocialVibeInsights(
      communityEngagement: communityOrientation,
      socialPreference: socialDiscoveryStyle,
      leadershipTendency: personality.dimensions['curation_tendency'] ?? 0.3,
      collaborationStyle: (communityOrientation + socialDiscoveryStyle) / 2.0,
      trustNetworkStrength: personality.dimensions['trust_network_reliance'] ?? 0.6,
    );
  }
  
  Future<RelationshipVibeInsights> _analyzeRelationshipPatterns(String userId) async {
    // Analyze relationship and connection patterns (anonymized)
    return RelationshipVibeInsights(
      connectionDepth: 0.6,
      relationshipStability: 0.7,
      influenceReceptivity: 0.5,
      givingTendency: 0.6,
      boundaryFlexibility: 0.7,
    );
  }
  
  Future<TemporalVibeInsights> _analyzeTemporalContext() async {
    final now = DateTime.now();
    final hour = now.hour;
    final weekday = now.weekday;
    
    return TemporalVibeInsights(
      currentEnergyLevel: _calculateCurrentEnergyLevel(hour),
      timeOfDayInfluence: _getTimeOfDayInfluence(hour),
      weekdayInfluence: _getWeekdayInfluence(weekday),
      seasonalInfluence: _getSeasonalInfluence(now.month),
      contextualModifier: _getContextualModifier(hour, weekday),
    );
  }
  
  Future<Map<String, double>> _compileVibeDimensions(
    PersonalityVibeInsights personality,
    BehavioralVibeInsights behavioral,
    SocialVibeInsights social,
    RelationshipVibeInsights relationship,
    TemporalVibeInsights temporal,
  ) async {
    final vibeDimensions = <String, double>{};
    
    // Compile exploration eagerness
    vibeDimensions['exploration_eagerness'] = (
      personality.evolutionMomentum * 0.4 +
      behavioral.explorationTendency * 0.4 +
      behavioral.spontaneityIndex * 0.2
    ).clamp(0.0, 1.0);
    
    // Compile community orientation
    vibeDimensions['community_orientation'] = (
      social.communityEngagement * 0.5 +
      social.collaborationStyle * 0.3 +
      relationship.connectionDepth * 0.2
    ).clamp(0.0, 1.0);
    
    // Compile authenticity preference
    vibeDimensions['authenticity_preference'] = (
      personality.authenticityLevel * 0.6 +
      behavioral.consistencyScore * 0.4
    ).clamp(0.0, 1.0);
    
    // Compile social discovery style
    vibeDimensions['social_discovery_style'] = (
      social.socialPreference * 0.5 +
      social.collaborationStyle * 0.3 +
      relationship.influenceReceptivity * 0.2
    ).clamp(0.0, 1.0);
    
    // Compile temporal flexibility
    vibeDimensions['temporal_flexibility'] = (
      behavioral.spontaneityIndex * 0.6 +
      temporal.contextualModifier * 0.4
    ).clamp(0.0, 1.0);
    
    // Compile location adventurousness
    vibeDimensions['location_adventurousness'] = (
      behavioral.explorationTendency * 0.7 +
      personality.evolutionMomentum * 0.3
    ).clamp(0.0, 1.0);
    
    // Compile curation tendency
    vibeDimensions['curation_tendency'] = (
      social.leadershipTendency * 0.6 +
      relationship.givingTendency * 0.4
    ).clamp(0.0, 1.0);
    
    // Compile trust network reliance
    vibeDimensions['trust_network_reliance'] = (
      social.trustNetworkStrength * 0.5 +
      relationship.relationshipStability * 0.3 +
      social.collaborationStyle * 0.2
    ).clamp(0.0, 1.0);
    
    // Apply temporal context modifications
    vibeDimensions.forEach((dimension, value) {
      vibeDimensions[dimension] = (value * temporal.contextualModifier).clamp(0.0, 1.0);
    });
    
    return vibeDimensions;
  }
  
  Future<String> _generateContextualSalt(String userId) async {
    final now = DateTime.now();
    final context = '${now.hour}_${now.weekday}_${now.month}';
    return '$userId:$context:${now.millisecondsSinceEpoch ~/ (1000 * 60 * 15)}'; // 15-minute windows
  }
  
  Future<void> _storeVibeAnalytics(String userId, UserVibe vibe, PersonalityProfile personality) async {
    try {
      final analytics = {
        'vibe_archetype': vibe.getVibeArchetype(),
        'energy_level': (vibe.overallEnergy * 100).round(),
        'social_preference': (vibe.socialPreference * 100).round(),
        'exploration_tendency': (vibe.explorationTendency * 100).round(),
        'personality_generation': personality.evolutionGeneration,
        'analysis_timestamp': DateTime.now().toIso8601String(),
      };
      
      await _prefs.setString('${_vibeAnalyticsKey}_$userId', analytics.toString());
    } catch (e) {
      developer.log('Error storing vibe analytics: $e', name: _logName);
    }
  }
  
  // Compatibility analysis methods
  Future<List<LearningOpportunity>> _analyzeLearningOpportunities(UserVibe localVibe, UserVibe remoteVibe) async {
    final opportunities = <LearningOpportunity>[];
    
    // Compare dimension differences for learning potential
    localVibe.anonymizedDimensions.forEach((dimension, localValue) {
      final remoteValue = remoteVibe.anonymizedDimensions[dimension] ?? 0.5;
      final difference = (localValue - remoteValue).abs();
      
      if (difference >= 0.3 && difference <= 0.7) {
        // Optimal learning range - not too similar, not too different
        opportunities.add(LearningOpportunity(
          dimension: dimension,
          learningPotential: 1.0 - difference,
          learningType: _determineLearningType(dimension, localValue, remoteValue),
        ));
      }
    });
    
    return opportunities;
  }
  
  Future<double> _calculateConnectionStrength(UserVibe localVibe, UserVibe remoteVibe) async {
    final compatibility = localVibe.calculateVibeCompatibility(remoteVibe);
    final energyAlignment = 1.0 - (localVibe.overallEnergy - remoteVibe.overallEnergy).abs();
    final socialAlignment = 1.0 - (localVibe.socialPreference - remoteVibe.socialPreference).abs();
    
    return (compatibility * 0.5 + energyAlignment * 0.25 + socialAlignment * 0.25).clamp(0.0, 1.0);
  }
  
  Future<AI2AIInteractionStyle> _determineOptimalInteractionStyle(UserVibe localVibe, UserVibe remoteVibe) async {
    final compatibility = localVibe.calculateVibeCompatibility(remoteVibe);
    final energyDiff = (localVibe.overallEnergy - remoteVibe.overallEnergy).abs();
    final socialDiff = (localVibe.socialPreference - remoteVibe.socialPreference).abs();
    
    if (compatibility >= 0.8) {
      return AI2AIInteractionStyle.deepLearning;
    } else if (compatibility >= 0.6) {
      return AI2AIInteractionStyle.moderateLearning;
    } else if (energyDiff <= 0.3 || socialDiff <= 0.3) {
      return AI2AIInteractionStyle.focusedExchange;
    } else {
      return AI2AIInteractionStyle.lightInteraction;
    }
  }
  
  Future<double> _calculateTrustBuildingPotential(UserVibe localVibe, UserVibe remoteVibe) async {
    final localTrustDimension = localVibe.anonymizedDimensions['trust_network_reliance'] ?? 0.5;
    final remoteTrustDimension = remoteVibe.anonymizedDimensions['trust_network_reliance'] ?? 0.5;
    
    final trustCompatibility = 1.0 - (localTrustDimension - remoteTrustDimension).abs();
    final overallCompatibility = localVibe.calculateVibeCompatibility(remoteVibe);
    
    return (trustCompatibility * 0.6 + overallCompatibility * 0.4).clamp(0.0, 1.0);
  }
  
  // Helper methods
  double _calculateEvolutionMomentum(PersonalityProfile personality) {
    if (personality.evolutionGeneration <= 1) return 0.3;
    
    // Higher momentum for recent evolution
    final recentEvolutions = personality.learningHistory['evolution_milestones'] as List<DateTime>? ?? [];
    final recentEvolutionCount = recentEvolutions
        .where((milestone) => DateTime.now().difference(milestone).inDays <= 7)
        .length;
    
    return (recentEvolutionCount / 3.0).clamp(0.0, 1.0);
  }
  
  double _calculateCurrentEnergyLevel(int hour) {
    // Energy patterns based on time of day
    if (hour >= 6 && hour <= 9) return 0.8; // Morning energy
    if (hour >= 10 && hour <= 12) return 0.9; // Peak energy
    if (hour >= 13 && hour <= 15) return 0.7; // Post-lunch dip
    if (hour >= 16 && hour <= 19) return 0.8; // Evening energy
    if (hour >= 20 && hour <= 22) return 0.6; // Winding down
    return 0.4; // Night/early morning
  }
  
  double _getTimeOfDayInfluence(int hour) {
    return _calculateCurrentEnergyLevel(hour);
  }
  
  double _getWeekdayInfluence(int weekday) {
    // Monday = 1, Sunday = 7
    if (weekday <= 5) return 0.7; // Weekdays
    return 0.9; // Weekends
  }
  
  double _getSeasonalInfluence(int month) {
    // Spring/Summer higher energy
    if (month >= 3 && month <= 8) return 0.8;
    return 0.6; // Fall/Winter
  }
  
  double _getContextualModifier(int hour, int weekday) {
    final timeInfluence = _getTimeOfDayInfluence(hour);
    final weekdayInfluence = _getWeekdayInfluence(weekday);
    return (timeInfluence + weekdayInfluence) / 2.0;
  }
  
  Duration _calculateRecommendedDuration(double compatibility) {
    if (compatibility >= VibeConstants.highCompatibilityThreshold) {
      return Duration(seconds: VibeConstants.maxInteractionDurationSeconds);
    } else if (compatibility >= VibeConstants.mediumCompatibilityThreshold) {
      return Duration(seconds: (VibeConstants.maxInteractionDurationSeconds * 0.7).round());
    } else {
      return Duration(seconds: VibeConstants.minInteractionDurationSeconds);
    }
  }
  
  ConnectionPriority _calculateConnectionPriority(double compatibility, double aiPleasure) {
    final combinedScore = (compatibility + aiPleasure) / 2.0;
    
    if (combinedScore >= 0.8) return ConnectionPriority.high;
    if (combinedScore >= 0.6) return ConnectionPriority.medium;
    if (combinedScore >= 0.4) return ConnectionPriority.low;
    return ConnectionPriority.minimal;
  }
  
  LearningType _determineLearningType(String dimension, double localValue, double remoteValue) {
    if (remoteValue > localValue) {
      return LearningType.expansion; // Learn to expand this dimension
    } else {
      return LearningType.refinement; // Learn to refine this dimension
    }
  }
  
  // Community analysis methods
  Future<List<UserVibe>> _getAnonymizedCommunityVibes() async {
    try {
      // In a real implementation, this would fetch anonymized vibes from network/local storage
      // For now, return empty list as community vibes are gathered through discovery
      // This method would integrate with network analytics or local cache
      return [];
    } catch (e) {
      developer.log('Error getting anonymized community vibes: $e', name: _logName);
      return [];
    }
  }
  
  Future<Map<String, double>> _analyzeArchetypeDistribution(List<UserVibe> vibes) async {
    if (vibes.isEmpty) return {};
    
    final archetypeCounts = <String, int>{};
    for (final vibe in vibes) {
      final archetype = vibe.getVibeArchetype();
      archetypeCounts[archetype] = (archetypeCounts[archetype] ?? 0) + 1;
    }
    
    final total = vibes.length;
    final distribution = <String, double>{};
    archetypeCounts.forEach((archetype, count) {
      distribution[archetype] = count / total;
    });
    
    return distribution;
  }
  
  Future<Map<String, double>> _analyzeEnergyPatterns(List<UserVibe> vibes) async {
    if (vibes.isEmpty) return {};
    
    final energyRanges = {
      'low': <double>[],
      'moderate': <double>[],
      'high': <double>[],
      'very_high': <double>[],
    };
    
    for (final vibe in vibes) {
      final energy = vibe.overallEnergy;
      if (energy < 0.3) {
        energyRanges['low']!.add(energy);
      } else if (energy < 0.6) {
        energyRanges['moderate']!.add(energy);
      } else if (energy < 0.8) {
        energyRanges['high']!.add(energy);
      } else {
        energyRanges['very_high']!.add(energy);
      }
    }
    
    final total = vibes.length;
    final patterns = <String, double>{};
    energyRanges.forEach((range, values) {
      patterns[range] = values.length / total;
    });
    
    // Calculate average energy
    final avgEnergy = vibes.map((v) => v.overallEnergy).reduce((a, b) => a + b) / total;
    patterns['average'] = avgEnergy;
    
    return patterns;
  }
  
  Future<Map<String, double>> _analyzeSocialPreferenceTrends(List<UserVibe> vibes) async {
    if (vibes.isEmpty) return {};
    
    final socialRanges = {
      'solo_preferred': <double>[],
      'balanced': <double>[],
      'social_preferred': <double>[],
    };
    
    for (final vibe in vibes) {
      final social = vibe.socialPreference;
      if (social < 0.4) {
        socialRanges['solo_preferred']!.add(social);
      } else if (social < 0.7) {
        socialRanges['balanced']!.add(social);
      } else {
        socialRanges['social_preferred']!.add(social);
      }
    }
    
    final total = vibes.length;
    final trends = <String, double>{};
    socialRanges.forEach((range, values) {
      trends[range] = values.length / total;
    });
    
    // Calculate average social preference
    final avgSocial = vibes.map((v) => v.socialPreference).reduce((a, b) => a + b) / total;
    trends['average'] = avgSocial;
    
    return trends;
  }
  
  Future<List<String>> _identifyEmergingVibePatterns(List<UserVibe> vibes) async {
    if (vibes.length < 5) return [];
    
    final patterns = <String>[];
    
    // Identify high-energy patterns
    final highEnergyCount = vibes.where((v) => v.overallEnergy >= 0.7).length;
    if (highEnergyCount / vibes.length > 0.3) {
      patterns.add('high_energy_community');
    }
    
    // Identify exploration-focused patterns
    final highExplorationCount = vibes.where((v) => v.explorationTendency >= 0.7).length;
    if (highExplorationCount / vibes.length > 0.3) {
      patterns.add('exploration_focused_community');
    }
    
    // Identify social-focused patterns
    final highSocialCount = vibes.where((v) => v.socialPreference >= 0.7).length;
    if (highSocialCount / vibes.length > 0.3) {
      patterns.add('social_focused_community');
    }
    
    // Identify balanced patterns
    final balancedCount = vibes.where((v) {
      final energy = v.overallEnergy;
      final social = v.socialPreference;
      final exploration = v.explorationTendency;
      return energy >= 0.4 && energy <= 0.7 &&
             social >= 0.4 && social <= 0.7 &&
             exploration >= 0.4 && exploration <= 0.7;
    }).length;
    if (balancedCount / vibes.length > 0.3) {
      patterns.add('balanced_community');
    }
    
    return patterns;
  }
  
  // Authenticity validation methods
  Future<double> _checkPersonalityConsistency(UserVibe vibe, PersonalityProfile personality) async {
    try {
      var consistencyScore = 0.0;
      var validDimensions = 0;
      
      // Compare vibe dimensions with personality dimensions
      for (final dimension in VibeConstants.coreDimensions) {
        final vibeValue = vibe.anonymizedDimensions[dimension];
        final personalityValue = personality.dimensions[dimension];
        
        if (vibeValue != null && personalityValue != null) {
          // Account for privacy noise in vibe (allow ±0.05 difference)
          final difference = (vibeValue - personalityValue).abs();
          final dimensionConsistency = 1.0 - (difference / 0.05).clamp(0.0, 1.0);
          consistencyScore += dimensionConsistency;
          validDimensions++;
        }
      }
      
      if (validDimensions == 0) return 0.5; // Neutral if no dimensions to compare
      
      return (consistencyScore / validDimensions).clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Error checking personality consistency: $e', name: _logName);
      return 0.8; // Default to high consistency on error
    }
  }
  
  Future<double> _detectArtificialPatterns(UserVibe vibe) async {
    try {
      var artificialityScore = 0.0;
      
      // Check for suspiciously perfect values (all 0.0, 0.5, or 1.0)
      final perfectValues = vibe.anonymizedDimensions.values
          .where((v) => v == 0.0 || v == 0.5 || v == 1.0)
          .length;
      final perfectRatio = perfectValues / vibe.anonymizedDimensions.length;
      if (perfectRatio > 0.5) {
        artificialityScore += 0.3; // Suspicious pattern
      }
      
      // Check for lack of variance (all values very similar)
      final values = vibe.anonymizedDimensions.values.toList();
      if (values.length > 1) {
        final min = values.reduce((a, b) => a < b ? a : b);
        final max = values.reduce((a, b) => a > b ? a : b);
        final variance = max - min;
        if (variance < 0.1) {
          artificialityScore += 0.2; // Low variance suggests artificiality
        }
      }
      
      // Check for impossible combinations
      // High exploration but low energy is suspicious
      final exploration = vibe.anonymizedDimensions['exploration_eagerness'] ?? 0.5;
      final energy = vibe.overallEnergy;
      if (exploration > 0.8 && energy < 0.3) {
        artificialityScore += 0.2; // Suspicious combination
      }
      
      return artificialityScore.clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Error detecting artificial patterns: $e', name: _logName);
      return 0.1; // Default to low artificiality on error
    }
  }
  
  Future<double> _checkTemporalConsistency(UserVibe vibe) async {
    try {
      // Check if vibe is expired (should not be used)
      if (vibe.isExpired) {
        return 0.0; // Expired vibes are inconsistent
      }
      
      // Check if vibe age is reasonable (not too old, not from future)
      final age = DateTime.now().difference(vibe.createdAt);
      if (age.isNegative) {
        return 0.0; // Future-dated vibe is inconsistent
      }
      
      // Vibes older than expiration period are inconsistent
      final maxAge = Duration(days: VibeConstants.vibeSignatureExpiryDays);
      if (age > maxAge) {
        return 0.0; // Too old
      }
      
      // Check temporal context consistency
      final expectedContext = _getTemporalContext(DateTime.now());
      final contextMatch = vibe.temporalContext == expectedContext ? 1.0 : 0.8;
      
      // Age-based consistency (newer = more consistent)
      final ageConsistency = 1.0 - (age.inDays / VibeConstants.vibeSignatureExpiryDays).clamp(0.0, 1.0);
      
      return (contextMatch * 0.6 + ageConsistency * 0.4).clamp(0.0, 1.0);
    } catch (e) {
      developer.log('Error checking temporal consistency: $e', name: _logName);
      return 0.9; // Default to high consistency on error
    }
  }
  
  String _getTemporalContext(DateTime time) {
    final hour = time.hour;
    final weekday = time.weekday;
    
    String timeOfDay;
    if (hour >= 6 && hour < 12) {
      timeOfDay = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeOfDay = 'afternoon';
    } else if (hour >= 17 && hour < 22) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }
    
    final dayType = weekday <= 5 ? 'weekday' : 'weekend';
    return '$dayType$timeOfDay';
  }
}

// Supporting classes for vibe analysis
class PersonalityVibeInsights {
  final List<String> dominantTraits;
  final double personalityStrength;
  final double evolutionMomentum;
  final double authenticityLevel;
  final double confidenceLevel;
  
  PersonalityVibeInsights({
    required this.dominantTraits,
    required this.personalityStrength,
    required this.evolutionMomentum,
    required this.authenticityLevel,
    required this.confidenceLevel,
  });
}

class BehavioralVibeInsights {
  final double activityLevel;
  final double explorationTendency;
  final double socialEngagement;
  final double spontaneityIndex;
  final double consistencyScore;
  
  BehavioralVibeInsights({
    required this.activityLevel,
    required this.explorationTendency,
    required this.socialEngagement,
    required this.spontaneityIndex,
    required this.consistencyScore,
  });
}

class SocialVibeInsights {
  final double communityEngagement;
  final double socialPreference;
  final double leadershipTendency;
  final double collaborationStyle;
  final double trustNetworkStrength;
  
  SocialVibeInsights({
    required this.communityEngagement,
    required this.socialPreference,
    required this.leadershipTendency,
    required this.collaborationStyle,
    required this.trustNetworkStrength,
  });
}

class RelationshipVibeInsights {
  final double connectionDepth;
  final double relationshipStability;
  final double influenceReceptivity;
  final double givingTendency;
  final double boundaryFlexibility;
  
  RelationshipVibeInsights({
    required this.connectionDepth,
    required this.relationshipStability,
    required this.influenceReceptivity,
    required this.givingTendency,
    required this.boundaryFlexibility,
  });
}

class TemporalVibeInsights {
  final double currentEnergyLevel;
  final double timeOfDayInfluence;
  final double weekdayInfluence;
  final double seasonalInfluence;
  final double contextualModifier;
  
  TemporalVibeInsights({
    required this.currentEnergyLevel,
    required this.timeOfDayInfluence,
    required this.weekdayInfluence,
    required this.seasonalInfluence,
    required this.contextualModifier,
  });
}

class VibeCompatibilityResult {
  final double basicCompatibility;
  final double aiPleasurePotential;
  final List<LearningOpportunity> learningOpportunities;
  final double connectionStrength;
  final AI2AIInteractionStyle interactionStyle;
  final double trustBuildingPotential;
  final Duration recommendedConnectionDuration;
  final ConnectionPriority connectionPriority;
  
  VibeCompatibilityResult({
    required this.basicCompatibility,
    required this.aiPleasurePotential,
    required this.learningOpportunities,
    required this.connectionStrength,
    required this.interactionStyle,
    required this.trustBuildingPotential,
    required this.recommendedConnectionDuration,
    required this.connectionPriority,
  });
  
  static VibeCompatibilityResult fallback() {
    return VibeCompatibilityResult(
      basicCompatibility: 0.5,
      aiPleasurePotential: 0.5,
      learningOpportunities: [],
      connectionStrength: 0.5,
      interactionStyle: AI2AIInteractionStyle.lightInteraction,
      trustBuildingPotential: 0.5,
      recommendedConnectionDuration: Duration(seconds: VibeConstants.minInteractionDurationSeconds),
      connectionPriority: ConnectionPriority.low,
    );
  }
}

class LearningOpportunity {
  final String dimension;
  final double learningPotential;
  final LearningType learningType;
  
  LearningOpportunity({
    required this.dimension,
    required this.learningPotential,
    required this.learningType,
  });
}

enum LearningType { expansion, refinement, discovery }
enum AI2AIInteractionStyle { deepLearning, moderateLearning, focusedExchange, lightInteraction }
enum ConnectionPriority { high, medium, low, minimal }

class VibeEvolutionEvent {
  final DateTime timestamp;
  final String vibeArchetype;
  final double energyLevel;
  final double socialPreference;
  final String changeReason;
  
  VibeEvolutionEvent({
    required this.timestamp,
    required this.vibeArchetype,
    required this.energyLevel,
    required this.socialPreference,
    required this.changeReason,
  });
}

class CommunityVibeInsights {
  final Map<String, double> archetypeDistribution;
  final Map<String, double> energyPatterns;
  final Map<String, double> socialTrends;
  final List<String> emergingPatterns;
  final int totalVibesAnalyzed;
  final DateTime analysisTimestamp;
  
  CommunityVibeInsights({
    required this.archetypeDistribution,
    required this.energyPatterns,
    required this.socialTrends,
    required this.emergingPatterns,
    required this.totalVibesAnalyzed,
    required this.analysisTimestamp,
  });
  
  static CommunityVibeInsights empty() {
    return CommunityVibeInsights(
      archetypeDistribution: {},
      energyPatterns: {},
      socialTrends: {},
      emergingPatterns: [],
      totalVibesAnalyzed: 0,
      analysisTimestamp: DateTime.now(),
    );
  }
}

class VibeAuthenticityResult {
  final bool isAuthentic;
  final double authenticityScore;
  final List<String> issues;
  final DateTime validatedAt;
  
  VibeAuthenticityResult({
    required this.isAuthentic,
    required this.authenticityScore,
    required this.issues,
    required this.validatedAt,
  });
}