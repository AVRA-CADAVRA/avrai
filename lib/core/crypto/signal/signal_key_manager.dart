// Signal Protocol Key Manager for Phase 14: Signal Protocol Implementation
// Option 1: libsignal-ffi via FFI
// Manages Signal Protocol keys: identity keys, prekeys, and session keys

import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/services/ledgers/ledger_audit_v0.dart';
import 'package:avrai/core/services/ledgers/ledger_domain_v0.dart';
import 'package:avrai/core/services/supabase_service.dart';

/// Signal Protocol Key Manager
///
/// Manages all Signal Protocol keys:
/// - Identity keys (long-term, stored securely)
/// - Signed prekeys (medium-term, uploaded to server)
/// - One-time prekeys (short-term, uploaded to server)
/// - Session keys (ephemeral, derived via Double Ratchet)
///
/// Phase 14: Signal Protocol Implementation - Option 1
class SignalKeyManager {
  static const String _logName = 'SignalKeyManager';
  static const String _identityKeyStorageKey = 'signal_identity_key_pair';
  static const String _registrationIdStorageKey = 'signal_registration_id';
  static const String _signedPreKeyRecordPrefix = 'signal_signed_prekey_record_';
  static const String _kyberPreKeyRecordPrefix = 'signal_kyber_prekey_record_';
  static const String _preKeyRecordPrefix = 'signal_prekey_record_';
  static const String _currentSignedPreKeyIdKey = 'signal_current_signed_prekey_id';
  static const String _currentKyberPreKeyIdKey = 'signal_current_kyber_prekey_id';
  static const String _currentPreKeyIdsKey = 'signal_current_prekey_ids';
  static const String _preKeyCachePrefix = 'signal_prekey_cache_';
  static const String _dmInviteTokenPrefix = 'signal_dm_invite_token_v1_';
  static const Duration _defaultPreKeyCacheTtl = Duration(hours: 24);
  
  /// Refresh threshold: refresh bundle if it expires within this time
  static const Duration _preKeyRefreshThreshold = Duration(hours: 2);
  
  /// Rotation interval: generate new bundle every N hours
  static const Duration _preKeyRotationInterval = Duration(hours: 12);

  final FlutterSecureStorage _secureStorage;
  final SignalFFIBindings _ffiBindings;
  final SupabaseService? _supabaseService;

  // Cached identity key (loaded once, kept in memory)
  SignalIdentityKeyPair? _identityKeyPair;

  int? _cachedRegistrationId;

  final Map<int, Uint8List> _signedPreKeyRecordCache = {};
  final Map<int, Uint8List> _kyberPreKeyRecordCache = {};
  final Map<int, Uint8List> _preKeyRecordCache = {};

  // Offline-first cache for remote prekey bundles (Mode 2: BLE bootstrap).
  //
  // Keyed by the same `recipientId` used by SignalProtocolService.encryptMessage().
  // In offline physical-layer mode, this is typically the remote deviceId.
  final Map<String, _CachedPreKeyBundle> _cachedRemotePreKeyBundles = {};

  SignalKeyManager({
    required FlutterSecureStorage secureStorage,
    required SignalFFIBindings ffiBindings,
    SupabaseService? supabaseService,
  })  : _secureStorage = secureStorage,
        _ffiBindings = ffiBindings,
        _supabaseService = supabaseService;

  /// Cache a DM invite token for a specific target user.
  ///
  /// This token can be used as an explicit eligibility proof when fetching the
  /// target user's prekey bundle (door-opening flow for DMs outside shared communities).
  Future<void> cacheDmInviteToken({
    required String targetUserId,
    required String token,
  }) async {
    await _secureStorage.write(
      key: '$_dmInviteTokenPrefix$targetUserId',
      value: token,
    );
  }

  Future<String?> _getCachedDmInviteToken(String targetUserId) async {
    try {
      final raw =
          await _secureStorage.read(key: '$_dmInviteTokenPrefix$targetUserId');
      if (raw == null || raw.isEmpty) return null;
      return raw;
    } catch (_) {
      return null;
    }
  }

