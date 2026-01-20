import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'package:avrai/core/theme/map_themes.dart';
import 'package:avrai/core/theme/map_theme_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/presentation/blocs/spots/spots_bloc.dart';
import 'package:avrai/presentation/blocs/lists/lists_bloc.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/models/list.dart';
import 'package:avrai/presentation/pages/spots/spot_details_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai/presentation/widgets/common/offline_indicator.dart';
import 'package:avrai/presentation/blocs/auth/auth_bloc.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/widgets/boundaries/border_visualization_widget.dart';
import 'package:avrai/presentation/widgets/chat/chat_button_with_badge.dart';
import 'package:avrai/core/services/geo_city_pack_service.dart';
import 'package:avrai/core/services/geo_hierarchy_service.dart';
import 'package:avrai/presentation/widgets/map/geo_synco_summary_card.dart';
import 'package:avrai/core/services/neighborhood_boundary_service.dart';
import 'package:avrai/core/models/neighborhood_boundary.dart';
import 'package:avrai/core/services/geohash_service.dart';
import 'package:avrai/presentation/widgets/map/spot_reservation_marker.dart';
import 'dart:developer' as developer;

class MapView extends StatefulWidget {
  final SpotList? initialSelectedList;
  final ValueChanged<SpotList?>? onListSelected;
  final bool showAppBar;
  final String? appBarTitle;

  const MapView({
    super.key,
    this.initialSelectedList,
    this.onListSelected,
    this.showAppBar = true,
    this.appBarTitle,
  });

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  final MapController _mapController = MapController();
  LatLng? _center;
  final double _currentZoom = 13.0;
  gmap.GoogleMapController? _gController;
  final bool _isLoadingLocation = false;
  String? _locationError;
  MapTheme _currentTheme = MapThemes.spotsBlue;
  SpotList? _selectedList;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  // Border visualization
  bool _showBoundaries = true;
  // ignore: unused_field
  BorderVisualizationWidget? _borderVisualization;
  final GlobalKey<State<BorderVisualizationWidget>> _borderVisualizationKey =
      GlobalKey<State<BorderVisualizationWidget>>();

  // First-class geo hierarchy + map overlays
  final GeoHierarchyService _geoHierarchyService = GeoHierarchyService();
  final NeighborhoodBoundaryService _neighborhoodBoundaryService =
      NeighborhoodBoundaryService();
  Set<gmap.Polyline> _boundaryPolylines = {};
  Set<gmap.Polygon> _boundaryPolygons = {};
  String? _selectedBoundaryCityCode;
  String? _selectedBoundaryLocalityName;
  String? _selectedBoundaryLocalityCode;

  static const bool _enableIosGoogleMaps =
      bool.fromEnvironment('ENABLE_IOS_GOOGLE_MAPS');

