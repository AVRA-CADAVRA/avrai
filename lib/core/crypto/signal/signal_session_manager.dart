// Signal Protocol Session Manager for Phase 14: Signal Protocol Implementation
// Option 1: libsignal-ffi via FFI
// Manages Signal Protocol session states for Double Ratchet

import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:sembast/sembast.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/models/connection_metrics.dart';

/// Signal Protocol Session Manager
///
/// Manages Signal Protocol session states for Double Ratchet algorithm.
/// Sessions are stored locally and used for encrypting/decrypting messages.
///
/// Phase 14: Signal Protocol Implementation - Option 1
class SignalSessionManager {
  static const String _logName = 'SignalSessionManager';
  static const String _sessionsStoreName = 'signal_sessions';
  static const String _sessionRecordsStoreName = 'signal_session_records';
  static const String _remoteIdentityKeysStoreName =
      'signal_remote_identity_keys';
  static const String _channelBindingHashesStoreName =
      'signal_channel_binding_hashes';

  final Database _database;
  // Note: _ffiBindings kept for potential future use (e.g., session serialization)
  // ignore: unused_field
  final SignalFFIBindings _ffiBindings;
  final SignalKeyManager _keyManager;

  // In-memory cache of active sessions
  final Map<String, SignalSessionState> _sessionCache = {};

  // Store for session states
  late final StoreRef<String, Map<String, Object?>> _sessionsStore;
  late final StoreRef<String, Map<String, Object?>> _sessionRecordsStore;
  late final StoreRef<String, Map<String, Object?>> _remoteIdentityKeysStore;
  late final StoreRef<String, Map<String, Object?>> _channelBindingHashesStore;

  // In-memory caches used by synchronous native callbacks.
  final Map<String, Uint8List> _sessionRecordCache = {};
  final Map<String, Uint8List> _remoteIdentityKeyCache = {};

  // Channel binding hash cache (handshake hash from Signal Protocol key exchange)
  final Map<String, Uint8List> _channelBindingHashCache = {};

  SignalSessionManager({
    required Database database,
    required SignalFFIBindings ffiBindings,
    required SignalKeyManager keyManager,
  })  : _database = database,
        _ffiBindings = ffiBindings,
        _keyManager = keyManager {
    _sessionsStore = stringMapStoreFactory.store(_sessionsStoreName);
    _sessionRecordsStore =
        stringMapStoreFactory.store(_sessionRecordsStoreName);
    _remoteIdentityKeysStore =
        stringMapStoreFactory.store(_remoteIdentityKeysStoreName);
    _channelBindingHashesStore =
        stringMapStoreFactory.store(_channelBindingHashesStoreName);
  }

