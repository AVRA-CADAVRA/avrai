import 'package:equatable/equatable.dart';
import 'package:spots/core/models/expertise_pin.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/expertise_service.dart';

/// Unified User model that combines core and domain features
/// Includes role system for curator/collaborator/follower architecture
class UnifiedUser extends Equatable {
  // Core identity fields
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? location;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  // Status fields
  final bool isOnline;
  final bool? hasCompletedOnboarding;
  final bool? hasReceivedStarterLists;

  // Enhanced profile fields for list creators
  final String? expertise;
  final List<String>? locations;
  final int? hostedEventsCount;
  final int? differentSpotsCount;

  // Social fields
  final List<String> tags;
  final Map<String, String> expertiseMap; // category -> level
  final List<String> friends;

  // Role system fields (new)
  final List<String> curatedLists; // Lists where user is curator
  final List<String> collaboratedLists; // Lists where user is collaborator
  final List<String> followedLists; // Lists where user is follower
  final UserRole primaryRole; // User's primary role in the community

  // Age verification for 18+ content
  final bool isAgeVerified;
  final DateTime? ageVerificationDate;

  const UnifiedUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.isOnline = false,
    this.hasCompletedOnboarding,
    this.hasReceivedStarterLists,
    this.expertise,
    this.locations,
    this.hostedEventsCount,
    this.differentSpotsCount,
    this.tags = const [],
    this.expertiseMap = const {},
    this.friends = const [],
    this.curatedLists = const [],
    this.collaboratedLists = const [],
    this.followedLists = const [],
    this.primaryRole = UserRole.follower,
    this.isAgeVerified = false,
    this.ageVerificationDate,
  });

  factory UnifiedUser.fromJson(Map<String, dynamic> json) {
    return UnifiedUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isOnline: json['isOnline'] as bool? ?? false,
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool?,
      hasReceivedStarterLists: json['hasReceivedStarterLists'] as bool?,
      expertise: json['expertise'] as String?,
      locations: json['locations'] != null
          ? List<String>.from(json['locations'] as List)
          : null,
      hostedEventsCount: json['hostedEventsCount'] as int?,
      differentSpotsCount: json['differentSpotsCount'] as int?,
      tags: List<String>.from(json['tags'] ?? []),
      expertiseMap: Map<String, String>.from(json['expertiseMap'] ?? {}),
      friends: List<String>.from(json['friends'] ?? []),
      curatedLists: List<String>.from(json['curatedLists'] ?? []),
      collaboratedLists: List<String>.from(json['collaboratedLists'] ?? []),
      followedLists: List<String>.from(json['followedLists'] ?? []),
      primaryRole: UserRole.values.firstWhere(
        (role) => role.name == json['primaryRole'],
        orElse: () => UserRole.follower,
      ),
      isAgeVerified: json['isAgeVerified'] as bool? ?? false,
      ageVerificationDate: json['ageVerificationDate'] != null
          ? DateTime.parse(json['ageVerificationDate'] as String)
          : null,
    );
  }

  factory UnifiedUser.fromMap(Map<String, dynamic> map) {
    return UnifiedUser(
      id: map['id'] as String,
      email: map['email'] as String,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      location: map['location'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isOnline: map['isOnline'] as bool? ?? false,
      hasCompletedOnboarding: map['hasCompletedOnboarding'] as bool?,
      hasReceivedStarterLists: map['hasReceivedStarterLists'] as bool?,
      expertise: map['expertise'] as String?,
      locations: map['locations'] != null
          ? List<String>.from(map['locations'] as List)
          : null,
      hostedEventsCount: map['hostedEventsCount'] as int?,
      differentSpotsCount: map['differentSpotsCount'] as int?,
      tags: List<String>.from(map['tags'] ?? []),
      expertiseMap: Map<String, String>.from(map['expertiseMap'] ?? {}),
      friends: List<String>.from(map['friends'] ?? []),
      curatedLists: List<String>.from(map['curatedLists'] ?? []),
      collaboratedLists: List<String>.from(map['collaboratedLists'] ?? []),
      followedLists: List<String>.from(map['followedLists'] ?? []),
      primaryRole: UserRole.values.firstWhere(
        (role) => role.name == map['primaryRole'],
        orElse: () => UserRole.follower,
      ),
      isAgeVerified: map['isAgeVerified'] as bool? ?? false,
      ageVerificationDate: map['ageVerificationDate'] != null
          ? DateTime.parse(map['ageVerificationDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isOnline': isOnline,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasReceivedStarterLists': hasReceivedStarterLists,
      'expertise': expertise,
      'locations': locations,
      'hostedEventsCount': hostedEventsCount,
      'differentSpotsCount': differentSpotsCount,
      'tags': tags,
      'expertiseMap': expertiseMap,
      'friends': friends,
      'curatedLists': curatedLists,
      'collaboratedLists': collaboratedLists,
      'followedLists': followedLists,
      'primaryRole': primaryRole.name,
      'isAgeVerified': isAgeVerified,
      'ageVerificationDate': ageVerificationDate?.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isOnline': isOnline,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasReceivedStarterLists': hasReceivedStarterLists,
      'expertise': expertise,
      'locations': locations,
      'hostedEventsCount': hostedEventsCount,
      'differentSpotsCount': differentSpotsCount,
      'tags': tags,
      'expertiseMap': expertiseMap,
      'friends': friends,
      'curatedLists': curatedLists,
      'collaboratedLists': collaboratedLists,
      'followedLists': followedLists,
      'primaryRole': primaryRole.name,
      'isAgeVerified': isAgeVerified,
      'ageVerificationDate': ageVerificationDate?.toIso8601String(),
    };
  }

  UnifiedUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isOnline,
    bool? hasCompletedOnboarding,
    bool? hasReceivedStarterLists,
    String? expertise,
    List<String>? locations,
    int? hostedEventsCount,
    int? differentSpotsCount,
    List<String>? tags,
    Map<String, String>? expertiseMap,
    List<String>? friends,
    List<String>? curatedLists,
    List<String>? collaboratedLists,
    List<String>? followedLists,
    UserRole? primaryRole,
    bool? isAgeVerified,
    DateTime? ageVerificationDate,
  }) {
    return UnifiedUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isOnline: isOnline ?? this.isOnline,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasReceivedStarterLists:
          hasReceivedStarterLists ?? this.hasReceivedStarterLists,
      expertise: expertise ?? this.expertise,
      locations: locations ?? this.locations,
      hostedEventsCount: hostedEventsCount ?? this.hostedEventsCount,
      differentSpotsCount: differentSpotsCount ?? this.differentSpotsCount,
      tags: tags ?? this.tags,
      expertiseMap: expertiseMap ?? this.expertiseMap,
      friends: friends ?? this.friends,
      curatedLists: curatedLists ?? this.curatedLists,
      collaboratedLists: collaboratedLists ?? this.collaboratedLists,
      followedLists: followedLists ?? this.followedLists,
      primaryRole: primaryRole ?? this.primaryRole,
      isAgeVerified: isAgeVerified ?? this.isAgeVerified,
      ageVerificationDate: ageVerificationDate ?? this.ageVerificationDate,
    );
  }

  /// Check if user can access age-restricted content
  bool canAccessAgeRestrictedContent() {
    return isAgeVerified && ageVerificationDate != null;
  }

  /// Check if user is a curator of any lists
  bool get isCurator => curatedLists.isNotEmpty;

  /// Check if user is a collaborator of any lists
  bool get isCollaborator => collaboratedLists.isNotEmpty;

  /// Check if user is a follower of any lists
  bool get isFollower => followedLists.isNotEmpty;

  /// Get total number of lists user is involved with
  int get totalListInvolvement =>
      curatedLists.length + collaboratedLists.length + followedLists.length;

  /// Get expertise pins for this user
  /// Uses ExpertiseService to convert expertiseMap to pins
  List<ExpertisePin> getExpertisePins() {
    final service = ExpertiseService();
    return service.getUserPins(this);
  }

  /// Check if user has expertise in a category
  bool hasExpertiseIn(String category) {
    return expertiseMap.containsKey(category);
  }

  /// Get expertise level for a category
  ExpertiseLevel? getExpertiseLevel(String category) {
    final levelString = expertiseMap[category];
    if (levelString == null) return null;
    return ExpertiseLevel.fromString(levelString);
  }

  /// Get all expertise categories
  List<String> getExpertiseCategories() {
    return expertiseMap.keys.toList();
  }

  /// Check if user can host events (requires Local level or higher)
  bool canHostEvents() {
    return expertiseMap.values.any((levelString) {
      final level = ExpertiseLevel.fromString(levelString);
      return level != null && level.index >= ExpertiseLevel.local.index;
    });
  }

  /// Check if user can perform expert validation (requires Regional level or higher)
  bool canPerformExpertValidation() {
    return expertiseMap.values.any((levelString) {
      final level = ExpertiseLevel.fromString(levelString);
      return level != null && level.index >= ExpertiseLevel.regional.index;
    });
  }

  /// Get primary expertise (highest level)
  ExpertisePin? getPrimaryExpertise() {
    final pins = getExpertisePins();
    if (pins.isEmpty) return null;
    
    // Sort by level (highest first)
    pins.sort((a, b) => b.level.index.compareTo(a.level.index));
    return pins.first;
  }

  /// Get expertise count
  int get expertiseCount => expertiseMap.length;

  @override
  List<Object?> get props => [
        id,
        email,
        displayName,
        photoUrl,
        location,
        createdAt,
        updatedAt,
        isOnline,
        hasCompletedOnboarding,
        hasReceivedStarterLists,
        expertise,
        locations,
        hostedEventsCount,
        differentSpotsCount,
        tags,
        expertiseMap,
        friends,
        curatedLists,
        collaboratedLists,
        followedLists,
        primaryRole,
        isAgeVerified,
        ageVerificationDate,
      ];
}

/// User roles in the SPOTS community
enum UserRole {
  curator,      // Can create and manage lists, delete lists, manage permissions
  collaborator, // Can add/remove spots from lists they have access to
  follower      // Can view and respect lists, basic user
}

/// Extension to provide role descriptions
extension UserRoleExtension on UserRole {
  String get description {
    switch (this) {
      case UserRole.curator:
        return 'List creator and manager';
      case UserRole.collaborator:
        return 'Can edit spots in lists';
      case UserRole.follower:
        return 'Basic user';
    }
  }

  String get shortName {
    switch (this) {
      case UserRole.curator:
        return 'Curator';
      case UserRole.collaborator:
        return 'Collaborator';
      case UserRole.follower:
        return 'Follower';
    }
  }
}
