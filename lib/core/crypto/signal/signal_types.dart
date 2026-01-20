// Signal Protocol Types for Phase 14: Signal Protocol Implementation
// Option 1: libsignal-ffi via FFI
// Defines Dart types for Signal Protocol operations

import 'dart:typed_data';

/// Signal Protocol Identity Key Pair
///
/// Long-term identity key used for authentication.
/// Generated once per device and stored securely.
class SignalIdentityKeyPair {
  final Uint8List publicKey;
  final Uint8List privateKey;

  SignalIdentityKeyPair({
    required this.publicKey,
    required this.privateKey,
  });

  /// Serialize to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'publicKey': publicKey.toList(),
      'privateKey': privateKey.toList(),
    };
  }

  /// Deserialize from JSON
  factory SignalIdentityKeyPair.fromJson(Map<String, dynamic> json) {
    return SignalIdentityKeyPair(
      publicKey: Uint8List.fromList((json['publicKey'] as List).cast<int>()),
      privateKey: Uint8List.fromList((json['privateKey'] as List).cast<int>()),
    );
  }

  /// Serialize to base64 string for secure storage
  String toBase64() {
    final json = toJson();
    return Uri.encodeComponent(json.toString());
  }

  /// Deserialize from base64 string
  ///
  /// **Note:** This method is not yet implemented. Use toJson()/fromJson() instead.
  factory SignalIdentityKeyPair.fromBase64(String base64) {
    // Note: This is a simple implementation. For production, consider using
    // a proper JSON encoding library for better security.
    // For now, use toJson()/fromJson() with jsonEncode/jsonDecode
    // ignore: unused_local_variable - Parameter kept for future implementation
    final _ = base64;
    throw UnimplementedError(
        'fromBase64 not yet implemented. Use fromJson(jsonDecode(string)) instead.');
  }
}

/// Signal Protocol Prekey Bundle
///
/// Contains keys needed for hybrid key exchange (X3DH + PQXDH):
/// - Identity key (ECDH, X25519)
/// - Signed prekey (ECDH, X25519)
/// - One-time prekey (optional, ECDH, X25519)
/// - Kyber prekey (REQUIRED, ML-KEM for PQXDH post-quantum security)
/// - Signatures
///
/// **PQXDH (Post-Quantum Security):**
/// - Kyber prekey (ML-KEM) is required for all key exchanges
/// - Enables hybrid key exchange: X3DH (classical) + PQXDH (post-quantum)
/// - Future-proof against quantum computing attacks
class SignalPreKeyBundle {
  final String preKeyId;
  final Uint8List signedPreKey;
  final int signedPreKeyId;
  final Uint8List signature;
  final Uint8List identityKey;
  final Uint8List? oneTimePreKey;
  final int? oneTimePreKeyId;
  // PQXDH fields (required for modern Signal Protocol)
  final int? registrationId;
  final int? deviceId;
  final int? kyberPreKeyId;
  final Uint8List? kyberPreKey;
  final Uint8List? kyberPreKeySignature;

  SignalPreKeyBundle({
    required this.preKeyId,
    required this.signedPreKey,
    required this.signedPreKeyId,
    required this.signature,
    required this.identityKey,
    this.oneTimePreKey,
    this.oneTimePreKeyId,
    this.registrationId,
    this.deviceId,
    this.kyberPreKeyId,
    this.kyberPreKey,
    this.kyberPreKeySignature,
  });

  Map<String, dynamic> toJson() {
    return {
      'preKeyId': preKeyId,
      'signedPreKey': signedPreKey,
      'signedPreKeyId': signedPreKeyId,
      'signature': signature,
      'identityKey': identityKey,
      'oneTimePreKey': oneTimePreKey,
      'oneTimePreKeyId': oneTimePreKeyId,
      'registrationId': registrationId,
      'deviceId': deviceId,
      'kyberPreKeyId': kyberPreKeyId,
      'kyberPreKey': kyberPreKey,
      'kyberPreKeySignature': kyberPreKeySignature,
    };
  }

