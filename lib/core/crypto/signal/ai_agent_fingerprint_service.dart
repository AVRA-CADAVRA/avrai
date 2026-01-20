// AI Agent Fingerprint Service for AI2AI Connections
// Generates and manages identity fingerprints from Signal Protocol identity keys

import 'dart:developer' as developer;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:avrai/core/crypto/signal/signal_types.dart';

/// AI Agent Fingerprint Service
///
/// Generates identity fingerprints from Signal Protocol identity keys for AI2AI connections.
/// Fingerprints enable out-of-band verification and trust establishment.
///
/// **BitChat-Inspired Pattern:**
/// - SHA-256 hash of identity key as fingerprint
/// - Human-readable format for verification
/// - QR code generation support (future)
///
/// **AI2AI-Specific:**
/// - Fingerprints keyed by AI agent ID (not device ID)
/// - Used for AI agent identity verification
/// - Displayed in connection UI for trust establishment
class AIAgentFingerprintService {
  static const String _logName = 'AIAgentFingerprintService';

  /// Generate fingerprint from Signal Protocol identity key (BitChat-inspired)
  ///
  /// **Fingerprint Format:**
  /// - SHA-256 hash of identity public key
  /// - Hex-encoded for human-readable display
  ///
  /// **Parameters:**
  /// - `identityKey`: Signal Protocol identity public key (from SignalIdentityKeyPair.publicKey or SignalPreKeyBundle.identityKey)
  ///
  /// **Returns:**
  /// 32-byte fingerprint (SHA-256 hash) and human-readable hex string
  static AgentFingerprint generateFingerprint(Uint8List identityKey) {
    if (identityKey.isEmpty) {
      throw ArgumentError('Identity key cannot be empty');
    }

    // Generate SHA-256 hash of identity key (BitChat pattern)
    final hash = sha256.convert(identityKey);
    final fingerprintBytes = Uint8List.fromList(hash.bytes);

    // Generate human-readable hex string (for display/verification)
    final hexFingerprint = hash.toString();

    developer.log(
      'Generated AI agent fingerprint: ${hexFingerprint.substring(0, 16)}...',
      name: _logName,
    );

    return AgentFingerprint(
      fingerprintBytes: fingerprintBytes,
      hexString: hexFingerprint,
    );
  }

  /// Generate fingerprint from SignalIdentityKeyPair
  ///
  /// Convenience method that extracts public key and generates fingerprint.
  static AgentFingerprint generateFingerprintFromKeyPair(
    SignalIdentityKeyPair identityKeyPair,
  ) {
    return generateFingerprint(identityKeyPair.publicKey);
  }

  /// Generate fingerprint from SignalPreKeyBundle
  ///
  /// Convenience method that extracts identity key from prekey bundle.
  static AgentFingerprint generateFingerprintFromBundle(
    SignalPreKeyBundle preKeyBundle,
  ) {
    return generateFingerprint(preKeyBundle.identityKey);
  }

  /// Compare two fingerprints (constant-time comparison)
  ///
  /// **Security:** Uses constant-time comparison to prevent timing attacks.
  ///
  /// **Parameters:**
  /// - `fingerprint1`: First fingerprint
  /// - `fingerprint2`: Second fingerprint
  ///
  /// **Returns:**
  /// `true` if fingerprints match, `false` otherwise
  static bool compareFingerprints(
    AgentFingerprint fingerprint1,
    AgentFingerprint fingerprint2,
  ) {
    if (fingerprint1.fingerprintBytes.length !=
        fingerprint2.fingerprintBytes.length) {
      return false;
    }

    // Constant-time comparison
    int result = 0;
    for (int i = 0; i < fingerprint1.fingerprintBytes.length; i++) {
      result |=
          fingerprint1.fingerprintBytes[i] ^ fingerprint2.fingerprintBytes[i];
    }

    return result == 0;
  }

  /// Format fingerprint for display (human-readable)
  ///
  /// **Format:** Groups of 4 hex characters separated by spaces
  /// Example: `A1B2 C3D4 E5F6 ...`
  ///
  /// **Parameters:**
  /// - `fingerprint`: Fingerprint to format
  ///
  /// **Returns:**
  /// Formatted string for display
  static String formatForDisplay(AgentFingerprint fingerprint) {
    final hex = fingerprint.hexString;
    final formatted = StringBuffer();

    // Group into 4-character chunks
    for (int i = 0; i < hex.length; i += 4) {
      if (i > 0) formatted.write(' ');
      final end = (i + 4 < hex.length) ? i + 4 : hex.length;
      formatted.write(hex.substring(i, end));
    }

    return formatted.toString().toUpperCase();
  }

}

/// AI Agent Fingerprint
///
/// Represents a cryptographic fingerprint of an AI agent's Signal Protocol identity key.
/// Used for identity verification and trust establishment.
class AgentFingerprint {
  /// Fingerprint bytes (32-byte SHA-256 hash)
  final Uint8List fingerprintBytes;

  /// Human-readable hex string (64 hex characters)
  final String hexString;

  AgentFingerprint({
    required this.fingerprintBytes,
    required this.hexString,
  }) {
    if (fingerprintBytes.length != 32) {
      throw ArgumentError('Fingerprint must be 32 bytes (SHA-256)');
    }
    if (hexString.length != 64) {
      throw ArgumentError('Hex string must be 64 characters (SHA-256 hex)');
    }
  }

  /// Format for display (human-readable)
  String get displayFormat => AIAgentFingerprintService.formatForDisplay(this);

  /// Serialize to JSON
  Map<String, dynamic> toJson() {
    return {
      'fingerprint_bytes': fingerprintBytes.toList(),
      'hex_string': hexString,
    };
  }

  /// Deserialize from JSON
  factory AgentFingerprint.fromJson(Map<String, dynamic> json) {
    return AgentFingerprint(
      fingerprintBytes: Uint8List.fromList(
        (json['fingerprint_bytes'] as List).cast<int>(),
      ),
      hexString: json['hex_string'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AgentFingerprint &&
        other.hexString == hexString &&
        _constantTimeEquals(other.fingerprintBytes, fingerprintBytes);
  }

  @override
  int get hashCode => hexString.hashCode;

  /// Constant-time byte comparison
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
