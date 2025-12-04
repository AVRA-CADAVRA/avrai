import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/logger.dart';

/// Expertise Curation Service
/// Manages expert-based curation and validation
class ExpertiseCurationService {
  static const String _logName = 'ExpertiseCurationService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  /// Create expert-curated list
  /// Requires Regional level or higher expertise
  Future<ExpertCuratedCollection> createExpertCuratedList({
    required UnifiedUser curator,
    required String title,
    required String description,
    required String category,
    required List<Spot> spots,
    bool isPublic = true,
  }) async {
    try {
      _logger.info('Creating expert-curated list: $title', tag: _logName);

      // Verify curator has Regional level or higher
      final curatorLevel = curator.getExpertiseLevel(category);
      if (curatorLevel == null || curatorLevel.index < ExpertiseLevel.regional.index) {
        throw Exception('Curator must have Regional level or higher expertise');
      }

      final collection = ExpertCuratedCollection(
        id: _generateCollectionId(),
        title: title,
        description: description,
        category: category,
        curator: curator,
        curatorLevel: curatorLevel,
        spots: spots,
        spotCount: spots.length,
        respectCount: 0,
        isPublic: isPublic,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _saveCollection(collection);
      _logger.info('Created expert-curated list: ${collection.id}', tag: _logName);
      return collection;
    } catch (e) {
      _logger.error('Error creating expert-curated list', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get expert-curated collections
  Future<List<ExpertCuratedCollection>> getExpertCuratedCollections({
    String? category,
    String? location,
    ExpertiseLevel? minLevel,
    int maxResults = 20,
  }) async {
    try {
      final allCollections = await _getAllCollections();
      
      return allCollections.where((collection) {
        if (category != null && collection.category != category) return false;
        if (location != null && collection.curator.location != null) {
          if (!collection.curator.location!.toLowerCase().contains(location.toLowerCase())) {
            return false;
          }
        }
        if (minLevel != null) {
          if (collection.curatorLevel.index < minLevel.index) return false;
        }
        return true;
      }).take(maxResults).toList()
        ..sort((a, b) => b.respectCount.compareTo(a.respectCount));
    } catch (e) {
      _logger.error('Error getting expert-curated collections', error: e, tag: _logName);
      return [];
    }
  }

  /// Get expert panel validation
  /// Multiple experts validate a spot
  Future<ExpertPanelValidation> createExpertPanelValidation({
    required Spot spot,
    required List<UnifiedUser> experts,
    required String category,
    Map<String, bool>? validations, // expertId -> isValid
  }) async {
    try {
      _logger.info('Creating expert panel validation for spot: ${spot.id}', tag: _logName);

      // Verify all experts have Regional level or higher
      for (final expert in experts) {
        final level = expert.getExpertiseLevel(category);
        if (level == null || level.index < ExpertiseLevel.regional.index) {
          throw Exception('All panel members must have Regional level or higher');
        }
      }

      final validation = ExpertPanelValidation(
        id: _generateValidationId(),
        spot: spot,
        category: category,
        experts: experts,
        validations: validations ?? {},
        createdAt: DateTime.now(),
      );

      await _saveValidation(validation);
      _logger.info('Created expert panel validation: ${validation.id}', tag: _logName);
      return validation;
    } catch (e) {
      _logger.error('Error creating expert panel validation', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get community-validated spots
  /// Spots validated by expert consensus
  Future<List<Spot>> getCommunityValidatedSpots({
    String? category,
    int minValidations = 3,
    int maxResults = 20,
  }) async {
    try {
      final allValidations = await _getAllValidations();
      
      // Group by spot
      final spotValidations = <String, List<ExpertPanelValidation>>{};
      for (final validation in allValidations) {
        spotValidations.putIfAbsent(validation.spot.id, () => []).add(validation);
      }

      // Filter by validation count
      final validatedSpots = <Spot>[];
      for (final entry in spotValidations.entries) {
        if (entry.value.length >= minValidations) {
          // Check if consensus is positive
          final positiveCount = entry.value.where((v) => v.isValidated).length;
          if (positiveCount >= minValidations) {
            validatedSpots.add(entry.value.first.spot);
          }
        }
      }

      return validatedSpots.take(maxResults).toList();
    } catch (e) {
      _logger.error('Error getting community-validated spots', error: e, tag: _logName);
      return [];
    }
  }

  // Private helper methods

  String _generateCollectionId() {
    return 'expert_collection_${DateTime.now().millisecondsSinceEpoch}';
  }

  String _generateValidationId() {
    return 'expert_validation_${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _saveCollection(ExpertCuratedCollection collection) async {
    // In production, save to database
  }

  Future<void> _saveValidation(ExpertPanelValidation validation) async {
    // In production, save to database
  }

  Future<List<ExpertCuratedCollection>> _getAllCollections() async {
    // In production, query database
    return [];
  }

  Future<List<ExpertPanelValidation>> _getAllValidations() async {
    // In production, query database
    return [];
  }
}

/// Expert Curated Collection
class ExpertCuratedCollection {
  final String id;
  final String title;
  final String description;
  final String category;
  final UnifiedUser curator;
  final ExpertiseLevel curatorLevel;
  final List<Spot> spots;
  final int spotCount;
  final int respectCount;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ExpertCuratedCollection({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.curator,
    required this.curatorLevel,
    required this.spots,
    required this.spotCount,
    this.respectCount = 0,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
  });
}

/// Expert Panel Validation
class ExpertPanelValidation {
  final String id;
  final Spot spot;
  final String category;
  final List<UnifiedUser> experts;
  final Map<String, bool> validations; // expertId -> isValid
  final DateTime createdAt;

  const ExpertPanelValidation({
    required this.id,
    required this.spot,
    required this.category,
    required this.experts,
    required this.validations,
    required this.createdAt,
  });

  /// Check if spot is validated (consensus)
  bool get isValidated {
    if (validations.isEmpty) return false;
    final positiveCount = validations.values.where((v) => v).length;
    return positiveCount > validations.length / 2;
  }

  /// Get validation percentage
  double get validationPercentage {
    if (validations.isEmpty) return 0.0;
    final positiveCount = validations.values.where((v) => v).length;
    return positiveCount / validations.length;
  }
}