  bool get _shouldUseGoogleMaps {
    // iOS Google Maps SDK hard-crashes if GMSServices isn't provided an API key.
    // Default to flutter_map tiles on iOS unless explicitly enabled.
    if (Platform.isIOS && !_enableIosGoogleMaps) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _selectedList = widget.initialSelectedList;
    _loadSavedTheme();
    _loadSpots();
    _initializeSearchSuggestions();

    // Load spots and lists if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Add a small delay to ensure native plugins are fully initialized
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;

        try {
          context.read<SpotsBloc>().add(LoadSpots());
          context.read<ListsBloc>().add(LoadLists());
        } catch (e) {
          developer.log('Error loading spots/lists: $e', name: 'MapView');
        }

        // Request location permission and auto-locate user
        //
        // NOTE: In widget tests, geolocator calls may never complete, and the
        // Future.timeout() timers can remain pending after disposal.
        // We skip auto-location in Flutter test runs to keep widget tests deterministic.
        if (!_isRunningInFlutterTest()) {
          // Wrap in try-catch to prevent crashes from location requests
          try {
            _requestLocationPermission();
            _getCurrentLocationWithRetry();
          } catch (e, stackTrace) {
            developer.log('Error in location initialization: $e',
                name: 'MapView');
            developer.log('Stack trace: $stackTrace', name: 'MapView');
            if (mounted) {
              setState(() {
                _locationError = 'Location initialization failed';
              });
            }
          }
        }

        // Initialize border visualization (Google Maps only).
        if (mounted && _shouldUseGoogleMaps) {
          try {
            _borderVisualization = BorderVisualizationWidget(
              key: _borderVisualizationKey,
              mapController: _gController,
              city: 'New York', // TODO: Get from user location or settings
              showSoftBorderSpots: true,
              showRefinementIndicators: true,
            );
          } catch (e) {
            developer.log('Error initializing border visualization: $e',
                name: 'MapView');
          }
        }
      });
    });
  }

  bool _isRunningInFlutterTest() {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  Future<Position?> _getCurrentLocation() async {
    try {
      developer.log('Getting current location...', name: 'MapView');

      // Check permission first
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        developer.log(
            'Location permission not granted, skipping location request',
            name: 'MapView');
        if (mounted) {
          setState(() {
            _locationError = 'Location permission required';
          });
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );
      developer.log(
          'Location obtained: ${position.latitude}, ${position.longitude}',
          name: 'MapView');

      if (mounted) {
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _locationError = null;
        });
      }

      // Center flutter_map (best-effort; MapController can throw before first render).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = _center;
        if (c == null) return;
        try {
          _mapController.move(c, _currentZoom);
        } catch (_) {
          // ignore controller lifecycle errors
        }
      });

      // Center the Google map camera (best-effort) and auto-load geo overlays.
      final g = _gController;
      if (g != null) {
        try {
          await g.animateCamera(
            gmap.CameraUpdate.newLatLng(
              gmap.LatLng(position.latitude, position.longitude),
            ),
          );
        } catch (_) {
          // ignore camera failures (controller lifecycle / platform quirks)
        }
      }
      // ignore: unawaited_futures
      _autoLoadBoundariesFromPoint(
        lat: position.latitude,
        lon: position.longitude,
      );

      return position;
    } catch (e, stackTrace) {
      developer.log('Error getting location: $e', name: 'MapView');
      developer.log('Stack trace: $stackTrace', name: 'MapView');
      if (mounted) {
        setState(() {
          _locationError = 'Failed to get location: ${e.toString()}';
        });
      }
      return null;
    }
  }

  Future<Position?> _getCurrentLocationWithRetry() async {
    try {
      developer.log('Getting current location with retry...', name: 'MapView');

      // Check permission first
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        developer.log(
            'Location permission not granted, skipping location request',
            name: 'MapView');
        if (mounted) {
          setState(() {
            _locationError = 'Location permission required';
          });
        }
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Location request timed out'),
      );
      developer.log(
          'Location obtained with retry: ${position.latitude}, ${position.longitude}',
          name: 'MapView');

      if (mounted) {
        setState(() {
          _center = LatLng(position.latitude, position.longitude);
          _locationError = null;
        });
      }

      // Center flutter_map (best-effort; MapController can throw before first render).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final c = _center;
        if (c == null) return;
        try {
          _mapController.move(c, _currentZoom);
        } catch (_) {
          // ignore controller lifecycle errors
        }
      });

      // Center the Google map camera (best-effort) and auto-load geo overlays.
      final g = _gController;
      if (g != null) {
        try {
          await g.animateCamera(
            gmap.CameraUpdate.newLatLng(
              gmap.LatLng(position.latitude, position.longitude),
            ),
          );
        } catch (_) {
          // ignore camera failures (controller lifecycle / platform quirks)
        }
      }
      // ignore: unawaited_futures
      _autoLoadBoundariesFromPoint(
        lat: position.latitude,
        lon: position.longitude,
      );

      return position;
    } catch (e, stackTrace) {
      developer.log('Error getting location with retry: $e', name: 'MapView');
      developer.log('Stack trace: $stackTrace', name: 'MapView');
      if (mounted) {
        setState(() {
          _locationError = 'Failed to get location: ${e.toString()}';
        });
      }
      return null;
    }
  }

  Future<void> _requestLocationPermission() async {
    developer.log('Requesting location permission...', name: 'MapView');
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      developer.log('Location permission denied, requesting...',
          name: 'MapView');
      final requestedPermission = await Geolocator.requestPermission();
      if (requestedPermission == LocationPermission.denied) {
        developer.log('Location permission still denied', name: 'MapView');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Location permission is required for map functionality')),
          );
        }
      } else if (requestedPermission == LocationPermission.deniedForever) {
        developer.log('Location permission denied forever', name: 'MapView');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content:
                    Text('Please enable location permissions in settings')),
          );
        }
      } else {
        developer.log('Location permission granted', name: 'MapView');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission granted!')),
          );
        }
      }
    } else if (permission == LocationPermission.deniedForever) {
      developer.log('Location permission denied forever', name: 'MapView');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enable location permissions in settings')),
        );
      }
    } else {
      developer.log('Location permission already granted', name: 'MapView');
    }
  }

  Future<void> _autoLoadBoundariesFromPoint({
    required double lat,
    required double lon,
  }) async {
    if (!mounted) return;
    if (!_showBoundaries) return;

    try {
      final locality = await _geoHierarchyService.lookupLocalityByPoint(
        lat: lat,
        lon: lon,
      );

      if (!mounted) return;

      if (locality != null) {
        // Best-effort: cache the city pack for offline use.
        // ignore: unawaited_futures
        unawaited(
            GeoCityPackService().ensureLatestInstalled(locality.cityCode));

        setState(() {
          _selectedBoundaryCityCode = locality.cityCode;
          _selectedBoundaryLocalityName = locality.displayName;
          _selectedBoundaryLocalityCode = locality.localityCode;
        });
        await _loadBoundaryOverlays();
        return;
      }

      final cityCode = await _geoHierarchyService.lookupCityCodeByPoint(
        lat: lat,
        lon: lon,
      );
      if (!mounted) return;
      if (cityCode != null && cityCode.isNotEmpty) {
        // Best-effort: cache the city pack for offline use.
        // ignore: unawaited_futures
        unawaited(GeoCityPackService().ensureLatestInstalled(cityCode));

        setState(() {
          _selectedBoundaryCityCode = cityCode;
          _selectedBoundaryLocalityName = null;
          _selectedBoundaryLocalityCode = null;
        });
        await _loadBoundaryOverlays();
      }
    } catch (e, st) {
      developer.log(
        'Auto boundary load failed: $e',
        name: 'MapView',
        stackTrace: st,
      );
    }
  }

  Future<void> _loadSavedTheme() async {
    final savedTheme = await MapThemeManager.getCurrentTheme();
    setState(() {
      _currentTheme = savedTheme;
    });
  }

  void _initializeSearchSuggestions() {
    _searchSuggestions = [
      'Coffee shops',
      'Restaurants',
      'Parks',
      'Museums',
      'Bars',
      'Shopping',
      'Gyms',
      'Libraries',
      'Near me',
      'Popular spots',
      'New places',
      'Trending',
    ];
  }

  void _loadSpots() {
    context.read<SpotsBloc>().add(LoadSpots());
  }

  void _handleSearch(String query) {
    if (query.isEmpty) {
      // Clear search and show all spots
      context.read<SpotsBloc>().add(SearchSpots(query: ''));
      setState(() {
        _showSuggestions = false;
      });
      return;
    }

    // Check if it's a location search
    if (query.toLowerCase().contains('near me') ||
        query.toLowerCase().contains('nearby')) {
      _searchNearbySpots();
      return;
    }

    // Check if it's a category search
    if (_isCategorySearch(query)) {
      _searchByCategory(query);
      return;
    }

    // Regular text search
    context.read<SpotsBloc>().add(SearchSpots(query: query));
    setState(() {
      _showSuggestions = false;
    });
  }

  bool _isCategorySearch(String query) {
    final categories = [
      'coffee',
      'restaurant',
      'park',
      'museum',
      'bar',
      'shopping',
      'gym',
      'library',
      'cafe',
      'food',
      'drink',
      'entertainment'
    ];
    return categories.any((category) => query.toLowerCase().contains(category));
  }

  void _searchByCategory(String query) {
    final category = _extractCategory(query);
    context.read<SpotsBloc>().add(SearchSpots(query: category));
    setState(() {
      _showSuggestions = false;
    });
  }

  String _extractCategory(String query) {
    final lowerQuery = query.toLowerCase();
    if (lowerQuery.contains('coffee') || lowerQuery.contains('cafe')) {
      return 'coffee';
    }
    if (lowerQuery.contains('restaurant') || lowerQuery.contains('food')) {
      return 'restaurant';
    }
    if (lowerQuery.contains('park')) return 'park';
    if (lowerQuery.contains('museum')) return 'museum';
    if (lowerQuery.contains('bar') || lowerQuery.contains('drink')) {
      return 'bar';
    }
    if (lowerQuery.contains('shopping')) return 'shopping';
    if (lowerQuery.contains('gym')) return 'gym';
    if (lowerQuery.contains('library')) return 'library';
    return query;
  }

  void _searchNearbySpots() {
    if (_center != null) {
      // For now, just show all spots since we don't have distance calculation
      // In a real app, you'd filter by distance from current location
      context.read<SpotsBloc>().add(SearchSpots(query: ''));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Showing all spots near your location'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Location not available. Please enable location services.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
    }
    setState(() {
      _showSuggestions = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _isSearching = value.isNotEmpty;
      if (value.isEmpty) {
        _showSuggestions = false;
        context.read<SpotsBloc>().add(SearchSpots(query: ''));
      } else {
        _showSuggestions = true;
        // Filter suggestions based on input
        _searchSuggestions = _searchSuggestions
            .where((suggestion) =>
                suggestion.toLowerCase().contains(value.toLowerCase()))
            .toList();
      }
    });
  }

  void _onSuggestionTap(String suggestion) {
    _searchController.text = suggestion;
    _handleSearch(suggestion);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = widget.showAppBar
        ? AppBar(
            title: Text(widget.appBarTitle ?? 'Map'),
            leading: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  return IconButton(
                    icon: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        state.user.displayName?.substring(0, 1).toUpperCase() ??
                            state.user.email.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onPressed: () {
                      _showProfileMenu(context);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            actions: [
              const ChatButtonWithBadge(),
              IconButton(
                icon:
                    Icon(_selectedList == null ? Icons.list : Icons.checklist),
                tooltip: 'Choose list',
                onPressed: () async {
                  final listState = context.read<ListsBloc>().state;
                  if (listState is ListsLoaded && listState.lists.isNotEmpty) {
                    final selected = await showModalBottomSheet<SpotList?>(
                      context: context,
                      builder: (context) {
                        return SafeArea(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.list),
                                title: const Text('All Spots'),
                                selected: _selectedList == null,
                                onTap: () => Navigator.pop(context, null),
                              ),
                              ...listState.lists.map((list) => ListTile(
                                    leading: const Icon(Icons.checklist),
                                    title: Text(list.title),
                                    selected: _selectedList?.id == list.id,
                                    onTap: () => Navigator.pop(context, list),
                                  )),
                            ],
                          ),
                        );
                      },
                    );
                    if (selected != null || _selectedList != selected) {
                      setState(() {
                        _selectedList = selected;
                      });
                      if (widget.onListSelected != null) {
                        widget.onListSelected!(selected);
                      }
                    }
                  }
                },
              ),
              IconButton(
                icon: Icon(
                    _showBoundaries ? Icons.border_clear : Icons.border_color),
                onPressed: () async {
                  final next = !_showBoundaries;
                  setState(() {
                    _showBoundaries = next;
                  });

                  if (!next) {
                    setState(() {
                      _boundaryPolylines = {};
                      _boundaryPolygons = {};
                    });
                    return;
                  }

                  if (_selectedBoundaryCityCode == null) {
                    await _pickBoundaryScope();
                  }
                  await _loadBoundaryOverlays();
                },
                tooltip:
                    _showBoundaries ? 'Hide boundaries' : 'Show boundaries',
              ),
              IconButton(
                icon: const Icon(Icons.palette),
                onPressed: _showThemeSelector,
                tooltip: 'Change map theme',
              ),
              IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _getCurrentLocation,
                tooltip: 'Center on my location',
              ),
              const OfflineIndicator(),
            ],
          )
        : null;

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: [
          // Enhanced search bar
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                // Search input
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.light
                        ? AppColors.grey100
                        : AppColors.grey800,
                    borderRadius: BorderRadius.circular(12),
                    border: _isSearching
                        ? Border.all(color: AppTheme.primaryColor, width: 2)
                        : null,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    onSubmitted: _handleSearch,
                    decoration: InputDecoration(
                      hintText: 'Search spots, categories, or "near me"...',
                      hintStyle: const TextStyle(
                        color: AppColors.textHint,
                        fontSize: 16,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: _isSearching
                            ? AppTheme.primaryColor
                            : AppColors.grey600,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _handleSearch('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),

                // Search suggestions
                if (_showSuggestions && _searchSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? AppColors.white
                          : AppColors.grey900,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final suggestion = _searchSuggestions[index];
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            _getSuggestionIcon(suggestion),
                            size: 20,
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _onSuggestionTap(suggestion),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Map content
          Expanded(
            child: _isLoadingLocation
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Getting your location...'),
                      ],
                    ),
                  )
                : BlocBuilder<SpotsBloc, SpotsState>(
                    builder: (context, spotState) {
                      if (spotState is SpotsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (spotState is SpotsLoaded) {
                        List<Spot> spots = spotState.filteredSpots.isNotEmpty
                            ? spotState.filteredSpots
                            : spotState.spots;

                        if (_selectedList != null) {
                          spots = spots
                              .where(
                                  (s) => _selectedList!.spotIds.contains(s.id))
                              .toList();
                        }

                        final LatLng centerLL = _center != null
                            ? _center!
                            : (spots.isNotEmpty
                                ? LatLng(
                                    spots.first.latitude, spots.first.longitude)
                                : const LatLng(37.7749, -122.4194));
                        final gmap.LatLng centerGM =
                            gmap.LatLng(centerLL.latitude, centerLL.longitude);

                        // Add boundary markers if boundaries are shown
                        // Note: Border visualization methods are accessed via widget state
                        // For now, boundaries are handled within the BorderVisualizationWidget itself
                        // TODO: Refactor to expose methods via callback or public interface

                        // Get boundary polylines/polygons if boundaries are shown (Google Maps only).
                        final polylines =
                            (_showBoundaries && _shouldUseGoogleMaps)
                                ? _boundaryPolylines
                                : <gmap.Polyline>{};
                        final polygons =
                            (_showBoundaries && _shouldUseGoogleMaps)
                                ? _boundaryPolygons
                                : <gmap.Polygon>{};

                        final showSynco = _showBoundaries &&
                            _selectedBoundaryCityCode != null &&
                            _selectedBoundaryCityCode!.isNotEmpty &&
                            _selectedBoundaryLocalityCode != null &&
                            _selectedBoundaryLocalityCode!.isNotEmpty;

                        final Widget mapWidget = _shouldUseGoogleMaps
                            ? gmap.GoogleMap(
                                initialCameraPosition: gmap.CameraPosition(
                                  target: centerGM,
                                  zoom: _currentZoom,
                                ),
                                myLocationEnabled: true,
                                myLocationButtonEnabled: false,
                                markers: <gmap.Marker>{
                                  if (_locationError == null && _center != null)
                                    gmap.Marker(
                                      markerId: const gmap.MarkerId('me'),
                                      position: gmap.LatLng(_center!.latitude,
                                          _center!.longitude),
                                    ),
                                  ...spots.map((spot) => gmap.Marker(
                                        markerId:
                                            gmap.MarkerId('spot-${spot.id}'),
                                        position: gmap.LatLng(
                                            spot.latitude, spot.longitude),
                                        onTap: () =>
                                            _showSpotInfo(context, spot),
                                      )),
                                },
                                polylines: polylines,
                                polygons: polygons,
                                onMapCreated: (controller) {
                                  _gController = controller;
                                  developer.log('GoogleMap ready',
                                      name: 'MapView');
                                },
                              )
                            : FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: centerLL,
                                  initialZoom: _currentZoom,
                                  interactionOptions:
                                      const InteractionOptions(),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: _getTileUrlTemplate(),
                                    subdomains: const ['a', 'b', 'c', 'd'],
                                    userAgentPackageName: 'com.avrai.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      if (_locationError == null &&
                                          _center != null)
                                        Marker(
                                          point: _center!,
                                          width: 40,
                                          height: 40,
                                          child: const Icon(
                                            Icons.my_location,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ...spots.map(
                                        (spot) => Marker(
                                          point: LatLng(
                                            spot.latitude,
                                            spot.longitude,
                                          ),
                                          width: 40,
                                          height: 40,
                                          child: SpotReservationMarker(
                                            spot: spot,
                                            // For map view, show that reservations are supported
                                            // Actual availability can be checked on spot details page
                                            isReservationAvailable: true,
                                            onTap: () =>
                                                _showSpotInfo(context, spot),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );

                        return Stack(
                          children: [
                            mapWidget,
                            if (showSynco)
                              Positioned(
                                left: 12,
                                right: 12,
                                bottom: 12,
                                child: GeoSyncoSummaryCard(
                                  cityCode: _selectedBoundaryCityCode!,
                                  geoId: _selectedBoundaryLocalityCode!,
                                ),
                              ),
                            if (kDebugMode &&
                                Platform.isIOS &&
                                !_shouldUseGoogleMaps)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 8,
                                        color: Color(0x22000000),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'Map: flutter_map (iOS Google Maps disabled)',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        );
                      }
                      return const Center(child: Text('No spots loaded'));
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _locationError != null
          ? FloatingActionButton.extended(
              onPressed: _getCurrentLocation,
              label: const Text('Retry Location'),
              icon: const Icon(Icons.refresh),
            )
          : null,
    );
  }

  // ignore: unused_element
  String _getTileUrlTemplate() {
    final url = _currentTheme.getTileUrl(0, 0, 0);
    if (url.contains('{s}')) {
      return url.replaceAll('/0/0/0.png', '/{z}/{x}/{y}.png');
    } else if (url.contains('{r}')) {
      return url.replaceAll('/0/0/0.png', '/{z}/{x}/{y}{r}.png');
    } else if (url.contains('{z}/{y}/{x}')) {
      return url;
    } else {
      return url.replaceAll('/0/0/0.png', '/{z}/{x}/{y}.png');
    }
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Text(
              'Choose Map Theme',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Select from different map styles and color themes',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.grey600,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: MapThemes.allThemes.length,
                itemBuilder: (context, index) {
                  final theme = MapThemes.allThemes[index];
                  final isSelected = theme.name == _currentTheme.name;
                  return GestureDetector(
                    onTap: () async {
                      await MapThemeManager.setTheme(theme);
                      if (!mounted) return;
                      if (!mounted || !context.mounted) return;
                      setState(() {
                        _currentTheme = theme;
                      });
                      if (!mounted || !context.mounted) return;
                      Navigator.pop(context);
                    },
                    child: Card(
                      elevation: isSelected ? 4 : 2,
                      color: isSelected
                          ? theme.primaryColor.withValues(alpha: 0.1)
                          : theme.surfaceColor,
                      child: Container(
                        decoration: BoxDecoration(
                          border: isSelected
                              ? Border.all(color: theme.primaryColor, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor,
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Icon(
                                  _getThemeIcon(theme.name),
                                  color: AppColors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                theme.name,
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                theme.tileServerName,
                                style: TextStyle(
                                  color: theme.textColor.withValues(alpha: 0.7),
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickBoundaryScope() async {
    try {
      final cities = await _geoHierarchyService.listCities();
      if (cities.isEmpty) return;

      String selectedCityCode =
          _selectedBoundaryCityCode ?? cities.first.cityCode;
      List<GeoLocalityV1> localities =
          await _geoHierarchyService.listCityLocalities(selectedCityCode);
      String? selectedLocalityName = _selectedBoundaryLocalityName ??
          (localities.isNotEmpty ? localities.first.displayName : null);

      if (!mounted) return;

      final result = await showModalBottomSheet<Map<String, String?>>(
        context: context,
        builder: (context) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select boundary scope',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCityCode,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                        items: cities
                            .map((c) => DropdownMenuItem(
                                  value: c.cityCode,
                                  child:
                                      Text('${c.displayName} (${c.cityCode})'),
                                ))
                            .toList(),
                        onChanged: (value) async {
                          if (value == null) return;
                          selectedCityCode = value;
                          localities = await _geoHierarchyService
                              .listCityLocalities(selectedCityCode);
                          selectedLocalityName = localities.isNotEmpty
                              ? localities.first.displayName
                              : null;
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedLocalityName,
                        decoration: const InputDecoration(
                          labelText: 'Locality (for boundaries)',
                          border: OutlineInputBorder(),
                        ),
                        items: localities
                            .where((l) => !l.isNeighborhood)
                            .map((l) => DropdownMenuItem(
                                  value: l.displayName,
                                  child: Text(l.displayName),
                                ))
                            .toList(),
                        onChanged: (value) {
                          selectedLocalityName = value;
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Note: neighborhood boundaries are currently available for large localities (e.g. Brooklyn, Los Angeles).',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context, null),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: AppColors.white,
                              ),
                              onPressed: () => Navigator.pop(context, {
                                'cityCode': selectedCityCode,
                                'localityName': selectedLocalityName,
                              }),
                              child: const Text('Apply'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      );

      if (result == null) return;
      setState(() {
        _selectedBoundaryCityCode = result['cityCode'];
        _selectedBoundaryLocalityName = result['localityName'];
        _selectedBoundaryLocalityCode = null; // resolved async below
      });

      // Best-effort: resolve locality_code for the selected locality name.
      final cityCode = _selectedBoundaryCityCode;
      final localityName = _selectedBoundaryLocalityName;
      if (cityCode != null &&
          cityCode.isNotEmpty &&
          localityName != null &&
          localityName.isNotEmpty) {
        final localityCode = await _geoHierarchyService.lookupLocalityCode(
          cityCode: cityCode,
          localityName: localityName,
        );
        if (!mounted) return;
        setState(() {
          _selectedBoundaryLocalityCode = localityCode;
        });
      }
    } catch (e, st) {
      developer.log('Failed to pick boundary scope: $e',
          name: 'MapView', stackTrace: st);
    }
  }

  Future<void> _loadBoundaryOverlays() async {
    if (!_showBoundaries) return;
    final cityCode = _selectedBoundaryCityCode;
    final localityName = _selectedBoundaryLocalityName;
    final localityCode = _selectedBoundaryLocalityCode;

    try {
      // Most precise (first-class geo): render locality polygon if available.
      if (localityCode != null && localityCode.isNotEmpty) {
        final poly = await _geoHierarchyService.getLocalityPolygon(
          localityCode: localityCode,
          simplifyTolerance: 0.01,
        );

        if (poly != null && poly.rings.isNotEmpty) {
          final polygons = <gmap.Polygon>{
            gmap.Polygon(
              polygonId: gmap.PolygonId('locality:$localityCode'),
              points: poly.rings.first
                  .map((p) => gmap.LatLng(p.lat, p.lon))
                  .toList(growable: false),
              holes: poly.rings.length > 1
                  ? poly.rings
                      .skip(1)
                      .map(
                        (r) => r
                            .map((p) => gmap.LatLng(p.lat, p.lon))
                            .toList(growable: false),
                      )
                      .toList(growable: false)
                  : const <List<gmap.LatLng>>[],
              strokeWidth: 2,
              strokeColor: AppTheme.primaryColor.withValues(alpha: 0.9),
              fillColor: AppTheme.primaryColor.withValues(alpha: 0.14),
            ),
          };

          if (!mounted) return;
          setState(() {
            _boundaryPolygons = polygons;
            _boundaryPolylines = {};
          });
          return;
        }
      }

      // Preferred (first-class geo): render city_code geohash3 tiles (bucket coverage).
      if (cityCode != null && cityCode.isNotEmpty) {
        final tiles = await _geoHierarchyService.listCityGeohash3Bounds(
          cityCode: cityCode,
          limit: 5000,
        );

        if (tiles.isNotEmpty) {
          final polygons = <gmap.Polygon>{};
          for (final t in tiles) {
            // Rectangle polygon (lon/lat order in LatLng is (lat, lon)).
            final points = <gmap.LatLng>[
              gmap.LatLng(t.minLat, t.minLon),
              gmap.LatLng(t.minLat, t.maxLon),
              gmap.LatLng(t.maxLat, t.maxLon),
              gmap.LatLng(t.maxLat, t.minLon),
            ];
            polygons.add(
              gmap.Polygon(
                polygonId:
                    gmap.PolygonId('city_tile:$cityCode:${t.geohash3Id}'),
                points: points,
                strokeWidth: 1,
                strokeColor: AppTheme.primaryColor.withValues(alpha: 0.8),
                fillColor: AppTheme.primaryColor.withValues(alpha: 0.12),
              ),
            );
          }

          if (!mounted) return;
          setState(() {
            _boundaryPolygons = polygons;
            _boundaryPolylines = {};
          });
          return;
        }
      }

      // NEW: Load locality agent geohash overlays (if available)
      final localityAgentPolygons = await _loadLocalityAgentGeohashOverlays(
        cityCode: cityCode,
        centerLat: _center?.latitude,
        centerLon: _center?.longitude,
      );
      if (localityAgentPolygons.isNotEmpty) {
        if (!mounted) return;
        setState(() {
          _boundaryPolygons = localityAgentPolygons;
          _boundaryPolylines = {};
        });
        return;
      }

      // Fallback: neighborhood "boundaries" (currently mock/generated)
      if (localityName == null || localityName.isEmpty) {
        setState(() {
          _boundaryPolylines = {};
          _boundaryPolygons = {};
        });
        return;
      }

      final boundaries = await _neighborhoodBoundaryService
          .loadBoundariesFromGoogleMaps(localityName);

      final next = <gmap.Polyline>{};
      for (final b in boundaries) {
        if (b.coordinates.isEmpty) continue;
        final points = b.coordinates
            .map((c) => gmap.LatLng(c.latitude, c.longitude))
            .toList(growable: false);
        next.add(
          gmap.Polyline(
            polylineId: gmap.PolylineId('boundary:${b.boundaryKey}'),
            points: points,
            width: b.boundaryType == BoundaryType.hardBorder ? 4 : 3,
            color: b.boundaryType == BoundaryType.hardBorder
                ? AppColors.error
                : AppTheme.primaryColor.withValues(alpha: 0.7),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _boundaryPolylines = next;
        _boundaryPolygons = {};
      });
    } catch (e, st) {
      developer.log('Failed to load boundaries: $e',
          name: 'MapView', stackTrace: st);
      if (!mounted) return;
      setState(() {
        _boundaryPolylines = {};
        _boundaryPolygons = {};
      });
    }
  }

  /// NEW: Load locality agent geohash overlays for visualization
  Future<Set<gmap.Polygon>> _loadLocalityAgentGeohashOverlays({
    required String? cityCode,
    required double? centerLat,
    required double? centerLon,
  }) async {
    if (cityCode == null || centerLat == null || centerLon == null) {
      return {};
    }

    try {
      // Get geohash for current location (precision 7 for locality agents)
      final geohash = GeohashService.encode(
        latitude: centerLat,
        longitude: centerLon,
        precision: 7,
      );

      // Get 8 neighbors for visualization
      final neighbors = GeohashService.neighbors(geohash: geohash);
      final allGeohashes = [geohash, ...neighbors];

      // Create polygons for each geohash
      final polygons = <gmap.Polygon>{};
      for (final gh in allGeohashes) {
        final bbox = GeohashService.decodeBoundingBox(gh);

        // Get agent state to determine opacity (more visits = more opaque)
        // Note: This requires accessing the global repository, which may not be public
        // For now, use a default opacity
        final opacity = 0.1; // Default opacity

        polygons.add(
          gmap.Polygon(
            polygonId: gmap.PolygonId('locality_agent_geohash:$gh'),
            points: [
              gmap.LatLng(bbox.latMin, bbox.lonMin),
              gmap.LatLng(bbox.latMin, bbox.lonMax),
              gmap.LatLng(bbox.latMax, bbox.lonMax),
              gmap.LatLng(bbox.latMax, bbox.lonMin),
            ],
            strokeWidth: 1,
            strokeColor: AppColors.secondary.withValues(alpha: 0.6),
            fillColor: AppColors.secondary.withValues(alpha: opacity),
          ),
        );
      }

      return polygons;
    } catch (e, st) {
      developer.log(
        'Failed to load locality agent geohash overlays: $e',
        name: 'MapView',
        stackTrace: st,
      );
      return {};
    }
  }

  IconData _getThemeIcon(String themeName) {
    switch (themeName.toLowerCase()) {
      case 'satellite':
        return Icons.satellite;
      case 'terrain':
        return Icons.terrain;
      case 'nature':
        return Icons.eco;
      case 'sunset':
        return Icons.wb_sunny;
      case 'purple':
        return Icons.palette;
      case 'minimalist':
        return Icons.crop_square;
      case 'dark':
        return Icons.dark_mode;
      case 'outdoors':
        return Icons.hiking;
      case 'street':
        return Icons.directions_car;
      default:
        return Icons.map;
    }
  }

  void _showSpotInfo(BuildContext context, Spot spot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(spot.name),
        content: Text(spot.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpotDetailsPage(spot: spot),
                ),
              );
            },
            child: const Text('View Details'),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        state.user.displayName?.substring(0, 1).toUpperCase() ??
                            state.user.email.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(state.user.displayName ?? 'User'),
                    subtitle: Text(state.user.email),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<AuthBloc>().add(SignOutRequested());
                    },
                  ),
                ],
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  IconData _getSuggestionIcon(String suggestion) {
    final lowerSuggestion = suggestion.toLowerCase();
    if (lowerSuggestion.contains('coffee') ||
        lowerSuggestion.contains('cafe')) {
      return Icons.coffee;
    }
    if (lowerSuggestion.contains('restaurant') ||
        lowerSuggestion.contains('food')) {
      return Icons.restaurant;
    }
    if (lowerSuggestion.contains('park')) return Icons.park;
    if (lowerSuggestion.contains('museum')) return Icons.museum;
    if (lowerSuggestion.contains('bar') || lowerSuggestion.contains('drink')) {
      return Icons.local_bar;
    }
    if (lowerSuggestion.contains('shopping')) return Icons.shopping_bag;
    if (lowerSuggestion.contains('gym')) return Icons.fitness_center;
    if (lowerSuggestion.contains('library')) return Icons.local_library;
    if (lowerSuggestion.contains('near me') ||
        lowerSuggestion.contains('nearby')) {
      return Icons.near_me;
    }
    if (lowerSuggestion.contains('popular')) return Icons.trending_up;
    if (lowerSuggestion.contains('new')) return Icons.new_releases;
    if (lowerSuggestion.contains('trending')) return Icons.trending_up;
    return Icons.search;
  }
}