  factory SignalPreKeyBundle.fromJson(Map<String, dynamic> json) {
    return SignalPreKeyBundle(
      preKeyId: json['preKeyId'] as String,
      signedPreKey:
          Uint8List.fromList((json['signedPreKey'] as List).cast<int>()),
      signedPreKeyId: json['signedPreKeyId'] as int,
      signature: Uint8List.fromList((json['signature'] as List).cast<int>()),
      identityKey:
          Uint8List.fromList((json['identityKey'] as List).cast<int>()),
      oneTimePreKey: json['oneTimePreKey'] != null
          ? Uint8List.fromList((json['oneTimePreKey'] as List).cast<int>())
          : null,
      oneTimePreKeyId: json['oneTimePreKeyId'] as int?,
      registrationId: json['registrationId'] as int?,
      deviceId: json['deviceId'] as int?,
      kyberPreKeyId: json['kyberPreKeyId'] as int?,
      kyberPreKey: json['kyberPreKey'] != null
          ? Uint8List.fromList((json['kyberPreKey'] as List).cast<int>())
          : null,
      kyberPreKeySignature: json['kyberPreKeySignature'] != null
          ? Uint8List.fromList(
              (json['kyberPreKeySignature'] as List).cast<int>())
          : null,
    );
  }
}

/// Local-only prekey material (includes private-state needed for decryption).
///
/// This **must never** be uploaded to the key server. Only `bundle` is safe to upload.
class SignalLocalPreKeyMaterial {
  final SignalPreKeyBundle bundle;

  /// Serialized PreKeyRecord (one-time prekey; contains private key material).
  ///
  /// If `bundle.oneTimePreKeyId` is null, this will be empty.
  final Uint8List preKeyRecordSerialized;

  /// Serialized SignedPreKeyRecord (contains private key material).
  final Uint8List signedPreKeyRecordSerialized;

  /// Serialized KyberPreKeyRecord (contains secret key material).
  final Uint8List kyberPreKeyRecordSerialized;

  SignalLocalPreKeyMaterial({
    required this.bundle,
    required this.preKeyRecordSerialized,
    required this.signedPreKeyRecordSerialized,
    required this.kyberPreKeyRecordSerialized,
  });
}

/// Signal Protocol Encrypted Message
///
/// Contains encrypted message data and metadata needed for decryption.
class SignalEncryptedMessage {
  final Uint8List ciphertext;
  final Uint8List? messageHeader; // For Double Ratchet
  final int? messageType;
  final DateTime timestamp;

