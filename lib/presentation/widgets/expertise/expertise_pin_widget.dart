import 'package:flutter/material.dart';
import 'package:spots/core/models/expertise_pin.dart';
import 'package:spots/core/theme/colors.dart';

/// Expertise Pin Widget
/// Displays a visual pin representing user expertise
/// OUR_GUTS.md: "Pins, Not Badges" - Visual recognition without gamification
class ExpertisePinWidget extends StatelessWidget {
  final ExpertisePin pin;
  final bool showDetails;
  final VoidCallback? onTap;

  const ExpertisePinWidget({
    super.key,
    required this.pin,
    this.showDetails = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pinColor = pin.getPinColor();
    final pinIcon = pin.getPinIcon();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: pinColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: pinColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pin Icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: pinColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                pinIcon,
                size: 16,
                color: pinColor,
              ),
            ),
            const SizedBox(width: 8),
            // Category and Level
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pin.category,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (showDetails) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        pin.level.emoji,
                        style: const TextStyle(fontSize: 10),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${pin.level.displayName} Level',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (pin.location != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          '• ${pin.location}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Expertise Pin Gallery Widget
/// Displays multiple pins in a gallery format
class ExpertisePinGallery extends StatelessWidget {
  final List<ExpertisePin> pins;
  final int maxDisplay;
  final bool expandable;

  const ExpertisePinGallery({
    super.key,
    required this.pins,
    this.maxDisplay = 3,
    this.expandable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (pins.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayPins = expandable && pins.length > maxDisplay
        ? pins.take(maxDisplay).toList()
        : pins;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayPins.map((pin) => ExpertisePinWidget(pin: pin)),
        if (expandable && pins.length > maxDisplay)
          _buildMorePinsChip(pins.length - maxDisplay),
      ],
    );
  }

  Widget _buildMorePinsChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.grey300),
      ),
      child: Text(
        '+$count more',
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Expertise Pin Detail Card
/// Shows full details of a pin
class ExpertisePinDetailCard extends StatelessWidget {
  final ExpertisePin pin;

  const ExpertisePinDetailCard({
    super.key,
    required this.pin,
  });

  @override
  Widget build(BuildContext context) {
    final pinColor = pin.getPinColor();
    final pinIcon = pin.getPinIcon();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: pinColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    pinIcon,
                    size: 24,
                    color: pinColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pin.category,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        pin.getFullDescription(),
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            // Details
            _buildDetailRow('Earned', pin.earnedAt.toString().split(' ')[0]),
            _buildDetailRow('Reason', pin.earnedReason),
            if (pin.contributionCount > 0)
              _buildDetailRow('Contributions', '${pin.contributionCount}'),
            if (pin.unlockedFeatures.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Unlocked Features:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: pin.unlockedFeatures.map((feature) {
                  return Chip(
                    label: Text(
                      feature.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 10),
                    ),
                    backgroundColor: AppColors.grey100,
                    side: BorderSide(color: AppColors.grey300),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

