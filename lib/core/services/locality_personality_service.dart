import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/services/golden_expert_ai_influence_service.dart';
import 'package:spots/core/services/logger.dart';

/// Locality Personality Service
/// 
/// Manages locality AI personality with golden expert influence.
/// Shapes neighborhood "vibe" in the system based on golden expert behavior.
/// 
/// **Philosophy Alignment:**
/// - Golden experts shape neighborhood character (10% higher influence)
/// - AI personality reflects actual community values (golden expert perspective)
/// - Neighborhood character shaped by golden experts (along with all locals, but higher rate)
/// 
/// **Key Features:**
/// - Get/update locality AI personality
/// - Incorporate golden expert influence
/// - Calculate locality vibe
/// - Get locality preferences and characteristics
class LocalityPersonalityService {
  static const String _logName = 'LocalityPersonalityService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final GoldenExpertAIInfluenceService _influenceService;
  
  // In-memory storage for locality personalities (in production, use database)
  final Map<String, PersonalityProfile> _localityPersonalities = {};

  LocalityPersonalityService({
    GoldenExpertAIInfluenceService? influenceService,
  }) : _influenceService = influenceService ?? GoldenExpertAIInfluenceService();

  /// Get AI personality for a locality
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name (e.g., "Brooklyn", "Manhattan", "Austin")
  /// 
  /// **Returns:**
  /// PersonalityProfile for the locality, or initial profile if not found
  Future<PersonalityProfile> getLocalityPersonality(String locality) async {
    try {
      _logger.info(
        'Getting locality personality: $locality',
        tag: _logName,
      );

      // Check if locality personality exists
      if (_localityPersonalities.containsKey(locality)) {
        return _localityPersonalities[locality]!;
      }

      // Create initial locality personality
      final initialProfile = PersonalityProfile.initial('locality_$locality');
      _localityPersonalities[locality] = initialProfile;
      
      _logger.info(
        'Created initial personality for locality: $locality',
        tag: _logName,
      );
      
      return initialProfile;
    } catch (e) {
      _logger.error(
        'Error getting locality personality',
        error: e,
        tag: _logName,
      );
      // Return initial profile on error
      return PersonalityProfile.initial('locality_$locality');
    }
  }

  /// Update AI personality based on user behavior
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// - `userBehavior`: Map of user behavior data
  /// - `localExpertise`: Optional LocalExpertise for golden expert weighting
  /// 
  /// **Returns:**
  /// Updated PersonalityProfile
  Future<PersonalityProfile> updateLocalityPersonality({
    required String locality,
    required Map<String, dynamic> userBehavior,
    LocalExpertise? localExpertise,
  }) async {
    try {
      _logger.info(
        'Updating locality personality: $locality',
        tag: _logName,
      );

      // Get current locality personality
      final currentProfile = await getLocalityPersonality(locality);
      
      // Calculate golden expert weight if applicable
      double influenceWeight = 1.0;
      if (localExpertise != null) {
        influenceWeight = _influenceService.calculateInfluenceWeight(localExpertise);
      }
      
      // Apply weight to behavior data
      final weightedBehavior = _influenceService.applyWeightToBehavior(
        userBehavior,
        influenceWeight,
      );
      
      // Create dimension updates from weighted behavior
      final dimensionUpdates = _extractDimensionUpdates(weightedBehavior);
      
      // Evolve personality with weighted updates
      final evolvedProfile = currentProfile.evolve(
        newDimensions: dimensionUpdates,
        newConfidence: {},
        newAuthenticity: currentProfile.authenticity,
        additionalLearning: {
          'locality': locality,
          'influence_weight': influenceWeight,
          'is_golden_expert': localExpertise?.isGoldenLocalExpert ?? false,
        },
      );
      
      // Save updated profile
      _localityPersonalities[locality] = evolvedProfile;
      
      _logger.info(
        'Updated locality personality: $locality (weight: $influenceWeight)',
        tag: _logName,
      );
      
      return evolvedProfile;
    } catch (e) {
      _logger.error(
        'Error updating locality personality',
        error: e,
        tag: _logName,
      );
      return await getLocalityPersonality(locality); // Return current on error
    }
  }

  /// Incorporate golden expert influence into locality personality
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// - `goldenExpertBehavior`: Behavior data from golden expert
  /// - `localExpertise`: LocalExpertise for the golden expert
  /// 
  /// **Returns:**
  /// Updated PersonalityProfile with golden expert influence
  Future<PersonalityProfile> incorporateGoldenExpertInfluence({
    required String locality,
    required Map<String, dynamic> goldenExpertBehavior,
    required LocalExpertise localExpertise,
  }) async {
    try {
      _logger.info(
        'Incorporating golden expert influence: $locality',
        tag: _logName,
      );

      // Update locality personality with golden expert behavior
      return await updateLocalityPersonality(
        locality: locality,
        userBehavior: goldenExpertBehavior,
        localExpertise: localExpertise,
      );
    } catch (e) {
      _logger.error(
        'Error incorporating golden expert influence',
        error: e,
        tag: _logName,
      );
      return await getLocalityPersonality(locality); // Return current on error
    }
  }

