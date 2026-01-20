import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:avrai/core/services/social_media_connection_service.dart';
import 'package:avrai/core/services/storage_service.dart';
import 'package:avrai/core/services/logger.dart';
import 'package:avrai/core/services/supabase_service.dart';
import 'package:get_it/get_it.dart';
import 'package:avrai_knot/services/knot/knot_weaving_service.dart';
import 'package:avrai_knot/services/knot/knot_storage_service.dart';
import 'package:avrai_knot/models/knot/braided_knot.dart';

/// Social Media Discovery Service
///
/// Finds friends who use SPOTS in a privacy-preserving way.
/// Uses hashed friend IDs to match users without exposing identities.
///
/// **Privacy:** All friend IDs are hashed with SHA-256 before comparison.
/// **User Control:** Users choose which friends to connect with.
class SocialMediaDiscoveryService {
  static const String _logName = 'SocialMediaDiscoveryService';
  final AppLogger _logger = const AppLogger(defaultTag: 'SPOTS');
  final StorageService _storageService;
  final SocialMediaConnectionService _connectionService;
  final SupabaseService? _supabaseService;

  // Storage keys
  static const String _friendSuggestionsKeyPrefix = 'friend_suggestions_';
  static const String _hashedFriendsKeyPrefix = 'hashed_friends_';

  SocialMediaDiscoveryService({
    required StorageService storageService,
    required SocialMediaConnectionService connectionService,
    SupabaseService? supabaseService,
  })  : _storageService = storageService,
        _connectionService = connectionService,
        _supabaseService = supabaseService;

  /// Find friends who use SPOTS (privacy-preserving)
  ///
  /// **Flow:**
  /// 1. Get friend IDs from connected social media platforms
  /// 2. Hash friend IDs with SHA-256
  /// 3. Query Supabase for matching hashed friend IDs
  /// 4. Return friend suggestions (without exposing identities)
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  /// - `userId`: User identifier for service lookup
  ///
  /// **Returns:**
  /// List of FriendSuggestion objects (privacy-preserving)
  Future<List<FriendSuggestion>> findFriendsWhoUseSpots({
    required String agentId,
    required String userId,
  }) async {
    try {
      _logger.info('🔍 Finding friends who use SPOTS for agent: ${agentId.substring(0, 10)}...', tag: _logName);

      // Get all active social media connections
      final connections = await _connectionService.getActiveConnections(userId);
      if (connections.isEmpty) {
        _logger.info('No social media connections found', tag: _logName);
        return [];
      }

      // Collect friend IDs from all platforms
      final allFriendIds = <String, String>{}; // friendId -> platform
      for (final connection in connections) {
        try {
          final friends = await _connectionService.fetchFollows(connection);
          for (final friend in friends) {
            final friendId = friend['id'] as String? ?? friend['user_id'] as String?;
            if (friendId != null) {
              allFriendIds[friendId] = connection.platform;
            }
          }
        } catch (e) {
          _logger.warn('Failed to fetch friends from ${connection.platform}: $e', tag: _logName);
          // Continue with other platforms
        }
      }

      if (allFriendIds.isEmpty) {
        _logger.info('No friends found from social media', tag: _logName);
        return [];
      }

      // Hash all friend IDs
      final hashedFriendIds = allFriendIds.map((friendId, platform) => MapEntry(
        _hashFriendId(friendId, platform),
        platform,
      ));

      // Store hashed friend IDs locally (for privacy-preserving matching)
      await _storeHashedFriends(agentId, hashedFriendIds);

      // Query Supabase for matching hashed friend IDs
      final suggestions = await _queryFriendMatches(agentId, hashedFriendIds.keys.toList());

      // Cache suggestions
      await _cacheFriendSuggestions(agentId, suggestions);

      _logger.info('✅ Found ${suggestions.length} friend suggestion(s)', tag: _logName);
      return suggestions;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to find friends', error: e, stackTrace: stackTrace, tag: _logName);
      return [];
    }
  }

