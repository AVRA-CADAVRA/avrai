import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/logger.dart';
import 'package:spots/core/services/expertise_event_service.dart';

/// Cross-Locality Connection Service
/// 
/// Tracks user movement patterns and identifies connected localities.
/// NOT just distance-based - based on actual user movement and connections.
/// 
/// **Philosophy:** "Doors, not badges" - Opens doors to neighboring localities
/// 
/// **Movement Patterns:**
/// - Commute patterns (regular travel between localities)
/// - Travel patterns (occasional travel)
/// - Fun/exploration patterns (visiting new localities)
/// 
/// **Connected Localities:**
/// - Not just geographic distance
/// - Based on actual user movement
/// - Transportation method tracking (car, transit, walking)
/// - Metro area detection (e.g., SF Bay Area, NYC Metro)
/// 
/// **What Doors Does This Open?**
/// - Discovery Doors: Users discover events in connected localities
/// - Exploration Doors: Users can explore neighboring localities
/// - Connection Doors: Bring likeminded individuals around the locality into the locality
class CrossLocalityConnectionService {
  static const String _logName = 'CrossLocalityConnectionService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  final ExpertiseEventService _eventService;

  CrossLocalityConnectionService({
    ExpertiseEventService? eventService,
  }) : _eventService = eventService ?? ExpertiseEventService();

  /// Get connected localities for a user and locality
  /// 
  /// **Parameters:**
  /// - `user`: User to find connected localities for
  /// - `locality`: Target locality
  /// 
  /// **Returns:**
  /// List of connected localities, sorted by connection strength
  /// 
  /// **Connection Strength Factors:**
  /// - User movement patterns (commute, travel, fun)
  /// - Metro area membership
  /// - Transportation methods
  /// - Frequency of travel
  Future<List<ConnectedLocality>> getConnectedLocalities({
    required UnifiedUser user,
    required String locality,
  }) async {
    try {
      _logger.info(
        'Getting connected localities: user=${user.id}, locality=$locality',
        tag: _logName,
      );

      // Get user movement patterns
      final movementPatterns = await getUserMovementPatterns(user: user);

      // Get all localities user has visited
      final visitedLocalities = _extractVisitedLocalities(movementPatterns);

      // Calculate connection strength for each visited locality
      final connections = <ConnectedLocality>[];

      for (final visitedLocality in visitedLocalities) {
        if (visitedLocality.toLowerCase() == locality.toLowerCase()) {
          continue; // Skip the target locality itself
        }

        // Calculate connection strength
        final strength = await _calculateConnectionStrength(
          user: user,
          fromLocality: locality,
          toLocality: visitedLocality,
          movementPatterns: movementPatterns,
        );

        if (strength > 0.0) {
          connections.add(ConnectedLocality(
            locality: visitedLocality,
            connectionStrength: strength,
            movementPattern: _getPatternForLocality(
              visitedLocality,
              movementPatterns,
            ),
            transportationMethod: _getTransportationMethod(
              visitedLocality,
              movementPatterns,
            ),
          ));
        }
      }

      // Check metro area connections
      final metroConnections = await _getMetroAreaConnections(
        user: user,
        locality: locality,
      );
      connections.addAll(metroConnections);

      // Sort by connection strength (highest first)
      connections.sort((a, b) => b.connectionStrength.compareTo(a.connectionStrength));

      return connections;
    } catch (e) {
      _logger.error('Error getting connected localities', error: e, tag: _logName);
      return [];
    }
  }

  /// Get user movement patterns
  /// 
  /// **Returns:**
  /// UserMovementPatterns object with commute, travel, and fun patterns
  Future<UserMovementPatterns> getUserMovementPatterns({
    required UnifiedUser user,
  }) async {
    try {
      // Get events user has attended (proxy for movement)
      final attendedEvents = await _eventService.getEventsByAttendee(user);

      // Extract localities from events
      final localities = <String>{};
      final localityVisits = <String, List<DateTime>>{};
      final localityTransportation = <String, TransportationMethod>{};

      for (final event in attendedEvents) {
        final eventLocality = _extractLocality(event.location);
        if (eventLocality != null) {
          localities.add(eventLocality);
          localityVisits.putIfAbsent(eventLocality, () => []).add(event.startTime);
          // Placeholder: In production, get transportation method from event metadata
          localityTransportation[eventLocality] = TransportationMethod.transit;
        }
      }

      // Categorize patterns
      final commutePatterns = <String>[];
      final travelPatterns = <String>[];
      final funPatterns = <String>[];

      for (final locality in localities) {
        final visits = localityVisits[locality] ?? [];
        final visitCount = visits.length;
        final frequency = _calculateFrequency(visits);

        // Commute: Regular visits (2+ times per week)
        if (frequency >= 2.0 && visitCount >= 4) {
          commutePatterns.add(locality);
        }
        // Travel: Occasional visits (1-2 times per month)
        else if (frequency >= 0.25 && visitCount >= 2) {
          travelPatterns.add(locality);
        }
        // Fun/Exploration: Infrequent visits (less than monthly)
        else {
          funPatterns.add(locality);
        }
      }

      return UserMovementPatterns(
        commutePatterns: commutePatterns,
        travelPatterns: travelPatterns,
        funPatterns: funPatterns,
        localityVisits: localityVisits,
        transportationMethods: localityTransportation,
      );
    } catch (e) {
      _logger.error('Error getting user movement patterns', error: e, tag: _logName);
      return UserMovementPatterns.empty();
    }
  }