  /// Calculate overall locality vibe
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// 
  /// **Returns:**
  /// Map of vibe characteristics (e.g., dominant traits, energy level)
  Future<Map<String, dynamic>> calculateLocalityVibe(String locality) async {
    try {
      _logger.info(
        'Calculating locality vibe: $locality',
        tag: _logName,
      );

      final profile = await getLocalityPersonality(locality);
      final dominantTraits = profile.getDominantTraits();
      
      // Calculate vibe characteristics
      final vibe = {
        'locality': locality,
        'dominantTraits': dominantTraits,
        'authenticityScore': profile.authenticity,
        'evolutionGeneration': profile.evolutionGeneration,
        'dimensions': profile.dimensions,
      };
      
      _logger.debug(
        'Calculated vibe for locality: $locality',
        tag: _logName,
      );
      
      return vibe;
    } catch (e) {
      _logger.error(
        'Error calculating locality vibe',
        error: e,
        tag: _logName,
      );
      return {
        'locality': locality,
        'dominantTraits': [],
        'authenticityScore': 0.5,
        'evolutionGeneration': 0,
        'dimensions': {},
      };
    }
  }

  /// Get locality preferences (shaped by golden experts)
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// 
  /// **Returns:**
  /// Map of locality preferences (categories, locations, etc.)
  Future<Map<String, dynamic>> getLocalityPreferences(String locality) async {
    try {
      _logger.info(
        'Getting locality preferences: $locality',
        tag: _logName,
      );

      final profile = await getLocalityPersonality(locality);
      
      // Extract preferences from personality dimensions
      final preferences = {
        'locality': locality,
        'explorationEagerness': profile.dimensions['exploration_eagerness'] ?? 0.5,
        'communityOrientation': profile.dimensions['community_orientation'] ?? 0.5,
        'authenticityPreference': profile.dimensions['authenticity_preference'] ?? 0.5,
        'energyPreference': profile.dimensions['energy_preference'] ?? 0.5,
        'noveltySeeking': profile.dimensions['novelty_seeking'] ?? 0.5,
        'valueOrientation': profile.dimensions['value_orientation'] ?? 0.5,
        'crowdTolerance': profile.dimensions['crowd_tolerance'] ?? 0.5,
      };
      
      _logger.debug(
        'Got preferences for locality: $locality',
        tag: _logName,
      );
      
      return preferences;
    } catch (e) {
      _logger.error(
        'Error getting locality preferences',
        error: e,
        tag: _logName,
      );
      return {
        'locality': locality,
        'explorationEagerness': 0.5,
        'communityOrientation': 0.5,
        'authenticityPreference': 0.5,
        'energyPreference': 0.5,
        'noveltySeeking': 0.5,
        'valueOrientation': 0.5,
        'crowdTolerance': 0.5,
      };
    }
  }

  /// Get locality characteristics
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// 
  /// **Returns:**
  /// Map of locality characteristics (personality summary)
  Future<Map<String, dynamic>> getLocalityCharacteristics(String locality) async {
    try {
      _logger.info(
        'Getting locality characteristics: $locality',
        tag: _logName,
      );

      final profile = await getLocalityPersonality(locality);
      final dominantTraits = profile.getDominantTraits();
      
      final characteristics = {
        'locality': locality,
        'dominantTraits': dominantTraits,
        'authenticityScore': profile.authenticity,
        'evolutionGeneration': profile.evolutionGeneration,
        'personalitySummary': _generatePersonalitySummary(profile),
      };
      
      _logger.debug(
        'Got characteristics for locality: $locality',
        tag: _logName,
      );
      
      return characteristics;
    } catch (e) {
      _logger.error(
        'Error getting locality characteristics',
        error: e,
        tag: _logName,
      );
      return {
        'locality': locality,
        'dominantTraits': [],
        'authenticityScore': 0.5,
        'evolutionGeneration': 0,
        'personalitySummary': 'Initial locality personality',
      };
    }
  }

  /// Extract dimension updates from behavior data
  /// 
  /// **Parameters:**
  /// - `behaviorData`: Map of behavior data
  /// 
  /// **Returns:**
  /// Map of dimension updates
  Map<String, double> _extractDimensionUpdates(Map<String, dynamic> behaviorData) {
    final updates = <String, double>{};
    
    // Map behavior data to personality dimensions
    // This is a simplified mapping - in production, use more sophisticated analysis
    if (behaviorData.containsKey('explorationScore')) {
      updates['exploration_eagerness'] = 
          (behaviorData['explorationScore'] as num?)?.toDouble() ?? 0.0;
    }
    
    if (behaviorData.containsKey('communityScore')) {
      updates['community_orientation'] = 
          (behaviorData['communityScore'] as num?)?.toDouble() ?? 0.0;
    }
    
    if (behaviorData.containsKey('authenticityScore')) {
      updates['authenticity_preference'] = 
          (behaviorData['authenticityScore'] as num?)?.toDouble() ?? 0.0;
    }
    
    if (behaviorData.containsKey('energyScore')) {
      updates['energy_preference'] = 
          (behaviorData['energyScore'] as num?)?.toDouble() ?? 0.0;
    }
    
    return updates;
  }

  /// Generate personality summary from profile
  /// 
  /// **Parameters:**
  /// - `profile`: PersonalityProfile
  /// 
  /// **Returns:**
  /// Human-readable personality summary
  String _generatePersonalitySummary(PersonalityProfile profile) {
    final dominantTraits = profile.getDominantTraits();
    if (dominantTraits.isEmpty) {
      return 'Initial locality personality - evolving based on community behavior';
    }
    
    return 'Locality personality shaped by ${dominantTraits.length} dominant traits: ${dominantTraits.join(", ")}';
  }
}

