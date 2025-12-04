import 'package:flutter/material.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/services/business_expert_matching_service.dart';
import 'package:spots/core/theme/colors.dart';

/// Business Expert Matching Widget
/// Displays expert matches for a business account
class BusinessExpertMatchingWidget extends StatelessWidget {
  final BusinessAccount business;
  final Function(UnifiedUser)? onExpertSelected;
  final Function(BusinessExpertMatch)? onMatchSelected;

  const BusinessExpertMatchingWidget({
    super.key,
    required this.business,
    this.onExpertSelected,
    this.onMatchSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<BusinessExpertMatch>>(
      future: _getMatches(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
            ),
          );
        }

        final matches = snapshot.data ?? [];
        
        if (matches.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(matches.length),
            const SizedBox(height: 8),
            _buildMatchesList(matches),
          ],
        );
      },
    );
  }

  Future<List<BusinessExpertMatch>> _getMatches() async {
    final service = BusinessExpertMatchingService();
    return await service.findExpertsForBusiness(business);
  }

  Widget _buildHeader(int count) {
    return Row(
      children: [
        const Text(
          'Expert Matches',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.grey200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'No expert matches found',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try updating your required expertise or preferred communities',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMatchesList(List<BusinessExpertMatch> matches) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return _buildMatchCard(matches[index]);
      },
    );
  }

  Widget _buildMatchCard(BusinessExpertMatch match) {
    final expert = match.expert;
    final matchTypeIcon = _getMatchTypeIcon(match.matchType);
    final matchTypeColor = _getMatchTypeColor(match.matchType);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          onExpertSelected?.call(expert);
          onMatchSelected?.call(match);
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.grey200,
                    radius: 24,
                    child: expert.photoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              expert.photoUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Text(
                            (expert.displayName ?? expert.email)[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          expert.displayName ?? expert.email,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (expert.location != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                expert.location!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: matchTypeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(matchTypeIcon, size: 14, color: matchTypeColor),
                        const SizedBox(width: 4),
                        Text(
                          '${(match.matchScore * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: matchTypeColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                match.matchReason,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (match.matchedCategories.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: match.matchedCategories.map((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.electricGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.electricGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              if (match.matchedCommunities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.group,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${match.matchedCommunities.length} community match${match.matchedCommunities.length > 1 ? 'es' : ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      onExpertSelected?.call(expert);
                      onMatchSelected?.call(match);
                    },
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View Profile'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.electricGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Handle connection request
                      _requestConnection(match);
                    },
                    icon: const Icon(Icons.person_add, size: 16),
                    label: const Text('Connect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricGreen,
                      foregroundColor: AppColors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMatchTypeIcon(MatchType type) {
    switch (type) {
      case MatchType.expertise:
        return Icons.star;
      case MatchType.community:
        return Icons.group;
      case MatchType.aiSuggestion:
        return Icons.auto_awesome;
    }
  }

  Color _getMatchTypeColor(MatchType type) {
    switch (type) {
      case MatchType.expertise:
        return AppColors.electricGreen;
      case MatchType.community:
        return AppColors.electricGreen;
      case MatchType.aiSuggestion:
        return AppColors.grey600;
    }
  }

  void _requestConnection(BusinessExpertMatch match) {
    // In production, this would call the business account service
    // to request a connection with the expert
  }
}

