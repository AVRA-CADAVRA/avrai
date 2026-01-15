import 'dart:async';
import 'dart:convert';
import 'package:avrai/core/services/logger.dart';
import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart'
    if (dart.library.html) 'package:avrai/presentation/pages/onboarding/web_geocoding_nominatim.dart';
import 'package:latlong2/latlong.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:avrai/core/services/geo_hierarchy_service.dart';
import 'package:avrai/core/services/geo_city_pack_service.dart';

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

  final GeoHierarchyService _geoHierarchyService = GeoHierarchyService();
  List<Polygon> _geoPolygons = const [];

  bool get _isWidgetTestBinding {
    // Avoid importing flutter_test into production code; detect via binding type name.
    final bindingType = WidgetsBinding.instance.runtimeType.toString();
    return bindingType.contains('TestWidgetsFlutterBinding') ||
        bindingType.contains('AutomatedTestWidgetsFlutterBinding');
  }

  @override
  void initState() {
    super.initState();
    _logger.debug('HomebaseSelectionPage: initState called');

    // Respect a pre-selected homebase (e.g., when navigating back in onboarding).
    if (widget.selectedHomebase != null &&
        widget.selectedHomebase!.isNotEmpty) {
      _selectedNeighborhood = widget.selectedHomebase;
    }

    // Use addPostFrameCallback to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadCachedLocation();
        _initializeMap();
        // NOTE: Geocoding preloads were removed because they can trigger async
        // errors and non-determinism (especially under widget tests where HTTP
        // requests are blocked and reverse geocoding can time out).
      }
    });
  }

  Future<void> _loadCachedLocation() async {
    try {
      if (!di.sl.isRegistered<SharedPreferences>()) {
        return;
      }
      final prefs = di.sl<SharedPreferences>();
      // Restore persisted geocoding cache (best-effort)
      try {
        final cacheJson = prefs.getString(_cacheKey);
        if (cacheJson != null && cacheJson.isNotEmpty) {
          final decoded = jsonDecode(cacheJson);
          if (decoded is Map) {
            for (final entry in decoded.entries) {
              final k = entry.key?.toString();
              final v = entry.value?.toString();
              if (k != null && v != null) {
                _geocodingCache[k] = v;
              }
            }
          }
        }
      } catch (e) {
        _logger.debug('HomebaseSelectionPage: Failed to restore cache: $e');
      }

      final cachedLat = prefs.getDouble('cached_lat');
      final cachedLng = prefs.getDouble('cached_lng');
      final cachedNeighborhood = prefs.getString('cached_neighborhood');

      if (cachedLat != null && cachedLng != null) {
        _currentLocation = LatLng(cachedLat, cachedLng);
        if (cachedNeighborhood != null) {
          _selectedNeighborhood = cachedNeighborhood;
          // Use addPostFrameCallback to avoid calling parent setState during build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onHomebaseChanged(cachedNeighborhood);
            }
          });
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
      if (!di.sl.isRegistered<SharedPreferences>()) {
        return;
      }
      final prefs = di.sl<SharedPreferences>();
      await prefs.setDouble('cached_lat', location.latitude);
      await prefs.setDouble('cached_lng', location.longitude);
      await prefs.setString('cached_neighborhood', neighborhood);
      // Persist geocoding cache (best-effort) to speed up future onboarding.
      try {
        await prefs.setString(_cacheKey, jsonEncode(_geocodingCache));
      } catch (_) {
        // ignore cache persistence failures
      }
      _logger.debug('HomebaseSelectionPage: Saved location to cache');
    } catch (e) {
      _logger.error('HomebaseSelectionPage: Error saving cached location',
          error: e);
    }
  }

  Future<void> _initializeMap() async {
    _logger.debug('HomebaseSelectionPage: Initializing map');

    // Set a default location first to ensure map loads
    _currentLocation ??= const LatLng(40.7128, -74.0060);

    setState(() {
      _mapLoaded = true;
    });

    // Auto-load geo overlays (best-effort) immediately for default/known location,
    // so onboarding shows locality geometry from the start.
    final initial = _currentLocation ?? const LatLng(40.7128, -74.0060);
    // ignore: unawaited_futures
    _loadGeoOverlayForCenter(initial);

    // Then try to get current location AFTER the map has rendered at least once.
    // flutter_map's MapController throws if move() is called before first render.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // If the user already has a selected homebase, don't override it.
        if (_selectedNeighborhood == null || _selectedNeighborhood!.isEmpty) {
          _getCurrentLocation();
        }
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    _logger.debug('HomebaseSelectionPage: Getting current location');

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Widget/integration test mode: avoid OS permission dialogs, plugins, and geocoding.
      if (_isWidgetTestBinding) {
        _logger.info(
          'HomebaseSelectionPage: FLUTTER_TEST enabled - using default homebase without permission prompts',
          tag: 'HomebaseSelectionPage',
        );
        _hasLocationPermission = false;
        _currentLocation = const LatLng(40.7128, -74.0060); // NYC default
        // IMPORTANT: Do not call _mapController.move() here; flutter_map throws if
        // the FlutterMap widget hasn't rendered yet (common in widget/integration tests).

        // Set a deterministic, human-readable homebase.
        const neighborhood = 'New York, NY';
        if (mounted) {
          setState(() {
            _selectedNeighborhood = neighborhood;
          });
        }
        widget.onHomebaseChanged(neighborhood);
        await _saveCachedLocation(_currentLocation!, neighborhood);
        return;
      }

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
        try {
          _mapController.move(_currentLocation!, 15);
        } catch (e) {
          _logger.debug('HomebaseSelectionPage: Map not ready for move(): $e');
        }

        // Auto-load locality geometry overlay for this point (best-effort).
        // ignore: unawaited_futures
        _loadGeoOverlayForCenter(_currentLocation!);

        // Get neighborhood name for the centered location (in parallel)
        _getNeighborhoodName(_currentLocation!);
      } else {
        _logger.warn(
            'HomebaseSelectionPage: Location permission denied, using default location');
        // Default to a central location if no permission
        try {
          _mapController.move(const LatLng(40.7128, -74.0060), 15); // NYC
        } catch (e) {
          _logger.debug('HomebaseSelectionPage: Map not ready for move(): $e');
        }
        // ignore: unawaited_futures
        _loadGeoOverlayForCenter(const LatLng(40.7128, -74.0060));
        _getNeighborhoodName(const LatLng(40.7128, -74.0060));
      }
    } catch (e) {
      _logger.error('HomebaseSelectionPage: Error getting location', error: e);
      // Default to a central location on error
      try {
        _mapController.move(const LatLng(40.7128, -74.0060), 15); // NYC
      } catch (moveError) {
        _logger.debug(
            'HomebaseSelectionPage: Map not ready for move() after error: $moveError');
      }
      // ignore: unawaited_futures
      _loadGeoOverlayForCenter(const LatLng(40.7128, -74.0060));
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
        // Auto-refresh locality overlay as the user moves the marker.
        // ignore: unawaited_futures
        _loadGeoOverlayForCenter(center);
        _getNeighborhoodName(center);
      }
    });
  }

  Future<void> _loadGeoOverlayForCenter(LatLng center) async {
    // Avoid any network/RPC calls in widget tests.
    if (_isWidgetTestBinding) return;

    try {
      final lookup = await _geoHierarchyService.lookupLocalityByPoint(
        lat: center.latitude,
        lon: center.longitude,
      );

      // If we can resolve a locality_code, render that polygon.
      if (lookup != null) {
        // Best-effort: ensure the relevant city pack is installed so the user
        // keeps getting locality boundaries offline after onboarding.
        // ignore: unawaited_futures
        unawaited(GeoCityPackService().ensureLatestInstalled(lookup.cityCode));

        final poly = await _geoHierarchyService.getLocalityPolygon(
          localityCode: lookup.localityCode,
          simplifyTolerance: 0.01,
        );
        if (!mounted) return;

        if (poly != null && poly.rings.isNotEmpty) {
          final outer = poly.rings.first
              .map((p) => LatLng(p.lat, p.lon))
              .toList(growable: false);

          setState(() {
            _geoPolygons = [
              Polygon(
                points: outer,
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderColor: AppTheme.primaryColor.withValues(alpha: 0.9),
                borderStrokeWidth: 2,
              ),
            ];
          });
          return;
        }
      }

      // No overlay available.
      if (!mounted) return;
      if (_geoPolygons.isNotEmpty) {
        setState(() => _geoPolygons = const []);
      }
    } catch (e) {
      // Best-effort: overlay failure should never block onboarding.
      _logger.debug('HomebaseSelectionPage: Geo overlay load failed: $e');
    }
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
    final isFlutterTest = _isWidgetTestBinding;

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
                    if (isFlutterTest)
                      // In `flutter test`, avoid network tile fetches and plugin-driven map behavior.
                      // This keeps widget tests deterministic and prevents HttpClient exceptions.
                      Container(
                        color: AppColors.grey200,
                        child: const Center(
                          child: Icon(
                            Icons.map,
                            color: AppColors.grey600,
                            size: 48,
                          ),
                        ),
                      )
                    else
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLocation ??
                              const LatLng(40.7128, -74.0060),
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
                            _logger
                                .debug('HomebaseSelectionPage: Map is ready');
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.avrai.app',
                            maxZoom: 18,
                          ),
                          if (_geoPolygons.isNotEmpty)
                            PolygonLayer(
                              polygons: _geoPolygons,
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
                              const Expanded(
                                child: Text(
                                  'Location access needed to find your neighborhood',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _getCurrentLocation,
                                style: TextButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
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
                              const Expanded(
                                child: Text(
                                  'Tap to refresh location',
                                  style: TextStyle(
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