  /// Check if two localities are in the same metro area
  /// 
  /// **Parameters:**
  /// - `locality1`: First locality
  /// - `locality2`: Second locality
  /// 
  /// **Returns:**
  /// `true` if both localities are in the same metro area
  /// 
  /// **Metro Areas:**
  /// - SF Bay Area: San Francisco, Oakland, San Jose, etc.
  /// - NYC Metro: Manhattan, Brooklyn, Queens, Bronx, Staten Island, etc.
  /// - LA Metro: Los Angeles, Long Beach, Pasadena, etc.
  /// - And more...
  Future<bool> isInSameMetroArea({
    required String locality1,
    required String locality2,
  }) async {
    try {
      // Get metro area for each locality
      final metro1 = _getMetroArea(locality1);
      final metro2 = _getMetroArea(locality2);

      // Same metro area if both have same metro area name
      return metro1 != null &&
          metro2 != null &&
          metro1.toLowerCase() == metro2.toLowerCase();
    } catch (e) {
      _logger.error('Error checking metro area', error: e, tag: _logName);
      return false;
    }
  }

  // Private helper methods

  /// Extract visited localities from movement patterns
  Set<String> _extractVisitedLocalities(UserMovementPatterns patterns) {
    final localities = <String>{};
    localities.addAll(patterns.commutePatterns);
    localities.addAll(patterns.travelPatterns);
    localities.addAll(patterns.funPatterns);
    return localities;
  }

  /// Calculate connection strength between two localities
  Future<double> _calculateConnectionStrength({
    required UnifiedUser user,
    required String fromLocality,
    required String toLocality,
    required UserMovementPatterns movementPatterns,
  }) async {
    double strength = 0.0;

    // Commute pattern: Strong connection (0.9)
    if (movementPatterns.commutePatterns.contains(toLocality)) {
      strength = 0.9;
    }
    // Travel pattern: Medium connection (0.7)
    else if (movementPatterns.travelPatterns.contains(toLocality)) {
      strength = 0.7;
    }
    // Fun/Exploration pattern: Weak connection (0.5)
    else if (movementPatterns.funPatterns.contains(toLocality)) {
      strength = 0.5;
    }

    // Metro area boost: +0.2 if in same metro area
    final inSameMetro = await isInSameMetroArea(
      locality1: fromLocality,
      locality2: toLocality,
    );
    if (inSameMetro) {
      strength += 0.2;
    }

    // Transportation method boost
    final transportation = movementPatterns.transportationMethods[toLocality];
    if (transportation == TransportationMethod.transit ||
        transportation == TransportationMethod.walking) {
      strength += 0.1; // Transit/walking = easier connection
    }

    return strength.clamp(0.0, 1.0);
  }

  /// Get movement pattern type for a locality
  MovementPatternType _getPatternForLocality(
    String locality,
    UserMovementPatterns patterns,
  ) {
    if (patterns.commutePatterns.contains(locality)) {
      return MovementPatternType.commute;
    } else if (patterns.travelPatterns.contains(locality)) {
      return MovementPatternType.travel;
    } else {
      return MovementPatternType.fun;
    }
  }

  /// Get transportation method for a locality
  TransportationMethod _getTransportationMethod(
    String locality,
    UserMovementPatterns patterns,
  ) {
    return patterns.transportationMethods[locality] ?? TransportationMethod.unknown;
  }

  /// Get metro area connections
  Future<List<ConnectedLocality>> _getMetroAreaConnections({
    required UnifiedUser user,
    required String locality,
  }) async {
    final connections = <ConnectedLocality>[];
    final metroArea = _getMetroArea(locality);

    if (metroArea == null) {
      return connections; // No metro area for this locality
    }

    // Get all localities in the same metro area
    final metroLocalities = _getLocalitiesInMetroArea(metroArea);

    for (final metroLocality in metroLocalities) {
      if (metroLocality.toLowerCase() == locality.toLowerCase()) {
        continue; // Skip the target locality itself
      }

      connections.add(ConnectedLocality(
        locality: metroLocality,
        connectionStrength: 0.6, // Metro area connection strength
        movementPattern: MovementPatternType.travel,
        transportationMethod: TransportationMethod.transit,
      ));
    }

    return connections;
  }

