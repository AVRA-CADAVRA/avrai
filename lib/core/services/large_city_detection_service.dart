import 'package:spots/core/services/logger.dart';

/// Large City Detection Service
/// 
/// Detects large diverse cities where neighborhoods should be treated
/// as separate localities. This preserves neighborhood identity and diversity.
/// 
/// **Large Cities:** Brooklyn, LA, Chicago, Tokyo, Seoul, Paris, Madrid, Lagos, etc.
/// 
/// **Philosophy:** Large cities have neighborhoods that are vastly different
/// in thought, atmosphere, idea, and identity. These neighborhoods should be
/// separate localities to preserve their unique character.
/// 
/// **Detection Criteria:**
/// 1. Geographic size (e.g., Houston is huge with many towns inside)
/// 2. Population size
/// 3. Well-documented neighborhoods backed by geography and population data
class LargeCityDetectionService {
  static const String _logName = 'LargeCityDetectionService';
  final AppLogger _logger = const AppLogger(
    defaultTag: 'SPOTS',
    minimumLevel: LogLevel.debug,
  );

  // Large city configuration
  // In production, this would be stored in a database or configuration service
  static const Map<String, LargeCityConfig> _largeCities = {
    // US Cities
    'brooklyn': LargeCityConfig(
      cityName: 'Brooklyn',
      neighborhoods: [
        'Greenpoint',
        'Williamsburg',
        'DUMBO',
        'Park Slope',
        'Red Hook',
        'Carroll Gardens',
        'Sunset Park',
        'Bath Beach',
        'Bushwick',
        'Bedford-Stuyvesant',
        'Crown Heights',
        'Prospect Heights',
        'Fort Greene',
        'Boerum Hill',
        'Cobble Hill',
        'Gowanus',
        'Long Island City',
      ],
      population: 2600000,
      geographicSize: 183.4, // km²
    ),
    'los angeles': LargeCityConfig(
      cityName: 'Los Angeles',
      neighborhoods: [
        'Hollywood',
        'Beverly Hills',
        'Santa Monica',
        'Venice',
        'West Hollywood',
        'Downtown LA',
        'Silver Lake',
        'Echo Park',
        'Highland Park',
        'Pasadena',
        'Glendale',
        'Burbank',
        'Culver City',
        'Manhattan Beach',
        'Redondo Beach',
      ],
      population: 3900000,
      geographicSize: 1302.0, // km²
    ),
    'chicago': LargeCityConfig(
      cityName: 'Chicago',
      neighborhoods: [
        'Loop',
        'River North',
        'Gold Coast',
        'Lincoln Park',
        'Wicker Park',
        'Bucktown',
        'Logan Square',
        'Pilsen',
        'Hyde Park',
        'South Loop',
        'West Loop',
        'Old Town',
        'Lakeview',
        'Wrigleyville',
      ],
      population: 2700000,
      geographicSize: 606.1, // km²
    ),
    'houston': LargeCityConfig(
      cityName: 'Houston',
      neighborhoods: [
        'Downtown',
        'Midtown',
        'Montrose',
        'Heights',
        'Rice Village',
        'West University',
        'Museum District',
        'Medical Center',
        'Galleria',
        'Energy Corridor',
      ],
      population: 2300000,
      geographicSize: 1703.0, // km²
    ),
    // International Cities
    'tokyo': LargeCityConfig(
      cityName: 'Tokyo',
      neighborhoods: [
        'Shibuya',
        'Shinjuku',
        'Harajuku',
        'Ginza',
        'Roppongi',
        'Akihabara',
        'Asakusa',
        'Ueno',
        'Ikebukuro',
        'Ebisu',
        'Daikanyama',
        'Nakameguro',
        'Aoyama',
        'Omotesando',
      ],
      population: 14000000,
      geographicSize: 2194.0, // km²
    ),
    'seoul': LargeCityConfig(
      cityName: 'Seoul',
      neighborhoods: [
        'Gangnam',
        'Hongdae',
        'Itaewon',
        'Myeongdong',
        'Insadong',
        'Jongno',
        'Dongdaemun',
        'Apgujeong',
        'Cheongdam',
        'Sinsa',
        'Samcheong',
        'Bukchon',
      ],
      population: 9700000,
      geographicSize: 605.2, // km²
    ),
    'paris': LargeCityConfig(
      cityName: 'Paris',
      neighborhoods: [
        'Le Marais',
        'Montmartre',
        'Saint-Germain-des-Prés',
        'Latin Quarter',
        'Champs-Élysées',
        'Bastille',
        'Belleville',
        'Canal Saint-Martin',
        'Pigalle',
        'Oberkampf',
        'République',
        'Nation',
      ],
      population: 2100000,
      geographicSize: 105.4, // km²
    ),
    'madrid': LargeCityConfig(
      cityName: 'Madrid',
      neighborhoods: [
        'Centro',
        'Malasaña',
        'Chueca',
        'Salamanca',
        'Lavapiés',
        'La Latina',
        'Retiro',
        'Chamberí',
        'Tetuán',
        'Usera',
      ],
      population: 3200000,
      geographicSize: 604.3, // km²
    ),
    'lagos': LargeCityConfig(
      cityName: 'Lagos',
      neighborhoods: [
        'Victoria Island',
        'Ikoyi',
        'Lekki',
        'Surulere',
        'Yaba',
        'Ikeja',
        'Ajah',
        'Banana Island',
        'Apapa',
        'Marina',
      ],
      population: 15000000,
      geographicSize: 1171.0, // km²
    ),
  };

