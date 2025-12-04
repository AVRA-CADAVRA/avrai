import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/large_city_detection_service.dart';

/// Geographic Scope Service
/// 
/// Enforces geographic hierarchy for event hosting:
/// - Local experts can only host in their locality
/// - City experts can host in all localities in their city
/// - State experts can host in all cities/localities in their state
/// - National experts can host in all states/cities/localities in their nation
/// - Global experts can host globally
/// - Universal experts can host anywhere
/// 
/// **Philosophy:** Local experts are the bread and butter of SPOTS.
/// They don't need city-wide reach to host events in their locality.
/// This service ensures geographic scope is properly enforced.
class GeographicScopeService {
  static const String _logName = 'GeographicScopeService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final LargeCityDetectionService _largeCityService;

  GeographicScopeService({
    LargeCityDetectionService? largeCityService,
  }) : _largeCityService = largeCityService ?? LargeCityDetectionService();

  /// Check if user can host events in a specific locality
  /// 
  /// **Rules:**
  /// - Local experts: Can only host in their own locality
  /// - City experts: Can host in all localities in their city
  /// - State experts: Can host in all localities in their state
  /// - National experts: Can host in all localities in their nation
  /// - Global/Universal experts: Can host anywhere
  /// 
  /// **Parameters:**
  /// - `userId`: User ID (for logging)
  /// - `user`: UnifiedUser to check expertise and location
  /// - `category`: Expertise category to check
  /// - `locality`: Target locality to host in
  /// 
  /// **Returns:**
  /// `true` if user can host in the locality, `false` otherwise
  bool canHostInLocality({
    required String userId,
    required UnifiedUser user,
    required String category,
    required String locality,
  }) {
    try {
      _logger.info(
        'Checking if user $userId can host in locality: $locality',
        tag: _logName,
      );

      final expertiseLevel = user.getExpertiseLevel(category);
      if (expertiseLevel == null) {
        _logger.warning(
          'User $userId has no expertise in category: $category',
          tag: _logName,
        );
        return false;
      }

      // Get user's location (locality)
      final userLocality = _extractLocality(user.location);
      if (userLocality == null) {
        _logger.warning(
          'User $userId has no location set',
          tag: _logName,
        );
        return false;
      }

      // Check based on expertise level
      switch (expertiseLevel) {
        case ExpertiseLevel.local:
          // Local experts can only host in their own locality
          return _isSameLocality(userLocality, locality);

        case ExpertiseLevel.city:
          // City experts can host in all localities in their city
          return _isInSameCity(userLocality, locality);

        case ExpertiseLevel.regional:
          // Regional (State) experts can host in all localities in their state
          return _isInSameState(userLocality, locality);

        case ExpertiseLevel.national:
          // National experts can host in all localities in their nation
          return _isInSameNation(userLocality, locality);

        case ExpertiseLevel.global:
        case ExpertiseLevel.universal:
          // Global/Universal experts can host anywhere
          return true;
      }
    } catch (e) {
      _logger.error(
        'Error checking locality hosting permission',
        error: e,
        tag: _logName,
      );
      return false;
    }
  }

  /// Check if user can host events in a specific city
  /// 
  /// **Rules:**
  /// - Local experts: Cannot host in other cities (only their locality)
  /// - City experts: Can host in their own city
  /// - State experts: Can host in all cities in their state
  /// - National experts: Can host in all cities in their nation
  /// - Global/Universal experts: Can host anywhere
  /// 
  /// **Parameters:**
  /// - `userId`: User ID (for logging)
  /// - `user`: UnifiedUser to check expertise and location
  /// - `category`: Expertise category to check
  /// - `city`: Target city to host in
  /// 
  /// **Returns:**
  /// `true` if user can host in the city, `false` otherwise
  bool canHostInCity({
    required String userId,
    required UnifiedUser user,
    required String category,
    required String city,
  }) {
    try {
      _logger.info(
        'Checking if user $userId can host in city: $city',
        tag: _logName,
      );

      final expertiseLevel = user.getExpertiseLevel(category);
      if (expertiseLevel == null) {
        return false;
      }

      final userLocation = user.location;
      if (userLocation == null) {
        return false;
      }

      final userCity = _extractCity(userLocation);

      // Check based on expertise level
      switch (expertiseLevel) {
        case ExpertiseLevel.local:
          // Local experts cannot host in other cities
          return userCity != null && _isSameCity(userCity, city);

        case ExpertiseLevel.city:
          // City experts can host in their own city
          return userCity != null && _isSameCity(userCity, city);

        case ExpertiseLevel.regional:
          // Regional (State) experts can host in all cities in their state
          return _isInSameState(userCity ?? '', city);

        case ExpertiseLevel.national:
          // National experts can host in all cities in their nation
          return _isInSameNation(userCity ?? '', city);

        case ExpertiseLevel.global:
        case ExpertiseLevel.universal:
          // Global/Universal experts can host anywhere
          return true;
      }
    } catch (e) {
      _logger.error(
        'Error checking city hosting permission',
        error: e,
        tag: _logName,
      );
      return false;
    }
  }

