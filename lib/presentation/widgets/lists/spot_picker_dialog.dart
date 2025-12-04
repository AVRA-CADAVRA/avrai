import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/list.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';

class SpotPickerDialog extends StatefulWidget {
  final SpotList list;
  final List<String> excludedSpotIds;

  const SpotPickerDialog({
    super.key,
    required this.list,
    this.excludedSpotIds = const [],
  });

  @override
  State<SpotPickerDialog> createState() => _SpotPickerDialogState();
}

class _SpotPickerDialogState extends State<SpotPickerDialog> {
  final Set<String> _selectedSpotIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    // Load spots if not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpotsBloc>().add(LoadSpotsWithRespected());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSpotSelection(String spotId) {
    setState(() {
      if (_selectedSpotIds.contains(spotId)) {
        _selectedSpotIds.remove(spotId);
      } else {
        _selectedSpotIds.add(spotId);
      }
    });
  }

  void _addSelectedSpots() {
    if (_selectedSpotIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one spot'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    Navigator.pop(context, _selectedSpotIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Spots to ${widget.list.title}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_selectedSpotIds.length} selected',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.grey600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search spots...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // Spots List
            Expanded(
              child: BlocBuilder<SpotsBloc, SpotsState>(
                builder: (context, state) {
                  if (state is SpotsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SpotsError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: AppTheme.errorColor,
                          ),
                          const SizedBox(height: 16),
                          Text('Error: ${state.message}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<SpotsBloc>().add(LoadSpotsWithRespected());
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is SpotsLoaded) {
                    final allSpots = [...state.spots, ...state.respectedSpots];
                    
                    // Filter out spots already in list and excluded spots
                    final availableSpots = allSpots.where((spot) {
                      final isExcluded = widget.excludedSpotIds.contains(spot.id) ||
                          widget.list.spotIds.contains(spot.id);
                      if (isExcluded) return false;
                      
                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        return spot.name.toLowerCase().contains(_searchQuery) ||
                            spot.category.toLowerCase().contains(_searchQuery) ||
                            (spot.description.toLowerCase().contains(_searchQuery) ?? false) ||
                            (spot.address?.toLowerCase().contains(_searchQuery) ?? false);
                      }
                      return true;
                    }).toList();

                    if (availableSpots.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_off,
                              size: 64,
                              color: AppColors.grey400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No spots found matching "$_searchQuery"'
                                  : 'No spots available to add',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'Try a different search term'
                                  : 'Create spots first to add them to lists',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.grey600,
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: availableSpots.length,
                      itemBuilder: (context, index) {
                        final spot = availableSpots[index];
                        final isSelected = _selectedSpotIds.contains(spot.id);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _toggleSpotSelection(spot.id),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  // Checkbox
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (_) => _toggleSpotSelection(spot.id),
                                  ),
                                  const SizedBox(width: 12),
                                  // Spot Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          spot.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.category,
                                              size: 14,
                                              color: AppColors.grey600,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              spot.category,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color: AppColors.grey600,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        if (spot.address != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: AppColors.grey600,
                                              ),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  spot.address!,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: AppColors.grey600,
                                                      ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const Center(child: Text('No spots loaded'));
                },
              ),
            ),

            const Divider(height: 1),

            // Footer Actions
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addSelectedSpots,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppColors.white,
                    ),
                    child: Text(
                      'Add ${_selectedSpotIds.isEmpty ? '' : '(${_selectedSpotIds.length})'}',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

