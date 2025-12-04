import 'package:equatable/equatable.dart';

/// Geographic Expansion Model
/// 
/// Tracks geographic expansion of clubs/communities from original locality.
/// 
/// **Philosophy Alignment:**
/// - Clubs/communities can expand naturally (doors open through growth)
/// - 75% coverage rule enables expertise gain at each geographic level
/// - Geographic expansion enabled (locality → universe)
/// 
/// **Key Features:**
/// - Tracks expansion from original locality
/// - Coverage percentages by geographic level (locality, city, state, nation, global)
/// - Tracks coverage methods (commute patterns, event hosting locations)
/// - Expansion timeline (expansion history, first/last expansion timestamps)
/// 
/// **Usage:**
/// ```dart
/// final expansion = GeographicExpansion(
///   id: 'expansion-123',
///   clubId: 'club-456',
///   originalLocality: 'Austin, TX',
///   expandedLocalities: ['Austin, TX', 'Round Rock, TX'],
///   expandedCities: ['Austin'],
///   expandedStates: ['Texas'],
///   expandedNations: ['United States'],
///   localityCoverage: {'Austin, TX': 1.0, 'Round Rock, TX': 0.5},
///   cityCoverage: {'Austin': 0.75},
///   stateCoverage: {'Texas': 0.25},
///   nationCoverage: {'United States': 0.1},
///   commutePatterns: {
///     'Austin, TX': ['Round Rock, TX', 'Cedar Park, TX'],
///   },
///   eventHostingLocations: {
///     'Austin, TX': ['event-1', 'event-2'],
///     'Round Rock, TX': ['event-3'],
///   },
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
/// );
/// ```

/// Expansion Event
/// Represents a single expansion event (when, where, how)
class ExpansionEvent extends Equatable {
  /// When expansion occurred
  final DateTime timestamp;
  
  /// Where expansion occurred (locality, city, state, nation)
  final String location;
  
  /// Geographic level of expansion (locality, city, state, nation, global)
  final String geographicLevel;
  
  /// How expansion occurred (event_hosting, commute_pattern, both)
  final String expansionMethod;
  
  /// Event ID that triggered expansion (if applicable)
  final String? eventId;
  
  /// Coverage percentage at time of expansion
  final double coveragePercentage;

  const ExpansionEvent({
    required this.timestamp,
    required this.location,
    required this.geographicLevel,
    required this.expansionMethod,
    this.eventId,
    required this.coveragePercentage,
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'geographicLevel': geographicLevel,
      'expansionMethod': expansionMethod,
      'eventId': eventId,
      'coveragePercentage': coveragePercentage,
    };
  }