  /// Get all localities and cities user can host in
  /// 
  /// **Returns:**
  /// Map with:
  /// - `localities`: List of localities user can host in
  /// - `cities`: List of cities user can host in
  /// 
  /// **Note:** For local experts, returns only their locality.
  /// For city experts, returns all localities in their city.
  Map<String, List<String>> getHostingScope({
    required UnifiedUser user,
    required String category,
  }) {
    try {
      final expertiseLevel = user.getExpertiseLevel(category);
      if (expertiseLevel == null) {
        return {'localities': [], 'cities': []};
      }

      final userLocation = user.location;
      if (userLocation == null) {
        return {'localities': [], 'cities': []};
      }

      final userLocality = _extractLocality(userLocation);
      final userCity = _extractCity(userLocation);
      final userState = _extractState(userLocation);
      final userNation = _extractNation(userLocation);

      switch (expertiseLevel) {
        case ExpertiseLevel.local:
          // Local experts: Only their locality
          return {
            'localities': userLocality != null ? [userLocality] : [],
            'cities': [],
          };

        case ExpertiseLevel.city:
          // City experts: All localities in their city
          if (userCity != null) {
            final localities = _getLocalitiesInCity(userCity);
            return {
              'localities': localities,
              'cities': [userCity],
            };
          }
          return {'localities': [], 'cities': []};

        case ExpertiseLevel.regional:
          // State experts: All localities in their state
          if (userState != null) {
            final localities = _getLocalitiesInState(userState);
            final cities = _getCitiesInState(userState);
            return {
              'localities': localities,
              'cities': cities,
            };
          }
          return {'localities': [], 'cities': []};

        case ExpertiseLevel.national:
          // National experts: All localities in their nation
          if (userNation != null) {
            final localities = _getLocalitiesInNation(userNation);
            final cities = _getCitiesInNation(userNation);
            return {
              'localities': localities,
              'cities': cities,
            };
          }
          return {'localities': [], 'cities': []};

        case ExpertiseLevel.global:
        case ExpertiseLevel.universal:
          // Global/Universal: All localities and cities
          // In production, this would query all localities/cities
          return {
            'localities': ['*'], // All localities
            'cities': ['*'], // All cities
          };
      }
    } catch (e) {
      _logger.error(
        'Error getting hosting scope',
        error: e,
        tag: _logName,
      );
      return {'localities': [], 'cities': []};
    }
  }

  /// Validate event location for user
  /// 
  /// Validates that a user can host an event at the specified location
  /// based on their expertise level and geographic scope.
  /// 
  /// **Parameters:**
  /// - `userId`: User ID
  /// - `user`: UnifiedUser to validate
  /// - `category`: Expertise category
  /// - `eventLocality`: Locality where event will be hosted
  /// 
  /// **Returns:**
  /// `true` if valid, `false` otherwise
  /// 
  /// **Throws:**
  /// `Exception` with descriptive message if validation fails
  bool validateEventLocation({
    required String userId,
    required UnifiedUser user,
    required String category,
    required String eventLocality,
  }) {
    try {
      _logger.info(
        'Validating event location for user $userId: $eventLocality',
        tag: _logName,
      );

      if (!canHostInLocality(
        userId: userId,
        user: user,
        category: category,
        locality: eventLocality,
      )) {
        final expertiseLevel = user.getExpertiseLevel(category);
        final userLocality = _extractLocality(user.location ?? '');

        String errorMessage;
        switch (expertiseLevel) {
          case ExpertiseLevel.local:
            errorMessage =
                'Local experts can only host events in their own locality. '
                'Your locality: ${userLocality ?? "unknown"}, '
                'Event locality: $eventLocality';
            break;
          case ExpertiseLevel.city:
            errorMessage =
                'City experts can only host events in their city. '
                'Event locality $eventLocality is outside your city.';
            break;
          case ExpertiseLevel.regional:
            errorMessage =
                'State experts can only host events in their state. '
                'Event locality $eventLocality is outside your state.';
            break;
          case ExpertiseLevel.national:
            errorMessage =
                'National experts can only host events in their nation. '
                'Event locality $eventLocality is outside your nation.';
            break;
          default:
            errorMessage =
                'You do not have permission to host events in $eventLocality.';
        }

        _logger.warning(
          'Event location validation failed: $errorMessage',
          tag: _logName,
        );
        throw Exception(errorMessage);
      }

      return true;
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      _logger.error(
        'Error validating event location',
        error: e,
        tag: _logName,
      );
      throw Exception('Failed to validate event location: ${e.toString()}');
    }
  }

