import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/theme/category_colors.dart';
import 'package:spots/presentation/blocs/spots/spots_bloc.dart';
import 'package:spots/presentation/pages/spots/create_spot_page.dart';
import 'package:spots/presentation/pages/spots/spot_details_page.dart';
import 'package:spots/presentation/widgets/spots/spot_card.dart';
import 'package:spots/presentation/widgets/common/offline_indicator.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/core/theme/colors.dart';

class SpotsPage extends StatefulWidget {
  const SpotsPage({super.key});

  @override
  State<SpotsPage> createState() => _SpotsPageState();
}

class _SpotsPageState extends State<SpotsPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load spots including respected lists
    context.read<SpotsBloc>().add(LoadSpotsWithRespected());
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    context.read<SpotsBloc>().add(SearchSpots(query: query));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spots'),
        actions: const [
          OfflineIndicator(),
          SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search spots...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
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
            child: _buildSpotsList(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSpotPage()),
          );
        },
        heroTag: 'spots_page_fab',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSpotsList(BuildContext context) {
    return BlocBuilder<SpotsBloc, SpotsState>(
      builder: (context, state) {
        if (state is SpotsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SpotsLoaded) {
          // Use filtered spots if search query exists, otherwise use all spots
          final spotsToShow = state.searchQuery != null && state.searchQuery!.isNotEmpty
              ? state.filteredSpots
              : [...state.spots, ...state.respectedSpots];

          if (spotsToShow.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    state.searchQuery != null && state.searchQuery!.isNotEmpty
                        ? Icons.search_off
                        : Icons.location_off,
                    size: 64,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    state.searchQuery != null && state.searchQuery!.isNotEmpty
                        ? 'No spots found matching "${state.searchQuery}"'
                        : 'No spots yet. Create your first spot!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (state.searchQuery != null && state.searchQuery!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        _searchController.clear();
                      },
                      child: const Text('Clear search'),
                    ),
                  ],
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: spotsToShow.length,
            itemBuilder: (context, index) {
              final spot = spotsToShow[index];
              return SpotCard(
                spot: spot,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SpotDetailsPage(spot: spot),
                    ),
                  );
                },
              );
            },
          );
        }

        if (state is SpotsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: AppTheme.errorColor),
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

        return const Center(child: Text('No spots loaded'));
      },
    );
  }

  Color _getCategoryColor(String category) => CategoryStyles.colorFor(category);

  IconData _getCategoryIcon(String category) => CategoryStyles.iconFor(category);
}
