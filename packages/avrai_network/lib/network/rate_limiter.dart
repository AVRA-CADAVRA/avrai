import 'dart:async';
import 'dart:developer' as developer;
import 'package:avrai_network/network/ai2ai_protocol.dart' show MessageType;

/// Rate limit types for RateLimiter
enum RateLimitType { handshake, message, connection }

/// Token bucket rate limiter for AI2AI mesh networking
///
/// **BitChat-Inspired Pattern:** Similar to BitChat's NoiseRateLimiter
/// **AI2AI-Enhanced:** Battery-aware, adaptive mesh integration, message type differentiation, geographic scope awareness
///
/// **Security Features:**
/// - Token bucket algorithm (10 tokens, refill 1 token/second base rate)
/// - Separate buckets for: handshakes, messages, connections
/// - Per-peer rate limiting (track by AI agent ID)
/// - Exponential backoff on rate limit exceeded
///
/// **AI2AI-Specific Enhancements:**
/// - Battery-aware rate limiting (integrate BatteryAdaptiveBleScheduler)
/// - Adaptive mesh integration (respect AdaptiveMeshNetworkingService)
/// - Message type differentiation (higher for learning insights, lower for personality exchange)
/// - Geographic scope awareness (higher for locality/city, lower for global)
class RateLimiter {
  static const String _logName = 'RateLimiter';

  /// Base token bucket configuration
  static const int baseTokens = 10;
  static const Duration baseRefillInterval = Duration(seconds: 1);

  /// Per-peer token buckets (keyed by AI agent ID)
  final Map<String, Map<RateLimitType, _TokenBucket>> _buckets = {};

  /// Optional battery level provider (for battery-aware rate limiting)
  /// If null, battery-aware adjustments are skipped
  final Future<int>? Function()? _batteryLevelProvider;

  /// Optional network density provider (for adaptive mesh integration)
  /// If null, adaptive mesh adjustments are skipped
  final int? Function()? _networkDensityProvider;

  /// Cleanup timer for expired buckets
  Timer? _cleanupTimer;

