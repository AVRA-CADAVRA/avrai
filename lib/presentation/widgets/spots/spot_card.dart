import 'package:flutter/material.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/theme/category_colors.dart';

class SpotCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback? onTap;
  final Widget? trailing;

  const SpotCard({
    super.key,
    required this.spot,
    this.onTap,
    this.trailing,
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
                Icon(Icons.star, size: 16, color: AppColors.grey600),
                Text(' ${spot.rating.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                   decoration: BoxDecoration(
                     color: _getCategoryColor(spot.category).withValues(alpha: 0.2),
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
