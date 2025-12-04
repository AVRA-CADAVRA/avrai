import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/services/logger.dart';

/// Golden Expert AI Influence Service
/// 
/// Calculates and applies golden expert weight to influence AI personality
/// and neighborhood character shaping.
/// 
/// **Philosophy Alignment:**
/// - Golden experts shape neighborhood character (10% higher influence)
/// - AI personality reflects actual community values (golden expert perspective)
/// - Golden expert contributions have more influence
/// - Neighborhood character shaped by golden experts (along with all locals, but higher rate)
/// 
/// **Weight Calculation:**
/// - Base weight: 10% higher (1.1x)
/// - Proportional to residency length:
///   - Formula: `1.1 + (residencyYears / 100)`
///   - Example: 30 years = 1.3x weight (1.1 + 0.2)
///   - Example: 25 years = 1.25x weight (1.1 + 0.15)
///   - Example: 20 years = 1.2x weight (1.1 + 0.1)
/// - Minimum weight: 1.1x (10% higher)
/// - Maximum weight: 1.5x (50% higher, for 40+ years)
class GoldenExpertAIInfluenceService {
  static const String _logName = 'GoldenExpertAIInfluenceService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  // Weight calculation constants
  static const double _baseWeight = 1.1; // 10% higher base weight
  static const double _minWeight = 1.1; // Minimum weight (10% higher)
  static const double _maxWeight = 1.5; // Maximum weight (50% higher)
  static const double _residencyMultiplier = 0.01; // 1/100 for years to weight conversion

  /// Calculate influence weight for a golden expert
  /// 
  /// **Parameters:**
  /// - `localExpertise`: LocalExpertise data for the user
  /// 
  /// **Returns:**
  /// Influence weight (1.1 to 1.5) based on residency length
  /// Returns 1.0 if user is not a golden expert
  double calculateInfluenceWeight(LocalExpertise? localExpertise) {
    try {
      // Check if user is a golden expert
      if (localExpertise == null || !localExpertise.isGoldenLocalExpert) {
        return 1.0; // No weight boost for non-golden experts
      }

      // Get residency years from continuousResidency
      final residencyYears = _getResidencyYears(localExpertise.continuousResidency);
      
      // Calculate weight: base + (residencyYears / 100)
      final calculatedWeight = _baseWeight + (residencyYears * _residencyMultiplier);
      
      // Clamp between min and max
      final weight = calculatedWeight.clamp(_minWeight, _maxWeight);
      
      _logger.info(
        'Calculated golden expert weight: $weight (residency: $residencyYears years)',
        tag: _logName,
      );
      
      return weight;
    } catch (e) {
      _logger.error(
        'Error calculating influence weight',
        error: e,
        tag: _logName,
      );
      return 1.0; // Default to no weight boost on error
    }
  }

  /// Apply weight to behavior data
  /// 
  /// **Parameters:**
  /// - `behaviorData`: Map of behavior data (e.g., spot visits, actions)
  /// - `weight`: Influence weight to apply
  /// 
  /// **Returns:**
  /// Weighted behavior data
  Map<String, dynamic> applyWeightToBehavior(
    Map<String, dynamic> behaviorData,
    double weight,
  ) {
    try {
      if (weight <= 1.0) {
        return behaviorData; // No weighting needed
      }

      final weightedData = Map<String, dynamic>.from(behaviorData);
      
      // Apply weight to numeric values that represent influence
      if (weightedData.containsKey('visitCount')) {
        weightedData['visitCount'] = 
            ((weightedData['visitCount'] as num?)?.toDouble() ?? 0.0) * weight;
      }
      
      if (weightedData.containsKey('actionCount')) {
        weightedData['actionCount'] = 
            ((weightedData['actionCount'] as num?)?.toDouble() ?? 0.0) * weight;
      }
      
      if (weightedData.containsKey('influenceScore')) {
        weightedData['influenceScore'] = 
            ((weightedData['influenceScore'] as num?)?.toDouble() ?? 0.0) * weight;
      }

      _logger.debug(
        'Applied weight $weight to behavior data',
        tag: _logName,
      );
      
      return weightedData;
    } catch (e) {
      _logger.error(
        'Error applying weight to behavior',
        error: e,
        tag: _logName,
      );
      return behaviorData; // Return original on error
    }
  }

