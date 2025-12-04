import 'package:flutter/material.dart';
import 'package:spots/core/models/business_account.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/business_patron_preferences.dart';
import 'package:spots/core/services/user_business_matching_service.dart';
import 'package:spots/core/theme/colors.dart';

/// Business Compatibility Widget
/// Shows users how well they match a specific business's patron preferences
/// Helps users understand what vibes and qualities the business is looking for
class BusinessCompatibilityWidget extends StatelessWidget {
  final BusinessAccount business;
  final UnifiedUser user;

  const BusinessCompatibilityWidget({
    super.key,
    required this.business,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BusinessCompatibilityScore>(
      future: _getCompatibilityScore(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: AppColors.error),
            ),
          );
        }

        final score = snapshot.data;
        if (score == null) {
          return const SizedBox.shrink();
        }

        return _buildCompatibilityCard(score);
      },
    );
  }

  Future<BusinessCompatibilityScore> _getCompatibilityScore() async {
    final service = UserBusinessMatchingService();
    return await service.getUserCompatibilityScore(user, business);
  }

  Widget _buildCompatibilityCard(BusinessCompatibilityScore score) {
    final isGoodMatch = score.isGoodMatch;
    final preferences = business.patronPreferences;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.people,
                  color: AppColors.electricGreen,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Your Compatibility',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isGoodMatch
                        ? AppColors.electricGreen.withValues(alpha: 0.1)
                        : AppColors.grey200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${score.percentageScore}%',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isGoodMatch
                          ? AppColors.electricGreen
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (preferences != null) ...[
              // What the business is looking for
              _buildSectionTitle('What ${business.name} is Looking For'),
              const SizedBox(height: 8),
              
              if (preferences.preferredVibePreferences?.isNotEmpty == true) ...[
                _buildInfoRow(
                  icon: Icons.mood,
                  label: 'Vibe',
                  value: preferences.preferredVibePreferences!.join(', '),
                ),
                const SizedBox(height: 8),
              ],
              
              if (preferences.preferredInterests?.isNotEmpty == true) ...[
                _buildInfoRow(
                  icon: Icons.favorite,
                  label: 'Interests',
                  value: preferences.preferredInterests!.take(3).join(', '),
                ),
                const SizedBox(height: 8),
              ],
              
              if (preferences.preferredPersonalityTraits?.isNotEmpty == true) ...[
                _buildInfoRow(
                  icon: Icons.person,
                  label: 'Personality',
                  value: preferences.preferredPersonalityTraits!.take(3).join(', '),
                ),
                const SizedBox(height: 8),
              ],
              
              if (preferences.preferredSpendingLevel != null) ...[
                _buildInfoRow(
                  icon: Icons.attach_money,
                  label: 'Spending Level',
                  value: preferences.preferredSpendingLevel?.displayName ?? 'Not specified',
                ),
                const SizedBox(height: 8),
              ],
              
              if (preferences.preferLocalPatrons || preferences.preferTourists) ...[
                _buildInfoRow(
                  icon: Icons.location_on,
                  label: 'Location Preference',
                  value: preferences.preferLocalPatrons
                      ? 'Local Patrons'
                      : 'Tourists Welcome',
                ),
                const SizedBox(height: 8),
              ],
              
              if (preferences.preferCommunityMembers) ...[
                _buildInfoRow(
                  icon: Icons.group,
                  label: 'Community',
                  value: 'Prefers Community Members',
                ),
                const SizedBox(height: 8),
              ],
              
              const SizedBox(height: 16),
            ],
            
            // How you match
            _buildSectionTitle('How You Match'),
            const SizedBox(height: 8),
            
            if (score.matchedCriteria.isNotEmpty) ...[
              ...score.matchedCriteria.map((criterion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 20,
                      color: AppColors.electricGreen,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        criterion,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ] else ...[
              const Text(
                'Complete your profile to see how you match',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            
            if (score.missingCriteria.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('What You\'re Missing'),
              const SizedBox(height: 8),
              ...score.missingCriteria.take(3).map((criterion) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        criterion,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            if (preferences?.aiMatchingPrompt != null) ...[
              const SizedBox(height: 16),
              _buildSectionTitle('What They Say'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  preferences!.aiMatchingPrompt!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

