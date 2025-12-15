import 'package:spots/core/models/spot.dart';

class _Sentinel {
  const _Sentinel();
}

class SpotList {
  final String id;
  final String title;
  final String description;
  final List<Spot> spots;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? category;
  final bool isPublic;
  final List<String> spotIds;
  final int respectCount;
  // Legacy optional fields expected by tests
  final List<String> collaborators;
  final List<String> followers;
  final String? curatorId;
  final List<String> tags;
  final bool ageRestricted;
  final bool moderationEnabled;
  final Map<String, dynamic> metadata;

  const SpotList({
    required this.id,
    String? title,
    String? name,
    required this.description,
    required this.spots,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.isPublic = true,
    this.spotIds = const [],
    this.respectCount = 0,
    this.collaborators = const [],
    this.followers = const [],
    this.curatorId,
    this.tags = const [],
    this.ageRestricted = false,
    this.moderationEnabled = false,
    this.metadata = const {},
  }) : title = title ?? name ?? '';

  SpotList copyWith({
    String? id,
    String? title,
    String? description,
    List<Spot>? spots,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? category = const _Sentinel(),
    bool? isPublic,
    List<String>? spotIds,
    int? respectCount,
    Object? curatorId = const _Sentinel(),
    List<String>? tags,
    bool? ageRestricted,
    bool? moderationEnabled,
    Map<String, dynamic>? metadata,
  }) {
    return SpotList(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      spots: spots ?? this.spots,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category is _Sentinel ? this.category : category as String?,
      isPublic: isPublic ?? this.isPublic,
      spotIds: spotIds ?? this.spotIds,
      respectCount: respectCount ?? this.respectCount,
      curatorId: curatorId is _Sentinel ? this.curatorId : curatorId as String?,
      tags: tags ?? this.tags,
      ageRestricted: ageRestricted ?? this.ageRestricted,
      moderationEnabled: moderationEnabled ?? this.moderationEnabled,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'spots': spots.map((spot) => spot.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'category': category,
      'isPublic': isPublic,
      'spotIds': spotIds,
      'respectCount': respectCount,
      'curatorId': curatorId,
      'tags': tags,
      'ageRestricted': ageRestricted,
      'moderationEnabled': moderationEnabled,
      'metadata': metadata,
    };
  }

  factory SpotList.fromJson(Map<String, dynamic> json) {
    return SpotList(
      id: json['id'] ?? '',
      title: json['title'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      spots: (json['spots'] as List<dynamic>?)
          ?.map((spotJson) => Spot.fromJson(spotJson))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      category: json['category'],
      isPublic: json['isPublic'] ?? true,
      spotIds: List<String>.from(json['spotIds'] ?? []),
      respectCount: json['respectCount'] ?? 0,
      curatorId: json['curatorId'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      ageRestricted: json['ageRestricted'] ?? false,
      moderationEnabled: json['moderationEnabled'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // Convenience methods
  Map<String, dynamic> toMap() => toJson();
  factory SpotList.fromMap(Map<String, dynamic> map) => SpotList.fromJson(map);
}
