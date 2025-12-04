import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:spots/presentation/pages/spots/spot_details_page.dart';
import 'package:spots/presentation/widgets/common/standard_error_widget.dart';
import 'package:spots/presentation/widgets/common/standard_loading_widget.dart';

class HybridSearchResults extends StatelessWidget {
  const HybridSearchResults({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HybridSearchBloc, HybridSearchState>(
      builder: (context, state) {
        if (state is HybridSearchInitial) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(
                  Icons.search,
                  size: 64,
                   color: AppColors.textSecondary,
                ),
                SizedBox(height: 16),
                Text(
                  'Search for spots',
                  style: TextStyle(
                    fontSize: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Find community spots and external places',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (state is HybridSearchLoading) {
          return StandardLoadingWidget.fullScreen(
            message: 'Searching community and external sources...',
          );
        }

        if (state is HybridSearchError) {
          return StandardErrorWidget.fullScreen(
            message: state.message,
            onRetry: () {
              context.read<HybridSearchBloc>().add(ClearHybridSearch());
            },
            retryLabel: 'Try Again',
          );
        }

        if (state is HybridSearchLoaded) {
          if (state.spots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.search_off,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No spots found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term or location',
                    style: const TextStyle(color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  _buildSearchStats(context, state),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Search Statistics Header
              _buildSearchStats(context, state),
              const SizedBox(height: 8),
              
              // Results List
              Expanded(
                child: ListView.builder(
                  itemCount: state.spots.length,
                  itemBuilder: (context, index) {
                    final spot = state.spots[index];
                    return _buildSpotCard(context, spot);
                  },
                ),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSearchStats(BuildContext context, HybridSearchLoaded state) {
    return Card(
      color: state.isCommunityPrioritized 
          ? AppColors.grey100 
          : AppColors.grey100,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  state.isCommunityPrioritized 
                      ? Icons.verified_user 
                      : Icons.warning_amber,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isCommunityPrioritized 
                            ? 'Community-First Results' 
                            : 'External Data Heavy',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${state.totalCount} total • ${state.communityCount} community • ${state.externalCount} external',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(state.searchDuration.inMilliseconds)}ms',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            if (state.sources.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: state.sources.entries.map((entry) {
                   return Chip(
                    label: Text(
                      '${entry.key}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                     backgroundColor: AppColors.grey100,
                     side: const BorderSide(color: AppColors.grey300),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSpotCard(BuildContext context, Spot spot) {
    final isExternal = spot.metadata.containsKey('is_external') && 
                      spot.metadata['is_external'] == true;
    final source = spot.metadata['source']?.toString() ?? 'community';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getSourceColor(source),
          child: Icon(
            _getSourceIcon(source),
            color: AppColors.white,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                spot.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildSourceBadge(source, isExternal),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              spot.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.grey200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    spot.category,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                if (spot.rating > 0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, size: 16, color: AppColors.grey600),
                  const SizedBox(width: 2),
                  Text(
                    '${spot.rating}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (spot.address != null) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      spot.address!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SpotDetailsPage(spot: spot),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSourceBadge(String source, bool isExternal) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getSourceColor(source).withValues(alpha: 0.1),
        border: Border.all(color: _getSourceColor(source), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getSourceDisplayName(source),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: _getSourceColor(source),
        ),
      ),
    );
  }

  Color _getSourceColor(String source) {
    switch (source.toLowerCase()) {
      case 'community':
        return AppTheme.successColor;
      case 'google_places':
        return AppColors.grey600;
      case 'openstreetmap':
      case 'osm':
        return AppColors.warning;
      default:
        return AppColors.grey600;
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source.toLowerCase()) {
      case 'community':
        return Icons.people;
      case 'google_places':
        return Icons.business;
      case 'openstreetmap':
      case 'osm':
        return Icons.map;
      default:
        return Icons.place;
    }
  }

  String _getSourceDisplayName(String source) {
    switch (source.toLowerCase()) {
      case 'community':
        return 'Community';
      case 'google_places':
        return 'Google';
      case 'openstreetmap':
      case 'osm':
        return 'OSM';
      default:
        return source.toUpperCase();
    }
  }
}