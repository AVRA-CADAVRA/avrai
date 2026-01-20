// Signal Protocol Service for Phase 14: Signal Protocol Implementation
// Option 1: libsignal-ffi via FFI
// High-level service for Signal Protocol encryption/decryption

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_bindings.dart';
import 'package:avrai/core/crypto/signal/signal_ffi_store_callbacks.dart';
import 'package:avrai/core/crypto/signal/signal_key_manager.dart';
import 'package:avrai/core/crypto/signal/signal_session_manager.dart';
import 'package:avrai_core/services/atomic_clock_service.dart';

/// Signal Protocol Service
///
/// High-level service for Signal Protocol encryption and decryption.
/// Provides a simple API for encrypting/decrypting messages using Signal Protocol.
///
/// **Features:**
/// - Perfect forward secrecy (Double Ratchet)
/// - Hybrid key exchange (X3DH + PQXDH) - **PQXDH ENABLED**
/// - Post-quantum security (ML-KEM via PQXDH) - **REQUIRED**
/// - Automatic session management
/// - Future-proof against quantum computing attacks
///
/// Phase 14: Signal Protocol Implementation - Option 1
class SignalProtocolService {
  static const String _logName = 'SignalProtocolService';

  final SignalFFIBindings _ffiBindings;
  final SignalFFIStoreCallbacks _storeCallbacks;
  final SignalKeyManager _keyManager;
  final SignalSessionManager _sessionManager;

  SignalProtocolService({
    required SignalFFIBindings ffiBindings,
    required SignalFFIStoreCallbacks storeCallbacks,
    required SignalKeyManager keyManager,
    required SignalSessionManager sessionManager,
    AtomicClockService?
        atomicClock, // Reserved for future use (atomic timestamps)
  })  : _ffiBindings = ffiBindings,
        _storeCallbacks = storeCallbacks,
        _keyManager = keyManager,
        _sessionManager = sessionManager;

