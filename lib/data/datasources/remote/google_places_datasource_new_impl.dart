import 'dart:developer' as developer;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:spots/data/datasources/remote/google_places_datasource.dart';
import 'package:spots/core/services/google_places_cache_service.dart';
import 'package:spots_core/spots_core.dart' hide Spot;
import 'package:spots/core/models/spot.dart' show Spot;

/// Google Places API (New) Implementation
/// Migrated to new Places API with field masking and POST requests
/// OUR_GUTS.md: "Authenticity Over Algorithms" - External data enriches community knowledge
class GooglePlacesDataSourceNewImpl implements GooglePlacesDataSource {
  static const String _logName = 'GooglePlacesDataSourceNew';
  static const String _baseUrl = 'https://places.googleapis.com/v1';
  
  final http.Client _httpClient;
  final String _apiKey;
  final GooglePlacesCacheService? _cacheService;
  
  // Rate limiting and caching
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _lastRequest = {};
  static const Duration _cacheExpiry = Duration(hours: 1);
  static const Duration _rateLimitDelay = Duration(milliseconds: 100);
  
  GooglePlacesDataSourceNewImpl({
    required String apiKey,
    http.Client? httpClient,
    GooglePlacesCacheService? cacheService,
  }) : _apiKey = apiKey,
       _httpClient = httpClient ?? http.Client(),
       _cacheService = cacheService;