  /// Warm the caches used by native store callbacks.
  ///
  /// This must be called during app initialization (async is OK there).
  Future<void> warmNativeCaches() async {
    try {
      final sessionRecords = await _sessionRecordsStore.find(_database);
      for (final rec in sessionRecords) {
        final b64 = rec.value['b64'] as String?;
        if (b64 == null || b64.isEmpty) continue;
        try {
          _sessionRecordCache[rec.key] = base64Decode(b64);
        } catch (_) {
          // ignore corrupt record
        }
      }

      final identityRecords = await _remoteIdentityKeysStore.find(_database);
      for (final rec in identityRecords) {
        final b64 = rec.value['b64'] as String?;
        if (b64 == null || b64.isEmpty) continue;
        try {
          _remoteIdentityKeyCache[rec.key] = base64Decode(b64);
        } catch (_) {
          // ignore corrupt record
        }
      }
    } catch (e, st) {
      developer.log(
        'Failed to warm native caches: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Uint8List? getCachedSessionRecordBytes({
    required String addressName,
    required int deviceId,
  }) {
    final key =
        _getSessionRecordKey(addressName: addressName, deviceId: deviceId);
    return _sessionRecordCache[key];
  }

  void cacheSessionRecordBytes({
    required String addressName,
    required int deviceId,
    required Uint8List bytes,
  }) {
    final key =
        _getSessionRecordKey(addressName: addressName, deviceId: deviceId);
    _sessionRecordCache[key] = bytes;
  }

  Uint8List? getCachedRemoteIdentityKeyBytes({
    required String addressName,
    required int deviceId,
  }) {
    final key =
        _getRemoteIdentityKeyKey(addressName: addressName, deviceId: deviceId);
    return _remoteIdentityKeyCache[key];
  }

  void cacheRemoteIdentityKeyBytes({
    required String addressName,
    required int deviceId,
    required Uint8List bytes,
  }) {
    final key =
        _getRemoteIdentityKeyKey(addressName: addressName, deviceId: deviceId);
    _remoteIdentityKeyCache[key] = bytes;
  }

  /// Get or create session for a recipient
  ///
  /// If session doesn't exist, performs X3DH key exchange to establish one.
  ///
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  ///
  /// **Returns:**
  /// Session state for the recipient
  Future<SignalSessionState> getOrCreateSession(String recipientId) async {
    try {
      // Check cache first
      if (_sessionCache.containsKey(recipientId)) {
        return _sessionCache[recipientId]!;
      }

      // Try to load from database
      final storedSession = await _loadSession(recipientId);
      if (storedSession != null) {
        _sessionCache[recipientId] = storedSession;
        return storedSession;
      }

      // Create new session via X3DH key exchange
      developer.log(
        'Creating new Signal Protocol session for recipient: $recipientId',
        name: _logName,
      );

      // Fetch recipient's prekey bundle
      // ignore: unused_local_variable - Fetched but not used because method throws exception
      final preKeyBundle = await _keyManager.fetchPreKeyBundle(recipientId);

      // Get our identity key
      // ignore: unused_local_variable - Fetched but not used because method throws exception
      final identityKeyPair = await _keyManager.getOrGenerateIdentityKeyPair();

      // Perform X3DH key exchange
      // NOTE: This requires storeCallbacks, which creates a circular dependency
      // SignalProtocolService handles X3DH directly, so this method should not be called
      // for session creation. Use SignalProtocolService.encryptMessage() instead.
      throw SignalProtocolException(
        'X3DH key exchange requires storeCallbacks. '
        'Use SignalProtocolService.encryptMessage() which handles this automatically.',
        code: 'STORE_CALLBACKS_REQUIRED',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error getting/creating session: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Get session for a recipient (returns null if doesn't exist)
  Future<SignalSessionState?> getSession(String recipientId) async {
    // Check cache first
    if (_sessionCache.containsKey(recipientId)) {
      return _sessionCache[recipientId];
    }

    // Load from database
    final session = await _loadSession(recipientId);
    if (session != null) {
      _sessionCache[recipientId] = session;
      return session;
    }

    // Fallback: if we have a persisted libsignal session record, treat it as “session exists”
    // even if we haven't stored a full SignalSessionState.
    try {
      final recordBytes = await loadSessionRecordBytes(
        addressName: recipientId,
        deviceId: 1,
      );
      if (recordBytes != null && recordBytes.isNotEmpty) {
        final placeholder = SignalSessionState(
          recipientId: recipientId,
          createdAt: DateTime.now(),
        );
        _sessionCache[recipientId] = placeholder;
        return placeholder;
      }
    } catch (_) {}

    return null;
  }

  /// Save session state
  Future<void> _saveSession(SignalSessionState session) async {
    try {
      final key = _getSessionKey(session.recipientId);
      final json = session.toJson();

      await _sessionsStore.record(key).put(_database, json);

      developer.log(
        'Session saved for recipient: ${session.recipientId}',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error saving session: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Load session state from database
  Future<SignalSessionState?> _loadSession(String recipientId) async {
    try {
      final key = _getSessionKey(recipientId);
      final json = await _sessionsStore.record(key).get(_database);

      if (json == null) {
        return null;
      }

      return SignalSessionState.fromJson(json.cast<String, dynamic>());
    } catch (e, stackTrace) {
      developer.log(
        'Error loading session: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Update session state (after encryption/decryption)
  Future<void> updateSession(SignalSessionState session) async {
    try {
      _sessionCache[session.recipientId] = session;
      await _saveSession(session);
    } catch (e, stackTrace) {
      developer.log(
        'Error updating session: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Increment message count for a session
  ///
  /// Called after each encryption or decryption to track total message count.
  Future<void> incrementMessageCount(String recipientId) async {
    try {
      final session = await getSession(recipientId);
      if (session != null) {
        final updatedSession = session.copyWith(
          totalMessageCount: session.totalMessageCount + 1,
          lastUsedAt: DateTime.now(),
        );
        await updateSession(updatedSession);
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error incrementing message count: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Non-fatal: continue without updating count
    }
  }

  /// Check if session needs re-keying
  ///
  /// Re-keying is needed if:
  /// - Total message count >= 1000, OR
  /// - Last re-key was more than 24 hours ago
  ///
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  ///
  /// **Returns:**
  /// `true` if re-keying is needed, `false` otherwise
  Future<bool> needsRekeying(String recipientId) async {
    try {
      final session = await getSession(recipientId);
      if (session == null) {
        return false; // No session to re-key
      }

      // Check message count threshold (1000 messages)
      if (session.totalMessageCount >= 1000) {
        developer.log(
          'Session re-keying needed for $recipientId: message count (${session.totalMessageCount}) >= 1000',
          name: _logName,
        );
        return true;
      }

      // Check time threshold (24 hours)
      final lastRekeyTime = session.lastRekeyedAt ?? session.createdAt;
      final timeSinceRekey = DateTime.now().difference(lastRekeyTime);
      if (timeSinceRekey.inHours >= 24) {
        developer.log(
          'Session re-keying needed for $recipientId: time since last re-key (${timeSinceRekey.inHours}h) >= 24h',
          name: _logName,
        );
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking re-keying need: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false; // On error, don't trigger re-keying
    }
  }

  /// Mark session as re-keyed
  ///
  /// Updates the session's lastRekeyedAt timestamp and resets message count.
  ///
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  Future<void> markRekeyed(String recipientId) async {
    try {
      final session = await getSession(recipientId);
      if (session != null) {
        final updatedSession = session.copyWith(
          lastRekeyedAt: DateTime.now(),
          totalMessageCount: 0, // Reset count after re-keying
        );
        await updateSession(updatedSession);
        developer.log(
          'Session marked as re-keyed for recipient: $recipientId',
          name: _logName,
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error marking session as re-keyed: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Non-fatal: continue
    }
  }

  /// Delete session for a recipient
  Future<void> deleteSession(String recipientId) async {
    try {
      _sessionCache.remove(recipientId);

      final key = _getSessionKey(recipientId);
      await _sessionsStore.record(key).delete(_database);

      // Also delete channel binding hash when session is deleted
      await deleteChannelBindingHash(recipientId);

      developer.log('Session deleted for recipient: $recipientId',
          name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting session: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Check if session should be closed based on connection quality (AI2AI-specific)
  ///
  /// Sessions are closed if connection quality is below threshold and connection
  /// has been active for sufficient duration.
  ///
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  /// - `metrics`: ConnectionMetrics for the connection
  ///
  /// **Returns:**
  /// `true` if session should be closed, `false` otherwise
  bool shouldCloseSessionBasedOnQuality(
    String recipientId,
    ConnectionMetrics metrics,
  ) {
    try {
      const qualityThreshold = 0.4; // Poor quality threshold
      const minDurationForClosure =
          Duration(hours: 1); // Minimum connection duration

      // Skip if connection hasn't been active long enough
      final connectionDuration = DateTime.now().difference(metrics.startTime);
      if (connectionDuration < minDurationForClosure) {
        return false;
      }

      // Calculate quality score (average of learning effectiveness and AI pleasure)
      final qualityScore =
          (metrics.learningEffectiveness + metrics.aiPleasureScore) / 2.0;

      // Close session if quality is below threshold
      if (qualityScore < qualityThreshold) {
        developer.log(
          'Session should be closed for $recipientId: quality=${qualityScore.toStringAsFixed(2)} < $qualityThreshold',
          name: _logName,
        );
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking if session should be closed: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false; // On error, don't close session
    }
  }

  /// Check if session should be maintained based on connection quality (AI2AI-specific)
  ///
  /// Sessions are maintained for high-quality connections to ensure continued
  /// secure communication.
  ///
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  /// - `metrics`: ConnectionMetrics for the connection
  ///
  /// **Returns:**
  /// `true` if session should be maintained, `false` otherwise
  bool shouldMaintainSession(String recipientId, ConnectionMetrics metrics) {
    try {
      const qualityThreshold = 0.6; // Good quality threshold

      // Calculate quality score
      final qualityScore =
          (metrics.learningEffectiveness + metrics.aiPleasureScore) / 2.0;

      // Maintain session if quality is above threshold
      if (qualityScore >= qualityThreshold) {
        developer.log(
          'Session should be maintained for $recipientId: quality=${qualityScore.toStringAsFixed(2)} >= $qualityThreshold',
          name: _logName,
        );
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking if session should be maintained: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false; // On error, don't maintain session
    }
  }

  /// Check if session should be renewed based on connection quality (AI2AI-specific)
  ///
  /// Sessions are renewed for high-quality, active connections to maintain
  /// fresh keys and ensure continued security.
  ///
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  /// - `metrics`: ConnectionMetrics for the connection
  ///
  /// **Returns:**
  /// `true` if session should be renewed, `false` otherwise
  Future<bool> shouldRenewSessionBasedOnQuality(
    String recipientId,
    ConnectionMetrics metrics,
  ) async {
    try {
      const renewalQualityThreshold = 0.6; // Good quality threshold
      const renewalMessageCountThreshold = 500; // High message count threshold
      const renewalInterval = Duration(hours: 12); // Renewal interval

      // Calculate quality score
      final qualityScore =
          (metrics.learningEffectiveness + metrics.aiPleasureScore) / 2.0;

      // Check if connection meets quality threshold
      if (qualityScore < renewalQualityThreshold) {
        return false; // Quality too low for renewal
      }

      // Check session state
      final session = await getSession(recipientId);
      if (session == null) {
        return false; // No session to renew
      }

      // Check if session meets renewal criteria
      final highMessageCount =
          session.totalMessageCount >= renewalMessageCountThreshold;
      final lastRekeyTime = session.lastRekeyedAt ?? session.createdAt;
      final timeSinceRekey = DateTime.now().difference(lastRekeyTime);
      final meetsTimeThreshold = timeSinceRekey >= renewalInterval;

      // Renew if meets criteria
      if (highMessageCount || meetsTimeThreshold) {
        developer.log(
          'Session should be renewed for $recipientId: quality=${qualityScore.toStringAsFixed(2)}, messages=${session.totalMessageCount}, timeSinceRekey=${timeSinceRekey.inHours}h',
          name: _logName,
        );
        return true;
      }

      return false;
    } catch (e, stackTrace) {
      developer.log(
        'Error checking if session should be renewed: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return false; // On error, don't renew session
    }
  }

  /// Get sessions that should be closed based on connection quality (AI2AI-specific)
  ///
  /// This method is used by ConnectionOrchestrator to find sessions that should
  /// be closed based on their connection metrics.
  ///
  /// **Parameters:**
  /// - `metricsByAgentId`: Map of agent ID to ConnectionMetrics
  ///
  /// **Returns:**
  /// List of recipient IDs whose sessions should be closed
  List<String> getSessionsToClose(
    Map<String, ConnectionMetrics> metricsByAgentId,
  ) {
    final sessionsToClose = <String>[];

    for (final entry in metricsByAgentId.entries) {
      final agentId = entry.key;
      final metrics = entry.value;

      if (shouldCloseSessionBasedOnQuality(agentId, metrics)) {
        sessionsToClose.add(agentId);
      }
    }

    return sessionsToClose;
  }

  /// Get sessions that should be maintained based on connection quality (AI2AI-specific)
  ///
  /// This method is used by ConnectionOrchestrator to identify high-quality
  /// connections that should maintain their sessions.
  ///
  /// **Parameters:**
  /// - `metricsByAgentId`: Map of agent ID to ConnectionMetrics
  ///
  /// **Returns:**
  /// List of recipient IDs whose sessions should be maintained
  List<String> getSessionsToMaintain(
    Map<String, ConnectionMetrics> metricsByAgentId,
  ) {
    final sessionsToMaintain = <String>[];

    for (final entry in metricsByAgentId.entries) {
      final agentId = entry.key;
      final metrics = entry.value;

      if (shouldMaintainSession(agentId, metrics)) {
        sessionsToMaintain.add(agentId);
      }
    }

    return sessionsToMaintain;
  }

  /// Get sessions that should be renewed based on connection quality (AI2AI-specific)
  ///
  /// This method is used by ConnectionOrchestrator to identify sessions that
  /// should be renewed based on their connection quality and activity.
  ///
  /// **Parameters:**
  /// - `metricsByAgentId`: Map of agent ID to ConnectionMetrics
  ///
  /// **Returns:**
  /// List of recipient IDs whose sessions should be renewed
  Future<List<String>> getSessionsToRenew(
    Map<String, ConnectionMetrics> metricsByAgentId,
  ) async {
    final sessionsToRenew = <String>[];

    for (final entry in metricsByAgentId.entries) {
      final agentId = entry.key;
      final metrics = entry.value;

      if (await shouldRenewSessionBasedOnQuality(agentId, metrics)) {
        sessionsToRenew.add(agentId);
      }
    }

    return sessionsToRenew;
  }

  /// Get session key for database storage
  String _getSessionKey(String recipientId) {
    return 'session_$recipientId';
  }

  String _getSessionRecordKey({
    required String addressName,
    required int deviceId,
  }) {
    return 'session_record_${addressName}_$deviceId';
  }

  String _getRemoteIdentityKeyKey({
    required String addressName,
    required int deviceId,
  }) {
    return 'remote_identity_${addressName}_$deviceId';
  }

  /// Load the raw libsignal session record bytes for a protocol address.
  ///
  /// Used by native libsignal store callbacks (session store).
  Future<Uint8List?> loadSessionRecordBytes({
    required String addressName,
    required int deviceId,
  }) async {
    try {
      final cached = getCachedSessionRecordBytes(
        addressName: addressName,
        deviceId: deviceId,
      );
      if (cached != null) return cached;

      final key =
          _getSessionRecordKey(addressName: addressName, deviceId: deviceId);
      final json = await _sessionRecordsStore.record(key).get(_database);
      final b64 = json?['b64'] as String?;
      if (b64 == null || b64.isEmpty) return null;
      final decoded = base64Decode(b64);
      _sessionRecordCache[key] = decoded;
      return decoded;
    } catch (e, st) {
      developer.log(
        'Error loading session record bytes: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Save the raw libsignal session record bytes for a protocol address.
  ///
  /// Used by native libsignal store callbacks (session store).
  Future<void> saveSessionRecordBytes({
    required String addressName,
    required int deviceId,
    required Uint8List bytes,
  }) async {
    final key =
        _getSessionRecordKey(addressName: addressName, deviceId: deviceId);
    _sessionRecordCache[key] = bytes;
    await _sessionRecordsStore.record(key).put(_database, <String, Object?>{
      'b64': base64Encode(bytes),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<Uint8List?> loadRemoteIdentityKeyBytes({
    required String addressName,
    required int deviceId,
  }) async {
    try {
      final cached = getCachedRemoteIdentityKeyBytes(
        addressName: addressName,
        deviceId: deviceId,
      );
      if (cached != null) return cached;

      final key = _getRemoteIdentityKeyKey(
          addressName: addressName, deviceId: deviceId);
      final json = await _remoteIdentityKeysStore.record(key).get(_database);
      final b64 = json?['b64'] as String?;
      if (b64 == null || b64.isEmpty) return null;
      final decoded = base64Decode(b64);
      _remoteIdentityKeyCache[key] = decoded;
      return decoded;
    } catch (e, st) {
      developer.log(
        'Error loading remote identity key bytes: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> saveRemoteIdentityKeyBytes({
    required String addressName,
    required int deviceId,
    required Uint8List bytes,
  }) async {
    final key =
        _getRemoteIdentityKeyKey(addressName: addressName, deviceId: deviceId);
    _remoteIdentityKeyCache[key] = bytes;
    await _remoteIdentityKeysStore.record(key).put(_database, <String, Object?>{
      'b64': base64Encode(bytes),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Clear all sessions (for testing/debugging)
  Future<void> clearAllSessions() async {
    try {
      _sessionCache.clear();
      _sessionRecordCache.clear();
      _remoteIdentityKeyCache.clear();
      _channelBindingHashCache.clear();
      await _sessionsStore.delete(_database);
      await _sessionRecordsStore.delete(_database);
      await _remoteIdentityKeysStore.delete(_database);
      await _channelBindingHashesStore.delete(_database);
      developer.log('All sessions cleared', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error clearing sessions: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Set channel binding hash for a recipient (handshake hash from Signal Protocol key exchange)
  ///
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  /// - `handshakeHash`: Handshake hash from X3DH/PQXDH key exchange
  Future<void> setChannelBindingHash(
    String recipientId,
    Uint8List handshakeHash,
  ) async {
    try {
      _channelBindingHashCache[recipientId] = handshakeHash;
      await _channelBindingHashesStore.record(recipientId).put(_database, {
        'handshake_hash': base64Encode(handshakeHash),
        'updatedAt': DateTime.now().toIso8601String(),
      });
      developer.log(
        'Channel binding hash stored for recipient: $recipientId',
        name: _logName,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error storing channel binding hash: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Non-fatal: continue without channel binding hash
    }
  }

  /// Get channel binding hash for a recipient
  ///
  /// **Parameters:**
  /// - `recipientId`: Recipient's agent ID
  ///
  /// **Returns:**
  /// Handshake hash from Signal Protocol key exchange, or null if not found
  Future<Uint8List?> getChannelBindingHash(String recipientId) async {
    try {
      // Check cache first
      final cached = _channelBindingHashCache[recipientId];
      if (cached != null) return cached;

      // Load from database
      final json =
          await _channelBindingHashesStore.record(recipientId).get(_database);
      if (json == null) return null;

      final hashBase64 = json['handshake_hash'] as String?;
      if (hashBase64 == null || hashBase64.isEmpty) return null;

      final hash = base64Decode(hashBase64);
      _channelBindingHashCache[recipientId] = hash;
      return hash;
    } catch (e, stackTrace) {
      developer.log(
        'Error loading channel binding hash: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Delete channel binding hash for a recipient (when session is deleted)
  Future<void> deleteChannelBindingHash(String recipientId) async {
    try {
      _channelBindingHashCache.remove(recipientId);
      await _channelBindingHashesStore.record(recipientId).delete(_database);
    } catch (e, stackTrace) {
      developer.log(
        'Error deleting channel binding hash: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Non-fatal: continue
    }
  }
}