  SignalEncryptedMessage({
    required this.ciphertext,
    this.messageHeader,
    this.messageType,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Serialize to bytes for transmission
  Uint8List toBytes() {
    // Format: [header_length][header][ciphertext]
    final headerBytes = messageHeader ?? Uint8List(0);
    final result = Uint8List(4 + headerBytes.length + ciphertext.length);

    // Write header length (4 bytes)
    result[0] = (headerBytes.length >> 24) & 0xFF;
    result[1] = (headerBytes.length >> 16) & 0xFF;
    result[2] = (headerBytes.length >> 8) & 0xFF;
    result[3] = headerBytes.length & 0xFF;

    // Write header
    if (headerBytes.isNotEmpty) {
      result.setRange(4, 4 + headerBytes.length, headerBytes);
    }

    // Write ciphertext
    result.setRange(4 + headerBytes.length, result.length, ciphertext);

    return result;
  }

  factory SignalEncryptedMessage.fromBytes(Uint8List bytes) {
    if (bytes.length < 4) {
      throw Exception('Invalid encrypted message format');
    }

    // Read header length
    final headerLength =
        (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];

    if (bytes.length < 4 + headerLength) {
      throw Exception(
          'Invalid encrypted message format: header length mismatch');
    }

    // Extract header
    final header = headerLength > 0 ? bytes.sublist(4, 4 + headerLength) : null;

    // Extract ciphertext
    final ciphertext = bytes.sublist(4 + headerLength);

    return SignalEncryptedMessage(
      ciphertext: ciphertext,
      messageHeader: header,
    );
  }
}

/// Signal Protocol Session State
///
/// Represents the state of a Signal Protocol session with a recipient.
/// Used for Double Ratchet operations.
class SignalSessionState {
  final String recipientId;
  final Uint8List? rootKey;
  final Uint8List? sendingChainKey;
  final Uint8List? receivingChainKey;
  final int sendingMessageNumber;
  final int receivingMessageNumber;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  // Re-keying tracking
  /// Total number of messages sent and received in this session
  final int totalMessageCount;

  /// Timestamp of last re-keying operation
  final DateTime? lastRekeyedAt;

  SignalSessionState({
    required this.recipientId,
    this.rootKey,
    this.sendingChainKey,
    this.receivingChainKey,
    this.sendingMessageNumber = 0,
    this.receivingMessageNumber = 0,
    DateTime? createdAt,
    this.lastUsedAt,
    this.totalMessageCount = 0,
    this.lastRekeyedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'recipientId': recipientId,
      'rootKey': rootKey,
      'sendingChainKey': sendingChainKey,
      'receivingChainKey': receivingChainKey,
      'sendingMessageNumber': sendingMessageNumber,
      'receivingMessageNumber': receivingMessageNumber,
      'createdAt': createdAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
      'totalMessageCount': totalMessageCount,
      'lastRekeyedAt': lastRekeyedAt?.toIso8601String(),
    };
  }

  factory SignalSessionState.fromJson(Map<String, dynamic> json) {
    return SignalSessionState(
      recipientId: json['recipientId'] as String,
      rootKey: json['rootKey'] != null
          ? Uint8List.fromList((json['rootKey'] as List).cast<int>())
          : null,
      sendingChainKey: json['sendingChainKey'] != null
          ? Uint8List.fromList((json['sendingChainKey'] as List).cast<int>())
          : null,
      receivingChainKey: json['receivingChainKey'] != null
          ? Uint8List.fromList((json['receivingChainKey'] as List).cast<int>())
          : null,
      sendingMessageNumber: json['sendingMessageNumber'] as int? ?? 0,
      receivingMessageNumber: json['receivingMessageNumber'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
      totalMessageCount: json['totalMessageCount'] as int? ?? 0,
      lastRekeyedAt: json['lastRekeyedAt'] != null
          ? DateTime.parse(json['lastRekeyedAt'] as String)
          : null,
    );
  }

  /// Create a copy with updated message count
  SignalSessionState copyWith({
    String? recipientId,
    Uint8List? rootKey,
    Uint8List? sendingChainKey,
    Uint8List? receivingChainKey,
    int? sendingMessageNumber,
    int? receivingMessageNumber,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? totalMessageCount,
    DateTime? lastRekeyedAt,
  }) {
    return SignalSessionState(
      recipientId: recipientId ?? this.recipientId,
      rootKey: rootKey ?? this.rootKey,
      sendingChainKey: sendingChainKey ?? this.sendingChainKey,
      receivingChainKey: receivingChainKey ?? this.receivingChainKey,
      sendingMessageNumber: sendingMessageNumber ?? this.sendingMessageNumber,
      receivingMessageNumber:
          receivingMessageNumber ?? this.receivingMessageNumber,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      totalMessageCount: totalMessageCount ?? this.totalMessageCount,
      lastRekeyedAt: lastRekeyedAt ?? this.lastRekeyedAt,
    );
  }
}

/// Signal Protocol Error
class SignalProtocolException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  SignalProtocolException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() {
    return 'SignalProtocolException: $message${code != null ? ' (code: $code)' : ''}';
  }
}
