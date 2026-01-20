// Embedding Delta Collector for Phase 11: User-AI Interaction Update
// Section 7: Federated Learning Hooks
// Collects anonymized embedding deltas from AI2AI connections

import 'dart:developer' as developer;
import 'dart:math' as math;
import 'package:avrai/core/constants/vibe_constants.dart';
import 'package:avrai_core/models/personality_profile.dart';

/// Embedding Delta
/// 
/// Represents an anonymized embedding difference between two AI personalities.
/// Used for federated learning to update on-device models without exposing
/// personal information.
class EmbeddingDelta {
  /// Anonymized embedding difference (vector of dimension deltas)
  final List<double> delta;
  
  /// Timestamp when delta was calculated
  final DateTime timestamp;
  
  /// Optional category (e.g., "coffee_preference", "exploration_style")
  final String? category;
  
  /// Optional metadata about the delta (anonymized)
  final Map<String, dynamic>? metadata;
  
  EmbeddingDelta({
    required this.delta,
    required this.timestamp,
    this.category,
    this.metadata,
  });
  
  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'delta': delta,
      'timestamp': timestamp.toIso8601String(),
      if (category != null) 'category': category,
      if (metadata != null) 'metadata': metadata,
    };
  }
  
  /// Create from JSON
  factory EmbeddingDelta.fromJson(Map<String, dynamic> json) {
    return EmbeddingDelta(
      delta: List<double>.from(json['delta'] as List),
      timestamp: DateTime.parse(json['timestamp'] as String),
      category: json['category'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Embedding Delta Collector
/// 
/// Collects anonymized embedding deltas from AI2AI connections.
/// These deltas represent differences in personality dimensions between
/// connected AIs, anonymized to preserve privacy.
/// 
/// Phase 11 Section 7: Federated Learning Hooks
/// Enhanced with AI2AI Learning Safeguards (Phase 11 Enhancement)
class EmbeddingDeltaCollector {
  static const String _logName = 'EmbeddingDeltaCollector';
  
  /// Collects anonymized embedding deltas from recent AI2AI connections
  /// 
  /// [localPersonality] - Local user's personality profile
  /// [remotePersonalities] - List of remote personality profiles from connections
  /// [learningQualityByPeer] - Optional map of learning quality by peer ID (65% minimum)
  /// 
  /// Returns list of anonymized embedding deltas
  /// 
  /// **Safeguards Applied:**
  /// - Connection limits: Max 12 simultaneous connections
  /// - Learning quality threshold: 65% minimum (if provided)
  /// - Dimension delta threshold: 22% minimum per dimension
  Future<List<EmbeddingDelta>> collectDeltas({
    required PersonalityProfile localPersonality,
    required List<PersonalityProfile> remotePersonalities,
    Map<String, double>? learningQualityByPeer,
  }) async {
    try {
      developer.log(
        'Collecting embedding deltas from ${remotePersonalities.length} connections',
        name: _logName,
      );
      
      // ========================================
      // SAFEGUARD 1: Connection Limits (Phase 11 Enhancement)
      // ========================================
      // Respect max simultaneous connections limit
      const maxConnections = 12; // From VibeConstants.maxSimultaneousConnections
      if (remotePersonalities.length > maxConnections) {
        developer.log(
          'Connection limit exceeded: ${remotePersonalities.length} connections '
          'exceeds max $maxConnections - limiting to max',
          name: _logName,
        );
        remotePersonalities = remotePersonalities.take(maxConnections).toList();
      }
      
      final deltas = <EmbeddingDelta>[];
      
      for (int i = 0; i < remotePersonalities.length; i++) {
        final remotePersonality = remotePersonalities[i];
        
        try {
          // ========================================
          // SAFEGUARD 2: Learning Quality Threshold (Phase 11 Enhancement)
          // ========================================
          // Check learning quality if provided (65% minimum)
          if (learningQualityByPeer != null) {
            // Try to match by agentId or index
            final peerId = remotePersonality.agentId;
            final learningQuality = learningQualityByPeer[peerId];
            
            if (learningQuality != null && learningQuality < 0.65) {
              developer.log(
                'Skipping delta collection: learning quality ${(learningQuality * 100).toStringAsFixed(1)}% '
                'below 65% threshold for peer $peerId',
                name: _logName,
              );
              continue; // Skip this connection (low quality)
            }
          }
          
          // Calculate embedding delta (anonymized)
          final delta = await _calculateDelta(
            localPersonality: localPersonality,
            remotePersonality: remotePersonality,
          );
          
          if (delta != null) {
            deltas.add(delta);
            developer.log(
              'Collected delta: ${delta.delta.length} dimensions, category: ${delta.category ?? "none"}',
              name: _logName,
            );
          } else {
            developer.log(
              'No significant delta found for remote personality (peerId: ${remotePersonality.agentId})',
              name: _logName,
            );
          }
        } catch (e) {
          developer.log(
            'Error calculating delta for remote personality: $e',
            name: _logName,
          );
          // Continue with other connections
        }
      }
      
      developer.log(
        'Collected ${deltas.length} embedding deltas from ${remotePersonalities.length} connections',
        name: _logName,
      );
      
      return deltas;
    } catch (e, stackTrace) {
      developer.log(
        'Error collecting embedding deltas: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
  
  /// Calculate embedding delta between two personalities (public for hooks)
  /// 
  /// Returns null if delta is not significant or cannot be calculated
  Future<EmbeddingDelta?> calculateDelta({
    required PersonalityProfile localPersonality,
    required PersonalityProfile remotePersonality,
  }) async {
    return await _calculateDelta(
      localPersonality: localPersonality,
      remotePersonality: remotePersonality,
    );
  }
  
  /// Calculate embedding delta between two personalities (private implementation)
  /// 
  /// Returns null if delta is not significant or cannot be calculated
  Future<EmbeddingDelta?> _calculateDelta({
    required PersonalityProfile localPersonality,
    required PersonalityProfile remotePersonality,
  }) async {
    try {
      // Step 1: Extract dimension vectors (anonymized)
      final localDimensions = _extractDimensionVector(localPersonality);
      final remoteDimensions = _extractDimensionVector(remotePersonality);
      
      // Step 2: Calculate delta (difference between dimensions)
      final deltaList = <double>[];
      for (int i = 0; i < localDimensions.length; i++) {
        if (i < remoteDimensions.length) {
          // Calculate difference (anonymized - no personal identifiers)
          final diff = remoteDimensions[i] - localDimensions[i];
          deltaList.add(diff);
        } else {
          deltaList.add(0.0);
        }
      }
      
      // Step 3: Check if delta is significant
      // ========================================
      // SAFEGUARD 3: Dimension Delta Threshold (Phase 11 Enhancement)
      // ========================================
      // Check each dimension delta individually (22% minimum per dimension)
      final significantDeltas = <double>[];
      bool hasSignificantDelta = false;
      
      for (int i = 0; i < deltaList.length; i++) {
        final dimensionDelta = deltaList[i];
        if (dimensionDelta.abs() >= 0.22) {
          // Individual dimension delta >= 22% threshold
          significantDeltas.add(dimensionDelta);
          hasSignificantDelta = true;
        } else {
          // Delta too small for this dimension
          significantDeltas.add(0.0);
        }
      }
      
      if (!hasSignificantDelta) {
        developer.log(
          'Delta rejected: no individual dimension delta >= 22% threshold',
          name: _logName,
        );
        return null; // No significant deltas
      }
      
      // Use only significant deltas
      final delta = significantDeltas;
      
      // Also check overall magnitude (legacy check)
      final deltaMagnitude = _calculateMagnitude(delta);
      if (deltaMagnitude < 0.1) {
        // Delta too small to be meaningful overall
        return null;
      }
      
      // Step 4: Determine category based on largest dimension differences
      final category = _determineCategory(localDimensions, remoteDimensions);
      
      // Step 5: Create anonymized metadata (no personal identifiers)
      final metadata = <String, dynamic>{
        'delta_magnitude': deltaMagnitude,
        'dimension_count': delta.length,
        'local_archetype': localPersonality.archetype, // Archetype is anonymized
        'remote_archetype': remotePersonality.archetype, // Archetype is anonymized
      };
      
      return EmbeddingDelta(
        delta: delta,
        timestamp: DateTime.now(),
        category: category,
        metadata: metadata,
      );
    } catch (e) {
      developer.log(
        'Error calculating delta: $e',
        name: _logName,
      );
      return null;
    }
  }
  
  /// Extract dimension vector from personality profile
  /// 
  /// Returns a normalized vector of dimension values
  List<double> _extractDimensionVector(PersonalityProfile personality) {
    // Extract all dimension values in a consistent order.
    //
    // IMPORTANT: This MUST match the canonical 12-dimension contract used across
    // the app (VibeConstants.coreDimensions). Federated deltas only make sense
    // if everyone agrees on the axis ordering.
    final dimensions = personality.dimensions;
    const orderedDimensions = VibeConstants.coreDimensions;
    
    final vector = <double>[];
    for (final dimension in orderedDimensions) {
      vector.add(dimensions[dimension] ?? 0.5); // Default to 0.5 if missing
    }
    
    return vector;
  }
  
  /// Calculate magnitude of delta vector
  double _calculateMagnitude(List<double> delta) {
    double sum = 0.0;
    for (final value in delta) {
      sum += value * value;
    }
    // Use Euclidean norm (not RMS). Normalizing by vector length makes sparse,
    // single-dimension changes look artificially “small” as dimension count grows.
    return math.sqrt(sum);
  }
  
  /// Determine category based on largest dimension differences
  String? _determineCategory(
    List<double> localDimensions,
    List<double> remoteDimensions,
  ) {
    if (localDimensions.length != remoteDimensions.length) {
      return null;
    }
    
    // Find dimension with largest absolute difference
    double maxDiff = 0.0;
    int maxIndex = -1;
    
    for (int i = 0; i < localDimensions.length; i++) {
      final diff = (remoteDimensions[i] - localDimensions[i]).abs();
      if (diff > maxDiff) {
        maxDiff = diff;
        maxIndex = i;
      }
    }
    
    if (maxIndex == -1 || maxDiff < 0.2) {
      return null; // No significant difference
    }
    
    // Map index to category
    final dimensionNames = [
      'exploration_style',
      'community_style',
      'authenticity_style',
      'social_style',
      'temporal_style',
      'location_style',
      'curation_style',
      'trust_style',
      'energy_style',
      'novelty_style',
      'value_style',
      'crowd_style',
    ];
    
    if (maxIndex < dimensionNames.length) {
      return dimensionNames[maxIndex];
    }
    
    return null;
  }
}
