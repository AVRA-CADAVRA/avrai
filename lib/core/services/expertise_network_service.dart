import 'package:spots/core/models/unified_user.dart';
import 'package:spots/core/models/expertise_level.dart';
import 'package:spots/core/services/logger.dart';

/// Expertise Network Service
/// Manages expertise-based social graph and connections
class ExpertiseNetworkService {
  static const String _logName = 'ExpertiseNetworkService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS', minimumLevel: LogLevel.debug);

  /// Get expertise network for a user
  /// Returns users connected through expertise
  Future<ExpertiseNetwork> getUserExpertiseNetwork(UnifiedUser user) async {
    try {
      _logger.info('Building expertise network for: ${user.id}', tag: _logName);

      final connections = <ExpertiseConnection>[];
      final userCategories = user.getExpertiseCategories();

      // Get all users
      final allUsers = await _getAllUsers();

      for (final otherUser in allUsers) {
        if (otherUser.id == user.id) continue;

        // Find shared expertise
        final sharedCategories = userCategories
            .where((cat) => otherUser.hasExpertiseIn(cat))
            .toList();

        if (sharedCategories.isNotEmpty) {
          // Calculate connection strength
          final strength = _calculateConnectionStrength(
            user: user,
            otherUser: otherUser,
            sharedCategories: sharedCategories,
          );

          if (strength > 0.2) {
            connections.add(ExpertiseConnection(
              user: otherUser,
              sharedExpertise: sharedCategories,
              connectionStrength: strength,
              connectionType: _determineConnectionType(user, otherUser, sharedCategories),
            ));
          }
        }
      }

      // Sort by connection strength
      connections.sort((a, b) => b.connectionStrength.compareTo(a.connectionStrength));

      _logger.info('Built network with ${connections.length} connections', tag: _logName);

      return ExpertiseNetwork(
        user: user,
        connections: connections,
        networkSize: connections.length,
        strongestConnections: connections.take(10).toList(),
      );
    } catch (e) {
      _logger.error('Error building expertise network', error: e, tag: _logName);
      return ExpertiseNetwork.empty(user);
    }
  }

  /// Get expertise circles (groups of experts in same category)
  Future<List<ExpertiseCircle>> getExpertiseCircles(String category, {String? location}) async {
    try {
      _logger.info('Getting expertise circles for: $category', tag: _logName);

      final allUsers = await _getAllUsers();
      final experts = <UnifiedUser>[];

      // Filter experts in category
      for (final user in allUsers) {
        if (!user.hasExpertiseIn(category)) continue;
        if (location != null && user.location != null) {
          if (!user.location!.toLowerCase().contains(location.toLowerCase())) {
            continue;
          }
        }
        experts.add(user);
      }

      // Group by level
      final circles = <ExpertiseCircle>[];
      final levelGroups = <String, List<UnifiedUser>>{};

      for (final expert in experts) {
        final level = expert.getExpertiseLevel(category);
        if (level == null) continue;

        final levelKey = level.name;
        levelGroups.putIfAbsent(levelKey, () => []).add(expert);
      }

      for (final entry in levelGroups.entries) {
        final level = ExpertiseLevel.fromString(entry.key);
        if (level == null) continue;

        circles.add(ExpertiseCircle(
          category: category,
          level: level,
          location: location,
          members: entry.value,
          memberCount: entry.value.length,
        ));
      }

      // Sort by level (highest first)
      circles.sort((a, b) => b.level.index.compareTo(a.level.index));

      return circles;
    } catch (e) {
      _logger.error('Error getting expertise circles', error: e, tag: _logName);
      return [];
    }
  }

  /// Get expertise influence (who influences this user's expertise)
  Future<List<ExpertiseInfluence>> getExpertiseInfluence(UnifiedUser user) async {
    try {
      _logger.info('Getting expertise influence for: ${user.id}', tag: _logName);

      // In production, this would analyze:
      // - Lists user has respected
      // - Experts user follows
      // - Spots user has discovered through experts
      
      final influences = <ExpertiseInfluence>[];
      
      // Placeholder implementation
      // Would query user's respected lists, follows, etc.
      
      return influences;
    } catch (e) {
      _logger.error('Error getting expertise influence', error: e, tag: _logName);
      return [];
    }
  }

  /// Get expertise following (who follows this user's expertise)
  Future<List<UnifiedUser>> getExpertiseFollowers(UnifiedUser user) async {
    try {
      _logger.info('Getting expertise followers for: ${user.id}', tag: _logName);

      // In production, this would query users who:
      // - Respect user's lists
      // - Follow user
      // - Discover spots through user
      
      return [];
    } catch (e) {
      _logger.error('Error getting expertise followers', error: e, tag: _logName);
      return [];
    }
  }

  // Private helper methods

  double _calculateConnectionStrength({
    required UnifiedUser user,
    required UnifiedUser otherUser,
    required List<String> sharedCategories,
  }) {
    double strength = 0.0;

    // Shared categories contribute to strength
    strength += sharedCategories.length * 0.2;

    // Level similarity
    for (final category in sharedCategories) {
      final userLevel = user.getExpertiseLevel(category);
      final otherLevel = otherUser.getExpertiseLevel(category);
      
      if (userLevel != null && otherLevel != null) {
        final levelDiff = (userLevel.index - otherLevel.index).abs();
        strength += (1.0 - (levelDiff / ExpertiseLevel.values.length)) * 0.3;
      }
    }

    // Location match bonus
    if (user.location != null && otherUser.location != null) {
      if (user.location == otherUser.location) {
        strength += 0.2;
      }
    }

    return strength.clamp(0.0, 1.0);
  }

  ExpertiseConnectionType _determineConnectionType(
    UnifiedUser user,
    UnifiedUser otherUser,
    List<String> sharedCategories,
  ) {
    // Check if mentor/mentee relationship
    for (final category in sharedCategories) {
      final userLevel = user.getExpertiseLevel(category);
      final otherLevel = otherUser.getExpertiseLevel(category);
      
      if (userLevel != null && otherLevel != null) {
        if (otherLevel.isHigherThan(userLevel)) {
          return ExpertiseConnectionType.mentor;
        } else if (userLevel.isHigherThan(otherLevel)) {
          return ExpertiseConnectionType.mentee;
        }
      }
    }

    // Check if complementary expertise
    final userCategories = user.getExpertiseCategories();
    final otherCategories = otherUser.getExpertiseCategories();
    
    final hasComplementary = userCategories.any((cat) => !otherCategories.contains(cat)) ||
                             otherCategories.any((cat) => !userCategories.contains(cat));
    
    if (hasComplementary) {
      return ExpertiseConnectionType.complementary;
    }

    return ExpertiseConnectionType.peer;
  }

  Future<List<UnifiedUser>> _getAllUsers() async {
    // Placeholder - in production, this would query the database
    return [];
  }
}

