import 'package:spots/core/models/geographic_expansion.dart';
import 'package:spots/core/models/expertise_event.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/geographic_scope_service.dart';

/// Geographic Expansion Service
/// 
/// Tracks geographic expansion of clubs/communities from original locality.
/// 
/// **Philosophy Alignment:**
/// - Clubs/communities can expand naturally (doors open through growth)
/// - 75% coverage rule enables expertise gain at each geographic level
/// - Geographic expansion enabled (locality → universe)
/// 
/// **Key Features:**
/// - Track event expansion from original locality
/// - Measure coverage (commute patterns OR event hosting)
/// - Calculate 75% thresholds for each geographic level
/// - Expansion management (get, update, history)
class GeographicExpansionService {
  static const String _logName = 'GeographicExpansionService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final GeographicScopeService _geographicScopeService;

  // In-memory storage (in production, use database)
  final Map<String, GeographicExpansion> _expansions = {};

  GeographicExpansionService({
    GeographicScopeService? geographicScopeService,
  }) : _geographicScopeService =
            geographicScopeService ?? GeographicScopeService();

  /// Track event expansion from original locality
  /// 
  /// Called when a club/community hosts an event in a new locality.
  /// 
  /// **Parameters:**
  /// - `clubId`: Club or Community ID
  /// - `isClub`: Whether this is for a club (true) or community (false)
  /// - `event`: Event that triggered expansion
  /// - `eventLocation`: Location of the event (locality, city, state, nation)
  /// 
  /// **Returns:**
  /// Updated GeographicExpansion
  Future<GeographicExpansion> trackEventExpansion({
    required String clubId,
    required bool isClub,
    required ExpertiseEvent event,
    required String eventLocation,
  }) async {
    try {
      _logger.info(
        'Tracking event expansion: club=$clubId, event=${event.id}, location=$eventLocation',
        tag: _logName,
      );

      // Get or create expansion
      GeographicExpansion expansion = _expansions[clubId] ??
          GeographicExpansion(
            id: _generateId(),
            clubId: clubId,
            isClub: isClub,
            originalLocality: eventLocation,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      // Extract geographic components
      final locality = _extractLocality(eventLocation);
      final city = _extractCity(eventLocation);
      final state = _extractState(eventLocation);
      final nation = _extractNation(eventLocation);

      if (locality == null) {
        throw Exception('Could not extract locality from event location');
      }

      // Check if this is a new locality
      final isNewLocality = !expansion.expandedLocalities.contains(locality);
      final isNewCity = city != null && !expansion.expandedCities.contains(city);
      final isNewState = state != null && !expansion.expandedStates.contains(state);
      final isNewNation = nation != null && !expansion.expandedNations.contains(nation);

      // Update expanded lists
      List<String> updatedLocalities = List.from(expansion.expandedLocalities);
      List<String> updatedCities = List.from(expansion.expandedCities);
      List<String> updatedStates = List.from(expansion.expandedStates);
      List<String> updatedNations = List.from(expansion.expandedNations);

      if (isNewLocality) {
        updatedLocalities.add(locality);
      }

      if (isNewCity) {
        updatedCities.add(city);
      }

      if (isNewState) {
        updatedStates.add(state);
      }

      if (isNewNation) {
        updatedNations.add(nation);
      }

      // Update event hosting locations
      Map<String, List<String>> updatedEventHostingLocations =
          Map.from(expansion.eventHostingLocations);
      if (!updatedEventHostingLocations.containsKey(locality)) {
        updatedEventHostingLocations[locality] = [];
      }
      updatedEventHostingLocations[locality]!.add(event.id);

      // Recalculate coverage
      final updatedLocalityCoverage = await _recalculateLocalityCoverage(
        expansion: expansion,
        updatedLocalities: updatedLocalities,
        updatedEventHostingLocations: updatedEventHostingLocations,
      );

      final updatedCityCoverage = await _recalculateCityCoverage(
        expansion: expansion,
        updatedLocalities: updatedLocalities,
        updatedCities: updatedCities,
      );

      final updatedStateCoverage = await _recalculateStateCoverage(
        expansion: expansion,
        updatedLocalities: updatedLocalities,
        updatedStates: updatedStates,
      );

      final updatedNationCoverage = await _recalculateNationCoverage(
        expansion: expansion,
        updatedLocalities: updatedLocalities,
        updatedNations: updatedNations,
      );

      // Create expansion event
      final expansionEvent = ExpansionEvent(
        timestamp: DateTime.now(),
        location: eventLocation,
        geographicLevel: 'locality',
        expansionMethod: 'event_hosting',
        eventId: event.id,
        coveragePercentage: updatedLocalityCoverage[locality] ?? 0.0,
      );

      // Update expansion history
      List<ExpansionEvent> updatedHistory = List.from(expansion.expansionHistory);
      updatedHistory.add(expansionEvent);

      // Update timestamps
      final now = DateTime.now();
      final firstExpansion = expansion.firstExpansionAt ?? now;
      final lastExpansion = now;

      // Create updated expansion
      final updatedExpansion = expansion.copyWith(
        expandedLocalities: updatedLocalities,
        expandedCities: updatedCities,
        expandedStates: updatedStates,
        expandedNations: updatedNations,
        localityCoverage: updatedLocalityCoverage,
        cityCoverage: updatedCityCoverage,
        stateCoverage: updatedStateCoverage,
        nationCoverage: updatedNationCoverage,
        eventHostingLocations: updatedEventHostingLocations,
        expansionHistory: updatedHistory,
        firstExpansionAt: firstExpansion,
        lastExpansionAt: lastExpansion,
        updatedAt: now,
      );

      // Save expansion
      await _saveExpansion(updatedExpansion);

      _logger.info(
        'Event expansion tracked: club=$clubId, localities=${updatedLocalities.length}',
        tag: _logName,
      );

      return updatedExpansion;
    } catch (e) {
      _logger.error('Error tracking event expansion', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Track commute pattern
  /// 
  /// Called when people commute to events (attendees from different localities).
  /// 
  /// **Parameters:**
  /// - `clubId`: Club or Community ID
  /// - `eventLocality`: Locality where event is hosted
  /// - `attendeeLocalities`: List of localities where attendees came from
  /// 
  /// **Returns:**
  /// Updated GeographicExpansion
  Future<GeographicExpansion> trackCommutePattern({
    required String clubId,
    required String eventLocality,
    required List<String> attendeeLocalities,
  }) async {
    try {
      _logger.info(
        'Tracking commute pattern: club=$clubId, eventLocality=$eventLocality, attendees=${attendeeLocalities.length}',
        tag: _logName,
      );

      // Get expansion
      final expansion = _expansions[clubId];
      if (expansion == null) {
        throw Exception('Expansion not found for club $clubId');
      }

      // Update commute patterns
      Map<String, List<String>> updatedCommutePatterns =
          Map.from(expansion.commutePatterns);
      if (!updatedCommutePatterns.containsKey(eventLocality)) {
        updatedCommutePatterns[eventLocality] = [];
      }

      // Add unique attendee localities
      final existingPatterns = updatedCommutePatterns[eventLocality]!;
      for (final attendeeLocality in attendeeLocalities) {
        if (!existingPatterns.contains(attendeeLocality)) {
          existingPatterns.add(attendeeLocality);
        }
      }

      // Recalculate coverage (commute patterns contribute to coverage)
      final updatedLocalityCoverage = await _recalculateLocalityCoverage(
        expansion: expansion,
        updatedLocalities: expansion.expandedLocalities,
        updatedEventHostingLocations: expansion.eventHostingLocations,
        commutePatterns: updatedCommutePatterns,
      );

      // Create expansion event
      final expansionEvent = ExpansionEvent(
        timestamp: DateTime.now(),
        location: eventLocality,
        geographicLevel: 'locality',
        expansionMethod: 'commute_pattern',
        coveragePercentage: updatedLocalityCoverage[eventLocality] ?? 0.0,
      );

      // Update expansion history
      List<ExpansionEvent> updatedHistory = List.from(expansion.expansionHistory);
      updatedHistory.add(expansionEvent);

      // Create updated expansion
      final updatedExpansion = expansion.copyWith(
        commutePatterns: updatedCommutePatterns,
        localityCoverage: updatedLocalityCoverage,
        expansionHistory: updatedHistory,
        lastExpansionAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save expansion
      await _saveExpansion(updatedExpansion);

      _logger.info(
        'Commute pattern tracked: club=$clubId, eventLocality=$eventLocality',
        tag: _logName,
      );

      return updatedExpansion;
    } catch (e) {
      _logger.error('Error tracking commute pattern', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate locality coverage
  /// 
  /// Coverage is calculated based on:
  /// - Event hosting locations (events hosted in locality)
  /// - Commute patterns (people commuting to events)
  /// 
  /// **Returns:**
  /// Map of locality → coverage percentage (0.0 to 1.0)
  Future<Map<String, double>> calculateLocalityCoverage({
    required GeographicExpansion expansion,
  }) async {
    try {
      return await _recalculateLocalityCoverage(
        expansion: expansion,
        updatedLocalities: expansion.expandedLocalities,
        updatedEventHostingLocations: expansion.eventHostingLocations,
        commutePatterns: expansion.commutePatterns,
      );
    } catch (e) {
      _logger.error('Error calculating locality coverage', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate city coverage
  /// 
  /// Coverage is calculated as percentage of localities in city that have coverage.
  /// 
  /// **Returns:**
  /// Map of city → coverage percentage (0.0 to 1.0)
  Future<Map<String, double>> calculateCityCoverage({
    required GeographicExpansion expansion,
  }) async {
    try {
      return await _recalculateCityCoverage(
        expansion: expansion,
        updatedLocalities: expansion.expandedLocalities,
        updatedCities: expansion.expandedCities,
      );
    } catch (e) {
      _logger.error('Error calculating city coverage', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate state coverage
  /// 
  /// Coverage is calculated as percentage of localities in state that have coverage.
  /// 
  /// **Returns:**
  /// Map of state → coverage percentage (0.0 to 1.0)
  Future<Map<String, double>> calculateStateCoverage({
    required GeographicExpansion expansion,
  }) async {
    try {
      return await _recalculateStateCoverage(
        expansion: expansion,
        updatedLocalities: expansion.expandedLocalities,
        updatedStates: expansion.expandedStates,
      );
    } catch (e) {
      _logger.error('Error calculating state coverage', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate nation coverage
  /// 
  /// Coverage is calculated as percentage of localities in nation that have coverage.
  /// 
  /// **Returns:**
  /// Map of nation → coverage percentage (0.0 to 1.0)
  Future<Map<String, double>> calculateNationCoverage({
    required GeographicExpansion expansion,
  }) async {
    try {
      return await _recalculateNationCoverage(
        expansion: expansion,
        updatedLocalities: expansion.expandedLocalities,
        updatedNations: expansion.expandedNations,
      );
    } catch (e) {
      _logger.error('Error calculating nation coverage', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Calculate global coverage
  /// 
  /// Coverage is calculated as average coverage across all nations.
  /// 
  /// **Returns:**
  /// Global coverage percentage (0.0 to 1.0)
  Future<double> calculateGlobalCoverage({
    required GeographicExpansion expansion,
  }) async {
    try {
      if (expansion.nationCoverage.isEmpty) return 0.0;

      // Calculate average nation coverage
      final totalCoverage = expansion.nationCoverage.values.fold(
        0.0,
        (sum, coverage) => sum + coverage,
      );
      return totalCoverage / expansion.nationCoverage.length;
    } catch (e) {
      _logger.error('Error calculating global coverage', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Check if expansion has reached locality threshold
  /// 
  /// Locality threshold: Any locality with >0 coverage
  bool hasReachedLocalityThreshold(GeographicExpansion expansion) {
    return expansion.hasReachedLocalityThreshold();
  }

  /// Check if expansion has reached city threshold (75% city coverage)
  bool hasReachedCityThreshold(GeographicExpansion expansion, String city) {
    return expansion.hasReachedCityThreshold(city);
  }

  /// Check if expansion has reached state threshold (75% state coverage)
  bool hasReachedStateThreshold(GeographicExpansion expansion, String state) {
    return expansion.hasReachedStateThreshold(state);
  }

  /// Check if expansion has reached nation threshold (75% nation coverage)
  bool hasReachedNationThreshold(GeographicExpansion expansion, String nation) {
    return expansion.hasReachedNationThreshold(nation);
  }

  /// Check if expansion has reached global threshold (75% global coverage)
  bool hasReachedGlobalThreshold(GeographicExpansion expansion) {
    return expansion.hasReachedGlobalThreshold();
  }

  /// Get expansion by club ID
  GeographicExpansion? getExpansionByClub(String clubId) {
    return _expansions[clubId];
  }

  /// Get expansion by community ID
  GeographicExpansion? getExpansionByCommunity(String communityId) {
    return _expansions[communityId];
  }

  /// Update expansion
  Future<GeographicExpansion> updateExpansion(
    GeographicExpansion expansion,
  ) async {
    try {
      await _saveExpansion(expansion);
      return expansion;
    } catch (e) {
      _logger.error('Error updating expansion', error: e, tag: _logName);
      rethrow;
    }
  }

  /// Get expansion history
  List<ExpansionEvent> getExpansionHistory(String clubId) {
    final expansion = _expansions[clubId];
    if (expansion == null) return [];
    return expansion.expansionHistory;
  }

  // Private helper methods

  /// Recalculate locality coverage
  Future<Map<String, double>> _recalculateLocalityCoverage({
    required GeographicExpansion expansion,
    required List<String> updatedLocalities,
    required Map<String, List<String>> updatedEventHostingLocations,
    Map<String, List<String>>? commutePatterns,
  }) async {
    final coverage = <String, double>{};

    for (final locality in updatedLocalities) {
      // Calculate coverage based on:
      // - Event hosting (events hosted in locality)
      // - Commute patterns (people commuting to events)
      
      final eventsInLocality = updatedEventHostingLocations[locality]?.length ?? 0;
      final commuteSources = commutePatterns?[locality]?.length ?? 0;
      
      // Coverage = (events + commute sources) / (events + commute sources + 1)
      // This gives a value between 0.0 and 1.0
      final totalActivity = eventsInLocality + commuteSources;
      final coverageValue = totalActivity > 0
          ? (totalActivity / (totalActivity + 1)).clamp(0.0, 1.0)
          : 0.0;
      
      coverage[locality] = coverageValue;
    }

    return coverage;
  }

  /// Recalculate city coverage
  Future<Map<String, double>> _recalculateCityCoverage({
    required GeographicExpansion expansion,
    required List<String> updatedLocalities,
    required List<String> updatedCities,
  }) async {
    final coverage = <String, double>{};

    for (final city in updatedCities) {
      // Count localities in this city that have coverage
      final localitiesInCity = updatedLocalities.where((locality) {
        final localityCity = _extractCity(locality);
        return localityCity?.toLowerCase() == city.toLowerCase();
      }).toList();

      if (localitiesInCity.isEmpty) {
        coverage[city] = 0.0;
        continue;
      }

      // Calculate coverage as percentage of localities with coverage
      // In production, would query total localities in city
      // For now, use simplified calculation
      final localitiesWithCoverage = localitiesInCity.length;
      final totalLocalitiesInCity = localitiesWithCoverage + 1; // Simplified
      final coverageValue = (localitiesWithCoverage / totalLocalitiesInCity).clamp(0.0, 1.0);
      
      coverage[city] = coverageValue;
    }

    return coverage;
  }

  /// Recalculate state coverage
  Future<Map<String, double>> _recalculateStateCoverage({
    required GeographicExpansion expansion,
    required List<String> updatedLocalities,
    required List<String> updatedStates,
  }) async {
    final coverage = <String, double>{};

    for (final state in updatedStates) {
      // Count localities in this state that have coverage
      final localitiesInState = updatedLocalities.where((locality) {
        final localityState = _extractState(locality);
        return localityState?.toLowerCase() == state.toLowerCase();
      }).toList();

      if (localitiesInState.isEmpty) {
        coverage[state] = 0.0;
        continue;
      }

      // Calculate coverage as percentage of localities with coverage
      // In production, would query total localities in state
      // For now, use simplified calculation
      final localitiesWithCoverage = localitiesInState.length;
      final totalLocalitiesInState = localitiesWithCoverage + 1; // Simplified
      final coverageValue = (localitiesWithCoverage / totalLocalitiesInState).clamp(0.0, 1.0);
      
      coverage[state] = coverageValue;
    }

    return coverage;
  }

  /// Recalculate nation coverage
  Future<Map<String, double>> _recalculateNationCoverage({
    required GeographicExpansion expansion,
    required List<String> updatedLocalities,
    required List<String> updatedNations,
  }) async {
    final coverage = <String, double>{};

    for (final nation in updatedNations) {
      // Count localities in this nation that have coverage
      final localitiesInNation = updatedLocalities.where((locality) {
        final localityNation = _extractNation(locality);
        return localityNation?.toLowerCase() == nation.toLowerCase();
      }).toList();

      if (localitiesInNation.isEmpty) {
        coverage[nation] = 0.0;
        continue;
      }

      // Calculate coverage as percentage of localities with coverage
      // In production, would query total localities in nation
      // For now, use simplified calculation
      final localitiesWithCoverage = localitiesInNation.length;
      final totalLocalitiesInNation = localitiesWithCoverage + 1; // Simplified
      final coverageValue = (localitiesWithCoverage / totalLocalitiesInNation).clamp(0.0, 1.0);
      
      coverage[nation] = coverageValue;
    }

    return coverage;
  }

  /// Extract locality from location string
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }

  /// Extract city from location string
  String? _extractCity(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',').map((s) => s.trim()).toList();
    if (parts.length < 2) return null;
    return parts[1];
  }

  /// Extract state from location string
  String? _extractState(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',').map((s) => s.trim()).toList();
    if (parts.length < 3) return null;
    return parts[2];
  }

  /// Extract nation from location string
  String? _extractNation(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',').map((s) => s.trim()).toList();
    if (parts.length < 4) return null;
    return parts[3];
  }

  /// Save expansion (in-memory for now)
  Future<void> _saveExpansion(GeographicExpansion expansion) async {
    _expansions[expansion.clubId] = expansion;
  }

  /// Generate unique ID
  String _generateId() {
    return 'expansion-${DateTime.now().millisecondsSinceEpoch}';
  }
}