  /// Check if a city is a large diverse city
  /// 
  /// **Parameters:**
  /// - `cityName`: City name to check (case-insensitive)
  /// 
  /// **Returns:**
  /// `true` if city is large and diverse, `false` otherwise
  bool isLargeCity(String cityName) {
    if (cityName.isEmpty) return false;

    final normalizedName = cityName.toLowerCase().trim();
    return _largeCities.containsKey(normalizedName);
  }

  /// Get neighborhoods for a large city
  /// 
  /// **Parameters:**
  /// - `cityName`: City name (case-insensitive)
  /// 
  /// **Returns:**
  /// List of neighborhood names, or empty list if city is not large
  List<String> getNeighborhoods(String cityName) {
    if (cityName.isEmpty) return [];

    final normalizedName = cityName.toLowerCase().trim();
    final config = _largeCities[normalizedName];
    return config?.neighborhoods ?? [];
  }

  /// Check if a locality is a neighborhood in a large city
  /// 
  /// **Parameters:**
  /// - `locality`: Locality name to check
  /// 
  /// **Returns:**
  /// `true` if locality is a neighborhood, `false` otherwise
  bool isNeighborhoodLocality(String locality) {
    if (locality.isEmpty) return false;

    // Check all large cities for this neighborhood
    for (final config in _largeCities.values) {
      if (config.neighborhoods.any(
        (neighborhood) =>
            neighborhood.toLowerCase() == locality.toLowerCase(),
      )) {
        return true;
      }
    }
    return false;
  }

  /// Get parent city for a neighborhood locality
  /// 
  /// **Parameters:**
  /// - `locality`: Neighborhood locality name
  /// 
  /// **Returns:**
  /// Parent city name, or `null` if locality is not a neighborhood
  String? getParentCity(String locality) {
    if (locality.isEmpty) return null;

    // Find which large city contains this neighborhood
    for (final entry in _largeCities.entries) {
      if (entry.value.neighborhoods.any(
        (neighborhood) =>
            neighborhood.toLowerCase() == locality.toLowerCase(),
      )) {
        return entry.value.cityName;
      }
    }
    return null;
  }

  /// Get large city configuration
  /// 
  /// **Parameters:**
  /// - `cityName`: City name (case-insensitive)
  /// 
  /// **Returns:**
  /// LargeCityConfig if city is large, `null` otherwise
  LargeCityConfig? getCityConfig(String cityName) {
    if (cityName.isEmpty) return null;
    final normalizedName = cityName.toLowerCase().trim();
    return _largeCities[normalizedName];
  }

  /// Get all large cities
  /// 
  /// **Returns:**
  /// List of all large city names
  List<String> getAllLargeCities() {
    return _largeCities.values.map((config) => config.cityName).toList();
  }
}

/// Configuration for a large city
class LargeCityConfig {
  final String cityName;
  final List<String> neighborhoods;
  final int population;
  final double geographicSize; // in km²

  const LargeCityConfig({
    required this.cityName,
    required this.neighborhoods,
    required this.population,
    required this.geographicSize,
  });

  /// Check if city meets large city criteria
  /// 
  /// Criteria:
  /// - Population > 1,000,000 OR
  /// - Geographic size > 500 km² OR
  /// - Has 10+ documented neighborhoods
  bool get meetsLargeCityCriteria {
    return population > 1000000 ||
        geographicSize > 500.0 ||
        neighborhoods.length >= 10;
  }
}