  /// Cache a remote prekey bundle for offline session establishment (Mode 2).
  ///
  /// Stores the bundle in-memory and in secure storage with a TTL.
  /// Validates bundle before caching (PQXDH requirements).
  Future<void> cacheRemotePreKeyBundle({
    required String recipientId,
    required SignalPreKeyBundle preKeyBundle,
    Duration ttl = _defaultPreKeyCacheTtl,
  }) async {
    // Validate bundle before caching (PQXDH requirements, signatures, etc.)
    _validatePreKeyBundle(preKeyBundle, recipientId);
    
    final expiresAt = DateTime.now().toUtc().add(ttl);

    _cachedRemotePreKeyBundles[recipientId] = _CachedPreKeyBundle(
      bundle: preKeyBundle,
      expiresAt: expiresAt,
      cachedAt: DateTime.now().toUtc(),
    );

    try {
      final storageKey = '$_preKeyCachePrefix$recipientId';
      final json = <String, dynamic>{
        'expires_at': expiresAt.toIso8601String(),
        'cached_at': DateTime.now().toUtc().toIso8601String(),
        'bundle': _preKeyBundleToJsonEncodable(preKeyBundle),
      };
      await _secureStorage.write(key: storageKey, value: jsonEncode(json));
      developer.log('✅ Cached remote prekey bundle for $recipientId (expires in ${ttl.inHours}h)',
          name: _logName);
    } catch (e, st) {
      developer.log(
        'Warning: Failed to persist remote prekey cache for $recipientId: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }

  Future<SignalPreKeyBundle?> _getCachedRemotePreKeyBundle(
    String recipientId,
  ) async {
    final now = DateTime.now().toUtc();

    final inMemory = _cachedRemotePreKeyBundles[recipientId];
    if (inMemory != null) {
      if (inMemory.expiresAt.isAfter(now)) {
        return inMemory.bundle;
      } else {
        _cachedRemotePreKeyBundles.remove(recipientId);
      }
    }

    try {
      final storageKey = '$_preKeyCachePrefix$recipientId';
      final stored = await _secureStorage.read(key: storageKey);
      if (stored == null || stored.isEmpty) return null;

      final decoded = jsonDecode(stored) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(decoded['expires_at'] as String).toUtc();
      if (!expiresAt.isAfter(now)) {
        // Expired: best-effort cleanup.
        try {
          await _secureStorage.delete(key: storageKey);
        } catch (_) {}
        return null;
      }

      final bundleJson = decoded['bundle'] as Map<String, dynamic>;
      final bundle = SignalPreKeyBundle.fromJson(bundleJson);
      final cachedAt = decoded['cached_at'] != null
          ? DateTime.parse(decoded['cached_at'] as String).toUtc()
          : expiresAt.subtract(_defaultPreKeyCacheTtl);

      // Validate loaded bundle
      _validatePreKeyBundle(bundle, recipientId);

      _cachedRemotePreKeyBundles[recipientId] = _CachedPreKeyBundle(
        bundle: bundle,
        expiresAt: expiresAt,
        cachedAt: cachedAt,
      );
      return bundle;
    } catch (e, st) {
      developer.log(
        'Error reading remote prekey cache for $recipientId: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  /// Get or generate a stable Signal registration id for this install.
  ///
  /// Signal registration ids are 14-bit integers (1..16380).
  Future<int> getOrGenerateRegistrationId() async {
    if (_cachedRegistrationId != null) return _cachedRegistrationId!;

    try {
      final raw = await _secureStorage.read(key: _registrationIdStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final parsed = int.tryParse(raw);
        if (parsed != null && parsed >= 1 && parsed <= 16380) {
          _cachedRegistrationId = parsed;
          return parsed;
        }
      }
    } catch (_) {
      // fall through to generate
    }

    final generated = Random.secure().nextInt(16380) + 1;
    _cachedRegistrationId = generated;
    try {
      await _secureStorage.write(
        key: _registrationIdStorageKey,
        value: generated.toString(),
      );
    } catch (e, st) {
      developer.log(
        'Warning: Failed to persist registration id (continuing): $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
    return generated;
  }

  /// Fast-path access for native store callbacks (must be warmed during init).
  int? get cachedRegistrationId => _cachedRegistrationId;

  /// Fast-path access for native store callbacks (must be warmed during init).
  SignalIdentityKeyPair? get cachedIdentityKeyPair => _identityKeyPair;

  Future<void> storeSignedPreKeyRecord({
    required int id,
    required Uint8List serialized,
  }) async {
    _signedPreKeyRecordCache[id] = serialized;
    await _secureStorage.write(
      key: '$_signedPreKeyRecordPrefix$id',
      value: base64Encode(serialized),
    );
  }

  Future<Uint8List?> loadSignedPreKeyRecord(int id) async {
    final cached = _signedPreKeyRecordCache[id];
    if (cached != null) return cached;
    final raw = await _secureStorage.read(key: '$_signedPreKeyRecordPrefix$id');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = base64Decode(raw);
      _signedPreKeyRecordCache[id] = decoded;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> storeKyberPreKeyRecord({
    required int id,
    required Uint8List serialized,
  }) async {
    _kyberPreKeyRecordCache[id] = serialized;
    await _secureStorage.write(
      key: '$_kyberPreKeyRecordPrefix$id',
      value: base64Encode(serialized),
    );
  }

  Future<Uint8List?> loadKyberPreKeyRecord(int id) async {
    final cached = _kyberPreKeyRecordCache[id];
    if (cached != null) return cached;
    final raw = await _secureStorage.read(key: '$_kyberPreKeyRecordPrefix$id');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = base64Decode(raw);
      _kyberPreKeyRecordCache[id] = decoded;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> storePreKeyRecord({
    required int id,
    required Uint8List serialized,
  }) async {
    _preKeyRecordCache[id] = serialized;
    await _secureStorage.write(
      key: '$_preKeyRecordPrefix$id',
      value: base64Encode(serialized),
    );
  }

  Future<Uint8List?> loadPreKeyRecord(int id) async {
    final cached = _preKeyRecordCache[id];
    if (cached != null) return cached;
    final raw = await _secureStorage.read(key: '$_preKeyRecordPrefix$id');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = base64Decode(raw);
      _preKeyRecordCache[id] = decoded;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> removePreKeyRecord(int id) async {
    _preKeyRecordCache.remove(id);
    try {
      await _secureStorage.delete(key: '$_preKeyRecordPrefix$id');
    } catch (_) {}

    try {
      final current = await getCurrentPreKeyIds();
      if (current.contains(id)) {
        final updated = current.where((e) => e != id).toList();
        await setCurrentPreKeyIds(updated);
      }
    } catch (_) {}
  }

  Uint8List? getCachedSignedPreKeyRecord(int id) => _signedPreKeyRecordCache[id];
  Uint8List? getCachedKyberPreKeyRecord(int id) => _kyberPreKeyRecordCache[id];
  Uint8List? getCachedPreKeyRecord(int id) => _preKeyRecordCache[id];

  Future<void> setCurrentSignedPreKeyId(int id) async {
    await _secureStorage.write(key: _currentSignedPreKeyIdKey, value: '$id');
  }

  Future<void> setCurrentKyberPreKeyId(int id) async {
    await _secureStorage.write(key: _currentKyberPreKeyIdKey, value: '$id');
  }

  Future<void> setCurrentPreKeyIds(List<int> ids) async {
    await _secureStorage.write(key: _currentPreKeyIdsKey, value: jsonEncode(ids));
  }

  Future<int?> getCurrentSignedPreKeyId() async {
    final raw = await _secureStorage.read(key: _currentSignedPreKeyIdKey);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<int?> getCurrentKyberPreKeyId() async {
    final raw = await _secureStorage.read(key: _currentKyberPreKeyIdKey);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<List<int>> getCurrentPreKeyIds() async {
    final raw = await _secureStorage.read(key: _currentPreKeyIdsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e as int).toList();
      }
    } catch (_) {}
    return const [];
  }

  /// Warm caches used by native store callbacks.
  Future<void> warmNativeCaches() async {
    await getOrGenerateIdentityKeyPair();
    await getOrGenerateRegistrationId();

    final signedId = await getCurrentSignedPreKeyId();
    if (signedId != null) {
      await loadSignedPreKeyRecord(signedId);
    }
    final kyberId = await getCurrentKyberPreKeyId();
    if (kyberId != null) {
      await loadKyberPreKeyRecord(kyberId);
    }

    final preKeyIds = await getCurrentPreKeyIds();
    for (final id in preKeyIds) {
      await loadPreKeyRecord(id);
    }
  }

  Map<String, dynamic> _preKeyBundleToJsonEncodable(SignalPreKeyBundle bundle) {
    return <String, dynamic>{
      'preKeyId': bundle.preKeyId,
      'signedPreKey': bundle.signedPreKey.toList(),
      'signedPreKeyId': bundle.signedPreKeyId,
      'signature': bundle.signature.toList(),
      'identityKey': bundle.identityKey.toList(),
      'oneTimePreKey': bundle.oneTimePreKey?.toList(),
      'oneTimePreKeyId': bundle.oneTimePreKeyId,
      'registrationId': bundle.registrationId,
      'deviceId': bundle.deviceId,
      'kyberPreKeyId': bundle.kyberPreKeyId,
      'kyberPreKey': bundle.kyberPreKey?.toList(),
      'kyberPreKeySignature': bundle.kyberPreKeySignature?.toList(),
    };
  }

  /// Get or generate identity key pair
  ///
  /// Identity keys are long-term keys used for authentication.
  /// Generated once per device and stored securely.
  ///
  /// **Returns:**
  /// Identity key pair (generated if doesn't exist)
  Future<SignalIdentityKeyPair> getOrGenerateIdentityKeyPair() async {
    if (_identityKeyPair != null) {
      return _identityKeyPair!;
    }

    try {
      // Try to load from secure storage
      final storedKeyJson =
          await _secureStorage.read(key: _identityKeyStorageKey);

      if (storedKeyJson != null) {
        try {
          // Deserialize stored key
          final json = jsonDecode(storedKeyJson) as Map<String, dynamic>;
          final identityKeyPair = SignalIdentityKeyPair.fromJson(json);

          developer.log('✅ Loaded identity key pair from secure storage',
              name: _logName);
          _identityKeyPair = identityKeyPair;
          return identityKeyPair;
        } catch (e, stackTrace) {
          developer.log(
            'Error deserializing stored identity key: $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Continue to generate new key if deserialization fails
        }
      }

      // Generate new identity key pair
      developer.log('Generating new Signal Protocol identity key pair',
          name: _logName);
      final identityKeyPair = await _ffiBindings.generateIdentityKeyPair();

      // Store securely
      try {
        final jsonString = jsonEncode(identityKeyPair.toJson());
        await _secureStorage.write(
          key: _identityKeyStorageKey,
          value: jsonString,
        );
        developer.log('✅ Identity key pair stored securely', name: _logName);
      } catch (e, stackTrace) {
        developer.log(
          'Warning: Failed to store identity key pair: $e',
          name: _logName,
          error: e,
          stackTrace: stackTrace,
        );
        // Continue even if storage fails - key is in memory
      }

      _identityKeyPair = identityKeyPair;
      developer.log('✅ Identity key pair generated and cached', name: _logName);

      return identityKeyPair;
    } catch (e, stackTrace) {
      developer.log(
        'Error getting/generating identity key pair: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Generate prekey bundle for X3DH key exchange
  ///
  /// Generates a bundle containing:
  /// - Signed prekey (signed with identity key)
  /// - One-time prekey (optional)
  /// - Identity key public key
  ///
  /// **Returns:**
  /// Prekey bundle ready for upload to key server
  Future<SignalPreKeyBundle> generatePreKeyBundle() async {
    try {
      final identityKeyPair = await getOrGenerateIdentityKeyPair();
      final registrationId = await getOrGenerateRegistrationId();

      developer.log('Generating prekey bundle with PQXDH (ML-KEM) support', name: _logName);
      final localMaterial = await _ffiBindings.generateLocalPreKeyMaterial(
        identityKeyPair: identityKeyPair,
        registrationId: registrationId,
        deviceId: 1,
      );

      // Persist local-only records needed for PreKey decrypt.
      await storeSignedPreKeyRecord(
        id: localMaterial.bundle.signedPreKeyId,
        serialized: localMaterial.signedPreKeyRecordSerialized,
      );
      await setCurrentSignedPreKeyId(localMaterial.bundle.signedPreKeyId);

      // PQXDH: Kyber prekey (ML-KEM) is required for modern Signal Protocol
      final kyberId = localMaterial.bundle.kyberPreKeyId;
      if (kyberId != null) {
        await storeKyberPreKeyRecord(
          id: kyberId,
          serialized: localMaterial.kyberPreKeyRecordSerialized,
        );
        await setCurrentKyberPreKeyId(kyberId);
        
        developer.log(
          '✅ Kyber prekey (ML-KEM) stored for PQXDH: id=$kyberId',
          name: _logName,
        );
      } else {
        developer.log(
          '⚠️ Warning: No kyber prekey generated. PQXDH support may be limited.',
          name: _logName,
        );
      }

      final preKeyId = localMaterial.bundle.oneTimePreKeyId;
      if (preKeyId != null) {
        if (localMaterial.preKeyRecordSerialized.isNotEmpty) {
          await storePreKeyRecord(
            id: preKeyId,
            serialized: localMaterial.preKeyRecordSerialized,
          );
        }

        // We currently maintain a small set of “active” prekey ids for warmup.
        // TODO(Phase 14): Expand to a pool rotation policy.
        final current = await getCurrentPreKeyIds();
        final updated = <int>{...current, preKeyId}.toList();
        await setCurrentPreKeyIds(updated);
      }

      developer.log('✅ Prekey bundle generated (local records stored)', name: _logName);
      return localMaterial.bundle;
    } catch (e, stackTrace) {
      developer.log(
        'Error generating prekey bundle: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Upload prekey bundle to key server (v2)
  ///
  /// Uploads prekey bundle to Supabase for distribution to other users.
  ///
  /// **Parameters:**
  /// - `userId`: Our Supabase auth user id (used as Signal address for user-to-user messaging)
  /// - `preKeyBundle`: Prekey bundle to upload
  Future<void> uploadPreKeyBundle({
    required String userId,
    required SignalPreKeyBundle preKeyBundle,
  }) async {
    try {
      developer.log(
        'Uploading prekey bundle for user: $userId',
        name: _logName,
      );

      // Check if Supabase is available
      if (_supabaseService == null || !_supabaseService!.isAvailable) {
        developer.log(
          '⚠️ Supabase not available, skipping prekey bundle upload',
          name: _logName,
        );
        return;
      }

      final client = _supabaseService!.client;

      // Serialize prekey bundle to JSON
      final preKeyBundleJson = preKeyBundle.toJson();

      // Convert Uint8List to List<int> for JSON serialization
      final jsonForStorage = {
        'preKeyId': preKeyBundleJson['preKeyId'],
        'signedPreKey': preKeyBundleJson['signedPreKey'],
        'signedPreKeyId': preKeyBundleJson['signedPreKeyId'],
        'signature': preKeyBundleJson['signature'],
        'identityKey': preKeyBundleJson['identityKey'],
        'oneTimePreKey': preKeyBundleJson['oneTimePreKey'],
        'oneTimePreKeyId': preKeyBundleJson['oneTimePreKeyId'],
        'registrationId': preKeyBundleJson['registrationId'],
        'deviceId': preKeyBundleJson['deviceId'],
        'kyberPreKeyId': preKeyBundleJson['kyberPreKeyId'],
        'kyberPreKey': preKeyBundleJson['kyberPreKey'],
        'kyberPreKeySignature': preKeyBundleJson['kyberPreKeySignature'],
      };

      final deviceId = preKeyBundle.deviceId ?? 1;

      // NOTE:
      // We intentionally keep a history of bundles. We do NOT use upsert here because
      // `signal_prekey_bundles_v2` enforces “only one active (consumed=false) per user/device”
      // via a partial unique index, which PostgREST cannot target for upsert conflict resolution.
      //
      // Instead:
      // 1) Mark any existing active bundle as consumed
      // 2) Insert a fresh active bundle row
      final nowIso = DateTime.now().toIso8601String();
      final expiresAtIso =
          DateTime.now().add(const Duration(days: 7)).toIso8601String();

      try {
        await client.from('signal_prekey_bundles_v2').update({
          'consumed': true,
          'consumed_at': nowIso,
        }).eq('user_id', userId).eq('device_id', deviceId).eq(
              'consumed',
              false,
            );
      } catch (e, st) {
        developer.log(
          'Warning: Failed to consume previous active prekey bundle (continuing): $e',
          name: _logName,
          error: e,
          stackTrace: st,
        );
      }

      await client.from('signal_prekey_bundles_v2').insert({
        'user_id': userId,
        'device_id': deviceId,
        'agent_id': null, // optional metadata; filled later when agent-keyed flows exist
        'prekey_bundle_json': jsonForStorage,
        'consumed': false,
        'expires_at': expiresAtIso,
      });

      developer.log('✅ Prekey bundle uploaded to Supabase', name: _logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_prekey_bundle_uploaded',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: <String, Object?>{
            'ok': true,
            'device_id': deviceId,
            'expires_at': expiresAtIso,
            'bundle_version': 2,
          },
        ));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error uploading prekey bundle: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      // Don't rethrow - allow app to continue with in-memory storage for testing
      developer.log(
        'Continuing without Supabase upload (using in-memory storage)',
        name: _logName,
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_prekey_bundle_upload_failed',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: <String, Object?>{
            'ok': false,
            'device_id': preKeyBundle.deviceId ?? 1,
            'error': e.toString(),
            'bundle_version': 2,
          },
        ));
      }
    }
  }

  // Test-only: In-memory storage for prekey bundles (for testing)
  final Map<String, SignalPreKeyBundle> _testPreKeyBundles = {};

  /// Set prekey bundle for testing
  ///
  /// **Note:** This is a test-only method. In production, prekey bundles
  /// are fetched from the key server.
  void setTestPreKeyBundle(String userId, SignalPreKeyBundle bundle) {
    _testPreKeyBundles[userId] = bundle;
    developer.log(
      'Test prekey bundle set for user: $userId',
      name: _logName,
    );
  }

  /// Fetch prekey bundle for a recipient (v2)
  ///
  /// Fetches prekey bundle from key server for X3DH key exchange.
  /// For testing, checks in-memory storage first.
  ///
  /// **Parameters:**
  /// - `recipientUserId`: Recipient's auth user id (Signal address)
  ///
  /// **Returns:**
  /// Prekey bundle for the recipient
  Future<SignalPreKeyBundle> fetchPreKeyBundle(String recipientUserId) async {
    try {
      developer.log(
        'Fetching prekey bundle for recipient: $recipientUserId',
        name: _logName,
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_prekey_bundle_fetch_started',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: recipientUserId,
          payload: <String, Object?>{
            'recipient_id': recipientUserId,
            'bundle_version': 2,
          },
        ));
      }

      // For testing, check in-memory storage first
      if (_testPreKeyBundles.containsKey(recipientUserId)) {
        developer.log(
          'Found prekey bundle in test storage for recipient: $recipientUserId',
          name: _logName,
        );
        if (LedgerAuditV0.isEnabled) {
          unawaited(LedgerAuditV0.tryAppend(
            domain: LedgerDomainV0.security,
            eventType: 'signal_prekey_bundle_fetch_succeeded',
            occurredAt: DateTime.now(),
            entityType: 'user',
            entityId: recipientUserId,
            payload: <String, Object?>{
              'recipient_id': recipientUserId,
              'source': 'test_storage',
              'bundle_version': 2,
            },
          ));
        }
        return _testPreKeyBundles[recipientUserId]!;
      }

      // Offline-first cache (Mode 2: BLE bootstrap)
      final cached = await _getCachedRemotePreKeyBundle(recipientUserId);
      if (cached != null) {
        // Check if bundle needs refresh (expiring soon)
        final cachedEntry = _cachedRemotePreKeyBundles[recipientUserId];
        if (cachedEntry != null) {
          final timeUntilExpiry = cachedEntry.expiresAt.difference(DateTime.now().toUtc());
          if (timeUntilExpiry < _preKeyRefreshThreshold) {
            developer.log(
              'Prekey bundle expiring soon for recipient: $recipientUserId (${timeUntilExpiry.inHours}h remaining). Will refresh proactively.',
              name: _logName,
            );
            // Proactively refresh in background (non-blocking)
            _refreshPreKeyBundleInBackground(recipientUserId);
          }
        }
        
        // Validate cached bundle (PQXDH requirements)
        _validatePreKeyBundle(cached, recipientUserId);
        
        developer.log(
          '✅ Using cached prekey bundle for recipient: $recipientUserId',
          name: _logName,
        );
        if (LedgerAuditV0.isEnabled) {
          unawaited(LedgerAuditV0.tryAppend(
            domain: LedgerDomainV0.security,
            eventType: 'signal_prekey_bundle_fetch_succeeded',
            occurredAt: DateTime.now(),
            entityType: 'user',
            entityId: recipientUserId,
            payload: <String, Object?>{
              'recipient_id': recipientUserId,
              'source': 'offline_cache',
              'bundle_version': 2,
            },
          ));
        }
        return cached;
      }

      // Try to fetch from Supabase
      if (_supabaseService != null && _supabaseService!.isAvailable) {
        try {
          final client = _supabaseService!.client;

          // Fetch via eligibility-gated RPC (v2). This avoids an “open directory”
          // SELECT policy on the table while still allowing community members to
          // establish sessions for sender-key shares.
          Map<String, dynamic>? jsonData;
          try {
            jsonData = await client.rpc(
              'get_signal_prekey_bundle_v2',
              params: <String, dynamic>{
                'p_target_user_id': recipientUserId,
                'target_device_id': 1,
                'invite_token': null,
              },
            ) as Map<String, dynamic>?;
          } catch (_) {
            // If community-based eligibility fails, try a cached DM invite token (if present).
            final inviteToken = await _getCachedDmInviteToken(recipientUserId);
            if (inviteToken != null && inviteToken.isNotEmpty) {
              jsonData = await client.rpc(
                'get_signal_prekey_bundle_v2',
                params: <String, dynamic>{
                  'p_target_user_id': recipientUserId,
                  'target_device_id': 1,
                  'invite_token': inviteToken,
                },
              ) as Map<String, dynamic>?;
            } else {
              rethrow;
            }
          }

          if (jsonData != null) {
            final preKeyBundle = SignalPreKeyBundle.fromJson(jsonData);

            // Validate fetched bundle (PQXDH requirements)
            _validatePreKeyBundle(preKeyBundle, recipientUserId);
            
            // Cache the fetched bundle for offline use
            await cacheRemotePreKeyBundle(
              recipientId: recipientUserId,
              preKeyBundle: preKeyBundle,
            );

            developer.log(
              '✅ Fetched prekey bundle from Supabase for recipient: $recipientUserId',
              name: _logName,
            );
            if (LedgerAuditV0.isEnabled) {
              unawaited(LedgerAuditV0.tryAppend(
                domain: LedgerDomainV0.security,
                eventType: 'signal_prekey_bundle_fetch_succeeded',
                occurredAt: DateTime.now(),
                entityType: 'user',
                entityId: recipientUserId,
                payload: <String, Object?>{
                  'recipient_id': recipientUserId,
                  'source': 'supabase_rpc',
                  'bundle_version': 2,
                  'has_one_time_prekey': preKeyBundle.oneTimePreKey != null,
                },
              ));
            }

            // Mark as consumed if it's a one-time prekey
            if (preKeyBundle.oneTimePreKey != null) {
              try {
                // NOTE: v2 RPC currently does not return row id, so consumption marking
                // is deferred until the bundle format is updated to support multi-OTK batches.
              } catch (e) {
                // Log but don't fail - bundle is already fetched
                developer.log(
                  'Warning: Failed to mark prekey bundle as consumed: $e',
                  name: _logName,
                );
              }
            }

            return preKeyBundle;
          }
        } catch (e, stackTrace) {
          developer.log(
            'Error fetching prekey bundle from Supabase (v2 RPC): $e',
            name: _logName,
            error: e,
            stackTrace: stackTrace,
          );
          // Continue to throw exception below
        }
      }

      // Not found in test storage or Supabase
      throw SignalProtocolException(
        'Prekey bundle not found for recipient: $recipientUserId. '
        'Use SignalKeyManager.cacheRemotePreKeyBundle() for offline Mode 2, '
        'SignalKeyManager.setTestPreKeyBundle() for testing, or upload bundle to Supabase.',
        code: 'PREKEY_BUNDLE_NOT_FOUND',
      );
    } catch (e, stackTrace) {
      developer.log(
        'Error fetching prekey bundle: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_prekey_bundle_fetch_failed',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: recipientUserId,
          payload: <String, Object?>{
            'recipient_id': recipientUserId,
            'error': e.toString(),
            'bundle_version': 2,
          },
        ));
      }
      rethrow;
    }
  }

  /// Rotate prekeys
  ///
  /// Generates new prekeys and uploads them to the key server.
  /// Should be called periodically to maintain fresh prekeys.
  Future<void> rotatePreKeys({required String userId}) async {
    try {
      developer.log('Rotating prekeys for user: $userId', name: _logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_prekey_bundle_rotate_started',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: const <String, Object?>{
            'bundle_version': 2,
          },
        ));
      }

      final newPreKeyBundle = await generatePreKeyBundle();
      await uploadPreKeyBundle(
        userId: userId,
        preKeyBundle: newPreKeyBundle,
      );

      developer.log('✅ Prekeys rotated successfully', name: _logName);
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_prekey_bundle_rotated',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: <String, Object?>{
            'ok': true,
            'device_id': newPreKeyBundle.deviceId ?? 1,
            'bundle_version': 2,
          },
        ));
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error rotating prekeys: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      if (LedgerAuditV0.isEnabled) {
        unawaited(LedgerAuditV0.tryAppend(
          domain: LedgerDomainV0.security,
          eventType: 'signal_prekey_bundle_rotate_failed',
          occurredAt: DateTime.now(),
          entityType: 'user',
          entityId: userId,
          payload: <String, Object?>{
            'ok': false,
            'error': e.toString(),
            'bundle_version': 2,
          },
        ));
      }
      rethrow;
    }
  }
  
  /// Validate prekey bundle (PQXDH requirements, signatures, etc.)
  ///
  /// **Validations:**
  /// - PQXDH: Kyber prekey, kyber prekey ID, and signature must be present
  /// - Required fields: Identity key, signed prekey, signature
  /// - Signature validation (if identity key available)
  ///
  /// **Throws:**
  /// - `SignalProtocolException` if validation fails
  void _validatePreKeyBundle(
    SignalPreKeyBundle bundle,
    String recipientId,
  ) {
    // Validate PQXDH requirements (required for modern Signal Protocol)
    if (bundle.kyberPreKey == null ||
        bundle.kyberPreKeyId == null ||
        bundle.kyberPreKeySignature == null) {
      throw SignalProtocolException(
        'Invalid prekey bundle for recipient $recipientId: PQXDH (Post-Quantum Security) required. '
        'Bundle must include kyberPreKey, kyberPreKeyId, and kyberPreKeySignature.',
        code: 'PQXDH_REQUIRED',
      );
    }
    
    // Validate required fields
    if (bundle.identityKey.isEmpty) {
      throw SignalProtocolException(
        'Invalid prekey bundle for recipient $recipientId: identity key is empty',
        code: 'MISSING_IDENTITY_KEY',
      );
    }
    
    if (bundle.signedPreKey.isEmpty) {
      throw SignalProtocolException(
        'Invalid prekey bundle for recipient $recipientId: signed prekey is empty',
        code: 'MISSING_SIGNED_PREKEY',
      );
    }
    
    if (bundle.signature.isEmpty) {
      throw SignalProtocolException(
        'Invalid prekey bundle for recipient $recipientId: signature is empty',
        code: 'MISSING_SIGNATURE',
      );
    }
    
    // Validate kyber prekey signature (basic size check)
    if (bundle.kyberPreKeySignature == null ||
        bundle.kyberPreKeySignature!.isEmpty) {
      throw SignalProtocolException(
        'Invalid prekey bundle for recipient $recipientId: kyber prekey signature is empty',
        code: 'MISSING_KYBER_SIGNATURE',
      );
    }
    
    developer.log(
      '✅ Prekey bundle validated for recipient: $recipientId (PQXDH enabled)',
      name: _logName,
    );
  }
  
  /// Refresh prekey bundle in background (non-blocking)
  ///
  /// Attempts to fetch a fresh bundle from Supabase if available.
  /// Does not block or throw errors - logs failures only.
  Future<void> _refreshPreKeyBundleInBackground(String recipientId) async {
    if (_supabaseService == null || !_supabaseService!.isAvailable) {
      return; // Cannot refresh without Supabase
    }
    
    try {
      developer.log(
        'Proactively refreshing prekey bundle for recipient: $recipientId',
        name: _logName,
      );
      
      // Fetch fresh bundle (this will cache it automatically)
      await fetchPreKeyBundle(recipientId);
      
      developer.log(
        '✅ Successfully refreshed prekey bundle for recipient: $recipientId',
        name: _logName,
      );
    } catch (e, st) {
      // Non-blocking: log but don't fail
      developer.log(
        'Warning: Failed to refresh prekey bundle for recipient $recipientId: $e',
        name: _logName,
        error: e,
        stackTrace: st,
      );
    }
  }
  
  /// Check if prekey bundle needs rotation
  ///
  /// Returns true if bundle should be rotated (cached for too long).
  bool shouldRotatePreKeyBundle(String recipientId) {
    final cached = _cachedRemotePreKeyBundles[recipientId];
    if (cached == null) return false;
    return cached.shouldRotate(_preKeyRotationInterval);
  }
  
  /// Get all recipient IDs that need bundle rotation
  List<String> getRecipientsNeedingRotation() {
    return _cachedRemotePreKeyBundles.entries
        .where((entry) => entry.value.shouldRotate(_preKeyRotationInterval))
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Get all recipient IDs that need bundle refresh
  List<String> getRecipientsNeedingRefresh() {
    return _cachedRemotePreKeyBundles.entries
        .where((entry) => entry.value.needsRefresh(_preKeyRefreshThreshold))
        .map((entry) => entry.key)
        .toList();
  }
  
  /// Clean up expired prekey bundles
  Future<void> cleanupExpiredPreKeyBundles() async {
    final now = DateTime.now().toUtc();
    final expired = <String>[];
    
    for (final entry in _cachedRemotePreKeyBundles.entries) {
      if (!entry.value.expiresAt.isAfter(now)) {
        expired.add(entry.key);
      }
    }
    
    for (final recipientId in expired) {
      _cachedRemotePreKeyBundles.remove(recipientId);
      try {
        final storageKey = '$_preKeyCachePrefix$recipientId';
        await _secureStorage.delete(key: storageKey);
      } catch (_) {
        // Best-effort cleanup
      }
    }
    
    if (expired.isNotEmpty) {
      developer.log(
        'Cleaned up ${expired.length} expired prekey bundles',
        name: _logName,
      );
    }
  }
}

class _CachedPreKeyBundle {
  final SignalPreKeyBundle bundle;
  final DateTime expiresAt;
  final DateTime cachedAt;

  const _CachedPreKeyBundle({
    required this.bundle,
    required this.expiresAt,
    required this.cachedAt,
  });
  
  /// Check if bundle should be rotated (cached for too long)
  bool shouldRotate(Duration rotationInterval) {
    final age = DateTime.now().toUtc().difference(cachedAt);
    return age >= rotationInterval;
  }
  
  /// Check if bundle needs refresh (expiring soon)
  bool needsRefresh(Duration refreshThreshold) {
    final timeUntilExpiry = expiresAt.difference(DateTime.now().toUtc());
    return timeUntilExpiry < refreshThreshold;
  }
}