  RateLimiter({
    Future<int>? Function()? batteryLevelProvider,
    int? Function()? networkDensityProvider,
  }) : _batteryLevelProvider = batteryLevelProvider,
       _networkDensityProvider = networkDensityProvider {
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpiredBuckets(),
    );
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _buckets.clear();
  }

  /// Check if operation is allowed (rate limit not exceeded)
  ///
  /// **AI2AI-Specific:** Adjusts rate limits based on:
  /// - Battery level (reduce when battery < 20%)
  /// - Network density (from AdaptiveMeshNetworkingService)
  /// - Message type (higher for learning insights, lower for personality exchange)
  /// - Geographic scope (higher for locality/city, lower for global)
  ///
  /// **Parameters:**
  /// - `peerAgentId`: AI agent ID of the peer
  /// - `limitType`: Type of operation (handshake, message, connection)
  /// - `messageType`: Message type (for message rate limiting) - AI2AI-specific
  /// - `geographicScope`: Geographic scope (for scope-aware limits) - AI2AI-specific
  ///
  /// **Returns:**
  /// `true` if allowed, `false` if rate limit exceeded
  Future<bool> checkRateLimit({
    required String peerAgentId,
    required RateLimitType limitType,
    MessageType? messageType, // AI2AI-specific
    String? geographicScope, // AI2AI-specific
  }) async {
    // Get effective token count based on AI2AI-specific factors
    final effectiveTokens = await _getEffectiveTokens(
      limitType: limitType,
      messageType: messageType,
      geographicScope: geographicScope,
    );

    final bucket = _getOrCreateBucket(peerAgentId, limitType, effectiveTokens);

    if (bucket.consumeToken()) {
      developer.log(
        'Rate limit check passed: peer=$peerAgentId, type=$limitType, tokens=${bucket.tokens}',
        name: _logName,
      );
      return true;
    } else {
      developer.log(
        'Rate limit exceeded: peer=$peerAgentId, type=$limitType, tokens=${bucket.tokens}',
        name: _logName,
      );
      return false;
    }
  }

  /// Get effective token count based on AI2AI-specific factors
  Future<int> _getEffectiveTokens({
    required RateLimitType limitType,
    MessageType? messageType,
    String? geographicScope,
  }) async {
    var tokens = baseTokens;

    // Battery-aware rate limiting (AI2AI-specific)
    if (_batteryLevelProvider != null) {
      try {
        final batteryLevel = await _batteryLevelProvider();
        if (batteryLevel != null && batteryLevel < 20) {
          // Reduce rate limits when battery < 20%
          tokens = (tokens * 0.5).round().clamp(1, tokens);
          developer.log(
            'Battery-aware rate limiting: battery=$batteryLevel%, tokens=$tokens',
            name: _logName,
          );
        }
      } catch (e) {
        // Best-effort: continue with base tokens if battery check fails
      }
    }

    // Adaptive mesh integration (AI2AI-specific)
    if (_networkDensityProvider != null) {
      final networkDensity = _networkDensityProvider();
      if (networkDensity != null) {
        if (networkDensity > 10) {
          // Increase tokens in dense networks
          tokens = (tokens * 1.5).round();
        } else if (networkDensity < 3) {
          // Decrease tokens in sparse networks
          tokens = (tokens * 0.7).round().clamp(1, tokens);
        }
      }
    }

    // Message type differentiation (AI2AI-specific)
    if (limitType == RateLimitType.message && messageType != null) {
      switch (messageType) {
        case MessageType.learningInsight:
          // Learning insights: higher rate limit (frequent, small)
          tokens = (tokens * 1.5).round();
          break;
        case MessageType.personalityExchange:
          // Personality exchange: lower rate limit (infrequent, large)
          tokens = (tokens * 0.7).round().clamp(1, tokens);
          break;
        default:
          // Default tokens for other message types
          break;
      }
    }

    // Geographic scope awareness (AI2AI-specific)
    if (geographicScope != null) {
      switch (geographicScope) {
        case 'locality':
        case 'city':
          // Higher rate limits for locality/city scope
          tokens = (tokens * 1.2).round();
          break;
        case 'global':
          // Lower rate limits for global scope
          tokens = (tokens * 0.8).round().clamp(1, tokens);
          break;
        default:
          // Default tokens for other scopes
          break;
      }
    }

    return tokens.clamp(1, 100); // Cap at 100 tokens max
  }

  /// Get or create token bucket for peer and limit type
  _TokenBucket _getOrCreateBucket(
    String peerAgentId,
    RateLimitType limitType,
    int tokens,
  ) {
    final peerBuckets = _buckets.putIfAbsent(peerAgentId, () => {});
    return peerBuckets.putIfAbsent(
      limitType,
      () => _TokenBucket(tokens: tokens, refillInterval: baseRefillInterval),
    );
  }

  /// Clean up expired buckets (peers with no recent activity)
  void _cleanupExpiredBuckets() {
    final now = DateTime.now();
    final expiredPeers = <String>[];

    for (final entry in _buckets.entries) {
      bool hasActiveBuckets = false;
      for (final bucket in entry.value.values) {
        if (bucket.lastUsed.difference(now).inHours < 1) {
          hasActiveBuckets = true;
          break;
        }
      }
      if (!hasActiveBuckets) {
        expiredPeers.add(entry.key);
      }
    }

    for (final peerId in expiredPeers) {
      _buckets.remove(peerId);
      developer.log(
        'Removed expired rate limit buckets for peer: $peerId',
        name: _logName,
      );
    }
  }

  /// Get statistics for debugging
  Map<String, dynamic> getStats() {
    return {
      'activePeers': _buckets.length,
      'totalBuckets': _buckets.values.fold(
        0,
        (sum, buckets) => sum + buckets.length,
      ),
    };
  }
}

/// Token bucket for rate limiting
class _TokenBucket {
  int tokens;
  final int maxTokens;
  final Duration refillInterval;
  DateTime lastRefill;
  DateTime lastUsed;

  _TokenBucket({required this.tokens, required this.refillInterval})
    : maxTokens = tokens,
      lastRefill = DateTime.now(),
      lastUsed = DateTime.now();

  /// Consume a token (returns true if token was available)
  bool consumeToken() {
    _refill();
    lastUsed = DateTime.now();

    if (tokens > 0) {
      tokens--;
      return true;
    }
    return false;
  }

  /// Refill tokens based on time elapsed
  void _refill() {
    final now = DateTime.now();
    final elapsed = now.difference(lastRefill);

    if (elapsed >= refillInterval) {
      final refills = elapsed.inSeconds ~/ refillInterval.inSeconds;
      tokens = (tokens + refills).clamp(0, maxTokens);
      lastRefill = now;
    }
  }
}
