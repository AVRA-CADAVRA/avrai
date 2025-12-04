import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:spots/core/theme/colors.dart';
import 'expertise_level.dart';

/// Expertise Pin Model
/// OUR_GUTS.md: "Pins, Not Badges" - Expertise recognition tied to subjects and areas
class ExpertisePin extends Equatable {
  final String id;
  final String userId;
  final String category; // e.g., "Coffee", "Thai Food", "Bookstores"
  final ExpertiseLevel level;
  final String? location; // e.g., "Brooklyn", "NYC", null for Global/Universal
  final DateTime earnedAt;
  final String earnedReason; // e.g., "Created 5 respected lists"
  final int contributionCount; // Number of contributions that earned this pin
  final double communityTrustScore; // 0.0 to 1.0, based on community respect
  final List<String> unlockedFeatures; // Features unlocked by this pin

  const ExpertisePin({
    required this.id,
    required this.userId,
    required this.category,
    required this.level,
    this.location,
    required this.earnedAt,
    required this.earnedReason,
    this.contributionCount = 0,
    this.communityTrustScore = 0.0,
    this.unlockedFeatures = const [],
  });

  /// Get pin color based on category
  /// Returns category-specific colors for visual distinction
  /// CRITICAL: Uses AppColors (100% adherence required)
  Color getPinColor() {
    // Category-specific color mapping using AppColors
    final categoryColors = {
      'Coffee': AppColors.grey700, // Brown -> grey700
      'Restaurants': AppColors.error, // Red -> error
      'Bookstores': AppColors.electricGreen, // Blue -> electricGreen
      'Parks': AppColors.electricGreen, // Green -> electricGreen
      'Museums': AppColors.grey600, // Purple -> grey600
      'Shopping': AppColors.grey500, // Pink -> grey500
      'Bars': AppColors.warning, // Amber -> warning
      'Hotels': AppColors.grey400, // Teal -> grey400
      'Thai Food': AppColors.warning, // Orange -> warning
      'Vintage': AppColors.grey600, // Indigo -> grey600
    };

    return categoryColors[category] ?? AppColors.grey500;
  }

  /// Get pin icon based on category
  IconData getPinIcon() {
    final categoryIcons = {
      'Coffee': Icons.local_cafe,
      'Restaurants': Icons.restaurant,
      'Bookstores': Icons.menu_book,
      'Parks': Icons.park,
      'Museums': Icons.museum,
      'Shopping': Icons.shopping_bag,
      'Bars': Icons.local_bar,
      'Hotels': Icons.hotel,
      'Thai Food': Icons.ramen_dining,
      'Vintage': Icons.store,
    };

    return categoryIcons[category] ?? Icons.place;
  }

  /// Get display title for the pin
  String getDisplayTitle() {
    final locationText = location != null ? ' in $location' : '';
    return '$category Expert$locationText';
  }

  /// Get full description with level
  String getFullDescription() {
    return '${level.emoji} ${level.displayName} Level - $category${
      location != null ? ' ($location)' : ''
    }';
  }

  /// Check if pin unlocks event hosting (requires Local level or higher)
  bool unlocksEventHosting() {
    return level.index >= ExpertiseLevel.local.index;
  }

  /// Check if pin unlocks expert validation
  bool unlocksExpertValidation() {
    return level.index >= ExpertiseLevel.regional.index;
  }

  /// Create from expertise map entry
  factory ExpertisePin.fromMapEntry({
    required String userId,
    required String category,
    required String levelString,
    String? location,
    DateTime? earnedAt,
    String? earnedReason,
  }) {
    final level = ExpertiseLevel.fromString(levelString) ?? ExpertiseLevel.local;
    
    return ExpertisePin(
      id: '${userId}_${category}_${level.name}',
      userId: userId,
      category: category,
      level: level,
      location: location,
      earnedAt: earnedAt ?? DateTime.now(),
      earnedReason: earnedReason ?? 'Earned through community contributions',
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'category': category,
      'level': level.name,
      'location': location,
      'earnedAt': earnedAt.toIso8601String(),
      'earnedReason': earnedReason,
      'contributionCount': contributionCount,
      'communityTrustScore': communityTrustScore,
      'unlockedFeatures': unlockedFeatures,
    };
  }

  /// Create from JSON
  factory ExpertisePin.fromJson(Map<String, dynamic> json) {
    return ExpertisePin(
      id: json['id'] as String,
      userId: json['userId'] as String,
      category: json['category'] as String,
      level: ExpertiseLevel.fromString(json['level'] as String?) ?? ExpertiseLevel.local,
      location: json['location'] as String?,
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      earnedReason: json['earnedReason'] as String,
      contributionCount: json['contributionCount'] as int? ?? 0,
      communityTrustScore: (json['communityTrustScore'] as num?)?.toDouble() ?? 0.0,
      unlockedFeatures: List<String>.from(json['unlockedFeatures'] as List? ?? []),
    );
  }

  /// Copy with method
  ExpertisePin copyWith({
    String? id,
    String? userId,
    String? category,
    ExpertiseLevel? level,
    String? location,
    DateTime? earnedAt,
    String? earnedReason,
    int? contributionCount,
    double? communityTrustScore,
    List<String>? unlockedFeatures,
  }) {
    return ExpertisePin(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      level: level ?? this.level,
      location: location ?? this.location,
      earnedAt: earnedAt ?? this.earnedAt,
      earnedReason: earnedReason ?? this.earnedReason,
      contributionCount: contributionCount ?? this.contributionCount,
      communityTrustScore: communityTrustScore ?? this.communityTrustScore,
      unlockedFeatures: unlockedFeatures ?? this.unlockedFeatures,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        category,
        level,
        location,
        earnedAt,
        earnedReason,
        contributionCount,
        communityTrustScore,
        unlockedFeatures,
      ];
}

