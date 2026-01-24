import 'dart:developer' as developer;
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/models/personality_profile.dart';

/// Builds context paragraphs from AVRAI data for BERT-SQuAD question answering.
/// 
/// Formats structured data (spots, users, lists, personality profiles) into
/// natural language context that BERT-SQuAD can use to answer questions.
class AvraiContextBuilder {
  static const String _logName = 'AvraiContextBuilder';
  
  /// Build context paragraph from query and available data.
  /// 
  /// Extracts entities from query and fetches relevant AVRAI data,
  /// then formats it as a context paragraph for BERT-SQuAD.
  Future<String> buildContext({
    required String query,
    String? userId,
    List<Spot>? spots,
    PersonalityProfile? personalityProfile,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      developer.log('Building context for query: $query', name: _logName);
      
      final contextParts = <String>[];
      
      // Add spots context
      if (spots != null && spots.isNotEmpty) {
        contextParts.add(_formatSpotsContext(spots));
      }
      
      // Add personality profile context
      if (personalityProfile != null) {
        contextParts.add(_formatPersonalityContext(personalityProfile));
      }
      
      // Add additional data context
      if (additionalData != null && additionalData.isNotEmpty) {
        contextParts.add(_formatAdditionalDataContext(additionalData));
      }
      
      final context = contextParts.join('\n\n');
      
      developer.log('Built context (${context.length} chars)', name: _logName);
      return context;
    } catch (e, stackTrace) {
      developer.log(
        'Error building context: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return '';
    }
  }
  
  /// Format spots data as context paragraph.
  String _formatSpotsContext(List<Spot> spots) {
    final parts = <String>['Spots:'];
    
    for (final spot in spots.take(10)) { // Limit to 10 spots
      final spotInfo = <String>[];
      spotInfo.add(spot.name);
      
      if (spot.description.isNotEmpty) {
        spotInfo.add('Description: ${spot.description}');
      }
      
      if (spot.address != null && spot.address!.isNotEmpty) {
        spotInfo.add('Address: ${spot.address}');
      }
      
      if (spot.category.isNotEmpty) {
        spotInfo.add('Category: ${spot.category}');
      }
      
      if (spot.tags.isNotEmpty) {
        spotInfo.add('Tags: ${spot.tags.join(", ")}');
      }
      
      // Note: respectCount and viewCount are not available on Spot model
      // These metrics would need to be fetched separately if needed
      
      parts.add(spotInfo.join('. '));
    }
    
    return parts.join('\n');
  }
  
  /// Format personality profile as context paragraph.
  String _formatPersonalityContext(PersonalityProfile profile) {
    final parts = <String>['Personality Profile:'];
    
    final dimensions = profile.dimensions;
    if (dimensions.isNotEmpty) {
      for (final entry in dimensions.entries) {
        final dimensionName = _formatDimensionName(entry.key);
        final score = entry.value;
        final description = _getDimensionDescription(entry.key, score);
        parts.add('$dimensionName: $score ($description)');
      }
    }
    
    parts.add('Archetype: ${profile.archetype}');
    parts.add('Authenticity Score: ${profile.authenticity}');
    
    return parts.join('\n');
  }
  
  /// Format additional data as context.
  String _formatAdditionalDataContext(Map<String, dynamic> data) {
    final parts = <String>[];
    
    for (final entry in data.entries) {
      if (entry.value != null) {
        parts.add('${entry.key}: ${entry.value}');
      }
    }
    
    return parts.join('\n');
  }
  
  /// Format dimension name for readability.
  String _formatDimensionName(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  
  /// Get human-readable description for dimension score.
  String _getDimensionDescription(String dimension, double score) {
    if (score >= 0.75) {
      return 'High';
    } else if (score >= 0.5) {
      return 'Moderate';
    } else if (score >= 0.25) {
      return 'Low';
    } else {
      return 'Very Low';
    }
  }
}
