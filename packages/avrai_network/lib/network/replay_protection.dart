import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';
import 'dart:math';

/// Replay protection using nonce-based sliding window
/// 
/// **BitChat-Inspired Pattern:** Similar to Noise Protocol's sliding window replay protection
/// **AI2AI-Specific:** Tracks nonces per AI agent ID (not device ID) - aligns with AI2AI connection model
/// 
/// **Security Features:**
/// - Sliding window of 1024 nonces per peer
/// - Nonce: 64-bit counter + 64-bit random (128 bits total)
/// - Rejects messages with nonces outside window or already seen
/// - Automatic expiration (1 hour)
/// 
/// **Integration:** Works with existing `_seenBleMessageHashes` system - enhances it, doesn't replace
class ReplayProtection {
  static const String _logName = 'ReplayProtection';
  
  /// Sliding window size (same as BitChat/Noise Protocol)
  static const int windowSize = 1024;
  
  /// Nonce expiration time (1 hour)
  static const Duration nonceExpiration = Duration(hours: 1);
  
  /// Per-peer nonce windows (keyed by AI agent ID)
  final Map<String, _NonceWindow> _nonceWindows = {};
  
  /// Cleanup timer for expired nonces
  Timer? _cleanupTimer;
  
  ReplayProtection() {
    // Start periodic cleanup
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _cleanupExpiredNonces(),
    );
  }
  
  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _nonceWindows.clear();
  }
  
  /// Generate a nonce for outgoing message
  /// 
  /// **Nonce Format:** 64-bit counter + 64-bit random (128 bits total)
  /// - Counter: Increments for each message from this peer
  /// - Random: Prevents nonce prediction
  /// 
  /// **Parameters:**
  /// - `peerAgentId`: AI agent ID of the peer
  /// 
  /// **Returns:**
  /// 128-bit nonce (16 bytes)
  Uint8List generateNonce(String peerAgentId) {
    final window = _getOrCreateWindow(peerAgentId);
    final counter = window.nextCounter();
    
    // Generate 64-bit random component
    final random = Random.secure();
    final randomBytes = Uint8List(8);
    for (int i = 0; i < randomBytes.length; i++) {
      randomBytes[i] = random.nextInt(256);
    }
    
    // Combine: counter (8 bytes) + random (8 bytes) = 16 bytes
    final nonce = Uint8List(16);
    final counterBytes = ByteData(8);
    counterBytes.setUint64(0, counter, Endian.little);
    nonce.setRange(0, 8, counterBytes.buffer.asUint8List());
    nonce.setRange(8, 16, randomBytes);
    
    developer.log(
      'Generated nonce for peer $peerAgentId: counter=$counter',
      name: _logName,
    );
    
    return nonce;
  }
  
  /// Check if nonce is valid (not replayed)
  /// 
  /// **Algorithm:**
  /// 1. Extract counter from nonce
  /// 2. Check if counter is within sliding window
  /// 3. Check if nonce has been seen before
  /// 4. Add nonce to window if valid
  /// 
  /// **Parameters:**
  /// - `nonce`: 128-bit nonce to check
  /// - `peerAgentId`: AI agent ID of the peer
  /// 
  /// **Returns:**
  /// `true` if nonce is valid (not replayed), `false` if replayed or invalid
  bool checkNonce(Uint8List nonce, String peerAgentId) {
    if (nonce.length != 16) {
      developer.log(
        'Invalid nonce length: ${nonce.length} (expected 16)',
        name: _logName,
      );
      return false;
    }
    
    final window = _getOrCreateWindow(peerAgentId);
    
    // Extract counter (first 8 bytes)
    final counterBytes = ByteData.sublistView(nonce.sublist(0, 8));
    final counter = counterBytes.getUint64(0, Endian.little);
    
    // Check if counter is within sliding window
    // Window is [baseCounter, baseCounter + windowSize)
    final baseCounter = window.baseCounter;
    if (counter < baseCounter) {
      // Counter is too old (outside window)
      developer.log(
        'Nonce counter too old: $counter < $baseCounter (peer: $peerAgentId)',
        name: _logName,
      );
      return false;
    }
    
    if (counter >= baseCounter + windowSize) {
      // Counter is too far in future, advance window
      window.advanceWindow(counter);
    }
    
    // Check if nonce has been seen before
    final nonceKey = _nonceToKey(nonce);
    if (window.seenNonces.contains(nonceKey)) {
      developer.log(
        'Replay detected: nonce already seen (peer: $peerAgentId, counter: $counter)',
        name: _logName,
      );
      return false;
    }
    
    // Add nonce to window
    window.addNonce(nonceKey, counter);
    
    developer.log(
      'Nonce accepted: counter=$counter (peer: $peerAgentId)',
      name: _logName,
    );
    
    return true;
  }
  
  /// Get or create nonce window for peer
  _NonceWindow _getOrCreateWindow(String peerAgentId) {
    return _nonceWindows.putIfAbsent(
      peerAgentId,
      () => _NonceWindow(),
    );
  }
  
  /// Convert nonce to key for storage
  String _nonceToKey(Uint8List nonce) {
    // Use first 12 bytes as key (sufficient for uniqueness)
    return nonce.sublist(0, 12).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
  
  /// Clean up expired nonces
  void _cleanupExpiredNonces() {
    final now = DateTime.now();
    final expiredPeers = <String>[];
    
    for (final entry in _nonceWindows.entries) {
      final window = entry.value;
      if (window.isExpired(now)) {
        expiredPeers.add(entry.key);
      } else {
        window.cleanupExpired(now);
      }
    }
    
    // Remove expired windows
    for (final peerId in expiredPeers) {
      _nonceWindows.remove(peerId);
      developer.log(
        'Removed expired nonce window for peer: $peerId',
        name: _logName,
      );
    }
  }
  
  /// Get statistics for debugging
  Map<String, dynamic> getStats() {
    return {
      'activeWindows': _nonceWindows.length,
      'totalNonces': _nonceWindows.values
          .fold(0, (sum, window) => sum + window.seenNonces.length),
    };
  }
}