  /// Create from JSON
  factory ExpansionEvent.fromJson(Map<String, dynamic> json) {
    return ExpansionEvent(
      timestamp: DateTime.parse(json['timestamp'] as String),
      location: json['location'] as String,
      geographicLevel: json['geographicLevel'] as String,
      expansionMethod: json['expansionMethod'] as String,
      eventId: json['eventId'] as String?,
      coveragePercentage: (json['coveragePercentage'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [
        timestamp,
        location,
        geographicLevel,
        expansionMethod,
        eventId,
        coveragePercentage,
      ];
}

class GeographicExpansion extends Equatable {
  /// Unique expansion identifier
  final String id;
  
  /// Club or Community ID
  final String clubId;
  
  /// Whether this is for a club (true) or community (false)
  final bool isClub;
  
  /// Original locality where club/community started
  final String originalLocality;
  
  /// Expanded localities (list of localities where club/community is active)
  final List<String> expandedLocalities;
  
  /// Expanded cities (list of cities where club/community is active)
  final List<String> expandedCities;
  
  /// Expanded states (list of states where club/community is active)
  final List<String> expandedStates;
  
  /// Expanded nations (list of nations where club/community is active)
  final List<String> expandedNations;
  
  /// Coverage percentages by geographic level
  /// Map of locality → coverage percentage (0.0 to 1.0)
  final Map<String, double> localityCoverage;
  
  /// Map of city → coverage percentage (0.0 to 1.0)
  final Map<String, double> cityCoverage;
  
  /// Map of state → coverage percentage (0.0 to 1.0)
  final Map<String, double> stateCoverage;
  
  /// Map of nation → coverage percentage (0.0 to 1.0)
  final Map<String, double> nationCoverage;
  
  /// Coverage methods
  /// Map of locality → list of source localities (people commuting to events)
  final Map<String, List<String>> commutePatterns;
  
  /// Map of locality → list of event IDs (events hosted in each locality)
  final Map<String, List<String>> eventHostingLocations;
  
  /// Expansion timeline
  /// List of expansion events (when, where, how)
  final List<ExpansionEvent> expansionHistory;
  
  /// When first expansion occurred
  final DateTime? firstExpansionAt;
  
  /// When last expansion occurred
  final DateTime? lastExpansionAt;
  
  /// Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const GeographicExpansion({
    required this.id,
    required this.clubId,
    this.isClub = true,
    required this.originalLocality,
    this.expandedLocalities = const [],
    this.expandedCities = const [],
    this.expandedStates = const [],
    this.expandedNations = const [],
    this.localityCoverage = const {},
    this.cityCoverage = const {},
    this.stateCoverage = const {},
    this.nationCoverage = const {},
    this.commutePatterns = const {},
    this.eventHostingLocations = const {},
    this.expansionHistory = const [],
    this.firstExpansionAt,
    this.lastExpansionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if expansion has reached locality threshold (any locality with >0 coverage)
  bool hasReachedLocalityThreshold() {
    return expandedLocalities.isNotEmpty;
  }

  /// Check if expansion has reached city threshold (75% city coverage)
  bool hasReachedCityThreshold(String city) {
    final coverage = cityCoverage[city] ?? 0.0;
    return coverage >= 0.75;
  }

  /// Check if expansion has reached state threshold (75% state coverage)
  bool hasReachedStateThreshold(String state) {
    final coverage = stateCoverage[state] ?? 0.0;
    return coverage >= 0.75;
  }

  /// Check if expansion has reached nation threshold (75% nation coverage)
  bool hasReachedNationThreshold(String nation) {
    final coverage = nationCoverage[nation] ?? 0.0;
    return coverage >= 0.75;
  }

  /// Check if expansion has reached global threshold (75% global coverage)
  /// Global coverage is calculated as coverage across all nations
  bool hasReachedGlobalThreshold() {
    if (nationCoverage.isEmpty) return false;
    
    // Calculate average nation coverage
    final totalCoverage = nationCoverage.values.fold(0.0, (sum, coverage) => sum + coverage);
    final averageCoverage = totalCoverage / nationCoverage.length;
    
    return averageCoverage >= 0.75;
  }

  /// Get total number of localities covered
  int get totalLocalitiesCovered => expandedLocalities.length;

  /// Get total number of cities covered
  int get totalCitiesCovered => expandedCities.length;

  /// Get total number of states covered
  int get totalStatesCovered => expandedStates.length;

  /// Get total number of nations covered
  int get totalNationsCovered => expandedNations.length;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clubId': clubId,
      'isClub': isClub,
      'originalLocality': originalLocality,
      'expandedLocalities': expandedLocalities,
      'expandedCities': expandedCities,
      'expandedStates': expandedStates,
      'expandedNations': expandedNations,
      'localityCoverage': localityCoverage,
      'cityCoverage': cityCoverage,
      'stateCoverage': stateCoverage,
      'nationCoverage': nationCoverage,
      'commutePatterns': commutePatterns,
      'eventHostingLocations': eventHostingLocations,
      'expansionHistory': expansionHistory.map((e) => e.toJson()).toList(),
      'firstExpansionAt': firstExpansionAt?.toIso8601String(),
      'lastExpansionAt': lastExpansionAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory GeographicExpansion.fromJson(Map<String, dynamic> json) {
    final localityCoverageMap = json['localityCoverage'] as Map<String, dynamic>?;
    final localityCoverage = <String, double>{};
    if (localityCoverageMap != null) {
      localityCoverageMap.forEach((key, value) {
        localityCoverage[key] = (value as num).toDouble();
      });
    }

    final cityCoverageMap = json['cityCoverage'] as Map<String, dynamic>?;
    final cityCoverage = <String, double>{};
    if (cityCoverageMap != null) {
      cityCoverageMap.forEach((key, value) {
        cityCoverage[key] = (value as num).toDouble();
      });
    }

    final stateCoverageMap = json['stateCoverage'] as Map<String, dynamic>?;
    final stateCoverage = <String, double>{};
    if (stateCoverageMap != null) {
      stateCoverageMap.forEach((key, value) {
        stateCoverage[key] = (value as num).toDouble();
      });
    }

    final nationCoverageMap = json['nationCoverage'] as Map<String, dynamic>?;
    final nationCoverage = <String, double>{};
    if (nationCoverageMap != null) {
      nationCoverageMap.forEach((key, value) {
        nationCoverage[key] = (value as num).toDouble();
      });
    }

    final commutePatternsMap = json['commutePatterns'] as Map<String, dynamic>?;
    final commutePatterns = <String, List<String>>{};
    if (commutePatternsMap != null) {
      commutePatternsMap.forEach((key, value) {
        commutePatterns[key] = List<String>.from(value as List);
      });
    }

    final eventHostingLocationsMap = json['eventHostingLocations'] as Map<String, dynamic>?;
    final eventHostingLocations = <String, List<String>>{};
    if (eventHostingLocationsMap != null) {
      eventHostingLocationsMap.forEach((key, value) {
        eventHostingLocations[key] = List<String>.from(value as List);
      });
    }

    final expansionHistoryList = json['expansionHistory'] as List<dynamic>?;
    final expansionHistory = expansionHistoryList != null
        ? expansionHistoryList
            .map((e) => ExpansionEvent.fromJson(e as Map<String, dynamic>))
            .toList()
        : <ExpansionEvent>[];

    return GeographicExpansion(
      id: json['id'] as String,
      clubId: json['clubId'] as String,
      isClub: json['isClub'] as bool? ?? true,
      originalLocality: json['originalLocality'] as String,
      expandedLocalities: List<String>.from(json['expandedLocalities'] as List? ?? []),
      expandedCities: List<String>.from(json['expandedCities'] as List? ?? []),
      expandedStates: List<String>.from(json['expandedStates'] as List? ?? []),
      expandedNations: List<String>.from(json['expandedNations'] as List? ?? []),
      localityCoverage: localityCoverage,
      cityCoverage: cityCoverage,
      stateCoverage: stateCoverage,
      nationCoverage: nationCoverage,
      commutePatterns: commutePatterns,
      eventHostingLocations: eventHostingLocations,
      expansionHistory: expansionHistory,
      firstExpansionAt: json['firstExpansionAt'] != null
          ? DateTime.parse(json['firstExpansionAt'] as String)
          : null,
      lastExpansionAt: json['lastExpansionAt'] != null
          ? DateTime.parse(json['lastExpansionAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with method
  GeographicExpansion copyWith({
    String? id,
    String? clubId,
    bool? isClub,
    String? originalLocality,
    List<String>? expandedLocalities,
    List<String>? expandedCities,
    List<String>? expandedStates,
    List<String>? expandedNations,
    Map<String, double>? localityCoverage,
    Map<String, double>? cityCoverage,
    Map<String, double>? stateCoverage,
    Map<String, double>? nationCoverage,
    Map<String, List<String>>? commutePatterns,
    Map<String, List<String>>? eventHostingLocations,
    List<ExpansionEvent>? expansionHistory,
    DateTime? firstExpansionAt,
    DateTime? lastExpansionAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GeographicExpansion(
      id: id ?? this.id,
      clubId: clubId ?? this.clubId,
      isClub: isClub ?? this.isClub,
      originalLocality: originalLocality ?? this.originalLocality,
      expandedLocalities: expandedLocalities ?? this.expandedLocalities,
      expandedCities: expandedCities ?? this.expandedCities,
      expandedStates: expandedStates ?? this.expandedStates,
      expandedNations: expandedNations ?? this.expandedNations,
      localityCoverage: localityCoverage ?? this.localityCoverage,
      cityCoverage: cityCoverage ?? this.cityCoverage,
      stateCoverage: stateCoverage ?? this.stateCoverage,
      nationCoverage: nationCoverage ?? this.nationCoverage,
      commutePatterns: commutePatterns ?? this.commutePatterns,
      eventHostingLocations: eventHostingLocations ?? this.eventHostingLocations,
      expansionHistory: expansionHistory ?? this.expansionHistory,
      firstExpansionAt: firstExpansionAt ?? this.firstExpansionAt,
      lastExpansionAt: lastExpansionAt ?? this.lastExpansionAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        clubId,
        isClub,
        originalLocality,
        expandedLocalities,
        expandedCities,
        expandedStates,
        expandedNations,
        localityCoverage,
        cityCoverage,
        stateCoverage,
        nationCoverage,
        commutePatterns,
        eventHostingLocations,
        expansionHistory,
        firstExpansionAt,
        lastExpansionAt,
        createdAt,
        updatedAt,
      ];
}