/// Expertise Network
class ExpertiseNetwork {
  final UnifiedUser user;
  final List<ExpertiseConnection> connections;
  final int networkSize;
  final List<ExpertiseConnection> strongestConnections;

  const ExpertiseNetwork({
    required this.user,
    required this.connections,
    required this.networkSize,
    required this.strongestConnections,
  });

  factory ExpertiseNetwork.empty(UnifiedUser user) {
    return ExpertiseNetwork(
      user: user,
      connections: [],
      networkSize: 0,
      strongestConnections: [],
    );
  }
}

/// Expertise Connection
class ExpertiseConnection {
  final UnifiedUser user;
  final List<String> sharedExpertise;
  final double connectionStrength;
  final ExpertiseConnectionType connectionType;

  const ExpertiseConnection({
    required this.user,
    required this.sharedExpertise,
    required this.connectionStrength,
    required this.connectionType,
  });
}

/// Expertise Connection Type
enum ExpertiseConnectionType {
  peer,          // Same level experts
  mentor,        // Higher level expert
  mentee,        // Lower level expert
  complementary, // Different but related expertise
}

/// Expertise Circle
class ExpertiseCircle {
  final String category;
  final ExpertiseLevel level;
  final String? location;
  final List<UnifiedUser> members;
  final int memberCount;

  const ExpertiseCircle({
    required this.category,
    required this.level,
    this.location,
    required this.members,
    required this.memberCount,
  });
}

/// Expertise Influence
class ExpertiseInfluence {
  final UnifiedUser influencer;
  final List<String> influencedCategories;
  final double influenceStrength;
  final String influenceReason;

  const ExpertiseInfluence({
    required this.influencer,
    required this.influencedCategories,
    required this.influenceStrength,
    required this.influenceReason,
  });
}

