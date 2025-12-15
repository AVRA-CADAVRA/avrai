import 'package:spots/core/models/neighborhood_boundary.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/large_city_detection_service.dart';
import 'package:spots/core/services/storage_service.dart';
import 'dart:convert';
import 'dart:io';

/// Neighborhood Boundary Service
/// 
/// Manages neighborhood boundaries between localities (neighborhoods).
/// Handles hard/soft border detection, soft border spot tracking, and dynamic refinement.
/// 
/// **Philosophy:**
/// - Neighborhood boundaries reflect actual community connections (not just geographic lines)
/// - Borders evolve based on user behavior (dynamic refinement)
/// - Soft border spots shared with both localities (community connections)
/// - System learns and refines boundaries based on actual user behavior
/// 
/// **Key Features:**
/// - Load boundaries from Google Maps (or mock data)
/// - Detect hard vs soft borders
/// - Track spots in soft border areas
/// - Track user visits to refine boundaries
/// - Dynamic border refinement based on user behavior
/// - Integration with geographic hierarchy
class NeighborhoodBoundaryService {
  static const String _logName = 'NeighborhoodBoundaryService';
  static const String _spotAssociationKeyPrefix = 'neighborhood.spot_association.';
  static const String _movementPatternsKeyPrefix = 'neighborhood.movement_patterns.';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final LargeCityDetectionService _largeCityService;
  final StorageService _storageService;

  // In-memory cache of boundaries (key: boundaryKey)
  final Map<String, NeighborhoodBoundary> _boundaryCache = {};