  // Private helper methods

  /// Extract locality from location string
  /// 
  /// Location format: "Locality, City, State, Country" or "Locality, City"
  /// For large cities, locality might be a neighborhood (e.g., "Greenpoint, Brooklyn")
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;

    // Split by comma and take first part (locality)
    final parts = location.split(',').map((s) => s.trim()).toList();
    if (parts.isEmpty) return null;

    // Check if first part is a neighborhood in a large city
    if (parts.length >= 2) {
      final potentialLocality = parts[0];
      final potentialCity = parts[1];

      // If city is large and has neighborhoods, check if locality is a neighborhood
      if (_largeCityService.isLargeCity(potentialCity)) {
        if (_largeCityService.isNeighborhoodLocality(potentialLocality)) {
          return potentialLocality; // Return neighborhood as locality
        }
      }
    }

    return parts[0];
  }

  /// Extract city from location string
  String? _extractCity(String? location) {
    if (location == null || location.isEmpty) return null;
    final parts = location.split(',').map((s) => s.trim()).toList();
    if (parts.length < 2) return null;

    // For large cities, second part might be the city
    // For neighborhoods, we need to get parent city
    final potentialLocality = parts[0];
    final potentialCity = parts[1];

    // Check if locality is a neighborhood
    if (_largeCityService.isNeighborhoodLocality(potentialLocality)) {
      return _largeCityService.getParentCity(potentialLocality) ?? potentialCity;
    }

    return potentialCity;
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

  /// Check if two localities are the same
  bool _isSameLocality(String locality1, String locality2) {
    return locality1.toLowerCase() == locality2.toLowerCase();
  }

  /// Check if two cities are the same
  bool _isSameCity(String city1, String city2) {
    return city1.toLowerCase() == city2.toLowerCase();
  }

  /// Check if two localities are in the same city
  bool _isInSameCity(String locality1, String locality2) {
    // For large cities, check if both are neighborhoods in the same city
    if (_largeCityService.isNeighborhoodLocality(locality1) &&
        _largeCityService.isNeighborhoodLocality(locality2)) {
      final city1 = _largeCityService.getParentCity(locality1);
      final city2 = _largeCityService.getParentCity(locality2);
      return city1 != null &&
          city2 != null &&
          city1.toLowerCase() == city2.toLowerCase();
    }

    // For regular localities, check if they're in the same city
    // This is a simplified check - in production, would query city data
    return locality1.toLowerCase() == locality2.toLowerCase() ||
        _extractCity(locality1)?.toLowerCase() ==
            _extractCity(locality2)?.toLowerCase();
  }

  /// Check if two locations are in the same state
  bool _isInSameState(String location1, String location2) {
    final state1 = _extractState(location1);
    final state2 = _extractState(location2);
    return state1 != null &&
        state2 != null &&
        state1.toLowerCase() == state2.toLowerCase();
  }

  /// Check if two locations are in the same nation
  bool _isInSameNation(String location1, String location2) {
    final nation1 = _extractNation(location1);
    final nation2 = _extractNation(location2);
    return nation1 != null &&
        nation2 != null &&
        nation1.toLowerCase() == nation2.toLowerCase();
  }

  /// Get all localities in a city
  /// 
  /// **Flow:**
  /// 1. Check if city is a large city with neighborhoods
  /// 2. If large city, return neighborhoods from LargeCityDetectionService
  /// 3. If regular city, query localities from database (requires database integration)
  /// 
  /// **Note:** For regular cities, this requires a localities database table.
  /// Currently returns empty list for regular cities.
  List<String> _getLocalitiesInCity(String city) {
    try {
      _logger.info('Getting localities in city: $city', tag: _logName);
      
      // For large cities, return neighborhoods from LargeCityDetectionService
      if (_largeCityService.isLargeCity(city)) {
        final neighborhoods = _largeCityService.getNeighborhoods(city);
        _logger.info(
          'Found ${neighborhoods.length} neighborhoods in large city: $city',
          tag: _logName,
        );
        return neighborhoods;
      }
      
      // For regular cities, query localities from database
      // In production, this would query: SELECT name FROM localities WHERE city = $city
      _logger.warn(
        'Querying localities for regular city requires database integration. '
        'City: $city - returning empty list.',
        tag: _logName,
      );
      
      return [];
    } catch (e) {
      _logger.error('Error getting localities in city', error: e, tag: _logName);
      return [];
    }
  }

  /// Get all cities in a state
  /// 
  /// **Flow:**
  /// 1. Query database for all cities in the state
  /// 2. Return list of city names
  /// 
  /// **Note:** Requires a cities/locations database table.
  /// In production: SELECT DISTINCT city FROM localities WHERE state = $state
  List<String> _getCitiesInState(String state) {
    try {
      _logger.info('Getting cities in state: $state', tag: _logName);
      
      // In production, this would query database:
      // SELECT DISTINCT city FROM localities WHERE state = $state
      // Or from a cities table: SELECT name FROM cities WHERE state = $state
      
      _logger.warn(
        'Querying cities in state requires database integration. '
        'State: $state - returning empty list.',
        tag: _logName,
      );
      
      return [];
    } catch (e) {
      _logger.error('Error getting cities in state', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get all localities in a state
  /// 
  /// **Flow:**
  /// 1. Query database for all localities in the state
  /// 2. Return list of locality names
  /// 
  /// **Note:** Requires a localities database table.
  /// In production: SELECT name FROM localities WHERE state = $state
  List<String> _getLocalitiesInState(String state) {
    try {
      _logger.info('Getting localities in state: $state', tag: _logName);
      
      // In production, this would query database:
      // SELECT name FROM localities WHERE state = $state
      
      _logger.warn(
        'Querying localities in state requires database integration. '
        'State: $state - returning empty list.',
        tag: _logName,
      );
      
      return [];
    } catch (e) {
      _logger.error('Error getting localities in state', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get all cities in a nation
  /// 
  /// **Flow:**
  /// 1. Query database for all cities in the nation
  /// 2. Return list of city names
  /// 
  /// **Note:** Requires a cities/locations database table.
  /// In production: SELECT DISTINCT city FROM localities WHERE country = $nation
  List<String> _getCitiesInNation(String nation) {
    try {
      _logger.info('Getting cities in nation: $nation', tag: _logName);
      
      // In production, this would query database:
      // SELECT DISTINCT city FROM localities WHERE country = $nation
      // Or from a cities table: SELECT name FROM cities WHERE country = $nation
      
      _logger.warn(
        'Querying cities in nation requires database integration. '
        'Nation: $nation - returning empty list.',
        tag: _logName,
      );
      
      return [];
    } catch (e) {
      _logger.error('Error getting cities in nation', error: e, tag: _logName);
      return [];
    }
  }
  
  /// Get all localities in a nation
  /// 
  /// **Flow:**
  /// 1. Query database for all localities in the nation
  /// 2. Return list of locality names
  /// 
  /// **Note:** Requires a localities database table.
  /// In production: SELECT name FROM localities WHERE country = $nation
  List<String> _getLocalitiesInNation(String nation) {
    try {
      _logger.info('Getting localities in nation: $nation', tag: _logName);
      
      // In production, this would query database:
      // SELECT name FROM localities WHERE country = $nation
      
      _logger.warn(
        'Querying localities in nation requires database integration. '
        'Nation: $nation - returning empty list.',
        tag: _logName,
      );
      
      return [];
    } catch (e) {
      _logger.error('Error getting localities in nation', error: e, tag: _logName);
      return [];
    }
  }
}