  /// Get metro area for a locality
  /// 
  /// **Note:** In production, this would query a metro area database
  /// For now, uses hardcoded metro area definitions
  String? _getMetroArea(String locality) {
    final localityLower = locality.toLowerCase();

    // SF Bay Area
    if (_isInSFBayArea(localityLower)) {
      return 'SF Bay Area';
    }

    // NYC Metro
    if (_isInNYCMetro(localityLower)) {
      return 'NYC Metro';
    }

    // LA Metro
    if (_isInLAMetro(localityLower)) {
      return 'LA Metro';
    }

    // Add more metro areas as needed
    return null;
  }

  /// Check if locality is in SF Bay Area
  bool _isInSFBayArea(String locality) {
    final sfBayLocalities = [
      'san francisco',
      'oakland',
      'san jose',
      'berkeley',
      'palo alto',
      'mountain view',
      'sunnyvale',
      'fremont',
      'hayward',
      'santa clara',
      'redwood city',
      'san mateo',
      'daly city',
      'south san francisco',
    ];
    return sfBayLocalities.any((l) => locality.contains(l));
  }

  /// Check if locality is in NYC Metro
  bool _isInNYCMetro(String locality) {
    final nycLocalities = [
      'manhattan',
      'brooklyn',
      'queens',
      'bronx',
      'staten island',
      'long island',
      'westchester',
      'jersey city',
      'newark',
      'yonkers',
    ];
    return nycLocalities.any((l) => locality.contains(l));
  }

  /// Check if locality is in LA Metro
  bool _isInLAMetro(String locality) {
    final laLocalities = [
      'los angeles',
      'long beach',
      'pasadena',
      'santa monica',
      'beverly hills',
      'glendale',
      'burbank',
      'torrance',
      'inglewood',
    ];
    return laLocalities.any((l) => locality.contains(l));
  }

  /// Get all localities in a metro area
  /// 
  /// **Note:** In production, this would query a metro area database
  List<String> _getLocalitiesInMetroArea(String metroArea) {
    switch (metroArea.toLowerCase()) {
      case 'sf bay area':
        return [
          'San Francisco',
          'Oakland',
          'San Jose',
          'Berkeley',
          'Palo Alto',
          'Mountain View',
        ];
      case 'nyc metro':
        return [
          'Manhattan',
          'Brooklyn',
          'Queens',
          'Bronx',
          'Staten Island',
        ];
      case 'la metro':
        return [
          'Los Angeles',
          'Long Beach',
          'Pasadena',
          'Santa Monica',
        ];
      default:
        return [];
    }
  }

  /// Extract locality from location string
  /// Location format: "Locality, City, State, Country" or "Locality, City"
  String? _extractLocality(String? location) {
    if (location == null || location.isEmpty) return null;
    return location.split(',').first.trim();
  }

  /// Calculate visit frequency (visits per week)
  double _calculateFrequency(List<DateTime> visits) {
    if (visits.isEmpty) return 0.0;

    // Sort by date
    final sortedVisits = List<DateTime>.from(visits)..sort();

    // Calculate time span
    final firstVisit = sortedVisits.first;
    final lastVisit = sortedVisits.last;
    final daysDiff = lastVisit.difference(firstVisit).inDays;

    if (daysDiff == 0) return visits.length.toDouble();

    // Calculate visits per week
    return (visits.length / daysDiff) * 7.0;
  }
}

/// Connected Locality Model
class ConnectedLocality {
  final String locality;
  final double connectionStrength; // 0.0 to 1.0
  final MovementPatternType movementPattern;
  final TransportationMethod transportationMethod;

  const ConnectedLocality({
    required this.locality,
    required this.connectionStrength,
    required this.movementPattern,
    required this.transportationMethod,
  });
}

/// User Movement Patterns Model
class UserMovementPatterns {
  final List<String> commutePatterns; // Regular travel (2+ times per week)
  final List<String> travelPatterns; // Occasional travel (1-2 times per month)
  final List<String> funPatterns; // Exploration (less than monthly)
  final Map<String, List<DateTime>> localityVisits;
  final Map<String, TransportationMethod> transportationMethods;

  const UserMovementPatterns({
    required this.commutePatterns,
    required this.travelPatterns,
    required this.funPatterns,
    required this.localityVisits,
    required this.transportationMethods,
  });

  factory UserMovementPatterns.empty() {
    return const UserMovementPatterns(
      commutePatterns: [],
      travelPatterns: [],
      funPatterns: [],
      localityVisits: {},
      transportationMethods: {},
    );
  }
}

/// Movement Pattern Type
enum MovementPatternType {
  commute, // Regular travel between localities
  travel, // Occasional travel
  fun, // Fun/exploration patterns
}

/// Transportation Method
enum TransportationMethod {
  car,
  transit, // Bus, subway, train
  walking,
  bike,
  boat,
  unknown,
}

