/// AI Improvement Impact Widget
/// 
/// Part of Feature Matrix Phase 2: Medium Priority UI/UX
/// Section 2.2: AI Self-Improvement Visibility
/// 
/// Widget explaining AI improvement impact:
/// - Explain improvement impact on user experience
/// - Show user benefits from improvements
/// - Transparency into AI evolution
/// - Real-world impact examples
/// 
/// Location: Settings/Account page
/// Uses AppColors and AppTheme for consistent styling per design token requirements.

import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/services/ai_improvement_tracking_service.dart';

/// Widget displaying AI improvement impact explanation
class AIImprovementImpactWidget extends StatelessWidget {
  /// User ID to show impact for
  final String userId;
  
  /// Improvement tracking service
  final AIImprovementTrackingService trackingService;
  
  const AIImprovementImpactWidget({
    super.key,
    required this.userId,
    required this.trackingService,
  });
  
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'AI Improvement Impact Explanation',
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildImpactSummary(),
              const SizedBox(height: 16),
              _buildBenefitsSection(),
              const SizedBox(height: 16),
              _buildTransparencySection(),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.electricGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.lightbulb_outline,
            color: AppColors.electricGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'What This Means for You',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildImpactSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.electricGreen.withValues(alpha: 0.1),
            AppColors.electricGreen.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.electricGreen.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.electricGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'AI Evolution Impact',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'As your AI improves, you experience:',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildImpactPoint(
            icon: Icons.recommend,
            title: 'Better Recommendations',
            description: 'More accurate spot suggestions matching your taste',
          ),
          _buildImpactPoint(
            icon: Icons.speed,
            title: 'Faster Responses',
            description: 'Quicker AI processing and instant suggestions',
          ),
          _buildImpactPoint(
            icon: Icons.psychology,
            title: 'Deeper Understanding',
            description: 'AI learns your preferences and patterns better',
          ),
        ],
      ),
    );
  }
  
  Widget _buildImpactPoint({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.electricGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: AppColors.electricGreen,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
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
  
  Widget _buildBenefitsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.card_giftcard,
              size: 18,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'Your Benefits',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          title: 'Personalization',
          description: 'AI adapts to your unique preferences',
          icon: Icons.person,
          color: AppColors.electricGreen,
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          title: 'Discovery',
          description: 'Find hidden gems that match your vibe',
          icon: Icons.explore,
          color: AppColors.primary,
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          title: 'Efficiency',
          description: 'Less time searching, more time enjoying',
          icon: Icons.flash_on,
          color: AppColors.warning,
        ),
        const SizedBox(height: 8),
        _buildBenefitCard(
          title: 'Community',
          description: 'Connect with like-minded people through AI',
          icon: Icons.people,
          color: AppColors.primary,
        ),
      ],
    );
  }
  
  Widget _buildBenefitCard({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
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
  
  Widget _buildTransparencySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(
              Icons.visibility,
              size: 18,
              color: AppColors.electricGreen,
            ),
            SizedBox(width: 8),
            Text(
              'Transparency & Control',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTransparencyPoint(
                icon: Icons.check_circle_outline,
                text: 'You always know what your AI is learning',
              ),
              const SizedBox(height: 10),
              _buildTransparencyPoint(
                icon: Icons.check_circle_outline,
                text: 'All improvements are privacy-preserving',
              ),
              const SizedBox(height: 10),
              _buildTransparencyPoint(
                icon: Icons.check_circle_outline,
                text: 'You control learning participation',
              ),
              const SizedBox(height: 10),
              _buildTransparencyPoint(
                icon: Icons.check_circle_outline,
                text: 'Progress tracked in real-time',
              ),
              const SizedBox(height: 16),
              Center(
                child: Semantics(
                  label: 'Navigate to privacy settings',
                  button: true,
                  child: TextButton.icon(
                    onPressed: () {
                      // Navigate to privacy settings
                    },
                    icon: const Icon(
                      Icons.settings,
                      size: 18,
                    ),
                    label: const Text('Privacy Settings'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.electricGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTransparencyPoint({
    required IconData icon,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.electricGreen,
          size: 18,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