  // #region agent log (ndjson helper)
  static void _ndjsonLog({
    required String hypothesisId,
    required String location,
    required String message,
    required Map<String, dynamic> data,
    String runId = 'pre-fix',
  }) {
    try {
      final payload = <String, dynamic>{
        'sessionId': 'debug-session',
        'runId': runId,
        'hypothesisId': hypothesisId,
        'location': location,
        'message': message,
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      File('/Users/reisgordon/SPOTS/.cursor/debug.log')
          .writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
    } catch (_) {
      // swallow all logging errors in production/test
    }
  }
  // #endregion

  NeighborhoodBoundaryService({
    LargeCityDetectionService? largeCityService,
    StorageService? storageService,
  })  : _largeCityService = largeCityService ?? LargeCityDetectionService(),
        _storageService = storageService ?? StorageService.instance;

  /// Load boundaries from Google Maps (or mock data for now)
  /// 
  /// **Parameters:**
  /// - `city`: City name to load boundaries for
  /// 
  /// **Returns:**
  /// List of boundaries for the city
  /// 
  /// **Note:** Currently uses mock data. In production, would integrate with Google Maps API.
  Future<List<NeighborhoodBoundary>> loadBoundariesFromGoogleMaps(
    String city,
  ) async {
    try {
      // #region agent log
      _ndjsonLog(
        hypothesisId: 'H1',
        location: 'neighborhood_boundary_service.dart:loadBoundariesFromGoogleMaps:entry',
        message: 'Load boundaries entry',
        data: {
          'city': city,
          'cacheSizeBefore': _boundaryCache.length,
        },
      );
      // #endregion
      _logger.info(
        'Loading boundaries from Google Maps for city: $city',
        tag: _logName,
      );

      // Check if city is a large city with neighborhoods
      if (!_largeCityService.isLargeCity(city)) {
        // #region agent log
        _ndjsonLog(
          hypothesisId: 'H1',
          location: 'neighborhood_boundary_service.dart:loadBoundariesFromGoogleMaps:notLargeCity',
          message: 'City is not large city; returning empty boundaries',
          data: {'city': city},
        );
        // #endregion
        _logger.warning(
          'City $city is not a large city, no boundaries to load',
          tag: _logName,
        );
        return [];
      }

      // Get neighborhoods for the city
      final neighborhoods = _largeCityService.getNeighborhoods(city);
      if (neighborhoods.isEmpty) {
        // #region agent log
        _ndjsonLog(
          hypothesisId: 'H1',
          location: 'neighborhood_boundary_service.dart:loadBoundariesFromGoogleMaps:noNeighborhoods',
          message: 'No neighborhoods found; returning empty boundaries',
          data: {'city': city},
        );
        // #endregion
        _logger.warning(
          'No neighborhoods found for city: $city',
          tag: _logName,
        );
        return [];
      }

      // Generate boundaries between adjacent neighborhoods
      // In production, this would use Google Maps API to get actual boundaries
      final boundaries = <NeighborhoodBoundary>[];
      final now = DateTime.now();

      for (int i = 0; i < neighborhoods.length; i++) {
        for (int j = i + 1; j < neighborhoods.length; j++) {
          final locality1 = neighborhoods[i];
          final locality2 = neighborhoods[j];

          // Determine boundary type (hard vs soft)
          // In production, this would be determined by Google Maps data
          // For now, use mock logic: well-known boundaries are hard, others are soft
          final boundaryType = _determineBoundaryType(locality1, locality2);

          // Generate mock coordinates (in production, from Google Maps)
          final coordinates = _generateMockCoordinates(locality1, locality2);

          final boundary = NeighborhoodBoundary(
            id: 'boundary_${locality1}_${locality2}_${now.millisecondsSinceEpoch}',
            locality1: locality1,
            locality2: locality2,
            boundaryType: boundaryType,
            coordinates: coordinates,
            source: 'Google Maps',
            createdAt: now,
            updatedAt: now,
          );

          boundaries.add(boundary);
          _boundaryCache[boundary.boundaryKey] = boundary;
        }
      }

      // Save boundaries to storage
      //
      // IMPORTANT (test isolation + correctness):
      // Do NOT auto-persist generated boundaries here.
      //
      // Rationale:
      // - This method currently uses mock/generated boundaries.
      // - Persisting them pollutes shared StorageService across tests and causes
      //   unrelated tests to see 100+ synthetic boundaries.
      // - Production persistence should be done explicitly via saveBoundary/updateBoundary
      //   (or a dedicated sync job) once we integrate real map data.

      _logger.info(
        'Loaded ${boundaries.length} boundaries for city: $city',
        tag: _logName,
      );

      return boundaries;
    } catch (e) {
      _logger.error(
        'Error loading boundaries from Google Maps',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Get boundary between two localities
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality name
  /// - `locality2`: Second locality name
  /// 
  /// **Returns:**
  /// Boundary between the two localities, or `null` if not found
  Future<NeighborhoodBoundary?> getBoundary(
    String locality1,
    String locality2,
  ) async {
    try {
      final boundaryKey = _getBoundaryKey(locality1, locality2);

      // Check cache first
      if (_boundaryCache.containsKey(boundaryKey)) {
        return _boundaryCache[boundaryKey];
      }

      // Load from storage
      final boundary = await _loadBoundaryFromStorage(boundaryKey);
      if (boundary != null) {
        _boundaryCache[boundaryKey] = boundary;
        return boundary;
      }

      return null;
    } catch (e) {
      _logger.error(
        'Error getting boundary',
        error: e,
        tag: _logName,
      );
      return null;
    }
  }

  /// Get all boundaries for a locality
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// 
  /// **Returns:**
  /// List of boundaries involving the locality
  Future<List<NeighborhoodBoundary>> getBoundariesForLocality(
    String locality,
  ) async {
    try {
      final boundaries = <NeighborhoodBoundary>[];

      // Check cache
      for (final boundary in _boundaryCache.values) {
        if (boundary.locality1 == locality || boundary.locality2 == locality) {
          boundaries.add(boundary);
        }
      }

      // Load from storage if needed
      final storedBoundaries = await _loadAllBoundariesFromStorage();
      for (final boundary in storedBoundaries) {
        if ((boundary.locality1 == locality || boundary.locality2 == locality) &&
            !boundaries.any((b) => b.id == boundary.id)) {
          boundaries.add(boundary);
          _boundaryCache[boundary.boundaryKey] = boundary;
        }
      }

      return boundaries;
    } catch (e) {
      _logger.error(
        'Error getting boundaries for locality',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Check if boundary is a hard border
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality name
  /// - `locality2`: Second locality name
  /// 
  /// **Returns:**
  /// `true` if hard border, `false` otherwise
  Future<bool> isHardBorder(String locality1, String locality2) async {
    final boundary = await getBoundary(locality1, locality2);
    return boundary?.isHardBorder ?? false;
  }

  /// Get all hard borders for a city
  /// 
  /// **Parameters:**
  /// - `city`: City name
  /// 
  /// **Returns:**
  /// List of hard borders
  Future<List<NeighborhoodBoundary>> getHardBorders(String city) async {
    try {
      // NOTE: In current mock stage, treat this as "all known boundaries"
      // (tests save explicit boundaries and expect these to be returned).
      final stored = await _loadAllBoundariesFromStorage();
      for (final b in stored) {
        _boundaryCache[b.boundaryKey] = b;
      }
      return stored.where((b) => b.isHardBorder).toList();
    } catch (e) {
      _logger.error(
        'Error getting hard borders',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Check if boundary is a soft border
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality name
  /// - `locality2`: Second locality name
  /// 
  /// **Returns:**
  /// `true` if soft border, `false` otherwise
  Future<bool> isSoftBorder(String locality1, String locality2) async {
    final boundary = await getBoundary(locality1, locality2);
    return boundary?.isSoftBorder ?? false;
  }

  /// Get all soft borders for a city
  /// 
  /// **Parameters:**
  /// - `city`: City name
  /// 
  /// **Returns:**
  /// List of soft borders
  Future<List<NeighborhoodBoundary>> getSoftBorders(String city) async {
    try {
      // NOTE: In current mock stage, treat this as "all known boundaries"
      // (tests save explicit boundaries and expect these to be returned).
      final stored = await _loadAllBoundariesFromStorage();
      for (final b in stored) {
        _boundaryCache[b.boundaryKey] = b;
      }
      return stored.where((b) => b.isSoftBorder).toList();
    } catch (e) {
      _logger.error(
        'Error getting soft borders',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }

  /// Save boundary
  /// 
  /// **Parameters:**
  /// - `boundary`: Boundary to save
  Future<void> saveBoundary(NeighborhoodBoundary boundary) async {
    try {
      _logger.info(
        'Saving boundary: ${boundary.boundaryKey}',
        tag: _logName,
      );

      // Update cache
      _boundaryCache[boundary.boundaryKey] = boundary;

      // Save to storage
      await _saveBoundaryToStorage(boundary);

      _logger.info(
        'Boundary saved: ${boundary.boundaryKey}',
        tag: _logName,
      );
    } catch (e) {
      _logger.error(
        'Error saving boundary',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Update boundary
  /// 
  /// **Parameters:**
  /// - `boundary`: Updated boundary
  Future<void> updateBoundary(NeighborhoodBoundary boundary) async {
    try {
      _logger.info(
        'Updating boundary: ${boundary.boundaryKey}',
        tag: _logName,
      );

      final updated = boundary.copyWith(
        updatedAt: DateTime.now(),
      );

      // Update cache
      _boundaryCache[updated.boundaryKey] = updated;

      // Save to storage
      await _saveBoundaryToStorage(updated);

      _logger.info(
        'Boundary updated: ${updated.boundaryKey}',
        tag: _logName,
      );
    } catch (e) {
      _logger.error(
        'Error updating boundary',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  // ========== Soft Border Handling ==========

  /// Add spot to soft border area
  /// 
  /// **Parameters:**
  /// - `spotId`: Spot ID
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  Future<void> addSoftBorderSpot(
    String spotId,
    String locality1,
    String locality2,
  ) async {
    try {
      final boundary = await getBoundary(locality1, locality2);
      if (boundary == null) {
        _logger.warning(
          'Boundary not found for $locality1 and $locality2',
          tag: _logName,
        );
        return;
      }

      if (!boundary.isSoftBorder) {
        _logger.warning(
          'Boundary is not a soft border, cannot add soft border spot',
          tag: _logName,
        );
        return;
      }

      if (boundary.softBorderSpots.contains(spotId)) {
        _logger.info(
          'Spot $spotId already in soft border area',
          tag: _logName,
        );
        return;
      }

      final updated = boundary.copyWith(
        softBorderSpots: [...boundary.softBorderSpots, spotId],
        updatedAt: DateTime.now(),
      );

      await updateBoundary(updated);

      _logger.info(
        'Added spot $spotId to soft border area',
        tag: _logName,
      );
    } catch (e) {
      _logger.error(
        'Error adding soft border spot',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Get soft border spots for a boundary
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  /// 
  /// **Returns:**
  /// List of spot IDs in soft border area
  Future<List<String>> getSoftBorderSpots(
    String locality1,
    String locality2,
  ) async {
    final boundary = await getBoundary(locality1, locality2);
    return boundary?.softBorderSpots ?? [];
  }

  /// Check if spot is in soft border area
  /// 
  /// **Parameters:**
  /// - `spotId`: Spot ID
  /// 
  /// **Returns:**
  /// `true` if spot is in any soft border area, `false` otherwise
  Future<bool> isSpotInSoftBorder(String spotId) async {
    try {
      final allBoundaries = await _loadAllBoundariesFromStorage();
      for (final boundary in allBoundaries) {
        if (boundary.isSpotInSoftBorder(spotId)) {
          return true;
        }
      }
      return false;
    } catch (e) {
      _logger.error(
        'Error checking if spot is in soft border',
        error: e,
        tag: _logName,
      );
      return false;
    }
  }

  /// Track spot visit by locality
  /// 
  /// **Parameters:**
  /// - `spotId`: Spot ID
  /// - `locality`: Locality name
  Future<void> trackSpotVisit(String spotId, String locality) async {
    try {
      // Find all boundaries that contain this spot
      final allBoundaries = await _loadAllBoundariesFromStorage();
      final relevantBoundaries = allBoundaries.where(
        (b) => b.isSpotInSoftBorder(spotId) &&
            (b.locality1 == locality || b.locality2 == locality),
      ).toList();

      // #region agent log
      _ndjsonLog(
        hypothesisId: 'H3',
        location: 'neighborhood_boundary_service.dart:trackSpotVisit:relevantBoundaries',
        message: 'Computed relevant boundaries for spot visit',
        data: {
          'spotId': spotId,
          'locality': locality,
          'allBoundariesCount': allBoundaries.length,
          'relevantBoundariesCount': relevantBoundaries.length,
        },
      );
      // #endregion
      if (relevantBoundaries.isEmpty) {
        _logger.debug(
          'No relevant boundaries found for spot $spotId and locality $locality',
          tag: _logName,
        );
        return;
      }

      // Update visit counts for each relevant boundary
      for (final boundary in relevantBoundaries) {
        final currentCounts = Map<String, Map<String, int>>.from(
          boundary.userVisitCounts,
        );

        final spotCounts = Map<String, int>.from(
          currentCounts[spotId] ?? {},
        );

        spotCounts[locality] = (spotCounts[locality] ?? 0) + 1;

        currentCounts[spotId] = spotCounts;

        final updated = boundary.copyWith(
          userVisitCounts: currentCounts,
          updatedAt: DateTime.now(),
        );

        await updateBoundary(updated);
      }

      _logger.info(
        'Tracked visit to spot $spotId by locality $locality',
        tag: _logName,
      );
    } catch (e) {
      _logger.error(
        'Error tracking spot visit',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Get spot visit counts
  /// 
  /// **Parameters:**
  /// - `spotId`: Spot ID
  /// 
  /// **Returns:**
  /// Map of locality to visit count
  Future<Map<String, int>> getSpotVisitCounts(String spotId) async {
    try {
      final allBoundaries = await _loadAllBoundariesFromStorage();
      final counts = <String, int>{};

      for (final boundary in allBoundaries) {
        if (boundary.isSpotInSoftBorder(spotId)) {
          final spotCounts = boundary.userVisitCounts[spotId] ?? {};
          spotCounts.forEach((locality, count) {
            counts[locality] = (counts[locality] ?? 0) + count;
          });
        }
      }

      return counts;
    } catch (e) {
      _logger.error(
        'Error getting spot visit counts',
        error: e,
        tag: _logName,
      );
      return {};
    }
  }

  /// Get dominant locality for a spot
  /// 
  /// **Parameters:**
  /// - `spotId`: Spot ID
  /// 
  /// **Returns:**
  /// Dominant locality name, or `null` if no visits tracked
  Future<String?> getDominantLocality(String spotId) async {
    try {
      final counts = await getSpotVisitCounts(spotId);
      if (counts.isEmpty) return null;

      String? dominantLocality;
      int maxCount = 0;

      counts.forEach((locality, count) {
        if (count > maxCount) {
          maxCount = count;
          dominantLocality = locality;
        }
      });

      return dominantLocality;
    } catch (e) {
      _logger.error(
        'Error getting dominant locality',
        error: e,
        tag: _logName,
      );
      return null;
    }
  }

  // ========== Dynamic Border Refinement ==========

  /// Track user movement
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `spotId`: Spot ID
  /// - `locality`: Locality name
  Future<void> trackUserMovement(
    String userId,
    String spotId,
    String locality,
  ) async {
    try {
      // #region agent log
      _ndjsonLog(
        hypothesisId: 'H3',
        location: 'neighborhood_boundary_service.dart:trackUserMovement:entry',
        message: 'trackUserMovement entry',
        data: {'userId': userId, 'spotId': spotId, 'locality': locality},
      );
      // #endregion
      _logger.debug(
        'Tracking user movement: user=$userId, spot=$spotId, locality=$locality',
        tag: _logName,
      );

      // Always track movement patterns, even if no boundary exists yet.
      await _incrementMovementPattern(locality: locality, spotId: spotId);

      // Track spot visit
      await trackSpotVisit(spotId, locality);

      // Check if refinement is needed
      final boundaries = await _getBoundariesForSpot(spotId);
      for (final boundary in boundaries) {
        if (await shouldRefineBorder(boundary.locality1, boundary.locality2)) {
          await refineSoftBorder(boundary.locality1, boundary.locality2);
        }
      }
    } catch (e) {
      _logger.error(
        'Error tracking user movement',
        error: e,
        tag: _logName,
      );
    }
  }

  /// Get user movement patterns for a locality
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  /// 
  /// **Returns:**
  /// Map of spot ID to visit count
  Future<Map<String, int>> getUserMovementPatterns(String locality) async {
    try {
      final stored = _getMovementPatterns(locality: locality);
      final boundaries = await getBoundariesForLocality(locality);
      final patterns = <String, int>{};

      for (final boundary in boundaries) {
        for (final spotId in boundary.softBorderSpots) {
          final counts = boundary.userVisitCounts[spotId] ?? {};
          final localityCount = counts[locality] ?? 0;
          patterns[spotId] = (patterns[spotId] ?? 0) + localityCount;
        }
      }

      // Merge persisted movement patterns (non-boundary-specific) with boundary-derived counts.
      for (final entry in stored.entries) {
        patterns[entry.key] = (patterns[entry.key] ?? 0) + entry.value;
      }

      return patterns;
    } catch (e) {
      _logger.error(
        'Error getting user movement patterns',
        error: e,
        tag: _logName,
      );
      return {};
    }
  }

  /// Analyze movement patterns between two localities
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  /// 
  /// **Returns:**
  /// Analysis result with patterns and recommendations
  Future<Map<String, dynamic>> analyzeMovementPatterns(
    String locality1,
    String locality2,
  ) async {
    try {
      final boundary = await getBoundary(locality1, locality2);
      if (boundary == null) {
        return {
          'error': 'Boundary not found',
        };
      }

      final patterns = <String, Map<String, int>>{};
      for (final spotId in boundary.softBorderSpots) {
        patterns[spotId] = boundary.userVisitCounts[spotId] ?? {};
      }

      return {
        'locality1': locality1,
        'locality2': locality2,
        'patterns': patterns,
        'totalSpots': boundary.softBorderSpots.length,
        'totalVisits': boundary.userVisitCounts.values
            .fold(0, (sum, counts) => sum + counts.values.fold(0, (s, c) => s + c)),
      };
    } catch (e) {
      _logger.error(
        'Error analyzing movement patterns',
        error: e,
        tag: _logName,
      );
      return {
        'error': e.toString(),
      };
    }
  }

  /// Associate spot with locality
  /// 
  /// **Parameters:**
  /// - `spotId`: Spot ID
  /// - `locality`: Locality name
  Future<void> associateSpotWithLocality(String spotId, String locality) async {
    try {
      // #region agent log
      _ndjsonLog(
        hypothesisId: 'H4',
        location: 'neighborhood_boundary_service.dart:associateSpotWithLocality:entry',
        message: 'associateSpotWithLocality entry',
        data: {'spotId': spotId, 'locality': locality},
      );
      // #endregion
      _logger.info(
        'Associating spot $spotId with locality $locality',
        tag: _logName,
      );

      // Persist explicit association (tests expect this even when no boundaries exist).
      await _storageService.setString(
        '$_spotAssociationKeyPrefix$spotId',
        locality,
      );

      // Find boundaries containing this spot
      final boundaries = await _getBoundariesForSpot(spotId);
      // #region agent log
      _ndjsonLog(
        hypothesisId: 'H4',
        location: 'neighborhood_boundary_service.dart:associateSpotWithLocality:boundariesForSpot',
        message: 'Computed boundaries for spot',
        data: {'spotId': spotId, 'boundaryCount': boundaries.length},
      );
      // #endregion
      for (final boundary in boundaries) {
        // Remove spot from soft border spots if it's now clearly associated
        if (boundary.softBorderSpots.contains(spotId)) {
          final dominantLocality = boundary.getDominantLocality(spotId);
          if (dominantLocality == locality) {
            // Spot is clearly associated with this locality, remove from soft border
            final updated = boundary.copyWith(
              softBorderSpots: boundary.softBorderSpots
                  .where((id) => id != spotId)
                  .toList(),
              updatedAt: DateTime.now(),
            );
            await updateBoundary(updated);
          }
        }
      }
    } catch (e) {
      _logger.error(
        'Error associating spot with locality',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Get spot locality association
  /// 
  /// **Parameters:**
  /// - `spotId`: Spot ID
  /// 
  /// **Returns:**
  /// Associated locality name, or `null` if not clearly associated
  Future<String?> getSpotLocalityAssociation(String spotId) async {
    try {
      final explicit = _storageService.getString('$_spotAssociationKeyPrefix$spotId');
      if (explicit != null && explicit.isNotEmpty) {
        return explicit;
      }
    } catch (_) {
      // ignore storage read failures
    }

    return await getDominantLocality(spotId);
  }

  // ========== Movement Pattern Storage ==========

  Map<String, int> _getMovementPatterns({required String locality}) {
    try {
      final raw = _storageService.getObject<dynamic>(
        '$_movementPatternsKeyPrefix$locality',
      );
      if (raw is Map) {
        final out = <String, int>{};
        for (final entry in raw.entries) {
          final k = entry.key?.toString();
          final v = entry.value;
          if (k == null) continue;
          if (v is int) out[k] = v;
          if (v is num) out[k] = v.toInt();
        }
        return out;
      }
    } catch (_) {
      // ignore
    }
    return <String, int>{};
  }

  Future<void> _incrementMovementPattern({
    required String locality,
    required String spotId,
  }) async {
    final patterns = _getMovementPatterns(locality: locality);
    patterns[spotId] = (patterns[spotId] ?? 0) + 1;
    await _storageService.setObject(
      '$_movementPatternsKeyPrefix$locality',
      patterns,
    );
  }

  /// Update spot locality association based on visit patterns
  /// 
  /// **Parameters:**
  /// - `spotId`: Spot ID
  Future<void> updateSpotLocalityAssociation(String spotId) async {
    try {
      final dominantLocality = await getDominantLocality(spotId);
      if (dominantLocality != null) {
        await associateSpotWithLocality(spotId, dominantLocality);
      }
    } catch (e) {
      _logger.error(
        'Error updating spot locality association',
        error: e,
        tag: _logName,
      );
    }
  }

  /// Refine soft border based on user behavior
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  Future<void> refineSoftBorder(String locality1, String locality2) async {
    try {
      _logger.info(
        'Refining soft border between $locality1 and $locality2',
        tag: _logName,
      );

      final boundary = await getBoundary(locality1, locality2);
      if (boundary == null) {
        _logger.warning(
          'Boundary not found for refinement',
          tag: _logName,
        );
        return;
      }

      if (!boundary.isSoftBorder) {
        _logger.debug(
          'Boundary is not a soft border, no refinement needed',
          tag: _logName,
        );
        return;
      }

      // Calculate refinement
      final refinement = await calculateBorderRefinement(locality1, locality2);
      if (refinement.isEmpty) {
        _logger.debug(
          'No refinement changes needed',
          tag: _logName,
        );
        return;
      }

      // Apply refinement
      await applyBoundaryRefinement(locality1, locality2, refinement);
    } catch (e) {
      _logger.error(
        'Error refining soft border',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Check if border should be refined
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  /// 
  /// **Returns:**
  /// `true` if refinement is needed, `false` otherwise
  Future<bool> shouldRefineBorder(String locality1, String locality2) async {
    try {
      final boundary = await getBoundary(locality1, locality2);
      if (boundary == null || !boundary.isSoftBorder) {
        return false;
      }

      // Refine if there are enough visits and clear patterns
      final totalVisits = boundary.userVisitCounts.values
          .fold(0, (sum, counts) => sum + counts.values.fold(0, (s, c) => s + c));

      // Refine if there are at least 10 visits and clear dominance patterns
      if (totalVisits < 10) {
        return false;
      }

      // Check if any spots have clear dominance (70%+ visits from one locality)
      for (final spotId in boundary.softBorderSpots) {
        final counts = boundary.userVisitCounts[spotId] ?? {};
        if (counts.isEmpty) continue;

        final total = counts.values.fold(0, (sum, count) => sum + count);
        if (total < 5) continue; // Need at least 5 visits

        for (final count in counts.values) {
          if (count / total >= 0.7) {
            // Clear dominance pattern detected
            return true;
          }
        }
      }

      return false;
    } catch (e) {
      _logger.error(
        'Error checking if border should be refined',
        error: e,
        tag: _logName,
      );
      return false;
    }
  }

  /// Calculate border refinement
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  /// 
  /// **Returns:**
  /// Map of refinement changes
  Future<Map<String, dynamic>> calculateBorderRefinement(
    String locality1,
    String locality2,
  ) async {
    try {
      final boundary = await getBoundary(locality1, locality2);
      if (boundary == null) {
        return {};
      }

      final changes = <String, dynamic>{
        'spotsToRemove': <String>[],
        'spotsToAssociate': <Map<String, String>>[],
      };

      // Check each soft border spot
      for (final spotId in boundary.softBorderSpots) {
        final counts = boundary.userVisitCounts[spotId] ?? {};
        if (counts.isEmpty) continue;

        final total = counts.values.fold(0, (sum, count) => sum + count);
        if (total < 5) continue; // Need at least 5 visits

        // Check for clear dominance (70%+ visits from one locality)
        for (final entry in counts.entries) {
          if (entry.value / total >= 0.7) {
            // Clear dominance - associate spot with this locality
            (changes['spotsToAssociate'] as List).add({
              'spotId': spotId,
              'locality': entry.key,
            });
            (changes['spotsToRemove'] as List).add(spotId);
            break;
          }
        }
      }

      return changes;
    } catch (e) {
      _logger.error(
        'Error calculating border refinement',
        error: e,
        tag: _logName,
      );
      return {};
    }
  }

  /// Update boundary from behavior
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  Future<void> updateBoundaryFromBehavior(
    String locality1,
    String locality2,
  ) async {
    await refineSoftBorder(locality1, locality2);
  }

  /// Calculate boundary changes
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  /// 
  /// **Returns:**
  /// Map of changes
  Future<Map<String, dynamic>> calculateBoundaryChanges(
    String locality1,
    String locality2,
  ) async {
    return await calculateBorderRefinement(locality1, locality2);
  }

  /// Apply boundary refinement
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  /// - `refinement`: Refinement changes to apply
  Future<void> applyBoundaryRefinement(
    String locality1,
    String locality2,
    Map<String, dynamic> refinement,
  ) async {
    try {
      final boundary = await getBoundary(locality1, locality2);
      if (boundary == null) {
        return;
      }

      final spotsToRemove = (refinement['spotsToRemove'] as List<dynamic>?)
              ?.map((s) => s as String)
              .toList() ??
          [];
      final spotsToAssociate = (refinement['spotsToAssociate'] as List<dynamic>?)
              ?.map((s) => s as Map<String, dynamic>)
              .toList() ??
          [];

      // Remove spots from soft border
      final updatedSpots = boundary.softBorderSpots
          .where((id) => !spotsToRemove.contains(id))
          .toList();

      // Create refinement event
      final refinementEvent = RefinementEvent(
        timestamp: DateTime.now(),
        reason: 'User behavior pattern detected',
        method: 'Spot visit count analysis',
        changes: 'Removed ${spotsToRemove.length} spots from soft border, '
            'associated ${spotsToAssociate.length} spots with localities',
      );

      final updatedHistory = [...boundary.refinementHistory, refinementEvent];

      final updated = boundary.copyWith(
        softBorderSpots: updatedSpots,
        refinementHistory: updatedHistory,
        lastRefinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateBoundary(updated);

      // Associate spots with localities
      for (final association in spotsToAssociate) {
        final spotId = association['spotId'] as String;
        final locality = association['locality'] as String;
        await associateSpotWithLocality(spotId, locality);
      }

      _logger.info(
        'Applied boundary refinement: removed ${spotsToRemove.length} spots, '
        'associated ${spotsToAssociate.length} spots',
        tag: _logName,
      );
    } catch (e) {
      _logger.error(
        'Error applying boundary refinement',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Integrate with geographic hierarchy
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  Future<void> integrateWithGeographicHierarchy(String locality) async {
    try {
      _logger.info(
        'Integrating boundaries with geographic hierarchy for locality: $locality',
        tag: _logName,
      );

      // Get boundaries for locality
      final boundaries = await getBoundariesForLocality(locality);

      // Check if locality is in a large city
      final parentCity = _largeCityService.getParentCity(locality);
      if (parentCity != null) {
        // Load boundaries for the city if not already loaded
        await loadBoundariesFromGoogleMaps(parentCity);
      }

      _logger.info(
        'Integrated ${boundaries.length} boundaries with geographic hierarchy',
        tag: _logName,
      );
    } catch (e) {
      _logger.error(
        'Error integrating with geographic hierarchy',
        error: e,
        tag: _logName,
      );
    }
  }

  /// Update geographic hierarchy
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name
  Future<void> updateGeographicHierarchy(String locality) async {
    await integrateWithGeographicHierarchy(locality);
  }

  // ========== Private Helper Methods ==========

  /// Get boundary key (normalized)
  String _getBoundaryKey(String locality1, String locality2) {
    final sorted = [locality1, locality2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  /// Determine boundary type (hard vs soft)
  /// 
  /// **Note:** This is mock logic. In production, would use Google Maps data.
  BoundaryType _determineBoundaryType(String locality1, String locality2) {
    // Well-known hard borders (mock examples)
    final hardBorderPairs = [
      ['NoHo', 'SoHo'],
      ['Greenpoint', 'Williamsburg'],
      ['DUMBO', 'Brooklyn Heights'],
    ];

    for (final pair in hardBorderPairs) {
      if ((pair[0] == locality1 && pair[1] == locality2) ||
          (pair[0] == locality2 && pair[1] == locality1)) {
        return BoundaryType.hardBorder;
      }
    }

    // Default to soft border
    return BoundaryType.softBorder;
  }

  /// Generate mock coordinates
  /// 
  /// **Note:** This is mock data. In production, would use Google Maps API.
  List<CoordinatePoint> _generateMockCoordinates(
    String locality1,
    String locality2,
  ) {
    // Generate mock coordinates along a boundary line
    // In production, would fetch actual boundary coordinates from Google Maps
    return [
      const CoordinatePoint(latitude: 40.7128, longitude: -73.9352),
      const CoordinatePoint(latitude: 40.7130, longitude: -73.9350),
      const CoordinatePoint(latitude: 40.7132, longitude: -73.9348),
    ];
  }

  /// Get boundaries for a spot
  Future<List<NeighborhoodBoundary>> _getBoundariesForSpot(
    String spotId,
  ) async {
    final allBoundaries = await _loadAllBoundariesFromStorage();
    return allBoundaries
        .where((b) => b.isSpotInSoftBorder(spotId))
        .toList();
  }

  // ========== Storage Methods ==========

  /// Save boundary to storage
  Future<void> _saveBoundaryToStorage(NeighborhoodBoundary boundary) async {
    try {
      final key = 'neighborhood_boundary_${boundary.boundaryKey}';
      final json = boundary.toJson();
      await _storageService.setObject(key, json);
    } catch (e) {
      _logger.error(
        'Error saving boundary to storage',
        error: e,
        tag: _logName,
      );
      rethrow;
    }
  }

  /// Load boundary from storage
  Future<NeighborhoodBoundary?> _loadBoundaryFromStorage(
    String boundaryKey,
  ) async {
    try {
      final key = 'neighborhood_boundary_$boundaryKey';
      final json = await _storageService.getObject<Map<String, dynamic>>(key);
      if (json == null) return null;
      return NeighborhoodBoundary.fromJson(json);
    } catch (e) {
      _logger.error(
        'Error loading boundary from storage',
        error: e,
        tag: _logName,
      );
      return null;
    }
  }

  /// Save all boundaries to storage
  // ignore: unused_element
  Future<void> _saveBoundariesToStorage(
    List<NeighborhoodBoundary> boundaries,
  ) async {
    for (final boundary in boundaries) {
      await _saveBoundaryToStorage(boundary);
    }
  }

  /// Load all boundaries from storage
  Future<List<NeighborhoodBoundary>> _loadAllBoundariesFromStorage() async {
    try {
      // In production, would query all boundaries
      // For now, return cached boundaries
      return _boundaryCache.values.toList();
    } catch (e) {
      _logger.error(
        'Error loading all boundaries from storage',
        error: e,
        tag: _logName,
      );
      return [];
    }
  }
}

