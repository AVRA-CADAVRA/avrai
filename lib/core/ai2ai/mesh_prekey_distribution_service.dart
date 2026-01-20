// Mesh Prekey Distribution Service
//
// Phase 3.3: Mesh Network Prekey Bundle Distribution (LOW PRIORITY)
// Forwards prekey bundles through mesh network for multi-hop key exchange
//
// Enables key exchange even without direct connection, improving resilience
// in sparse networks.

import 'dart:developer' as developer;
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/ai2ai/adaptive_mesh_networking_service.dart';
import 'package:avrai/core/ai2ai/adaptive_mesh_hop_policy.dart' as mesh_policy;

/// Mesh Prekey Distribution Service
///
/// Forwards prekey bundles through mesh network for multi-hop key exchange.
/// This enables key exchange even without direct connection, improving
/// resilience in sparse networks.
///
/// **Phase 3.3:** Mesh Network Prekey Bundle Distribution (LOW PRIORITY)
///
/// **Features:**
/// - Multi-hop prekey bundle distribution
/// - Caching in intermediate nodes
/// - Expiration handling
/// - Mesh-aware routing
class MeshPrekeyDistributionService {
  static const String _logName = 'MeshPrekeyDistributionService';

  final AdaptiveMeshNetworkingService? _meshService;

  // Cache for prekey bundles being forwarded (intermediate node caching)
  // Key: recipientId, Value: (bundle, expiresAt, hopCount)
  final Map<String, _CachedPreKeyForward> _forwardCache = {};
  
  static const Duration _cacheExpiry = Duration(minutes: 10);
  static const int _maxHops = 3; // Maximum hops for prekey bundle forwarding

  MeshPrekeyDistributionService({
    AdaptiveMeshNetworkingService? meshService,
  }) : _meshService = meshService;

  /// Forward prekey bundle through mesh network
  ///
  /// **Parameters:**
  /// - `bundle`: Prekey bundle to forward
  /// - `recipientId`: Target recipient ID
  /// - `currentHop`: Current hop count (0 = original sender)
  /// - `originId`: Original sender ID (for loop prevention)
  ///
  /// **Returns:**
  /// `true` if forwarded, `false` if not (due to hop limit, cache, etc.)
  Future<bool> forwardPreKeyBundle({
    required SignalPreKeyBundle bundle,
    required String recipientId,
    int currentHop = 0,
    String? originId,
  }) async {
    // Check hop limit
    if (currentHop >= _maxHops) {
      developer.log(
        'Prekey bundle forwarding stopped: hop limit reached (currentHop=$currentHop, maxHops=$_maxHops)',
        name: _logName,
      );
      return false;
    }

    // Check cache to avoid duplicate forwarding (before mesh service check)
    final cacheKey = '$recipientId:$originId';
    final cached = _forwardCache[cacheKey];
    if (cached != null) {
      final now = DateTime.now();
      if (cached.expiresAt.isAfter(now) && cached.hopCount <= currentHop) {
        developer.log(
          'Prekey bundle forwarding skipped: already cached (recipientId=$recipientId, hop=$currentHop)',
          name: _logName,
        );
        return false;
      }
    }

    // Check if mesh service is available
    if (_meshService == null) {
      developer.log(
        'Prekey bundle forwarding skipped: mesh service not available',
        name: _logName,
      );
      // Still cache the bundle for potential future use (even if we can't forward now)
      _forwardCache[cacheKey] = _CachedPreKeyForward(
        bundle: bundle,
        expiresAt: DateTime.now().add(_cacheExpiry),
        hopCount: currentHop,
      );
      return false;
    }

    // Check if mesh forwarding is allowed
    if (!_meshService!.shouldForwardMessage(
      currentHop: currentHop,
      priority: mesh_policy.MessagePriority.high,
      messageType: mesh_policy.MessageType.learningInsight, // Reuse type
      geographicScope: 'locality', // Prekey bundles are locality-scoped
    )) {
      developer.log(
        'Prekey bundle forwarding skipped: mesh policy says don\'t forward (hop=$currentHop)',
        name: _logName,
      );
      return false;
    }

    // Cache bundle for forwarding (already checked for duplicates above)
    _forwardCache[cacheKey] = _CachedPreKeyForward(
      bundle: bundle,
      expiresAt: DateTime.now().add(_cacheExpiry),
      hopCount: currentHop,
    );

    developer.log(
      'Prekey bundle cached for mesh forwarding: recipientId=$recipientId, hop=$currentHop',
      name: _logName,
    );

    return true;
  }

  /// Get cached prekey bundle (for intermediate node caching)
  ///
  /// **Parameters:**
  /// - `recipientId`: Target recipient ID
  /// - `originId`: Original sender ID
  ///
  /// **Returns:**
  /// Cached bundle if available and not expired, `null` otherwise
  SignalPreKeyBundle? getCachedPreKeyBundle({
    required String recipientId,
    String? originId,
  }) {
    final cacheKey = '$recipientId:$originId';
    final cached = _forwardCache[cacheKey];
    
    if (cached == null) {
      return null;
    }

    final now = DateTime.now();
    if (!cached.expiresAt.isAfter(now)) {
      // Expired, remove from cache
      _forwardCache.remove(cacheKey);
      return null;
    }

    return cached.bundle;
  }

  /// Cleanup expired cache entries
  ///
  /// Removes expired entries from forward cache.
  void cleanupExpiredCache() {
    final now = DateTime.now();
    final expired = <String>[];
    
    for (final entry in _forwardCache.entries) {
      if (!entry.value.expiresAt.isAfter(now)) {
        expired.add(entry.key);
      }
    }
    
    for (final key in expired) {
      _forwardCache.remove(key);
    }
    
    if (expired.isNotEmpty) {
      developer.log(
        'Cleaned up ${expired.length} expired prekey bundle cache entries',
        name: _logName,
      );
    }
  }

  /// Clear all cache entries
  void clearCache() {
    _forwardCache.clear();
    developer.log('Cleared all prekey bundle cache entries', name: _logName);
  }
}

/// Cached prekey bundle forward entry
class _CachedPreKeyForward {
  final SignalPreKeyBundle bundle;
  final DateTime expiresAt;
  final int hopCount;

  _CachedPreKeyForward({
    required this.bundle,
    required this.expiresAt,
    required this.hopCount,
  });
}
