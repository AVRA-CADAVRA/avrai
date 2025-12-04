import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'package:spots/core/models/spot.dart';

class SpotMarker extends StatelessWidget {
  final Spot spot;
  final Color color;
  final VoidCallback? onTap;

  const SpotMarker({
    super.key,
    required this.spot,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.white,
            width: 2,
          ),
        ),
        child: Icon(
          _getCategoryIcon(spot.category),
          color: AppColors.white,
          size: 16,
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'coffee':
        return Icons.coffee;
      case 'bakery':
        return Icons.cake;
      case 'park':
        return Icons.park;
      case 'restaurant':
        return Icons.restaurant;
      case 'attraction':
        return Icons.attractions;
      default:
        return Icons.place;
    }
  }
}