  /// Get cached friend suggestions
  Future<List<FriendSuggestion>> getCachedFriendSuggestions(String agentId) async {
    try {
      final key = '$_friendSuggestionsKeyPrefix$agentId';
      final data = _storageService.getObject<Map<String, dynamic>>(key);
      if (data == null) return [];

      final suggestionsJson = data['suggestions'] as List<dynamic>? ?? [];
      return suggestionsJson
          .map((s) => FriendSuggestion.fromJson(s as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.warn('Failed to get cached suggestions: $e', tag: _logName);
      return [];
    }
  }

  /// Connect with a friend (both users must consent)
  ///
  /// **Flow:**
  /// 1. Send connection request to friend
  /// 2. Friend receives notification
  /// 3. Friend accepts/rejects
  /// 4. If accepted, establish connection
  ///
  /// **Parameters:**
  /// - `agentId`: Privacy-protected agent identifier
  /// - `friendAgentId`: Friend's agent ID
  /// - `userId`: User identifier for service lookup
  ///
  /// **Returns:**
  /// True if connection request sent successfully
  Future<bool> sendFriendConnectionRequest({
    required String agentId,
    required String friendAgentId,
    required String userId,
  }) async {
    try {
      _logger.info('📤 Sending friend connection request', tag: _logName);

      // Store connection request in Supabase
      if (_supabaseService != null) {
        // TODO: Implement connection request storage in Supabase
        // For now, return success
        return true;
      }

      // Fallback: Store locally
      await _storeConnectionRequest(agentId, friendAgentId);
      return true;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to send connection request', error: e, stackTrace: stackTrace, tag: _logName);
      return false;
    }
  }

  /// Accept a friend connection request
  ///
  /// **Flow:**
  /// 1. Store accepted connection
  /// 2. Get both users' personality knots
  /// 3. Create braided knot via KnotWeavingService
  /// 4. Store braided knot
  /// 5. Update both users' friends lists
  Future<bool> acceptFriendConnectionRequest({
    required String agentId,
    required String friendAgentId,
    required String userId,
  }) async {
    try {
      _logger.info('✅ Accepting friend connection request', tag: _logName);

      // Store accepted connection in Supabase
      if (_supabaseService != null) {
        // TODO: Implement connection acceptance in Supabase
        // For now, continue with local storage
      }

      // Store locally
      await _storeAcceptedConnection(agentId, friendAgentId);

      // Create braided knot (if knot services are available)
      try {
        final sl = GetIt.instance;
        if (sl.isRegistered<KnotWeavingService>() &&
            sl.isRegistered<KnotStorageService>()) {
          final knotWeavingService = sl<KnotWeavingService>();
          final knotStorageService = sl<KnotStorageService>();

          // Get both users' personality knots
          final localKnot = await knotStorageService.loadKnot(agentId);
          final friendKnot = await knotStorageService.loadKnot(friendAgentId);

          if (localKnot != null && friendKnot != null) {
            // Create braided knot with friendship relationship type
            final braidedKnot = await knotWeavingService.weaveKnots(
              knotA: localKnot,
              knotB: friendKnot,
              relationshipType: RelationshipType.friendship,
            );

            // Store braided knot (using agentId as connectionId for now)
            await knotStorageService.saveBraidedKnot(
              connectionId: 'friend_${agentId}_$friendAgentId',
              braidedKnot: braidedKnot,
            );

            _logger.info(
              '✅ Braided knot created for friendship: ${agentId.substring(0, 10)}... <-> ${friendAgentId.substring(0, 10)}...',
              tag: _logName,
            );
          } else {
            _logger.warn(
              'Knots not available for braiding (local: ${localKnot != null}, friend: ${friendKnot != null})',
              tag: _logName,
            );
          }
        }
      } catch (e) {
        // Log error but don't fail the friend acceptance
        _logger.warn(
          'Error creating braided knot (continuing without knot): $e',
          tag: _logName,
        );
      }

      return true;
    } catch (e, stackTrace) {
      _logger.error('❌ Failed to accept connection request', error: e, stackTrace: stackTrace, tag: _logName);
      return false;
    }
  }

  /// Get connected friends
  Future<List<String>> getConnectedFriends(String agentId) async {
    try {
      final key = 'connected_friends_$agentId';
      final data = _storageService.getObject<List<dynamic>>(key);
      if (data == null) return [];
      return data.cast<String>();
    } catch (e) {
      _logger.warn('Failed to get connected friends: $e', tag: _logName);
      return [];
    }
  }

  // Private helper methods

  /// Hash friend ID with SHA-256 (privacy-preserving)
  String _hashFriendId(String friendId, String platform) {
    final input = '$platform:$friendId';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Store hashed friend IDs locally
  Future<void> _storeHashedFriends(String agentId, Map<String, String> hashedFriends) async {
    try {
      final key = '$_hashedFriendsKeyPrefix$agentId';
      await _storageService.setObject(key, {
        'hashedFriends': hashedFriends,
        'storedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.warn('Failed to store hashed friends: $e', tag: _logName);
    }
  }

  /// Query Supabase for matching hashed friend IDs
  Future<List<FriendSuggestion>> _queryFriendMatches(
    String agentId,
    List<String> hashedFriendIds,
  ) async {
    try {
      if (_supabaseService == null) {
        _logger.warn('Supabase service not available, returning empty suggestions', tag: _logName);
        return [];
      }

      // TODO: Implement Supabase query for matching hashed friend IDs
      // Query structure:
      // SELECT agent_id, platform, username (if available)
      // FROM social_media_profiles
      // WHERE hashed_friend_id IN (hashedFriendIds)
      // AND agent_id != agentId (exclude self)

      // For now, return empty list (to be implemented with Supabase)
      return [];
    } catch (e) {
      _logger.error('Error querying friend matches: $e', tag: _logName);
      return [];
    }
  }

  /// Cache friend suggestions locally
  Future<void> _cacheFriendSuggestions(String agentId, List<FriendSuggestion> suggestions) async {
    try {
      final key = '$_friendSuggestionsKeyPrefix$agentId';
      await _storageService.setObject(key, {
        'suggestions': suggestions.map((s) => s.toJson()).toList(),
        'cachedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      _logger.warn('Failed to cache suggestions: $e', tag: _logName);
    }
  }

  /// Store connection request locally
  Future<void> _storeConnectionRequest(String agentId, String friendAgentId) async {
    try {
      final key = 'connection_requests_$agentId';
      final requests = _storageService.getObject<List<dynamic>>(key) ?? [];
      requests.add({
        'friendAgentId': friendAgentId,
        'requestedAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
      await _storageService.setObject(key, requests);
    } catch (e) {
      _logger.warn('Failed to store connection request: $e', tag: _logName);
    }
  }

  /// Store accepted connection locally
  Future<void> _storeAcceptedConnection(String agentId, String friendAgentId) async {
    try {
      final key = 'connected_friends_$agentId';
      final friends = _storageService.getObject<List<dynamic>>(key) ?? [];
      if (!friends.contains(friendAgentId)) {
        friends.add(friendAgentId);
        await _storageService.setObject(key, friends);
      }
    } catch (e) {
      _logger.warn('Failed to store accepted connection: $e', tag: _logName);
    }
  }
}

/// Friend Suggestion Model
///
/// Represents a friend who uses SPOTS (privacy-preserving).
class FriendSuggestion {
  /// Friend's agent ID (privacy-protected)
  final String agentId;

  /// Platform where friend was found
  final String platform;

  /// Friend's username (if available, from social media)
  final String? username;

  /// Friend's display name (if available)
  final String? displayName;

  /// Friend's profile image URL (if available)
  final String? profileImageUrl;

  /// Mutual friends count (if available)
  final int? mutualFriendsCount;

  /// Connection status
  final FriendConnectionStatus status;

  const FriendSuggestion({
    required this.agentId,
    required this.platform,
    this.username,
    this.displayName,
    this.profileImageUrl,
    this.mutualFriendsCount,
    this.status = FriendConnectionStatus.notConnected,
  });

  Map<String, dynamic> toJson() {
    return {
      'agentId': agentId,
      'platform': platform,
      'username': username,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'mutualFriendsCount': mutualFriendsCount,
      'status': status.name,
    };
  }

  factory FriendSuggestion.fromJson(Map<String, dynamic> json) {
    return FriendSuggestion(
      agentId: json['agentId'] as String,
      platform: json['platform'] as String,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      profileImageUrl: json['profileImageUrl'] as String?,
      mutualFriendsCount: json['mutualFriendsCount'] as int?,
      status: FriendConnectionStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => FriendConnectionStatus.notConnected,
      ),
    );
  }
}

/// Friend Connection Status
enum FriendConnectionStatus {
  notConnected,
  requestSent,
  requestReceived,
  connected,
}
