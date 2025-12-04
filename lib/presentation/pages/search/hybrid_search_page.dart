import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:spots/presentation/widgets/search/hybrid_search_results.dart';

class HybridSearchPage extends StatefulWidget {
  const HybridSearchPage({super.key});

  @override
  State<HybridSearchPage> createState() => _HybridSearchPageState();
}

class _HybridSearchPageState extends State<HybridSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;
  bool _includeExternal = true;
  int _maxResults = 50;
  int _searchRadius = 5000;

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

    context.read<HybridSearchBloc>().add(
      SearchHybridSpots(
        query: query.trim(),
        includeExternal: _includeExternal,
        maxResults: _maxResults,
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
            SnackBar(
              content: const Text('Location services are disabled. Please enable them.'),
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
              SnackBar(
                content: const Text('Location permissions are denied.'),
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
              SnackBar(
                content: const Text('Location permissions are permanently denied. Please enable them in settings.'),
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
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
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
            decoration: BoxDecoration(
              color: AppColors.grey100,
              border: Border(
                bottom: BorderSide(color: AppColors.grey200),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 8),
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
                const SizedBox(height: 4),
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
                                context.read<HybridSearchBloc>().add(ClearHybridSearch());
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
      decoration: BoxDecoration(
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
            title: Text('Search Radius: ${(_searchRadius / 1000).toStringAsFixed(1)}km'),
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