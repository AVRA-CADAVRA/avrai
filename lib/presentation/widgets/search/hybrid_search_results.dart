import 'package:flutter/material.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/presentation/blocs/search/hybrid_search_bloc.dart';
import 'package:avrai/presentation/pages/spots/spot_details_page.dart';
import 'package:avrai/presentation/widgets/common/standard_error_widget.dart';
import 'package:avrai/presentation/widgets/common/standard_loading_widget.dart';
import 'package:avrai/presentation/widgets/common/source_indicator_widget.dart';
import 'package:avrai/presentation/widgets/reservations/spot_reservation_badge_widget.dart';
import 'package:avrai/core/models/reservation.dart';
import 'package:go_router/go_router.dart';

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
                  const Text(
                    'Try a different search term or location',
                    style: TextStyle(color: AppColors.textSecondary),
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
      color:
          state.isCommunityPrioritized ? AppColors.grey100 : AppColors.grey100,
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
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${state.totalCount} total • ${state.communityCount} community • ${state.externalCount} external',
                        style: const TextStyle(
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
    final indicator = spot.getSourceIndicator();
    // Check if spot accepts reservations (community spots can, external spots can't)
    final isReservable = !spot.metadata.containsKey('is_external') ||
        spot.metadata['is_external'] != true;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: indicator.badgeColor,
          child: Icon(
            indicator.badgeIcon,
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
            // Use SourceIndicator for consistent source display
            SourceIndicatorWidget(
              indicator: indicator,
              compact: true,
              showWarning: false,
            ),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                  const Icon(Icons.location_on,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 2),
                  Expanded(
                    child: Text(
                      spot.address!,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
            // Reservation badge
            if (isReservable) ...[
              const SizedBox(height: 8),
              SpotReservationBadgeWidget(
                isAvailable: true,
                compact: true,
                onTap: () {
                  // Quick reservation action
                  context.push(
                    '/reservations/create',
                    extra: {
                      'type': ReservationType.spot,
                      'targetId': spot.id,
                      'targetTitle': spot.name,
                    },
                  );
                },
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quick reservation button (if reservable)
            if (isReservable)
              IconButton(
                icon: const Icon(Icons.event_available, size: 20),
                tooltip: 'Quick Reserve',
                onPressed: () {
                  context.push(
                    '/reservations/create',
                    extra: {
                      'type': ReservationType.spot,
                      'targetId': spot.id,
                      'targetTitle': spot.name,
                    },
                  );
                },
              ),
            const Icon(Icons.chevron_right),
          ],
        ),
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
}
