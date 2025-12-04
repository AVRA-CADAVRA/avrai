import 'package:flutter/material.dart';
import 'package:spots/core/models/brand_discovery.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/app_theme.dart';
import 'package:spots/presentation/widgets/partnerships/compatibility_badge.dart';

/// Sponsorable Event Card Widget
/// 
/// Displays an event that can be sponsored, with compatibility information.
/// Shows vibe matching scores and match reasons.
/// 
/// **CRITICAL:** Uses AppColors/AppTheme (100% adherence required)
class SponsorableEventCard extends StatelessWidget {
  final BrandMatch brandMatch;
  final VoidCallback? onTap;
  final VoidCallback? onPropose;
  
  const SponsorableEventCard({
    super.key,
    required this.brandMatch,
    this.onTap,
    this.onPropose,
  });
  
  @override
  Widget build(BuildContext context) {
    final compatibility = brandMatch.vibeCompatibility;
    final meetsThreshold = brandMatch.meetsThreshold; // 70%+ check
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Compatibility Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CompatibilityBadge(
                    compatibility: compatibility.overallScore / 100.0,
                  ),
                  if (meetsThreshold)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.electricGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 16, color: AppColors.electricGreen),
                          const SizedBox(width: 4),
                          Text(
                            'Recommended',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.electricGreen,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Event Title
              Text(
                brandMatch.metadata['eventTitle'] as String? ?? 'Event',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Host Info
              if (brandMatch.metadata['hostName'] != null)
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'By ${brandMatch.metadata['hostName']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              
              const SizedBox(height: 12),
              
              // Compatibility Breakdown
              if (meetsThreshold) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Match Score: ${compatibility.overallScore.toStringAsFixed(0)}% ⭐',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.electricGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildCompatibilityRow('Value Alignment', compatibility.valueAlignment),
                      _buildCompatibilityRow('Style Compatibility', compatibility.styleCompatibility),
                      _buildCompatibilityRow('Quality Focus', compatibility.qualityFocus),
                      _buildCompatibilityRow('Audience Alignment', compatibility.audienceAlignment),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Match Reasons
              if (brandMatch.matchReasons.isNotEmpty) ...[
                ...brandMatch.matchReasons.take(3).map((reason) => Padding(
                      padding: const EdgeInsets.only(left: 8, top: 2),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, size: 14, color: AppColors.electricGreen),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 12),
              ],
              
              // Estimated Contribution
              if (brandMatch.estimatedContribution != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 16, color: AppTheme.primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated: \$${brandMatch.estimatedContribution!.minAmount.toStringAsFixed(0)} - \$${brandMatch.estimatedContribution!.maxAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(color: AppColors.grey300),
                      ),
                      child: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: meetsThreshold ? onPropose : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Propose Sponsorship'),
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
  
  Widget _buildCompatibilityRow(String label, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

