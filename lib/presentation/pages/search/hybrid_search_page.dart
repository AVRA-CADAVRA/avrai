import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:avrai/core/theme/app_theme.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:avrai/presentation/widgets/search/hybrid_search_results.dart';
import 'package:avrai/core/ai/event_logger.dart';
import 'package:avrai/injection_container.dart' as di;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

class HybridSearchPage extends StatefulWidget {
  const HybridSearchPage({super.key});

  @override
  State<HybridSearchPage> createState() => _HybridSearchPageState();
}

class _HybridSearchPageState extends State<HybridSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  bool _includeExternal = true;
  bool _reservationAvailable = false; // Reservation filter
  int _maxResults = 50;
  int _searchRadius = 5000;
  late EventLogger _eventLogger;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeEventLogger();
  }

  Future<void> _initializeEventLogger() async {
    try {
      _eventLogger = di.sl<EventLogger>();
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        await _eventLogger.initialize(userId: currentUser.id);
        _eventLogger.updateScreen('search');
      }
      _isInitialized = true;
    } catch (e) {
      // Event logging is non-critical, continue without it
      _isInitialized = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      context.read<HybridSearchBloc>().add(ClearHybridSearch());
      return;
    }

    final trimmedQuery = query.trim();

    // Log search performed (will log results count after search completes)
    if (_isInitialized) {
      _eventLogger.logSearchPerformed(
        query: trimmedQuery,
        resultsCount: 0, // Will be updated when results are available
      );
    }

    // Build filters if reservation filter is enabled
    final filters = _reservationAvailable
        ? const SearchFilters(reservationAvailable: true)
        : null;

    context.read<HybridSearchBloc>().add(
          SearchHybridSpots(
            query: trimmedQuery,
            includeExternal: _includeExternal,
            maxResults: _maxResults,
            filters: filters,
          ),
        );
  }

  void _searchNearby() async {
    try {
      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location services are disabled. Please enable them.'),
              backgroundColor: AppTheme.warningColor,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permissions are denied.'),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Location permissions are permanently denied. Please enable them in settings.'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition();

      if (mounted) {
        context.read<HybridSearchBloc>().add(
              SearchNearbyHybridSpots(
                latitude: position.latitude,
                longitude: position.longitude,
                radius: _searchRadius,
                includeExternal: _includeExternal,
                maxResults: _maxResults,
              ),
            );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hybrid Search'),
        actions: [
          IconButton(
            icon:
                Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header with OUR_GUTS.md Info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.grey100,
              border: Border(
                bottom: BorderSide(color: AppColors.grey200),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: AppColors.textSecondary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Community-First Search',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  'Per OUR_GUTS.md: Community spots are prioritized over external data sources for authentic, local knowledge.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for spots, places, or categories...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<HybridSearchBloc>()
                                    .add(ClearHybridSearch());
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onSubmitted: _performSearch,
                    onChanged: (value) {
                      setState(() {}); // Update to show/hide clear button
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _searchNearby,
                  icon: const Icon(Icons.near_me),
                  tooltip: 'Search nearby spots',
                  // Use default icon theme; keep it neutral
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    context.go('/group/formation');
                  },
                  icon: const Icon(Icons.group),
                  tooltip: 'Find with Friends',
                  // Use default icon theme; keep it neutral
                ),
              ],
            ),
          ),

          // Filters (if expanded)
          if (_showFilters) _buildFilters(),

          // Results
          const Expanded(
            child: HybridSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: AppColors.grey100,
        border: Border(
          bottom: BorderSide(color: AppColors.grey300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search Filters',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // External Data Toggle
          SwitchListTile(
            title: const Text('Include External Data'),
            subtitle: Text(
              _includeExternal
                  ? 'Google Places and OpenStreetMap included'
                  : 'Community data only',
            ),
            value: _includeExternal,
            onChanged: (value) {
              setState(() {
                _includeExternal = value;
              });
              context.read<HybridSearchBloc>().add(
                    ToggleExternalDataSources(value),
                  );
            },
            secondary: Icon(
              _includeExternal ? Icons.public : Icons.people,
              color: AppTheme.primaryColor,
            ),
          ),

          // Reservation Available Filter
          SwitchListTile(
            title: const Text('Reservations Available'),
            subtitle: const Text(
              'Show only spots that accept reservations',
            ),
            value: _reservationAvailable,
            onChanged: (value) {
              setState(() {
                _reservationAvailable = value;
              });
              // Re-search with new filter if there's a current query
              if (_searchController.text.trim().isNotEmpty) {
                _performSearch(_searchController.text);
              }
            },
            secondary: Icon(
              Icons.event_available,
              color: _reservationAvailable
                  ? AppTheme.primaryColor
                  : AppColors.textSecondary,
            ),
          ),

          // Max Results Slider
          ListTile(
            title: Text('Max Results: $_maxResults'),
            subtitle: Slider(
              value: _maxResults.toDouble(),
              min: 10,
              max: 100,
              divisions: 9,
              onChanged: (value) {
                setState(() {
                  _maxResults = value.round();
                });
              },
            ),
          ),

          // Search Radius for Nearby
          ListTile(
            title: Text(
                'Search Radius: ${(_searchRadius / 1000).toStringAsFixed(1)}km'),
            subtitle: Slider(
              value: _searchRadius.toDouble(),
              min: 1000,
              max: 50000,
              divisions: 49,
              onChanged: (value) {
                setState(() {
                  _searchRadius = value.round();
                });
              },
            ),
          ),

          // Quick Search Buttons
          const SizedBox(height: 8),
          Text(
            'Quick Search',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Coffee',
              'Restaurants',
              'Parks',
              'Museums',
              'Shopping',
              'Bars',
              'Hotels',
            ].map((category) {
              return ActionChip(
                label: Text(category),
                onPressed: () {
                  _searchController.text = category;
                  _performSearch(category);
                },
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