  /// Apply weight to preference data
  /// 
  /// **Parameters:**
  /// - `preferenceData`: Map of preference data (e.g., categories, locations)
  /// - `weight`: Influence weight to apply
  /// 
  /// **Returns:**
  /// Weighted preference data
  Map<String, dynamic> applyWeightToPreferences(
    Map<String, dynamic> preferenceData,
    double weight,
  ) {
    try {
      if (weight <= 1.0) {
        return preferenceData; // No weighting needed
      }

      final weightedData = Map<String, dynamic>.from(preferenceData);
      
      // Apply weight to preference scores
      if (weightedData.containsKey('preferenceScores')) {
        final scores = Map<String, dynamic>.from(
          weightedData['preferenceScores'] as Map<String, dynamic>? ?? {},
        );
        scores.forEach((key, value) {
          if (value is num) {
            scores[key] = value.toDouble() * weight;
          }
        });
        weightedData['preferenceScores'] = scores;
      }
      
      if (weightedData.containsKey('categoryPreferences')) {
        final categories = Map<String, dynamic>.from(
          weightedData['categoryPreferences'] as Map<String, dynamic>? ?? {},
        );
        categories.forEach((key, value) {
          if (value is num) {
            categories[key] = value.toDouble() * weight;
          }
        });
        weightedData['categoryPreferences'] = categories;
      }

      _logger.debug(
        'Applied weight $weight to preference data',
        tag: _logName,
      );
      
      return weightedData;
    } catch (e) {
      _logger.error(
        'Error applying weight to preferences',
        error: e,
        tag: _logName,
      );
      return preferenceData; // Return original on error
    }
  }

  /// Apply weight to connection data
  /// 
  /// **Parameters:**
  /// - `connectionData`: Map of connection data (e.g., AI2AI connections, relationships)
  /// - `weight`: Influence weight to apply
  /// 
  /// **Returns:**
  /// Weighted connection data
  Map<String, dynamic> applyWeightToConnections(
    Map<String, dynamic> connectionData,
    double weight,
  ) {
    try {
      if (weight <= 1.0) {
        return connectionData; // No weighting needed
      }

      final weightedData = Map<String, dynamic>.from(connectionData);
      
      // Apply weight to connection scores
      if (weightedData.containsKey('connectionScore')) {
        weightedData['connectionScore'] = 
            ((weightedData['connectionScore'] as num?)?.toDouble() ?? 0.0) * weight;
      }
      
      if (weightedData.containsKey('ai2aiCompatibility')) {
        weightedData['ai2aiCompatibility'] = 
            ((weightedData['ai2aiCompatibility'] as num?)?.toDouble() ?? 0.0) * weight;
      }
      
      if (weightedData.containsKey('networkInfluence')) {
        weightedData['networkInfluence'] = 
            ((weightedData['networkInfluence'] as num?)?.toDouble() ?? 0.0) * weight;
      }

      _logger.debug(
        'Applied weight $weight to connection data',
        tag: _logName,
      );
      
      return weightedData;
    } catch (e) {
      _logger.error(
        'Error applying weight to connections',
        error: e,
        tag: _logName,
      );
      return connectionData; // Return original on error
    }
  }

  /// Get residency years from continuous residency duration
  /// 
  /// **Parameters:**
  /// - `continuousResidency`: Duration of continuous residency
  /// 
  /// **Returns:**
  /// Residency years as a double (e.g., 25.5 years)
  double _getResidencyYears(Duration? continuousResidency) {
    if (continuousResidency == null) {
      return 0.0;
    }
    
    // Convert days to years (approximate: 365.25 days per year)
    return continuousResidency.inDays / 365.25;
  }
}

