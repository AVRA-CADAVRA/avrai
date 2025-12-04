import 'package:spots/core/models/unified_user.dart' show UnifiedUser, UserRole;
import 'package:spots/core/models/unified_list.dart';
import 'package:spots/core/models/spot.dart';
import 'package:spots/core/models/personality_profile.dart';
import 'package:spots/core/models/unified_models.dart' hide UnifiedUser;
import 'package:spots/core/constants/vibe_constants.dart';
import '../helpers/test_helpers.dart';

/// Factory methods for creating test model instances
/// Provides realistic test data with proper relationships
class ModelFactories {
  
  // ======= UnifiedUser Factories =======
  
  /// Create a basic test user
  static UnifiedUser createTestUser({
    String? id,
    String? email,
    String? displayName,
    UserRole? primaryRole,
    bool? isAgeVerified,
    List<String>? curatedLists,
    List<String>? collaboratedLists,
    List<String>? followedLists,
    List<String>? tags,
    DateTime? ageVerificationDate,
  }) {
    return UnifiedUser(
      id: id ?? TestConstants.testUserId,
      email: email ?? TestConstants.testEmail,
      displayName: displayName ?? 'Test User',
      createdAt: TestHelpers.createTestDateTime(),
      updatedAt: TestHelpers.createTestDateTime(),
      primaryRole: primaryRole ?? UserRole.follower,
      isAgeVerified: isAgeVerified ?? false,
      curatedLists: curatedLists ?? [],
      collaboratedLists: collaboratedLists ?? [],
      followedLists: followedLists ?? [],
      tags: tags ?? [],
      ageVerificationDate: ageVerificationDate,
    );
  }

  /// Create a curator user with curated lists
  static UnifiedUser createCuratorUser({
    String? id,
    List<String>? curatedLists,
  }) {
    return createTestUser(
      id: id,
      primaryRole: UserRole.curator,
      curatedLists: curatedLists ?? ['list-1', 'list-2'],
      isAgeVerified: true,
    );
  }

  /// Create a collaborator user
  static UnifiedUser createCollaboratorUser({
    String? id,
    List<String>? collaboratedLists,
  }) {
    return createTestUser(
      id: id,
      primaryRole: UserRole.collaborator,
      collaboratedLists: collaboratedLists ?? ['list-1'],
    );
  }

  /// Create user with age verification
  static UnifiedUser createAgeVerifiedUser({
    String? id,
    DateTime? ageVerificationDate,
  }) {
    return createTestUser(
      id: id,
      isAgeVerified: true,
      ageVerificationDate: ageVerificationDate ?? TestHelpers.createTestDateTime(),
    );
  }

  // ======= UnifiedList Factories =======

  /// Create a basic test list
  static UnifiedList createTestList({
    String? id,
    String? title,
    String? curatorId,
    List<String>? collaboratorIds,
    List<String>? followerIds,
    List<String>? spotIds,
    bool? isPublic,
    bool? isAgeRestricted,
    int? respectCount,
    bool? isSuspended,
  }) {
    return UnifiedList(
      id: id ?? TestConstants.testListId,
      title: title ?? 'Test List',
      category: 'General',
      createdAt: TestHelpers.createTestDateTime(),
      curatorId: curatorId ?? TestConstants.testUserId,
      collaboratorIds: collaboratorIds ?? [],
      followerIds: followerIds ?? [],
      spotIds: spotIds ?? [],
      isPublic: isPublic ?? true,
      isAgeRestricted: isAgeRestricted ?? false,
      respectCount: respectCount ?? 0,
      isSuspended: isSuspended ?? false,
    );
  }

  /// Create a private list with collaborators
  static UnifiedList createPrivateList({
    String? curatorId,
    List<String>? collaboratorIds,
  }) {
    return createTestList(
      curatorId: curatorId,
      collaboratorIds: collaboratorIds ?? ['user-2', 'user-3'],
      isPublic: false,
    );
  }

  /// Create an age-restricted list
  static UnifiedList createAgeRestrictedList({
    String? curatorId,
  }) {
    return createTestList(
      curatorId: curatorId,
      isAgeRestricted: true,
    );
  }

  /// Create a suspended list
  static UnifiedList createSuspendedList({
    String? suspensionReason,
    DateTime? suspensionEndDate,
  }) {
    return createTestList().copyWith(
      isSuspended: true,
      suspensionReason: suspensionReason ?? 'Community reports',
      suspensionEndDate: suspensionEndDate,
    );
  }

  // ======= Spot Factories =======

  /// Create a basic test spot
  static Spot createTestSpot({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    String? category,
    String? createdBy,
    List<String>? tags,
  }) {
    return Spot(
      id: id ?? TestConstants.testSpotId,
      name: name ?? 'Test Spot',
      description: 'A test location for unit testing',
      latitude: latitude ?? TestConstants.testLatitude,
      longitude: longitude ?? TestConstants.testLongitude,
      category: category ?? 'Restaurant',
      rating: 4.5,
      createdBy: createdBy ?? TestConstants.testUserId,
      createdAt: TestHelpers.createTestDateTime(),
      updatedAt: TestHelpers.createTestDateTime(),
      tags: tags ?? ['test', 'location'],
    );
  }

  /// Create spot with specific location
  static Spot createSpotAtLocation(double lat, double lng, {String? name}) {
    return createTestSpot(
      name: name ?? 'Location Spot',
      latitude: lat,
      longitude: lng,
    );
  }

  // ======= PersonalityProfile Factories =======

