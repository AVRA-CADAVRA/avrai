import 'package:flutter/material.dart';
import 'package:avrai/core/models/spot.dart';
import 'package:avrai/core/theme/colors.dart';
import 'package:avrai/core/theme/category_colors.dart';
import 'package:avrai/presentation/widgets/common/source_indicator_widget.dart';
import 'package:avrai/presentation/widgets/reservations/spot_reservation_badge_widget.dart';

class SpotCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool? isReservationAvailable;
  final bool? hasExistingReservation;
  final int? availableCapacity;
  final VoidCallback? onReservationTap;

  const SpotCard({
    super.key,
    required this.spot,
    this.onTap,
    this.trailing,
    this.isReservationAvailable,
    this.hasExistingReservation,
    this.availableCapacity,
    this.onReservationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(spot.category),
          child: Icon(
            CategoryStyles.iconFor(spot.category),
            color: AppColors.white,
          ),
        ),
        title: Text(spot.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(spot.description),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, size: 16, color: AppColors.grey600),
                Text(' ${spot.rating.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color:
                        _getCategoryColor(spot.category).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    spot.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getCategoryColor(spot.category),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: SourceIndicatorWidget(
                    indicator: spot.getSourceIndicator(),
                    compact: true,
                    showWarning: false,
                  ),
                ),
                if (isReservationAvailable != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: SpotReservationBadgeWidget(
                      isAvailable: isReservationAvailable!,
                      hasExistingReservation: hasExistingReservation ?? false,
                      availableCapacity: availableCapacity,
                      compact: true,
                      onTap: onReservationTap,
                    ),
                  ),
              ],
            ),
          ],
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Color _getCategoryColor(String category) => CategoryStyles.colorFor(category);

  // Icon handled by CategoryStyles.iconFor
}