  @override
  Future<List<Spot>> searchPlaces({
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
    String? type,
  }) async {
    try {
      developer.log('Searching places (New API): $query', name: _logName);
      
      // Check cache first for performance
      final cacheKey = 'search_${query}_${latitude}_${longitude}_${radius}_$type';
      if (_isCacheValid(cacheKey)) {
        developer.log('Returning cached results for: $query', name: _logName);
        return List<Spot>.from(_cache[cacheKey]);
      }
      
      // Rate limiting
      await _enforceRateLimit();
      
      // Build request body
      final requestBody = _buildSearchTextRequest(
        query: query,
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        type: type,
      );
      
      // Build URL and headers
      final url = Uri.parse('$_baseUrl/places:searchText');
      final headers = _buildHeaders(includeDetails: false);
      
      // Make POST request
      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final spots = _parseSearchResults(data);
        
        // Cache results in memory
        _cache[cacheKey] = spots;
        _lastRequest[cacheKey] = DateTime.now();
        
        // Cache in local database for offline use
        if (_cacheService != null) {
          await _cacheService!.cachePlaces(spots);
        }
        
        developer.log('Found ${spots.length} places for: $query', name: _logName);
        return List<Spot>.from(spots);
      } else {
        final errorData = json.decode(response.body);
        throw GooglePlacesException('Search failed: ${response.statusCode} - ${errorData['error']?.toString() ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('Error searching places: $e', name: _logName);
      // OUR_GUTS.md: "Effortless, Seamless Discovery" - Graceful fallback
      return [];
    }
  }

  @override
  Future<Spot?> getPlaceDetails(String placeId) async {
    try {
      developer.log('Getting place details (New API): $placeId', name: _logName);
      
      // Normalize place ID format (handle both "places/ChIJ..." and "ChIJ...")
      final normalizedPlaceId = placeId.startsWith('places/') 
          ? placeId 
          : 'places/$placeId';
      
      // Check cache first
      final cacheKey = 'details_$normalizedPlaceId';
      if (_isCacheValid(cacheKey)) {
        return _cache[cacheKey] as Spot?;
      }
      
      // Rate limiting
      await _enforceRateLimit();
      
      // Build URL and headers
      final url = Uri.parse('$_baseUrl/$normalizedPlaceId');
      final headers = _buildHeaders(includeDetails: true);
      
      // Make GET request (details endpoint uses GET)
      final response = await _httpClient.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final spot = _parsePlaceDetails(data);
        
        // Cache result in memory
        _cache[cacheKey] = spot;
        _lastRequest[cacheKey] = DateTime.now();
        
        // Cache in local database for offline use
        if (_cacheService != null && spot != null) {
          await _cacheService!.cachePlace(spot);
        }
        
        return spot;
      } else {
        final errorData = json.decode(response.body);
        throw GooglePlacesException('Place details failed: ${response.statusCode} - ${errorData['error']?.toString() ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('Error getting place details: $e', name: _logName);
      return null;
    }
  }

  @override
  Future<List<Spot>> searchNearbyPlaces({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
  }) async {
    try {
      developer.log('Searching nearby places (New API): $latitude,$longitude', name: _logName);
      
      // Check cache first
      final cacheKey = 'nearby_${latitude}_${longitude}_${radius}_$type';
      if (_isCacheValid(cacheKey)) {
        return List<Spot>.from(_cache[cacheKey]);
      }
      
      // Rate limiting
      await _enforceRateLimit();
      
      // Build request body
      final requestBody = _buildSearchNearbyRequest(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        type: type,
      );
      
      // Build URL and headers
      final url = Uri.parse('$_baseUrl/places:searchNearby');
      final headers = _buildHeaders(includeDetails: false);
      
      // Make POST request
      final response = await _httpClient.post(
        url,
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final spots = _parseSearchResults(data);
        
        // Cache results in memory
        _cache[cacheKey] = spots;
        _lastRequest[cacheKey] = DateTime.now();
        
        // Cache in local database for offline use
        if (_cacheService != null) {
          await _cacheService!.cachePlaces(spots);
        }
        
        developer.log('Found ${spots.length} nearby places', name: _logName);
        return spots;
      } else {
        final errorData = json.decode(response.body);
        throw GooglePlacesException('Nearby search failed: ${response.statusCode} - ${errorData['error']?.toString() ?? 'Unknown error'}');
      }
    } catch (e) {
      developer.log('Error searching nearby places: $e', name: _logName);
      return [];
    }
  }

  // Helper methods

  /// Build headers with API key and field masking
  Map<String, String> _buildHeaders({bool includeDetails = false}) {
    return {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': _apiKey,
      'X-Goog-FieldMask': _getFieldMask(includeDetails: includeDetails),
    };
  }

  /// Get field mask for cost optimization
  /// Only request fields we actually use
  String _getFieldMask({bool includeDetails = false}) {
    final baseFields = [
      'places.id',
      'places.displayName',
      'places.location',
      'places.rating',
      'places.formattedAddress',
      'places.types',
      'places.priceLevel',
    ];
    
    if (includeDetails) {
      baseFields.addAll([
        'places.nationalPhoneNumber',
        'places.websiteUri',
        'places.regularOpeningHours',
        'places.photos',
        'places.userRatingCount',
      ]);
    }
    
    return baseFields.join(',');
  }

  /// Build search text request body
  Map<String, dynamic> _buildSearchTextRequest({
    required String query,
    double? latitude,
    double? longitude,
    int radius = 5000,
    String? type,
  }) {
    final request = <String, dynamic>{
      'textQuery': query,
      'maxResultCount': 20,
    };
    
    // Add location bias if provided
    if (latitude != null && longitude != null) {
      request['locationBias'] = {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radius.toDouble(),
        },
      };
    }
    
    // Add type filter if provided
    if (type != null) {
      request['includedType'] = _mapTypeToNewApiType(type);
    }
    
    return request;
  }

  /// Build search nearby request body
  Map<String, dynamic> _buildSearchNearbyRequest({
    required double latitude,
    required double longitude,
    int radius = 5000,
    String? type,
  }) {
    final request = <String, dynamic>{
      'maxResultCount': 20,
      'locationRestriction': {
        'circle': {
          'center': {
            'latitude': latitude,
            'longitude': longitude,
          },
          'radius': radius.toDouble(),
        },
      },
    };
    
    // Add type filter if provided
    if (type != null) {
      request['includedTypes'] = [_mapTypeToNewApiType(type)];
    }
    
    return request;
  }

  /// Map legacy type to new API type format
  String _mapTypeToNewApiType(String type) {
    // New API uses different type format
    // Map common types
    switch (type.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return 'restaurant';
      case 'cafe':
      case 'coffee':
        return 'cafe';
      case 'bar':
      case 'night_club':
        return 'bar';
      case 'park':
        return 'park';
      case 'museum':
        return 'museum';
      case 'shopping_mall':
      case 'store':
        return 'store';
      case 'lodging':
        return 'lodging';
      default:
        return type;
    }
  }

  /// Parse search results from new API format
  List<Spot> _parseSearchResults(Map<String, dynamic> data) {
    final places = data['places'] as List<dynamic>? ?? [];
    return places.map((place) => _createSpotFromNewPlace(place)).toList();
  }

  /// Parse place details from new API format
  Spot? _parsePlaceDetails(Map<String, dynamic>? data) {
    if (data == null) return null;
    return _createSpotFromNewPlace(data, isDetailed: true);
  }

  /// Create Spot from new API place format
  Spot _createSpotFromNewPlace(Map<String, dynamic> place, {bool isDetailed = false}) {
    // Extract display name
    final displayName = place['displayName'] as Map<String, dynamic>?;
    final name = displayName?['text'] as String? ?? 'Unknown Place';
    
    // Extract location
    final location = place['location'] as Map<String, dynamic>?;
    final latitude = location?['latitude']?.toDouble() ?? 0.0;
    final longitude = location?['longitude']?.toDouble() ?? 0.0;
    
    // Extract place ID (format: "places/ChIJ..." or just "ChIJ...")
    final placeId = place['id'] as String? ?? '';
    final cleanPlaceId = placeId.replaceFirst('places/', '');
    
    // Extract types
    final types = place['types'] as List<dynamic>? ?? [];
    
    // Extract rating
    final rating = place['rating']?.toDouble() ?? 0.0;
    
    // Extract formatted address
    final formattedAddress = place['formattedAddress'] as String? ?? '';
    
    // Extract price level (map Google API to SPOTS enum)
    PriceLevel? priceLevel;
    final priceLevelStr = place['priceLevel'] as String?;
    if (priceLevelStr != null) {
      switch (priceLevelStr) {
        case 'PRICE_LEVEL_FREE':
          priceLevel = PriceLevel.free;
          break;
        case 'PRICE_LEVEL_INEXPENSIVE':
          priceLevel = PriceLevel.low; // Map inexpensive to low
          break;
        case 'PRICE_LEVEL_MODERATE':
          priceLevel = PriceLevel.moderate;
          break;
        case 'PRICE_LEVEL_EXPENSIVE':
          priceLevel = PriceLevel.high; // Map expensive to high
          break;
        case 'PRICE_LEVEL_VERY_EXPENSIVE':
          priceLevel = PriceLevel.luxury; // Map very expensive to luxury
          break;
      }
    }
    
    // OUR_GUTS.md: "Privacy and Control Are Non-Negotiable" - Clear external data marking
    final now = DateTime.now();
    final spot = Spot(
      id: 'google_$cleanPlaceId',
      name: name,
      description: formattedAddress,
      latitude: latitude,
      longitude: longitude,
      category: _mapNewApiTypesToCategory(types),
      rating: rating,
      createdBy: 'google_places_api',
      createdAt: now,
      updatedAt: now,
      address: formattedAddress,
      tags: [
        'external_data',
        'google_places',
        ...types.map((type) => type.toString()),
      ],
      metadata: {
        'source': 'google_places',
        'place_id': cleanPlaceId,
        'place_id_full': placeId,
        'is_external': true,
        'api_version': 'new',
        if (priceLevel != null) 'price_level': priceLevel.toString(),
        if (isDetailed) ...{
          'phone': place['nationalPhoneNumber'],
          'website': place['websiteUri'],
          'opening_hours': place['regularOpeningHours'],
          'user_rating_count': place['userRatingCount'],
          'photos': place['photos'],
        }
      },
      googlePlaceId: cleanPlaceId,
      googlePlaceIdSyncedAt: now,
    );
    
    return spot;
  }

  /// Map new API types to SPOTS category
  String _mapNewApiTypesToCategory(List<dynamic> types) {
    // OUR_GUTS.md: "Authenticity Over Algorithms" - Maintain consistent categorization
    for (final type in types) {
      final typeStr = type.toString().toLowerCase();
      switch (typeStr) {
        case 'restaurant':
        case 'meal_takeaway':
        case 'food':
        case 'cafe':
          return 'Food';
        case 'tourist_attraction':
        case 'museum':
        case 'park':
          return 'Attractions';
        case 'shopping_mall':
        case 'store':
        case 'clothing_store':
          return 'Shopping';
        case 'night_club':
        case 'bar':
          return 'Nightlife';
        case 'lodging':
        case 'hotel':
          return 'Stay';
        default:
          continue;
      }
    }
    return 'Other';
  }

  bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_lastRequest.containsKey(key)) {
      return false;
    }
    
    final lastRequest = _lastRequest[key]!;
    return DateTime.now().difference(lastRequest) < _cacheExpiry;
  }

  Future<void> _enforceRateLimit() async {
    final now = DateTime.now();
    final lastRequestTime = _lastRequest['rate_limit'];
    
    if (lastRequestTime != null) {
      final timeSinceLastRequest = now.difference(lastRequestTime);
      if (timeSinceLastRequest < _rateLimitDelay) {
        final delay = _rateLimitDelay - timeSinceLastRequest;
        await Future.delayed(delay);
      }
    }
    
    _lastRequest['rate_limit'] = DateTime.now();
  }
}

class GooglePlacesException implements Exception {
  final String message;
  GooglePlacesException(this.message);
  
  @override
  String toString() => 'GooglePlacesException: $message';
}

