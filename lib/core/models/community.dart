import 'package:equatable/equatable.dart';

/// Community Model
/// 
/// Represents communities that form from events (people who attend together).
/// 
/// **Philosophy Alignment:**
/// - Events naturally create communities (doors open from events)
/// - Communities form organically from successful events
/// - People find their communities through events
/// - Communities can organize as clubs when structure is needed
/// 
/// **Key Features:**
/// - Links to originating event (CommunityEvent or ExpertiseEvent)
/// - Tracks members (people who attended events)
/// - Tracks events hosted by community
/// - Tracks growth metrics (member growth, event growth)
/// - Stores community metrics (engagement, diversity, activity)
/// - Geographic tracking (original locality, current localities)
/// 
/// **Note:** This is different from `ExpertiseCommunity` (expertise-based communities).
/// This is about communities that form from events, not expertise requirements.
enum OriginatingEventType {
  communityEvent,
  expertiseEvent,
}

enum ActivityLevel {
  active,
  growing,
  stable,
  declining,
}

class Community extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String category;
  
  /// Link to originating event
  final String originatingEventId;
  final OriginatingEventType originatingEventType;
  
  /// Track members
  final List<String> memberIds;
  final int memberCount;
  final String founderId; // Event host who created the community
  
  /// Track events
  final List<String> eventIds;
  final int eventCount;
  
  /// Track growth
  final double memberGrowthRate; // Growth rate of members (0.0 to 1.0)
  final double eventGrowthRate; // Growth rate of events (0.0 to 1.0)
  final DateTime createdAt;
  final DateTime? lastEventAt;
  
  /// Store community metrics
  final double engagementScore; // Community engagement (0.0 to 1.0)
  final double diversityScore; // Member diversity (0.0 to 1.0)
  final ActivityLevel activityLevel;
  
  /// Geographic tracking
  final String originalLocality; // Original locality where community formed
  final List<String> currentLocalities; // List of localities where community is active
  
  final DateTime updatedAt;

  const Community({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.originatingEventId,
    required this.originatingEventType,
    this.memberIds = const [],
    this.memberCount = 0,
    required this.founderId,
    this.eventIds = const [],
    this.eventCount = 0,
    this.memberGrowthRate = 0.0,
    this.eventGrowthRate = 0.0,
    required this.createdAt,
    this.lastEventAt,
    this.engagementScore = 0.0,
    this.diversityScore = 0.0,
    this.activityLevel = ActivityLevel.active,
    required this.originalLocality,
    this.currentLocalities = const [],
    required this.updatedAt,
  });

  /// Check if user is a member
  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  /// Check if user is the founder
  bool isFounder(String userId) {
    return founderId == userId;
  }

  /// Check if community has events
  bool get hasEvents => eventCount > 0;

  /// Check if community is growing
  bool get isGrowing => memberGrowthRate > 0.0 || eventGrowthRate > 0.0;

  /// Get display name
  String getDisplayName() {
    return name;
  }

  /// Get activity level display name
  String getActivityLevelDisplayName() {
    switch (activityLevel) {
      case ActivityLevel.active:
        return 'Active';
      case ActivityLevel.growing:
        return 'Growing';
      case ActivityLevel.stable:
        return 'Stable';
      case ActivityLevel.declining:
        return 'Declining';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'originatingEventId': originatingEventId,
      'originatingEventType': originatingEventType.name,
      'memberIds': memberIds,
      'memberCount': memberCount,
      'founderId': founderId,
      'eventIds': eventIds,
      'eventCount': eventCount,
      'memberGrowthRate': memberGrowthRate,
      'eventGrowthRate': eventGrowthRate,
      'createdAt': createdAt.toIso8601String(),
      'lastEventAt': lastEventAt?.toIso8601String(),
      'engagementScore': engagementScore,
      'diversityScore': diversityScore,
      'activityLevel': activityLevel.name,
      'originalLocality': originalLocality,
      'currentLocalities': currentLocalities,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      originatingEventId: json['originatingEventId'] as String,
      originatingEventType: OriginatingEventType.values.firstWhere(
        (type) => type.name == json['originatingEventType'],
        orElse: () => OriginatingEventType.communityEvent,
      ),
      memberIds: List<String>.from(json['memberIds'] as List? ?? []),
      memberCount: json['memberCount'] as int? ?? 0,
      founderId: json['founderId'] as String,
      eventIds: List<String>.from(json['eventIds'] as List? ?? []),
      eventCount: json['eventCount'] as int? ?? 0,
      memberGrowthRate: (json['memberGrowthRate'] as num?)?.toDouble() ?? 0.0,
      eventGrowthRate: (json['eventGrowthRate'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastEventAt: json['lastEventAt'] != null
          ? DateTime.parse(json['lastEventAt'] as String)
          : null,
      engagementScore: (json['engagementScore'] as num?)?.toDouble() ?? 0.0,
      diversityScore: (json['diversityScore'] as num?)?.toDouble() ?? 0.0,
      activityLevel: ActivityLevel.values.firstWhere(
        (level) => level.name == json['activityLevel'],
        orElse: () => ActivityLevel.active,
      ),
      originalLocality: json['originalLocality'] as String,
      currentLocalities: List<String>.from(
        json['currentLocalities'] as List? ?? [],
      ),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Copy with method
  Community copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? originatingEventId,
    OriginatingEventType? originatingEventType,
    List<String>? memberIds,
    int? memberCount,
    String? founderId,
    List<String>? eventIds,
    int? eventCount,
    double? memberGrowthRate,
    double? eventGrowthRate,
    DateTime? createdAt,
    DateTime? lastEventAt,
    double? engagementScore,
    double? diversityScore,
    ActivityLevel? activityLevel,
    String? originalLocality,
    List<String>? currentLocalities,
    DateTime? updatedAt,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      originatingEventId: originatingEventId ?? this.originatingEventId,
      originatingEventType: originatingEventType ?? this.originatingEventType,
      memberIds: memberIds ?? this.memberIds,
      memberCount: memberCount ?? this.memberCount,
      founderId: founderId ?? this.founderId,
      eventIds: eventIds ?? this.eventIds,
      eventCount: eventCount ?? this.eventCount,
      memberGrowthRate: memberGrowthRate ?? this.memberGrowthRate,
      eventGrowthRate: eventGrowthRate ?? this.eventGrowthRate,
      createdAt: createdAt ?? this.createdAt,
      lastEventAt: lastEventAt ?? this.lastEventAt,
      engagementScore: engagementScore ?? this.engagementScore,
      diversityScore: diversityScore ?? this.diversityScore,
      activityLevel: activityLevel ?? this.activityLevel,
      originalLocality: originalLocality ?? this.originalLocality,
      currentLocalities: currentLocalities ?? this.currentLocalities,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        category,
        originatingEventId,
        originatingEventType,
        memberIds,
        memberCount,
        founderId,
        eventIds,
        eventCount,
        memberGrowthRate,
        eventGrowthRate,
        createdAt,
        lastEventAt,
        engagementScore,
        diversityScore,
        activityLevel,
        originalLocality,
        currentLocalities,
        updatedAt,
      ];
}