/// Nonce window for a single peer
class _NonceWindow {
  int _baseCounter = 0;
  int _nextCounter = 0;
  final Set<String> _seenNonces = {};
  final Map<String, DateTime> _nonceTimestamps = {};
  final DateTime _createdAt = DateTime.now();
  
  int get baseCounter => _baseCounter;
  Set<String> get seenNonces => _seenNonces;
  
  /// Get next counter value
  int nextCounter() {
    return _nextCounter++;
  }
  
  /// Advance window to include new counter
  void advanceWindow(int newCounter) {
    final newBase = (newCounter - ReplayProtection.windowSize + 1).clamp(0, newCounter);
    
    // Remove nonces outside new window
    final toRemove = <String>[];
    for (final entry in _nonceTimestamps.entries) {
      // Extract counter from nonce key (simplified - in production would parse properly)
      // For now, just remove old entries
      if (_baseCounter < newBase - ReplayProtection.windowSize) {
        toRemove.add(entry.key);
      }
    }
    
    for (final key in toRemove) {
      _seenNonces.remove(key);
      _nonceTimestamps.remove(key);
    }
    
    _baseCounter = newBase;
  }
  
  /// Add nonce to window
  void addNonce(String nonceKey, int counter) {
    _seenNonces.add(nonceKey);
    _nonceTimestamps[nonceKey] = DateTime.now();
    
    // Keep window size manageable
    if (_seenNonces.length > ReplayProtection.windowSize * 2) {
      // Remove oldest nonces
      final sorted = _nonceTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final toRemove = sorted.take(_seenNonces.length - ReplayProtection.windowSize);
      for (final entry in toRemove) {
        _seenNonces.remove(entry.key);
        _nonceTimestamps.remove(entry.key);
      }
    }
  }
  
  /// Check if window is expired
  bool isExpired(DateTime now) {
    return now.difference(_createdAt) > ReplayProtection.nonceExpiration;
  }
  
  /// Clean up expired nonces within window
  void cleanupExpired(DateTime now) {
    final expired = <String>[];
    for (final entry in _nonceTimestamps.entries) {
      if (now.difference(entry.value) > ReplayProtection.nonceExpiration) {
        expired.add(entry.key);
      }
    }
    
    for (final key in expired) {
      _seenNonces.remove(key);
      _nonceTimestamps.remove(key);
    }
  }
}
