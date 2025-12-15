import 'dart:convert';
import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';

class _CopyWithSentinel {
  const _CopyWithSentinel();
}

/// Expertise Community Model
/// Represents a community of experts in a specific category/location
class ExpertiseCommunity extends Equatable {
  final String id;
  final String category;
  final String? location; // e.g., "Brooklyn", "NYC", null for global
  final String name; // e.g., "Coffee Experts of Brooklyn"
  final String? description;
  final List<String> memberIds;
  final int memberCount;
  final ExpertiseLevel? minLevel; // Minimum level to join
  final bool isPublic;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;

  const ExpertiseCommunity({
    required this.id,
    required this.category,
    this.location,
    required this.name,
    this.description,
    this.memberIds = const [],
    this.memberCount = 0,
    this.minLevel,
    this.isPublic = true,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
  });

  /// Check if user can join this community
  bool canUserJoin(UnifiedUser user) {
    if (!isPublic) return false;
    
    if (!user.hasExpertiseIn(category)) return false;
    
    if (minLevel != null) {
      final userLevel = user.getExpertiseLevel(category);
      if (userLevel == null || userLevel.index < minLevel!.index) {
        return false;
      }
    }
    
    return true;
  }

  /// Check if user is a member
  bool isMember(UnifiedUser user) {
    return memberIds.contains(user.id);
  }

  /// Get display name
  String getDisplayName() {
    if (location != null) {
      return '$category Experts of $location';
    }
    return '$category Experts';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'location': location,
      'name': name,
      'description': description,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'minLevel': minLevel?.name,
      'isPublic': isPublic,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  /// Create from JSON
  factory ExpertiseCommunity.fromJson(Map<String, dynamic> json) {
    return ExpertiseCommunity(
      id: json['id'] as String,
      category: json['category'] as String,
      location: json['location'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
      memberCount: json['memberCount'] as int? ?? 0,
      minLevel: json['minLevel'] != null
          ? ExpertiseLevel.fromString(json['minLevel'] as String)
          : null,
      isPublic: json['isPublic'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      createdBy: json['createdBy'] as String,
    );
  }

  /// Copy with method
  ExpertiseCommunity copyWith({
    String? id,
    String? category,
    Object? location = const _CopyWithSentinel(),
    String? name,
    Object? description = const _CopyWithSentinel(),
    List<String>? memberIds,
    int? memberCount,
    Object? minLevel = const _CopyWithSentinel(),
    bool? isPublic,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    assert(() {
      // #region agent log
      try {
        const debugLogPath = '/Users/reisgordon/SPOTS/.cursor/debug.log';
        final payload = <String, dynamic>{
          'sessionId': 'debug-session',
          'runId': 'pre-fix',
          'hypothesisId': 'H-copyWith-null',
          'location': 'expertise_community.dart:copyWith',
          'message': 'copyWith called',
          'data': {
            'location_isSentinel': location is _CopyWithSentinel,
            'location_value': location is _CopyWithSentinel ? null : location,
          },
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
        File(debugLogPath).writeAsStringSync('${jsonEncode(payload)}\n', mode: FileMode.append);
      } catch (_) {}
      // #endregion
      return true;
    }());

    return ExpertiseCommunity(
      id: id ?? this.id,
      category: category ?? this.category,
      location: location is _CopyWithSentinel ? this.location : location as String?,
      name: name ?? this.name,
      description: description is _CopyWithSentinel ? this.description : description as String?,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      minLevel: minLevel is _CopyWithSentinel ? this.minLevel : minLevel as ExpertiseLevel?,
      isPublic: isPublic ?? this.isPublic,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  @override
  List<Object?> get props => [
        id,
        category,
        location,
        name,
        description,
        memberIds,
        memberCount,
        minLevel,
        isPublic,
        createdAt,
        updatedAt,
        createdBy,
      ];
}