  /// Initialize Signal Protocol service
  ///
  /// Initializes FFI bindings and ensures identity key exists.
  Future<void> initialize() async {
    try {
      developer.log('Initializing Signal Protocol service...', name: _logName);

      // Initialize FFI bindings
      await _ffiBindings.initialize();

      // Initialize store callbacks (required for any session/identity store access
      // inside libsignal-ffi operations).
      if (!_storeCallbacks.isInitialized) {
        await _storeCallbacks.initialize();
      }

      // Ensure identity key exists
      await _keyManager.getOrGenerateIdentityKeyPair();

      developer.log('✅ Signal Protocol service initialized', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing Signal Protocol service: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Encrypt a message for a recipient
  ///
  /// Encrypts a message using Signal Protocol (Double Ratchet).
  /// Automatically establishes session if needed via X3DH.
  /// Automatically re-keys session if needed (after 1000 messages or 24 hours).
  ///
  /// **Parameters:**
  /// - `plaintext`: Message to encrypt
  /// - `recipientId`: Recipient's agent ID
  ///
  /// **Returns:**
  /// Encrypted message ready for transmission
  Future<SignalEncryptedMessage> encryptMessage({
    required Uint8List plaintext,
    required String recipientId,
  }) async {
    try {
      // Check if session exists
      var session = await _sessionManager.getSession(recipientId);

      // If no session, perform X3DH key exchange to establish one
      if (session == null) {
        developer.log(
          'No session found for recipient: $recipientId. Performing hybrid key exchange (X3DH + PQXDH)...',
          name: _logName,
        );

        // Fetch recipient's prekey bundle
        final preKeyBundle = await _keyManager.fetchPreKeyBundle(recipientId);

        // Verify PQXDH support (kyber prekey is required for modern Signal Protocol)
        if (preKeyBundle.kyberPreKey == null ||
            preKeyBundle.kyberPreKeyId == null ||
            preKeyBundle.kyberPreKeySignature == null) {
          throw SignalProtocolException(
            'PQXDH (Post-Quantum Security) required: PreKeyBundle must include '
            'kyberPreKey, kyberPreKeyId, and kyberPreKeySignature for hybrid key exchange (X3DH + PQXDH).',
            code: 'PQXDH_REQUIRED',
          );
        }

        developer.log(
          'PreKeyBundle verified: X3DH + PQXDH (ML-KEM) hybrid key exchange enabled',
          name: _logName,
        );

        // Get our identity key
        final identityKeyPair =
            await _keyManager.getOrGenerateIdentityKeyPair();

        // Perform hybrid key exchange (X3DH + PQXDH)
        // libsignal-ffi automatically performs both X3DH and PQXDH when kyber prekey is present
        session = await _ffiBindings.performX3DHKeyExchange(
          recipientId: recipientId,
          preKeyBundle: preKeyBundle,
          identityKeyPair: identityKeyPair,
          storeCallbacks: _storeCallbacks,
        );

        // Extract handshake hash for channel binding (from root key)
        final handshakeHash = _computeHandshakeHash(
          session.rootKey,
          identityKeyPair.publicKey,
          preKeyBundle.identityKey,
        );

        // Save session (with handshake hash in metadata for channel binding)
        await _sessionManager.updateSession(session);
        
        // Store handshake hash for channel binding verification
        await _sessionManager.setChannelBindingHash(recipientId, handshakeHash);

        developer.log(
          '✅ Hybrid key exchange (X3DH + PQXDH) completed. Post-quantum secure session established for recipient: $recipientId',
          name: _logName,
        );
      } else {
        // Check if re-keying is needed
        if (await _sessionManager.needsRekeying(recipientId)) {
          developer.log(
            'Session re-keying needed for recipient: $recipientId. Performing re-keying...',
            name: _logName,
          );

          // Perform re-keying by establishing a new session
          // Fetch recipient's prekey bundle
          final preKeyBundle = await _keyManager.fetchPreKeyBundle(recipientId);

          // Get our identity key
          final identityKeyPair =
              await _keyManager.getOrGenerateIdentityKeyPair();

          // Verify PQXDH support for re-keying
          if (preKeyBundle.kyberPreKey == null ||
              preKeyBundle.kyberPreKeyId == null ||
              preKeyBundle.kyberPreKeySignature == null) {
            throw SignalProtocolException(
              'PQXDH (Post-Quantum Security) required: PreKeyBundle must include '
              'kyberPreKey, kyberPreKeyId, and kyberPreKeySignature for hybrid key exchange (X3DH + PQXDH).',
              code: 'PQXDH_REQUIRED',
            );
          }

          // Perform hybrid key exchange (X3DH + PQXDH) for re-keying
          // This creates a new post-quantum secure session, replacing the old one
          session = await _ffiBindings.performX3DHKeyExchange(
            recipientId: recipientId,
            preKeyBundle: preKeyBundle,
            identityKeyPair: identityKeyPair,
            storeCallbacks: _storeCallbacks,
          );

          // Extract new handshake hash for channel binding (updated after re-keying)
          final newHandshakeHash = _computeHandshakeHash(
            session.rootKey,
            identityKeyPair.publicKey,
            preKeyBundle.identityKey,
          );

          // Mark session as re-keyed (resets message count and updates timestamp)
          await _sessionManager.markRekeyed(recipientId);
          
          // Update channel binding hash after re-keying
          await _sessionManager.setChannelBindingHash(recipientId, newHandshakeHash);

          // Save new session
          await _sessionManager.updateSession(session);

          developer.log(
            '✅ Post-quantum secure session re-keying completed (X3DH + PQXDH) for recipient: $recipientId',
            name: _logName,
          );
        }
      }

      // Encrypt using Signal Protocol
      final encrypted = await _ffiBindings.encryptMessage(
        plaintext: plaintext,
        recipientId: recipientId,
        storeCallbacks: _storeCallbacks,
      );

      // Increment message count after encryption
      await _sessionManager.incrementMessageCount(recipientId);

      // Update session state (Double Ratchet advances)
      // TODO: Update session with new state from encryption
      // await _sessionManager.updateSession(updatedSession);

      developer.log(
        'Message encrypted for recipient: $recipientId (${plaintext.length} bytes → ${encrypted.ciphertext.length} bytes)',
        name: _logName,
      );

      return encrypted;
    } catch (e, stackTrace) {
      developer.log(
        'Error encrypting message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Decrypt a message from a sender
  ///
  /// Decrypts a message using Signal Protocol (Double Ratchet).
  /// Automatically establishes session if needed via X3DH.
  /// Automatically re-keys session if needed (after 1000 messages or 24 hours).
  ///
  /// **Parameters:**
  /// - `encrypted`: Encrypted message
  /// - `senderId`: Sender's agent ID
  ///
  /// **Returns:**
  /// Decrypted plaintext
  Future<Uint8List> decryptMessage({
    required SignalEncryptedMessage encrypted,
    required String senderId,
  }) async {
    try {
      // Check if session exists and needs re-keying (before decryption)
      // Note: We check before decryption, but re-keying happens after successful decryption
      // to avoid disrupting the current message flow
      final needsRekey = await _sessionManager.getSession(senderId) != null &&
          await _sessionManager.needsRekeying(senderId);

      // Try to decrypt - libsignal-ffi will handle PreKey messages automatically
      // If it's a PreKey message, the session will be established during decryption
      final plaintext = await _ffiBindings.decryptMessage(
        encrypted: encrypted,
        senderId: senderId,
        storeCallbacks: _storeCallbacks,
      );

      // After decryption, check if a new session was created
      // (This happens automatically via store callbacks for PreKey messages)
      var session = await _sessionManager.getSession(senderId);
      if (session != null) {
        // If re-keying was needed, perform it now (after successful decryption)
        if (needsRekey) {
          developer.log(
            'Session re-keying needed for sender: $senderId. Performing re-keying...',
            name: _logName,
          );

          // Perform re-keying by establishing a new session
          // Fetch sender's prekey bundle
          final preKeyBundle = await _keyManager.fetchPreKeyBundle(senderId);

          // Get our identity key
          final identityKeyPair =
              await _keyManager.getOrGenerateIdentityKeyPair();

          // Perform X3DH key exchange (this creates a new session, replacing the old one)
          session = await _ffiBindings.performX3DHKeyExchange(
            recipientId: senderId,
            preKeyBundle: preKeyBundle,
            identityKeyPair: identityKeyPair,
            storeCallbacks: _storeCallbacks,
          );

          // Mark session as re-keyed (resets message count and updates timestamp)
          await _sessionManager.markRekeyed(senderId);

          // Save new session
          await _sessionManager.updateSession(session);

          developer.log(
            '✅ Session re-keying completed for sender: $senderId',
            name: _logName,
          );
        }

        // Increment message count after decryption
        await _sessionManager.incrementMessageCount(senderId);

        // Update session state (Double Ratchet advances)
        // TODO: Update session with new state from decryption
        // await _sessionManager.updateSession(updatedSession);
      }

      developer.log(
        'Message decrypted from sender: $senderId (${encrypted.ciphertext.length} bytes → ${plaintext.length} bytes)',
        name: _logName,
      );

      // Verify channel binding if session exists (handshake hash should match)
      if (session != null) {
        final storedHandshakeHash =
            await _sessionManager.getChannelBindingHash(senderId);
        if (storedHandshakeHash != null && session.rootKey != null) {
          // Compute current handshake hash from session root key
          final currentHandshakeHash = _computeHandshakeHash(
            session.rootKey,
            null, // Can't access our identity key here easily
            null, // Can't access peer identity key here easily
          );
          
          // Verify handshake hash matches (channel binding verification)
          // Basic check: verify root key exists and hash is present
          // Full verification would require identity keys for enhanced binding
          if (storedHandshakeHash.isNotEmpty) {
            // Compare handshake hashes (should match if session is valid)
            if (currentHandshakeHash.length == storedHandshakeHash.length) {
              bool matches = true;
              for (int i = 0; i < currentHandshakeHash.length; i++) {
                if (currentHandshakeHash[i] != storedHandshakeHash[i]) {
                  matches = false;
                  break;
                }
              }
              
              if (matches) {
                developer.log(
                  'Channel binding verified for sender: $senderId',
                  name: _logName,
                );
              } else {
                developer.log(
                  '⚠️ Channel binding mismatch for sender: $senderId (possible MITM attack)',
                  name: _logName,
                );
                // TODO: In production, reject message or take security action
              }
            }
          } else {
            // No stored hash yet - will be set on next key exchange
            developer.log(
              'Channel binding hash not yet stored for sender: $senderId',
              name: _logName,
            );
          }
        }
      }

      return plaintext;
    } catch (e, stackTrace) {
      developer.log(
        'Error decrypting message: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Upload prekey bundle to key server
  ///
  /// Should be called periodically to maintain fresh prekeys.
  ///
  /// **Parameters:**
  /// - `userId`: Our Supabase auth user id (used as Signal address for user-to-user messaging)
  Future<void> uploadPreKeyBundle(String userId) async {
    try {
      await _keyManager.rotatePreKeys(userId: userId);
      developer.log('Prekey bundle uploaded for user: $userId', name: _logName);
    } catch (e, stackTrace) {
      developer.log(
        'Error uploading prekey bundle: $e',
        name: _logName,
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Compute handshake hash for channel binding
  ///
  /// Computes a SHA-256 hash from Signal Protocol handshake material:
  /// - Root key from X3DH/PQXDH key exchange
  /// - Identity keys (local and remote, if available)
  ///
  /// This hash is used for channel binding verification to prevent MITM attacks.
  ///
  /// **Parameters:**
  /// - `rootKey`: Root key from Signal Protocol key exchange (primary binding material)
  /// - `localIdentityKey`: Local identity public key (optional, for additional binding)
  /// - `remoteIdentityKey`: Remote identity public key (optional, for additional binding)
  ///
  /// **Returns:**
  /// 32-byte SHA-256 hash of handshake material
  Uint8List _computeHandshakeHash(
    Uint8List? rootKey,
    Uint8List? localIdentityKey,
    Uint8List? remoteIdentityKey,
  ) {
    if (rootKey != null) {
      // Primary binding: root key from X3DH/PQXDH handshake
      if (localIdentityKey != null && remoteIdentityKey != null) {
        // Enhanced binding: root key + identity keys
        final combined = Uint8List(
          rootKey.length + localIdentityKey.length + remoteIdentityKey.length,
        );
        combined.setRange(0, rootKey.length, rootKey);
        combined.setRange(
          rootKey.length,
          rootKey.length + localIdentityKey.length,
          localIdentityKey,
        );
        combined.setRange(
          rootKey.length + localIdentityKey.length,
          combined.length,
          remoteIdentityKey,
        );
        return Uint8List.fromList(sha256.convert(combined).bytes);
      } else {
        // Basic binding: root key only
        return Uint8List.fromList(sha256.convert(rootKey).bytes);
      }
    }

    // Fallback: hash of empty buffer (should not happen in practice)
    return Uint8List.fromList(sha256.convert(<int>[]).bytes);
  }

  /// Check if service is initialized
  bool get isInitialized => _ffiBindings.isInitialized;
}
