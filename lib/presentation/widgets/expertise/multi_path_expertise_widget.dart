import 'package:flutter/material.dart';
import 'package:spots/core/models/multi_path_expertise.dart';
import 'package:spots/core/theme/colors.dart';

/// Multi-Path Expertise Widget
/// 
/// Displays expertise breakdown across all 6 paths to expertise.
/// Shows progress for each path and overall weighted score.
/// 
/// **Philosophy Alignment:**
/// - Opens doors to expertise through multiple paths
/// - Recognizes different types of expertise
/// - Supports diverse ways to become an expert
/// 
/// **Path Weights:**
/// - Exploration (40%): Visits, reviews, check-ins
/// - Credentials (25%): Degrees, certifications
/// - Influence (20%): Followers, shares, lists
/// - Professional (25%): Proof of work
/// - Community (15%): Contributions, endorsements
/// - Local (varies): Locality-based expertise
class MultiPathExpertiseWidget extends StatelessWidget {
  final ExplorationExpertise? exploration;
  final CredentialExpertise? credential;
  final InfluenceExpertise? influence;
  final ProfessionalExpertise? professional;
  final CommunityExpertise? community;
  final LocalExpertise? local;
  final double totalScore;
  final bool showDetails;

  const MultiPathExpertiseWidget({
    super.key,
    this.exploration,
    this.credential,
    this.influence,
    this.professional,
    this.community,
    this.local,
    required this.totalScore,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Expertise Paths',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.electricGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${(totalScore * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Path breakdown
          if (exploration != null)
            _buildPathCard(
              title: 'Exploration',
              weight: '40%',
              score: exploration!.score,
              icon: Icons.explore,
              color: AppColors.electricGreen,
              details: showDetails
                  ? '${exploration!.totalVisits} visits, ${exploration!.reviewsGiven} reviews'
                  : null,
            ),
          if (credential != null)
            _buildPathCard(
              title: 'Credentials',
              weight: '25%',
              score: credential!.score,
              icon: Icons.school,
              color: AppColors.primaryBlue,
              details: showDetails
                  ? '${credential!.degrees.length} degrees, ${credential!.certifications.length} certifications'
                  : null,
            ),
          if (influence != null)
            _buildPathCard(
              title: 'Influence',
              weight: '20%',
              score: influence!.score,
              icon: Icons.trending_up,
              color: AppColors.warning,
              details: showDetails
                  ? '${influence!.spotsFollowers} followers, ${influence!.curatedLists} lists'
                  : null,
            ),
          if (professional != null)
            _buildPathCard(
              title: 'Professional',
              weight: '25%',
              score: professional!.score,
              icon: Icons.work,
              color: AppColors.primaryBlue,
              details: showDetails
                  ? '${professional!.roles.length} roles, ${professional!.peerEndorsements.length} endorsements'
                  : null,
            ),
          if (community != null)
            _buildPathCard(
              title: 'Community',
              weight: '15%',
              score: community!.score,
              icon: Icons.people,
              color: AppColors.electricGreen,
              details: showDetails
                  ? '${community!.questionsAnswered} answers, ${community!.eventsHosted} events'
                  : null,
            ),
          if (local != null)
            _buildPathCard(
              title: 'Local',
              weight: 'Varies',
              score: local!.score,
              icon: Icons.location_on,
              color: AppColors.warning,
              details: showDetails
                  ? '${local!.localVisits} local visits, ${local!.locality}'
                  : null,
              isGolden: local!.isGoldenLocalExpert,
            ),
        ],
      ),
    );
  }

  Widget _buildPathCard({
    required String title,
    required String weight,
    required double score,
    required IconData icon,
    required Color color,
    String? details,
    bool isGolden = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Title and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (isGolden) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const Text(
                        'Golden',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      weight,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (details != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    details,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppColors.grey200,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(score * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact Multi-Path Expertise Widget
/// Smaller version for use in lists/cards
class CompactMultiPathExpertiseWidget extends StatelessWidget {
  final double totalScore;
  final int activePaths;

  const CompactMultiPathExpertiseWidget({
    super.key,
    required this.totalScore,
    required this.activePaths,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 14,
            color: AppColors.electricGreen,
          ),
          const SizedBox(width: 4),
          Text(
            '${(totalScore * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($activePaths paths)',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