  /// Create a basic personality profile
  static PersonalityProfile createTestPersonalityProfile({
    String? userId,
    Map<String, double>? dimensions,
    String? archetype,
    double? authenticity,
    int? evolutionGeneration,
  }) {
    final testDimensions = dimensions ?? _createTestDimensions();
    return PersonalityProfile(
      userId: userId ?? TestConstants.testUserId,
      dimensions: testDimensions,
      dimensionConfidence: _createTestConfidence(testDimensions),
      archetype: archetype ?? 'balanced',
      authenticity: authenticity ?? 0.7,
      createdAt: TestHelpers.createTestDateTime(),
      lastUpdated: TestHelpers.createTestDateTime(),
      evolutionGeneration: evolutionGeneration ?? 1,
      learningHistory: _createTestLearningHistory(),
    );
  }

  /// Create adventurous explorer personality
  static PersonalityProfile createAdventurousExplorerProfile({String? userId}) {
    return createTestPersonalityProfile(
      userId: userId,
      dimensions: {
        'exploration_eagerness': 0.9,
        'location_adventurousness': 0.8,
        'temporal_flexibility': 0.7,
        'community_orientation': 0.6,
        'authenticity_preference': 0.5,
        'social_discovery_style': 0.5,
        'curation_tendency': 0.5,
        'trust_network_reliance': 0.5,
      },
      archetype: 'adventurous_explorer',
    );
  }

  /// Create community curator personality
  static PersonalityProfile createCommunityCuratorProfile({String? userId}) {
    return createTestPersonalityProfile(
      userId: userId,
      dimensions: {
        'community_orientation': 0.9,
        'curation_tendency': 0.8,
        'trust_network_reliance': 0.7,
        'authenticity_preference': 0.8,
        'exploration_eagerness': 0.5,
        'location_adventurousness': 0.5,
        'temporal_flexibility': 0.5,
        'social_discovery_style': 0.5,
      },
      archetype: 'community_curator',
    );
  }

  // ======= UnifiedUserAction Factories =======

  /// Create test user action
  static UnifiedUserAction createTestUserAction({
    String? type,
    Map<String, dynamic>? metadata,
  }) {
    return UnifiedUserAction(
      type: type ?? 'test_action',
      timestamp: TestHelpers.createTestDateTime(),
      metadata: metadata ?? {'test': true},
      socialContext: _createTestSocialContext(),
    );
  }

  // ======= Utility Methods for Multiple Instances =======

  /// Creates a list of test Users
  static List<UnifiedUser> createTestUsers(int count) {
    return List.generate(count, (index) => createTestUser(
      id: 'test-user-$index',
      email: 'test$index@example.com',
      displayName: 'Test User $index',
    ));
  }

  /// Creates a list of test Spots
  static List<Spot> createTestSpots(int count) {
    return List.generate(count, (index) => createTestSpot(
      id: 'test-spot-$index',
      name: 'Test Spot $index',
      latitude: TestConstants.testLatitude + (index * 0.001),
      longitude: TestConstants.testLongitude + (index * 0.001),
    ));
  }

  /// Creates a list of test Lists
  static List<UnifiedList> createTestLists(int count) {
    return List.generate(count, (index) => createTestList(
      id: 'test-list-$index',
      title: 'Test List $index',
      curatorId: 'curator-$index',
    ));
  }


  // ======= Private Helper Methods =======

  static Map<String, double> _createTestDimensions() {
    final dimensions = <String, double>{};
    for (final dimension in VibeConstants.coreDimensions) {
      dimensions[dimension] = 0.5; // Default balanced values
    }
    return dimensions;
  }

  static Map<String, double> _createTestConfidence(Map<String, double> dimensions) {
    final confidence = <String, double>{};
    for (final dimension in dimensions.keys) {
      confidence[dimension] = 0.8; // High confidence for testing
    }
    return confidence;
  }

  static Map<String, dynamic> _createTestLearningHistory() {
    return {
      'total_interactions': 10,
      'successful_ai2ai_connections': 5,
      'learning_sources': ['user_behavior', 'ai2ai_network'],
      'evolution_milestones': [TestHelpers.createTestDateTime()],
    };
  }

  static UnifiedSocialContext _createTestSocialContext() {
    return UnifiedSocialContext(
      nearbyUsers: [],
      friends: [],
      communityMembers: ['test_community'],
      socialMetrics: {'engagement': 0.8},
      timestamp: TestHelpers.createTestDateTime(),
    );
  }
}

/// Edge case test data factories
class ModelFactoriesEdgeCases {
  /// User with minimal data
  static UnifiedUser minimalUser() {
    return UnifiedUser(
      id: 'minimal-user',
      email: 'minimal@test.com',
      displayName: 'M',
      createdAt: TestConstants.testDate,
      updatedAt: TestConstants.testDate,
    );
  }

  /// Spot with extreme coordinates
  static Spot extremeCoordinateSpot() {
    return ModelFactories.createTestSpot(
      id: 'extreme-spot',
      latitude: 89.9999, // Near north pole
      longitude: 179.9999, // Near international date line
    );
  }

  /// Empty list
  static UnifiedList emptyList() {
    return ModelFactories.createTestList(
      id: 'empty-list',
      title: '',
      spotIds: [],
    );
  }

  /// List with many spots
  static UnifiedList largeList() {
    return ModelFactories.createTestList(
      id: 'large-list',
      title: 'Large Test List',
      spotIds: List.generate(100, (index) => 'spot-$index'),
    );
  }
}