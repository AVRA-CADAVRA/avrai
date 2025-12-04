import 'dart:async';
import 'package:spots/core/services/logger.dart';
import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'
    if (dart.library.html) 'package:spots/presentation/pages/onboarding/web_geocoding_nominatim.dart';
import 'package:latlong2/latlong.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/services/storage_service.dart';
import 'package:spots/injection_container.dart' as di;

class HomebaseSelectionPage extends StatefulWidget {
  final String? selectedHomebase;
  final Function(String) onHomebaseChanged;
  final VoidCallback? onNext;

  const HomebaseSelectionPage({
    super.key,
    this.selectedHomebase,
    required this.onHomebaseChanged,
    this.onNext,
  });

  @override
  State<HomebaseSelectionPage> createState() => _HomebaseSelectionPageState();
}

class _HomebaseSelectionPageState extends State<HomebaseSelectionPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  String? _selectedNeighborhood;
  bool _isLoadingLocation = false;
  bool _hasLocationPermission = false;
  bool _mapLoaded = false;
  Timer? _debounceTimer;
  final AppLogger _logger =
      const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  // Cache for geocoding results
  static final Map<String, String> _geocodingCache = {};
  static const String _cacheKey = 'homebase_geocoding_cache';

  @override
  void initState() {
    super.initState();
    _logger.debug('HomebaseSelectionPage: initState called');
    _loadCachedLocation();
    _initializeMap();
    _preloadCommonLocations();
  }

  Future<void> _preloadCommonLocations() async {
    // Preload geocoding for common locations to improve performance
    final commonLocations = [
      const LatLng(40.7128, -74.0060), // NYC
      const LatLng(34.0522, -118.2437), // LA
      const LatLng(41.8781, -87.6298), // Chicago
      const LatLng(29.7604, -95.3698), // Houston
      const LatLng(33.7490, -84.3880), // Atlanta
    ];

    for (final location in commonLocations) {
      final cacheKey =
          '${location.latitude.toStringAsFixed(4)}_${location.longitude.toStringAsFixed(4)}';
      if (!_geocodingCache.containsKey(cacheKey)) {
        // Preload in background
        _getNeighborhoodName(location).catchError((e) {
          _logger.warn(
              'HomebaseSelectionPage: Error preloading location $location: $e');
        });
      }
    }
  }

  Future<void> _loadCachedLocation() async {
    try {
      final prefs = di.sl<SharedPreferences>();
      final cachedLat = prefs.getDouble('cached_lat');
      final cachedLng = prefs.getDouble('cached_lng');
      final cachedNeighborhood = prefs.getString('cached_neighborhood');

      if (cachedLat != null && cachedLng != null) {
        _currentLocation = LatLng(cachedLat, cachedLng);
        if (cachedNeighborhood != null) {
          _selectedNeighborhood = cachedNeighborhood;
          widget.onHomebaseChanged(cachedNeighborhood);
        }
        _logger.debug(
            'HomebaseSelectionPage: Loaded cached location: $_currentLocation, neighborhood: $_selectedNeighborhood');
      }
    } catch (e) {
      _logger.error('HomebaseSelectionPage: Error loading cached location',
          error: e);
    }
  }

  Future<void> _saveCachedLocation(LatLng location, String neighborhood) async {
    try {
      final prefs = di.sl<SharedPreferences>();
      await prefs.setDouble('cached_lat', location.latitude);
      await prefs.setDouble('cached_lng', location.longitude);
      await prefs.setString('cached_neighborhood', neighborhood);
      _logger.debug('HomebaseSelectionPage: Saved location to cache');
    } catch (e) {
      _logger.error('HomebaseSelectionPage: Error saving cached location',
          error: e);
    }
  }

  Future<void> _initializeMap() async {
    _logger.debug('HomebaseSelectionPage: Initializing map');

    // Set a default location first to ensure map loads
    if (_currentLocation == null) {
      _currentLocation = const LatLng(40.7128, -74.0060); // NYC default
    }

    setState(() {
      _mapLoaded = true;
    });

    // Then try to get current location
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    _logger.debug('HomebaseSelectionPage: Getting current location');

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      _logger.debug(
          'HomebaseSelectionPage: Initial permission status: $permission');

      if (permission == LocationPermission.denied) {
        _logger.debug('HomebaseSelectionPage: Requesting location permission');
        permission = await Geolocator.requestPermission();
        _logger.debug(
            'HomebaseSelectionPage: Permission after request: $permission');
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        _hasLocationPermission = true;
        _logger.debug('HomebaseSelectionPage: Location permission granted');

        // Get current position with medium accuracy for faster results
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium, // Faster than high accuracy
          ),
        ).timeout(
          const Duration(seconds: 8), // Reduced from 15 seconds
          onTimeout: () => throw TimeoutException('Location request timed out'),
        );

        _logger.debug(
            'HomebaseSelectionPage: Got position: ${position.latitude}, ${position.longitude}');

        // Update current location
        _currentLocation = LatLng(position.latitude, position.longitude);

        // Center map on user's location
        _mapController.move(_currentLocation!, 15);

        // Get neighborhood name for the centered location (in parallel)
        _getNeighborhoodName(_currentLocation!);
      } else {
        _logger.warn(
            'HomebaseSelectionPage: Location permission denied, using default location');
        // Default to a central location if no permission
        _mapController.move(const LatLng(40.7128, -74.0060), 15); // NYC
        _getNeighborhoodName(const LatLng(40.7128, -74.0060));
      }
    } catch (e) {
      _logger.error('HomebaseSelectionPage: Error getting location', error: e);
      // Default to a central location on error
      _mapController.move(const LatLng(40.7128, -74.0060), 15); // NYC
      _getNeighborhoodName(const LatLng(40.7128, -74.0060));
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getNeighborhoodName(LatLng location) async {
    _logger.debug(
        'HomebaseSelectionPage: Getting neighborhood name for location: ${location.latitude}, ${location.longitude}');

    // Create cache key
    final cacheKey =
        '${location.latitude.toStringAsFixed(4)}_${location.longitude.toStringAsFixed(4)}';

    // Check cache first
    if (_geocodingCache.containsKey(cacheKey)) {
      final cachedResult = _geocodingCache[cacheKey]!;
      _logger
          .debug('HomebaseSelectionPage: Using cached result: $cachedResult');
      if (mounted) {
        setState(() {
          _selectedNeighborhood = cachedResult;
        });
      }
      widget.onHomebaseChanged(cachedResult);
      await _saveCachedLocation(location, cachedResult);
      return;
    }

    try {
      // Use a short-timeout geocoding; on web this resolves via stub quickly
      final placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      ).timeout(const Duration(seconds: 4));
      _logger
          .debug('HomebaseSelectionPage: Got ${placemarks.length} placemarks');

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        _logger.debug(
            'HomebaseSelectionPage: First placemark: ${place.name}, ${place.thoroughfare}, ${place.locality}');

        String neighborhood = _extractNeighborhood(place);
        _logger.debug(
            'HomebaseSelectionPage: Extracted neighborhood: $neighborhood');

        // Cache the result
        _geocodingCache[cacheKey] = neighborhood;

        if (mounted) {
          setState(() {
            _selectedNeighborhood = neighborhood;
          });
        }

        // Update the homebase selection
        if (neighborhood != 'Unknown Location') {
          widget.onHomebaseChanged(neighborhood);
          await _saveCachedLocation(location, neighborhood);
        }
      } else {
        _logger.warn('HomebaseSelectionPage: No placemarks found');
        if (mounted) {
          setState(() {
            _selectedNeighborhood = 'Unknown Location';
          });
        }
      }
    } catch (e) {
      _logger.error('HomebaseSelectionPage: Error in geocoding', error: e);
      // Try reverse geocoding as fallback with shorter timeout
      try {
        final completer = Completer<List<Placemark>>();

        Timer(const Duration(seconds: 3), () {
          if (!completer.isCompleted) {
            completer.completeError('Reverse geocoding timeout');
          }
        });

        placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        ).then((placemarks) {
          if (!completer.isCompleted) {
            completer.complete(placemarks);
          }
        }).catchError((error) {
          if (!completer.isCompleted) {
            completer.completeError(error);
          }
        });

        final reversePlacemarks = await completer.future;

        if (reversePlacemarks.isNotEmpty) {
          Placemark place = reversePlacemarks.first;
          String neighborhood = _extractNeighborhood(place);

          // Cache the result
          _geocodingCache[cacheKey] = neighborhood;

          if (mounted) {
            setState(() {
              _selectedNeighborhood = neighborhood;
            });
          }
        }
      } catch (e2) {
        _logger.error('HomebaseSelectionPage: Error in reverse geocoding',
            error: e2);
        // Handle geocoding error
        if (mounted) {
          setState(() {
            _selectedNeighborhood = 'Unknown Location';
          });
        }
      }
    }
  }

  String _extractNeighborhood(Placemark place) {
    // Try to get the most specific neighborhood name
    // For NYC and other cities, prioritize thoroughfare over sublocality

    // First, try to get the thoroughfare (street name) which is more specific
    if (place.thoroughfare?.isNotEmpty == true) {
      return place.thoroughfare!;
    }

    // For NYC specifically, try to extract neighborhood from address components
    if (place.locality?.toLowerCase().contains('new york') == true ||
        place.administrativeArea?.toLowerCase().contains('new york') == true) {
      // Try to get neighborhood from street name or address
      String street = place.street ?? '';
      String thoroughfare = place.thoroughfare ?? '';

      // Common NYC neighborhood patterns in street names
      List<String> nycNeighborhoods = [
        'gowanus',
        'red hook',
        'upper east side',
        'upper west side',
        'lower east side',
        'lower west side',
        'chelsea',
        'greenwich village',
        'soho',
        'noho',
        'tribeca',
        'financial district',
        'battery park',
        'east village',
        'west village',
        'harlem',
        'morningside heights',
        'washington heights',
        'inwood',
        'astoria',
        'long island city',
        'sunnyside',
        'woodside',
        'jackson heights',
        'flushing',
        'forest hills',
        'kew gardens',
        'bayside',
        'douglaston',
        'williamsburg',
        'greenpoint',
        'bushwick',
        'bedford-stuyvesant',
        'crown heights',
        'prospect heights',
        'park slope',
        'carroll gardens',
        'cobble hill',
        'boerum hill',
        'brooklyn heights',
        'dumbo',
        'vinegar hill',
        'fort greene',
        'clinton hill',
        'prospect lefferts gardens',
        'bay ridge',
        'sunset park',
        'borough park',
        'bensonhurst',
        'sheepshead bay',
        'brighton beach',
        'coney island',
        'flatbush',
        'east flatbush',
        'canarsie',
        'brownsville',
        'east new york'
      ];

      // Check if any neighborhood name is in the street or thoroughfare
      String searchText =
          '${street.toLowerCase()} ${thoroughfare.toLowerCase()}'.trim();
      for (String neighborhood in nycNeighborhoods) {
        if (searchText.contains(neighborhood)) {
          return neighborhood
              .split(' ')
              .map((word) =>
                  word.substring(0, 1).toUpperCase() + word.substring(1))
              .join(' ');
        }
      }
    }

    // Fallback to sublocality (borough for NYC)
    if (place.subLocality?.isNotEmpty == true) {
      return place.subLocality!;
    }

    // Fallback to subadministrative area (borough for NYC)
    if (place.subAdministrativeArea?.isNotEmpty == true) {
      if (place.locality?.isNotEmpty == true) {
        return '${place.subAdministrativeArea}, ${place.locality}';
      }
      return place.subAdministrativeArea!;
    }

    // Fallback to locality (city name)
    if (place.locality?.isNotEmpty == true) {
      return place.locality!;
    }

    // Final fallback to administrative area (state)
    if (place.administrativeArea?.isNotEmpty == true) {
      return place.administrativeArea!;
    }

    return 'Unknown Location';
  }

  void _onMapMoved() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Get current map center (where the fixed marker is positioned)
    final center = _mapController.camera.center;
    // Debounce the geocoding call with shorter delay for faster response
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        _getNeighborhoodName(center);
      }
    });
  }

  void _onMapZoomChanged() {
    // Disable zoom in if user hasn't zoomed out first
    final zoom = _mapController.camera.zoom;
    if (zoom > 15) {
      // If zoomed in too much, zoom out to neighborhood level
      _mapController.move(_mapController.camera.center, 15);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Where\'s your homebase?',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Position the marker over your homebase. Only the location name will appear on your profile.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.grey600,
                ),
          ),
          const SizedBox(height: 24),

          // Map Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.grey300,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Map
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            _currentLocation ?? const LatLng(40.7128, -74.0060),
                        initialZoom: 15,
                        minZoom: 10,
                        maxZoom: 15,
                        onMapEvent: (event) {
                          if (event is MapEventMove) {
                            _onMapMoved();
                            _onMapZoomChanged();
                          }
                        },
                        onMapReady: () {
                          _logger.debug('HomebaseSelectionPage: Map is ready');
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.spots.app',
                          maxZoom: 18,
                        ),
                      ],
                    ),

                    // Fixed center marker (always in center of map)
                    Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.white,
                          size: 20,
                        ),
                      ),
                    ),

                    // Loading overlay
                    if (_isLoadingLocation || !_mapLoaded)
                      Container(
                        color: AppColors.black.withValues(alpha: 0.3),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Loading map...',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Selected neighborhood indicator
                    if (_selectedNeighborhood != null)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _selectedNeighborhood!,
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Location permission warning
                    if (!_hasLocationPermission)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_off,
                                color: AppColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Location access needed to find your neighborhood',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _getCurrentLocation,
                                child: const Text(
                                  'Enable',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Retry button for location issues
                    if (_selectedNeighborhood == null && !_isLoadingLocation)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.grey600.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.refresh,
                                color: AppColors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tap to refresh location',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _getCurrentLocation,
                                child: const Text(
                                  'Retry',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}
